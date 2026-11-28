import Foundation
import SwiftData

enum EstadoDePartida: String, Codable, Sendable {
    case enCurso
    case terminada
}

/// Una sesión de un Juego (SPEC §3.1). Es común a todos los Juegos: la Variante, las
/// Anotaciones y el borrador se guardan codificados, y cada Juego los interpreta con sus
/// `ReglasDeJuego`. Nunca guarda totales: los puntajes, el fin y los Ganadores se calculan
/// (ADR 0001).
///
/// Cada cambio se guarda al instante, así que cerrar la app nunca pierde una Partida.
@Model
final class Partida {
    var id: UUID
    var tipoRaw: String
    var estadoRaw: String
    var terminadaAntes: Bool
    var fechaDeInicio: Date
    var fechaDeFin: Date?
    var fechaDeUltimaAnotacion: Date
    var varianteData: Data
    var registroData: Data
    /// Para Burako: la Mano a medio cargar.
    var borradorData: Data?

    @Relationship(deleteRule: .cascade, inverse: \Participante.partida)
    var participantes: [Participante] = []

    private init(tipo: TipoDeJuego, varianteData: Data, registroData: Data, fecha: Date) {
        self.id = UUID()
        self.tipoRaw = tipo.rawValue
        self.estadoRaw = EstadoDePartida.enCurso.rawValue
        self.terminadaAntes = false
        self.fechaDeInicio = fecha
        self.fechaDeFin = nil
        self.fechaDeUltimaAnotacion = fecha
        self.varianteData = varianteData
        self.registroData = registroData
    }

    /// Crea una Partida En curso y la guarda. Los lugares vacíos de los borradores se ignoran.
    @discardableResult
    static func crear<R: ReglasDeJuego>(
        _ reglas: R.Type,
        variante: R.Variante,
        participantes: [ParticipanteBorrador],
        en contexto: ModelContext,
        fecha: Date = .now
    ) throws -> Partida {
        let partida = Partida(
            tipo: R.tipo,
            varianteData: try Codificacion.codificar(variante),
            registroData: try Codificacion.codificar(RegistroDeAnotaciones<R.Anotacion>()),
            fecha: fecha
        )
        contexto.insert(partida)
        for (orden, borrador) in participantes.enumerated() {
            let participante = Participante(orden: orden, nombreDeEquipo: borrador.nombreDeEquipo)
            partida.participantes.append(participante)
            for (ordenDeIntegrante, jugador) in borrador.jugadores.compactMap({ $0 }).enumerated() {
                participante.integrantes.append(Integrante(orden: ordenDeIntegrante, jugador: jugador))
            }
        }
        try contexto.save()
        return partida
    }

    // MARK: - Lectura

    var tipo: TipoDeJuego { TipoDeJuego(rawValue: tipoRaw) ?? .truco }

    var estado: EstadoDePartida {
        get { EstadoDePartida(rawValue: estadoRaw) ?? .enCurso }
        set { estadoRaw = newValue.rawValue }
    }

    var participantesEnOrden: [Participante] {
        participantes.sorted { $0.orden < $1.orden }
    }

    func variante<R: ReglasDeJuego>(_ reglas: R.Type) throws -> R.Variante {
        try verificar(reglas)
        return try Codificacion.decodificar(R.Variante.self, de: varianteData)
    }

    func registro<R: ReglasDeJuego>(_ reglas: R.Type) throws -> RegistroDeAnotaciones<R.Anotacion> {
        try verificar(reglas)
        return try Codificacion.decodificar(RegistroDeAnotaciones<R.Anotacion>.self, de: registroData)
    }

    /// Puntajes, fin y Ganadores. En una Partida Terminada antes, ganan los que van primeros.
    func resultado<R: ReglasDeJuego>(_ reglas: R.Type) throws -> Resultado {
        let segunReglas = R.resultado(
            variante: try variante(reglas),
            cantidadDeParticipantes: participantes.count,
            anotaciones: try registro(reglas).anotaciones
        )
        guard terminadaAntes else { return segunReglas }
        return Resultado(
            puntajes: segunReglas.puntajes,
            terminada: true,
            ganadores: Resultado.lideres(segunReglas.puntajes)
        )
    }

