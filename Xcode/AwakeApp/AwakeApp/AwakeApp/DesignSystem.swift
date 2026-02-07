//
//  DesignSystem.swift
//  AwakeApp
//
//  Liquid Glass design system for macOS 26+
//

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Active/Success state green
    static let awakeGreen = Color(red: 0.3, green: 0.85, blue: 0.4)

    /// Primary/Timer blue
    static let awakeBlue = Color(red: 0.2, green: 0.6, blue: 1.0)

    /// Warning orange
    static let awakeOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    /// Automation purple
    static let awakePurple = Color(red: 0.7, green: 0.3, blue: 0.9)
}

// MARK: - Depth Level

enum DepthLevel {
    case surface    // 4px shadow
    case raised     // 8px shadow
    case floating   // 16px shadow
    case overlay    // 30px shadow

    var shadowRadius: CGFloat {
        switch self {
        case .surface: return 4
        case .raised: return 8
        case .floating: return 16
        case .overlay: return 30
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .surface: return 2
        case .raised: return 4
        case .floating: return 8
        case .overlay: return 12
        }
    }
}

// MARK: - Liquid Glass View Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var depth: DepthLevel = .raised

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Border highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(
                color: Color.black.opacity(0.15),
                radius: depth.shadowRadius,
                x: 0,
                y: depth.shadowY
            )
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, depth: DepthLevel = .raised) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, depth: depth))
    }
}

// MARK: - Floating Card Modifier

struct FloatingCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 14
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func floatingCard(cornerRadius: CGFloat = 14, padding: CGFloat = 16) -> some View {
        modifier(FloatingCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Status Glow Modifier

struct StatusGlowModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(isPulsing ? 0.6 : 0.3) : Color.clear,
                radius: isPulsing ? 12 : 6,
                x: 0,
                y: 0
            )
            .onAppear {
                if isActive {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                } else {
                    isPulsing = false
                }
            }
    }
}

extension View {
    func statusGlow(color: Color, isActive: Bool) -> some View {
        modifier(StatusGlowModifier(color: color, isActive: isActive))
    }
}

// MARK: - Premium Button Style

struct PremiumButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let isActive: Bool

    init(
        colors: [Color] = [Color.awakeBlue, Color.awakeBlue.opacity(0.8)],
        isActive: Bool = true
    ) {
        self.gradient = LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
        self.isActive = isActive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(gradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: isActive ? Color.awakeBlue.opacity(0.4) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Power Toggle Button Style

struct PowerToggleButtonStyle: ButtonStyle {
    let isActive: Bool

    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isActive
                            ? LinearGradient(
                                colors: [Color.awakeGreen, Color.awakeGreen.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isActive ? Color.awakeGreen.opacity(0.5) : Color.gray.opacity(0.3),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isActive ? Color.awakeGreen.opacity(0.5) : Color.clear,
                radius: isHovering ? 12 : 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.95 : (isHovering ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

// MARK: - Enhanced Duration Button Style

struct EnhancedDurationButtonStyle: ButtonStyle {
    let isSelected: Bool
    let accentColor: Color

    @State private var isHovering = false

    init(isSelected: Bool, accentColor: Color = .awakeBlue) {
        self.isSelected = isSelected
        self.accentColor = accentColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                            : LinearGradient(
                                colors: [
                                    Color(nsColor: .controlBackgroundColor),
                                    Color(nsColor: .controlBackgroundColor).opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        isSelected
                            ? accentColor.opacity(0.6)
                            : (isHovering ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2)),
                        lineWidth: isSelected ? 2 : 1.5
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .shadow(
                color: isSelected ? accentColor.opacity(0.35) : Color.clear,
                radius: 10,
                x: 0,
                y: 5
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovering && !isSelected ? 1.02 : 1.0))
            .brightness(isHovering && !isSelected ? 0.03 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

// MARK: - Feature Card Style

struct FeatureCardView: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.12))
                )

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)

            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    let colors: [Color]

    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 5.0)
                .repeatForever(autoreverses: true)
            ) {
                animateGradient = true
            }
        }
    }
}
