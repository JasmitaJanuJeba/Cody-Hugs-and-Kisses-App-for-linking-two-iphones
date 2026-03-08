// PairingView.swift
// Two-flow pairing: generate QR (inviter) or enter code (joiner)

import SwiftUI

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pairing = PairingService()
    @Environment(\.dismiss) var dismiss

    @State private var mode: PairMode = .choose
    @State private var enteredCode: String = ""
    @FocusState private var codeFocused: Bool

    enum PairMode { case choose, create, join }

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    if mode != .choose {
                        Button {
                            mode = .choose
                            pairing.cancel()
                        } label: {
                            Image(systemName: "chevron.left")
                                .imageScale(.large)
                                .foregroundStyle(HKColor.roseGold)
                        }
                    }
                    Spacer()
                    Text("Pair with Partner")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    if mode == .choose {
                        Color.clear.frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    switch mode {
                    case .choose:  chooseView
                    case .create:  createView
                    case .join:    joinView
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        // Auto-dismiss on successful pair
        .onChange(of: pairing.state) { _, state in
            if state == .paired {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Choose mode

    var chooseView: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 50)

            Text("💕")
                .font(.system(size: 60))
                .shadow(color: HKColor.deepRose.opacity(0.5), radius: 10)

            VStack(spacing: 8) {
                Text("Link your phones")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("One person creates an invite,\nthe other scans or types the code.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 14) {
                PairOptionCard(
                    emoji: "📲",
                    title: "Create Invite",
                    subtitle: "Share a QR code with your partner"
                ) { mode = .create; pairing.startInvite(appState: appState) }

                PairOptionCard(
                    emoji: "🔑",
                    title: "Enter a Code",
                    subtitle: "Type the code your partner shared"
                ) { mode = .join }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 40)
        }
    }

    // MARK: - Create (QR) mode

    var createView: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            switch pairing.state {
            case .creatingInvite:
                ProgressView()
                    .tint(HKColor.roseGold)
                    .scaleEffect(1.5)
                Text("Creating invite…")
                    .foregroundStyle(.secondary)

            case .waitingForPartner:
                VStack(spacing: 20) {
                    Text("Show this to your partner")
                        .font(.headline)
                        .foregroundStyle(HKColor.roseGold)

                    // QR Code
                    if let qr = pairing.qrImage {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(16)
                            .glassCard(cornerRadius: 20)
                            .shadow(color: HKColor.roseGold.opacity(0.3), radius: 12)
                    }

                    // Text code
                    VStack(spacing: 6) {
                        Text("Or share this code")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(pairing.inviteCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .tracking(8)
                            .foregroundStyle(
                                LinearGradient(colors: [HKColor.roseGold, HKColor.warmWhite],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .shimmer()
                    }
                    .padding(20)
                    .glassCard()

                    // Share button
                    ShareLink(item: "Join me on Hugs & Kisses! Use code: \(pairing.inviteCode)") {
                        Label("Share Code", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(HKColor.deepRose.opacity(0.8)))
                    }

                    WaitingDotsView(text: "Waiting for your partner")
                }

            case .paired:
                pairedSuccessView

            default:
                EmptyView()
            }

            if let err = pairing.errorMessage {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Join (code) mode

    var joinView: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 50)

            Text("🔑")
                .font(.system(size: 56))

            Text("Enter Partner's Code")
                .font(.title3.bold())
                .foregroundStyle(.white)

            // Code input
            TextField("A B C 1 2 3", text: $enteredCode)
                .focused($codeFocused)
                .multilineTextAlignment(.center)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .tracking(8)
                .foregroundStyle(HKColor.roseGold)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .padding(20)
                .glassCard()
                .onChange(of: enteredCode) { _, v in
                    enteredCode = String(v.prefix(6)).uppercased()
                }
                .onAppear { codeFocused = true }

            if pairing.state == .joining {
                ProgressView()
                    .tint(HKColor.roseGold)
            } else {
                PrimaryButton(
                    title: "Join",
                    systemImage: "heart.fill",
                    disabled: enteredCode.count < 6
                ) {
                    pairing.joinWithCode(enteredCode, appState: appState)
                }
            }

            if pairing.state == .paired {
                pairedSuccessView
            }

            if let err = pairing.errorMessage {
                Text(err)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Success

    var pairedSuccessView: some View {
        VStack(spacing: 14) {
            Text("💞")
                .font(.system(size: 60))
                .transition(.scale.combined(with: .opacity))

            Text("You're connected!")
                .font(.title2.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [HKColor.roseGold, HKColor.warmWhite],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Text("Connected with \(appState.partnerName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .glassCard()
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Helper views

struct PairOptionCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji).font(.system(size: 36))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundStyle(.white)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(HKColor.roseGold.opacity(0.6))
            }
            .padding(20)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

struct WaitingDotsView: View {
    let text: String
    @State private var dotCount = 1

    var body: some View {
        Text(text + String(repeating: ".", count: dotCount))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                    dotCount = (dotCount % 3) + 1
                }
            }
    }
}
