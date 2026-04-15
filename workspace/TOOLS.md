# Tools & Environment

> This file describes the available tools and environment. It does NOT contain secrets.
> Actual API keys are stored in ~/.openclaw/.env (never committed to git).

## Available Tools
- **Web Search** — market research, fact checking, current information
- **File System** — read/write workspace markdown files
- **Browser** — web browsing for research tasks

### Phase 3 (active)
- **Google Calendar** — schedule management, event creation, reminders
- **Wiki-Links** — agent-maintained `[[wiki-link]]` knowledge graph from workspace content

### Phase 4
- **GitHub MCP** — read-only repo access for repo-deep-dive and business-feasibility skills

## VPS Environment
- OS: Ubuntu 24.04 LTS
- Region: _(configure based on your VPS provider)_
- Specs: 1 vCPU / 4GB RAM recommended minimum
- Security: UFW active (SSH only), SSH password login disabled, loopback binding

## Model Configuration
- **Daily (MiniMax-2.7):** conversations, archiving, summaries, food photo recognition
- **Complex tasks (Claude Opus):** weekly reports, deep analysis, pitch prep — triggered only by explicit rules in AGENTS.md