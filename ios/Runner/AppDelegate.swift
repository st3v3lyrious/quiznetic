import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var registeredPluginRegistries = Set<ObjectIdentifier>()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerPluginsIfNeeded(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    registerPluginsIfNeeded(with: engineBridge.pluginRegistry)
  }

  private func registerPluginsIfNeeded(with registry: FlutterPluginRegistry) {
    let registryIdentifier = ObjectIdentifier(registry as AnyObject)
    guard !registeredPluginRegistries.contains(registryIdentifier) else {
      return
    }

    registeredPluginRegistries.insert(registryIdentifier)
    GeneratedPluginRegistrant.register(with: registry)
  }
}
