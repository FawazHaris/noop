# Real-Device Test Checklist — NOOP Personal Fork V1

Run these **in order** on the target iPhone with a real WHOOP 4.0, after installing the fork's
unsigned IPA via SideStore (see `docs/IOS.md` for the sideload flow; `fork-testing-build.yml`'s
`testing-latest` release carries `NOOP-ios-unsigned-v<version>.ipa`).

**Capture evidence ONLY if a check fails** (screenshot or screen recording +, where noted, the
strap log from More → Developer Lab → Test Centre → Export). A check passes if — and only if —
the "What should happen" line is fully true.

> Precondition for all checks: iPhone Bluetooth on, NOOP notifications permission either granted or
> deliberately denied (note which — two checks depend on it).

---

## 1. Launch & first screen

- **Tap:** the NOOP icon (first launch after sideload).
- **What should happen:** the app opens to the **personal Today glance** (big "You now" heart-rate
  area, TODAY / LAST NIGHT tiles, NEXT alarm, quick actions). Before pairing, the guardian banner
  says the strap is not connected, and the heart-rate number reads `--` honestly.
- **If it fails:** screenshot the whole screen + note the exact text shown.

## 2. Existing history intact (upgrade path)

- **Tap:** nothing yet — just look at TODAY / LAST NIGHT tiles.
- **What should happen:** if this install kept its container (a SideStore refresh over the same
  bundle ID), previously synced days still show (tiles carry values; the section header may say
  "yesterday" before today scores — that is correct, not a bug). A fresh install (new bundle ID or
  after a delete-reinstall) shows honest dashes — also correct.
- **If it fails:** screenshot Today + open Trends (one screenshot) and note the install path.

## 3. Pair / connect the strap

- **Tap:** the guardian banner's **Reconnect strap** (or Open Devices → pair flow).
- **What should happen:** an encrypted bond enables buzz/history commands. Before the first
  completed history sync the guardian still says **Sync due**, even while HR streams; it clears
  after a successful sync (or stays informational while backfilling). The "You now" card
  shows a live bpm and an "as of Ns ago" line that stays under ~15 s while worn.
- **If it fails:** capture the strap log (Developer Lab → Test Centre → Export) — it carries the
  connect/bond trace.

## 4. Live heart rate

- **Watch:** the "You now" number for ~30 s.
- **What should happen:** it tracks your pulse and does not freeze; the staleness line stays fresh.
  Take the strap off → within ~10–60 s the guardian/banner reflects "no live reading" (the exact
  wording may vary by state); put it back on → it recovers.
- **If it fails:** screen-record 60 s around the failure.

## 5. Battery + device card

- **Tap:** More → **Wrist**.
- **What should happen:** the Wrist screen shows the five-step chain (Connected · Bonded · On
  wrist · Streaming · Synced — the first three filled), the device card with the strap's name (or
  "WHOOP strap" before the firmware reports it), firmware string, battery % (charging bolt if on
  the charger), and the same battery % as the Today badge.
- **If it fails:** screenshot Wrist + Today together (the two battery numbers must match).

## 6. Backfill / history sync

