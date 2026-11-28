import Foundation

/// Build-time values of the app: version, contact email and public pages (SPEC §9).
/// They come from build settings in `project.yml`, exposed as Info.plist keys.
struct AppInfo: Equatable {
    var version: String
    var build: String
    var supportEmail: String
    var privacyURL: URL?
    var supportURL: URL?

    init(info: [String: Any]) {
        func string(_ key: String) -> String { (info[key] as? String) ?? "" }
        func url(_ key: String) -> URL? { URL(string: string(key)) }
        version = string("CFBundleShortVersionString")
        build = string("CFBundleVersion")
        supportEmail = string("PorotosSupportEmail")
        privacyURL = url("PorotosPrivacyURL")
        supportURL = url("PorotosSupportURL")
    }

    static let current = AppInfo(info: Bundle.main.infoDictionary ?? [:])

    /// For example "0.1.0 (1)".
    var versionText: String { "\(version) (\(build))" }

    var mailtoURL: URL? { URL(string: "mailto:\(supportEmail)") }
}
