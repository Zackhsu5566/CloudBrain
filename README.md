# CloudBrain

A self-hosted AI agent system built on [OpenClaw](https://openclaw.ai). Deploy your own personal AI assistant on a VPS, communicate via Telegram, and store everything as human-readable Markdown.

CloudBrain ships with **Kila** — a life mentor agent that handles daily journaling, habit tracking, idea filing, expense logging, project tracking, and weekly reviews. You can use Kila as-is or create your own agent persona.

## Features

- **Daily check-ins** — Morning planning + evening review with habit tracking
- **Idea capture** — Auto-classify messages into business, tech, content, or research
- **Expense tracking** — Log and query spending by category
- **Project tracking** — Goals, milestones, and notes per project
- **Knowledge graph** — Auto-maintained wiki with entity pages and cross-references
- **Procedural skills** — Save and reuse workflows (planning, business analysis, etc.)
- **Nightly automation** — Wiki maintenance, behavioral analysis, and backups
- **Two-tier memory** — Markdown files (persistent) + LanceDB vectors (semantic recall)
- **Customizable agents** — Define your own agent persona via SOUL.md

## Prerequisites

- **VPS:** Ubuntu 24.04 (1+ vCPU, 4GB+ RAM recommended)
- **Telegram:** Bot created via [@BotFather](https://t.me/BotFather), bot token ready
- **API Keys:** At least one LLM provider (e.g., MiniMax, Anthropic, OpenAI)
- **SSH:** Public key configured for key-only authentication

> **First time?** See [SETUP.md](SETUP.md) for a step-by-step guide on getting your Telegram bot, API keys, and VPS ready.

## Quick Start

```bash
# 1. SSH into your VPS
ssh root@YOUR_VPS_IP

# 2. Clone the repo
git clone https://github.com/YOUR_USER/CloudBrain.git
cd CloudBrain

# 3. Deploy
chmod +x deploy.sh
./deploy.sh

# 4. (Optional) Enable scheduled tasks
./deploy.sh --phase3
```

The deploy script will:
1. Install system packages + OpenClaw
2. Copy workspace and config to `~/.openclaw/`
3. Prompt for API keys (saved to `~/.openclaw/.env`, chmod 600)
4. Install plugins (LanceDB, lossless compression)
5. Setup firewall + SSH hardening
6. Run health check

## Customizing Your Agent

CloudBrain is designed to let you define your own agent. See [`agents/README.md`](agents/README.md) for a full guide.

**Quick version:**

```bash
# Copy the example agent
cp -r agents/kila agents/my-agent

# Edit the persona
nano agents/my-agent/SOUL.md

# Deploy it
cp agents/my-agent/SOUL.md workspace/SOUL.md
```

Your SOUL.md defines:
- **Identity** — Name, role, personality
- **Communication modes** — How the agent adapts to different situations
- **Responsibilities** — What it tracks and manages
- **Boundaries** — What it delegates to other tools

## Configuration

### Model Routing

Edit `config/openclaw.json` to configure your LLM providers:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "minimax/MiniMax-M2.7",
        "fallbacks": ["anthropic/claude-opus-4-6"]
      }
    }
  }
}
```

The default setup uses MiniMax-M2.7 (~$9/mo) for daily tasks and Claude Opus as a fallback for complex analysis. Adjust to your preferred providers.

### Plugins

| Plugin | Purpose | Docs |
|--------|---------|------|
| `memory-lancedb-pro` | Vector memory with semantic search | [github.com/openclaw-ai/plugin-memory-lancedb](https://github.com/openclaw-ai/plugin-memory-lancedb) |
| `lossless-claw-enhanced` | Context compression (CJK-aware) | [github.com/openclaw-ai/plugin-lossless-claw](https://github.com/openclaw-ai/plugin-lossless-claw) |

Plugin config is applied by `deploy.sh` step 6b. `lossless-claw-enhanced` uses defaults; `memory-lancedb-pro` is tuned for conservative admission control. See the plugin repos for available config options.

### Location & Timezone

Edit `workspace/HEARTBEAT.md` to set your city, timezone, news source, and optional air quality API.

### Expense Categories

Edit `workspace/finance/categories.md` to match your spending patterns.

## File Structure

```
CloudBrain/
├── deploy.sh              # Interactive VPS deployment
├── backup.sh              # Backup to GitHub private repo / B2
├── nightly.sh             # Nightly pipeline (Wiki → Dreaming → Backup)
├── restore.sh             # Disaster recovery
├── config/
│   └── openclaw.json      # OpenClaw config (model routing, memory, plugins)
├── agents/                # Agent persona definitions
│   ├── README.md          # Guide to creating custom agents
│   └── kila/SOUL.md       # Example agent (life mentor)
└── workspace/             # Agent workspace (copied to ~/.openclaw/workspace/)
    ├── SOUL.md            # Active agent persona (runtime copy)
    ├── AGENTS.md          # Operational rules (archiving, wiki, skills, etc.)
    ├── USER.md            # User profile (filled by the agent over time)
    ├── HEARTBEAT.md       # Scheduled check-in schedule
    ├── TOOLS.md           # Environment and tool descriptions
    ├── journal/           # Daily journal entries (append-only)
    ├── daily/             # Daily summaries (append-only)
    ├── inbox/             # Incoming unclassified messages
    ├── notes/             # Research and reference notes
    ├── ideas/             # Ideas by category (tech, content, research)
    ├── habits/            # Exercise, food, sleep tracking
    ├── business/          # Business ideas, market analysis, pitch prep
    ├── projects/          # Project-specific goals and notes
    ├── finance/           # Expense tracking
    ├── planning/          # Planning logs (daily, weekly, monthly, quarterly)
    ├── skills/            # Procedural skills (reusable workflows)
    ├── wiki/              # Knowledge graph (auto-maintained entity pages)
    └── archive/           # Archived old entries
