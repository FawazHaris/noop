# NOOP Personal Fork — Architecture & Implementation Map (V1)

**Task ID:** 1-a · **Date:** 2026-10-22 · **Audited tree:** `ryanbr/noop` @ `0e56473` ("build: testing build 541 / 422", app version **11.8.0**, iOS build **422**, macOS build **198**)
**Scope:** static read-only audit of the upstream repo to decide REUSE vs BUILD for the 9 V1 personal-fork features. No Swift/YAML was modified to produce this document.

---

## 1. Executive summary of the repo architecture

NOOP is an **offline-by-default, on-device WHOOP 4.0/5.0 companion** (PolyForm Noncommercial license, anonymity-preserving, no App Store distribution). Core logic lives in cross-platform Swift packages; each platform is a thin app layer. **macOS is the reference implementation; Android is a full shipped app; iOS is a build-from-source / unsigned-IPA target that is already fully wired for AltStore/SideStore sideloading** (see §6 — this is the single biggest "already done" finding of this audit).

### 1.1 Targets (`project.yml` — XcodeGen is the source of truth; `Strand.xcodeproj/` is generated, never hand-edited)

| Target | Platform | Bundle ID | Notes |
|---|---|---|---|
| `Strand` | macOS 13+ | `$(BUNDLE_ID_PREFIX).noop.staging` (default `com.noopapp.noop.staging`) | PRODUCT_NAME "NOOP Staging", module name `Strand`. Own sidebar shell (`RootView`/`ContentView`), MenuBar. |
| `StrandTests` | macOS | `$(BUNDLE_ID_PREFIX).strandtests` | XCTest, **hosted in the macOS app** (`TEST_HOST` = NOOP Staging.app). Also compiles the pure iOS-only shared files (`StrandiOSShared/WidgetSnapshot.swift`, `HrTrace.swift`, `StressTrace.swift`, `WidgetTelemetry.swift`). |
| `NOOPiOS` | iOS 17+ | `$(BUNDLE_ID_PREFIX).noop` | Sources = `Strand/` (minus macOS-only excludes) + `StrandiOS/` + `StrandiOSShared/`. Embeds `NOOPWatch`. |
| `NOOPiOSWidgets` | iOS 17+ (app-extension) | `$(BUNDLE_ID_PREFIX).noop.widgets` | Sources = `StrandiOSWidgets/` + `StrandiOSShared/`. WidgetKit + Live Activities. |
| `NOOPWatch` | watchOS 10+ | `$(BUNDLE_ID_PREFIX).noop.watch` | Single-target SwiftUI watch app; displays `WatchScoreSnapshot` pushed from the phone. |
| `NOOPWatchComplications` | watchOS 10+ (app-extension) | `$(BUNDLE_ID_PREFIX).noop.watch.complications` | WidgetKit complications. |

