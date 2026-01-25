# AwakeApp - Feature Roadmap

## Version History Plan

| Version | Focus | Status |
|---------|-------|--------|
| **1.0** | Core features | ✅ Complete |
| **1.1** | Quick Wins Bundle | ✅ Complete |
| **1.2** | Closed-Lid Mode + Tests + Error Handling | ✅ Complete |
| **1.3** | Calendar Integration | 🔜 Next |
| **1.4** | Siri Shortcuts + AppleScript | Planned |
| **2.0** | StoreKit 2 + Polish | Planned |

---

## Version 1.1: Quick Wins Bundle ✅ COMPLETE

### 1. Custom Keyboard Shortcut
**Status:** ✅ Complete
**Effort:** Low

Let users customize their preferred keyboard shortcut instead of fixed ⌘⇧A.

```swift
// In Settings.swift
@AppStorage("customShortcutKey") var customShortcutKey: String = "A"
@AppStorage("customShortcutModifiers") var customShortcutModifiers: Int = 0x180000 // Cmd+Shift

// UI: Shortcut recorder in Settings
```

**UI Addition:**
- Settings → General → "Keyboard Shortcut" section
- Show current shortcut with "Change..." button
- Use `KeyboardShortcuts` package or custom recorder

---

### 2. Custom Duration Input
**Status:** ✅ Complete
**Effort:** Low

Let users enter any duration, not just presets.

```swift
// New TimerPreset case
enum TimerPreset: Equatable, Identifiable {
    case fifteenMinutes
    case thirtyMinutes
    case oneHour
    case twoHours
    case fiveHours
    case indefinite
    case custom(minutes: Int)  // NEW

    var seconds: Int? {
        switch self {
        // ... existing cases
        case .custom(let minutes):
            return minutes * 60
        }
    }
}
```

**UI Addition:**
- "Custom..." button in duration picker
- Opens popover with minute/hour input
- Remember last custom duration

---

### 3. Notification When Timer Ends
**Status:** ✅ Complete
**Effort:** Low

Send macOS notification when timer expires.

```swift
// NotificationManager.swift
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleTimerEndNotification(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "AwakeApp"
        content.body = "Timer ended. Your Mac can now sleep."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "timerEnd", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelTimerEndNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerEnd"])
    }
}
```

**Settings:**
- Toggle: "Notify when timer ends"
- Optional sound selection

---

### 4. Mouse Jiggler
**Status:** ✅ Complete
**Effort:** Low

Move mouse cursor slightly to prevent inactivity detection by other apps (like Slack/Teams showing "Away").

```swift
// MouseJiggler.swift
import CoreGraphics
import Foundation

class MouseJiggler {
    private var timer: Timer?
    private var jiggleAmount: CGFloat = 1

    func start(intervalSeconds: Double = 60) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) { [weak self] _ in
            self?.jiggle()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func jiggle() {
        guard let currentPosition = CGEvent(source: nil)?.location else { return }

        // Move 1 pixel right, then back
        let moveRight = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                mouseCursorPosition: CGPoint(x: currentPosition.x + jiggleAmount, y: currentPosition.y),
                                mouseButton: .left)
        moveRight?.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let moveBack = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                   mouseCursorPosition: currentPosition,
                                   mouseButton: .left)
            moveBack?.post(tap: .cghidEventTap)
        }
    }
}
```

**Settings:**
- Toggle: "Keep me active in chat apps (mouse jiggler)"
- Interval: 30s, 60s, 120s, 300s
- Note: "Moves cursor 1 pixel periodically to prevent 'Away' status"

**⚠️ Requires Accessibility permission**

---

### 5. Wi-Fi Network Trigger
**Status:** ✅ Complete
**Effort:** Low

Auto-activate when connected to specific networks (e.g., office Wi-Fi).

```swift
// WiFiMonitor.swift
import CoreWLAN
import SystemConfiguration

class WiFiMonitor: ObservableObject {
    @Published var currentSSID: String?

    private var timer: Timer?

    func startMonitoring() {
        updateCurrentSSID()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.updateCurrentSSID()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateCurrentSSID() {
        let client = CWWiFiClient.shared()
        currentSSID = client.interface()?.ssid()
    }
}

// In Settings
struct WiFiTrigger: Codable, Identifiable {
    var id = UUID()
    var ssid: String
    var isEnabled: Bool = true
}
```

**Settings:**
- List of Wi-Fi networks that trigger activation
- "Add Current Network" button
- Toggle each network on/off

**⚠️ Requires Location permission (for SSID access)**

---

### 6. Power Adapter Trigger
**Status:** ✅ Complete
**Effort:** Low

Auto-activate when power adapter is connected (or disconnected).

