# Heartbeat Schedule

## How heartbeat works

Every 30 minutes, the agent receives a heartbeat turn. It must:

1. Check current local time (using your configured timezone).
2. Scan the schedule below for any task whose window contains the current time.
3. **If a task matches → execute it immediately. Send the message to the user. Do NOT reply HEARTBEAT_OK.**
4. If no task matches → reply `HEARTBEAT_OK` (silent, no user message).

**Time windows:** each task fires once when the clock first enters its window (±15 min of the listed time). Track completion in today's daily file (`daily/YYYY-MM-DD.md`) so the same task doesn't repeat in the same day.

**Do not wait for the user to initiate.** Scheduled tasks are proactive — the agent sends first.

---

## Configuration

Before deploying, customize these values for your location:

```
TIMEZONE=UTC+8                              # Your timezone
CITY=YourCity                               # For weather (used with wttr.in)
NEWS_SOURCE=https://www.npr.org             # Or your preferred news source
AIR_QUALITY_API=                            # Optional: air quality API endpoint
AIR_QUALITY_API_KEY=                        # Optional: set via .env file
```

Store API keys in `~/.openclaw/.env`, never in this file.

---

## Schedule

| Time (local) | Task | Agent | Phase |
|--------------|------|-------|-------|
| 07:50 | News + weather (combined) | Agent | 1 |
| 08:00 | Morning check-in + daily planning (see priority logic) | Agent | 1 |
| 12:00 | Noon inbox archiving | Agent | 1 |
| 16:50 | Exercise reminder (only if exercise was set in morning check-in) | Agent | 1 |
| 18:00 | Evening summary | Agent | 1 |
| 22:00 | Evening review + journal | Agent | 1 |
| Sun 21:00 | Weekly review + weekly planning | Agent (Opus) | 1 |
| 02:00 | nightly.sh: Wiki Maintenance → Dreaming → Backup | System | 3 |

---

## 07:50 — News + Weather (Combined)

Fetch top 5-6 stories from your configured news source — for EACH story, fetch the individual article page and extract the key details (who, what, when, where, why). Do NOT just list headlines. Write 2-3 substantive paragraphs per story with real context. Combine with current weather. Send as one combined message.

```
[News Briefing — Top 5 stories]
[Weather — current conditions + daily forecast]
```

**Weather:** `wttr.in/{CITY}` — temp, feels-like, humidity, UV, hourly forecast.

**Air quality (optional):** If `AIR_QUALITY_API` is configured in `.env`, fetch and display AQI. If API fails (timeout, rate limit), skip silently. Max 5s fetch timeout. Omit air quality section entirely if no data available.

---

## 08:00 — Morning Check-in + Daily Planning

### Priority Logic

1. First day of calendar quarter (default: 1/1, 4/1, 7/1, 10/1)? → Run `skills/plan-future.md`, then `skills/plan-monthly.md`, then `skills/plan-daily.md`
2. First day of month? → Run `skills/plan-monthly.md`, then `skills/plan-daily.md`
3. Otherwise → Run `skills/plan-daily.md`

On boundary days (quarter/month first day), plan-daily always runs last to ensure sleep tracking, calendar reminders, and exercise plan are never skipped.