    /// Para las pantallas comunes, que no conocen el Juego.
    func resultado(con reglas: any ReglasDeJuego.Type) throws -> Resultado {
        try resultado(reglas)
    }

    // MARK: - Cambios

    /// Aplica un cambio a las Anotaciones (agregar, editar, quitar o deshacer), recalcula el
    /// estado y guarda. Si la Partida estaba Terminada antes, el cambio la reanuda.
    func modificar<R: ReglasDeJuego>(
        _ reglas: R.Type,
        fecha: Date = .now,
        _ cambio: (inout RegistroDeAnotaciones<R.Anotacion>) -> Void
    ) throws {
        var registro = try registro(reglas)
        cambio(&registro)
        registroData = try Codificacion.codificar(registro)
        fechaDeUltimaAnotacion = fecha
        terminadaAntes = false
        try actualizarEstado(reglas, fecha: fecha)
    }

    /// Cambia la Variante a mitad de Partida (SPEC §6.4). Qué opciones se permiten lo decide
    /// cada Juego.
    func cambiarVariante<R: ReglasDeJuego>(_ reglas: R.Type, por nueva: R.Variante, fecha: Date = .now) throws {
        try verificar(reglas)
        varianteData = try Codificacion.codificar(nueva)
        try actualizarEstado(reglas, fecha: fecha)
    }

    /// "Terminar con este resultado" (SPEC §4.4).
    func terminarAntes(fecha: Date = .now) throws {
        guard estado == .enCurso else { return }
        terminadaAntes = true
        estado = .terminada
        fechaDeFin = fecha
        try guardar()
    }

    /// Vuelve a poner En curso una Partida Terminada antes, sin tocar sus Anotaciones.
    func reanudar<R: ReglasDeJuego>(_ reglas: R.Type) throws {
        guard terminadaAntes else { return }
        terminadaAntes = false
        try actualizarEstado(reglas, fecha: fechaDeFin ?? .now)
    }

    func borrador<B: Decodable>(_ tipo: B.Type) throws -> B? {
        guard let borradorData else { return nil }
        return try Codificacion.decodificar(tipo, de: borradorData)
    }

    func guardarBorrador<B: Encodable>(_ borrador: B?) throws {
        if let borrador {
            borradorData = try Codificacion.codificar(borrador)
        } else {
            borradorData = nil
        }
        try guardar()
    }

    /// Descartar o borrar (SPEC §6.3).
    func borrar() throws {
        guard let contexto = modelContext else { return }
        contexto.delete(self)
        try contexto.save()
    }

    // MARK: - Privado

    private func actualizarEstado<R: ReglasDeJuego>(_ reglas: R.Type, fecha: Date) throws {
        let resultado = try resultado(reglas)
        if resultado.terminada {
            if estado == .enCurso {
                estado = .terminada
                fechaDeFin = fecha
            }
        } else {
            estado = .enCurso
            fechaDeFin = nil
        }
        try guardar()
    }

    private func verificar<R: ReglasDeJuego>(_ reglas: R.Type) throws {
        guard R.tipo == tipo else {
            throw ErrorDePartida.juegoEquivocado(esperado: tipo, recibido: R.tipo)
        }
    }

    private func guardar() throws {
        try modelContext?.save()
    }
}

enum ErrorDePartida: Error, Equatable {
    case juegoEquivocado(esperado: TipoDeJuego, recibido: TipoDeJuego)
}

enum Codificacion {
    static func codificar<T: Encodable>(_ valor: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(valor)
    }

    static func decodificar<T: Decodable>(_ tipo: T.Type, de data: Data) throws -> T {
        try JSONDecoder().decode(tipo, from: data)
    }
}
