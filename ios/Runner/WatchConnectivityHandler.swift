import WatchConnectivity

/// Manages the WCSession lifecycle and pushes account context to the Watch.
/// Secrets are never included – only generated OTP codes.
final class WatchConnectivityHandler: NSObject, WCSessionDelegate {
  private var latestContext: [String: Any] = [:]

  /// Called from the Flutter MethodChannel handler with fresh account data.
  func updateContext(_ context: [String: Any]) {
    latestContext = context
    guard WCSession.default.activationState == .activated else { return }

    // Immediate delivery when Watch is in foreground
    if WCSession.default.isReachable {
      WCSession.default.sendMessage(context, replyHandler: nil, errorHandler: nil)
    }

    // Background delivery via application context (latest value wins)
    do {
      try WCSession.default.updateApplicationContext(context)
    } catch {
      // Non-critical; Watch will pick up next update
    }
  }

  // MARK: – WCSessionDelegate

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    if activationState == .activated {
      updateContext(latestContext)
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }
}
