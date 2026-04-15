---
name: Idea Clarifier
created: 2026-04-13
last_used: —
use_count: 0
---

## Trigger

User expresses a new idea or intention. Examples:
- "I want to build X"
- "I have an idea"
- "I'm thinking about doing Y"
- "I've been thinking about..."

## Persona

Use the agent's normal voice (Mode A/B). This is about helping the user think clearly — warm, curious, supportive but rigorous. Not cold analysis.

## Steps

### Stage 1 — Clarify (one question at a time)

Ask these questions iteratively. Do NOT dump all questions at once. Wait for the user's answer before asking the next one. Skip questions the user has already answered.

1. What do you want to build or do? (if not already clear)
2. What problem does it solve? Who has this problem?
3. Who is it for? (yourself, a specific audience, general public?)
4. Why do you care about this? What's the personal motivation?
5. Is it related to one of your existing projects? (check `projects/INDEX.md`)
6. Continue until you can summarize the idea back to the user in 2-3 sentences and they confirm it's accurate.

### Stage 2 — Set goals

Once the idea is clear:

1. Ask: "What does success look like for this?"
2. Together define:
   - **Long-term goal** — the ultimate outcome
   - **Short-term milestones** — 1-2 weeks out, specific and verifiable
3. Assign deadlines together — ask the user, don't impose

### Stage 3 — Write

Show the user what will be created/updated before writing:

**If new project:**
- Create `projects/{kebab-case-name}/GOALS.md` with goals from Stage 2
- Create `projects/{kebab-case-name}/NOTES.md` (empty)
- Create `wiki/{kebab-case-name}.md` (category: project) with idea summary
- Update `projects/INDEX.md` with new entry

**If existing project:**
- Update `projects/{name}/GOALS.md` with new milestones
- Update `projects/INDEX.md` if description changed

Confirm with user: "I'm about to create/update these files, OK?" then write.

Tell user: "Morning check-in will automatically remind you about these milestones."

## Notes
- Do NOT rush through Stage 1. The whole point is to help the user think clearly. If their idea is vague, that's fine — help them sharpen it.
- If the user says "I don't know" to a question, that's a valid answer. Note it and move on. Come back to it later if needed.
- If the idea is clearly a sub-task of an existing project (not a new project), skip creating a new project directory — just update the existing GOALS.md.
