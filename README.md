# StayOff — Block Distractions. Reclaim Focus.

StayOff is an Android productivity app that blocks distracting content at the system level — YouTube Shorts, Instagram Reels, adult sites, and any app or website you choose. Built with Flutter + Kotlin native services.

---

## Features

| Feature | How it works |
|---|---|
| **YouTube Shorts blocking** | Accessibility Service detects Shorts UI and presses Back instantly |
| **Instagram Reels blocking** | Same — Reels view IDs trigger automatic exit |
| **TikTok blocking** | Whole-app block via Accessibility Service |
| **App Blocker** | Block any installed app — it gets sent home every time it opens |
| **Website / Domain blocking** | DNS-level VPN intercepts queries — works in every browser |
| **SafeGuard** | Blocks 75+ adult sites via DNS, password-locked |
| **Daily time limits** | Set X minutes/day for Shorts or Reels — auto-blocked after limit |
| **Commitment Lock** | Lock your blocklist for days/months — cannot undo until expiry |
| **Extend-only lock** | Locked period can only be extended, never shortened |
| **Parent PIN** | Locks all app settings behind a 4-digit PIN |
| **PIN unlock** | App protected by a PIN on every open |
| **Security question** | PIN recovery via secret question |
| **Dark / Light theme** | Full theme toggle |
| **Daily usage reset** | Time limits reset automatically at midnight |
| **DoH blocking** | Blocks DNS-over-HTTPS providers so browsers cannot bypass |

---

## Tech Stack

- **Flutter** (Dart) — UI, state management (Riverpod), routing (go_router)
- **Kotlin** — 3 native Android services
- **flutter_secure_storage** — PIN and SafeGuard password storage
- **shared_preferences** — Blocklist, settings, usage data
- **VpnService** (Android) — DNS-only interception
- **AccessibilityService** (Android) — Real-time UI detection

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── routes.dart
│   ├── providers/app_state_provider.dart
│   ├── services/vpn_service.dart
│   └── theme/
│       ├── app_theme.dart
│       └── theme_provider.dart
└── features/
    ├── auth/
    │   ├── screens/register_screen.dart      ← 4-step onboarding
    │   └── widgets/auth_widgets.dart
    ├── blocklist/
    │   ├── models/blocked_site.dart
    │   ├── providers/blocklist_provider.dart
    │   └── screens/blocklist_screen.dart
    ├── appblocker/
    │   ├── models/blocked_app.dart
    │   ├── providers/appblocker_provider.dart
    │   └── screens/appblocker_screen.dart
    ├── safeguard/
    │   ├── providers/safeguard_provider.dart
    │   └── screens/safeguard_screen.dart
    ├── lock/
    │   ├── providers/lock_provider.dart
    │   └── screens/lock_screen.dart
    ├── dashboard/
    │   ├── providers/dashboard_provider.dart
    │   └── screens/dashboard_screen.dart
    ├── pin/
    │   └── screens/pin_unlock_screen.dart
    ├── settings/
    │   └── screens/settings_screen.dart
    └── onboarding/
        └── screens/onboarding_screen.dart

android/app/src/main/kotlin/com/focusguard/
├── MainActivity.kt                    ← Flutter↔Native bridge
├── FocusGuardVpnService.kt            ← DNS interception VPN
└── FocusGuardAccessibilityService.kt  ← Shorts/Reels/App detection
```

---

## Android Setup

### 1. Package name
In `android/app/build.gradle`:
```gradle
applicationId "com.focusguard"
minSdkVersion 26
```

### 2. AndroidManifest.xml permissions
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### 3. AndroidManifest.xml services
```xml
<!-- VPN Service -->
<service
    android:name=".FocusGuardVpnService"
    android:permission="android.permission.BIND_VPN_SERVICE"
    android:exported="false"
    android:foregroundServiceType="specialUse">
  <intent-filter>
    <action android:name="android.net.VpnService"/>
  </intent-filter>
  <property
      android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
      android:value="VPN"/>
</service>

<!-- Accessibility Service -->
<service
    android:name=".FocusGuardAccessibilityService"
    android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
    android:exported="false">
  <intent-filter>
    <action android:name="android.accessibilityservice.AccessibilityService"/>
  </intent-filter>
  <meta-data
      android:name="android.accessibilityservice"
      android:resource="@xml/accessibility_service_config"/>
