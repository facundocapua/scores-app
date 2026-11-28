import Foundation
import Testing
@testable import Porotos

struct RegistroDeAnotacionesTests {
    @Test func deshacerSacaLasAnotacionesAgregadasEnOrdenInverso() {
        var registro = RegistroDeAnotaciones<Int>()
        registro.agregar(1)
        registro.agregar(2)
        registro.agregar(3)

        let deshizo = registro.deshacer()
        #expect(deshizo)
        #expect(registro.anotaciones == [1, 2])
        registro.deshacer()
        registro.deshacer()
        #expect(registro.anotaciones.isEmpty)
        #expect(!registro.puedeDeshacer)
        let deshizoSinCambios = registro.deshacer()
        #expect(!deshizoSinCambios)
    }

    @Test func deshacerRestauraElValorAnteriorDeUnaEdicion() {
        var registro = RegistroDeAnotaciones<Int>()
        registro.agregar(10)
        registro.agregar(20)
        registro.editar(en: 0, por: 15)

        #expect(registro.anotaciones == [15, 20])
        registro.deshacer()
        #expect(registro.anotaciones == [10, 20])
        registro.deshacer()
        #expect(registro.anotaciones == [10])
    }

    @Test func editarConElMismoValorNoEsUnCambio() {
        var registro = RegistroDeAnotaciones<Int>()
        registro.agregar(10)
        registro.editar(en: 0, por: 10)

        registro.deshacer()
        #expect(registro.anotaciones.isEmpty)
    }

    @Test func deshacerDevuelveUnaAnotacionQuitadaASuLugar() {
        var registro = RegistroDeAnotaciones<Int>()
        registro.agregar(1)
        registro.agregar(2)
        registro.agregar(3)
        registro.quitar(en: 1)

        #expect(registro.anotaciones == [1, 3])
        registro.deshacer()
        #expect(registro.anotaciones == [1, 2, 3])
    }

    @Test func cambiosMezcladosSeDeshacenEnOrden() {
        var registro = RegistroDeAnotaciones<Int>()
        registro.agregar(1)
        registro.agregar(2)
        registro.editar(en: 0, por: 5)
        registro.quitar(en: 1)
        registro.agregar(9)
        let estados: [[Int]] = [[5, 9], [5], [5, 2], [1, 2], [1], []]

        #expect(registro.anotaciones == estados[0])
        for esperado in estados.dropFirst() {
            registro.deshacer()
            #expect(registro.anotaciones == esperado)
        }
    }

    @Test func elHistorialDeCambiosSobreviveALaCodificacion() throws {
        var registro = RegistroDeAnotaciones<Int>()
        registro.agregar(1)
        registro.editar(en: 0, por: 2)

        var decodificado = try Codificacion.decodificar(
            RegistroDeAnotaciones<Int>.self,
            de: try Codificacion.codificar(registro)
        )
        #expect(decodificado == registro)
        decodificado.deshacer()
        #expect(decodificado.anotaciones == [1])
    }
}

struct ResultadoTests {
    @Test func losLideresIncluyenATodosLosEmpatadosArriba() {
        #expect(Resultado.lideres([3, 7, 7, 1]) == [1, 2])
        #expect(Resultado.lideres([5]) == [0])
        #expect(Resultado.lideres([]) == [])
    }
}