**Fallback**: If a quarterly or monthly planning session was not completed yesterday (no completion marker in yesterday's daily file), re-trigger it today before plan-daily. Check completion markers in `## Planning Completed` section.

### plan-daily flow (runs every day)

Read the full skill file at `skills/plan-daily.md` and follow its steps. Summary:

1. Hot Cache Review — weave active threads from `cache.md`
2. Active Goals Review — mention milestones due within 7 days from `projects/*/GOALS.md`
3. Memory Review — check yesterday's daily file for `## Memory Review` (conditional)
4. Ask sleep quality (feeds `habits/sleep.md`)
5. Read current Weekly Log's today section → propose schedule (confirm-and-adjust)
6. Discuss and finalize
7. Ask calendar reminders
8. Ask exercise plan (feeds 16:50 reminder)
9. Write to Google Calendar + update Weekly Log + record in daily file

After completion, write to `daily/YYYY-MM-DD.md`:

```
## Planning Completed
- [x] plan-daily (HH:MM)
```

(On boundary days, also include plan-future and/or plan-monthly markers.)

---

## 12:00 — Noon Inbox Archiving

Check `inbox/INDEX.md`. If there are pending items, silently archive them to the correct folder per AGENTS.md archiving rules. Update INDEX.md. No user message unless something is ambiguous.

---

## 16:50 — Exercise Reminder

Only send if morning check-in recorded a planned exercise. Send a one-line reminder.

Skip silently if no exercise was recorded this morning.

---

## 18:00 — Evening Summary

Send a brief summary of the day so far:
- Any ideas or notes filed today
- Finance log (if any entries today)
- Unfinished morning top-3 items
- One line suggestion for the evening

Keep it to 3-5 lines. Don't ask questions — just inform.

---

## 22:00 — Evening Review

Send the required questions + 1-2 rotating questions in one message. Keep it conversational, not clinical.

### Required (every day)

1. How many of your morning top 3 did you complete?
2. Describe your mood today in one word. Why?
3. What would you do differently tomorrow?

### Rotating (pick 1-2, vary day to day)

4. What did you learn today, even something small?
5. What are you grateful for today?
6. What did you eat today? Did you follow the plan?
7. Did you exercise? What type, how long?

After user replies: append evening responses to today's `daily/YYYY-MM-DD.md`. Then perform session-end extraction before marking done.

---

### Session-End Extraction

After writing evening responses to daily file, before marking done:

1. Review today's conversation history available in your current context window. If context has been compressed and earlier turns are lost, process only what is available — do not skip extraction entirely.
2. Extract and store to LanceDB via memory_store. Tag each entry with `[source: session-end]`:
   - Decisions the user made
   - Commitments
   - Preference shifts
   - Emotional turns
3. Write a `## Session Insights` section to today's `daily/YYYY-MM-DD.md` summarizing what was extracted (2-5 bullet points).
4. Skip content that was already archived to workspace files during the day.
5. Update `cache.md`:
   - For insights still in progress: add with `[expires: {date+72h}]`.
   - For threads resolved today: remove from cache.md.
   - Update the "Last updated" timestamp.
6. Silent — do not notify user
7. Mark evening review as done only after extraction completes

---

## Sunday 21:00 — Weekly Review + Planning

Use Opus model (per AGENTS.md). Read the full skill file at `skills/plan-weekly.md` and follow its steps. Summary:

### Review phase

Compile from this week's daily files:
- Habit completion rates (exercise, sleep, food)
- Goal vs reality comparison
- Top learnings
- Honest observation about the week's patterns

Present as a structured report.

### Planning phase

Run the planning flow from `skills/plan-weekly.md`:
1. Carryover check — for each incomplete item, ask whether to keep, escalate, rescope, or drop
2. Plan next week — reference Monthly Log's weekly breakdown, propose day-by-day draft
3. Write next week's Weekly Log + update `planning/INDEX.md`

After completion, write to `daily/YYYY-MM-DD.md`:

```
## Planning Completed
- [x] plan-weekly (HH:MM)
```

---

## Completion tracking

To prevent double-firing, append completion records to `daily/YYYY-MM-DD.md`:

```
## Heartbeat Log
- 08:00 morning check-in: done
- 22:00 evening review: done
```

```
## Planning Completed
- [x] plan-future (HH:MM)
- [x] plan-monthly (HH:MM)
- [x] plan-daily (HH:MM)
- [x] plan-weekly (HH:MM)
```

Planning markers are separate from heartbeat markers. A planning session is "completed" only when the user confirms the final plan and the agent writes the output file. If the user abandons mid-conversation (no confirmation), no marker is written — fallback re-triggers next day.

Manual triggers (`/plan future`, `/plan monthly`, `/plan weekly`, `/plan today`) always execute regardless of markers.

If the daily file doesn't exist yet, create it with the relevant section.
