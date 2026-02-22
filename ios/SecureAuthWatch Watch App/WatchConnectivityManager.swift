import WatchConnectivity
import SwiftUI

/// Receives OTP data pushed by the iPhone app and exposes it to SwiftUI views.
final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    @Published var accounts: [WatchAccount] = []
    @Published var isAuthenticated = false
    @Published var lastUpdated: Date?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: – Context processing

    private func processContext(_ context: [String: Any]) {
        guard let isAuth = context["isAuthenticated"] as? Bool else { return }
        let parsed: [WatchAccount]
        if let list = context["accounts"] as? [[String: Any]] {
            parsed = list.compactMap { WatchAccount(from: $0) }
        } else {
            parsed = []
        }
        DispatchQueue.main.async {
            self.isAuthenticated = isAuth
            self.accounts = parsed
            self.lastUpdated = Date()
        }
    }

    // MARK: – WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let ctx = session.receivedApplicationContext as? [String: Any], !ctx.isEmpty {
            processContext(ctx)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        processContext(message)
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        processContext(applicationContext)
    }
}

// MARK: – WatchAccount convenience init

private extension WatchAccount {
    init?(from dict: [String: Any]) {
        guard
            let id = dict["id"] as? String,
            let issuer = dict["issuer"] as? String,
            let name = dict["name"] as? String,
            let code = dict["code"] as? String,
            let remaining = dict["remainingSeconds"] as? Int,
            let period = dict["period"] as? Int,
            let type = dict["type"] as? String,
            let progress = dict["progress"] as? Double
        else { return nil }

        self.init(
            id: id, issuer: issuer, name: name, code: code,
            remainingSeconds: remaining, period: period,
            type: type, progress: progress
        )
    }
}
