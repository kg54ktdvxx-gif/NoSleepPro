//
//  MenuBarView.swift
//  AwakeApp
//
//  Menu bar dropdown UI with modern, polished design
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var caffeinateManager: CaffeinateManager
    @State private var showDurationPicker = false
    @State private var showAbout = false
    @State private var aboutButtonHovered = false
    @State private var quitButtonHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with app name and toggle switch - Enhanced with gradient
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AwakeApp")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    if appState.isActive {
                        HStack(spacing: 6) {
                            // Pulsing green indicator dot
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                                        .scaleEffect(1.5)
                                        .opacity(0)
                                        .animation(
                                            Animation.easeInOut(duration: 1.5)
                                                .repeatForever(autoreverses: false),
                                            value: appState.isActive
                                        )
                                )
                            Text("Active")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Inactive")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { appState.isActive },
                    set: { newValue in
                        if newValue {
                            // Default to last preset or indefinite
                            activate(with: appState.currentPreset ?? .indefinite)
                        } else {
                            deactivate()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(1.1)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(nsColor: .controlBackgroundColor).opacity(0.6),
                        Color(nsColor: .controlBackgroundColor).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Error display if something went wrong
            if let error = caffeinateManager.lastError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)

                    Text(error.localizedDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
            }

            // Timer display when active
            if appState.isActive, let remaining = appState.remainingSeconds {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)

                    Text(formatTime(remaining))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("remaining")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.08))
            }

            Divider()
                .padding(.vertical, 4)

            // Duration section
            VStack(alignment: .leading, spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showDurationPicker.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text("Duration")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: showDurationPicker ? "chevron.down" : "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if showDurationPicker {
                    // Duration picker grid with fade-in animation
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            DurationButton(
                                preset: .fifteenMinutes,
                                isSelected: appState.currentPreset == .fifteenMinutes,
                                action: { activate(with: .fifteenMinutes) }
                            )
                            DurationButton(
                                preset: .thirtyMinutes,
                                isSelected: appState.currentPreset == .thirtyMinutes,
                                action: { activate(with: .thirtyMinutes) }
                            )
                            DurationButton(
                                preset: .oneHour,
                                isSelected: appState.currentPreset == .oneHour,
                                action: { activate(with: .oneHour) }
                            )
                        }

                        HStack(spacing: 12) {
                            DurationButton(
                                preset: .twoHours,
                                isSelected: appState.currentPreset == .twoHours,
                                action: { activate(with: .twoHours) }
                            )
                            DurationButton(
                                preset: .fiveHours,
                                isSelected: appState.currentPreset == .fiveHours,
                                action: { activate(with: .fiveHours) }
                            )
                            DurationButton(
                                preset: .indefinite,
                                isSelected: appState.currentPreset == .indefinite,
                                action: { activate(with: .indefinite) }
                            )
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        )
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()
                .padding(.vertical, 4)

            // Quick actions
            if appState.isActive {
                Button(action: {
                    deactivate()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 24)

                        Text("Stop Timer")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.05))
                .contentShape(Rectangle())

                Divider()
                    .padding(.vertical, 4)
            }

            // About button with hover state
            Button(action: {
                showAbout = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    Text("About")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(aboutButtonHovered ? Color.gray.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onHover { isHovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    aboutButtonHovered = isHovering
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Quit button with hover state
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    Text("Quit AwakeApp")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("⌘Q")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(quitButtonHovered ? Color.gray.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onHover { isHovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    quitButtonHovered = isHovering
                }
            }
            .keyboardShortcut("q")
        }
        .frame(width: 340)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    /// Format remaining seconds as HH:MM:SS or MM:SS
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    /// Activate sleep prevention with a preset
    private func activate(with preset: TimerPreset) {
        appState.activate(with: preset)
        caffeinateManager.start(duration: preset.seconds)
    }

    /// Deactivate sleep prevention
    private func deactivate() {
        appState.deactivate()
        caffeinateManager.stop()
    }
}

// Custom duration button component with enhanced interactions
struct DurationButton: View {
    let preset: TimerPreset
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            VStack(spacing: 6) {
                // Icon or number
                if preset == .indefinite {
                    Image(systemName: "infinity")
                        .font(.system(size: 22, weight: .semibold))
                } else {
                    Text(shortLabel)
                        .font(.system(size: 22, weight: .bold))
                }

                Text(subLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(backgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2.5 : 1.5)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.96 : (isHovering ? 1.02 : 1.0))
            .brightness(isHovering && !isSelected ? 0.05 : 0)
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var shortLabel: String {
        switch preset {
        case .fifteenMinutes: return "15"
        case .thirtyMinutes: return "30"
        case .oneHour: return "1"
        case .twoHours: return "2"
        case .fiveHours: return "5"
        case .indefinite: return "∞"
        }
    }

    private var subLabel: String {
        switch preset {
        case .fifteenMinutes, .thirtyMinutes: return "minutes"
        case .oneHour, .twoHours, .fiveHours: return "hours"
        case .indefinite: return "forever"
        }
    }

    private var backgroundGradient: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(
                isSelected
                    ? LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color(nsColor: .controlBackgroundColor), Color(nsColor: .controlBackgroundColor)], startPoint: .top, endPoint: .bottom)
            )
    }

    private var borderColor: Color {
        if isSelected {
            return Color.blue.opacity(0.5)
        } else if isHovering {
            return Color.gray.opacity(0.4)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

// Custom button style for press effect
struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = newValue
                }
            }
    }
}

// Preview for development
#Preview {
    MenuBarView()
        .environmentObject(AppState())
        .environmentObject(CaffeinateManager())
}
