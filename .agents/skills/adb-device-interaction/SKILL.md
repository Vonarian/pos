---
name: adb-device-interaction
description: >-
  Use when developing, testing, debugging, or verifying Android / Flutter mobile apps on physical devices
  or emulators using ADB - covers waking device, screen inspection, touch/swipe/key interaction, capturing
  and viewing screenshots, permission handling, logcat inspections, and presenting visual confirmation carousels.
---

# ADB Mobile Device Interaction & Visual Verification Workflow

## Overview

Live visual verification on real devices or emulators is the ultimate truth for mobile applications.
**Core Principle:** *Never make assertions about mobile UI or device behavior without capturing and viewing live visual evidence via ADB.*

---

## 1. Device Discovery & Environment Setup

### 1.1 List Connected Devices
```bash
adb devices -l
```
If multiple devices or emulators are connected, always pass `-s <SERIAL>` to all ADB commands (e.g., `adb -s R5GL13Y25VH ...`).

### 1.2 Flutter Build Environment (if applicable)
For network/storage constrained environments, always ensure required storage URLs:
```bash
env FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com flutter build apk --debug
```

---

## 2. Fast Build, Install & Launch Pipeline

Execute build, install, and launch in a single streamlined command:
```bash
# 1. Build debug APK
env FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com flutter build apk --debug

# 2. Reinstall keeping app data (-r)
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Launch the main activity
adb shell am start -n <package_name>/<main_activity_class>
# Example: adb shell am start -n com.pos.pos_frontend/.MainActivity
```

---

## 3. Screen State Management (Wake, Unlock, Resolution)

### 3.1 Wake & Unlock Screen
Mobile screens frequently time out and go black. Always precede UI interactions with wakeup commands:
```bash
# Wake up display
adb shell input keyevent KEYCODE_WAKEUP

# Dismiss lock screen / keyguard (if no secure pin/biometrics lock is set)
adb shell input keyevent KEYCODE_MENU
```

### 3.2 Inspect Physical Resolution & Density
Understanding physical pixel bounds is essential for accurate tap and swipe coordinates:
```bash
adb shell wm size     # e.g., Physical size: 1440x3120
adb shell wm density  # e.g., Physical density: 560
```

---

## 4. Device Interaction (Taps, Swipes, Text, Keyevents)

### 4.1 Taps (Clicking UI Elements)
Calculate coordinates from the physical resolution (e.g., on 1440x3120, center is (720, 1560)):
```bash
adb shell input tap <X> <Y>
# Example: adb shell input tap 720 1560
```

### 4.2 Swiping & Scrolling
Syntax: `adb shell input swipe <StartX> <StartY> <EndX> <EndY> <DurationMs>`
- **Scroll Down (pull content up):**
  ```bash
  adb shell input swipe 720 2000 720 600 300
  ```
- **Scroll Up (pull content down):**
  ```bash
  adb shell input swipe 720 600 720 2000 300
  ```
- **Horizontal Swipe (e.g., switch tab/carousel):**
  ```bash
  adb shell input swipe 1200 1500 200 1500 250
  ```

### 4.3 Text Entry & Typing
```bash
adb shell input text "SampleText"
# Note: For spaces use %s or quote the string
adb shell input text "Hello%sWorld"
```

### 4.4 Essential Hardware Keys
```bash
adb shell input keyevent KEYCODE_BACK        # Key code 4 (Go back / dismiss keyboard)
adb shell input keyevent KEYCODE_HOME        # Key code 3 (Go to home screen)
adb shell input keyevent KEYCODE_APP_SWITCH  # Key code 187 (Recents / Task switcher)
```

---

## 5. Instant Screenshot Capture & Inspection

### 5.1 High-Speed Screencap (Direct to Artifacts)
Use `adb exec-out screencap -p` to pipe binary PNG data directly into the target file without intermediate files on device storage:
```bash
adb exec-out screencap -p > <appDataDir>/brain/<conversation-id>/screenshot_<name>.png
```

### 5.2 Mandatory Visual Inspection
Always call `view_file` on the saved screenshot immediately to verify:
1. The screen is awake (not a black image).
2. The UI transitioned to the expected state.
3. No overflowing text, clipped widgets, or red screen errors.

### 5.3 Presenting Visual Proof to the User
When presenting verification results in artifacts or chat responses, embed the screenshots using Markdown carousels:
````markdown
````carousel
![1. Habits Dashboard Telemetry](/path/to/screenshot_1.png)
<!-- slide -->
![2. Analytics Screen Modal](/path/to/screenshot_2.png)
````
````

---

## 6. Permissions & System Dialog Workflows

When adding new permissions (e.g., Android Health Connect, Notification, Location):
1. **Trigger Dialog:** Tap the "Connect" / "Grant Access" button in the app.
2. **Capture Dialog Screen:** Run `adb exec-out screencap -p` and view it to locate permission switches/buttons.
3. **Toggle Permissions:** Tap the "Allow all" toggle (e.g., `adb shell input tap 1200 2200`).
4. **Confirm Dialog:** Tap the "Allow" button (e.g., `adb shell input tap 1050 2980`).
5. **Verify Re-render:** Capture a follow-up screenshot confirming the app received permissions and data loaded.

---

## 7. Real-Time Logcat & Native Diagnostics

### 7.1 Filtered Logcat Inspection
```bash
# Clear logcat buffer, trigger action, then dump filtered logs
adb logcat -c
adb shell input tap <X> <Y>
sleep 2
adb logcat -d -s "flutter" "HealthConnect" "GoLog"
```

### 7.2 Native App Data & SQLite Inspection
To inspect app data or extract databases:
```bash
adb shell "run-as com.pos.pos_frontend ls -la databases/"
```