```

## Scripts

| Script | Purpose | When |
|--------|---------|------|
| `deploy.sh` | Full VPS setup from scratch | First deploy |
| `backup.sh` | Backup workspace + LanceDB to GitHub/B2 | Called by nightly.sh or manually |
| `nightly.sh` | Wiki Maintenance → Dreaming → Backup (flock-guarded) | Cron at 02:00 daily |
| `restore.sh` | Disaster recovery on fresh VPS | After VPS failure |

### deploy.sh flags

```
--phase3          Enable Phase 3 (cron scheduling)
--skip-firewall   Skip UFW and SSH hardening
--help            Show help
```

## Deployment Phases

| Phase | Features |
|-------|----------|
| **1** | Basic agent + idea capture + memory |
| **2** | LanceDB vector memory + context compression |
| **3** | Scheduled tasks (heartbeat, cron), Google Calendar |
| **4** | GitHub MCP (read-only repo access for analysis skills) |

## Cost Estimate

| Item | Monthly Cost |
|------|-------------|
| VPS (1 vCPU, 4GB RAM) | ~$5-10 |
| LLM API (primary, daily use) | ~$9 |
| LLM API (fallback, on-demand) | ~$5-15 |
| Embedding API | $0 (free tier) |
| Backup storage | $0 (GitHub private / B2 free tier) |
| **Total** | **~$19-34 USD** |

## Disaster Recovery

```bash
# On a fresh VPS:
git clone https://github.com/YOUR_USER/CloudBrain.git
cd CloudBrain
chmod +x restore.sh
./restore.sh
```

Target recovery time: ~30 minutes from bare VPS to fully operational.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| OpenClaw version too old | Requires >= 2026.3.22. Run `openclaw --version` to check |
| AVX2 not supported | Check `grep avx2 /proc/cpuinfo`. If missing, upgrade VPS plan |
| High memory usage | Monitor with `free -h`. Consider adding swap |
| Cron not firing | Check `crontab -l`. Logs at `~/.openclaw/logs/nightly.log` |
| Backup fails | Run `backup.sh` manually. Check SSH key (GitHub) or `rclone config` (B2) |
| High LLM costs | Check AGENTS.md — fallback model should only trigger on explicit rules |

## License

MIT
