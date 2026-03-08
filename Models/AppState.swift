// AppState.swift
// Central observable state shared across all views via @EnvironmentObject

import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {

    // MARK: - Pairing

    @Published public var isPaired: Bool = false
    @Published public var myUID: String = ""
    @Published public var myName: String = ""
    @Published public var partnerUID: String = ""
    @Published public var partnerName: String = ""
    @Published public var fcmToken: String = ""

    // MARK: - Haptic settings (current user's receive preferences)

    @Published public var hapticSettings = UserHapticSettings.load()

    // MARK: - Widget / animation state (local to this phone)

    @Published public var hugIsLit: Bool = false
    @Published public var kissIsLit: Bool = false

    // MARK: - Send state

    @Published public var isSending: Bool = false
    @Published public var lastSentType: String? = nil

    // MARK: - Onboarding

    @Published public var hasCompletedOnboarding: Bool = false

    // MARK: - Init

    public init() {
        loadFromDefaults()
    }

    // MARK: - Persistence

    public func loadFromDefaults() {
        isPaired   = SharedDefaults.bool(for: .isPaired)
        myUID      = SharedDefaults.string(for: .myUID)      ?? ""
        myName     = SharedDefaults.string(for: .myName)     ?? ""
        partnerUID = SharedDefaults.string(for: .partnerUID) ?? ""
        partnerName = SharedDefaults.string(for: .partnerName) ?? ""
        fcmToken   = SharedDefaults.string(for: .fcmToken)   ?? ""
        hapticSettings = UserHapticSettings.load()
        hasCompletedOnboarding = isPaired
    }

    public func saveToDefaults() {
        SharedDefaults.set(isPaired,    for: .isPaired)
        SharedDefaults.set(myUID,       for: .myUID)
        SharedDefaults.set(myName,      for: .myName)
        SharedDefaults.set(partnerUID,  for: .partnerUID)
        SharedDefaults.set(partnerName, for: .partnerName)
        SharedDefaults.set(fcmToken,    for: .fcmToken)
        hapticSettings.save()
    }

    // MARK: - Pairing helpers

    public func completePairing(partnerUID: String, partnerName: String) {
        self.partnerUID  = partnerUID
        self.partnerName = partnerName
        self.isPaired    = true
        self.hasCompletedOnboarding = true
        saveToDefaults()
    }

    public func unpair() {
        partnerUID  = ""
        partnerName = ""
        isPaired    = false
        SharedDefaults.set(false, for: .isPaired)
        SharedDefaults.set("",    for: .partnerUID)
        SharedDefaults.set("",    for: .partnerName)
    }

    // MARK: - Widget light-up

    /// Called when this phone receives a hug or kiss.
    public func activateLightUp(type: String, duration: Double) {
        if type == "hug" {
            hugIsLit = true
            SharedDefaults.activateLightUp(type: "hug", duration: duration)
        } else {
            kissIsLit = true
            SharedDefaults.activateLightUp(type: "kiss", duration: duration)
        }

        // Schedule turn-off
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if type == "hug" { hugIsLit = false }
            else              { kissIsLit = false }
            SharedDefaults.set(false, for: type == "hug" ? .hugLitUp : .kissLitUp)
            // Tell WidgetKit to refresh its timeline
            WidgetRefresher.reload()
        }
        WidgetRefresher.reload()
    }
}

// MARK: - WidgetKit reload shim
// Import WidgetKit only in the app target; the shim keeps models free of that dependency.

import WidgetKit

public enum WidgetRefresher {
    public static func reload() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
