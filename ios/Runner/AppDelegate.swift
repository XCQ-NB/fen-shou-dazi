import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Process-level engine: ready before any FlutterViewController loads.
  /// Avoids VSyncClient nil crash on ProMotion devices with UIScene.
  let flutterEngine = FlutterEngine(name: "runner2_engine")
  private var pluginsRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NSLog("[runner2/native][I] application didFinishLaunching")
    let ran = flutterEngine.run()
    NSLog("[runner2/native][I] flutterEngine.run => %@", ran ? "true" : "false")
    if !pluginsRegistered {
      GeneratedPluginRegistrant.register(with: flutterEngine)
      pluginsRegistered = true
      NSLog("[runner2/native][I] plugins registered once")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
