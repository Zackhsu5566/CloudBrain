---
name: Plan Future
created: 2026-04-14
last_used: —
use_count: 0
---

## Trigger

User says `/plan future`, or Heartbeat fires on first day of calendar quarter (default: 1/1, 4/1, 7/1, 10/1) at 08:00.

## Persona

Use Mode B (Socratic Questioning). One question at a time. Warm but structured — this is long-term vision work.

## Steps

### Stage 1 — Gather context (silent)

Read all of these before speaking:
1. `planning/INDEX.md` — find previous Future Log path
2. Previous Future Log (if exists)
3. `projects/INDEX.md` → active projects' `GOALS.md`
4. `USER-INSIGHTS.md`
5. `USER.md`
6. `business/IDEAS.md`
7. `ideas/INDEX.md` — scan for relevant idea files

### Stage 2 — Review previous quarter (skip if first-time)

If no previous Future Log exists:
- Say: "Let's set up your first quarterly plan. What are the big things you want to focus on this quarter?"
- Skip to Stage 3, question 1.

If previous Future Log exists:
1. Walk through each goal — ask: "This was on your list: {goal}. How did it go?"
2. For each: mark done, carry forward, or drop
3. Ask: "Anything else from last quarter worth noting?"

### Stage 3 — Define new quarter goals

Ask one at a time:
1. "What new things do you want to pursue this quarter?" — for each item:
   - "Why is this important to you?"
   - "What does success look like?"
   - "Is this linked to any existing project?" (reference `projects/INDEX.md`)
   - Assign a category tag (free-text: project, health, learning, finance, personal, social, career, etc.)
2. "How would you prioritize these goals?"
3. "Let's break this into months." — The agent proposes a Monthly Breakdown based on priorities and dependencies, then discusses adjustments.

### Stage 4 — Write

Show the user the complete Future Log before writing. Confirm: "This is the plan for Q{N}. OK to save?"

On confirmation:
1. Write to `planning/future/YYYY-QN.md` using the template:

```
# Future Log — {YYYY} Q{N}

## Vision
{user's big-picture direction}

## Goals
- [ ] {goal} — category: {tag}
  - why: {motivation}
  - success: {completion criteria}
  - links: [[project-name]] GOALS.md (if applicable)

## Monthly Breakdown
- **{Month 1}**: {focus areas}
- **{Month 2}**: {focus areas}
- **{Month 3}**: {focus areas}

## Review
<!-- End-of-quarter review — to be filled later -->
```

2. Update `planning/INDEX.md` → set `Future:` to the new file path
3. Write completion marker to `daily/YYYY-MM-DD.md`:
   `- [x] plan-future (HH:MM)`

## Notes
- All file content must be in English (per AGENTS.md language rules)
- If triggered on quarter first day, plan-monthly runs next (transition naturally: "Great, now let's plan this month in more detail.")
- Categories are free-text — don't force the user into a fixed list
- Do NOT create project directories here. If user wants to formalize a goal into a project, suggest using the Idea Clarifier skill afterward.