```swift
// PowerMonitor.swift
import IOKit.ps

class PowerMonitor: ObservableObject {
    @Published var isOnACPower: Bool = false

    private var runLoopSource: CFRunLoopSource?

    func startMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        runLoopSource = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                monitor.updatePowerStatus()
            }
        }, context).takeRetainedValue()

        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        updatePowerStatus()
    }

    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
    }

    private func updatePowerStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        for source in sources {
            let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as! [String: Any]
            if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                isOnACPower = (powerSource == kIOPSACPowerValue)
                return
            }
        }
    }
}
```

**Settings:**
- Toggle: "Activate when power adapter connected"
- Toggle: "Deactivate when on battery"

---

### 7. External Display Trigger
**Status:** ✅ Complete
**Effort:** Low

Auto-activate when external display is connected.

```swift
// DisplayMonitor.swift
import AppKit

class DisplayMonitor: ObservableObject {
    @Published var externalDisplayConnected: Bool = false

    private var observer: NSObjectProtocol?

    func startMonitoring() {
        updateDisplayStatus()

        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateDisplayStatus()
        }
    }

    func stopMonitoring() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func updateDisplayStatus() {
        // More than 1 screen = external display connected
        externalDisplayConnected = NSScreen.screens.count > 1
    }
}
```

**Settings:**
- Toggle: "Activate when external display connected"

---

### 8. Custom Menu Bar Icon
**Status:** ✅ Complete
**Effort:** Low

Let users choose from different icon styles.

```swift
// Settings
enum MenuBarIconStyle: String, CaseIterable {
    case coffeCup = "cup.and.saucer"
    case moon = "moon.zzz"
    case bolt = "bolt"
    case eye = "eye"
    case sun = "sun.max"
    case customEmoji = "custom"

    var systemName: String { rawValue }
    var filledName: String { rawValue + ".fill" }
}

@AppStorage("menuBarIconStyle") var menuBarIconStyle: MenuBarIconStyle = .coffeeCup
@AppStorage("customMenuBarEmoji") var customMenuBarEmoji: String = "☕️"
```

**Settings:**
- Icon picker with preview
- Option to use custom emoji

---

## Version 1.2: Closed-Lid Mode ✅ COMPLETE

### Clamshell Mode Support
**Status:** ✅ Complete
**Effort:** Medium

Keep Mac awake even when lid is closed (requires external display/power).

```swift
// ClamshellManager.swift
import IOKit
import IOKit.pwr_mgt

class ClamshellManager {
    private var assertionID: IOPMAssertionID = 0

    /// Enable clamshell mode (prevent sleep when lid closed)
    func enableClamshellMode() -> Bool {
        // Create assertion that prevents idle sleep
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "AwakeApp Clamshell Mode" as CFString,
            &assertionID
        )

        return result == kIOReturnSuccess
    }

    func disableClamshellMode() {
        IOPMAssertionRelease(assertionID)
        assertionID = 0
    }

    /// Check if conditions are met for clamshell mode
    static func canEnableClamshellMode() -> Bool {
        // Need: external display + power adapter
        let hasExternalDisplay = NSScreen.screens.count > 1
        let isOnACPower = !CaffeinateManager.isOnBatteryPower()

        return hasExternalDisplay && isOnACPower
    }
}
```

**Requirements:**
- External display must be connected
- Power adapter must be connected
- User must explicitly enable this feature

**Settings:**
- Toggle: "Allow closed-lid mode"
- Status indicator showing if conditions are met
- Warning about battery drain if used incorrectly

**UI Indicator:**
- Different menu bar icon when in clamshell mode
- Tooltip showing "Clamshell mode active"

---

## Version 1.3: Calendar Integration

### Auto-Activate During Meetings
**Status:** To implement
**Effort:** Medium

Sync with Calendar app and auto-activate during events.

```swift
// CalendarManager.swift
import EventKit

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var hasCalendarAccess = false
    @Published var upcomingEvents: [EKEvent] = []

    private var timer: Timer?

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run { hasCalendarAccess = granted }
            return granted
        } catch {
            return false
        }
    }

    func startMonitoring() {
        checkCurrentEvents()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkCurrentEvents()
        }
    }

    func checkCurrentEvents() {
        guard hasCalendarAccess else { return }

        let now = Date()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endOfDay,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
            .filter { $0.startDate <= now && $0.endDate > now }

        DispatchQueue.main.async {
            self.upcomingEvents = events
        }
    }

    func isInMeeting() -> Bool {
        let now = Date()
        return upcomingEvents.contains { event in
            event.startDate <= now && event.endDate > now
        }
    }

    func currentMeetingEndTime() -> Date? {
        let now = Date()
        return upcomingEvents.first { event in
            event.startDate <= now && event.endDate > now
        }?.endDate
    }
}
```

