# Personal Fork — Implementation Status

**Fork:** personal V1 of `ryanbr/noop` (upstream `main` @ `0e56473`, "build: testing build 541 / 422", app 11.8.0)
**Branch:** `feature/personal-v1` (commit from `main`)
**Date:** 2026-10-22 · **Task:** 3 (iOS Engineer, personal V1 fork)

---

## Current phase

**V1 code complete.** All nine scoped features are implemented additively on top of upstream
`main`; the branch is ready to push for CI compile verification and then real-device validation.

- Audit / blueprint: [`PERSONAL_FORK_ARCHITECTURE.md`](PERSONAL_FORK_ARCHITECTURE.md) (Task 1-a) —
  §12 at the end of that file maps every V1 feature → files added → integration point.
- Live interactive prototype of the same UX (web): the NOOP Personal V1 Command Center at the
  workspace Next.js app (Task 2-a/2-b) — useful for UX validation while CI runs.

## Completed, per feature

| # | Feature | Status | Files | Integration point |
|---|---|---|---|---|
| A | **Personal Today** (glance dashboard: YOU NOW / TODAY / LAST NIGHT / NEXT / quick actions) | ✅ | `StrandiOS/Personal/PersonalTodayView.swift` (new) | `RootTabView.todayTabRoot` swaps on `noop.personalTodayEnabled` (default ON in this fork), ahead of liquid/classic; the header layout menu writes the same keys for one-tap fallback |
| B | **Wrist screen** (link chain · device · stream · sync · actions · alarms · quiet hours) | ✅ | `Strand/Screens/WristView.swift` (new, cross-platform) | `MoreDestination.wrist` + More row; `NavRouter.Destination.wrist` + `openWrist()` (macOS maps it to the Devices sidebar row) |
| C | **Connection Guardian** (pure observer → named state + honest copy + recovery actions) | ✅ | `Strand/BLE/ConnectionGuardian.swift` (new, cross-platform) | `GuardianStatusBanner` (shared banner, defined in WristView.swift) shown on Personal Today + Wrist; zero BLEManager changes |
| D | **Alarms** (app-side schedules + explicit arm-to-strap through the existing funnel) | ✅ | `StrandiOS/Personal/PersonalAlarms.swift` (new) | `MoreDestination.personalAlarms` + More row; wake schedules copy into the SAME `BehaviorStore` fields SmartAlarmView edits, then the SAME `AppModel.applySmartAlarm()` (`armStrapAlarm`, #535 path) |
| E | **Haptics** (named presets + honest reminder scheduler) | ✅ | `StrandiOS/Personal/PersonalHapticPatterns.swift`, `StrandiOS/Personal/WristHapticScheduler.swift` (new) | Patterns fire only via `AppModel.buzz(loops:)` / `buzzStrapOnce()` (proven paths); reminders quiet-hours-gated reading the `notif.quietHours*` keys; UNUserNotification fallback is status-only |
| F | **Coach cleanup** (structured context + labelled attachment + prompts) | ✅ | `Strand/AI/CoachContextBuilder.swift` (new, cross-platform); edits: `AICoach.swift`, `CoachView.swift`, `CoachPrompts.swift` | Appended inside `AICoachEngine.buildFullContext()` (same consent-gated text channel); CoachView gains an additive context badge; CoachPrompts gains 2 suggestions (original 4 untouched). API key already lives in the Keychain (`AIKeyStore`) — no migration needed |
| G | **Developer Lab isolation** | ✅ (verified already isolated; grouping added) | edit: `RootTabView.swift` | Test Centre moved into its own clearly-labelled "Developer Lab" More section, collapsed by default (title not in `MoreSectionPrefs.defaultExpanded`). Probes were already gated behind `TestCentre.active(.connection)` in DevicesView; no probe auto-popups exist (verified — results only render in gated sheets) |
| H | **App Intents** | ✅ (additive; 3 of 4 already existed) | edits: `StrandiOS/System/NOOPAppIntents.swift`, `StrandiOS/App/AppModel+iOS.swift` | NEW: `ShowWristStatusIntent` (queues `.showWrist`, registered in `NOOPShortcuts`, drained on `.active` → `router.openWrist()`). Buzz / Ask Coach / Sync already existed upstream (`BuzzStrapIntent` / `AskCoachIntent` / `SyncStrapIntent`) and are reused as-is |
| I | **CI push trigger** (the one fork-local CI change) | ✅ | edit: `.github/workflows/app-build.yml` | `push: branches: [main]` added with the same path filter (duplicated — no YAML anchors in Actions), with the cost rationale in a comment. `fork-release.yml` / `fork-testing-build.yml` untouched |

## Build status

- **Local (2026-09-28):** macOS with Swift command-line tools, but no full Xcode/XCTest installation.
  Swift source parsing, focused headless resolver checks, Source Hygiene, the exact i18n audit,
  153 core Python tests and 234 capture tests are locally validated. App builds and StrandTests
  require the Xcode-backed GitHub runners; see PR #2's current checks for their live result.
- **CI:** `app-build.yml` will run on push of this branch's commits to `main` (or via the PR /
  dispatch paths). Matrix: `Strand` on macos-15 (universal + **runs StrandTests**) and `NOOPiOS` on
  macos-26 (iOS 26 SDK, compile-only). `swift-packages.yml` also runs on push (path-filtered).
- **Unsigned IPA:** produced on demand by the untouched `fork-testing-build.yml` (rolling
  `testing-latest` prerelease) and `fork-release.yml` (versioned + AltStore manifest update).

## Test status

- `StrandTests` run via the macOS leg of `app-build.yml` for PR #2. New regression tests cover
  Guardian sync/pairing/backfill priority, banked Last Night sleep and sparse-history trend windows,
  and delayed notification callbacks after edit/cancel/re-enable.
- Package suites run via `swift-packages.yml` (no packages were modified — no package-level risk).

## Known blockers

- None code-side. The remaining requirements are environmental: push to the GitHub fork, let CI
  compile, then validate on a real WHOOP 4.0 + iPhone (BLE behavior cannot be CI-verified —
  AGENTS.md's standing rule).

## Manual validation remaining

See [`REAL_DEVICE_TEST_CHECKLIST.md`](REAL_DEVICE_TEST_CHECKLIST.md) — 14 sequential checks
(launch → history → pair → live HR → battery → backfill → buzz → alarm → background/reopen →
BT off/on → Coach key + ask → Shortcut run → relaunch persistence → Developer Lab isolation),
each with what to tap, what should happen, and what to capture ONLY if it fails.

## Honesty notes (read before testing)

- **Reminders need the app alive.** iOS suspends a backgrounded app, so app-side reminder buzzes
  fire only while NOOP is foregrounded (or within the brief background grace); a local notification
  is the fallback tap. The dependable timed wrist event remains the strap's own firmware wake alarm.
- **The strap holds ONE alarm.** "Arm as strap alarm" copies a wake schedule into that single alarm
  (the same one the Alarms screen edits). This is modelled explicitly in the UI.
- **Today's default changed in this fork:** the personal glance dashboard replaces the liquid layout
  as the default Today. The header's layout menu (⋯ rectangle icon) falls back to Liquid or Classic
  at any time.
