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
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var automationManager: AutomationManager

    @State private var showDurationPicker = false
    @State private var showCustomDuration = false
    @State private var customMinutes: String = ""
    @State private var aboutButtonHovered = false
    @State private var settingsButtonHovered = false
    @State private var quitButtonHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with app name and toggle switch
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AwakeApp")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)

                    statusSubtitle
                }

                Spacer()

                // Custom styled power button
                Button(action: {
                    if appState.isActive {
                        deactivate()
                    } else {
                        activate(with: appState.currentPreset ?? .indefinite)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: appState.isActive ? "stop.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(appState.isActive ? "ON" : "OFF")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(appState.isActive
                                ? LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom))
                    )
                    .shadow(color: appState.isActive ? Color.green.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
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

            // Error display
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

            // Battery warning
            if automationManager.stoppedByBattery {
                HStack(spacing: 10) {
                    Image(systemName: "battery.25")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)

                    Text("Stopped to preserve battery")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
            }

            // Automation status display
            if let reason = caffeinateManager.activationReason, reason != .manual {
                HStack(spacing: 10) {
                    Image(systemName: automationIcon(for: reason))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.purple)

                    Text(automationText(for: reason))
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("Auto")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(6)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.purple.opacity(0.08))
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
            } else if appState.isActive {
                // Indefinite mode indicator
                HStack(spacing: 10) {
                    Image(systemName: "infinity")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)

                    Text("Running indefinitely")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)

                    Spacer()
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

                        // Custom duration button
                        Button(action: {
                            customMinutes = String(settings.lastCustomDurationMinutes)
                            showCustomDuration = true
                        }) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Custom duration...")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
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

            // Stop button when active
            if appState.isActive {
                Button(action: { deactivate() }) {
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

            // Settings button
            Button(action: { WindowManager.shared.openSettings() }) {
                HStack(spacing: 10) {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    Text("Settings")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("⌘,")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(settingsButtonHovered ? Color.gray.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
            .onHover { isHovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    settingsButtonHovered = isHovering
                }
            }
            .keyboardShortcut(",", modifiers: .command)

            // About button
            Button(action: { WindowManager.shared.openAbout() }) {
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

            // Quit button
            Button(action: { NSApplication.shared.terminate(nil) }) {
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
        .sheet(isPresented: $showCustomDuration) {
            CustomDurationSheet(
                customMinutes: $customMinutes,
                onActivate: { minutes in
                    settings.lastCustomDurationMinutes = minutes
                    activate(with: .custom(minutes: minutes))
                }
            )
        }
        .onAppear {
            automationManager.startMonitoring()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusSubtitle: some View {
        if appState.isActive {
            HStack(spacing: 6) {
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

    // MARK: - Helpers

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

    private func activate(with preset: TimerPreset) {
        appState.activate(with: preset)
        caffeinateManager.start(
            duration: preset.seconds,
            allowDisplaySleep: settings.allowDisplaySleep,
            reason: .manual
        )
        automationManager.onAppStateChanged()
    }

    private func deactivate() {
        appState.deactivate()
        caffeinateManager.stop()
        automationManager.onAppStateChanged()
    }

    private func automationIcon(for reason: ActivationReason) -> String {
        switch reason {
        case .manual: return "hand.tap"
        case .schedule: return "calendar"
        case .appTrigger: return "app.badge"
        case .keyboardShortcut: return "keyboard"
        case .wifiTrigger: return "wifi"
        case .hardwareTrigger: return "cable.connector"
        }
    }

    private func automationText(for reason: ActivationReason) -> String {
        switch reason {
        case .manual: return "Manual activation"
        case .schedule: return "Activated by schedule"
        case .appTrigger(let appName): return "Triggered by \(appName)"
        case .keyboardShortcut: return "Activated via shortcut"
        case .wifiTrigger(let ssid): return "Connected to \(ssid)"
        case .hardwareTrigger(let type): return "\(type) detected"
        }
    }
}

// MARK: - Custom Duration Sheet

struct CustomDurationSheet: View {
    @Binding var customMinutes: String
    let onActivate: (Int) -> Void
    @Environment(\.dismiss) var dismiss
    @FocusState private var isFocused: Bool

    var parsedMinutes: Int? {
        Int(customMinutes)
    }

    var isValid: Bool {
        guard let minutes = parsedMinutes else { return false }
        return minutes > 0 && minutes <= 1440 // Max 24 hours
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Custom Duration")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Minutes", text: $customMinutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .focused($isFocused)
                        .onSubmit {
                            if isValid, let minutes = parsedMinutes {
                                onActivate(minutes)
                                dismiss()
                            }
                        }

                    Text("minutes")
                        .foregroundColor(.secondary)
                }

                if let minutes = parsedMinutes, isValid {
                    Text(formatDuration(minutes))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !customMinutes.isEmpty {
                    Text("Enter 1-1440 minutes")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Quick presets
            HStack(spacing: 12) {
                QuickPresetButton(label: "45m", action: { customMinutes = "45" })
                QuickPresetButton(label: "90m", action: { customMinutes = "90" })
                QuickPresetButton(label: "3h", action: { customMinutes = "180" })
                QuickPresetButton(label: "8h", action: { customMinutes = "480" })
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Start") {
                    if let minutes = parsedMinutes {
                        onActivate(minutes)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 280, height: 220)
        .onAppear {
            isFocused = true
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(mins) minute\(mins == 1 ? "" : "s")"
        }
    }
}

struct QuickPresetButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Duration Button

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
        case .custom(let minutes):
            if minutes >= 60 {
                return "\(minutes / 60)"
            } else {
                return "\(minutes)"
            }
        }
    }

    private var subLabel: String {
        switch preset {
        case .fifteenMinutes, .thirtyMinutes: return "minutes"
        case .oneHour, .twoHours, .fiveHours: return "hours"
        case .indefinite: return "forever"
        case .custom(let minutes):
            return minutes >= 60 ? "hours" : "minutes"
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

// MARK: - Button Style

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

// MARK: - Preview

#Preview {
    MenuBarView()
        .environmentObject(AppState())
        .environmentObject(CaffeinateManager())
        .environmentObject(AppSettings.shared)
        .environmentObject(AutomationManager(
            settings: AppSettings.shared,
            appState: AppState(),
            caffeinateManager: CaffeinateManager()
        ))
}
