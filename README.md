# 🤗💋 Hugs & Kisses — iOS App

A romantic couple app that links two iPhones and lets you send haptic hugs and
kisses to each other — straight from the Lock Screen via liquid-glass widgets.

---

## Features

| Feature | Details |
|---------|---------|
| **Lock Screen Widgets** | Two `accessoryCircular` widgets sit in the same spot as the Flashlight & Camera circles (the + customisable circles at the bottom of the Lock Screen) |
| **Hug & Kiss buttons** | Liquid-glass art style with emoji — 🤗 and 💋 |
| **Haptic on sender** | Quick confirmation tap when you press the button |
| **Haptic on recipient** | Adjustable duration (0.5 – 10 s) and intensity — completely independent from the sender's settings |
| **Vibration styles** | Gentle Wave · Heartbeat · Love Pulse · Butterfly Kiss · Longing |
| **Widget lights up pink** | Recipient's matching widget glows pink with outline preserved for the full duration of the vibration |
| **Works both ways** | Either partner can send |
| **Background ready** | Silent push notification wakes the app in background; minimal battery footprint |
| **Cute aesthetic** | Dark rose / rose-gold / liquid-glass palette throughout |

---

## Project Structure

```
HugsAndKisses/
├── App/
│   ├── HugsAndKissesApp.swift      – @main entry, scene setup
│   └── AppDelegate.swift           – push notifications, FCM, payload routing
│
├── Models/
│   ├── SharedDefaults.swift        – App Group UserDefaults (shared with widget)
│   ├── HapticSettings.swift        – HapticPattern enum + UserHapticSettings
│   ├── MessageTypes.swift          – Firestore document shapes, push keys
│   └── AppState.swift              – @EnvironmentObject central state
│
├── Services/
│   ├── HapticService.swift         – CoreHaptics engine, all patterns
│   ├── FirebaseService.swift       – Firestore CRUD, FCM callable
│   └── PairingService.swift        – Invite creation, QR code, code acceptance
│
├── Views/
│   ├── OnboardingView.swift        – Name entry, brand intro
│   ├── PairingView.swift           – QR generate / code scan flow
│   ├── DashboardView.swift         – Main hug/kiss buttons + receive banner
│   ├── SettingsView.swift          – Per-type haptic sliders + pattern picker
│   └── Components/
│       └── LiquidGlass.swift       – All reusable UI components
│
├── Widget/
│   ├── HugsKissesWidget.swift      – WidgetKit definitions + views
│   └── WidgetIntents.swift         – AppIntents (tap → send without opening app)
│
├── CloudFunctions/
│   ├── index.js                    – Firebase Cloud Function (FCM dispatch)
│   └── package.json
│
└── Assets/
    ├── firestore.rules             – Firestore security rules
    └── HugsKisses.xcconfig         – Shared Xcode build settings
```

---

## Requirements

- **Xcode 15.2+**
- **iOS 17+** (interactive widgets via AppIntents; iOS 16 works without button interactivity)
- **Firebase project** (Firestore + FCM + Cloud Functions)
- **Apple Developer account** (paid — required for push notifications and App Groups)

---

## Setup Guide

### Step 1 — Create the Xcode Project

1. Open Xcode → **New Project** → **App**
   - Product Name: `HugsAndKisses`
   - Bundle ID: `com.yourname.hugsandkisses`
   - Language: Swift, Interface: SwiftUI
2. Add a **Widget Extension** target:
   - File → New → Target → Widget Extension
   - Product Name: `HugsKissesWidget`
   - Include Configuration Intent: **No**
3. Add a **Notification Service Extension** target (optional, for future rich notifications).

### Step 2 — Configure App Group

Both the main app target and the widget target must share the same App Group so
`SharedDefaults` can communicate between them.

1. In each target's **Signing & Capabilities**, click **+ Capability → App Groups**.
2. Add `group.com.yourname.hugsandkisses`.
3. Confirm this matches `SharedDefaults.appGroupID` in `SharedDefaults.swift`.

### Step 3 — Enable Push Notifications

1. Main app target → Signing & Capabilities → **+ Push Notifications**.
2. Main app target → Signing & Capabilities → **+ Background Modes**:
   - ✅ Remote notifications
   - ✅ Background fetch