</service>
```

Also add inside `<application>`:
```xml
android:label="StayOff"
android:icon="@mipmap/ic_launcher"
android:enableOnBackInvokedCallback="true"
```

### 4. Accessibility config
Create `android/app/src/main/res/xml/accessibility_service_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged|typeViewScrolled"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagReportViewIds|flagIncludeNotImportantViews"
    android:canRetrieveWindowContent="true"
    android:notificationTimeout="50"
    android:settingsActivity="com.focusguard.MainActivity"/>
```

---

## How to Run

```bash
flutter pub get
flutter run
```

First launch walks through a 4-step registration:
1. Enter your name
2. Set a 4-digit PIN
3. Enable Accessibility permission
4. Set a security question (for PIN recovery)

---

## How Blocking Works

### YouTube Shorts / Instagram Reels
The Accessibility Service monitors specific view IDs that only appear when Shorts or Reels are active:
- `com.google.android.youtube:id/reel_player_page_container`
- `com.instagram.android:id/clips_viewer_pager`

When detected → `GLOBAL_ACTION_BACK` is performed → user returns to main feed.

**Time limits:** Usage is tracked using wall-clock time (not event counting). When the daily limit is reached, every Shorts/Reels detection triggers a block. Resets at midnight.

### App Blocker
When a blocked app is foregrounded → `GLOBAL_ACTION_HOME` sends the user back to the home screen. Works for any installed app.

### Website / Domain Blocking (VPN)
A local VPN intercepts DNS queries only:
- Route: `addRoute("10.8.8.8", 32)` — only DNS traffic enters tunnel
- All other traffic (HTTP/HTTPS) uses the real network unaffected
- Blocked domains → NXDOMAIN response → browser shows "can't find server"
- Allowed domains → forwarded to `8.8.8.8` → normal DNS response
- DoH providers (dns.google, cloudflare-dns.com) also blocked to prevent bypass

### SafeGuard
Same DNS VPN mechanism but with a curated list of 75+ adult domains. Password-locked — cannot be disabled without the password. If a Commitment Lock is active, even the password cannot disable it.

---

## Key Decisions

| Decision | Reason |
|---|---|
| DNS-only VPN route (not 0.0.0.0/0) | Full-route VPN breaks internet — all non-DNS packets dropped |
| View IDs only for Shorts detection | Text like "Like"/"Dislike" appears on all videos — false positives |
| Single GLOBAL_ACTION_BACK for Shorts | Double-back or HOME closes the whole app |
| Wall-clock time for usage tracking | Event-gap tracking misses time when user watches without scrolling |
| Extend-only Commitment Lock | Allows strengthening but not weakening a commitment |
| Payment apps excluded from VPN | PhonePe/Paytm detect VPN and refuse to work |
| Package filter on A11y service | `packageNames=null` monitors all apps → excessive battery drain |

---

## Known Limitations

- **iOS not supported** — Accessibility Service and VPN-level blocking are Android-only
- **HTTPS bypass** — Sites with hardcoded IPs can bypass DNS blocking (rare)
- **Root not required** — Everything works without root
- **Emulator** — VPN does not work on Android emulators (permission rejected by system)

---

## pubspec.yaml Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.x
  go_router: ^13.x
  flutter_secure_storage: ^9.x
  shared_preferences: ^2.x
  google_fonts: ^6.x
  fl_chart: ^0.x
  lottie: ^3.x
  shimmer: ^3.x
  equatable: ^2.x
  intl: ^0.x
  dio: ^5.x
```

---

## Architecture

- **State management:** Riverpod (`StateNotifier` pattern)
- **Navigation:** go_router with redirect based on `AppStartRoute` enum
- **Storage:** `flutter_secure_storage` for sensitive data (PIN, SafeGuard password), `shared_preferences` for everything else
- **Native bridge:** `MethodChannel` — two channels: `com.focusguard/vpn` and `com.focusguard/app_blocker`
- **Theme:** Custom `FGColors` / `FGColorsLight` with full dark/light support

---

## Play Store

- **App name:** StayOff
- **Package:** com.focusguard
- **Category:** Productivity
- **Content rating:** Everyone
- **Tagline:** Block distractions. Reclaim focus.

---

*Built by Priyanshu*
