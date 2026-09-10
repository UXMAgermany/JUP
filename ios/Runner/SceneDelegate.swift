import Flutter
import UIKit
import UserNotifications

/// Scene delegate for the app's single window scene.
///
/// Under the UIScene lifecycle, foreground/background transitions are delivered
/// here instead of to `AppDelegate`, so the badge reset lives on this side.
class SceneDelegate: FlutterSceneDelegate {
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    clearBadge()
  }

  private func clearBadge() {
    if #available(iOS 16.0, *) {
      UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    } else {
      UIApplication.shared.applicationIconBadgeNumber = 0
    }
  }
}
