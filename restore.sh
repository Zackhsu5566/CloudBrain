#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cloud Brain — Disaster Recovery Script
# Restores system from backup on a fresh VPS
# Target: 30 minutes from bare VPS to fully operational
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"

# Source deploy.sh functions (source guard prevents main() from running)
source "$SCRIPT_DIR/deploy.sh"

echo "========================================"
echo "  Cloud Brain — Disaster Recovery"
echo "========================================"
echo ""

# Step 1-2: System prep + Install OpenClaw (reuse from deploy.sh)
system_prep
install_openclaw

# Step 3: Restore from backup
echo "=== Step 3: Restore from Backup ==="
echo "Choose backup source:"
echo "  1) GitHub private repository"
echo "  2) Backblaze B2"
read -rp "Enter choice (1 or 2): " choice

case $choice in
    1)
        read -rp "GitHub repo URL: " repo_url
        mkdir -p "$OPENCLAW_DIR"
        git clone "$repo_url" "$OPENCLAW_DIR/backup-staging" || { fail "git clone failed"; exit 1; }

        if [ -d "$OPENCLAW_DIR/backup-staging/workspace" ]; then
            cp -r "$OPENCLAW_DIR/backup-staging/workspace/" "$OPENCLAW_DIR/workspace/"
            ok "Workspace restored"
        fi

        if [ -d "$OPENCLAW_DIR/backup-staging/lancedb" ]; then
            cp -r "$OPENCLAW_DIR/backup-staging/lancedb/" "$OPENCLAW_DIR/lancedb/"
            ok "LanceDB restored"
        fi
        ;;
    2)
        read -rp "Rclone remote (e.g., b2:cloud-brain-backup): " remote
        # List available snapshots
        echo "Available snapshots:"
        rclone lsf "$remote/" --dirs-only 2>/dev/null || echo "(none found)"
        read -rp "Snapshot date to restore (YYYY-MM-DD): " snapshot

        mkdir -p "$OPENCLAW_DIR"
        rclone copy "$remote/$snapshot/" "$OPENCLAW_DIR/backup-staging/" --quiet || { fail "rclone copy failed"; exit 1; }

        if [ -d "$OPENCLAW_DIR/backup-staging/workspace" ]; then
            cp -r "$OPENCLAW_DIR/backup-staging/workspace/" "$OPENCLAW_DIR/workspace/"
            ok "Workspace restored"
        fi

        if [ -d "$OPENCLAW_DIR/backup-staging/lancedb" ]; then
            cp -r "$OPENCLAW_DIR/backup-staging/lancedb/" "$OPENCLAW_DIR/lancedb/"
            ok "LanceDB restored"
        fi
        ;;
    *)
        fail "Invalid choice"
        exit 1
        ;;
esac

# Step 4: Copy config template (if not in backup)
if [ ! -f "$OPENCLAW_DIR/openclaw.json" ]; then
    copy_config
fi

# Step 5: Setup secrets (not in backup)
setup_secrets

# Step 6: Install plugins
install_plugins

# Step 7: Setup cron
read -rp "Setup nightly cron job? [y/N]: " setup_cr
if [[ "$setup_cr" =~ ^[Yy]$ ]]; then
    setup_cron
else
    skip "Cron jobs"
fi

# Step 9: Health check
health_check

echo ""
ok "Disaster recovery complete!"
