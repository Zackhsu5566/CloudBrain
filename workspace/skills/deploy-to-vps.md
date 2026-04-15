---
name: Deploy to VPS
created: 2026-04-13
last_used: —
use_count: 0
---

## Trigger

When changes to CloudBrain repo files need to be deployed to the VPS. Typical after committing changes to nightly.sh, workspace/*.md, deploy.sh, backup.sh, or restore.sh.

## Prerequisites

- SSH access: `ssh root@YOUR_VPS_IP`
- Local repo cloned

## Steps

1. **Push to GitHub**
   ```bash
   git push
   ```

2. **Identify changed files and their VPS destinations**

   | Local path | VPS path | Notes |
   |---|---|---|
   | `nightly.sh` | `~/CloudBrain/nightly.sh` | Shell script — needs CRLF fix if uploading from Windows |
   | `backup.sh` | `~/CloudBrain/backup.sh` | Shell script — needs CRLF fix |
   | `restore.sh` | `~/CloudBrain/restore.sh` | Shell script — needs CRLF fix |
   | `deploy.sh` | `~/CloudBrain/deploy.sh` | Shell script — needs CRLF fix |
   | `workspace/*.md` | `~/.openclaw/workspace/*.md` | Actual runtime path used by the agent |
   | `config/openclaw.json` | `~/.openclaw/config.json` | Rarely changed; requires restart |

   > **Note:** Workspace files on VPS live at `~/.openclaw/workspace/`, not `~/CloudBrain/workspace/`. The latter is the repo template.

3. **SCP the changed files**

   Shell scripts:
   ```bash
   scp nightly.sh root@YOUR_VPS_IP:~/CloudBrain/nightly.sh
   ```

   Workspace markdown:
   ```bash
   scp workspace/AGENTS.md root@YOUR_VPS_IP:~/.openclaw/workspace/AGENTS.md
   ```

   Only upload files that changed — don't copy everything.

4. **Fix CRLF (shell scripts only, if uploading from Windows)**

   ```bash
   ssh root@YOUR_VPS_IP "sed -i 's/\r$//' ~/CloudBrain/nightly.sh"
   ```
   Markdown files don't need CRLF fixing.

5. **Verify**
   ```bash
   ssh root@YOUR_VPS_IP "head -3 ~/CloudBrain/nightly.sh"
   ```

## Notes

- Workspace .md changes take effect immediately (next heartbeat uses new version)
- nightly.sh changes take effect at next 02:00 cron run
- If you changed openclaw.json, restart the gateway: `systemctl restart openclaw`
- Don't run deploy.sh again — that's for initial full setup only
- Manual nightly trigger: `ssh root@YOUR_VPS_IP "bash ~/CloudBrain/nightly.sh"`
