// SettingsView.swift
// Adjust haptic preferences independently for hug and kiss

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var settings: UserHapticSettings = UserHapticSettings.load()
    @State private var showUnpairAlert = false
    @State private var previewingPattern: HapticPattern? = nil

    var body: some View {
        ZStack {
            LiquidGlassBackground(animated: false)

            NavigationStack {
                ScrollView {
                    VStack(spacing: 22) {

                        // MARK: Partner info card
                        partnerCard

                        // MARK: Hug settings
                        hapticCard(
                            title: "When you receive a Hug",
                            emoji: "🤗",
                            durationBinding: $settings.hugDuration,
                            intensityBinding: $settings.hugIntensity,
                            patternBinding: $settings.hugPattern
                        )

                        // MARK: Kiss settings
                        hapticCard(
                            title: "When you receive a Kiss",
                            emoji: "💋",
                            durationBinding: $settings.kissDuration,
                            intensityBinding: $settings.kissIntensity,
                            patternBinding: $settings.kissPattern
                        )

                        // MARK: Confirmation haptic
                        confirmCard

                        // MARK: Danger zone
                        dangerCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(HKColor.roseGold)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            appState.hapticSettings = settings
                            settings.save()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(HKColor.deepRose)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Unpair?", isPresented: $showUnpairAlert) {
            Button("Unpair", role: .destructive) {
                appState.unpair()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will disconnect you from \(appState.partnerName). You can pair again at any time.")
        }
    }

    // MARK: - Partner card

    private var partnerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(HKColor.roseGold.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text("💞")
                    .font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Connected with")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(appState.partnerName)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundStyle(HKColor.deepRose)
                .imageScale(.large)
        }
        .padding(18)
        .glassCard()
    }

    // MARK: - Haptic card builder

    @ViewBuilder
    private func hapticCard(
        title: String,
        emoji: String,
        durationBinding: Binding<Double>,
        intensityBinding: Binding<Double>,
        patternBinding: Binding<HapticPattern>
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(emoji).font(.title2)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(HKColor.roseGold)
            }

            // Duration
            HapticSliderRow(
                title: "Duration",
                icon: "clock",
                valueLabel: String(format: "%.1fs", durationBinding.wrappedValue),
                value: durationBinding,
                range: 0.5...10.0,
                step: 0.5
            )

            // Intensity
            HapticSliderRow(
                title: "Intensity",
                icon: "waveform",
                valueLabel: String(format: "%.0f%%", intensityBinding.wrappedValue * 100),
                value: intensityBinding,
                range: 0.1...1.0
            )

            Divider().overlay(HKColor.roseGold.opacity(0.2))

            // Vibration pattern picker
            VStack(alignment: .leading, spacing: 10) {
                Label("Vibration Style", systemImage: "hand.tap")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HKColor.roseGold)

                ForEach(HapticPattern.allCases) { pattern in
                    PatternRow(
                        pattern: pattern,
                        isSelected: patternBinding.wrappedValue == pattern,
                        isPreviewing: previewingPattern == pattern
                    ) {
                        patternBinding.wrappedValue = pattern
                    } onPreview: {
                        previewPattern(pattern,
                                       duration: durationBinding.wrappedValue,
                                       intensity: Float(intensityBinding.wrappedValue))
                    }
                }
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Confirmation card

    private var confirmCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Button Press Confirmation", systemImage: "iphone.radiowaves.left.and.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(HKColor.roseGold)

            Text("Quick tap you feel when you press Hug or Kiss.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HapticSliderRow(
                title: "Duration",
                icon: "clock",
                valueLabel: String(format: "%.2fs", settings.confirmDuration),
                value: $settings.confirmDuration,
                range: 0.05...1.0
            )
            HapticSliderRow(
                title: "Intensity",
                icon: "waveform",
                valueLabel: String(format: "%.0f%%", settings.confirmIntensity * 100),
                value: $settings.confirmIntensity,
                range: 0.1...1.0
            )

            Button {
                Task {
                    await HapticService.shared.playConfirmation(
                        duration: settings.confirmDuration,
                        intensity: Float(settings.confirmIntensity)
                    )
                }
            } label: {
                Label("Preview", systemImage: "play.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(HKColor.deepRose.opacity(0.7)))
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Danger card

    private var dangerCard: some View {
        Button { showUnpairAlert = true } label: {
            HStack {
                Image(systemName: "link.badge.minus")
                Text("Unpair from \(appState.partnerName)")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(16)
            .glassCard(tint: .red)
        }
    }

    // MARK: - Pattern preview

    private func previewPattern(_ pattern: HapticPattern, duration: Double, intensity: Float) {
        previewingPattern = pattern
        Task {
            await HapticService.shared.play(pattern: pattern,
                                            duration: min(duration, 3.0),   // cap preview at 3 s
                                            intensity: intensity)
            await MainActor.run { previewingPattern = nil }
        }
    }
}

// MARK: - Pattern row

struct PatternRow: View {
    let pattern: HapticPattern
    let isSelected: Bool
    let isPreviewing: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Select radio
            Button(action: onSelect) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? HKColor.deepRose : HKColor.roseGold.opacity(0.4),
                                      lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(HKColor.deepRose)
                            .frame(width: 13, height: 13)
                    }
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(pattern.emoji)
                    Text(pattern.displayName)
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? HKColor.roseGold : .white)
                }
                Text(pattern.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Preview button
            Button(action: onPreview) {
                Image(systemName: isPreviewing ? "stop.fill" : "play.fill")
                    .imageScale(.small)
                    .foregroundStyle(HKColor.roseGold)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(.ultraThinMaterial))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}
