# AwakeApp Testing Documentation

## Test Suite Overview

| Test Category | Count | Status |
|---------------|-------|--------|
| Unit Tests | 89 | Passing |
| Integration Tests | 49 | Passing |
| **Total** | **138** | **All Passing** |

---

## First-Launch Test Scenarios

These scenarios must be manually tested before each release to ensure proper first-run experience.

### Scenario 1: Clean Install First Launch

**Preconditions:**
- App has never been installed on this Mac
- No AwakeApp preferences exist in `~/Library/Preferences/`

**Steps:**
1. Install app from DMG
2. Launch app from Applications folder

**Expected Outcomes:**
- [ ] Menu bar icon appears (default: coffee cup, unfilled)
- [ ] App is in inactive state (no sleep prevention)
- [ ] No permission prompts appear until features are used
- [ ] Clicking menu bar icon shows main panel
- [ ] Default settings are applied:
  - Allow display sleep: OFF
  - Notify on timer end: ON
  - Battery protection: ON (20% threshold)
  - Keyboard shortcut: OFF
  - Mouse jiggler: OFF
  - Hardware triggers: OFF
  - Schedules: OFF
  - App triggers: OFF

### Scenario 2: Accessibility Permission Request

**Preconditions:**
- Clean install (no accessibility permission granted)

**Steps:**
1. Launch app
2. Enable "Mouse Jiggler" in Settings OR
3. Enable "Keyboard Shortcut" in Settings

**Expected Outcomes:**
- [ ] System Settings opens to Privacy & Security > Accessibility
- [ ] AwakeApp appears in the list
- [ ] After granting permission, feature activates without restart
- [ ] If denied, appropriate error message shown
- [ ] Feature toggle reverts to OFF if permission denied

### Scenario 3: Notification Permission Request

**Preconditions:**
- Clean install (no notification permission granted)

**Steps:**
1. Launch app
2. Enable any timer preset (e.g., "15 minutes")

**Expected Outcomes:**
- [ ] macOS notification permission prompt appears
- [ ] If allowed, notification scheduled for timer end
- [ ] If denied, timer still works (notification silently skipped)
- [ ] Permission only requested once

### Scenario 4: Update from Previous Version

**Preconditions:**
- Previous version (1.x) is installed
- User has customized settings

**Steps:**
1. Install new version (overwrites old)
2. Launch app

**Expected Outcomes:**
- [ ] All previous settings preserved
- [ ] Menu bar icon style preserved
- [ ] Schedules preserved
- [ ] App triggers preserved
- [ ] Custom keyboard shortcut preserved
- [ ] No duplicate menu bar icons

### Scenario 5: Login Item Behavior

**Preconditions:**
- App installed, settings configured

**Steps:**
1. Enable "Launch at Login" in Settings
2. Restart Mac
3. Log in

**Expected Outcomes:**
- [ ] App launches automatically
- [ ] Menu bar icon visible
- [ ] Previous active state NOT restored (security best practice)
- [ ] Schedules evaluated and auto-activate if applicable

---

## Device Testing Coverage Matrix

### macOS Versions

| Version | Build Status | Manual Test | Notes |
|---------|--------------|-------------|-------|
| macOS 15.0 (Sequoia) | Required | Required | Primary target |
| macOS 14.x (Sonoma) | Required | Required | Secondary target |
| macOS 13.x (Ventura) | Optional | Recommended | Legacy support |
| macOS 12.x (Monterey) | Not supported | N/A | Below minimum deployment |

### Hardware Configurations

| Configuration | Priority | Test Focus |
|---------------|----------|------------|
| MacBook Pro (Apple Silicon) | Critical | Power management, display sleep, closed lid |
| MacBook Air (Apple Silicon) | Critical | Battery protection, thermal behavior |
| Mac mini (Apple Silicon) | High | No battery, no lid - feature detection |
| iMac (Apple Silicon) | High | No battery, external display scenarios |
| Intel Mac (any) | Medium | Rosetta compatibility, IOKit differences |
| Mac with external display | Critical | Closed lid mode, display count detection |
| Mac on battery | Critical | Battery protection trigger, battery level |
| Mac on power adapter | Critical | Power state transitions |