**Settings:**
- Toggle: "Activate during calendar events"
- Calendar picker (which calendars to monitor)
- Filter options:
  - All events
  - Only events with video call links (Zoom, Meet, Teams)
  - Only events marked "Busy"
- Buffer time: "Start X minutes early, end X minutes late"

**Privacy:**
- Requires Calendar access permission
- Events processed locally, never sent anywhere
- Show permission request explanation

---

## Version 1.4: Siri Shortcuts + AppleScript

### Siri Shortcuts Integration
**Status:** To implement
**Effort:** Medium

Enable "Hey Siri, keep my Mac awake" and Shortcuts app integration.

```swift
// ShortcutsManager.swift
import AppIntents

// Define App Intents for Shortcuts

struct StartAwakeIntent: AppIntent {
    static var title: LocalizedStringResource = "Start AwakeApp"
    static var description = IntentDescription("Prevents your Mac from sleeping")

    @Parameter(title: "Duration")
    var duration: DurationEntity?

    func perform() async throws -> some IntentResult {
        // Activate with specified duration
        await MainActor.run {
            let preset: TimerPreset = duration?.toPreset() ?? .indefinite
            AppState.shared.activate(with: preset)
            CaffeinateManager.shared.start(duration: preset.seconds)
        }
        return .result()
    }
}

struct StopAwakeIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop AwakeApp"
    static var description = IntentDescription("Allows your Mac to sleep normally")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppState.shared.deactivate()
            CaffeinateManager.shared.stop()
        }
        return .result()
    }
}

struct ToggleAwakeIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle AwakeApp"
    static var description = IntentDescription("Toggles sleep prevention on or off")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            if AppState.shared.isActive {
                AppState.shared.deactivate()
                CaffeinateManager.shared.stop()
            } else {
                AppState.shared.activate(with: .indefinite)
                CaffeinateManager.shared.start(duration: nil)
            }
        }
        return .result()
    }
}

struct GetStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get AwakeApp Status"
    static var description = IntentDescription("Check if AwakeApp is currently active")

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let isActive = await MainActor.run { AppState.shared.isActive }
        return .result(value: isActive)
    }
}

// Duration entity for Shortcuts
struct DurationEntity: AppEntity {
    var id: String
    var minutes: Int

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Duration")
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(minutes) minutes")
    }

    static var defaultQuery = DurationQuery()

    func toPreset() -> TimerPreset {
        switch minutes {
        case 15: return .fifteenMinutes
        case 30: return .thirtyMinutes
        case 60: return .oneHour
        case 120: return .twoHours
        case 300: return .fiveHours
        default: return .custom(minutes: minutes)
        }
    }
}

// App Shortcuts Provider
struct AwakeAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartAwakeIntent(),
            phrases: [
                "Keep my Mac awake with \(.applicationName)",
                "Start \(.applicationName)",
                "Prevent sleep with \(.applicationName)"
            ],
            shortTitle: "Start AwakeApp",
            systemImageName: "cup.and.saucer.fill"
        )

        AppShortcut(
            intent: StopAwakeIntent(),
            phrases: [
                "Stop \(.applicationName)",
                "Let my Mac sleep",
                "Turn off \(.applicationName)"
            ],
            shortTitle: "Stop AwakeApp",
            systemImageName: "moon.zzz"
        )

        AppShortcut(
            intent: ToggleAwakeIntent(),
            phrases: [
                "Toggle \(.applicationName)"
            ],
            shortTitle: "Toggle AwakeApp",
            systemImageName: "arrow.triangle.2.circlepath"
        )
    }
}
```

### AppleScript Support
**Status:** To implement
**Effort:** Low

Enable automation via AppleScript.

```swift
// In Info.plist, add:
// NSAppleScriptEnabled = YES

// ScriptingBridge.swift - Expose scriptable interface
import Foundation

@objc(AwakeAppApplication)
class AwakeAppApplication: NSObject {

    @objc var isActive: Bool {
        get { AppState.shared.isActive }
    }

    @objc var remainingSeconds: Int {
        get { AppState.shared.remainingSeconds ?? -1 }
    }

    @objc func start(_ minutes: Int) {
        let preset: TimerPreset = minutes == 0 ? .indefinite : .custom(minutes: minutes)
        AppState.shared.activate(with: preset)
        CaffeinateManager.shared.start(duration: preset.seconds)
    }

    @objc func stop() {
        AppState.shared.deactivate()
        CaffeinateManager.shared.stop()
    }

    @objc func toggle() {
        if AppState.shared.isActive {
            stop()
        } else {
            start(0) // Indefinite
        }
    }
}
```

