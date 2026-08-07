# Home-screen widget review — 2026-08-07

Scope: the widget implementation on `main` (1.1.0+57), and the reported failure
"tapping the widget opens the app, it can't connect, then shows *Still setting
things up*".

## Root cause of the reported hang

**`hoquefamilychores://home` reaches `FLTFirebaseAuthPlugin`, which blocks the
iOS main thread inside FirebaseAuth while the app is still starting up.**

The chain, every link verified in source:

1. `ios/ChoresStarWidget/ChoresStarWidget.swift:122` sets
   `.widgetURL(URL(string: "hoquefamilychores://home"))`. Tapping the widget
   therefore launches the app **via a URL**, which is the one launch type that
   calls `application(_:open:options:)`. Tapping the app icon never does.
2. `ios/Runner/AppDelegate.swift` does not override `application(_:open:options:)`,
   so `FlutterAppDelegate` walks the registered plugin delegates in order until
   one returns `true`.
3. `home_widget`'s plugin declines it — `HomeWidgetPlugin.isWidgetUrl` only
   claims URLs carrying a `?homeWidget` query parameter, which ours does not
   have. The URL falls through to the next plugin.
4. `firebase_auth`'s plugin takes it unconditionally:

   ```objc
   // FLTFirebaseAuthPlugin.m:289
   - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
     return [[FIRAuth auth] canHandleURL:url];
   }
   ```

5. By this point `GeneratedPluginRegistrant.register` has already run, and
   `FLTFirebaseCorePlugin.sharedInstance` configures the default `FIRApp` from
   the bundled `GoogleService-Info.plist` as a side effect of registration
   (`FLTFirebaseCorePlugin.m:59-62`). So `[FIRAuth auth]` finds a configured app
   — and this is the process's **first** access to `Auth`, which constructs it
   on the main thread and enqueues its keychain restore.

6. `canHandleURL:` then blocks the calling thread — here, the main/platform
   thread — behind that just-enqueued work:

   ```swift
   // FirebaseAuth 11.13.0, Auth.swift:1608
   @objc(canHandleURL:) open func canHandle(_ url: URL) -> Bool {
     kAuthGlobalWorkQueue.sync { ... }
   }
   ```

7. The app never recovers. A blocked platform thread means Flutter
   method/event channels stop being serviced, so
   `FirebaseAuth.instance.authStateChanges()` never delivers: `main.dart:171`
   stays in `ConnectionState.waiting`, renders `_SplashScreen`, and 10 seconds
   later shows *"Still setting things up. Check your connection and retry — or
   sign out and back in."* Dart itself is alive on the UI thread, which is why
   the timer fires and the screen still paints.

   The exact lock cycle was not isolated. What **is** established: this call is
   made, only on the URL launch path; it blocks the calling thread; and the
   failure is permanent. Permanent rules out transient queue contention — a
   cold-launch probe on the simulator showed `currentUser` already non-null at
   the first `StreamBuilder` build, so the keychain restore is not a long
   operation, and contention alone would self-heal in well under the 10-second
   timeout.

This is the **only** code-path difference between an icon launch and a widget
launch, and it explains every observation: deterministic, iOS-only, widget-only,
and unaffected by a force-quit beforehand.

### On the native-init comment in `main.dart`

`main.dart:57-58` says a native auto-init creates the `[DEFAULT]` app before
`main()` runs, naming "iOS's `FirebaseApp.configure()`". That is accurate,
though not for the reason the wording suggests: `FirebaseCore` itself does not
auto-configure on iOS, but `FLTFirebaseCorePlugin.sharedInstance` does
(`FLTFirebaseCorePlugin.m:59-62`), and plugin registration runs inside
`didFinishLaunchingWithOptions`. Since the default app therefore always exists
before any URL is delivered, `Auth.auth()`'s "must be configured first"
`fatalError` (`Auth.swift:152`) is not reachable here — the failure mode is the
block, not a crash.

### Fix

One change closes it:

