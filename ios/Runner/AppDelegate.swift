import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private var screenProtectionEnabled = true
  private var blurOverlay: UIVisualEffectView?

  // MARK: - App Launch

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerLifecycleObservers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Flutter Engine

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.kaandikec.secureauth/window",
      binaryMessenger: engineBridge.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      if call.method == "setSecure" {
        let secure = (call.arguments as? [String: Any])?["secure"] as? Bool ?? true
        self.screenProtectionEnabled = secure
        if !secure { self.removeBlurOverlay() }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Lifecycle Observers

  private func registerLifecycleObservers() {
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(appWillResignActive),
                   name: UIApplication.willResignActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(appDidBecomeActive),
                   name: UIApplication.didBecomeActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(userDidTakeScreenshot),
                   name: UIApplication.userDidTakeScreenshotNotification, object: nil)
  }

  // MARK: - Blur Overlay (App Switcher Privacy)

  @objc private func appWillResignActive() {
    guard screenProtectionEnabled else { return }
    guard let window = keyWindow, blurOverlay == nil else { return }

    let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
    blur.frame = window.bounds
    blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blur.tag = 0x53435054  // "SCPT"
    window.addSubview(blur)
    blurOverlay = blur
  }

  @objc private func appDidBecomeActive() {
    removeBlurOverlay()
  }

  private func removeBlurOverlay() {
    blurOverlay?.removeFromSuperview()
    blurOverlay = nil
    keyWindow?.viewWithTag(0x53435054)?.removeFromSuperview()
  }

  // MARK: - Screenshot Detection

  @objc private func userDidTakeScreenshot() {
    guard screenProtectionEnabled else { return }
    guard let window = keyWindow else { return }

    let black = UIView(frame: window.bounds)
    black.backgroundColor = .black
    black.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(black)

    UIView.animate(withDuration: 0.15, delay: 1.2, options: []) {
      black.alpha = 0
    } completion: { _ in
      black.removeFromSuperview()
    }
  }

  // MARK: - Helpers

  private var keyWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