### Form Factor Features

| Feature | MacBook | Desktop Mac | Notes |
|---------|---------|-------------|-------|
| Battery protection | Yes | N/A (hidden) | Auto-detect via IOKit |
| Closed lid mode | Yes | N/A (hidden) | Requires external display + power |
| Power state triggers | Yes | Limited | Desktop only detects power loss |
| Display sleep | Yes | Yes | |
| System sleep prevention | Yes | Yes | |

---

## Test Coverage Analysis

### Core Services Coverage

| Service | Unit Tests | Integration Tests | Coverage |
|---------|-----------|-------------------|----------|
| AppState | Yes | Yes | Good |
| CaffeinateManager | Partial | Yes | Needs: error paths |
| AutomationManager | Limited | Yes | Needs: edge cases |
| MouseJiggler | Mock only | Yes | Needs: permission flows |
| KeyboardShortcutManager | Yes | Partial | Needs: recording flow |
| NotificationManager | Mock only | Yes | Good |
| ClosedLidManager | Limited | Yes | Needs: hardware states |
| WindowManager | No | No | Low priority |

### Identified Coverage Gaps

#### High Priority (Must Fix)

1. **CaffeinateManager Error Handling**
   - Missing: Test for IOPMAssertionRelease failure
   - Missing: Test for duplicate start() calls
   - Missing: Test for stop() when not running

2. **Battery Protection Edge Cases**
   - Missing: Test for rapid battery level changes
   - Missing: Test for battery level at exact threshold
   - Missing: Test for charger connect during protection

3. **Schedule Timezone Handling**
   - Missing: Test for timezone change during active schedule
   - Missing: Test for DST transition during schedule

#### Medium Priority (Should Fix)

4. **Keyboard Shortcut Conflicts**
   - Missing: Test for system shortcut conflicts
   - Missing: Test for recording cancellation
   - Missing: Test for shortcut persistence after restart

5. **App Trigger Reliability**
   - Missing: Test for app crash during trigger
   - Missing: Test for multiple matching apps
   - Missing: Test for app bundle ID changes

6. **Hardware State Transitions**
   - Missing: Test for power adapter hot-plug
   - Missing: Test for display hot-plug
   - Missing: Test for lid close/open rapid cycling

#### Low Priority (Nice to Have)

7. **UI State Consistency**
   - Missing: Menu bar icon animation states
   - Missing: Timer display accuracy under load
   - Missing: Settings view state restoration

---

## Running Tests

### Command Line

```bash
# Run all tests
xcodebuild test \
  -project AwakeApp.xcodeproj \
  -scheme AwakeApp \
  -destination 'platform=macOS'

# Run specific test class
xcodebuild test \
  -project AwakeApp.xcodeproj \
  -scheme AwakeApp \
  -destination 'platform=macOS' \
  -only-testing:AwakeAppTests/ActivationReasonTests

# Run with code coverage
xcodebuild test \
  -project AwakeApp.xcodeproj \
  -scheme AwakeApp \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES
```

### Xcode

1. Open `AwakeApp.xcodeproj`
2. Select Product > Test (Cmd+U)
3. View results in Test Navigator (Cmd+6)

---

## Pre-Release Checklist

### Automated Checks
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] SwiftLint passes (strict mode)
- [ ] Build succeeds without warnings
- [ ] Code signing valid

### Manual Checks
- [ ] First-launch scenarios (all 5)
- [ ] Device matrix (minimum 2 configurations)
- [ ] VoiceOver navigation works
- [ ] Menu bar icon renders correctly (light/dark mode)
- [ ] Timer countdown accurate
- [ ] Battery percentage displays correctly
- [ ] Closed lid mode activates/deactivates properly
- [ ] App triggers detect running apps
- [ ] Schedules activate at correct times
- [ ] Keyboard shortcut toggles state
- [ ] Mouse jiggler moves cursor subtly
- [ ] Notifications appear when timer ends
- [ ] About window displays correct version

---

## CI Integration

GitHub Actions runs on every push/PR:
1. SwiftLint (blocking)
2. Build
3. Unit tests
4. Integration tests

See `.github/workflows/ci.yml` for configuration.
