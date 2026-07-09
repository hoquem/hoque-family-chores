# Auth Phase 1 — OAuth for Parents Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add "Sign in with Apple" and "Continue with Google" for adults, alongside the existing email/password login, and make a first-time OAuth user a `parent` with a Firestore profile — without breaking the current email/password flow (children still use it in Phase 1).

**Architecture:** Extend the existing `AuthRepository` abstraction with OAuth methods + an `authStateChanges` stream; implement them in `FirebaseAuthRepository` via `FirebaseAuth.signInWithCredential`. `AuthNotifier` gains OAuth entry points that reuse the existing profile-creation + profile-stream logic, defaulting new adults to `role: parent`. The app's routing (`main.dart` `StreamBuilder` on `authStateChanges()`) is untouched — an OAuth sign-in creates a Firebase session exactly like email/password, so it "just works." This phase stays on the Firebase **free (Spark)** tier; no Cloud Functions.

**Tech Stack:** Flutter, Riverpod (codegen), Firebase Auth, `sign_in_with_apple`, `google_sign_in`, `crypto` (Apple nonce). Spec: `docs/superpowers/specs/2026-07-09-auth-redesign-design.md`.

**Reference skills:** @superpowers:test-driven-development, @superpowers:verification-before-completion. For Firebase/Flutter API specifics, consult context7 (`sign_in_with_apple`, `google_sign_in`, `firebase_auth`).

---

## File Structure

- **Modify** `lib/domain/repositories/auth_repository.dart` — add `authStateChanges`, `signInWithApple()`, `signInWithGoogle()`.
- **Modify** `lib/data/repositories/firebase_auth_repository.dart` — implement the three, plus account-collision mapping.
- **Create** `lib/data/auth/apple_nonce.dart` — pure nonce/hash helpers (unit-testable).
- **Modify** `lib/domain/usecases/user/initialize_user_data_usecase.dart` — add optional `role` param.
- **Modify** `lib/presentation/providers/riverpod/auth_notifier.dart` — add `signInWithApple()`/`signInWithGoogle()`.
- **Modify** `lib/presentation/screens/login_screen.dart` — add OAuth buttons (keep email form).
- **Modify** `test/mocks/mock_auth_repository.dart` — implement new interface members.
- **Create** tests under `test/data/auth/`, `test/domain/usecases/user/`, `test/presentation/`.
- **Modify** `ios/Runner/Info.plist`, **create** `ios/Runner/Runner.entitlements` — Apple capability + Google URL scheme.
- **Modify** `pubspec.yaml` — dependencies.

---

## Task 0: Branch + dependencies

**Files:** Modify `pubspec.yaml`

- [ ] **Step 1: Create the feature branch**

Run:
```bash
git checkout -b feature/auth-phase1-oauth
```

- [ ] **Step 2: Add dependencies**

Add under `dependencies:` in `pubspec.yaml` (check pub.dev for latest compatible versions):
```yaml
  sign_in_with_apple: ^6.1.4
  google_sign_in: ^6.2.1
  crypto: ^3.0.3
```

- [ ] **Step 3: Install and verify**

Run: `flutter pub get`
Expected: resolves with no version conflicts.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add sign_in_with_apple, google_sign_in, crypto for OAuth"
```

---

## Task 1: iOS native config (manual — verify by build)

These are Xcode/Firebase config steps, not code. **The Firebase Console steps require the user's login** — flag them as user actions if not already done.

**Files:** Create `ios/Runner/Runner.entitlements`; Modify `ios/Runner/Info.plist`

- [ ] **Step 1 (USER): enable providers in Firebase Console**

In Firebase Console → Authentication → Sign-in method: enable **Apple** and **Google**. Then **re-download `GoogleService-Info.plist`** (it now contains `CLIENT_ID` / `REVERSED_CLIENT_ID`, which the current file lacks) and replace `ios/Runner/GoogleService-Info.plist`.

- [ ] **Step 2: add the Sign in with Apple entitlement**

Create `ios/Runner/Runner.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```
Then reference it in the Runner target's build settings (`CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`) — set via Xcode (Signing & Capabilities → + Capability → Sign in with Apple) or by editing `ios/Runner.xcodeproj/project.pbxproj`.

- [ ] **Step 3: add the Google URL scheme**

Read the `REVERSED_CLIENT_ID` value from the new `GoogleService-Info.plist`, then add to `ios/Runner/Info.plist` (inside the top-level `<dict>`):
```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>REVERSED_CLIENT_ID_VALUE_HERE</string>
			</array>
		</dict>
	</array>