1. Claim the widget's own scheme in `AppDelegate` and return before the plugin
   chain runs, so `firebase_auth` never sees a URL it cannot own:

   ```swift
   override func application(
     _ app: UIApplication, open url: URL,
     options: [UIApplication.OpenURLOptionsKey: Any] = [:]
   ) -> Bool {
     if url.scheme == "hoquefamilychores" { return true }
     return super.application(app, open: url, options: options)
   }
   ```

   Google's OAuth callback uses the reverse-client-id scheme, so it still
   reaches the plugins via `super`.

   Note for the follow-up in finding 3: returning `true` here means
   `home_widget`'s plugin never records the URL either, so
   `HomeWidget.initiallyLaunchedFromHomeWidget()` will not see it. If the widget
   link is later made addressable, capture the URL inside this override and
   forward it to Dart directly — do not re-open it to the plugin chain.

**Not recommended:** adding a native `FirebaseApp.configure()` in
`didFinishLaunchingWithOptions`. It changes nothing about this bug — the
firebase_core plugin already configures the default app during registration —
and it would only add a second configure call on a path `main.dart:57-67`
deliberately treats as a fatal config-drift signal.

Upstream, `firebase_auth`'s unconditional `canHandleURL:` on every incoming URL
is worth an issue against FlutterFire.

## Other defects found

### 1. The widget never gets its first payload — CONFIRMED

`home_screen.dart:186`:

```dart
ref.listen(
  homeWidgetDataProvider(currentUser.familyId, currentUser.id),
  (_, data) => ref.read(homeWidgetBridgeProvider).update(data),
);
```

`ref.listen` fires on *change*, never for the value already present when it
registers — and it registers inside the `data:` branch, i.e. after tasks have
loaded. Nothing pushes the initial payload. Until some later change happens
while the Home tab is on screen, the shared container stays empty and the widget
renders its fallbacks: `"Hi there!"`, no missions, no streak.

Fix: push once on registration (`fireImmediately: true`, or an explicit
`update()` alongside the listener).

### 2. Widget updates are scoped to one screen state — CONFIRMED

The listener lives only in `_buildDashboard`, the `data:` branch of HomeScreen.
A user who stays on another tab, or whose task stream errors, never updates the
widget. Anything that changes elsewhere (claiming a chore on the Chores tab,
approving from Notifications) is not reflected until Home rebuilds with new data.

Fix: hoist the sync to a place that lives for the session — a `keepAlive`
listener wired once the family and user are known.

### 3. The deep link is registered but inert — CONFIRMED

The widget opens `hoquefamilychores://home`; every notification deep link uses
`choresapp://` (`notification_templates.dart`, `firebase_push_notification_repository.dart`).
Nothing in `lib/` reads an incoming URL at all — commit 379df48 says so
explicitly. So the widget's URL routes nowhere, lands on Home only because Home
is the default tab, and (per the root cause above) is actively harmful.

Fix: once the AppDelegate short-circuit is in, either drop the `widgetURL`
entirely or route it through the same `pendingDeepLink` path the push payloads
already use, and use one scheme for both.

### 4. `FamilyGate` swallows `AuthStatus.error` — CONFIRMED

`main.dart:241-262` checks `needsProfileCompletion`, then `user == null`, and
nothing else. But `AuthNotifier._startUserProfileStream`'s `onError`
(`auth_notifier.dart:610`) sets `status: AuthStatus.error` with the real message
— a Firestore permission denial or a stream failure renders as the same
"check your connection" splash, with the actual cause visible only in a debug
log. `AppLogger` uses `logger`'s default `DevelopmentFilter`, so in a release
build that message is not recorded anywhere. This is the reason the reported
fault could not be diagnosed from the device.

Fix: render `AuthStatus.error` with `errorMessage`, per the fail-loudly rule in
CLAUDE.md.

### 5. The splash "Retry" button retries nothing — CONFIRMED

`main.dart:315-322` only resets `_timedOut` and re-arms the 10-second timer. No
provider is invalidated, no stream is re-subscribed. The copy promises a retry
that does not exist.

Fix: `ref.invalidate(authNotifierProvider)` (which re-runs `build()` and
restarts the profile stream) before re-arming.

### 6. `AuthNotifier` never listens to auth state — FIXED

`AuthNotifier.build()` (`auth_notifier.dart:53`) reads
`authRepository.currentUser` **once** and never subscribes to
`authStateChanges`. If the notifier is ever built during a window where
FirebaseAuth has not yet restored the session — `LoginScreen` watches the
provider at `login_screen.dart:30`, and it is what renders while
`authStateChanges` is still null — then `state.user` stays null forever:
`FamilyGate` keeps watching the provider so autoDispose never collects it,
Retry does not rebuild it, and only signing out escapes. That is precisely the
"or sign out and back in" escape hatch the splash copy offers.

