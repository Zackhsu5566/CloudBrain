# AGENTS.md — Operational Rules

## Archiving Rules (Signal-based Classification)

When a message arrives, classify it by scanning for these signals. If signals are ambiguous or match 2+ categories, ask the user.

| Target file | Signals |
|---|---|
| `→ business/IDEAS.md` | Message mentions: pricing, revenue, competitor, market, customer, funding, MVP, launch, business model, monetization, B2B, B2C, SaaS, or explicitly describes an idea that could generate revenue. |
| `→ ideas/tech.md` | Message mentions: a specific technology, framework, API, architecture pattern, dev tool, or programming concept — but does NOT involve commercialization or business viability. |
| `→ ideas/content.md` | Message mentions: writing an article, blog post, social media post, video script, newsletter, content strategy, or audience building. |
| `→ ideas/research.md` | Message mentions: wanting to study a topic, a paper to read, a learning goal, or a research question — but is NOT a concrete business idea or technical implementation. |
| `→ projects/[name]/NOTES.md` | Message mentions an existing project by name, or user explicitly says "this is about project-X". |
| `→ Ask user` | None of the above signals are clear, OR the message matches two or more categories equally. |

See also: **Wiki-Links** section for inline `[[wiki-link]]` rules when writing to mutable files.

## Source Immutability

The following directories are append-only — do not modify or delete existing content:

- `journal/` — user's original diary entries
- `daily/` — check-in responses and heartbeat logs

