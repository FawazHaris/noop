# Release Notes — NOOP Personal Fork v1.0.0

**Personal fork of [ryanbr/noop](https://github.com/ryanbr/noop)** (upstream `main` @ `0e56473`,
app 11.8.0 / build 422). Private, single-wearer build. Not distributed; PolyForm Noncommercial
licensing and upstream attribution preserved.

---

## Highlights

- **Personal Today glance** — the fork's new default Today: a big live heart rate with honest
  "as of" staleness, the active device's battery, TODAY (recovery / strain / HRV / resting HR with
  an honest yesterday carry-over), LAST NIGHT (duration, efficiency, RHR, respiration, plus an
  "HR-only staging" confidence note), the NEXT strap-alarm countdown, and one-tap actions (Ask
  Coach, Sync, Buzz, Alarms). The ⋯ layout menu falls back to NOOP's built-in Liquid or Classic
  layouts at any time.
- **Wrist screen** (More → Wrist) — one glance at your strap: the five-step link chain (Connected ·
  Bonded · On wrist · Streaming · Synced), device card (name, firmware, battery, charging,
  voltage), live stream with frame age, sync state with the honest chunk counter, and the proven
  actions (Test buzz, Sync now, Reconnect). No protocol logs — those stay behind the Test Centre
  gate. Also reachable via the new "Show Wrist Status" Siri/Shortcuts intent.
- **Connection Guardian** — a named, plain-language diagnosis of the strap link (streaming · no
  live reading · sync due · reconnecting · paired-but-offline · disconnected · Bluetooth off) with
  one-tap recovery actions, shown on Today and Wrist. Read-only: it observes the same facts the
  app already publishes and never touches the BLE engine.
- **App-side alarm schedules** (More → Alarm schedules) — as many schedules as you like beside the
  strap's single hardware alarm: wake times you can copy onto the strap with one tap (through the
  same proven path the Alarms screen uses), and reminders that buzz your wrist while NOOP is
  running (quiet-hours respected) with a phone-notification fallback. The strap's one-alarm limit
  and iOS's background limits are stated plainly in the UI, not hidden.
- **Safer haptics vocabulary** — four named patterns (reminder / event / battery warning / wake),
  built exclusively on the hardware-confirmed buzz paths; no new opcodes.
- **Coach with structured context** — every question now rides with a compact structured block
  (today · last night · 7-day trends vs your own baseline), and the Coach screen states exactly
  what is attached. Two new suggested prompts. The API key stays in the Keychain, as upstream
  already had it.
- **Developer Lab** — the Test Centre and every protocol probe now live behind a clearly labelled,
  collapsed "Developer Lab" section in More. (Probes were already opt-in gated; this makes the
  boundary visible.)
- **CI on every push** — the app-build workflow now compiles both app targets and runs the app
  tests on direct pushes to the fork's main, not just PRs.

## Preserved upstream systems (untouched)

- The BLE engine (`BLEManager` / `FrameRouter` / bond watchdogs) — zero changes; every new feature
  observes or calls existing entry points only.
- The GRDB store, all v1–v46 migrations, the `.noopbak` backup whitelist — zero schema changes.
- The smart alarm's single funnel (`BehaviorStore` → `applySmartAlarm()` → `armStrapAlarm`, the
  hardware-confirmed #535 path) — reused, not duplicated.
- The unsigned-IPA + SideStore/AltStore release pipeline (`fork-testing-build.yml`,
  `fork-release.yml`, `Tools/prepare-ios-sideload-app.sh`, `altstore-source.json`) — unchanged.
- Bundle ID, versions, entitlements — unchanged (no version bump, no identity churn).

## New user-facing settings & keys (all display-local, none in `.noopbak`)

| Key | Meaning | Default |
|---|---|---|
| `noop.personalTodayEnabled` | personal glance Today | ON (fork default) |
| `personal.alarmSchedules` | app-side schedule list (JSON) | empty |
| `haptics.personalReminders` | reminder-haptic gate (HapticPrefs idiom) | ON |

## Install (unsigned IPA → SideStore)

1. Run the repo's **Testing build (fork)** workflow (Actions → *Testing build (fork)* → Run), or
   take the latest `testing-latest` prerelease.
2. Download `NOOP-ios-unsigned-v<version>.ipa` from that release.
3. Sideload with **SideStore** (recommended; see `docs/IOS.md` for the AltServer sign-in bug and
   the full flow). Free-Apple-ID realities: 7-day re-sign (SideStore auto-refreshes), 3-app limit,
   the embedded watch app is stripped from the IPA (widgets + Live Activities survive).
4. First run: pair your WHOOP 4.0 (guardian banner → Reconnect / Open Devices), then work through
   `REAL_DEVICE_TEST_CHECKLIST.md`.

## Known limitations (honest)

- Reminder buzzes require NOOP to be running on the phone; iOS suspends backgrounded apps. The
  notification fallback taps the phone, not the wrist. The strap's own firmware wake alarm remains
  the only dependable timed wrist event.
- The strap holds exactly ONE wake alarm; "Arm as strap alarm" overwrites it (reversibly — the
  Alarms screen edits the same alarm).
- WHOOP 5/MG owners: the upstream 5/MG alarm remains experimental and gated (unchanged); this fork
  targets the WHOOP 4.0.
- A sideload identity change (new Apple ID, bundle prefix switch, delete + reinstall) orphans the
  Keychain API key and the app container — keep one identity; `.noopbak` is the escape hatch.

## Credits & license

Built on **NOOP** by @ryanbr and contributors — the entire architecture, BLE protocol work,
analytics, design system and release pipeline are theirs. This fork only adds the personal layer
described above. PolyForm Noncommercial 1.0.0; see `LICENSE`.
