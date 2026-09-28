# Personal V1 final architectural audit — PR #2

Source audit: 28 September 2026. Scope is the full diff against the fork's `main`, not just the
latest review-fix commit. Build/check evidence is the live PR #2 checks; do not treat this document
as hardware validation or authorization to merge/run the IPA workflow.

## Findings resolved

- Guardian reports a missing completed sync as Sync due, after pairing/error gates and outside
  active backfill. Regression cases cover missing/fresh/stale sync, pairing, errors and backfill.
- Today resolves both alarm timestamp and countdown from each TimelineView tick.
- Exact-date wake schedules cannot be saved or enabled; legacy records remain editable/deletable
  but have no advertised next occurrence. The UI offers repeating wake or a one-off reminder.
- Today and Coach share the same sleep-first selection; a banked sleep-only today row wins over
  older vitals. Only a row without sleep invokes Repository.lastVitalsDay.
- Wrist and Personal Today buzz actions require connectivity and encryptedBond.
- Notification authorization callbacks carry revisions; cancelled/edited requests cannot be
  reinstated by old callbacks. One-off/daily and all seven weekly identifiers are owned/cancelled
  together. Notification add/remove calls are serialized on the main actor.
- Persisted reminders reconcile at launch/foreground, including changed notification permission.
  The single shared timer remains idempotent. Unavailable command channels don't consume the
  foreground occurrence; delivery remains best-effort within the existing two-minute grace.
- Quiet-hours checks use the occurrence's fire date, not a later polling time. A long reminder
  pattern remains subject to quiet hours; the separate firmware wake alarm is unaffected.
- Copying a repeating wake schedule clears inherited per-day overrides through the existing
  WindDownNudge settings API before applySmartAlarm, so the armed time matches the chosen schedule.
- Coach's trend windows cover actual calendar days, excluding stale and future-dated history,
  rather than treating the last seven rows as the last seven days.

## Architectural boundaries verified

| Area | Result |
|---|---|
| BLE safety | No new commands, opcodes, framing, handshake, encrypted-bond or backfill behavior. Actions use existing buzz, sync, connect and alarm funnels. Guardian only reads LiveState. |
| Wake lifecycle | BehaviorStore + applySmartAlarm remain authoritative. Firmware alarm remains a single instant; upstream fire-event, daily timer and foreground re-arm paths are unchanged. No promise of background app execution. |
| Reminder lifecycle | Phone notifications survive suspension/relaunch; foreground wrist reminders require the live encrypted connection. Repeating calendar triggers continue after the first occurrence. Disabling/deleting invalidates pending callback revisions and every owned request shape. |
| Today provenance | Recovery uses Repository.widgetAnchor, not vitals carry. HRV/RHR select field-specific sources and show the selected source date only when that value fell back. Effort is today's stored score through StrainScorer.effectiveEffort, never a prior-vitals fallback or speculative live estimate. |
| Coach | Same consent-gated summary channel; no raw-data export or new network path. Banked sleep selection is shared with Today; missing values remain missing; trends use bounded calendar windows. |
| Persistence | Device-local JSON/UserDefaults schedules retain existing IDs, enabled state and dedup stamps. No SQLite changes, migrations, backup-whitelist changes or historical-data rewrites. |
| App Intents | Additive showWrist action uses the existing App Group pending-action queue, foreground drain and NavRouter. No BLE from the intent extension; existing buzz/Coach/sync intents stay on upstream paths. |
| Upstream fallback | Liquid/classic Today, Devices, SmartAlarmView, Test Centre gates and all storage/history/sync infrastructure remain available and unchanged. |
| Localization | Existing catalog and audit baselines preserved; no gate weakening or baseline expansion. Reused copy is already localized. |

## Verification boundaries

- Focused headless checks execute the repository's actual Guardian, Coach and revision sources.
- Added macOS app-target tests cover resolver/revision behavior. Source-contract tests pin iOS
  wiring explicitly; they do not claim to execute iOS views or notification delivery.
- Full macOS build + StrandTests and iOS compile are verified by the Xcode-backed PR workflow.
- Real WHOOP 4.0/iPhone delivery, background behavior and sideload persistence remain the next
  stage in REAL_DEVICE_TEST_CHECKLIST.md. iOS permission/focus/notification-capacity constraints
  still make phone notification delivery best-effort, not a guaranteed wrist wake channel.
- PR #2 stays unmerged. The unsigned IPA workflow has not been run.