Not the cause of the reported bug — instrumentation on the simulator showed
`currentUser` already non-null at the first `StreamBuilder` build, so the window
did not open there.

`build()` now subscribes to `authStateChanges` for the notifier's lifetime,
keeping the synchronous `currentUser` read so an already-restored session does
not render a signed-out frame first. The listener reconciles two transitions the
notifier previously ignored: a session arriving after build (populate), and a
session dropped from elsewhere — revoked token, sign-out on another surface —
which used to leave a signed-out user looking signed in.

Three things guard it, because this is the sign-in path for every user:

- `_streamedUserId` tracks which profile the stream is following, so Firebase
  re-emitting the same user on token refresh is a no-op rather than a
  teardown-and-resubscribe. Confirmed against the real SDK: a cold start logs
  no "Session appeared" line.
- The listener stands down while `status` is `authenticating` or
  `needsProfileCompletion`. Those flows decide for themselves whether a profile
  exists; stepping in would replace `needsProfileCompletion` with
  "authenticated, no profile" — the same dead end in a new place.
- A null emission is ignored when already signed out, so sign-out does not
  double-write state.

Still open, and adjacent: when the profile stream emits null for a signed-in
user (the document does not exist), `_startUserProfileStream` sets
`status: authenticated` with `user: null`, which lands on the splash again.
`CompleteProfileScreen` is the right destination, but changing it touches
`deleteAccount` and `leaveFamily`, so it was left alone rather than smuggled in
here.

### 7. Android: every widget refresh threw — CONFIRMED

`HomeWidgetBridgeImpl.update` passed the same string for both platforms:

```dart
await HomeWidget.updateWidget(
  name: _kWidgetName,        // 'ChoresStarWidget'
  androidName: _kWidgetName,
  iOSName: _kWidgetName,
);
```

The two platforms do not name the widget the same way. iOS wants the WidgetKit
`kind`; Android wants the AppWidgetProvider **class**, which home_widget
resolves as `Class.forName("${context.packageName}.${androidName}")`
(`HomeWidgetPlugin.kt:108`). `com.hoque.familychores.ChoresStarWidget` does not
exist — the class is `ChoresStarWidgetProvider` — so every call threw
`ClassNotFoundException`, surfaced as `PlatformException(-3, "No Widget found
with Name ChoresStarWidget")`.

Two consequences:

- The broadcast never fired, so the Android widget only ever refreshed on its
  own `updatePeriodMillis`, which `chores_star_widget_info.xml` sets to
  86400000 ms — **once a day**.
- The rejected Future was never awaited at the `ref.listen` call site, so it
  escaped to the zone handler and `PlatformDispatcher.instance.onError`
  (`main.dart:75`) recorded it in Crashlytics as **fatal**, once per widget
  update attempt.

`saveWidgetData` was unaffected — it needs no class name — so the payload was
being written correctly all along; only the redraw was broken.

### The rest of the Android setup is sound

Checked and correct:

- `AndroidManifest.xml` declares the receiver as `.ChoresStarWidgetProvider`,
  `exported="true"`, with the `APPWIDGET_UPDATE` intent filter and the
  `android.appwidget.provider` meta-data pointing at
  `@xml/chores_star_widget_info`.
- `applicationId`, `namespace` and the Kotlin source package all agree on
  `com.hoque.familychores`, so `context.packageName` resolves the provider
  class. (home_widget uses the *applicationId*, not the source package — pinned
  by a test now.)
- Every view id the provider writes (`widget_container`, `widget_greeting`,
  `widget_badge`, `widget_missions`, `widget_streak`) exists in
  `res/layout/chores_star_widget.xml`.
- `chores_star_widget_info.xml` supplies `targetCellWidth`/`targetCellHeight`
  alongside `minWidth`/`minHeight`, so it sizes correctly on Android 12+.
- Tapping uses `HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)`
  with `MainActivity` at `launchMode="singleTop"`. No URL scheme is involved, so
  **the iOS launch bug never applied to Android** — which matches the report.

Remaining Android polish, not fixed here:

- `chores_star_widget_info.xml` has no `android:description`, so the widget
  picker on API 31+ shows no subtitle.
- `previewImage` is `@mipmap/launcher_icon` — the app icon, not a preview of the
  widget itself.
- `updatePeriodMillis` of 24h is now only a backstop, but it is also the floor
  for anyone who never opens the Home tab (see finding 2).

### 8. Minor

- `connectivity_plus` is a dependency and is never imported anywhere in `lib/`.
- `.env` is loaded at `main.dart:49` but `dotenv` is never read, and no `.env`
  asset is declared in `pubspec.yaml` — every launch logs the "No .env file
  found" warning.
- `ChoresStarWidget.swift` only supports `.systemSmall`; no accessory or
  medium families.

## What was fixed on `fix/widget-launch-and-sync`

| Finding | Status |
| --- | --- |
| Root cause — URL launch wedges startup | Fixed, `ios/Runner/AppDelegate.swift` |
| 1. Widget never gets its first payload | Fixed, `syncHomeWidget` |
| 2. Sync scoped to HomeScreen's data branch | **Not fixed** — still only runs while Home is showing loaded tasks |
| 3. Deep link registered but inert | **Not fixed** — the URL is now safely ignored rather than routed |
| 4. `FamilyGate` swallows `AuthStatus.error` | Fixed |
| 5. Retry retries nothing | Fixed |
| 6. `AuthNotifier` never listens to auth state | Fixed, subscribes in `build()` |
| 7. Android: every widget refresh threw | Fixed, `home_widget_bridge.dart` |

Also fixed in passing: `_SplashScreen` armed a `Future.delayed` that was never
cancelled on dispose; it is a cancellable `Timer` now.

## What was verified how

- Built a debug simulator build of `main`, installed on iPhone 16 Pro (iOS 18.5)
  with a live signed-in session, and captured `log stream` output for a cold
  launch: startup completes and the profile stream delivers in well under a
  second.
- Delivered `hoquefamilychores://home` to the **running** app: harmless, no
  state change — consistent with the fault being specific to the launch-time
  window.
- A cold launch *through* the URL could not be reproduced locally: the simulator
  prompts "Open in Chores Star?" and there is no GUI window session available to
  dismiss it, so the mechanism above is established from source, not from a
  local repro.

  **Two checks remain, both needing an iOS device:**

  1. Force-quit, tap the widget → expect Home.
  2. Sign out, sign in with Google → expect it to work. The new
     `application(_:open:options:)` override sits on the launch path for every
     URL the app opens. The reverse-client-id scheme falls through to `super`
     by construction, but OAuth breaking would be a worse bug than the one
     being fixed, so it must be exercised rather than reasoned about.
- After the fix, a cold launch on the simulator reaches Home and the shared
  container holds a real payload with nothing having changed after load —
  `greeting => "Hi Abboo!"` — which is finding 1 verified end to end.
- Android, on an API 36 emulator with a live session — the A/B that pins
  finding 7. With the shipped name, logcat on every launch:

  ```
  ⛔ [HomeWidget] Failed to push data to the home-screen widget
     PlatformException(-3, No Widget found with Name ChoresStarWidget…,
     java.lang.ClassNotFoundException: com.hoque.familychores.ChoresStarWidget)
     at es.antonborri.home_widget.HomeWidgetPlugin.onMethodCall(HomeWidgetPlugin.kt:108)
  ```

  With the fix, no such line — and `shared_prefs/HomeWidgetPreferences.xml`
  holds a real payload (`greeting = "Hi Abboo!"`) written on load with nothing
  having changed after. The APK's dex confirms why: it contains
  `Lcom/hoque/familychores/ChoresStarWidgetProvider;` and no
  `…/ChoresStarWidget;` at all, so the old name could only ever throw.
  That log line is also finding 7's second half fixed: the failure is logged
  now instead of escaping to `PlatformDispatcher.onError` as a fatal
  Crashlytics report.
- 532 tests pass; `flutter analyze` is clean. New coverage:
  `test/utils/home_widget_names_consistency_test.dart` (platform names and the
  URL scheme pinned across Dart, Swift, Info.plist, AppDelegate and the Android
  manifest), `test/presentation/screens/family_gate_test.dart`,
  `test/presentation/providers/riverpod/home_widget_sync_test.dart`.