```

- [ ] **Step 4: verify the app still builds**

Run: `flutter build ios --debug --no-codesign`
Expected: build succeeds (entitlement + plist parse correctly).

- [ ] **Step 5: Commit**

```bash
git add ios/Runner/Runner.entitlements ios/Runner/Info.plist ios/Runner/GoogleService-Info.plist ios/Runner.xcodeproj/project.pbxproj
git commit -m "chore(ios): add Sign in with Apple capability + Google URL scheme"
```

---

## Task 2: Apple nonce helper (pure, TDD)

Apple sign-in requires a cryptographic nonce: a random string sent as the SHA-256 hash, with the raw value handed to Firebase. Isolate it as a pure function so it is unit-testable.

**Files:** Create `lib/data/auth/apple_nonce.dart`; Test `test/data/auth/apple_nonce_test.dart`

- [ ] **Step 1: Write the failing test**

`test/data/auth/apple_nonce_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hoque_family_chores/data/auth/apple_nonce.dart';

void main() {
  test('generateNonce returns a string of the requested length', () {
    expect(generateNonce(length: 32).length, 32);
  });

  test('generateNonce returns different values each call', () {
    expect(generateNonce(), isNot(generateNonce()));
  });

  test('sha256OfString matches crypto sha256 hex', () {
    expect(sha256OfString('abc'),
        sha256.convert(utf8.encode('abc')).toString());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/auth/apple_nonce_test.dart`
Expected: FAIL — `apple_nonce.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

`lib/data/auth/apple_nonce.dart`:
```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

const _charset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

/// Returns a cryptographically secure random string of [length] chars.
String generateNonce({int length = 32}) {
  final random = Random.secure();
  return List.generate(length, (_) => _charset[random.nextInt(_charset.length)])
      .join();
}

/// Returns the hex SHA-256 of [input].
String sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/auth/apple_nonce_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/auth/apple_nonce.dart test/data/auth/apple_nonce_test.dart
git commit -m "feat(auth): add Apple sign-in nonce helper"
```

---

## Task 3: Extend the AuthRepository interface + mock

**Files:** Modify `lib/domain/repositories/auth_repository.dart`, `test/mocks/mock_auth_repository.dart`; Test `test/mocks/mock_auth_repository_oauth_test.dart`

- [ ] **Step 1: Write the failing test** (drives the interface + mock)

`test/mocks/mock_auth_repository_oauth_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/repositories/auth_repository.dart';
import '../mocks/mock_auth_repository.dart';

void main() {
  test('signInWithGoogle sets currentUser and emits on authStateChanges',
      () async {
    final AuthRepository repo = MockAuthRepository();
    final emissions = <dynamic>[];
    final sub = repo.authStateChanges.listen(emissions.add);

    final user = await repo.signInWithGoogle();

    expect(user, isNotNull);
    expect(repo.currentUser, isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(emissions.last, isNotNull);
    await sub.cancel();
  });

  test('signInWithApple sets currentUser', () async {
    final AuthRepository repo = MockAuthRepository();
    final user = await repo.signInWithApple();
    expect(user, isNotNull);
    expect(repo.currentUser, isNotNull);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/mocks/mock_auth_repository_oauth_test.dart`
Expected: FAIL — `signInWithGoogle`/`signInWithApple`/`authStateChanges` not defined.

- [ ] **Step 3: Add the interface members**

In `lib/domain/repositories/auth_repository.dart`, add to the abstract class:
```dart
  /// Stream of auth state changes (null = signed out).
  Stream<dynamic> get authStateChanges;

  /// Sign in with Apple (OAuth). Returns the raw Firebase user.
  Future<dynamic> signInWithApple();

  /// Sign in with Google (OAuth). Returns the raw Firebase user.
  Future<dynamic> signInWithGoogle();
```

- [ ] **Step 4: Implement them in the mock**

In `test/mocks/mock_auth_repository.dart`: add a broadcast controller and methods.
```dart
  final _authStateController = StreamController<FakeFirebaseUser?>.broadcast();

  @override
  Stream<dynamic> get authStateChanges => _authStateController.stream;

  @override
  Future<dynamic> signInWithApple() async {
    _currentUser = FakeFirebaseUser(uid: 'mock_apple_uid', email: 'apple@example.com');
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<dynamic> signInWithGoogle() async {
    _currentUser = FakeFirebaseUser(uid: 'mock_google_uid', email: 'google@example.com');
    _authStateController.add(_currentUser);
    return _currentUser;
  }
```
Also emit on the existing `signOut()` (`_authStateController.add(null);`).

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/mocks/mock_auth_repository_oauth_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/repositories/auth_repository.dart test/mocks/mock_auth_repository.dart test/mocks/mock_auth_repository_oauth_test.dart
git commit -m "feat(auth): add OAuth + authStateChanges to AuthRepository interface"
```

---

## Task 4: Implement OAuth in FirebaseAuthRepository

Live Firebase/provider calls cannot be unit-tested without device/emulator; keep the method bodies thin and delegate pure logic (nonce) to Task 2. Verify on device in Task 8. Do add a test for **account-collision error mapping** using an injected fake `FirebaseAuth` if `firebase_auth_mocks` is available; otherwise assert the mapping via a small extracted pure function.

**Files:** Modify `lib/data/repositories/firebase_auth_repository.dart`

- [ ] **Step 1: Implement `authStateChanges`**
```dart
  @override
  Stream<dynamic> get authStateChanges => _auth.authStateChanges();
```

- [ ] **Step 2: Implement `signInWithGoogle`**
```dart
  @override
  Future<dynamic> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in cancelled', code: 'SIGN_IN_CANCELLED');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapOAuthError(e);
    }
  }
```

- [ ] **Step 3: Implement `signInWithApple`** (uses Task 2 helpers)
```dart
  @override
  Future<dynamic> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: sha256OfString(rawNonce),
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      final cred = await _auth.signInWithCredential(oauthCredential);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw _mapOAuthError(e);
    }
  }
