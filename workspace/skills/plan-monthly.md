---
name: Plan Monthly
created: 2026-04-14
last_used: —
use_count: 0
---

## Trigger

User says `/plan monthly`, or Heartbeat fires on 1st of month at 08:00.

## Persona

Use Mode B (Socratic Questioning). One question at a time. Focus on translating quarterly vision into actionable monthly focus areas.

## Steps

### Stage 1 — Gather context (silent)

Read all of these before speaking:
1. `planning/INDEX.md` — find current Future Log and previous Monthly Log
2. Current Future Log
3. Previous Monthly Log (if exists)
4. `projects/INDEX.md` → active projects' `GOALS.md`
5. `habits/weekly-stats.md` (skip if file doesn't exist)

### Stage 2 — Review previous month (skip if first month)

If no previous Monthly Log exists:
- Skip to Stage 3.

If previous Monthly Log exists:
1. Walk through each Focus Area — ask per item: "How did {focus} go this month?"
2. Note completions and gaps

### Stage 3 — Plan this month

1. Reference the Future Log's Monthly Breakdown for this month: "Your quarterly plan has {X} for this month. Still on track? Want to adjust?"
2. Ask: "Anything extra to add this month?"
3. The agent proposes Weekly Breakdown — list all ISO weeks overlapping this month with full date ranges (Mon date – Sun date). Typically 4-6 weeks. Discuss and adjust.

### Stage 4 — Write

Show the user the complete Monthly Log before writing. Confirm: "This is the plan for {Month YYYY}. OK to save?"

On confirmation:
1. Write to `planning/monthly/YYYY-MM.md` using the template:

```
# Monthly Log — {YYYY-MM}

## Focus Areas
- [ ] {focus} ← future:{goal-ref}

## Weekly Breakdown
- **W{NN} ({Mon date} – {Sun date})**: {focus for this week}
- **W{NN} ({Mon date} – {Sun date})**: {focus for this week}
<!-- rows for all overlapping ISO weeks -->

## Review
<!-- End-of-month review — to be filled later -->
```

2. Update `planning/INDEX.md` → set `Monthly:` to the new file path
3. Write completion marker to `daily/YYYY-MM-DD.md`:
   `- [x] plan-monthly (HH:MM)`

## Notes
- All file content must be in English (per AGENTS.md language rules)
- On month 1st, plan-daily runs after plan-monthly to handle sleep/calendar/exercise (don't skip it)
- Weekly Breakdown must use full date ranges, not just week numbers — "W16 (Apr 13 – Apr 19)" not just "W16"
- A month typically overlaps 4-6 ISO weeks. List them all.
