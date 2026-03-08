// WidgetIntents.swift
// App Intents that power interactive lock screen widgets (iOS 17+)
// These let the widget buttons call back into the app without fully opening it.

import AppIntents
import WidgetKit

// MARK: - Send Hug Intent

struct SendHugIntent: AppIntent {

    static var title: LocalizedStringResource = "Send Hug"
    static var description = IntentDescription("Sends a hug to your partner")

    // Open app in background – do NOT bring to foreground
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        guard SharedDefaults.bool(for: .isPaired),
              let myUID      = SharedDefaults.string(for: .myUID),
              let partnerUID = SharedDefaults.string(for: .partnerUID),
              let myName     = SharedDefaults.string(for: .myName)
        else { return .result() }

        let settings = UserHapticSettings.load()

        // Send to partner (fire-and-forget; widget shouldn't block)
        Task {
            try? await FirebaseService.shared.send(
                type: "hug",
                senderUID: myUID,
                senderName: myName,
                recipientUID: partnerUID,
                settings: settings
            )
        }

        return .result()
    }
}

// MARK: - Send Kiss Intent

struct SendKissIntent: AppIntent {

    static var title: LocalizedStringResource = "Send Kiss"
    static var description = IntentDescription("Sends a kiss to your partner")

    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        guard SharedDefaults.bool(for: .isPaired),
              let myUID      = SharedDefaults.string(for: .myUID),
              let partnerUID = SharedDefaults.string(for: .partnerUID),
              let myName     = SharedDefaults.string(for: .myName)
        else { return .result() }

        let settings = UserHapticSettings.load()

        Task {
            try? await FirebaseService.shared.send(
                type: "kiss",
                senderUID: myUID,
                senderName: myName,
                recipientUID: partnerUID,
                settings: settings
            )
        }

        return .result()
    }
}
