//
//  SettingsView.swift
//  AwakeApp
//
//  Preferences window for configuring app behavior
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AutomationSettingsTab()
                .tabItem {
                    Label("Automation", systemImage: "wand.and.stars")
                }

            ScheduleSettingsTab()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            AppTriggersSettingsTab()
                .tabItem {
                    Label("Apps", systemImage: "app.badge")
                }
        }
        .frame(width: 520, height: 480)
        .environmentObject(settings)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var shortcutManager = KeyboardShortcutManager.shared
    @State private var showingIconPicker = false

    var body: some View {
        Form {
            Section {
                // Menu bar icon picker
                HStack {
                    Text("Menu bar icon:")
                    Spacer()
                    Button(action: { showingIconPicker = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: settings.menuBarIconStyle.systemName)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: settings.menuBarIconStyle.filledSystemName)
                            Text(settings.menuBarIconStyle.displayName)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                Toggle("Show countdown in menu bar", isOn: $settings.showMenuBarCountdown)
                    .help("Display remaining time next to the menu bar icon")
                    .accessibilityHint("Display remaining time next to the menu bar icon")

                Toggle("Allow display to sleep", isOn: $settings.allowDisplaySleep)
                    .help("Keep system awake but allow display to turn off")
                    .accessibilityHint("Keep system awake but allow display to turn off")

                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    .help("Automatically start No Sleep Pro when you log in")
                    .accessibilityHint("Automatically start No Sleep Pro when you log in")
            } header: {
                Text("Display Options")
            }

            Section {
                Toggle("Notify when timer ends", isOn: $settings.notifyOnTimerEnd)
                Toggle("Notify on battery protection", isOn: $settings.notifyOnBatteryStop)
            } header: {
                Text("Notifications")
            }

            Section {
                Toggle("Enable keyboard shortcut", isOn: $settings.keyboardShortcutEnabled)

                HStack {
                    Text("Shortcut:")
                    Spacer()
                    ShortcutRecorderButton()
                }
                .opacity(settings.keyboardShortcutEnabled ? 1 : 0.5)
                .disabled(!settings.keyboardShortcutEnabled)

                Picker("Default duration:", selection: $settings.defaultPreset) {
                    ForEach(TimerPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .opacity(settings.keyboardShortcutEnabled ? 1 : 0.5)
            } header: {
                Text("Keyboard Shortcut")
            }

            Section {
                Toggle("Enable mouse jiggler", isOn: $settings.mouseJigglerEnabled)
                    .help("Periodically move mouse to prevent 'Away' status in chat apps")
                    .accessibilityHint("Periodically move mouse to prevent Away status in chat apps")

                if settings.mouseJigglerEnabled {
                    Picker("Jiggle interval:", selection: $settings.mouseJigglerInterval) {
                        ForEach(MouseJiggler.availableIntervals, id: \.seconds) { interval in
                            Text(interval.label).tag(interval.seconds)
                        }
                    }

                    // Accessibility permission status
                    HStack {
                        if MouseJiggler.shared.hasAccessibilityPermission {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Accessibility permission granted")
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Accessibility permission required")
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Grant") {
                                MouseJiggler.shared.requestAccessibilityPermission()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .font(.caption)
                }
            } header: {
                Text("Mouse Jiggler")
            } footer: {
                Text("Moves the cursor slightly to prevent apps like Slack or Teams from marking you as 'Away'.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView(selectedStyle: $settings.menuBarIconStyle)
        }
    }
}

// MARK: - Shortcut Recorder Button

struct ShortcutRecorderButton: View {
    @StateObject private var shortcutManager = KeyboardShortcutManager.shared

    var body: some View {
        Button(action: {
            if shortcutManager.isRecording {
                shortcutManager.cancelRecording()
            } else {
                shortcutManager.startRecording { _ in }
            }
        }) {
            HStack {
                if shortcutManager.isRecording {
                    Text("Press shortcut...")
                        .foregroundColor(.blue)
                } else {
                    Text(shortcutManager.currentShortcut.displayString)
                }
            }
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(shortcutManager.isRecording ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(shortcutManager.isRecording ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(shortcutManager.isRecording ? "Recording shortcut, press keys to set" : "Keyboard shortcut: \(shortcutManager.currentShortcut.displayString)")
        .accessibilityHint("Double tap to record a new keyboard shortcut")

        Button(action: {
            shortcutManager.resetToDefault()
        }) {
            Image(systemName: "arrow.counterclockwise")
                .foregroundColor(.secondary)
        }
        .buttonStyle(.plain)
        .help("Reset to default (⌘⇧A)")
        .accessibilityLabel("Reset shortcut to default")
        .accessibilityHint("Reset to Command Shift A")
    }
}

// MARK: - Automation Settings Tab

struct AutomationSettingsTab: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var closedLidManager = ClosedLidManager.shared

    var body: some View {
        Form {
            Section {
                Toggle("Enable battery protection", isOn: $settings.batteryProtectionEnabled)
                    .help("Automatically stop when battery is low")
                    .accessibilityHint("Automatically stop sleep prevention when battery is low")

                if settings.batteryProtectionEnabled {
                    HStack {
                        Text("Stop when battery below:")
                        Spacer()
                        Picker("", selection: $settings.batteryThreshold) {
                            Text("10%").tag(10)
                            Text("15%").tag(15)
                            Text("20%").tag(20)
                            Text("25%").tag(25)
                            Text("30%").tag(30)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }

                    // Battery status indicator
                    if let level = CaffeinateManager.getBatteryLevel() {
                        HStack {
                            Image(systemName: batteryIcon(for: level))
                                .foregroundColor(batteryColor(for: level))
                            Text("Current: \(level)%")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    } else {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.green)
                            Text("Connected to power")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }
            } header: {
                Text("Battery Protection")
            } footer: {
                Text("Automatically stop sleep prevention if your battery drops below the threshold.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Enable closed-lid mode", isOn: $settings.closedLidModeEnabled)
                    .help("Keep Mac awake with lid closed when using external display")
                    .accessibilityHint("Keep Mac awake with lid closed when using external display")
                    .onChange(of: settings.closedLidModeEnabled) { _, enabled in
                        if enabled {
                            closedLidManager.startMonitoring()
                            _ = closedLidManager.enable()
                        } else {
                            closedLidManager.stopMonitoring()
                        }
                    }

                if settings.closedLidModeEnabled {
                    Toggle("Auto-enable when conditions met", isOn: $settings.autoEnableClosedLid)
                        .help("Automatically enable when power and external display are connected")

                    // Status display
                    ClosedLidStatusView(status: closedLidManager.status)

                    // Error display
                    if let error = closedLidManager.lastError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } header: {
                Text("Closed-Lid Mode")
            } footer: {
                Text("Use your Mac with the lid closed when connected to power and an external display. Great for desktop setups.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Toggle("Enable hardware triggers", isOn: $settings.hardwareTriggersEnabled)

                if settings.hardwareTriggersEnabled {
                    Toggle("Activate when power adapter connected", isOn: $settings.activateOnPowerConnect)
                        .help("Automatically activate when you plug in your Mac")
                        .accessibilityHint("Automatically activate when you plug in your Mac")

                    Toggle("Deactivate when on battery", isOn: $settings.deactivateOnBattery)
                        .help("Automatically stop when you unplug your Mac")
                        .accessibilityHint("Automatically stop when you unplug your Mac")

                    Toggle("Activate when external display connected", isOn: $settings.activateOnExternalDisplay)
                        .help("Automatically activate when connecting an external monitor")
                        .accessibilityHint("Automatically activate when connecting an external monitor")
                }
            } header: {
                Text("Hardware Triggers")
            } footer: {
                Text("Automatically control sleep prevention based on hardware connections.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            if settings.closedLidModeEnabled {
                closedLidManager.startMonitoring()
            }
        }
    }

    private func batteryIcon(for level: Int) -> String {
        switch level {
        case 0..<10: return "battery.0"
        case 10..<35: return "battery.25"
        case 35..<65: return "battery.50"
        case 65..<90: return "battery.75"
        default: return "battery.100"
        }
    }

    private func batteryColor(for level: Int) -> Color {
        if level <= settings.batteryThreshold {
            return .red
        } else if level < 30 {
            return .orange
        }
        return .green
    }
}

// MARK: - Closed-Lid Status View

struct ClosedLidStatusView: View {
    let status: ClosedLidStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Power status
                StatusIndicator(
                    isActive: status.isPowerConnected,
                    activeIcon: "bolt.fill",
                    inactiveIcon: "bolt.slash",
                    label: "Power"
                )

                // Display status
                StatusIndicator(
                    isActive: status.hasExternalDisplay,
                    activeIcon: "display",
                    inactiveIcon: "display",
                    label: "Display"
                )

                // Lid status
                StatusIndicator(
                    isActive: status.isLidClosed,
                    activeIcon: "laptopcomputer.slash",
                    inactiveIcon: "laptopcomputer",
                    label: status.isLidClosed ? "Closed" : "Open"
                )
            }

            // Overall status
            HStack {
                Circle()
                    .fill(status.isEnabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(status.statusDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusIndicator: View {
    let isActive: Bool
    let activeIcon: String
    let inactiveIcon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isActive ? activeIcon : inactiveIcon)
                .font(.system(size: 16))
                .foregroundColor(isActive ? .green : .secondary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 50)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(isActive ? "connected" : "not connected")")
    }
}

// MARK: - Schedule Settings Tab

struct ScheduleSettingsTab: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingAddSchedule = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Toggle("Enable schedules", isOn: $settings.schedulesEnabled)
                Spacer()
                Button(action: { showingAddSchedule = true }) {
                    Label("Add Schedule", systemImage: "plus")
                }
                .disabled(!settings.schedulesEnabled)
            }
            .padding()

            Divider()

            // Schedule list
            if settings.schedules.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.awakeOrange.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.awakeOrange)
                    }

                    VStack(spacing: 8) {
                        Text("Automate Your Work Hours")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Create schedules to automatically keep your Mac awake during specific times. Perfect for work hours or regular meetings.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button(action: { showingAddSchedule = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Your First Schedule")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.awakeOrange)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!settings.schedulesEnabled)
                    .opacity(settings.schedulesEnabled ? 1 : 0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach($settings.schedules) { $schedule in
                        ScheduleRow(schedule: $schedule)
                    }
                    .onDelete { indexSet in
                        settings.schedules.remove(atOffsets: indexSet)
                    }
                }
            }
        }
        .opacity(settings.schedulesEnabled ? 1 : 0.6)
        .sheet(isPresented: $showingAddSchedule) {
            AddScheduleView { newSchedule in
                settings.schedules.append(newSchedule)
            }
        }
    }
}

struct ScheduleRow: View {
    @Binding var schedule: ScheduleEntry

    var body: some View {
        HStack {
            Toggle("", isOn: $schedule.isEnabled)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 4) {
                // Days
                HStack(spacing: 2) {
                    ForEach(ScheduleEntry.Weekday.allCases) { day in
                        Text(day.initial)
                            .font(.system(size: 10, weight: .medium))
                            .frame(width: 18, height: 18)
                            .background(schedule.days.contains(day) ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(schedule.days.contains(day) ? .white : .secondary)
                            .cornerRadius(4)
                    }
                }

                // Time range
                Text("\(formatTime(schedule.startTime)) - \(formatTime(schedule.endTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .opacity(schedule.isEnabled ? 1 : 0.5)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AddScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var schedule = ScheduleEntry()
    let onAdd: (ScheduleEntry) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Schedule")
                .font(.headline)

            // Day selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(ScheduleEntry.Weekday.allCases) { day in
                        Button(action: {
                            if schedule.days.contains(day) {
                                schedule.days.remove(day)
                            } else {
                                schedule.days.insert(day)
                            }
                        }) {
                            Text(day.shortName)
                                .font(.system(size: 12, weight: .medium))
                                .frame(width: 40, height: 32)
                                .background(schedule.days.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(schedule.days.contains(day) ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Time selection
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Start Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $schedule.startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                VStack(alignment: .leading) {
                    Text("End Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $schedule.endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    onAdd(schedule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(schedule.days.isEmpty)
            }
        }
        .padding()
        .frame(width: 360, height: 280)
    }
}

// MARK: - App Triggers Settings Tab

struct AppTriggersSettingsTab: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingAppPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Toggle("Enable app triggers", isOn: $settings.appTriggersEnabled)
                Spacer()
                Button(action: { showingAppPicker = true }) {
                    Label("Add App", systemImage: "plus")
                }
                .disabled(!settings.appTriggersEnabled)
            }
            .padding()

            Divider()

            // App list
            if settings.appTriggers.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.awakePurple.opacity(0.12))
                            .frame(width: 80, height: 80)

                        Image(systemName: "app.badge")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.awakePurple)
                    }

                    VStack(spacing: 8) {
                        Text("Smart App Detection")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Add apps like Zoom, PowerPoint, or Final Cut Pro. When they're running, No Sleep Pro will automatically keep your Mac awake.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button(action: { showingAppPicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Your First App")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.awakePurple)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!settings.appTriggersEnabled)
                    .opacity(settings.appTriggersEnabled ? 1 : 0.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach($settings.appTriggers) { $trigger in
                        HStack {
                            Toggle("", isOn: $trigger.isEnabled)
                                .labelsHidden()

                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: trigger.bundleIdentifier) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "app.fill")
                                    .frame(width: 24, height: 24)
                            }

                            Text(trigger.appName)
                                .opacity(trigger.isEnabled ? 1 : 0.5)

                            Spacer()

                            Text(trigger.bundleIdentifier)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .onDelete { indexSet in
                        settings.appTriggers.remove(atOffsets: indexSet)
                    }
                }
            }
        }
        .opacity(settings.appTriggersEnabled ? 1 : 0.6)
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { bundleId, appName in
                let trigger = AppTrigger(bundleIdentifier: bundleId, appName: appName)
                if !settings.appTriggers.contains(where: { $0.bundleIdentifier == bundleId }) {
                    settings.appTriggers.append(trigger)
                }
            }
        }
    }
}

struct AppPickerView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (String, String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Select App")
                .font(.headline)

            Text("Choose an app that will automatically activate sleep prevention when running.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(AppSettings.commonAppTriggers, id: \.bundleId) { app in
                        Button(action: {
                            onSelect(app.bundleId, app.name)
                            dismiss()
                        }) {
                            HStack {
                                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleId) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 24))
                                        .frame(width: 32, height: 32)
                                }

                                Text(app.name)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 350, height: 400)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