### Step 4 — Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) → **New Project**.
2. Add an **iOS app** → Bundle ID `com.yourname.hugsandkisses`.
3. Download `GoogleService-Info.plist` → drag into the **main app target** (not widget).
4. Enable **Firestore Database** (start in test mode, then apply `firestore.rules`).
5. Enable **Cloud Messaging** (FCM).
   - Upload your APNs Auth Key in FCM settings (Project Settings → Cloud Messaging → APNs Authentication Key).

### Step 5 — Swift Package Dependencies

Add via **File → Add Package Dependencies**:

| Package | URL |
|---------|-----|
| Firebase iOS SDK | `https://github.com/firebase/firebase-ios-sdk` |

Select: `FirebaseFirestore`, `FirebaseFirestoreSwift`, `FirebaseAuth`,
`FirebaseMessaging`, `FirebaseFunctions`.

### Step 6 — Deploy Cloud Function

```bash
cd CloudFunctions
npm install
firebase login
firebase use --add          # select your project
firebase deploy --only functions
```

### Step 7 — Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### Step 8 — URL Scheme (Widget deep-link)

In `Info.plist` of the **main app**:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>hugsandkisses</string></array>
  </dict>
</array>
```

### Step 9 — Build & Run

1. Build the **main app scheme** on both iPhones.
2. On Phone A: open the app, enter your name, tap **Create Invite** → share the code.
3. On Phone B: open the app, tap **Enter a Code** → type the 6-character code.
4. Both phones are now paired! 🎉

### Step 10 — Add Lock Screen Widgets

On each phone:
1. Long-press the Lock Screen.
2. Tap **Customize → Lock Screen**.
3. Tap the bottom circular widget area (the row with Flashlight & Camera).
4. Replace one or both circles with **Hug** and **Kiss** from the Hugs & Kisses app.

---

## How It Works — Architecture

```
[Lock Screen Widget]
       │ tap (AppIntent)
       ▼
[App runs in background]
  ├─ Confirmation haptic on sender
  └─ FirebaseService.send() ──► Firestore document
                                       │
                          Cloud Function (FCM push)
                                       │
                               [Recipient's iPhone]
                                  ├─ APNs wakes app
                                  ├─ HapticService plays pattern
                                  ├─ SharedDefaults.activateLightUp()
                                  └─ WidgetKit.reloadAllTimelines()
                                       │
                               [Widget re-renders]
                                  └─ Lit-up pink circle for duration
```

---

## Haptic Settings — Per Person

Each person controls **their own receive experience** in the Settings tab:

| Setting | Range | Default |
|---------|-------|---------|
| Hug duration | 0.5 – 10 s | 3.0 s |
| Hug intensity | 10% – 100% | 80% |
| Hug pattern | 5 styles | Heartbeat |
| Kiss duration | 0.5 – 10 s | 2.0 s |
| Kiss intensity | 10% – 100% | 70% |
| Kiss pattern | 5 styles | Butterfly Kiss |
| Confirmation tap | 0.05 – 1 s | 0.25 s |

---

## Vibration Patterns

| Pattern | Feel |
|---------|------|
| 🌊 Gentle Wave | Slow, soft rolling pulses |
| 💓 Heartbeat | ba-dum ba-dum rhythm (~70 bpm) |
| 💞 Love Pulse | Quick repeating taps |
| 🦋 Butterfly Kiss | Rapid light flutters + pause |
| 💗 Longing | One long sustained throb |

---

## Bundle ID Customisation

Replace all occurrences of `com.yourname.hugsandkisses` with your own reverse-domain
bundle ID before running. Also update:

- `SharedDefaults.appGroupID` → `group.YOUR_BUNDLE_ID`
- `HugsKisses.xcconfig`
- `firestore.rules` (no change needed)
- Xcode target Bundle Identifiers

---

## Technical Notes

### Widget interactivity requires iOS 17
On iOS 16 the widgets display correctly but tapping them opens the app rather
than running silently in the background. The hug/kiss is still sent.

### Background haptics
iOS allows CoreHaptics to play while the app is in the background as long as
the audio session is active (set to `.ambient`). For completely killed apps,
the push notification's default vibration plays; the custom pattern plays the
next time the app comes to the foreground.

### Battery life
- The Firestore listener runs only while the app is in the foreground.
- In the background, delivery relies entirely on APNs push — no polling.
- The widget timeline refreshes once every 5 minutes (or immediately on light-up expiry).

---

## Privacy

- No personal data is stored beyond display name and FCM token.
- Anonymous Firebase Auth is used (no email/password required).
- Invite codes expire after acceptance.
- All Firestore rules enforce that only paired users can read/write each other's data.
