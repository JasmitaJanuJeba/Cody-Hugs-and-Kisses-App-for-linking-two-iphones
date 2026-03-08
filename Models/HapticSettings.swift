// HapticSettings.swift
// Haptic pattern definitions and per-user settings model

import Foundation
import CoreHaptics

// MARK: - Haptic Pattern Enum

/// The selectable vibration styles shown in the app's settings screen.
public enum HapticPattern: String, CaseIterable, Identifiable, Codable {
    case gentle     = "gentle"      // slow soft waves  – perfect for a tender hug
    case heartbeat  = "heartbeat"   // ba-dum ba-dum
    case pulse      = "pulse"       // quick rhythmic pulses
    case butterfly  = "butterfly"   // rapid light flutters  – a kiss
    case longing    = "longing"     // one long sustained throb

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gentle:    return "Gentle Wave"
        case .heartbeat: return "Heartbeat"
        case .pulse:     return "Love Pulse"
        case .butterfly: return "Butterfly Kiss"
        case .longing:   return "Longing"
        }
    }

    public var emoji: String {
        switch self {
        case .gentle:    return "🌊"
        case .heartbeat: return "💓"
        case .pulse:     return "💞"
        case .butterfly: return "🦋"
        case .longing:   return "💗"
        }
    }

    public var description: String {
        switch self {
        case .gentle:    return "Soft, rolling waves of warmth"
        case .heartbeat: return "Feels like a heartbeat next to yours"
        case .pulse:     return "Quick rhythmic pulses of love"
        case .butterfly: return "Light fluttering – like a soft kiss"
        case .longing:   return "One deep, sustained embrace"
        }
    }

    // MARK: CoreHaptics event list

    /// Returns a list of CHHapticEvent objects scaled to [0,1] time.
    /// The caller should stretch them across the user-chosen `duration`.
    public func events(duration: Double, intensity: Float) -> [CHHapticEvent] {
        switch self {
        case .gentle:
            return gentleEvents(duration: duration, intensity: intensity)
        case .heartbeat:
            return heartbeatEvents(duration: duration, intensity: intensity)
        case .pulse:
            return pulseEvents(duration: duration, intensity: intensity)
        case .butterfly:
            return butterflyEvents(duration: duration, intensity: intensity)
        case .longing:
            return longingEvents(duration: duration, intensity: intensity)
        }
    }

    // MARK: - Pattern builders

    private func gentleEvents(duration: Double, intensity: Float) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        let count = max(3, Int(duration / 0.6))
        for i in 0..<count {
            let t = duration * Double(i) / Double(count)
            let fade = Float(sin(Double.pi * Double(i) / Double(count))) // envelope
            let params = [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * fade),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ]
            events.append(CHHapticEvent(eventType: .hapticContinuous,
                                        parameters: params,
                                        relativeTime: t,
                                        duration: 0.5))
        }
        return events
    }

    private func heartbeatEvents(duration: Double, intensity: Float) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        var t = 0.0
        while t < duration - 0.2 {
            // First beat
            events.append(CHHapticEvent(eventType: .hapticTransient,
                                        parameters: [
                                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                                        ],
                                        relativeTime: t))
            // Second beat (slightly softer)
            events.append(CHHapticEvent(eventType: .hapticTransient,
                                        parameters: [
                                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.7),
                                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                                        ],
                                        relativeTime: t + 0.15))
            t += 0.85  // heartbeat period ~70 bpm
        }
        return events
    }

    private func pulseEvents(duration: Double, intensity: Float) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        let interval = 0.3
        var t = 0.0
        while t < duration {
            events.append(CHHapticEvent(eventType: .hapticTransient,
                                        parameters: [
                                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                                        ],
                                        relativeTime: t))
            t += interval
        }
        return events
    }

    private func butterflyEvents(duration: Double, intensity: Float) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        // Flutter: 5 rapid light taps then a pause, repeat
        let flutterCount = 5
        let flutterInterval = 0.07
        let pauseAfter = 0.4
        var t = 0.0
        while t < duration {
            for k in 0..<flutterCount {
                let tapped = t + Double(k) * flutterInterval
                if tapped >= duration { break }
                events.append(CHHapticEvent(eventType: .hapticTransient,
                                            parameters: [
                                                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.5),
                                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                                            ],
                                            relativeTime: tapped))
            }
            t += Double(flutterCount) * flutterInterval + pauseAfter
        }
        return events
    }

    private func longingEvents(duration: Double, intensity: Float) -> [CHHapticEvent] {
        // One long sustained vibration with a ramp up and ramp down
        return [
            CHHapticEvent(eventType: .hapticContinuous,
                          parameters: [
                              CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                              CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                          ],
                          relativeTime: 0,
                          duration: duration)
        ]
    }
}

// MARK: - Per-user settings

public struct UserHapticSettings: Codable {
    // --- Hug ---
    public var hugDuration:  Double        = 3.0
    public var hugIntensity: Double        = 0.8
    public var hugPattern:   HapticPattern = .heartbeat

    // --- Kiss ---
    public var kissDuration:  Double        = 2.0
    public var kissIntensity: Double        = 0.7
    public var kissPattern:   HapticPattern = .butterfly

    // --- Sender confirmation (quick tap on sender's phone) ---
    public var confirmDuration:  Double = 0.25
    public var confirmIntensity: Double = 0.6

    // Persist to / restore from SharedDefaults
    public func save() {
        SharedDefaults.set(hugDuration,       for: .myHugDuration)
        SharedDefaults.set(hugIntensity,      for: .myHugIntensity)
        SharedDefaults.set(hugPattern.rawValue, for: .myHugPattern)
        SharedDefaults.set(kissDuration,      for: .myKissDuration)
        SharedDefaults.set(kissIntensity,     for: .myKissIntensity)
        SharedDefaults.set(kissPattern.rawValue, for: .myKissPattern)
        SharedDefaults.set(confirmDuration,   for: .confirmDuration)
        SharedDefaults.set(confirmIntensity,  for: .confirmIntensity)
    }

    public static func load() -> UserHapticSettings {
        var s = UserHapticSettings()
        s.hugDuration   = SharedDefaults.double(for: .myHugDuration,   default: 3.0)
        s.hugIntensity  = SharedDefaults.double(for: .myHugIntensity,  default: 0.8)
        s.hugPattern    = HapticPattern(rawValue: SharedDefaults.string(for: .myHugPattern) ?? "") ?? .heartbeat
        s.kissDuration  = SharedDefaults.double(for: .myKissDuration,  default: 2.0)
        s.kissIntensity = SharedDefaults.double(for: .myKissIntensity, default: 0.7)
        s.kissPattern   = HapticPattern(rawValue: SharedDefaults.string(for: .myKissPattern) ?? "") ?? .butterfly
        s.confirmDuration  = SharedDefaults.double(for: .confirmDuration,  default: 0.25)
        s.confirmIntensity = SharedDefaults.double(for: .confirmIntensity, default: 0.6)
        return s
    }
}
