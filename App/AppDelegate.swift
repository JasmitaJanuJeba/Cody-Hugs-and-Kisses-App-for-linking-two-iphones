// AppDelegate.swift
// Handles push notifications, Firebase setup, and background tasks

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

final class AppDelegate: NSObject, UIApplicationDelegate,
                         UNUserNotificationCenterDelegate,
                         MessagingDelegate {

    /// Injected from HugsAndKissesApp after environment objects are ready.
    var appState: AppState?

    // MARK: - Launch

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        // 1. Firebase
        FirebaseApp.configure()

        // 2. Push notifications
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        requestNotificationPermission(application: application)

        // 3. Background delivery – lets silent pushes wake the app to play haptics
        application.registerForRemoteNotifications()

        return true
    }

    // MARK: - Notification permission

    private func requestNotificationPermission(application: UIApplication) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, _ in
                guard granted else { return }
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
    }

    // MARK: - APNs token → Firebase

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // MARK: - FCM token refresh

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        DispatchQueue.main.async { [weak self] in
            self?.appState?.fcmToken = token
            SharedDefaults.set(token, for: .fcmToken)
            // Upload token to Firestore so the partner can find it
            Task {
                await FirebaseService.shared.updateFCMToken(token)
            }
        }
    }

    // MARK: - Foreground notification display

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        handleIncomingPayload(notification.request.content.userInfo)
        completionHandler([.banner, .sound])
    }

    // MARK: - Background / tapped notification

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        handleIncomingPayload(response.notification.request.content.userInfo)
        completionHandler()
    }

    // MARK: - Silent background push (content-available: 1)

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handleIncomingPayload(userInfo)
        completionHandler(.newData)
    }

    // MARK: - Unified payload handler

    private func handleIncomingPayload(_ userInfo: [AnyHashable: Any]) {
        guard
            let type      = userInfo[PushKey.type]      as? String,
            let durationS = userInfo[PushKey.duration]  as? String,
            let intensityS = userInfo[PushKey.intensity] as? String,
            let patternS  = userInfo[PushKey.pattern]   as? String,
            let duration  = Double(durationS),
            let intensity = Double(intensityS)
        else { return }

        let pattern = HapticPattern(rawValue: patternS) ?? .heartbeat
        let senderName = userInfo[PushKey.senderName] as? String ?? "Your partner"

        DispatchQueue.main.async { [weak self] in
            guard let state = self?.appState else { return }

            // Trigger receive haptic
            Task {
                await HapticService.shared.play(
                    pattern: pattern,
                    duration: duration,
                    intensity: Float(intensity)
                )
            }

            // Light up the widget
            state.activateLightUp(type: type, duration: duration)

            // Post local notification if app is in background (shows banner)
            let content = UNMutableNotificationContent()
            let emoji   = type == "hug" ? "🤗" : "💋"
            content.title = "\(emoji) \(senderName) sent you a \(type)!"
            content.body  = "Open the app to send one back."
            content.sound = .default
            let req = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
            UNUserNotificationCenter.current().add(req)
        }
    }
}
