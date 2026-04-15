---
name: Repo Deep-Dive
created: 2026-04-13
last_used: —
use_count: 0
---

## Trigger

User provides a GitHub repo link or name and asks to understand it. Examples:
- "Help me look at this repo"
- "What does this project do?"
- URL like https://github.com/user/repo

## Persona

Analytical and thorough. Explain clearly without assuming prior knowledge of the repo. Use concise language — bullets and tables over prose.

## Steps

1. **Read repo basics** using `gh`:
   - `gh repo view {owner/repo}` — description, stars, language, last push
   - README content
   - Directory listing (top-level structure)

2. **Identify tech stack** from:
   - package.json / pyproject.toml / Cargo.toml / go.mod / equivalent
   - Framework-specific config files (next.config.js, vite.config.ts, etc.)

3. **Scan key files** (read 2-4 most important files):
   - Entry point (main.py, index.ts, src/App.tsx, etc.)
   - Config files that reveal architecture decisions
   - Core module directories

4. **Produce structured summary:**

   ```
   ## {Repo Name}

   **What it is:** {one sentence}

   **Tech Stack:** {list}

   **Architecture:**
   - {module} — {responsibility}
   - {module} — {responsibility}

   **Current State:** {active/archived} · {stars} stars · last commit {date}

   **Notable Design Decisions:**
   - {decision and why it matters}
   ```

5. **Ask user:** "要存到 wiki 嗎？"
   - Yes → Ask: "跟你哪個 project 有關嗎？" then create `wiki/{repo-name}.md` (category: repo) with `## Why Bookmarked` and `## Related` sections. Update `wiki/index.md`.
   - No → End.

## Notes
- Always use `gh` CLI for GitHub access — do not use raw API calls
- For very large repos, focus on README + top-level structure + 2-3 core files. Don't try to read everything.
- If repo is private and `gh` auth fails, tell the user instead of guessing.
