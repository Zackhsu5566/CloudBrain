---
name: Plan Daily
created: 2026-04-14
last_used: —
use_count: 0
---

## Trigger

User says `/plan today`, or Heartbeat fires daily at 08:00 (merged with morning check-in).

## Persona

Use Mode A (Warm & Firm) by default. Quick, practical, focused on today. Switch to Mode B if user seems uncertain about priorities.

## Steps

### Stage 1 — Pre-questions (preserved from morning check-in)

These steps happen BEFORE the planning conversation:

1. **Hot Cache Review** — read `cache.md`. If active threads or pending questions exist, weave 1-2 most relevant into conversation naturally. Skip if empty.
2. **Active Goals Review** — scan `projects/INDEX.md` → active projects' `GOALS.md` for milestones due within 7 days. Mention at most 2 conversationally. Skip if none.
3. **Memory Review** — check yesterday's `daily/YYYY-MM-DD.md` for `## Memory Review` section (written by nightly Dreaming pipeline). If present, weave a casual one-sentence summary. If flagged items exist, ask about them after the planning conversation.

### Stage 2 — Sleep (preserved)

Ask: "昨晚幾點睡？睡眠品質怎麼樣？" (feeds `habits/sleep.md`)

### Stage 3 — Daily planning (replaces top-3 + carryover)

Read silently:
1. `planning/INDEX.md` → current Weekly Log
2. Current Weekly Log → today's section under `## Daily Schedule`
3. Yesterday's `daily/` file
4. `cache.md`
5. Google Calendar (today's existing events)

Then propose:
"The weekly plan has {X} for today. Considering your calendar and what happened yesterday, I'd suggest this schedule: {proposed schedule}. What do you think?"

This is **confirm-and-adjust** — the weekly draft is the starting point, not a blank slate. User can:
- Confirm as-is
- Modify, reorder, add, or remove items
- Defer items to later in the week (they stay in Weekly Log draft for those days)

Discuss until user confirms.

### Stage 4 — Remaining morning items (preserved)

1. Ask: "今天有沒有需要提醒的行程？" (calendar reminders)
2. Ask: "今天打算做什麼運動？" (feeds 16:50 exercise reminder; if user says none, nudge once)

### Stage 5 — Write

On confirmation:
1. Write confirmed schedule items to Google Calendar. If Calendar API fails, note `[calendar sync failed]` in daily file. User can retry with `/plan today`.
2. Update Weekly Log's today section — add `[confirmed]` marker to the day header. Mark adjustments:
   - Items from draft kept as-is: unchanged
   - Items added during daily planning: append `← added`
   - Items removed/deferred: leave in draft but mark `← deferred to {day}`
3. Record in `daily/YYYY-MM-DD.md` Morning Check-in section (append-only)
4. Write completion marker: `- [x] plan-daily (HH:MM)`

## Notes
- All file content must be in English (per AGENTS.md language rules)
- This skill runs on ALL days including month/quarter first days (after plan-monthly/plan-future)
- On month/quarter boundary days, some context will already be fresh from the preceding planning sessions — don't ask redundant questions
- If no Weekly Log exists yet (e.g., first week of using the system), fall back to the old top-3 format: ask user directly for priorities instead of referencing a weekly draft
- Google Calendar writes are the final step. Never write to Calendar before user confirms.