**AppleScript Examples:**
```applescript
-- Check if active
tell application "AwakeApp"
    get isActive
end tell

-- Start for 60 minutes
tell application "AwakeApp"
    start 60
end tell

-- Start indefinitely
tell application "AwakeApp"
    start 0
end tell

-- Stop
tell application "AwakeApp"
    stop
end tell

-- Toggle
tell application "AwakeApp"
    toggle
end tell
```

**Siri Phrases (automatically enabled):**
- "Hey Siri, keep my Mac awake with AwakeApp"
- "Hey Siri, start AwakeApp"
- "Hey Siri, stop AwakeApp"
- "Hey Siri, toggle AwakeApp"

---

## Version 2.0: Polish & Monetization

### Features
- StoreKit 2 integration (see ROADMAP_StoreKit2.md)
- Usage statistics ("You've kept your Mac awake for 127 hours")
- macOS Widget support
- Refined onboarding experience
- Localization (Chinese, Japanese, German, Spanish, French)

---

## Feature Priority Matrix

| Feature | User Value | Dev Effort | Priority |
|---------|------------|------------|----------|
| Custom duration | High | Low | **P1** |
| Notifications | High | Low | **P1** |
| Custom hotkey | Medium | Low | **P1** |
| Power adapter trigger | High | Low | **P1** |
| External display trigger | High | Low | **P1** |
| Mouse jiggler | High | Low | **P1** |
| Wi-Fi trigger | Medium | Low | **P1** |
| Custom icons | Low | Low | **P2** |
| Closed-lid mode | High | Medium | **P2** |
| Calendar integration | High | Medium | **P2** |
| Siri Shortcuts | High | Medium | **P3** |
| AppleScript | Medium | Low | **P3** |
| Widgets | Medium | Medium | **P4** |
| Statistics | Low | Low | **P4** |

---

## Implementation Order

### Sprint 1 (Week 1-2): Quick Wins v1.1
1. ✅ Custom duration input
2. ✅ Notification when timer ends
3. ✅ Power adapter trigger
4. ✅ External display trigger
5. ✅ Custom keyboard shortcut UI

### Sprint 2 (Week 3-4): More Triggers v1.1.5
1. ✅ Wi-Fi network trigger
2. ✅ Mouse jiggler
3. ✅ Custom menu bar icons

### Sprint 3 (Week 5-6): Clamshell v1.2
1. ✅ Closed-lid mode
2. ✅ Clamshell mode UI and warnings

### Sprint 4 (Week 7-8): Calendar v1.3
1. ✅ Calendar integration
2. ✅ Meeting detection
3. ✅ Calendar settings UI

### Sprint 5 (Week 9-10): Automation v1.4
1. ✅ Siri Shortcuts (App Intents)
2. ✅ AppleScript support

### Sprint 6 (Week 11-12): Monetization v2.0
1. ✅ StoreKit 2 integration
2. ✅ Polish and bug fixes
3. ✅ Prepare for App Store feature

---

## Permissions Required

| Feature | Permission | Prompt |
|---------|------------|--------|
| Mouse jiggler | Accessibility | "AwakeApp needs accessibility access to keep you active in chat apps" |
| Wi-Fi trigger | Location | "AwakeApp needs location to detect Wi-Fi networks" |
| Calendar | Calendar | "AwakeApp needs calendar access to activate during meetings" |
| Notifications | Notifications | "AwakeApp wants to notify you when timers end" |

---

## Competitive Positioning After v2.0

| Feature | AwakeApp | Amphetamine | Lungo |
|---------|----------|-------------|-------|
| Timer presets | ✅ | ✅ | ✅ |
| Custom duration | ✅ | ✅ | ✅ |
| App triggers | ✅ | ✅ | ❌ |
| Wi-Fi triggers | ✅ | ✅ | ❌ |
| Power triggers | ✅ | ✅ | ❌ |
| Display triggers | ✅ | ✅ | ❌ |
| Schedules | ✅ | ✅ | ✅ |
| Battery protection | ✅ | ✅ | ❌ |
| Closed-lid mode | ✅ | ✅ | ❌ |
| Calendar integration | ✅ | ❌ | ❌ |
| Siri Shortcuts | ✅ | ❌ | ❌ |
| AppleScript | ✅ | ✅ | ❌ |
| Mouse jiggler | ✅ | ✅ | ❌ |
| Modern SwiftUI UI | ✅ | ❌ | ✅ |
| Price | $2.99 | Free | $4.99 |

**Unique differentiators vs Amphetamine:**
- Calendar integration
- Siri Shortcuts
- Modern SwiftUI interface
- Simpler, more focused UX

**Unique differentiators vs Lungo:**
- App triggers
- Wi-Fi/Power/Display triggers
- Calendar integration
- Mouse jiggler
- Lower price
