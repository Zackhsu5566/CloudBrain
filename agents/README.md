# Creating Your Own Agent

CloudBrain agents are defined by a **SOUL.md** file — a markdown document that describes the agent's identity, personality, communication style, and operational rules.

## Quick Start

```bash
# 1. Copy the example agent
cp -r agents/kila agents/my-agent

# 2. Edit the SOUL file
nano agents/my-agent/SOUL.md

# 3. Copy it to the workspace (single-agent setup)
cp agents/my-agent/SOUL.md workspace/SOUL.md
```

## SOUL.md Structure

Your SOUL.md should define:

| Section | Purpose |
|---------|---------|
| **Identity** | Name, role, personality description |
| **Language Rules** | How the agent communicates and archives |
| **Modes** | Different interaction styles for different contexts |
| **Core Principles** | Guiding philosophy for the agent's behavior |
| **Responsibilities** | What the agent does (journaling, tracking, filing, etc.) |
| **Query Rules** | How the agent searches workspace content |
| **Boundaries** | What the agent does NOT do |

## Example Agents

### Kila (included)
A **life mentor + personal assistant** — warm but firm, uses Socratic questioning, tracks habits and goals.

### Ideas for Custom Agents

- **Stoic Coach** — Minimal words, maximum impact. References Marcus Aurelius. Never sugarcoats.
- **Creative Partner** — Brainstorm-first approach. Always asks "what if?" before narrowing down.
- **Accountability Bot** — Pure data, zero emotion. Reports completion rates and trends without commentary.
- **Research Assistant** — Academic tone, citation-heavy, always asks for sources.

## Tips

- **Start with Kila and modify.** It's easier to adjust an existing persona than write one from scratch.
- **Test your modes.** Make sure Mode A/B/C (or your own modes) feel distinct.
- **Language rules matter.** If you're bilingual, define which language is used for conversation vs. archiving.
- **Keep boundaries clear.** Define what the agent should NOT do to prevent scope creep.
- **The SOUL.md in `workspace/`** is what OpenClaw actually reads at runtime. The copy in `agents/` is your version-controlled source of truth.
