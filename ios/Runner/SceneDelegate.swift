import Flutter
import UIKit

/// Programmatic window + explicit engine (no storyboard FlutterViewController).
/// Storyboard-loaded FlutterViewController hits viewDidLoad before the engine
/// exists and crashes in VSyncClient on device.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      NSLog("[runner2/native][E] AppDelegate missing in scene connect")
      return
    }

    NSLog("[runner2/native][I] scene willConnect — attach FlutterViewController")
    let engine = appDelegate.flutterEngine
    if engine.viewController != nil {
      NSLog("[runner2/native][W] detaching previous FlutterViewController")
      engine.viewController = nil
    }

    let flutterViewController = FlutterViewController(
      engine: engine,
      nibName: nil,
      bundle: nil
    )
    window = UIWindow(windowScene: windowScene)
    window?.rootViewController = flutterViewController
    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    NSLog("[runner2/native][I] sceneDidDisconnect")
  }
}
