# No Sleep Pro - App Store Submission Checklist

## Pre-Submission Requirements

### App Store Connect Setup
- [x] Apple Developer Program membership active
- [ ] App ID created in Apple Developer Portal
- [ ] Bundle ID matches (verify in Xcode project)
- [x] App record created in App Store Connect
- [x] App category selected: Utilities
- [ ] Age rating completed (4+, no objectionable content)

### App Information
- [x] App name: "No Sleep Pro"
- [ ] Subtitle: "Keep Your Mac Awake"
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Marketing URL (optional)

### App Description
```
No Sleep Pro keeps your Mac from sleeping with a single click.

FEATURES:
- Prevent system sleep with customizable timers
- Quick presets: 15 min, 30 min, 1 hour, 2 hours, 4 hours, or indefinitely
- Battery protection: auto-stops at configurable battery level
- Schedule-based activation for work hours
- App triggers: activate when specific apps are running
- Hardware triggers: activate when power/display connected
- Mouse jiggler to prevent "Away" status
- Global keyboard shortcut for quick toggle
- Closed-lid mode support with external display

MENU BAR INTEGRATION:
- Clean, unobtrusive menu bar icon
- Optional countdown display
- 8 icon styles to choose from

BATTERY FRIENDLY:
- Automatically stops at low battery
- Uses efficient IOKit APIs
- No background CPU usage when inactive

Perfect for presentations, downloads, video calls, or any time you need your Mac to stay awake.
```

### Keywords (100 characters max)
```
awake,caffeinate,prevent sleep,keep alive,anti-sleep,no sleep,amphetamine,insomnia,presentation
```

### Screenshots Required

| Device | Resolution | Count Required |
|--------|------------|----------------|
| Mac (13") | 2880 x 1800 | 1-10 |
| Mac (16") | 3456 x 2234 | Optional |

**Screenshot Checklist:**
- [ ] Menu bar popover - inactive state
- [ ] Menu bar popover - active with timer
- [ ] Settings view - General tab
- [ ] Settings view - Automation tab
- [ ] Settings view - Appearance tab
- [ ] About window
- [ ] Menu bar icon variations (optional)

### App Icon
- [ ] 512x512 icon in Assets.xcassets
- [ ] 1024x1024 icon for App Store Connect
- [ ] Icon follows Apple Human Interface Guidelines
- [ ] No alpha channel issues

---

## Technical Requirements

### Build Configuration
- [ ] Build number incremented
- [ ] Version number correct (CFBundleShortVersionString)
- [ ] Minimum deployment target: macOS 14.0+
- [ ] Archive build succeeds
- [ ] Code signing configured for distribution

### Privacy Manifest (Required since Spring 2024)
- [ ] PrivacyInfo.xcprivacy exists and included in target
- [ ] NSPrivacyAccessedAPITypes declared:
  - UserDefaults (CA92.1 - app functionality)
- [ ] NSPrivacyTrackingDomains empty
- [ ] NSPrivacyCollectedDataTypes empty

### Info.plist
- [ ] NSAccessibilityUsageDescription present
- [ ] CFBundleDisplayName set
- [ ] LSApplicationCategoryType set to "public.app-category.utilities"
- [ ] LSMinimumSystemVersion correct

### Entitlements
- [ ] App Sandbox enabled
- [ ] Hardened Runtime enabled
- [ ] Required entitlements only (no unused entitlements)

### Code Signing
- [ ] Developer ID certificate valid
- [ ] Team ID matches App Store Connect
- [ ] Provisioning profile for Mac App Store
- [ ] Notarization succeeds (for direct distribution)

---

## Testing Checklist

### Automated Tests
- [ ] All unit tests pass (170 tests)
- [ ] SwiftLint passes (strict mode)
- [ ] Build succeeds without warnings
- [ ] Archive build succeeds

### Manual Testing

**Core Functionality:**
- [ ] App launches from Applications folder
- [ ] Menu bar icon appears
- [ ] Toggle on/off works
- [ ] All timer presets work
- [ ] Custom duration works
- [ ] Timer countdown displays correctly
- [ ] Timer ends correctly with notification

**Automation Features:**
- [ ] Schedule activation works
- [ ] App trigger activation works
- [ ] Battery protection triggers at threshold
- [ ] Hardware triggers work (power/display)
- [ ] Keyboard shortcut toggle works
- [ ] Mouse jiggler works (moves cursor subtly)

**Settings:**
- [ ] All settings persist across restart
- [ ] Launch at login works
- [ ] Icon style changes apply immediately
- [ ] About window shows correct version

**Edge Cases:**
- [ ] Handles sleep/wake cycles
- [ ] Handles display disconnect
- [ ] Handles power state changes
- [ ] No memory leaks (check with Instruments)
- [ ] No excessive CPU usage

**Accessibility:**
- [ ] VoiceOver can navigate all controls
- [ ] All buttons have accessibility labels
- [ ] Keyboard navigation works

---

## Submission Process

### Pre-Upload
1. [ ] Archive app in Xcode (Product > Archive)
2. [ ] Validate archive in Organizer
3. [ ] Fix any validation errors
4. [ ] Upload to App Store Connect

### App Store Connect
1. [ ] Select build for review
2. [ ] Complete app information
3. [ ] Upload screenshots
4. [ ] Submit for review

### Review Notes (if needed)
```
No Sleep Pro uses Accessibility permissions for:
1. Mouse Jiggler feature - requires permission to move cursor
2. Global keyboard shortcut - requires permission to detect key events

The app only uses these permissions when the respective features are enabled by the user.

To test:
1. Enable Mouse Jiggler in Settings > Automation
2. Grant Accessibility permission when prompted
3. Observe subtle mouse movement every 60 seconds

Or:
1. Enable Keyboard Shortcut in Settings > Shortcuts
2. Grant Accessibility permission when prompted
3. Press Cmd+Shift+A to toggle sleep prevention
```

---

## Post-Submission

### After Approval
- [ ] Verify app appears in Mac App Store
- [ ] Test download and install from App Store
- [ ] Monitor crash reports in App Store Connect
- [ ] Monitor reviews and respond to feedback

### Marketing
- [ ] Update website with App Store link
- [ ] Share on social media
- [ ] Submit to Mac app directories
- [ ] Consider Product Hunt launch

---

## Version History

| Version | Status | Notes |
|---------|--------|-------|
| 1.0 | Pending | Initial release |

---

## Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines - macOS](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Privacy Manifest Requirements](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
