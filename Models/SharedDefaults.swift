// SharedDefaults.swift
// Shared between main app and widget extension via App Groups
// App Group ID must match in both targets: "group.com.yourname.hugsandkisses"

import Foundation

public enum SharedDefaultsKey: String {
    // Partner state
    case partnerUID         = "partner_uid"
    case myUID              = "my_uid"
    case isPaired           = "is_paired"
    case partnerName        = "partner_name"
    case myName             = "my_name"
    case fcmToken           = "fcm_token"

    // Widget display state
    case hugLitUp           = "hug_lit_up"
    case kissLitUp          = "kiss_lit_up"
    case litUpUntil         = "lit_up_until"         // Date timestamp
    case litUpType          = "lit_up_type"          // "hug" | "kiss"

    // My haptic preferences
    case myHugDuration      = "my_hug_duration"      // seconds: 0.5 – 10.0
    case myHugIntensity     = "my_hug_intensity"     // 0.0 – 1.0
    case myHugPattern       = "my_hug_pattern"       // HapticPattern raw value
    case myKissDuration     = "my_kiss_duration"
    case myKissIntensity    = "my_kiss_intensity"
    case myKissPattern      = "my_kiss_pattern"

    // Sender confirmation haptic
    case confirmDuration    = "confirm_duration"     // seconds: 0.1 – 1.0
    case confirmIntensity   = "confirm_intensity"    // 0.0 – 1.0

    // Widget-initiated send (written by widget, cleared by app)
    case pendingAction      = "pending_action"       // "hug" | "kiss" | nil
}

public final class SharedDefaults {

    public static let appGroupID = "group.com.yourname.hugsandkisses"

    private static var store: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    // MARK: - Generic helpers

    public static func set<T>(_ value: T, for key: SharedDefaultsKey) {
        store.set(value, forKey: key.rawValue)
    }

    public static func string(for key: SharedDefaultsKey) -> String? {
        store.string(forKey: key.rawValue)
    }

    public static func bool(for key: SharedDefaultsKey) -> Bool {
        store.bool(forKey: key.rawValue)
    }

    public static func double(for key: SharedDefaultsKey, default def: Double = 0) -> Double {
        let v = store.double(forKey: key.rawValue)
        return v == 0 ? def : v
    }

    public static func date(for key: SharedDefaultsKey) -> Date? {
        store.object(forKey: key.rawValue) as? Date
    }

    // MARK: - Widget light-up helpers

    /// Call when a hug/kiss arrives to light up the widget for `duration` seconds.
    public static func activateLightUp(type: String, duration: Double) {
        let until = Date().addingTimeInterval(duration)
        set(true,   for: type == "hug" ? .hugLitUp  : .kissLitUp)
        set(type,   for: .litUpType)
        set(until,  for: .litUpUntil)
    }

    /// Returns true if the widget of `type` should currently be lit up.
    public static func isLitUp(type: String) -> Bool {
        let key: SharedDefaultsKey = type == "hug" ? .hugLitUp : .kissLitUp
        guard bool(for: key) else { return false }
        if let until = date(for: .litUpUntil), until > Date() {
            return true
        }
        // Expired — clean up
        set(false, for: key)
        return false
    }
}
