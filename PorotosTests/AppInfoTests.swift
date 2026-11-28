import Foundation
import Testing
@testable import Porotos

struct AppInfoTests {
    @Test func readsTheValuesFromTheInfoDictionary() {
        let info = AppInfo(info: [
            "CFBundleShortVersionString": "1.2.0",
            "CFBundleVersion": "7",
            "PorotosSupportEmail": "hola@example.com",
            "PorotosPrivacyURL": "https://example.com/privacidad/",
            "PorotosSupportURL": "https://example.com/soporte/",
        ])
        #expect(info.versionText == "1.2.0 (7)")
        #expect(info.supportEmail == "hola@example.com")
        #expect(info.mailtoURL?.absoluteString == "mailto:hola@example.com")
        #expect(info.privacyURL?.absoluteString == "https://example.com/privacidad/")
        #expect(info.supportURL?.absoluteString == "https://example.com/soporte/")
    }

    @Test func theBundleDefinesTheBuildTimeValues() {
        let info = AppInfo.current
        #expect(!info.supportEmail.isEmpty)
        #expect(info.privacyURL?.scheme == "https")
        #expect(info.supportURL?.scheme == "https")
    }
}