- **Tap:** Wrist → **Sync now** (or Today's **Sync strap** quick action).
- **What should happen:** the sync card shows the in-progress pill + a chunk count that climbs; on
  completion it reads "History synced" with a fresh "N min ago". Today's LAST NIGHT tiles fill in
  after the re-score (may take a minute — pull-to-refresh).
- **If it fails:** capture the strap log immediately (it holds the offload trace).

## 7. Buzz

- **Tap:** Wrist → **Test buzz**.
- **What should happen:** the strap buzzes once (the acked one-shot sequence). If it does not, tap
  Reconnect and retry once — a just-woken link can drop the first write.
- **If it fails:** note whether the strap log shows "Buzz: one-shot fired".

## 8. Strap alarm

- **Tap:** More → **Alarm schedules** → Add schedule → kind **Wake**, a time 2–3 minutes out →
  Save → **Arm as strap alarm**. Then confirm on More → **Alarms** that the strap wake-alarm card
  shows the same time.
- **What should happen:** "On the strap" on the schedules screen and the Alarms screen agree on
  the same next buzz; at the chosen time the strap buzzes on your wrist (phone can be asleep).
  Disarm afterwards in Alarms.
- Also leave Today visible across the occurrence: its countdown AND timestamp must advance to
  the next selected weekday. Existing per-day overrides must not change a newly copied schedule's
  time. Try Wake + One specific day: Save must be disabled with the repeating-wake/reminder explanation.
- **If it fails:** note the two times shown on each screen (if they disagree, that is the bug) and
  whether the strap buzzed.

## 8b. App reminder (honest limits)

- **Tap:** Alarm schedules → Add schedule → kind **Reminder**, 1–2 minutes out → Save. Keep NOOP
  in the FOREGROUND and the phone unlocked.
- **What should happen:** at the time, the strap buzzes the reminder pattern (1 short buzz by
  default) while NOOP is alive; a phone notification appears if notifications are authorized.
  Backgrounding NOOP before the time = no wrist buzz (iOS suspension) — that is the documented
  limit, the notification fallback covers it.
- Repeat after relaunch without opening Alarm schedules. Test a repeating reminder across two
  occurrences. Edit daily → selected weekdays → one-off, then disable/delete; no old request may
  fire. Also test rapid edit/delete while permission is being checked, and granting permission in
  iOS Settings then reopening NOOP.
- **If it fails:** note whether NOOP was foregrounded and whether a notification arrived.

## 9. Background & reopen

- **Do:** background NOOP for ~5 minutes (screen off is fine), then reopen.
- **What should happen:** on reopen the Today numbers are current (the shell refreshes), the
  guardian banner reflects the real link state, and no probe/diagnostic popup appears.
- **If it fails:** screenshot whatever appeared.

## 10. Bluetooth off / on

- **Do:** toggle iPhone Bluetooth OFF (Settings or Control Center), wait ~10 s, look at Today;
  then toggle it back ON.
- **What should happen:** with BT off, the guardian says **Bluetooth is off** (not a generic
  disconnect); after BT returns, the strap reconnects on its own within ~30 s and the banner clears.
- **If it fails:** screenshot the banner in each state.

## 11. Coach key + ask

- **Tap:** the Coach tab → set up with your Gemini (or other provider) key → enable data access →
  ask "How do my last 7 days compare to my baseline?".
- **What should happen:** the header shows an "Attached: …" line naming the context; the reply
  cites your actual numbers, including a 7-day trend comparison (the fork's structured context
  block). After a key rejection, the repair path offers Update key.
- **If it fails:** screenshot the Coach screen incl. the Attached line + the error text.

## 12. Shortcut run

- **Do:** in the Shortcuts app, run **Show my NOOP wrist status** (or create a button for the
  "Wrist Status" shortcut). Also try the upstream **Sync Strap** shortcut once.
- **What should happen:** NOOP opens directly on the Wrist screen (pushed inside the More tab);
  the Sync shortcut reports honestly ("syncing" / "strap isn't connected yet").
- **If it fails:** note which shortcut and the exact reply/dialog text.

## 13. Relaunch persistence

- **Do:** force-quit NOOP and relaunch.
- **What should happen:** the personal Today layout is still selected, alarm schedules and the
  armed strap alarm survive, and the layout menu still offers the Liquid/Classic fallbacks.
- **If it fails:** screenshot Today + Alarm schedules.

## 14. Developer Lab isolation

- **Tap:** More — scan the list — then expand **Developer Lab** → Test Centre.
- **What should happen:** the everyday More groups (Insights / Body / Data / App) contain no
  diagnostics; Developer Lab starts collapsed; Test Centre opens only on explicit tap with every
  probe still behind its domain gate. Nothing probe-related auto-surfaces anywhere during the
  whole session (checks 1–13).
- **If it fails:** screenshot where the probe/diagnostic surfaced.

---

## Evidence capture quick reference

| Evidence | Where |
|---|---|
| Screenshot | iPhone Side + Volume Up |
| Screen recording | Control Center screen-record |
| Strap log (the single diagnostic funnel) | More → Developer Lab → Test Centre → export/share (see `Strap/BLE/LiveState.swift` — redacted on write) |
| Sync details | Wrist screen → Sync card + the strap log's offload trace |

Keep the phone on the SAME Apple ID + bundle prefix across refreshes — switching either orphans
the Keychain API key and the app container (documented in `docs/IOS.md` and the architecture
audit §7); the `.noopbak` backup is the escape hatch.
