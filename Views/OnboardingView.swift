// OnboardingView.swift
// First-run screen: enter your name → choose Create or Join

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var name: String = ""
    @State private var showPairing = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(spacing: 36) {
                    Spacer(minLength: 60)

                    // Logo / brand
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [HKColor.roseGold.opacity(0.5), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                                .blur(radius: 20)

                            Text("🤗💋")
                                .font(.system(size: 72))
                                .shadow(color: HKColor.deepRose.opacity(0.6), radius: 12, y: 6)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        VStack(spacing: 6) {
                            Text("Hugs & Kisses")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [HKColor.warmWhite, HKColor.roseGold],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: HKColor.deepRose.opacity(0.4), radius: 8)

                            Text("Stay close, no matter the distance")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(logoOpacity)
                    }

                    // Name entry card
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Your Name", systemImage: "person.fill.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HKColor.roseGold)

                        TextField("e.g. Emma", text: $name)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(HKColor.roseGold.opacity(0.4), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .font(.body.weight(.medium))
                    }
                    .padding(24)
                    .glassCard()
                    .padding(.horizontal, 24)

                    // CTA buttons
                    VStack(spacing: 14) {
                        PrimaryButton(title: "Get Started",
                                      systemImage: "heart.fill",
                                      disabled: name.trimmingCharacters(in: .whitespaces).isEmpty) {
                            appState.myName = name.trimmingCharacters(in: .whitespaces)
                            SharedDefaults.set(appState.myName, for: .myName)
                            showPairing = true
                        }

                        Text("You'll pair with your partner on the next screen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showPairing) {
            PairingView()
                .environmentObject(appState)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

// MARK: - Shared primary button

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [HKColor.deepRose, HKColor.roseGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: HKColor.deepRose.opacity(0.5), radius: 12, y: 6)
            )
            .foregroundStyle(.white)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: disabled)
    }
}