```

**Account-collision decision (spec §9/§11):** for a family-scale app we deliberately
choose **error-only, no auto-linking** — map `account-exists-with-different-credential`
to a clear message telling the user which provider to use. We do **not** implement
`fetchSignInMethodsForEmail` + `linkWithCredential`. Apple "Hide My Email" yields a
real relay address, so it does not produce a null email. Record this as the decision;
revisit only if a real user hits it.

- [ ] **Step 4: Add the collision mapper** (per the decision above)
```dart
  AuthException _mapOAuthError(FirebaseAuthException e) {
    if (e.code == 'account-exists-with-different-credential') {
      return AuthException(
        'This email is already registered with a different sign-in method. '
        'Please use the provider you signed up with.',
        code: 'ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL',
      );
    }
    return AuthException('OAuth sign-in failed: ${e.message}', code: e.code);
  }
```
Add imports: `sign_in_with_apple`, `google_sign_in`, and `../auth/apple_nonce.dart`.

- [ ] **Step 5: Verify it compiles + existing tests still pass**

Run: `flutter analyze && flutter test`
Expected: 0 analyzer issues; all existing tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/firebase_auth_repository.dart
git commit -m "feat(auth): implement Apple/Google sign-in in FirebaseAuthRepository"
```

---

## Task 5: Default OAuth adults to `parent`

**Files:** Modify `lib/domain/usecases/user/initialize_user_data_usecase.dart`; Test `test/domain/usecases/user/initialize_user_data_role_test.dart`

- [ ] **Step 1: Write the failing test**
```dart
// Arrange a mock user repository; call the usecase with role: UserRole.parent;
// assert the created User has role == UserRole.parent and familyId is empty.
```
(Use the existing `test/mocks/mock_user_repository.dart` pattern; assert on the captured created user.)

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/domain/usecases/user/initialize_user_data_role_test.dart`
Expected: FAIL — the usecase has no `role` parameter.

- [ ] **Step 3: Add the optional `role` parameter (and keep the loud email check)**

In `initialize_user_data_usecase.dart`, add `UserRole role = UserRole.child` to `call(...)` and use it in the `User(... role: role ...)` construction (replacing the hardcoded `UserRole.child`). **Do not** weaken the existing "email must be non-empty" validation — it stays. The OAuth caller (Task 6) is responsible for supplying a real email or failing loudly; this use case must never receive an empty string masked by a fallback (per the global "no fallbacks to hide issues" rule).

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/domain/usecases/user/initialize_user_data_role_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/usecases/user/initialize_user_data_usecase.dart test/domain/usecases/user/initialize_user_data_role_test.dart
git commit -m "feat(user): allow role override in InitializeUserDataUseCase (default child)"
```

---

## Task 6: AuthNotifier OAuth entry points

**Files:** Modify `lib/presentation/providers/riverpod/auth_notifier.dart`; Test `test/presentation/auth_notifier_oauth_test.dart`

- [ ] **Step 1: Write the failing test**

