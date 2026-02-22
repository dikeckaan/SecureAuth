import Foundation

struct WatchAccount: Identifiable, Codable {
    let id: String
    let issuer: String
    let name: String
    let code: String
    let remainingSeconds: Int
    let period: Int
    let type: String
    let progress: Double

    var isHotp: Bool { type == "hotp" }
    var isSteam: Bool { type == "steam" }

    var initials: String {
        String(issuer.prefix(1)).uppercased()
    }
}