Key build settings: `MARKETING_VERSION 11.8.0`; `CURRENT_PROJECT_VERSION 422` (shared by iOS app + widget + watch so extension versions match, #416); `SWIFT_VERSION 5.0`; `CODE_SIGN_STYLE: Automatic`; `SWIFT_STRICT_CONCURRENCY: minimal`; `SWIFT_EMIT_LOC_STRINGS: YES`; `APP_GROUP_ID = group.$(BUNDLE_ID_PREFIX).noop.staging` exposed to runtime via the `AppGroupIdentifier` Info.plist key (never hard-coded in Swift).

**Sources are included by directory globs with excludes** — a new file under `Strand/`, `StrandiOS/`, `StrandiOSShared/`, `StrandiOSWidgets/` is picked up by re-running `xcodegen generate`; no explicit file lists to maintain (exception: `StrandTests` deliberately compiles specific `StrandiOSShared` pure files).

`Config/BundleId.xcconfig` (tracked) defines `BUNDLE_ID_PREFIX = com.noopapp`; a fork overrides it via the **gitignored `Config/BundleIdSecrets.xcconfig`** (template: `Config/BundleIdSecrets.example.xcconfig`) — one file drives every target's bundle ID, the App Group, and the watch companion pairing. `DEVELOPMENT_TEAM` is also set there for physical-device builds.

SPM deps: **MarkdownUI 2.4.1** and **ZIPFoundation 0.9.20** pinned *exactly* (supply-chain policy) + local packages `WhoopProtocol`, `WhoopStore`, `StrandAnalytics`, `StrandImport`, `StrandDesign`, `OuraProtocol`, `PolarProtocol`. GRDB pinned (6.29.3) inside `Packages/WhoopStore/Package.swift`.

### 1.2 Layers (per `AGENTS.md`)

| Layer | Path | Contents |
|---|---|---|
| Protocol (pure, Linux-buildable) | `Packages/WhoopProtocol`, `Packages/OuraProtocol`, `Packages/PolarProtocol` | Frame parse/CRC/decode, probes, alarm & haptic payload encoders. **No CoreBluetooth, no UIKit/AppKit** — enforced by convention ("never `import AppKit`/`UIKit`/`CoreBluetooth` under `Packages/`"). |
| Storage | `Packages/WhoopStore` | GRDB/SQLite actor, migrations v1–v46, streams, caches, registry. |
| Analytics (pure) | `Packages/StrandAnalytics` | HRV/recovery/strain/sleep/correlation/stress/illness math, `TestDomain`. |
| Import | `Packages/StrandImport` | WHOOP CSV + Apple Health `export.xml` importers. |
| Design system | `Packages/StrandDesign` | `StrandPalette`/`StrandFont`/`NoopMetrics`, `NoopCard`, charts, `WatchScoreSnapshot`. |
| Shared app | `Strand/` | `App/` (AppModel, NavRouter, TabRoute, RootView…), `BLE/` (CoreBluetooth), `Collect/`, `Data/` (Repository, stores), `Screens/`, `Liquid/`, `AI/`, `System/`, `Oura/`. Shared with iOS where not macOS-only. |
| iOS-only app | `StrandiOS/`, `StrandiOSShared/`, `StrandiOSWidgets/`, `NOOPWatch*` | `StrandiOSApp` (@main), `RootTabView` (tab shell), HealthKit, widgets, intents, watch. |
| Android | `android/` | Kotlin/Compose/Room reimplementation (out of scope for the iOS fork, but the **parity contract** applies to any shared-schema/prefs change — see §4). |

### 1.3 Runtime data flow (iOS)

`StrandiOSApp.init` builds `AppModel` (which owns `ble: BLEManager`, `live: LiveState`, `repo: Repository`, `profile: ProfileStore`, `behavior: BehaviorStore`, `intelligence: IntelligenceEngine`, `coach: AICoachEngine`, device registry + `SourceCoordinator`), a `NavRouter`, `HealthKitBridge`, `WatchSessionBridge`, Live-Activity controllers, `LiftSessionController`, and registers BGTask handlers. `StrandiOSApp.body` injects them all as `@EnvironmentObject`s. Strap → `BLEManager` (CoreBluetooth central, GATT service `6108…`, WHOOP5 service `fd4b…`) → `FrameRouter` → `LiveState` (@Published live readouts) + `Backfiller` → `WhoopStore` (SQLite) → `Repository` caches (`refreshSeq`) → screens; `WidgetSnapshot.publish` writes a tiny Codable snapshot into the App Group for widgets/Live Activities; `WatchSessionBridge.pushLatest` pushes a `WatchScoreSnapshot` to the watch. The DB lives at **`<AppSupport>/OpenWhoop/whoop.sqlite`** (`Strand/Collect/StorePaths.swift`) — inside the app container on iOS, with file protection downgraded to `completeUntilFirstUserAuthentication` so background BLE can write while locked (#222).

---

## 2. Reuse map — the 9 V1 features

Legend: **Reuse** = existing code covers it as-is; **Wrap** = build a thin new layer over existing systems; **Build** = genuinely new. "Risk" = integration risk for an additive personal fork.

| # | V1 feature | Existing assets (exact paths) | What's missing | Verdict / additive approach | Risk |
|---|---|---|---|---|---|
| 1 | **Glanceable Today dashboard redesign** | `Strand/Liquid/LiquidTodayView.swift` (3173 ln, default Today via `noop.liquidTodayEnabled`), `Strand/Liquid/LiquidCore.swift`+`LiquidPrimitives`+`LiquidSky`, classic `Strand/Screens/TodayView.swift` (5994 ln), section model `Strand/Data/TodayLayoutPrefs.swift` (`TodaySection`, reorder/hide via `today.sectionOrder`/`today.hiddenSections`), `Strand/Screens/DashboardCards.swift` (`DashboardCard` + `DashboardCardPrefs`, key `today.dashboardCards`), `Strand/Screens/HostedCards.swift` (cross-tab hosted cards, key `today.hostedCards`), `Strand/Screens/TodayCustomizationSheet.swift` + `TodayCustomizationMetadata.swift`, `Strand/Screens/ScreenScaffold.swift`, `Strand/Screens/EditableLayoutList.swift` | A personal "redesign" is a *composition* choice, not new plumbing: everything (reorderable sections, customisable card registry, customisation sheet, day-cycle scenes) exists | **Reuse heavily.** Either (a) ship a personal preference default for section order/cards (display-only UserDefaults — zero schema risk), or (b) add new `DashboardCard`/`TodaySection` cases for personal glance cards. Both are the documented extension points. Note: card/section rawValues are **byte-identical to Android** and ride `.noopbak` — for a personal fork adding new cases is safe (unknown ids are dropped on read on old builds), but do not rename existing ids | **Low** |
| 2 | **Dedicated Wrist screen** | Phone side: `Strand/Screens/SmartAlarmView.swift` (strap alarm + wind-down), `Strand/App/AppModel.swift` §"Wrist-buzz mirror notifications" (L1479: `postSmartAlarm`/`postInactivity`, gate `notif.masterEnabled`), `Strand/Screens/DevicesView.swift` (battery, firmware, clock line, probe UIs), `Strand/Data/WatchSessionBridge.swift`, `Strand/Screens/AppleWatchSetupView.swift`/`AppleWatchAboutView.swift`. Watch side: `NOOPWatch/` (`WatchRootView`, `WatchGlanceView`, `WatchLiveHR`, `WatchScoreStore`), `NOOPWatchComplications/`. Haptics: `Packages/WhoopProtocol/.../HapticPayloads.swift`, `HapticClock.swift`, `LiveSessionHaptics.swift`, `BLEManager.buzz`/`buzzTimeNow` | One unified phone screen that fuses strap-battery/firmware/clock + alarm controls + haptic tools + watch status; today these live across Devices/Alarms/Test Centre | **Wrap.** New additive `WristView` (Strand/Screens/) composed from existing stores (`LiveState`, `BehaviorStore`, `WatchSessionBridge`), routed per §3. Watch app itself is reuse-as-is (snapshot display only; sideload caveat — watch app is stripped from the IPA by CI, see §6) | **Low–Med** |
| 3 | **Connection Guardian layer** | `Strand/BLE/LiveState.swift` (connected/bonded/encryptedBond/historyReady/connectSettled/streamingLiveHR/pairingHint/reconnectGuide/backfilling/lastSyncedAt/sync counters/log), `Strand/BLE/StuckStrapDetector.swift`, `Strand/BLE/PendingConnectReplay.swift`, `Strand/BLE/BackfillPolicy.swift`, `Strand/BLE/HelloSuppression.swift`, bond watchdogs inside `BLEManager` (#982/#1635), `Strand/Screens/HealthAlertBanner.swift`, `Strand/BLE/LiveHeartRateReadability.swift` | A named, user-facing "guardian" state machine (connected → degraded → stale → recovering) that observes the existing signals and surfaces guidance | **Wrap — do NOT touch `BLEManager`** (7431 lines, hardware-sensitive, `didBond` is load-bearing per AGENTS.md). New pure `ConnectionGuardian` ObservableObject subscribing to `LiveState`/`AppModel` publishers; renders via banner + Wrist screen tile. AGENTS.md rule "a diagnostic may only assert what it can attribute" applies to its copy | **Med** (risk is only in *claiming* states the data can't support) |
| 4 | **Safe haptics + alarms** | WHOOP **4.0 alarm is hardware-confirmed** (#535): `BLEManager.armStrapAlarm(at:)` (`Strand/BLE/BLEManager.swift:5279` — SET_CLOCK both forms + SET_ALARM_TIME + GET_ALARM_TIME readback), `WhoopCommand.setAlarmPayload` (`Strand/BLE/Commands.swift`), disarm + deferred-disarm latch; backup `UNCalendarNotificationTrigger` + per-day fan-out in `AppModel.applySmartAlarm` (L1673) with pure `nextSmartAlarmDate` (unit-tested); persistence `Strand/Data/BehaviorStore.swift` (`behavior.smartAlarmMinutes` default 07:00, enabled, weekdays) + `WindDownNudge` per-day overrides; `SmartAlarmView` (783 ln) incl. reject-streak card (`alarm.rejectStreak`); buzz: `MaverickHaptics.notificationBuzz(loops:)` (cmd 19, hardware-confirmed loop semantics #926), `HapticClock` (read-the-time buzzes, pure, cross-platform pinned), `LiveSessionHaptics` (push/easeOff), `model.buzz(loops:gate:)` with `HapticPrefs` gates; `docs/PROTOCOL_ALARMS.md` | Nothing for 4.0. (5/MG rev-4 alarm is experimental & gated behind Protocol probes — irrelevant for a WHOOP 4.0 fork but keep the gates intact) | **Reuse as-is.** Fork work = presentation (surface alarm controls on Wrist screen / Today glance countdown), not protocol. All sends already go through `BLEManager.send` with CRC framing; BLE safety contract forbids new destructive commands | **Low** |
| 5 | **Gemini BYOK Coach cleanup + Keychain storage** | **The API key is ALREADY stored in the Keychain**: `AIKeyStore` (`Strand/AI/AICoach.swift:43–105`) — `kSecClassGenericPassword`, service `com.noop.aicoach`, account `api-key`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`; only a non-secret owner marker (`ai.keyProvider`) sits in UserDefaults. `AICoachEngine` (provider/model/consent/custom-URL/system-prompt prefs, `ai.*` keys), providers `Strand/AI/Providers/{OpenAI,Anthropic,Gemini,Custom}.swift` (Gemini: `x-goog-api-key`, `:generateContent`, `:streamGenerateContent?alt=sse`, multimodal `inline_data`, stable `-latest` model aliases), context builder `buildContext()` (AICoach.swift:1196: 14-day lines + 30-day averages + workouts), scheduled brief `generateBrief()` + `CoachBriefScheduler`, consent gating, `aiCoachPrivacyNote` | **Assumption in the fork plan is wrong: no UserDefaults-stored key exists to migrate.** What remains is *cleanup/UX*: e.g. defaulting provider to Gemini, simplifying onboarding, trimming provider surface if desired | **Reuse.** Optional fork touches: default `AIProvider` to `.gemini`, add Wrist/Today coach launcher hooks (existing `NavRouter.openCoach()` + `DashboardCard.coach` + `CoachLauncherSheet` already give entry points). Keychain-on-sideload caveat: items are bound to the signing identity's `(TeamID, bundleID)`; AltStore/SideStore re-signs keep working across 7-day refreshes with the same Apple ID, but a *switch of Apple ID* or full reinstall can orphan the item — the UI already handles re-entry gracefully (`AIKeyStore.read()` → nil → setup card) | **Low** |
| 6 | **App Intents / Shortcuts** | `StrandiOS/System/NOOPAppIntents.swift`: `SyncStrapIntent` (LiveActivityIntent, background sync + Dynamic Island), `MarkMomentIntent`, `BuzzStrapIntent`, `AskCoachIntent`, `NOOPShortcuts` AppShortcutsProvider; deferred-execution queue `PendingIntents` (App Group defaults, drained by `model.drainPendingIntents(router:)` on `.active`); `StrandiOS/System/HomeScreenQuickActions.swift` (4 dynamic quick actions via scene delegate); `StrandiOS/App/SiriShortcutsSettingsView.swift` + `ShortcutExportSettingsView.swift` (`noop://import-health` URL scheme, Documents `noop_sync.txt` drop file for HealthKit-free shortcuts) | Personal intents (e.g. "arm alarm", "open Wrist", "coach brief now") | **Reuse + small additive intents.** Pattern is established: append to `PendingIntents.Action`, add an `AppIntent`, drain in `RootTabView`/`AppModel`. Note macOS uses a *different* `Strand/System/NOOPAppIntents.swift` (excluded from iOS in project.yml to avoid a stringsdata collision — keep that exclude) | **Low** |
| 7 | **Developer Lab isolation of probes** | Probes are **already gated**: pure decoders in `Packages/WhoopProtocol/` (`BodyLocationProbe`, `ExtendedBatteryProbe`, `FeatureFlagProbe`, `DeviceConfigReadProbe`, `DeviceConfigWriteGate`, `HelloIdentityProbe`, `Whoop5EcgProbe`, `R22Disable`); results surface as `LiveState.*Probe` strings + strap-log lines; UI entries in `DevicesView` behind `probeGate = active && connected && isWhoop && TestCentre.active(.connection)` (`Strand/Screens/DevicesView.swift:165–174`); `TestCentreView` (1277 ln) hosts domain test modes, `RawDataCollectorView` (L237), recalibrate, env dump, scheduled export, `PuffinExperiment` toggles; gate model `Strand/System/TestCentre.swift` (UserDefaults `testcentre.active.<domain>`, master switch) + `TestDomain` (`Packages/StrandAnalytics/.../TestDomain.swift`, 15 domains) | A single "Developer Lab" *section* in the fork (renaming/re-homing is cosmetic). No probe result is shown automatically in normal flow today — everything is opt-in gated | **Reuse as-is.** The isolation architecture already exists (gate → probe → strap log). For the fork: keep `TestCentre.active(.connection)` gating; optionally collapse Test Centre behind one "Developer Lab" entry. Do not remove the always-on rare-event evidence lines (AGENTS.md explicitly wants them left on) | **Low** |
| 8 | **CI unsigned IPA + SideStore readiness** | **Fully built already.** `.github/workflows/fork-testing-build.yml` (on-demand rolling `testing-latest` prerelease: android debug+release, macOS universal zip, iOS unsigned IPA) and `fork-release.yml` (version bump in source → non-prerelease `v<version>` release with version-stamped artifacts + AltStore manifest update); iOS leg: `xcodebuild -scheme NOOPiOS -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO`, strip `Watch/`, keep `NOOPWidgets.appex`, then `Tools/prepare-ios-sideload-app.sh` embeds a **replaceable ad-hoc capability template** (HealthKit + App Group) so AltStore/SideStore can provision + re-sign; `altstore-source.json` (repo root, 71KB) is a full AltStore source manifest (auto-prepended per release by the `altstore` job); `WidgetSnapshot.resolveSuiteName` even reads **`ALTAppGroups`** injected by the sideloader so the App Group resolves post-re-sign; `docs/IOS.md` documents the whole sideload + build-from-source + BundleIdSecrets flow | Nothing structural. For a *personal* fork: fork the repo, Actions are workflow_dispatch — first run of `fork-testing-build.yml` produces an installable IPA. Optionally adjust release notes/`altstore-source.json` identity fields for the private fork | **Reuse entirely.** See §6 for details | **Low** |
| 9 | **Data preservation guarantees** | Single-file SQLite at `<AppSupport>/OpenWhoop/whoop.sqlite` (+`-wal`/`-shm`) via `StorePaths.defaultDatabasePath()`; WAL checkpoint before backup (`WhoopStore.checkpointWAL`); `.noopbak` full-DB ZIP backup/restore (`Strand/Data/DataBackup.swift`, `FolderBackup.catchUpIfDue` on launch) with a **byte-identical cross-platform settings whitelist** (`Packages/WhoopStore/.../BackupSettings.swift`); GRDB versioned migrations v1–v46 (`Packages/WhoopStore/Sources/WhoopStore/Database.swift`) applied under a serialized open gate (`StoreOpenGate`); foreign-DB quarantine; migration tests + shared `schema_oracle.json` parity fixture | Nothing for read-only reuse. Fork guarantee = never mutate an existing migration, only append `vN` (+ MigrationTests case), keep `.noopbak` whitelist in sync if new prefs are added | **Reuse; discipline required.** See §5 | **Low–Med** (risk only if migrations/prefs drift) |

---

## 3. Navigation & tabs — current structure and integration points

### 3.1 iOS shell today (`StrandiOS/App/RootTabView.swift`)

`StrandiOSApp` (@main) → `iOSRootView` (reproduces the macOS first-run gates: onboarding `noop.onboarded`, Terms gate `noop.acceptedTermsVersion`, What's-New sheet) → **`RootTabView`**, a `TabView` with **literal tags 0–4**:

| Tag | Tab | Root view | Icon |
|---|---|---|---|
| 0 | Today | `LiquidTodayView()` when `noop.liquidTodayEnabled` (default **true**), else `TodayView()` | `square.grid.2x2` |
| 1 | Trends | `TrendsView()` | `chart.line.uptrend.xyaxis` |
| 2 | Sleep | `SleepView()` | `bed.double` |
| 3 | Coach — **conditional** on `noop.coachEnabled` (default true) | `CoachView()` | `sparkles` |
| 4 | More (always last; tags stay literal when Coach is off) | `moreTab` | `ellipsis` |

Mechanics that matter for extension:
- `tabPaths: [NavigationPath]` ×5 and `scrollTop: [Int]` ×5 are **indexed by tab tag**; `reselectTab` pops-to-root or scrolls to top. A **6th tab requires growing both arrays** (`RootTabView.swift:54,59`) and re-checking `tabSwipeGesture`'s `min(4, …)` clamp (L117).
- Each tab is its own `NavigationStack`; root links push `TabRoute` values (`Strand/App/TabRoute.swift`: fullDayChart, metric, metricSourced, metricExplorer, workouts, dataSources, stress, sleep, health, hydration, coupled) registered once via `.tabRouteDestinations()` (double registration double-pushes, #38).
- The **More tab** is a `ScreenScaffold` list with four collapsible groups (Insights / Body / Data / App; expansion persisted via `MoreSectionPrefs`, `Strand/App/MoreSectionPrefs.swift`, key `more.expandedSections`). Rows push `MoreDestination` values — a **private enum in RootTabView.swift (L599–637) with 28 cases** (insightsHub, intelligence, coach, insights, explore, compare, live, workouts, liftLog, health, labBook, stress, breathe, intervals, rhythm, fusedRecord, appleHealth, miBand, dataSources, backupSync, shortcutsExport, noopLimitations, alarms, automations, **testCentre**, siriShortcuts, powerSaving, settings).
- Cross-shell routing: `NavRouter` (`Strand/App/NavRouter.swift`, `@EnvironmentObject`) with destinations devices, insightsHub, labBook, fusedRecord, rhythm, trends, activeWorkout, liveSession, journal, coach, alarms. `RootTabView` maps: devices → dedicated sheet; pillars (incl. `.alarms` → `SmartAlarmView`) → `routedPillar` sheet; `.coach` → switch to tab 3 (guarded on the master switch); `.trends` → tab 1; `.journal`/`.activeWorkout` → quick-action sheets.
- Sheets at shell level: quick-action FAB sheet (Live HR / Start workout / Log journal / Breathe), Devices sheet, pillar sheets, Lift-session bar + sheet.

### 3.2 macOS shell (for parity when editing shared files)

`Strand/App/ContentView.swift` → `RootView` (`Strand/App/RootView.swift`): `NavigationSplitView` sidebar driven by the `NavItem` enum (~28 cases, 5 collapsible sections, searchable). `RootView.swift`, `ContentView.swift`, `StrandApp.swift`, `MenuBar/`, `NotificationSettingsView.swift` + `NotificationSettingsStore.swift`, and the macOS `System/NOOPAppIntents.swift` are **excluded from the iOS target** in `project.yml` — that exclude list is the contract that keeps both shells compiling.

### 3.3 Recommended additive integration for personal V1 screens

- **Wrist screen**: add a `case wrist` to `MoreDestination` + one `MoreRow("Wrist", "watch.smart", .wrist)` in the "App" (or "Body") group → **smallest possible diff, zero tab-structure risk**, cross-platform-safe (pure iOS nav change; macOS parity optional via a `NavItem` case per docs/CONTRIBUTING.md "Add a new screen"). If it must be a top-level tab: add the tab entry with tag 5, grow `tabPaths`/`scrollTop` to 6, fix the swipe clamp, and add a `selectedTab` fallback mirroring the Coach-off pattern (L144–149).
- **Connection Guardian**: no navigation change — banner in the shell or a `TodaySection`/card. Prefer a **new `DashboardCard` case** (e.g. `.connection`) if it should be glanceable; it will not appear for existing users unless added (unknown/absent ids are simply not shown).
- **Deep links** (intents, guardian alerts): new `NavRouter.Destination` case + handler in `RootTabView.onChange(of: router.requestedDestination)`; keep the macOS `RootView` handler in step.
- Any new screen **must** follow docs/CONTRIBUTING.md §"Add a new screen": `StrandDesign` components only, `ScreenScaffold` chrome, state via `AppModel`/`Repository` environment objects, optional features default OFF.

---

## 4. Conventions distilled from `AGENTS.md` (+ `docs/CONTRIBUTING.md`)

1. **XcodeGen is law.** Edit `project.yml`, never `Strand.xcodeproj/`; re-run `xcodegen generate` after any file add/remove (the fork's CI does this).
2. **Layering by purity:** the more wire/math-level a change, the deeper into `Packages/` it goes, and the more it must be covered by `swift test` that runs with no app/strap. Never `import AppKit/UIKit/CoreBluetooth` under `Packages/`; guard with `#if canImport(...)`.
3. **Cross-platform parity contract (#1 rule):** analytics + stored data must be byte-identical Swift↔Kotlin; `.noopbak` settings whitelist, `schema_oracle.json`, `decoder_oracle.json` are pinned by tests on both sides; platform-neutral hashes only (FNV-1a, never `hashValue`). *For a personal iOS-only fork this relaxes to: don't change stored values/schema casually, or do it fork-only and accept oracle-test drift; the safest personal additions are display-only.*
4. **BLE safety contract:** no destructive commands (firmware/DFU/ship-mode/power-cycle/force-trim/fuel-gauge). Writes must be reversible, confirmation-gated, never automatic; new non-trivial commands are issue-first; CRC-gate inbound frames; no hardcoded hex frames in app code — protocol facts live in decoders (`Strand/BLE/Commands.swift`, WhoopProtocol).
5. **`didBond` is load-bearing:** three independent watchdogs treat "connected but never bonded" as a fault — don't make a strap deliberately not bond without checking every reader.
6. **Diagnostics may only assert what they can attribute**; **two readouts of one fact must not disagree** (resolve both from ONE gated funnel + ONE clock — the Alarms screen is the worked example); gates must be able to fail on the change that caused them.
7. **Design system is law:** only `StrandPalette`/`StrandFont`/`NoopMetrics` + shared components (`NoopCard`, `StatTile`, `ChartCard`, `ScreenScaffold`…). No hardcoded colors/fonts/spacing.
8. **Migrations:** add versioned `vN` GRDB migration + `MigrationTests` case; never mutate an existing migration; GRDB ids strictly sequential `v<N>[-slug]`; watch for data-loss traps (window-wide deletes, backfill rewrites); prefer additive/transactional.
9. **Device model resolution:** always through `DeviceFamily.forRegistryModel` (one canonical resolver), thread the registry's active strap id, never raw BLE addresses, never scattered string compares.
10. **Testing reality:** `swift-packages.yml` (macos-15) runs `swift test` per package — it does **not** compile app targets; `app-build.yml` compiles Strand + NOOPiOS and runs StrandTests on the macOS leg, triggered on PRs to main (path-filtered) + manual dispatch — **no push trigger on main**; BLE behavior can only be validated on a real strap. App-target Swift changes MUST be compile-verified via `xcodebuild` locally or an on-demand `app-build.yml` dispatch. (AGENTS.md's "trap" paragraph calls app-build "disabled" — at this HEAD the workflow is **active on PRs**; the real gap is: pushes directly to a branch/main of a personal fork run nothing unless dispatched. Plan the fork's loop accordingly: dispatch `app-build.yml` per push, or open PRs against the fork's own main.)
11. **PR/commit style:** one concern per PR; English for all repo-facing text; `Refs #N` (no auto-close keywords); show your verification (hardware for BLE, method+test for analytics, compiled-app claim for app-target Swift); keep generated artifacts out of git; **versioning:** bump `MARKETING_VERSION` in project.yml AND `versionName` in `android/app/build.gradle.kts` together (build numbers independent); neutral third-person voice.
12. **iOS specifics:** iOS target is `NOOPiOS`; `RootTabView` is the shell; a file shared with macOS must keep compiling for **both** (check the `Strand` macOS build when editing shared files). Deployment: macOS 13.0 / iOS 17.0 / watchOS 10.0. `doc_comment_lint` failures point at wrong lines on purpose (per-file count baseline) — look at what you inserted. i18n: new user-facing strings localize via the String Catalog (`SWIFT_EMIT_LOC_STRINGS`); diff-scoped `i18n-coverage.yml` gates PRs.
13. **Scope limits (hard):** no server/account/cloud/telemetry; the one networked feature is the opt-in BYOK Coach; #1314's default-off one-way self-hosted export is the only data-egress exception; PolyForm Noncommercial licensing with attribution preserved.

---

## 5. Data preservation analysis

- **DB location:** `<AppSupport>/OpenWhoop/whoop.sqlite` + WAL/SHM sidecars (`Strand/Collect/StorePaths.swift:3–51`). On iOS this is **inside the app container** (not the App Group) → an app *deletion* deletes it; a SideStore **refresh/re-sign keeps it** (same bundle ID). File protection is set to `completeUntilFirstUserAuthentication` on iOS so background BLE writes work while locked (#222).
- **Migrations:** GRDB `DatabaseMigrator` v1…v46 in `Packages/WhoopStore/Sources/WhoopStore/Database.swift`; applied under `StoreOpenGate` (serialized open+migrate, #261); `WhoopStoreInfo.schemaVersion = 18` is the backup-manifest marker (independent of the migration count). Incompatible foreign DBs are quarantined, not destroyed (`quarantineIncompatibleDatabase`). Migration tests: `Packages/WhoopStore/Tests/WhoopStoreTests/MigrationTests.swift` + shared `schema_oracle.json` fixture (Swift + Kotlin byte-identical).
- **Backup/restore:** `.noopbak` single-file ZIP of the checkpointed DB (`Strand/Data/DataBackup.swift`); auto FolderBackup catch-up on launch (`RootTabView.task` → `FolderBackup.catchUpIfDue`, default OFF); settings whitelist `Packages/WhoopStore/Sources/WhoopStore/BackupSettings.swift` (canonical keys, Int/Double/String only — new fork prefs should either stay out of `.noopbak` or be added to the whitelist *knowing* the Android twin contract).
- **Preservation rules for the fork:** (1) never edit an existing migration; (2) new prefs use new keys (old builds ignore unknown keys; `DashboardCardPrefs`/`TodayLayoutPrefs` decoders drop unknown ids and re-insert missing sections — the patterns are deliberately forward/backward-compatible); (3) don't rename `TodaySection`/`DashboardCard`/`HostedCard` rawValues (they ride `.noopbak` and mirror Android); (4) before any risky schema work, take a `.noopbak` (the UI's Backup & Sync screen, `Strand/Screens/BackupSyncView.swift`).
- **Residual risks:** a 7-day-cert sideload that lapses doesn't touch the container, but an iOS *reinstall after delete* loses the DB + Keychain (AI key) + App Group snapshot — the `.noopbak` in Files/Documents (UIFileSharingEnabled) is the escape hatch; document that in the fork's onboarding.

---

## 6. CI / release analysis — the fork build system already exists

### 6.1 Workflows (all read in full)

- **`.github/workflows/app-build.yml`** ("App build (macOS + iOS)") — compile gate. Matrix: `Strand` on macos-15 (universal, `ARCHS="x86_64 arm64"`) and `NOOPiOS` on **macos-26** (iOS 26 SDK needed for Liquid-Glass `glassEffect`). `CODE_SIGNING_ALLOWED=NO`, Debug config, no artifacts. The macOS leg also **runs `StrandTests`**. Triggers: `pull_request` to main with paths (Strand/**, StrandTests/**, StrandiOS/**, StrandiOSShared/**, StrandiOSWidgets/**, NOOPWatch*/**, Packages/**, project.yml) + `workflow_dispatch` with a PR-number input that checks out the PR head and merges current main (avoids the stale `refs/pull/n/merge` false-green). **No push trigger** (cost control) — direct pushes to a personal fork's main need a manual dispatch.
- **`.github/workflows/swift-packages.yml`** — per-package `swift build` + `swift test` on macos-15 (WhoopProtocol, OuraProtocol, PolarProtocol, WhoopStore, StrandAnalytics, StrandImport, StrandDesign, NoopLocalAccess) + Tools (SleepBench tests, SleepPSG tests, Backfill build-only). PR + push-to-main + dispatch, path-filtered. **This is the only check that can run green while app-target Swift is broken.**
- **`.github/workflows/fork-testing-build.yml`** ("Testing build (fork)") — on-demand, `workflow_dispatch`. `meta` job re-creates the rolling **`testing-latest` prerelease** (with defensive delete/recreate + draft assertions), then `android` (debug + staging-release APKs, committed fork-debug keystore), `macos` (unsigned universal **Release** .app, ad-hoc `codesign --sign -` for macOS-26 TCC, zipped), and **`ios`**: Release build for `generic/platform=iOS` with `CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""`, then **strip `$APP/Watch`** (embedded watch app doesn't survive free-cert sideloading), **assert `PlugIns/NOOPWidgets.appex` present** (widgets + Live Activity renderer must survive), run **`Tools/prepare-ios-sideload-app.sh`**, package `Payload/` → `NOOP-ios-unsigned-v${VER}.ipa`, upload with `--clobber`. A `cleanup` job deletes the disposable `noop-staging` branch.
- **`.github/workflows/fork-release.yml`** ("Release build (fork)") — on-demand versioned release. `bump` job: increments `versionName`/`versionCode` (android/app/build.gradle.kts) and `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` (project.yml) **in source and commits**, generates the in-app What's New from `docs/releases/<TAG>.md` front-matter via `Tools/appchangelog-gen.py`, creates a **non-prerelease** `v<VERSION>` GitHub release (so the in-app "Check for updates" — which reads `releases/latest` — finds it); then `android`/`macos`/`ios` jobs attach version-stamped artifacts (identical build recipe to the testing build); finally the **`altstore` job** prepends the new version to `altstore-source.json` **on main** (both the `versions[]` array and the legacy app-level fields, deduped, with the real IPA byte size and download URL).
- Also present: `android.yml`, `source-hygiene.yml` (doc-comment lint), `i18n-coverage.yml`, `tools-python.yml` (+ windows), `parity-governance.yml`, `prune-stale-branches.yml`.

### 6.2 `Tools/prepare-ios-sideload-app.sh`

Reads `AppGroupIdentifier` from the app's and widget's Info.plist (asserts they match), builds ad-hoc entitlements plist (app: HealthKit + healthkit.access + application-groups; widget: application-groups), re-signs inside-out with `codesign --sign -`, then **verifies the signed entitlements survived**. Purpose: preserve the capability *request* inside each Mach-O so AltStore/SideStore's AltSign provisions the matching App IDs + shared App Group before re-signing.

### 6.3 `altstore-source.json`

A complete AltStore/SideStore source manifest at the repo root: `name: NOOP`, `identifier: com.noopapp.noop.altstore`, `sourceURL: https://raw.githubusercontent.com/ryanbr/noop/main/altstore-source.json`, one app (`bundleIdentifier: com.noopapp.noop`) with icon/tint/category/localizedDescription and a long `versions[]` history (71KB; current head entry: version 11.8.0, buildVersion 400 → superseded by newer releases as they're cut). **Adding this source URL to AltStore/SideStore gives one-tap install + auto-updates of the sideloaded IPA.**

### 6.4 What a personal fork actually needs (answer: almost nothing)

1. Fork the repo → Actions tab → run **Testing build (fork)** → download `NOOP-ios-unsigned-v11.8.0.ipa` from the `testing-latest` release → sideload with SideStore (recommended; docs/IOS.md documents an open AltServer/OS-26.2 sign-in bug and recommends SideStore).
2. For a personal *App-Group-isolated* build (optional): `cp Config/BundleIdSecrets.example.xcconfig Config/BundleIdSecrets.xcconfig`, set `BUNDLE_ID_PREFIX` + `DEVELOPMENT_TEAM` — every target, the App Group, and the watch pairing follow automatically.
3. CI-trigger note: with no `push` trigger on `app-build.yml`, a solo fork pushing to its own `main` should either open self-PRs (cheap, runs the full path-filtered matrix) or dispatch the workflow per push — this is the one workflow-level change worth making in the fork (add a `push: branches: [main, feature/**]` trigger to a fork-local copy of `app-build.yml`).
4. Free-Apple-ID realities (documented upstream): 7-day re-sign (SideStore refreshes automatically); 3-app limit; embedded **watch app is stripped from the IPA** (watch users are steered to a source build); widgets + Live Activities survive and share the provisioned App Group.

---

## 7. AI / Keychain — exact current mechanism

- **Storage today:** `AIKeyStore` in `Strand/AI/AICoach.swift` (L43–105). `SecItemAdd`/`SecItemCopyMatching`/`SecItemDelete` on a `kSecClassGenericPassword` item, `service = "com.noop.aicoach"`, `account = "api-key"`, `kSecAttrAccessible = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. `save(_:owner:)` delete-then-add (single fresh item), records the owning provider in UserDefaults `ai.keyProvider` (so one provider's key is never sent to another endpoint); `read()` gates the whole feature; `clear()` on disconnect. A write failure surfaces `AICoachError.keySaveFailed` and leaves the owner marker untouched (#872).
- **Non-secret prefs (UserDefaults):** `ai.provider`, `ai.model`, `ai.dataConsent` (consent gate for any network send), `ai.customBaseURL` + `ai.customAuthHeader` (Custom provider; `guardCustomBaseURL` allows cleartext http only to loopback/RFC-1918/`.local` — #321), `ai.systemPrompt` (editable prompt override), `ai.multimodalChartEnabled` (K11 chart screenshots to Gemini), `ai.customConnected`, `ai.includeOnDeviceSignals`. Master switch `noop.coachEnabled` (hides the tab, launcher card, and cancels the background brief).
- **Gemini specifics:** `Strand/AI/Providers/Gemini.swift` — endpoint base `https://generativelanguage.googleapis.com/v1beta/models`, key via `x-goog-api-key` header, `system_instruction` + `contents` (+ `inline_data` image parts), `generationConfig {temperature 0.6, maxOutputTokens 4096}` (thinking-model headroom), SSE streaming via `:streamGenerateContent?alt=sse`, model list via GET `/models` filtered to chat-capable `gemini-*`; default model `gemini-flash-latest` (stable alias, #400).
- **Migration plan to Keychain: none needed.** The master prompt's assumption that the key sits in UserDefaults is **false at this HEAD**. Fork tasks reduce to: (optional) verify `AIKeyStore.read()` survives the SideStore re-sign on device (it should — same TeamID+bundleID across refreshes), keep the key-rejection repair flow (`keyRejected` + `AICoachError.isKeyRejection`), and consider a fork default of `AIProvider.gemini`. If a *legacy* key is ever found in UserDefaults (pre-history installs), note that no legacy migration code exists — none is needed for a fresh fork install.

---

## 8. Developer Lab — current probe surface and isolation plan

**Where probes appear today (all opt-in):**
- `Strand/Screens/DevicesView.swift` device cards expose: extended-battery probe (#592), body-location probe (#690), feature-flag enumeration probe (#761), device-config read probe (#103), 4.0 reboot probe (#275 analysis: no safe 4.0 reboot frame), MG ECG probe (write — extra gates) — each behind `probeGate` (= active + connected + isWhoop + `TestCentre.active(.connection)`, L165–174); ECG additionally requires the Experimental ECG opt-in + a positively identified MG. Results render from `LiveState.*Probe` strings via dedicated sheets (`BodyLocationProbeSheets`, `FeatureFlagProbeSheets`, `DeviceConfigProbeSheets`…).
- `Strand/Screens/TestCentreView.swift` (reachable from **More → App → Test Centre** on iOS, the macOS sidebar, and Settings → Test Centre) — Section 1 domain test modes (guided sleep/battery capture targets, answers), Section 2 diagnostics (strap log + `RawDataCollectorView` + recalibrate + env dump), Section 2b Oura, Section 3 manual + scheduled export (`ScheduledDebugExport`, BGTask `debugexport`), Section 4 experimental algorithms (`PuffinExperiment`).
- Gate model: `Strand/System/TestCentre.swift` — UserDefaults `testcentre.active.<domain>` + `testcentre.startedAt.<domain>` + `master`; zero-cost `nonisolated static func active(_:)` gate; `anyActive` drives a "testing on" banner. Domains: `Packages/StrandAnalytics/Sources/StrandAnalytics/TestDomain.swift` (universal, sleep, connection, workouts, display, import, steps, notifications, battery, recovery, hrv, sources, stress, longevity, master).
- **No probe result is shown automatically in normal flow**: emitters check `TestCentre.active(...)` before writing tagged strap-log lines (see `FrameRouter`, `ImportTrace`, GpsWorkoutRecorder gating in `StrandTests/WorkoutsTestModeEmissionTests.swift`), with rare-event evidence intentionally always-on per AGENTS.md.

**Fork isolation plan:** the desired "Developer Lab" *is* Test Centre + the DevicesView probe rows, already isolated behind an explicit gate. Recommended fork posture: (1) keep gates exactly as-is; (2) optionally re-skin/collapse entry points into one "Developer Lab" More row; (3) never surface `LiveState.*Probe` values outside the gated sheets; (4) keep the strap log (`LiveState.log`, `StrapLogArchive` under `<AppSupport>/OpenWhoop/strap-log/`) as the single funnel for probe output so "two readouts of one fact cannot disagree".

---

## 9. Risk map (top 10)

| # | Risk | Why it bites | Mitigation |
|---|---|---|---|
| 1 | **No local build possible** (this sandbox; also true of any non-macOS contributor) | App-target Swift compiles nowhere before CI; `swift-packages` CI is green while app targets are broken (AGENTS.md "trap") | Every push to the fork gets an `app-build.yml` dispatch (or self-PR); add a `push:` trigger to the fork's copy; pure-logic work lands in `Packages/` where `swift test` covers it |
| 2 | **iOS leg needs macos-26 runner** (iOS 26 SDK, `glassEffect`) | A fork-local CI edit that pins macos-15 will fail the NOOPiOS build | Keep the runner matrix verbatim from `app-build.yml`/`fork-*-build.yml` |
| 3 | **Editing shared `Strand/` files breaks the macOS build** | `Strand/` compiles into both targets with different excludes | Guard platform code `#if os(iOS)`; keep new iOS-only screens in `StrandiOS/` or fully guarded; verify via the Strand leg of app-build |
| 4 | **BLE path fragility** (`didBond` watchdogs, #1635 history) | A "small" BLEManager change can be silently undone by bond watchdogs and mis-diagnose later | Additive-only: new observer layers (Connection Guardian) read `LiveState`, never touch `BLEManager`; hardware validation before trusting any change |
| 5 | **Sideload identity churn** | Deleting/reinstalling, switching Apple IDs, or changing `BUNDLE_ID_PREFIX` orphans the Keychain key and/or the app container DB | Keep one bundle prefix + one Apple ID; rely on `.noopbak` + Documents export for recovery; the app already degrades gracefully to the key setup card |
| 6 | **UserDefaults/App-Group cross-process drift** | App Group defaults (`PendingIntents`, widget snapshot) silently no-op if the group isn't provisioned (debug canary exists: `WidgetSnapshot.assertGroupProvisioned`) | Keep `ALTAppGroups` resolution (`WidgetSnapshot.resolveSuiteName`) intact; test widgets after first SideStore install |
| 7 | **Tab-structure regressions** (adding a 6th tab) | Tag-indexed `tabPaths`/`scrollTop`, literal tags, swipe clamp `min(4,…)`, Coach-off fallback — several interacting invariants documented inline | Prefer MoreDestination/NavRouter additions; if a tab is required, grow arrays + clamp + fallback together in one commit, mirroring the Coach conditional pattern |
| 8 | **Cross-platform parity gates** (schema oracle, `.noopbak` whitelist, decoder oracle) | Fork-only schema/prefs changes fail `parity-governance`/oracle tests or silently diverge from Android | Personal fork: display-only changes only, or accept + document deliberate divergence; never mutate existing GRDB migrations |
| 9 | **i18n + doc-comment lint baselines** | New user-facing strings without catalog entries, or a detached doc comment, trip `i18n-coverage.yml` / `source-hygiene.yml` pointing at the wrong lines | Add strings as plain `Text("…")` literals (auto-extracted on build); insert new declarations above the neighbour's doc block (AGENTS.md tip) |
| 10 | **Upstream drift** (repo is very active — testing build 541, v11.8.0) | A long-lived fork accumulates merge pain, especially in `RootTabView`, `BLEManager`, `project.yml` | Keep fork changes small, additive, and localized to new files; rebase onto upstream main regularly; record fork-only decisions in this file |

---

## 10. Assumptions from the plan that the audit corrected

1. *"Migrate the Gemini API key from UserDefaults to Keychain"* — **already Keychain** (`AIKeyStore`, `Strand/AI/AICoach.swift`). No migration exists or is needed.
2. *"Set up CI for personal unsigned IPA + SideStore"* — **already exists end-to-end** (`fork-testing-build.yml`, `fork-release.yml`, `Tools/prepare-ios-sideload-app.sh`, `altstore-source.json`, `docs/IOS.md`). Only the missing `push:` trigger on `app-build.yml` is worth adding fork-side.
3. *"Isolate probes into a Developer Lab"* — probes are **already gated** behind `TestCentre.active(.connection)` + connection state in `DevicesView`, with results confined to gated sheets and the strap log. Isolation is a presentation preference, not missing safety.
4. *"WHOOP haptics/alarms need proving"* — the **4.0 wake alarm is hardware-confirmed** (#535, official-app wire capture + on-device buzz) with arm/disarm/readback + reject-streak handling; maverick buzz loop semantics hardware-confirmed (#926). Only 5/MG rev-4 alarms remain experimental (and are irrelevant to a 4.0 fork).
5. `app-build.yml` is *not* disabled at this HEAD (it is PR-triggered + dispatch) — AGENTS.md's "disabled" wording refers to the no-push-trigger gap; plan the fork's verification loop around manual dispatch or self-PRs.

---

## 11. Quick reference — key files for the V1 build tasks

| Concern | File(s) |
|---|---|
| App entry / DI | `StrandiOS/App/StrandiOSApp.swift` |
| Tab shell / More list / quick actions | `StrandiOS/App/RootTabView.swift` |
| Cross-shell routing | `Strand/App/NavRouter.swift`, `Strand/App/TabRoute.swift` |
| App-wide state | `Strand/App/AppModel.swift` (alarm logic L1660–1760; wrist-buzz mirrors L1479+) |
| Today (default / classic) | `Strand/Liquid/LiquidTodayView.swift`, `Strand/Screens/TodayView.swift` |
| Section/card registries | `Strand/Data/TodayLayoutPrefs.swift`, `Strand/Screens/DashboardCards.swift`, `Strand/Screens/HostedCards.swift`, `Strand/Screens/TodayCustomizationSheet.swift` |
| Live connection state | `Strand/BLE/LiveState.swift`, `Strand/BLE/BLEManager.swift` (alarm cmds L5279+), `Strand/BLE/LiveHRSource.swift`, `Strand/BLE/SourceCoordinator.swift` |
| Alarms / haptics UI | `Strand/Screens/SmartAlarmView.swift`; payloads `Packages/WhoopProtocol/Sources/WhoopProtocol/HapticPayloads.swift`, `HapticClock.swift`, `LiveSessionHaptics.swift`; docs `docs/PROTOCOL_ALARMS.md` |
| Coach | `Strand/AI/AICoach.swift` (Keychain L43–105, context L1196), `Strand/AI/AIProvider.swift`, `Strand/AI/Providers/Gemini.swift`, `Strand/Screens/CoachView.swift`, `CoachSettingsView.swift`, `CoachLauncherSheet.swift` |
| Probes / dev tools | `Strand/Screens/TestCentreView.swift`, `Strand/System/TestCentre.swift`, `Strand/Screens/RawDataCollectorView.swift`, probe rows in `Strand/Screens/DevicesView.swift` |
| Storage | `Packages/WhoopStore/Sources/WhoopStore/{WhoopStore,Database,Reads,BackupSettings}.swift`, `Strand/Collect/StorePaths.swift`, `Strand/Data/DataBackup.swift`, `Strand/Data/Repository.swift` |
| Intents / shortcuts | `StrandiOS/System/NOOPAppIntents.swift`, `StrandiOS/System/HomeScreenQuickActions.swift`, `StrandiOS/App/SiriShortcutsSettingsView.swift`, `ShortcutExportSettingsView.swift` |
| Widgets / Live Activities | `StrandiOSShared/WidgetSnapshot.swift`, `StrandiOS/Widgets/WidgetPublish.swift`, `StrandiOSWidgets/*` |
| HealthKit | `StrandiOS/Health/HealthKitBridge.swift`, `HealthWritebackBackgroundScheduler.swift` |
| Devices UX | `Strand/Screens/DevicesView.swift`, `Strand/Screens/AddDeviceWizard.swift` |
| Watch | `Strand/Data/WatchSessionBridge.swift`, `NOOPWatch/*`, `NOOPWatchComplications/*`, `Packages/StrandDesign/Sources/StrandDesign/WatchScoreSnapshot.swift` |
| Build / CI / release | `project.yml`, `Config/BundleId.xcconfig`, `.github/workflows/{app-build,swift-packages,fork-testing-build,fork-release}.yml`, `Tools/prepare-ios-sideload-app.sh`, `altstore-source.json`, `docs/IOS.md`, `docs/BUILD.md` |
| Conventions | `AGENTS.md`, `docs/CONTRIBUTING.md` (§"Add a new screen/metric/command/column"), `docs/CROSS_PLATFORM.md`, `docs/SCOPE.md` |

---

## 12. V1 Implementation Log (Task 3, 2026-10-22)

Everything in this section is ADDITIVE on top of the audited tree (upstream `main` @ `0e56473`);
the audit above is unchanged. Branch: `feature/personal-v1`. No existing migration, BLE command,
bundle id, version or release pipeline was touched. The only existing files modified are listed
under "Modified upstream files" below, each with the minimal additive hunk.

### Feature → files → integration point

| Feature | Files added | Integration point (existing) |
|---|---|---|
| **A. Personal Today** | `StrandiOS/Personal/PersonalTodayView.swift` | `RootTabView.todayTabRoot` — new `@AppStorage("noop.personalTodayEnabled")` (default ON in this fork) swaps `PersonalTodayView()` ahead of the `noop.liquidTodayEnabled` liquid/classic pair, mirroring that swap idiom exactly. Data: `Repository.today` / `Repository.lastVitalsDay(days:)` / `LiveState` (leaf subviews so the 1 Hz tick stays local). Alarm countdown via the same pure `AppModel.nextSmartAlarmDate(minutes:weekdays:overrides:)` the arm path uses. Actions: `router.openCoach()` / `model.ble.syncNow()` (HealthView's gate) / `model.buzzStrapOnce()` / `router.openAlarms()`. The header layout menu writes both layout keys for one-tap fallback. |
| **B. Wrist screen** | `Strand/Screens/WristView.swift` (cross-platform; also defines the shared `GuardianStatusBanner`) | New `MoreDestination.wrist` case + `MoreRow("Wrist", "watch.smart", .wrist)` in the More "App" group; `navigationDestination(for: MoreDestination.self)` resolves it. Deep-link parity: new `NavRouter.Destination.wrist` + `openWrist()`, handled in `RootTabView.onChange(of: router.requestedDestination)` (switches to the More tab, resets its path, pushes the value) and mapped on macOS in `RootView` to the `.devices` sidebar row (Wrist is an iOS surface; Devices is the Mac equivalent). Status chain reads one LiveState fact per step; battery via `LiveConsoleReadout.batteryPercent` (cross-source resolver); quiet hours read the `notif.quietHours*` keys; sync card shows `lastSyncError` verbatim; NO protocol logs. |
| **C. Connection Guardian** | `Strand/BLE/ConnectionGuardian.swift` (pure, cross-platform) | `ConnectionGuardian.resolve(Snapshot, now:)` maps the existing observables (`connected`, `encryptedBond`, `heartRate`, `lastFrameAtUnix`, `lastSyncedAt`, `lastSyncError`, `backfilling`, `rebootInProgress`) to `GuardianState` (healthyStream / staleHr / staleSync / connecting / bondedIdle / disconnected / bluetoothUnavailable) with title/message/severity/actions. Bluetooth-off is detected through the `lastSyncError` "Bluetooth is off…" funnel `BLEManager.centralManagerDidUpdateState` already publishes (read-only, no CoreBluetooth reach-in). Rendered by `GuardianStatusBanner` on Personal Today + Wrist. **Zero BLEManager changes.** |
| **D. App-side alarm schedules** | `StrandiOS/Personal/PersonalAlarms.swift` (`PersonalAlarmSchedule`, `PersonalAlarmStore`, `PersonalAlarmsView`, editor) | New `MoreDestination.personalAlarms` + More row. Persistence: one JSON array under `personal.alarmSchedules` (BehaviorStore/UserDefaults idiom; deliberately NOT added to the `.noopbak` whitelist). Next occurrence: repeating schedules resolve through the SAME `AppModel.nextSmartAlarmDate` (pure, unit-tested upstream); one-offs via Calendar. **Strap arming is explicit-only:** "Arm as strap alarm" writes the SAME `BehaviorStore` fields `SmartAlarmView` edits, then calls the SAME `AppModel.applySmartAlarm()` (→ `armStrapAlarm`, the #535 hardware-confirmed path, + backup notification). One funnel, nothing to disagree. Reminders: foreground poller (30 s, AppModel's timer idiom) fires `WristHapticScheduler.fireReminder` (quiet-hours-gated, de-duped per occurrence) + per-schedule `UNCalendarNotificationTrigger` fallback. UI footer models app-side vs strap-side explicitly. |
| **E. Haptic patterns + reminder scheduler** | `StrandiOS/Personal/PersonalHapticPatterns.swift`, `StrandiOS/Personal/WristHapticScheduler.swift` | `PersonalHapticPattern` (reminder 1 / event 2 / batteryWarning 3 / wake 5 — exactly the shipped `BuzzPattern` loop values) fires ONLY through `AppModel.buzz(loops:)` (graduated pattern, hardware-confirmed loop semantics) and `AppModel.buzzStrapOnce()` (the #921 acked one-shot). `WristHapticScheduler`: `inQuietHours` pure helper reading the `notif.quietHours*` keys (NotificationSettingsStore's, evaluated like the SedentaryDetector engine); foreground `DispatchWorkItem` scheduling; `UNUserNotification` fallback with a status-only authorization check (never prompts); iOS suspension limits documented up front. Gate key `haptics.personalReminders` uses the `HapticPrefs.enabled(_:)` idiom (default ON) without editing that type. |
| **F. Coach structured context** | `Strand/AI/CoachContextBuilder.swift` (pure, cross-platform) | Appended inside `AICoachEngine.buildFullContext()` — the same consent-gated, summary-only text channel (buildContext's day lines + workouts are unchanged ahead of it). Block = TODAY (charge/effort, honest "not scored yet") · LAST NIGHT (duration, normalised efficiency, HRV, RHR, respiration, `sleepHrOnly` note) · 7-DAY TRENDS as deviations vs the prior 7 days. `CoachView` gains an additive `contextBadge` naming what is attached (measured metrics / structured block / trends / opt-in signals). `CoachPrompts.suggestions` gains 2 entries following the existing pattern (original 4 untouched). **No key migration: the API key already lives in `AIKeyStore` (Keychain), as audited in §7.** |
| **G. Developer Lab isolation** | — (edit in `RootTabView.swift`) | Verified first: every probe already hangs behind `TestCentre.active(.connection)` + connection state in `DevicesView` (probeGate), results render only in gated sheets, and no probe auto-popup exists anywhere. The V1 change is presentational: the Test Centre More row moves into a new `moreSection("Developer Lab")`, which starts COLLAPSED (its title is not in `MoreSectionPrefs.defaultExpanded`). Trivially additive — sections are title-generic strings. |
| **H. App intents** | — (edits in `NOOPAppIntents.swift` + `AppModel+iOS.swift`) | NEW `ShowWristStatusIntent` (openAppWhenRun) following the exact existing pattern: `PendingIntents.Action.showWrist` queued in the App-Group store, drained in `AppModel.drainPendingIntents` → `router.openWrist()`; registered in `NOOPShortcuts.appShortcuts`. **Buzz / Ask Coach / Sync already existed upstream** (`BuzzStrapIntent` / `AskCoachIntent` / `SyncStrapIntent` incl. the LiveActivity sync intent) and are reused, not duplicated. |
| **I. CI push trigger** | — (edit in `.github/workflows/app-build.yml`) | `push: branches: [main]` + the same path filter (duplicated verbatim; Actions has no anchors), with the cost rationale in a comment. This is the one fork-local CI change identified in §6.4. `fork-release.yml` / `fork-testing-build.yml` untouched. |
| **J. Docs** | `IMPLEMENTATION_STATUS.md`, `REAL_DEVICE_TEST_CHECKLIST.md`, `RELEASE_NOTES_PERSONAL.md`, this section | Repo root / appended here. |

### Modified upstream files (complete list, all additive hunks)

| File | Why |
|---|---|
| `StrandiOS/App/RootTabView.swift` | personal-Today swap (`noop.personalTodayEnabled`); `MoreDestination.wrist` / `.personalAlarms` cases + rows + destination mappings; `NavRouter` `.wrist` handling (onChange push + pillarScreen exhaustive fallback); Test Centre row moved into the new "Developer Lab" section |
| `Strand/App/NavRouter.swift` | `Destination.wrist` case + `openWrist()` (shared file — macOS keeps compiling via the RootView mapping below) |
| `Strand/App/RootView.swift` | one switch case: `.wrist` → `.devices` sidebar selection on macOS (exhaustive-switch fix + the honest Mac equivalent) |
| `Strand/AI/AICoach.swift` | `buildFullContext()` appends the `CoachContextBuilder` block (4 lines + comment) |
| `Strand/Screens/CoachView.swift` | additive `contextBadge` + `contextLine` under `connectedHeader` |
| `Strand/Screens/CoachPrompts.swift` | 2 new suggested prompts (existing 4 untouched) |
| `StrandiOS/System/NOOPAppIntents.swift` | `PendingIntents.Action.showWrist`; `ShowWristStatusIntent`; AppShortcut registration |
| `StrandiOS/App/AppModel+iOS.swift` | drain case `.showWrist` → `router?.openWrist()` |
| `.github/workflows/app-build.yml` | push trigger (see I) |

### Conventions held

- XcodeGen: all new files live under glob-included directories (`Strand/`, `StrandiOS/`); CI runs
  `xcodegen generate`, so no project edits are needed. `Strand.xcodeproj/` untouched.
- Purity: `ConnectionGuardian` and `CoachContextBuilder` are Foundation-only and pure;
  UI code uses `StrandDesign` tokens exclusively (StrandPalette / StrandFont / NoopMetrics /
  NoopCard / NoopButton / StatePill / SectionHeader / ScreenScaffold).
- Shared `Strand/` files stay macOS-compilable: `WristView`, `ConnectionGuardian`,
  `CoachContextBuilder` and the `NavRouter`/`RootView` edits are cross-platform; iOS-only code sits
  in `StrandiOS/Personal/` behind `#if os(iOS)`.
- BLE safety contract: no new commands, no BLEManager edits, no writes except the explicit
  "Arm as strap alarm" through the existing reversible funnel.
- No migrations, no `.noopbak` whitelist changes, no version bumps, no bundle-id changes, no
  secrets.

### Verification posture (no local build possible — Linux sandbox)

Every external symbol referenced by the new code was verified against the repo source before use
(full list in the shared worklog, Task 3 entry). Compile verification lands on CI: push
`feature/personal-v1` to the fork's `main` (or PR against it) and `app-build.yml` builds `Strand`
(macOS, runs StrandTests) + `NOOPiOS` (macos-26, compile-only). Real-device validation follows
`REAL_DEVICE_TEST_CHECKLIST.md`.
