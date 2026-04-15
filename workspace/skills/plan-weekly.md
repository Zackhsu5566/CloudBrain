---
name: Plan Weekly
created: 2026-04-14
last_used: —
use_count: 0
---

## Trigger

User says `/plan weekly`, or Heartbeat fires Sunday 21:00 (merged with existing weekly review).

Entire session (review + planning) uses **Opus model**.

## Persona

Use Mode B (Socratic Questioning). One question at a time. Balance honest review with forward momentum.

## Steps

### Stage 1 — Gather context (silent)

Read all of these before speaking:
1. `planning/INDEX.md` — find current Monthly Log and current Weekly Log
2. Current Monthly Log
3. Current Weekly Log
4. This week's `daily/` files (Mon-Sun)
5. `habits/INDEX.md` → relevant habit files
6. `cache.md`

### Stage 2 — Review this week

Walk through each item in `## This Week's Plan`:
1. For each item, ask: "How did {task} go?" — done / partially done / not started
2. Mark items as `[x]` (done) or leave `[ ]` (incomplete)
3. Fill in `## Review` section of current week's Weekly Log

### Stage 3 — Carryover check

For each incomplete item from Stage 2, ask one by one:
- "Still want to keep {task} for next week?"

If the item has been carried over 3+ weeks (check the `carried N weeks` count):
- The agent proactively suggests: "This has been on the list for {N} weeks. Three options: escalate it to your monthly/future plan, rescope it smaller, or drop it. What do you think?"

Kept items will be marked in next week's log as:
`← carryover:W{current} (carried {N+1} weeks)`

### Stage 4 — Plan next week

1. Reference the Monthly Log's Weekly Breakdown for next week: "The monthly plan has {X} for next week. Plus carryover: {Y}. How do you want to arrange these?"
2. Discuss day-by-day draft allocation — the agent proposes, user confirms/adjusts
3. These are **drafts** — each morning's plan-daily will finalize them

### Stage 5 — Write

Show the user the complete next-week plan before writing. Confirm: "This is the draft for W{NN+1}. OK to save?"

On confirmation:
1. Update current week's Weekly Log — fill `## Review` section (from Stage 2)
2. Create **next week's** `planning/weekly/YYYY-WNN.md` using the template:

```
# Weekly Log — {YYYY}-W{NN} ({Mon date} – {Sun date})

## This Week's Plan
- [ ] {task} ← monthly:{focus-ref}
- [ ] {task} ← carryover:W{prev} (carried {N} weeks)

## Daily Schedule (draft — confirmed each morning by plan-daily)
### Monday {MM/DD}
- [ ] {action item}

### Tuesday {MM/DD}
- [ ] {action item}

### Wednesday {MM/DD}
- [ ] {action item}

### Thursday {MM/DD}
- [ ] {action item}

### Friday {MM/DD}
- [ ] {action item}

### Saturday {MM/DD}
- [ ] {action item}

### Sunday {MM/DD}
- [ ] {action item}

## Review
<!-- Sunday 21:00 review — to be filled next week -->
```

3. Update `planning/INDEX.md` → set `Weekly:` to the new file path
4. Write completion marker to `daily/YYYY-MM-DD.md`:
   `- [x] plan-weekly (HH:MM)`

## Notes
- All file content must be in English (per AGENTS.md language rules)
- This session uses Opus model (per AGENTS.md Opus trigger rules)
- The existing weekly review (habit rates, goal vs reality, top learnings, agent's observation) runs FIRST as Stage 2. The planning phase (Stages 3-5) replaces the old free-form goal-setting question.
- Daily Schedule is a DRAFT. Each morning plan-daily will confirm-and-adjust it.
- Week numbering follows ISO 8601 (Mon-Sun). Sunday 21:00 falls on the last day of the current ISO week.
- Cross-year weeks use ISO year (W01 starting in December uses the next year's number).