With `authRepositoryProvider` overridden to `MockAuthRepository` and the user repo mocked: call `signInWithGoogle()`; assert (a) a profile doc is created with `role: parent` when none exists, (b) `state.status == authenticated`, and (c) when the fake Firebase user has a null/empty email, no profile is created and `state.status == error` with the provider-email message (loud failure, not a silent empty string). Make `MockAuthRepository.signInWithGoogle` support a null-email variant for this case.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/presentation/auth_notifier_oauth_test.dart`
Expected: FAIL — `signInWithGoogle` not defined on notifier.

- [ ] **Step 3: Implement the methods**

Add to `AuthNotifier` a private `_afterOAuth(dynamic firebaseUser)` that: extracts `UserId(firebaseUser.uid)`; checks if a profile exists (via `getUserProfileUseCaseProvider` — confirmed to exist in `riverpod_container.g.dart`); if a profile already exists, just start the stream; if not, **require a real email** and create the profile as a parent:
```dart
final email = firebaseUser.email as String?;
if (email == null || email.trim().isEmpty) {
  state = state.copyWith(
    isLoading: false, status: AuthStatus.error,
    errorMessage: 'Could not get your email from the sign-in provider. '
        'Please try the other provider (Apple/Google).');
  return; // fail loudly — no empty-string fallback
}
await initializeUserData.call(
  userId: userId,
  name: (firebaseUser.displayName as String?)?.trim().isNotEmpty == true
      ? firebaseUser.displayName as String
      : email.split('@').first,
  email: email.trim().toLowerCase(),
  role: UserRole.parent,
);
```
then `_startUserProfileStream(userId)` and `status: authenticated`. Expose:
```dart
  Future<void> signInWithApple() => _oauth(() =>
      ref.read(authRepositoryProvider).signInWithApple());
  Future<void> signInWithGoogle() => _oauth(() =>
      ref.read(authRepositoryProvider).signInWithGoogle());
```
where `_oauth(fn)` wraps loading/error state like `signIn` does and calls `_afterOAuth`.

**Codegen note:** these are plain instance methods on the existing `@riverpod AuthNotifier`; the `AuthState` shape is unchanged, so no `build_runner` run is required for this task. (Only re-run codegen if you add/rename a provider or change `AuthState`'s fields.)

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/presentation/auth_notifier_oauth_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/providers/riverpod/auth_notifier.dart test/presentation/auth_notifier_oauth_test.dart
git commit -m "feat(auth): OAuth sign-in in AuthNotifier, new adults become parent"
```

---

## Task 7: Login screen OAuth buttons

**Files:** Modify `lib/presentation/screens/login_screen.dart`; Test `test/presentation/login_screen_oauth_test.dart`

- [ ] **Step 1: Write the failing widget test**

Pump `LoginScreen` with `authNotifierProvider` overridden; assert a "Continue with Google" button and a Sign in with Apple button are present; tapping Google invokes the notifier's `signInWithGoogle` (spy via an override).

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/presentation/login_screen_oauth_test.dart`
Expected: FAIL — buttons absent.

- [ ] **Step 3: Add the buttons**

Above the email `TextField`s add a `SignInWithAppleButton(onPressed: () => ref.read(authNotifierProvider.notifier).signInWithApple())` and an `ElevatedButton.icon` "Continue with Google" calling `signInWithGoogle()`, then a divider "or use email". **Keep the email/password form and Sign In button (Phase 1 requirement — children still use email).**

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/presentation/login_screen_oauth_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/login_screen.dart test/presentation/login_screen_oauth_test.dart
git commit -m "feat(ui): add Apple/Google buttons to login (email kept for Phase 1)"
```

---

## Task 8: Full verification + ship to TestFlight

**Files:** Modify `pubspec.yaml` (build number)

- [ ] **Step 1: Static checks**

Run: `flutter analyze` → Expected: 0 issues.
Run: `flutter test` → Expected: all pass.

- [ ] **Step 2: On-device OAuth smoke test** (@superpowers:verification-before-completion)

Run the app on a real device / TestFlight-eligible build. Verify: Apple sign-in completes and lands on the family onboarding as a **parent**; Google sign-in same; email/password login still works; sign-out returns to login. Record the observed result — do not claim success without it.

- [ ] **Step 3: Bump build number**

In `pubspec.yaml` set `version: 1.0.0+11` (must exceed the highest uploaded, which is 10 — see `docs/DEPLOYMENT_CHECKLIST.md`).

- [ ] **Step 4: Build, upload, ship** (per `docs/DEPLOYMENT_CHECKLIST.md` working pipeline)

Run the archive → export → upload commands from the checklist, then confirm the build reaches the "Family" TestFlight group.

- [ ] **Step 5: Commit + open PR**

```bash
git add pubspec.yaml
git commit -m "chore: release 1.0.0+11 (Phase 1 OAuth for parents)"
git push -u origin feature/auth-phase1-oauth
gh pr create --fill
```

---

## Done criteria (Phase 1)

- Apple + Google sign-in work on device; new adults become `parent` with a Firestore profile.
- Email/password login untouched and functional (children unaffected).
- `flutter analyze` clean, all tests green, build 1.0.0+11 on TestFlight.
- No Cloud Functions, still Spark tier.
