//
//  MenuBarView.swift
//  AwakeApp
//
//  Menu bar dropdown UI with Liquid Glass design
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
            // Header with app name and toggle switch - Liquid Glass style
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("No Sleep Pro")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        if appState.isActive {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.awakeGreen)
                                .symbolEffect(.pulse)
                        }
                    }

                    statusSubtitle
                }

                Spacer()

                // Premium gradient power button with glow
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
                }
                .buttonStyle(PowerToggleButtonStyle(isActive: appState.isActive))
                .accessibilityLabel(appState.isActive ? "Stop sleep prevention" : "Start sleep prevention")
                .accessibilityHint("Double tap to toggle")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .liquidGlass(cornerRadius: 0, depth: .surface)

            // Error display
            if let error = caffeinateManager.lastError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.awakeOrange)

                    Text(error.localizedDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.awakeOrange.opacity(0.1))
            }

            // Battery warning
            if automationManager.stoppedByBattery {
                HStack(spacing: 10) {
                    Image(systemName: "battery.25")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .symbolEffect(.pulse)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stopped to preserve battery")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Text("Plug in to continue")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.08))
            }

            // Automation status display
            if let reason = caffeinateManager.activationReason, reason != .manual {
                HStack(spacing: 10) {
                    Image(systemName: automationIcon(for: reason))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.awakePurple)
                        .symbolEffect(.pulse)

                    Text(automationText(for: reason))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("Auto")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.awakePurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.awakePurple.opacity(0.15))
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.awakePurple.opacity(0.06))
            }

            // Timer display when active - using CircularTimerView
            if appState.isActive, let remaining = appState.remainingSeconds,
               let totalSeconds = appState.currentPreset?.seconds {
                HStack(spacing: 16) {
                    CompactCircularTimerView(
                        remainingSeconds: remaining,
                        totalSeconds: totalSeconds,
                        size: 56
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTime(remaining))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.primary)

                        Text("remaining")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.awakeBlue.opacity(0.08))
            } else if appState.isActive {
                // Indefinite mode indicator with animation
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.awakeBlue.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "infinity")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.awakeBlue)
                            .symbolEffect(.pulse)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Running indefinitely")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("No time limit set")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.awakeBlue.opacity(0.08))
            }

            Divider()
                .padding(.vertical, 4)

            // Duration section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.awakeBlue)
                        .frame(width: 24)

                    Text("Duration")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: showDurationPicker ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.15), value: showDurationPicker)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showDurationPicker.toggle()
                    }
                }

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

                        // Custom duration toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if !showCustomDuration {
                                    customMinutes = String(settings.lastCustomDurationMinutes)
                                }
                                showCustomDuration.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showCustomDuration ? "chevron.down" : "slider.horizontal.3")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Custom duration...")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        // Inline custom duration picker
                        if showCustomDuration {
                            VStack(spacing: 12) {
                                HStack {
                                    TextField("Minutes", text: $customMinutes)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                        .onSubmit {
                                            if let minutes = Int(customMinutes), minutes > 0, minutes <= 1440 {
                                                settings.lastCustomDurationMinutes = minutes
                                                activate(with: .custom(minutes: minutes))
                                                showCustomDuration = false
                                            }
                                        }

                                    Text("minutes")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button("Start") {
                                        if let minutes = Int(customMinutes), minutes > 0, minutes <= 1440 {
                                            settings.lastCustomDurationMinutes = minutes
                                            activate(with: .custom(minutes: minutes))
                                            showCustomDuration = false
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled((Int(customMinutes) ?? 0) <= 0 || (Int(customMinutes) ?? 0) > 1440)
                                }

                                // Quick presets
                                HStack(spacing: 8) {
                                    ForEach([("45m", 45), ("90m", 90), ("3h", 180), ("8h", 480)], id: \.1) { label, value in
                                        Button(label) {
                                            customMinutes = String(value)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.bottom, 12)

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
                .accessibilityLabel("Stop timer")
                .accessibilityHint("Double tap to stop keeping your Mac awake")

                Divider()
                    .padding(.vertical, 4)
            }

            // Settings button
            Button(action: {
                Task { @MainActor in
                    WindowManager.shared.openSettings()
                }
            }) {
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
            .accessibilityLabel("Settings")
            .accessibilityHint("Open No Sleep Pro settings. Command comma.")

            // About button
            Button(action: {
                Task { @MainActor in
                    WindowManager.shared.openAbout()
                }
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
            .accessibilityLabel("About No Sleep Pro")

            Divider()
                .padding(.vertical, 4)

            // Quit button
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 10) {
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    Text("Quit No Sleep Pro")
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
            .accessibilityLabel("Quit No Sleep Pro")
            .accessibilityHint("Command Q")
        }
        .frame(width: 340)
        .background(Color(nsColor: .windowBackgroundColor))
        // Note: Monitoring now starts from DependencyContainer at app launch
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusSubtitle: some View {
        if appState.isActive {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.awakeGreen)
                    .frame(width: 8, height: 8)
                    .statusGlow(color: .awakeGreen, isActive: true)

                Text("Active")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.awakeGreen)
            }
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)

                Text("Inactive")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
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
        case .hardwareTrigger: return "cable.connector"
        }
    }

    private func automationText(for reason: ActivationReason) -> String {
        switch reason {
        case .manual: return "Manual activation"
        case .schedule: return "Activated by schedule"
        case .appTrigger(let appName): return "Triggered by \(appName)"
        case .keyboardShortcut: return "Activated via shortcut"
        case .hardwareTrigger(let type): return "\(type) detected"
        }
    }
}

// MARK: - Duration Button

struct DurationButton: View {
    let preset: TimerPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            VStack(spacing: 6) {
                if preset == .indefinite {
                    Image(systemName: "infinity")
                        .font(.system(size: 24, weight: .semibold))
                        .symbolEffect(.pulse, options: .repeating, isActive: isSelected)
                } else {
                    Text(shortLabel)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }

                Text(subLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
        }
        .buttonStyle(EnhancedDurationButtonStyle(isSelected: isSelected, accentColor: .awakeBlue))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityLabel: String {
        switch preset {
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .fiveHours: return "5 hours"
        case .indefinite: return "Indefinite, no time limit"
        case .custom(let minutes):
            if minutes >= 60 {
                let hours = minutes / 60
                return "\(hours) \(hours == 1 ? "hour" : "hours")"
            } else {
                return "\(minutes) minutes"
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