Allowed operations:
- Create new files (e.g., daily/2026-04-14.md)
- Append new sections to existing files (e.g., ## Evening Review, ## Memory Review, ## Heartbeat Log)
- Fix obvious typos within the same day

Prohibited operations:
- Modify files from past dates
- Delete any previously written paragraph
- Rewrite the user's original response wording

Mutable directories (normal read/write/update/delete):
- `planning/` — planning logs are living documents, updated each planning session

Exception: when the user explicitly requests a correction (e.g., "The sleep time yesterday was wrong, change it to 11pm"), modification is allowed. When correcting, append an audit note at the end of the modified paragraph:
`[corrected YYYY-MM-DD: {original value} → {corrected value}]`

## Archiving Confidence

- **High confidence** → silent archive, just tell user where it was saved.
- **Low confidence** → ask: "I'd file this to ideas/tech.md, sound right?"

## Opus Trigger Signal (STRICT)

Use Opus ONLY when:

1. User explicitly says "use Opus" or "deep analysis"
2. Weekly review + planning (Sunday 21:00 scheduled task, including plan-weekly skill)
3. Pitch preparation or investor Q&A drafting

Everything else → MiniMax-2.7. No exceptions. No auto-fallback.

## Language Rules

- **Reply language**: Mirror whatever language the user sends.
- **Archive language**: ALL writes to workspace must be in English.
- Translate faithfully. Preserve nuance, numbers, and proper nouns.

## Inbox Cleanup

- After archiving a message from `inbox/`: remove the entry (content is now in target file).
- On the 1st of each month: scan `inbox/` for stale items missed.
- Stale items older than 7 days → ask user before archiving.

## Planning Commands

When user sends `/plan` with a subcommand, load the corresponding skill:
- `/plan future` → `skills/plan-future.md`
- `/plan monthly` → `skills/plan-monthly.md`
- `/plan weekly` → `skills/plan-weekly.md`
- `/plan today` → `skills/plan-daily.md`
- `/plan` (no subcommand) → ask user which level, or auto-select based on context:
  - Sunday evening → suggest weekly
  - First day of month → suggest monthly
  - First day of quarter → suggest future
  - Otherwise → suggest today

## INDEX.md Query Priority

- When querying workspace, ALWAYS read the folder's `INDEX.md` first.
- Then decide which specific file to open based on the INDEX summary.
- Never blindly scan entire folders.

## Query Writeback

- **Trigger**: when response required web search, multi-file synthesis, or produced analysis/recommendations.
- **No trigger**: simple lookups, casual chat, journal entries (already tracked separately).
- **Agent behavior**: ask user before saving ("Worth keeping? Save to notes/?").

## Search Strategy

When retrieving information, choose the right tool for the job:

| Need | Method | When |
|------|--------|------|
| Exact keyword match | File search (read/grep workspace files) | User asks about a specific entry, date, name, number |
| Fuzzy semantic recall | Memory recall (LanceDB) | "What did I say about...", "How do I feel about...", vague references |
| Behavioral context | Read USER-INSIGHTS.md | Before check-ins, weekly reports, or giving personalized advice |
| Task playbook | Read skills/INDEX.md → skill file | User requests a task that might have a saved procedure |
| Concept overview | Read `wiki/index.md` → entity page | User asks about a concept that might have an entity page |

Priority order:
1. If the query contains a specific keyword/date/name → file search first
2. If the query is about a concept/topic → check `wiki/index.md` first
3. If the query is vague or about feelings/preferences → memory recall first
4. If both could apply → file search first, supplement with memory recall if insufficient

## Procedural Skills

### Creating skills
User triggers skill creation by saying: "save this as a skill" / "remember this process" / "do it this way from now on"

When triggered:
1. Review the task just completed — extract the steps, edge cases, and decisions made
2. Write to `skills/{kebab-case-name}.md` using this format:

```
---
name: {Skill Name}
created: YYYY-MM-DD
last_used: YYYY-MM-DD
use_count: 1
---

## Trigger
{When this skill applies}

## Steps
1. {Step}
2. {Step}

## Notes
- {Edge cases, warnings}
```

3. Update `skills/INDEX.md` — add one line: `- [{name}](filename.md) — {one-line description}`
4. Confirm: "Saved as skill: {name}. Next time you can say 'use the {name} process'"

### Using skills
- On receiving a task, scan `skills/INDEX.md` for a matching skill
- If found: read the skill file, follow its steps
- After execution: update `last_used` and `use_count` in frontmatter, update INDEX.md if needed
- Never auto-create skills. Only create when user explicitly asks.

### Improving skills

After executing a skill, evaluate whether it needs improvement.

Triggers for improvement (any one):
- A step was missing — extra work was needed to complete the task
- An edge case was encountered not covered in Notes
- Step ordering needed adjustment

Do NOT improve when:
- Execution was smooth with no issues
- The situation was a one-off unlikely to recur

Correction vs improvement:
- If the user corrects a step ("No, this step should do X first"), apply the fix but do NOT update `last_improved` — this is a user-initiated correction, not an agent-discovered improvement. Log it in ## Changelog as `(user correction)` to distinguish from agent improvements.
- Only update `last_improved` when the agent autonomously identifies the improvement during execution.

How to improve:
1. Edit the skill file's Steps or Notes section directly
2. Add `last_improved: YYYY-MM-DD` to frontmatter
3. Append to ## Changelog at the end of the file:
   ```
   ## Changelog
   - YYYY-MM-DD: {one-line description of what changed and why}
   ```
4. Inform user in reply: "Updated skill: {name} — {what changed}"

## User Insights

`USER-INSIGHTS.md` contains behavioral inferences about the user — patterns, goal drift, communication preferences. Updated nightly by the Dreaming pipeline.

### When to read
- Before 08:00 morning check-in
- Before 22:00 evening review
- Before Sunday 21:00 weekly report
- Before giving personalized advice or habit-related nudges

### How to use
- Adjust interaction mode based on observed communication preferences
- Reference behavioral patterns when relevant (e.g., "You exercised 4 times last week, up from the week before")
- Do NOT proactively say "I observed that you..." unless user asks or context is appropriate
- Insights inform your approach; they are not conversation topics by default

## Wiki-Links

When writing to any **mutable** workspace markdown file, add `[[kebab-case-name]]` links for concepts that have an existing entity page in `wiki/`. Immutable directories (`journal/`, `daily/`) are excluded — wiki-links are NOT inserted into those files.

### Entity page creation

Hard gate: a concept must appear in **2+ different files** before creating an entity page. Counting rules: each file counts as 1 regardless of how many times the concept appears within it; files in the same folder each count separately; immutable files count toward the threshold even though wiki-links are not inserted into them.

After passing the hard gate, also evaluate:
- DO create: concepts with concrete insights, research notes, or cross-domain relevance
- DO NOT create: generic technology terms (`[[typescript]]`), trivial daily items (`[[lunch]]`)

Entity page template:

```
---
category: {business|technology|health|content|research|personal|project|repo}
created: YYYY-MM-DD
---

# {Concept Name}

{1-2 paragraph summary: what this concept is, why it matters}

## Related
<!-- Bidirectional: if A lists B here, B must also list A. Enforced by nightly Step 1b. -->
- [[related-concept-1]]

## Sources
- path/to/file.md — {context of mention}

## Contradictions
<!-- Auto-detected by nightly Step 1a. Do not manually edit. -->
```

Category values by topic: business, technology, health, content, research, personal, project, repo.

### Behavior

- Adding a wiki-link → silent, no notification
- Creating an entity page → mention in reply: "建了 `wiki/{name}.md`"
- Before creating, read `wiki/index.md` to check for duplicates
- Naming convention: kebab-case English only. Link name = filename.

### Ownership

Wiki is maintained exclusively by the agent.

### Skills vs Wiki

`skills/` and `wiki/` are independent namespaces. Same kebab-case name is allowed — `skills/` = how to do it, `wiki/` = what it is.

### Wiki Log

`wiki/log.md` is a chronological audit trail of all wiki maintenance operations. Appended automatically by nightly.sh Steps 1a and 1b. Read-only for agents — do not manually edit.

### Contradiction Detection

Scope: within a single entity page, across its `## Sources` entries. When nightly Step 1a adds or updates a source for an entity, it compares the new source's claim against existing sources' claims for that same entity.

- **Skip condition:** If the entity was just created in this same run (only 1 source exists), there is nothing to compare — skip contradiction check for that entity.
- If claims conflict → append to the entity's `## Contradictions` section:
  ```
  - ⚠️ {source-file-A} ({date}) claims "{claim A}"
    vs {source-file-B} ({date}) claims "{claim B}"
    — [unresolved]
  ```
  The `({date})` is the source file's **last-modified date** (filesystem mtime), not the nightly scan date.
- Cross-entity claims (e.g., LoRA page vs QLoRA page) are NOT contradictions — different concepts may have different properties.
- When the agent reads an entity page during a query and finds `[unresolved]` contradictions, it must inform the user and ask which claim is correct.
- User resolves → the agent updates the tag to `[resolved: YYYY-MM-DD — {resolution}]` and corrects the summary if needed.
- **Cleanup:** Nightly Step 1b removes `[resolved: ...]` entries older than 30 days from `## Contradictions` sections. This keeps entity pages clean while preserving recent resolution context.

### Hot Cache

`cache.md` is a short-term working memory for cross-session continuity. It stores threads, pending questions, and recent decisions that are still in progress.

#### Division of labor: cache.md vs LanceDB

| | cache.md | LanceDB |
|---|---|---|
| Content | Unfinished threads, pending questions, undecided topics | Confirmed insights, preferences, decisions, facts |
| Lifespan | 72h auto-expire (unless `[pinned]`) | Long-term, pruned by nightly Step 2d |
| Analogy | Open documents on the desk | Filed in the cabinet |

#### When to write (22:00 session-end)

During Session-End Extraction, for each extracted insight:
1. Has a conclusion → LanceDB (existing behavior, unchanged)
2. Still in progress / no decision yet → cache.md under the appropriate section
3. Both → conclusion to LanceDB, open thread to cache.md

#### When to read (08:00 morning)

Before the 5 morning questions, read cache.md. If there are active threads or pending questions, weave them naturally into the check-in:
- "Yesterday you were comparing X and Y — have you decided?"
- Do NOT recite the cache — reference it conversationally.

#### Sections

- **Active Threads** — ongoing discussions without conclusion. Format: `- **{topic}** — {1-line context} [expires: YYYY-MM-DD]`
- **Pending Questions** — things the user deferred. Format: `- {question} [expires: YYYY-MM-DD]`
- **Recent Decisions** — decisions made in the last 72h for quick reference. Format: `- {decision} ({date}) [expires: YYYY-MM-DD]` or `[pinned]`

#### Expiry and pinning

- Default expiry: 72h from creation
- `[pinned]` entries never expire — user must explicitly unpin ("unpin X")
- Nightly Step 2d cleans expired entries
- The agent may suggest pinning if a thread persists across 3+ sessions

## Project Tracking

### Directory: projects/
- Each project has its own subdirectory: `projects/{kebab-case-name}/`
- `GOALS.md`: long-term goals + short-term milestones with `due: YYYY-MM-DD`
- `NOTES.md`: freeform notes, append-only within a day
- `INDEX.md`: overview of all projects and their status (active/paused/done)
- `projects/` is NOT scanned by nightly Dreaming (Step 2). INDEX.md is maintained by skills and manual updates only.

### Rules
- When user mentions a new project, check if it exists in `projects/` first
- Mark milestones as done (`[x]`) when user confirms completion
- Move completed short-term milestones to a `## Completed` section (don't delete)
- Update `INDEX.md` status when a project is paused or completed
- ANY creation or modification of `projects/*/GOALS.md` MUST also update `projects/INDEX.md` — whether via skill or normal conversation
