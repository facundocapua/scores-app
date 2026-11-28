import Foundation
import SwiftData
import Testing
import UIKit
@testable import Porotos

@MainActor
struct JugadorTests {
    let contenedor: ModelContainer
    var contexto: ModelContext { contenedor.mainContext }

    init() throws {
        contenedor = try Almacen.contenedor(enMemoria: true)
    }

    private func partida(con jugadores: [Jugador]) throws -> Partida {
        try Partida.crear(
            JuegoDeSuma.self,
            variante: .init(meta: 10),
            participantes: jugadores.map { .jugador($0) },
            en: contexto
        )
    }

    @Test func renombrarUnJugadorSeVeEnSusPartidas() throws {
        let ana = Jugador(nombre: "Ana")
        contexto.insert(ana)
        let partida = try partida(con: [ana])

        ana.nombre = "Anita"
        #expect(partida.participantesEnOrden.first?.nombre == "Anita")
    }

    @Test func borrarUnJugadorConservaSuUltimoNombreEnLasPartidas() throws {
        let ana = Jugador(nombre: "Ana")
        let beto = Jugador(nombre: "Beto")
        contexto.insert(ana)
        contexto.insert(beto)
        let enCurso = try partida(con: [ana, beto])
        let terminada = try partida(con: [ana, beto])
        try terminada.terminarAntes()

        ana.nombre = "Anita"
        try ana.borrar()

        #expect(try contexto.fetchCount(FetchDescriptor<Jugador>()) == 1)
        for partida in [enCurso, terminada] {
            let primero = try #require(partida.participantesEnOrden.first?.integrantesEnOrden.first)
            #expect(primero.jugador == nil)
            #expect(primero.nombre == "Anita")
        }
    }
}

@MainActor
struct RecordarTests {
    let contenedor: ModelContainer
    var contexto: ModelContext { contenedor.mainContext }

    init() throws {
        contenedor = try Almacen.contenedor(enMemoria: true)
    }

    @Test func laPrimeraVezProponeLosValoresEstandar() throws {
        let configuracion = try Recordar.ultimaConfiguracion(JuegoDeSuma.self, en: contexto)

        #expect(configuracion.variante == JuegoDeSuma.varianteEstandar)
        #expect(configuracion.participantes == JuegoDeSuma.participantesIniciales)
    }

    @Test func proponeLaUltimaPartidaDeEseJuego() throws {
        let ana = Jugador(nombre: "Ana")
        contexto.insert(ana)
        try Partida.crear(
            JuegoDeSuma.self, variante: .init(meta: 15),
            participantes: [.equipo("A"), .equipo("B")], en: contexto,
            fecha: Date(timeIntervalSince1970: 100)
        )
        try Partida.crear(
            JuegoDeSuma.self, variante: .init(meta: 30),
            participantes: [.equipo("Los de acá", jugadores: [ana]), .equipo("Ellos")], en: contexto,
            fecha: Date(timeIntervalSince1970: 200)
        )
        try Partida.crear(
            OtroJuego.self, variante: .init(opcion: false),
            participantes: [], en: contexto,
            fecha: Date(timeIntervalSince1970: 300)
        )

        let configuracion = try Recordar.ultimaConfiguracion(JuegoDeSuma.self, en: contexto)
        #expect(configuracion.variante == .init(meta: 30))
        #expect(configuracion.participantes == [.equipo("Los de acá", jugadores: [ana]), .equipo("Ellos")])
        #expect(try Recordar.ultimaConfiguracion(OtroJuego.self, en: contexto).variante == .init(opcion: false))
    }

    @Test func unaPartidaDescartadaYaNoSeRecuerda() throws {
        try Partida.crear(
            JuegoDeSuma.self, variante: .init(meta: 15),
            participantes: JuegoDeSuma.participantesIniciales, en: contexto,
            fecha: Date(timeIntervalSince1970: 100)
        )
        let descartada = try Partida.crear(
            JuegoDeSuma.self, variante: .init(meta: 30),
            participantes: JuegoDeSuma.participantesIniciales, en: contexto,
            fecha: Date(timeIntervalSince1970: 200)
        )
        try descartada.borrar()

        #expect(try Recordar.ultimaConfiguracion(JuegoDeSuma.self, en: contexto).variante == .init(meta: 15))
    }

    @Test func unJugadorBorradoDejaSuLugarVacio() throws {
        let ana = Jugador(nombre: "Ana")
        let beto = Jugador(nombre: "Beto")
        contexto.insert(ana)
        contexto.insert(beto)
        try Partida.crear(
            JuegoDeSuma.self, variante: .init(meta: 10),
            participantes: [.jugador(ana), .jugador(beto)], en: contexto
        )
        try ana.borrar()

        let configuracion = try Recordar.ultimaConfiguracion(JuegoDeSuma.self, en: contexto)
        #expect(configuracion.participantes == [.jugador(nil), .jugador(beto)])
        #expect(configuracion.participantes[0].tieneLugaresVacios)
    }
}

@MainActor
struct FuentesTests {
    @Test(arguments: FuenteDeDisplay.allCases)
    func lasFuentesDeDisplayEstanIncluidas(fuente: FuenteDeDisplay) {
        #expect(UIFont(name: fuente.rawValue, size: 12) != nil)
    }
}
