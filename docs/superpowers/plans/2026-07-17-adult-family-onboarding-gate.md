# Adult Family Onboarding Gate — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline) or subagent-driven-development. Steps use checkbox syntax.

**Goal:** After an adult signs in with Apple/Google (no family), show a hard onboarding gate to create a family or join one by invite code (as parent or guardian), instead of dropping them on an empty Home tab.

**Architecture:** No backend/rules changes — `JoinFamilyUseCase` already does the work. Add a profile-aware `_FamilyGate` in `main.dart` that keys on `authNotifierProvider.user` (null → splash, empty familyId → onboarding, else → MainScreen). Extract the existing create/join UI from the Family tab into a shared `FamilyOnboardingScreen`, swapping the join card's parent/child switch for a parent/guardian picker.

**Tech Stack:** Flutter, Riverpod (codegen Notifier), freezed AuthState, mocktail.

Spec: `docs/superpowers/specs/2026-07-17-adult-family-onboarding-gate-design.md`

---

## Task 1: Confirm join works for parent AND guardian (backend confidence test)

The capability exists; lock it with a test so the picker's two values are both proven.

**Files:**
- Test: `test/domain/usecases/family/join_family_role_test.dart` (create)
- Under test: `lib/domain/usecases/family/join_family_usecase.dart` (no change)

- [ ] **Step 1:** Read `join_family_usecase.dart` and `join_family_as_child_usecase_test.dart` to mirror the mock setup (MockFamilyRepository, MockUserRepository, a User with `familyId: FamilyId.empty`, a FamilyEntity resolvable by code).
- [ ] **Step 2:** Write a parametrised test: for `role` in {parent, guardian}, `JoinFamilyUseCase(...)(inviteCode: 'AB3XY9', userId: me, role: role)` returns Right, calls `addUserToFamily(family.id, me)`, and calls `updateUserProfile` with a user whose `familyId == family.id` and `role == role`.
- [ ] **Step 3:** `flutter test test/domain/usecases/family/join_family_role_test.dart` — expect PASS (proves the backend already supports guardian).
- [ ] **Step 4:** Commit.

## Task 2: Extract `FamilyOnboardingScreen` with a parent/guardian picker

**Files:**
- Create: `lib/presentation/screens/family_onboarding_screen.dart`
- Modify: `lib/presentation/screens/family_screen.dart` (use the new screen; delete `_FamilyOnboardingView`)
- Test: `test/presentation/family_onboarding_screen_test.dart` (create)

- [ ] **Step 1:** Create `family_onboarding_screen.dart` — move `_FamilyOnboardingView` verbatim, rename to public `FamilyOnboardingScreen extends ConsumerStatefulWidget` (keep `final User currentUser`). Copy imports it needs (material, services not needed, riverpod, user.dart, auth_notifier.dart, family_onboarding_notifier.dart, app_tokens.dart).
- [ ] **Step 2:** In that file replace the join role control:
  - Remove `bool _joinAsParent = false;` → add `UserRole _joinRole = UserRole.parent;`.
  - Replace the `SwitchListTile('I am a parent/guardian')` with a parent/guardian selector (SegmentedButton or two ChoiceChips), keyed `join_role_parent` / `join_role_guardian`, defaulting to parent. Keep a `Key('join_role_selector')` on the wrapper.
  - In `_joinFamily`, change `role: _joinAsParent ? UserRole.parent : UserRole.child` → `role: _joinRole`.
- [ ] **Step 3:** Add a Sign out action to the `AppBar` (`IconButton(Icons.logout)` → `ref.read(authNotifierProvider.notifier).signOut()`), so the hard gate has an escape for a wrong-account sign-in.
- [ ] **Step 4:** In `family_screen.dart`: delete the entire `_FamilyOnboardingView` + its State class; change line 30 to `return FamilyOnboardingScreen(currentUser: currentUser);`; add the import; remove now-unused imports (family_onboarding_notifier if only that view used it — check).
- [ ] **Step 5:** `flutter analyze` — expect no issues.
- [ ] **Step 6:** Write `family_onboarding_screen_test.dart`: pump `FamilyOnboardingScreen(currentUser: <no-family user>)` inside a ProviderScope overriding `familyOnboardingNotifierProvider` with a fake notifier that records `joinFamily`'s `role` arg. Tap `join_role_guardian`, enter a code in `invite_code_field`, tap `join_family_button`; assert the recorded role is `UserRole.guardian`. (Model the override on an existing presentation test.)
- [ ] **Step 7:** `flutter test test/presentation/family_onboarding_screen_test.dart` — expect PASS.
- [ ] **Step 8:** Commit.

## Task 3: The hard gate in `main.dart`

**Files:**
- Modify: `lib/main.dart` (add `_FamilyGate`, use it in the `hasData` branch)
- Test: `test/presentation/family_gate_test.dart` (create)

- [ ] **Step 1:** Write `family_gate_test.dart` first (TDD). Pump `_FamilyGate` (make it a top-level `class FamilyGate` so it's importable, not `_`-private) in a ProviderScope overriding `authNotifierProvider` to yield, across three tests:
  - `AuthState(status: authenticated, user: null)` → finds a `CircularProgressIndicator`/splash, NOT the onboarding "Set up your family" text and NOT MainScreen.
  - `AuthState(user: <familyId empty>)` → finds "Set up your family" (FamilyOnboardingScreen).
  - `AuthState(user: <familyId set>)` → finds MainScreen's bottom nav (e.g. a tab label), NOT "Set up your family".
- [ ] **Step 2:** `flutter test test/presentation/family_gate_test.dart` — expect FAIL (FamilyGate doesn't exist).
- [ ] **Step 3:** In `main.dart` add:
```dart
class FamilyGate extends ConsumerWidget {
  const FamilyGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    // Authenticated but the profile stream hasn't delivered yet: wait, don't
    // guess. Treating null as "no family" would flash onboarding at a user who
    // actually has one. See auth_notifier.dart:52-57.
    if (user == null) return const _SplashScreen();
    if (user.familyId.value.isEmpty) {
      return FamilyOnboardingScreen(currentUser: user);
    }
    return const MainScreen();
  }
}
```
  Convert `MyApp` from `StatelessWidget` to `ConsumerWidget` **or** keep it and just place `const FamilyGate()` in the `hasData` branch (FamilyGate is its own ConsumerWidget, so `MyApp` need not change). Replace `return const MainScreen();` (line ~153) with `return const FamilyGate();`. Add imports for `FamilyOnboardingScreen` and `authNotifierProvider`.
- [ ] **Step 4:** `flutter test test/presentation/family_gate_test.dart` — expect PASS.
- [ ] **Step 5:** Commit.

## Task 4: Green everything

- [ ] **Step 1:** `flutter analyze` → No issues.
- [ ] **Step 2:** `flutter test` → all pass (existing family/auth tests still green; the child-join and create paths are untouched).
- [ ] **Step 3:** Commit any fixups. Open PR to main, closes TASK-454.

## Notes
- **Do NOT** change `JoinFamilyUseCase`, `CreateFamilyUseCase`, `family_onboarding_notifier.dart`, or `firestore.rules` — all already correct.
- Children never hit the gate (their join is atomic, pre-`MainScreen`).
- Create path stays parent-only (no picker) per the design decision.
</content>
