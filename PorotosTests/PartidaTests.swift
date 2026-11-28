import Foundation
import SwiftData
import Testing
@testable import Porotos

@MainActor
struct PartidaTests {
    let contenedor: ModelContainer
    var contexto: ModelContext { contenedor.mainContext }

    init() throws {
        contenedor = try Almacen.contenedor(enMemoria: true)
    }

    private func nuevaPartida(meta: Int = 10, fecha: Date = .now) throws -> Partida {
        try Partida.crear(
            JuegoDeSuma.self,
            variante: .init(meta: meta),
            participantes: JuegoDeSuma.participantesIniciales,
            en: contexto,
            fecha: fecha
        )
    }

    private func sumar(_ puntos: Int, a participante: Int, en partida: Partida, fecha: Date = .now) throws {
        try partida.modificar(JuegoDeSuma.self, fecha: fecha) {
            $0.agregar(.init(participante: participante, puntos: puntos))
        }
    }

    @Test func unaPartidaNuevaEstaEnCursoConSusParticipantesEnOrden() throws {
        let partida = try nuevaPartida()

        #expect(partida.estado == .enCurso)
        #expect(partida.tipo == .truco)
        #expect(partida.participantesEnOrden.map(\.nombre) == ["Nosotros", "Ellos"])
        #expect(try partida.resultado(JuegoDeSuma.self) == .enCurso([0, 0]))
    }

    @Test func llegarAlFinTerminaLaPartidaYDeshacerLaReabre() throws {
        let partida = try nuevaPartida(meta: 5)
        let fin = Date(timeIntervalSince1970: 1_000)
        try sumar(3, a: 0, en: partida)
        try sumar(5, a: 1, en: partida, fecha: fin)

        #expect(partida.estado == .terminada)
        #expect(partida.fechaDeFin == fin)
        #expect(try partida.resultado(JuegoDeSuma.self).ganadores == [1])

        try partida.modificar(JuegoDeSuma.self) { $0.deshacer() }
        #expect(partida.estado == .enCurso)
        #expect(partida.fechaDeFin == nil)
        #expect(try partida.resultado(JuegoDeSuma.self).puntajes == [3, 0])
    }

    @Test func cadaCambioActualizaLaFechaDeLaUltimaAnotacion() throws {
        let partida = try nuevaPartida()
        let fecha = Date(timeIntervalSince1970: 5_000)
        try sumar(1, a: 0, en: partida, fecha: fecha)

        #expect(partida.fechaDeUltimaAnotacion == fecha)
    }

    @Test func terminadaAntesGananLosQueVanPrimerosConEmpateCompartido() throws {
        let partida = try nuevaPartida()
        try sumar(4, a: 0, en: partida)
        try sumar(4, a: 1, en: partida)
        try partida.terminarAntes()

        #expect(partida.estado == .terminada)
        #expect(partida.terminadaAntes)
        #expect(try partida.resultado(JuegoDeSuma.self).ganadores == [0, 1])
    }

    @Test func reanudarUnaTerminadaAntesNoTocaLasAnotaciones() throws {
        let partida = try nuevaPartida()
        try sumar(4, a: 0, en: partida)
        try partida.terminarAntes()
        try partida.reanudar(JuegoDeSuma.self)

        #expect(partida.estado == .enCurso)
        #expect(!partida.terminadaAntes)
        #expect(partida.fechaDeFin == nil)
        #expect(try partida.resultado(JuegoDeSuma.self).puntajes == [4, 0])
    }

    @Test func cambiarLaVarianteRecalculaElFin() throws {
        let partida = try nuevaPartida(meta: 30)
        try sumar(12, a: 0, en: partida)
        try partida.cambiarVariante(JuegoDeSuma.self, por: .init(meta: 10))

        #expect(partida.estado == .terminada)
        #expect(try partida.variante(JuegoDeSuma.self) == .init(meta: 10))
    }

    @Test func leerConLasReglasDeOtroJuegoEsUnError() throws {
        let partida = try nuevaPartida()

        #expect(throws: ErrorDePartida.juegoEquivocado(esperado: .truco, recibido: .generala)) {
            try partida.registro(OtroJuego.self)
        }
    }

    @Test func lasPantallasComunesCalculanSinConocerElJuego() throws {
        let partida = try nuevaPartida()
        try sumar(2, a: 1, en: partida)
        let reglas: any ReglasDeJuego.Type = JuegoDeSuma.self

        #expect(try partida.resultado(con: reglas).puntajes == [0, 2])
    }

    @Test func elBorradorSeGuardaYSeLimpia() throws {
        let partida = try nuevaPartida()
        try partida.guardarBorrador(["canastas": 2])
        #expect(try partida.borrador([String: Int].self) == ["canastas": 2])

        try partida.guardarBorrador(Optional<[String: Int]>.none)
        #expect(try partida.borrador([String: Int].self) == nil)
    }

    @Test func borrarUnaPartidaBorraSusParticipantes() throws {
        let jugador = Jugador(nombre: "Ana")
        contexto.insert(jugador)
        let partida = try Partida.crear(
            JuegoDeSuma.self,
            variante: .init(meta: 10),
            participantes: [.jugador(jugador), .equipo("Ellos")],
            en: contexto
        )
        try partida.borrar()

        #expect(try contexto.fetchCount(FetchDescriptor<Partida>()) == 0)
        #expect(try contexto.fetchCount(FetchDescriptor<Participante>()) == 0)
        #expect(try contexto.fetchCount(FetchDescriptor<Integrante>()) == 0)
        #expect(try contexto.fetchCount(FetchDescriptor<Jugador>()) == 1)
    }
}

/// Cerrar la app nunca pierde una Partida, y Deshacer sigue funcionando al volver (SPEC §6.5).
@MainActor
struct PersistenciaTests {
    @Test func deshacerFuncionaDespuesDeReabrirElAlmacen() throws {
        let carpeta = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: carpeta) }
        let url = carpeta.appendingPathComponent("Porotos.store")

        do {
            let contenedor = try Almacen.contenedor(url: url)
            let contexto = contenedor.mainContext
            let partida = try Partida.crear(
                JuegoDeSuma.self,
                variante: .init(meta: 30),
                participantes: JuegoDeSuma.participantesIniciales,
                en: contexto
            )
            try partida.modificar(JuegoDeSuma.self) { $0.agregar(.init(participante: 0, puntos: 3)) }
            try partida.modificar(JuegoDeSuma.self) { $0.agregar(.init(participante: 1, puntos: 4)) }
            try partida.modificar(JuegoDeSuma.self) { $0.editar(en: 0, por: .init(participante: 0, puntos: 6)) }
            try partida.guardarBorrador("mano a medio cargar")
        }

        let contenedor = try Almacen.contenedor(url: url)
        let contexto = contenedor.mainContext
        let partida = try #require(try contexto.fetch(FetchDescriptor<Partida>()).first)
        #expect(try partida.resultado(JuegoDeSuma.self).puntajes == [6, 4])
        #expect(try partida.borrador(String.self) == "mano a medio cargar")

        try partida.modificar(JuegoDeSuma.self) { $0.deshacer() }
        #expect(try partida.resultado(JuegoDeSuma.self).puntajes == [3, 4])
        try partida.modificar(JuegoDeSuma.self) { $0.deshacer() }
        #expect(try partida.resultado(JuegoDeSuma.self).puntajes == [3, 0])
    }
}
