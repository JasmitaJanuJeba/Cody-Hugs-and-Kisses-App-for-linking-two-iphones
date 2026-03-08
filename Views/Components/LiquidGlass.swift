// LiquidGlass.swift
// Reusable liquid-glass art-style components matching iOS 26 aesthetic

import SwiftUI

// MARK: - Design tokens

public enum HKColor {
    public static let roseGold   = Color(red: 1.00, green: 0.76, blue: 0.80)   // #FFC2CC
    public static let blush      = Color(red: 1.00, green: 0.88, blue: 0.90)   // #FFE0E6
    public static let deepRose   = Color(red: 0.90, green: 0.35, blue: 0.55)   // #E6598C
    public static let softPink   = Color(red: 1.00, green: 0.72, blue: 0.77)   // #FFB8C4
    public static let litPink    = Color(red: 1.00, green: 0.41, blue: 0.61)   // #FF69B3 – widget lit
    public static let warmWhite  = Color(red: 1.00, green: 0.97, blue: 0.97)
}

// MARK: - Liquid glass background gradient

struct LiquidGlassBackground: View {
    var animated: Bool = true
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30, paused: !animated)) { timeline in
            let t = animated ? timeline.date.timeIntervalSinceReferenceDate : 0
            ZStack {
                // Deep gradient base
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.02, blue: 0.12),
                        Color(red: 0.25, green: 0.05, blue: 0.20),
                        Color(red: 0.35, green: 0.08, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Floating blobs
                ForEach(0..<4) { i in
                    let offset = Double(i) * .pi / 2
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    HKColor.roseGold.opacity(0.35),
                                    HKColor.deepRose.opacity(0.10),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)
                        .offset(
                            x: CGFloat(sin(t * 0.3 + offset)) * 120,
                            y: CGFloat(cos(t * 0.2 + offset)) * 100
                        )
                        .blur(radius: 60)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass card modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 28
    var tint: Color = HKColor.roseGold

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.20), tint.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [HKColor.warmWhite.opacity(0.55),
                                             HKColor.roseGold.opacity(0.20)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 28, tint: Color = HKColor.roseGold) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, tint: tint))
    }
}

// MARK: - Liquid glass circle button (main hug / kiss button)

struct LiquidGlassCircleButton: View {
    let emoji: String
    let label: String
    let isLit: Bool
    var disabled: Bool = false
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var shimmerPhase: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            ZStack {
                // Outer glow when lit
                if isLit {
                    Circle()
                        .fill(HKColor.litPink.opacity(0.4))
                        .blur(radius: 20)
                        .scaleEffect(pulseScale)
                }

                // Glass circle body
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isLit
                                        ? [HKColor.litPink.opacity(0.70),
                                           HKColor.deepRose.opacity(0.50)]
                                        : [HKColor.roseGold.opacity(0.40),
                                           HKColor.blush.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        // Inner specular highlight
                        Ellipse()
                            .fill(
                                LinearGradient(
                                    colors: [HKColor.warmWhite.opacity(0.65), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .padding(8)
                            .offset(x: -4, y: -6)
                    )
                    .overlay(
                        // Border
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: isLit
                                        ? [HKColor.litPink, HKColor.warmWhite.opacity(0.6)]
                                        : [HKColor.warmWhite.opacity(0.6), HKColor.roseGold.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isLit ? 2 : 1
                            )
                    )
                    .shadow(color: isLit
                            ? HKColor.litPink.opacity(0.6)
                            : HKColor.roseGold.opacity(0.25),
                            radius: isLit ? 20 : 10,
                            x: 0, y: 4)

                // Emoji
                Text(emoji)
                    .font(.system(size: 38))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            .frame(width: 110, height: 110)
            .scaleEffect(isPressed ? 0.88 : 1.0)
            .opacity(disabled ? 0.45 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onAppear { startPulseIfNeeded() }
        .onChange(of: isLit) { _, newVal in
            if newVal { startPulse() } else { stopPulse() }
        }
    }

    private func startPulseIfNeeded() {
        if isLit { startPulse() }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseScale = 1.18
        }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.4)) {
            pulseScale = 1.0
        }
    }
}

// MARK: - Haptic slider row

struct HapticSliderRow: View {
    let title: String
    let icon: String
    let valueLabel: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HKColor.roseGold)
                Spacer()
                Text(valueLabel)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step > 0 ? step : (range.upperBound - range.lowerBound) / 100)
                .tint(HKColor.deepRose)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Shimmer modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: phase * geo.size.width * 1.5)
                    .blendMode(.overlay)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}

// MARK: - Custom heart particle emitter (decorative)

struct HeartParticles: View {
    @State private var particles: [HeartParticle] = []
    let active: Bool

    struct HeartParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var symbol: String
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Text(p.symbol)
                        .font(.system(size: 18 * p.scale))
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear { if active { emit(in: geo.size) } }
            .onChange(of: active) { _, newVal in
                if newVal { emit(in: geo.size) }
            }
        }
        .allowsHitTesting(false)
    }

    private func emit(in size: CGSize) {
        let symbols = ["❤️","💕","💗","💓","✨","💖"]
        for i in 0..<12 {
            let delay = Double(i) * 0.08
            let p = HeartParticle(
                x: CGFloat.random(in: size.width * 0.2 ... size.width * 0.8),
                y: size.height * 0.6,
                scale: CGFloat.random(in: 0.6...1.4),
                opacity: 1,
                symbol: symbols.randomElement()!
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                particles.append(p)
                guard let idx = particles.firstIndex(where: { $0.id == p.id }) else { return }
                withAnimation(.easeOut(duration: 1.4)) {
                    particles[idx].y -= CGFloat.random(in: 120...220)
                    particles[idx].x += CGFloat.random(in: -40...40)
                    particles[idx].opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    particles.removeAll { $0.id == p.id }
                }
            }
        }
    }
}
