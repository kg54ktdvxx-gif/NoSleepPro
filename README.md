# AwakeApp - macOS Menu Bar Sleep Prevention

A powerful macOS menu bar app that prevents your Mac from sleeping with smart automation features.

## Current Version: 1.2

---

## Development Status

**Last Session:** January 25, 2026

### Completed:
- [x] Git repository initialized (9 commits)
- [x] Build errors fixed (Combine imports, Equatable)
- [x] UI/UX improvements:
  - Settings window opens properly (WindowManager)
  - Clear ON/OFF toggle button (green/gray states)
  - About window simplified (no animations)
- [x] Test suite created (200+ tests) - needs Xcode test target

### Next Steps:
- [ ] Add test target to Xcode project
- [ ] App Store screenshots
- [ ] Final testing before submission
- [ ] Create website for support/privacy URLs

---

### What's New in v1.2
- **Closed-Lid Mode** - Keep your Mac awake with the lid closed (requires external display + power)
- **Comprehensive Test Suite** - 200+ unit and integration tests
- **Error Handling** - Robust error handling with user-friendly messages
- **Localization Ready** - Full i18n support prepared

### v1.1 Features
- **Custom Keyboard Shortcut** - Toggle with ⌘⇧A (customizable)
- **Schedule-Based Activation** - Auto-activate during work hours
- **App Triggers** - Auto-activate when Zoom, Teams, etc. launch
- **Wi-Fi Triggers** - Auto-activate on specific networks
- **Hardware Triggers** - Activate on power/display connection
- **Mouse Jiggler** - Stay "Active" in chat apps
- **Battery Protection** - Auto-stop when battery is low
- **Custom Menu Bar Icons** - 8 icon styles to choose from
- **Notifications** - Get notified when timers end

## Features

### Core Features
- **Menu bar integration** - Lives in your menu bar, no dock clutter
- **Timer presets** - 15 min, 30 min, 1 hour, 2 hours, 5 hours, indefinite
- **Custom duration** - Set any duration you need
- **Visual feedback** - Icon changes when active
- **Countdown display** - See remaining time in the menu

### Smart Automation
- **App Triggers** - Auto-activate for Zoom, Teams, Keynote, PowerPoint, etc.
- **Schedule Triggers** - Set work hours for automatic activation
- **Wi-Fi Triggers** - Activate when connected to office/home network
- **Hardware Triggers** - Activate when power adapter or external display connected
- **Battery Protection** - Automatically stops when battery drops below threshold

### Power User Features
- **Global Keyboard Shortcut** - Toggle from anywhere (⌘⇧A default)
- **Mouse Jiggler** - Prevents "Away" status in chat apps
- **Closed-Lid Mode** - Use Mac with lid closed (clamshell mode)
- **Allow Display Sleep** - Keep system awake while display sleeps
- **Custom Icons** - Choose your preferred menu bar icon style

## Requirements

- macOS 13.0 (Ventura) or later
- For Wi-Fi triggers: Location permission
- For Mouse Jiggler: Accessibility permission
- For Closed-Lid Mode: External display + power adapter

## Installation

### From Mac App Store (Recommended)
Coming soon!

### From Source
1. Clone this repository
2. Open `Xcode/AwakeApp/AwakeApp.xcodeproj` in Xcode
3. Build and run (⌘+R)

## Usage

### Quick Start
1. Click the coffee cup icon in your menu bar
2. Select a duration preset (or use ⌘⇧A to toggle)
3. The icon fills to indicate active state
4. Click "Turn Off" or use ⌘⇧A to stop

### Setting Up Automation
1. Click the menu bar icon → Settings (⚙️)
2. Configure triggers in the Automation tab:
   - **App Triggers**: Select apps that auto-activate
   - **Schedules**: Set work hours
   - **Wi-Fi**: Add network names
   - **Hardware**: Enable power/display triggers
   - **Battery Protection**: Set threshold (10-30%)

### Closed-Lid Mode
1. Connect an external display
2. Connect power adapter
3. Enable in Settings → Automation → Closed-Lid Mode
4. Close your MacBook lid - it stays awake!

## Architecture

```
AwakeApp/
├── Xcode/
│   └── AwakeApp/
│       ├── AwakeApp/
│       │   ├── AwakeAppMain.swift        # App entry point
│       │   ├── AppState.swift            # State management
│       │   ├── CaffeinateManager.swift   # IOKit power assertions
│       │   ├── AutomationManager.swift   # Triggers & schedules
│       │   ├── Settings.swift            # User preferences
│       │   ├── MenuBarView.swift         # Main menu UI
│       │   ├── SettingsView.swift        # Settings window
│       │   ├── KeyboardShortcutManager.swift
│       │   ├── MouseJiggler.swift
│       │   ├── WiFiMonitor.swift
│       │   ├── HardwareMonitors.swift
│       │   ├── NotificationManager.swift
│       │   ├── ClosedLidManager.swift    # v1.2
│       │   ├── ErrorHandling.swift       # Centralized errors
│       │   ├── Localization.swift        # i18n support
│       │   ├── MenuBarIcon.swift
│       │   ├── TimerPreset.swift
│       │   └── AboutView.swift
│       └── AwakeAppTests/
│           ├── Unit Tests (8 files)
│           ├── Integration/ (6 files)
│           └── Mocks/
├── README.md
├── AppStore_Submission.md
├── ROADMAP_Features.md
└── ROADMAP_StoreKit2.md
```

## Testing

The project includes a comprehensive test suite:

### Unit Tests
- `TimerPresetTests` - Timer preset logic
- `ActivationReasonTests` - Activation reason handling
- `ScheduleEntryTests` - Schedule data models
- `TriggerModelsTests` - Trigger configurations
- `KeyboardShortcutTests` - Keyboard shortcut handling
- `MenuBarIconStyleTests` - Icon style options
- `WiFiTriggerLogicTests` - Wi-Fi trigger matching
- `ScheduleLogicTests` - Schedule time calculations

### Integration Tests
- `AppStateIntegrationTests` - App state flows
- `AutomationIntegrationTests` - Trigger workflows
- `NotificationIntegrationTests` - Notification scheduling
- `ClosedLidIntegrationTests` - Clamshell mode
- `EndToEndWorkflowTests` - Real-world scenarios
- `ErrorHandlingIntegrationTests` - Error recovery

Run tests in Xcode: Product → Test (⌘+U)

## Technical Details

### How It Works
AwakeApp uses macOS IOKit power assertions to prevent sleep:

```swift
IOPMAssertionCreateWithName(
    kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
    IOPMAssertionLevel(kIOPMAssertionLevelOn),
    "AwakeApp preventing sleep" as CFString,
    &assertionID
)
```

This is the App Store-compliant approach (unlike spawning `caffeinate`).

### Privacy
- No data collection
- No analytics or tracking
- All processing happens locally
- No network requests (except for Wi-Fi SSID detection)

## Development

Built with:
- Swift 5.9+
- SwiftUI
- macOS 13.0+ SDK
- IOKit for power management
- CoreWLAN for Wi-Fi monitoring

## Roadmap

See [ROADMAP_Features.md](ROADMAP_Features.md) for planned features:
- v1.3: Calendar Integration
- v1.4: Siri Shortcuts + AppleScript
- v2.0: StoreKit 2 + Polish

## License

Copyright © 2026. All rights reserved.

---

Made with ❤️ & 🤖 in 🇸🇬

Built with [Claude Code](https://claude.com/claude-code)
