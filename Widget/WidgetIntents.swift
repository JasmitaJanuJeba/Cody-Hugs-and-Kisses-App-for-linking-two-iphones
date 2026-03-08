// WidgetIntents.swift
// App Intents that power interactive lock screen widgets (iOS 17+)
// These let the widget buttons call back into the app without fully opening it.

import AppIntents
import WidgetKit

// MARK: - Send Hug Intent

struct SendHugIntent: AppIntent {

    static var title: LocalizedStringResource = "Send Hug"
    static var description = IntentDescription("Sends a hug to your partner")

    // Open the app so it can read the pending action and send via Firebase
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard SharedDefaults.bool(for: .isPaired) else { return .result() }
        SharedDefaults.set("hug", for: .pendingAction)
        return .result()
    }
}

// MARK: - Send Kiss Intent

struct SendKissIntent: AppIntent {

    static var title: LocalizedStringResource = "Send Kiss"
    static var description = IntentDescription("Sends a kiss to your partner")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard SharedDefaults.bool(for: .isPaired) else { return .result() }
        SharedDefaults.set("kiss", for: .pendingAction)
        return .result()
    }
}
