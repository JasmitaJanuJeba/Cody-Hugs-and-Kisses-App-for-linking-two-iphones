// DashboardView.swift
// Main screen after pairing – shows the two big hug/kiss buttons + status

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @State private var sendFeedback: SendFeedback? = nil
    @State private var showParticles = false

    struct SendFeedback: Identifiable {
        let id = UUID()
        let type: String   // "hug" | "kiss"
        let success: Bool
    }

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            // Heart particles when sending
            HeartParticles(active: showParticles)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected with")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(appState.partnerName)
                            .font(.headline)
                            .foregroundStyle(HKColor.roseGold)
                    }
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                            .foregroundStyle(HKColor.roseGold.opacity(0.8))
                            .padding(10)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // MARK: Central content
                VStack(spacing: 40) {

                    // Partner receive-indicator banner
                    if appState.hugIsLit || appState.kissIsLit {
                        receivingBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Title
                    VStack(spacing: 8) {
                        Text("Send some love 💕")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Tap to send, \(appState.partnerName) will feel it")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // HUG & KISS buttons
                    HStack(spacing: 44) {
                        VStack(spacing: 12) {
                            LiquidGlassCircleButton(
                                emoji: "🤗",
                                label: "Hug",
                                isLit: appState.hugIsLit,
                                disabled: appState.isSending
                            ) { sendAction(type: "hug") }

                            Text("Hug")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(appState.hugIsLit ? HKColor.litPink : .white)
                        }

                        VStack(spacing: 12) {
                            LiquidGlassCircleButton(
                                emoji: "💋",
                                label: "Kiss",
                                isLit: appState.kissIsLit,
                                disabled: appState.isSending
                            ) { sendAction(type: "kiss") }

                            Text("Kiss")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(appState.kissIsLit ? HKColor.litPink : .white)
                        }
                    }

                    // Send status
                    if appState.isSending {
                        HStack(spacing: 8) {
                            ProgressView().tint(HKColor.roseGold).scaleEffect(0.8)
                            Text("Sending…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }

                Spacer()

                // MARK: Bottom hint
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.iphone")
                        Text("Add widgets to your Lock Screen")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))

                    Text("Hold Lock Screen → Customize → Bottom row")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                .padding(.bottom, 30)
            }

            // Feedback toast
            if let fb = sendFeedback {
                VStack {
                    Spacer()
                    toastView(fb)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                }
                .animation(.spring(), value: sendFeedback?.id)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(appState)
        }
        .onAppear {
            startMessageListener()
        }
        .onDisappear {
            FirebaseService.shared.removeListeners()
        }
    }

    // MARK: - Send action

    private func sendAction(type: String) {
        guard !appState.isSending, !appState.partnerUID.isEmpty else { return }

        appState.isSending = true

        // Sender confirmation haptic
        Task {
            await HapticService.shared.playConfirmation(
                duration: appState.hapticSettings.confirmDuration,
                intensity: Float(appState.hapticSettings.confirmIntensity)
            )
        }

        // Particles
        withAnimation { showParticles = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showParticles = false }
        }

        Task {
            do {
                try await FirebaseService.shared.send(
                    type: type,
                    senderUID: appState.myUID,
                    senderName: appState.myName,
                    recipientUID: appState.partnerUID,
                    settings: appState.hapticSettings
                )
                await MainActor.run {
                    appState.isSending = false
                    appState.lastSentType = type
                    withAnimation { sendFeedback = SendFeedback(type: type, success: true) }
                    dismissFeedback()
                }
            } catch {
                await MainActor.run {
                    appState.isSending = false
                    withAnimation { sendFeedback = SendFeedback(type: type, success: false) }
                    dismissFeedback()
                }
            }
        }
    }

    private func dismissFeedback() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { sendFeedback = nil }
        }
    }

    // MARK: - Message listener

    private func startMessageListener() {
        guard !appState.myUID.isEmpty else { return }
        FirebaseService.shared.listenForMessages(myUID: appState.myUID) { msg, _ in
            let pattern = HapticPattern(rawValue: msg.pattern) ?? .heartbeat
            Task { @MainActor in
                await HapticService.shared.play(
                    pattern: pattern,
                    duration: msg.duration,
                    intensity: Float(msg.intensity)
                )
                appState.activateLightUp(type: msg.type, duration: msg.duration)
            }
        }
    }

    // MARK: - Sub-views

    private var receivingBanner: some View {
        let type = appState.hugIsLit ? "hug" : "kiss"
        let emoji = type == "hug" ? "🤗" : "💋"
        return HStack(spacing: 10) {
            Text(emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.partnerName) sent you a \(type)!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Feel the vibration 💕")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .glassCard(tint: HKColor.litPink)
        .padding(.horizontal, 24)
    }

    private func toastView(_ fb: SendFeedback) -> some View {
        let emoji = fb.type == "hug" ? "🤗" : "💋"
        let msg   = fb.success
            ? "\(emoji) \(fb.type.capitalized) sent to \(appState.partnerName)!"
            : "Couldn't send right now. Try again."
        return Text(msg)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(fb.success ? HKColor.deepRose.opacity(0.9) : .red.opacity(0.8))
                    .shadow(radius: 12)
            )
    }
}
