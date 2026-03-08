// HapticService.swift
// CoreHaptics engine – plays custom patterns for send confirmation and receive

import CoreHaptics
import UIKit

@MainActor
public final class HapticService {

    public static let shared = HapticService()

    private var engine: CHHapticEngine?
    private var isEngineRunning = false

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        prepareEngine()
    }

    // MARK: - Engine lifecycle

    private func prepareEngine() {
        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in self?.prepareEngine() }
            }
            engine?.stoppedHandler = { [weak self] _ in
                self?.isEngineRunning = false
            }
            try engine?.start()
            isEngineRunning = true
        } catch {
            print("[HapticService] Engine init failed: \(error)")
        }
    }

    private func ensureRunning() async {
        guard let engine else { return }
        if !isEngineRunning {
            do {
                try await engine.start()
                isEngineRunning = true
            } catch {
                print("[HapticService] Restart failed: \(error)")
            }
        }
    }

    // MARK: - Public API

    /// Short confirmation tap played on the SENDER's phone when they tap a button.
    public func playConfirmation(duration: Double = 0.25, intensity: Float = 0.6) async {
        await ensureRunning()
        guard let engine else { fallbackVibrate(); return }

        do {
            let events: [CHHapticEvent] = [
                CHHapticEvent(eventType: .hapticTransient,
                              parameters: [
                                  CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                  CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                              ],
                              relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient,
                              parameters: [
                                  CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.5),
                                  CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                              ],
                              relativeTime: 0.1)
            ]
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[HapticService] Confirmation failed: \(error)")
        }
    }

    /// Plays the chosen pattern on the RECIPIENT's phone.
    public func play(pattern: HapticPattern,
                     duration: Double,
                     intensity: Float) async {
        await ensureRunning()
        guard let engine else { fallbackVibrate(); return }

        do {
            let events = pattern.events(duration: duration, intensity: intensity)
            guard !events.isEmpty else { return }

            // Dynamic parameter curve: fade out over last 20% of duration
            let fadeStart = duration * 0.8
            let fadeParam = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0,         value: 1.0),
                    CHHapticParameterCurve.ControlPoint(relativeTime: fadeStart, value: 1.0),
                    CHHapticParameterCurve.ControlPoint(relativeTime: duration,  value: 0.0)
                ],
                relativeTime: 0)

            let hapticPattern = try CHHapticPattern(events: events,
                                                    parameterCurves: [fadeParam])
            let player = try engine.makeAdvancedPlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[HapticService] Play failed: \(error)")
            fallbackVibrate()
        }
    }

    /// Stop any in-progress haptic immediately.
    public func stop() {
        engine?.stop()
        isEngineRunning = false
    }

    // MARK: - Fallback for older devices

    private func fallbackVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

// CoreAudio import for fallback
import AudioToolbox
