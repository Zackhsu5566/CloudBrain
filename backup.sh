#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cloud Brain — Backup Script
# Backs up workspace + lancedb to GitHub private repo or B2
# ============================================================

OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace"
LANCEDB_DIR="$OPENCLAW_DIR/lancedb"
LOG_DIR="$OPENCLAW_DIR/logs"
LOG_FILE="$LOG_DIR/backup.log"
CONFIG_FILE="$OPENCLAW_DIR/backup-config.json"
STAGING_DIR="$OPENCLAW_DIR/backup-staging"

mkdir -p "$LOG_DIR"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') [backup] $1" >> "$LOG_FILE"; }

# ---- First-run setup ----
setup_backup() {
    echo "=== Backup Setup (first run) ==="
    echo "Choose backup destination:"
    echo "  1) GitHub private repository"
    echo "  2) Backblaze B2 (via rclone)"
    read -rp "Enter choice (1 or 2): " choice

    case $choice in
        1)
            read -rp "GitHub repo URL (e.g., git@github.com:user/cloud-brain-backup.git): " repo_url
            cat > "$CONFIG_FILE" <<EOF
{
    "method": "github",
    "repo_url": "$repo_url"
}
EOF
            # Initialize staging as git repo
            mkdir -p "$STAGING_DIR"
            cd "$STAGING_DIR" || { echo "Failed to cd to $STAGING_DIR"; exit 1; }
            git init
            git remote add origin "$repo_url" 2>/dev/null || git remote set-url origin "$repo_url"
            echo "GitHub backup configured."
            ;;
        2)
            read -rp "Rclone remote name (e.g., b2:cloud-brain-backup): " remote_name
            cat > "$CONFIG_FILE" <<EOF
{
    "method": "b2",
    "remote": "$remote_name"
}
EOF
            echo "B2 backup configured. Make sure rclone is set up: rclone config"
            ;;
        *)
            echo "Invalid choice. Run backup.sh again."
            exit 1
            ;;
    esac

    chmod 600 "$CONFIG_FILE"
}

# ---- Sync to staging ----
sync_to_staging() {
    mkdir -p "$STAGING_DIR"
    if ! rsync -a --delete --exclude='.git' "$WORKSPACE_DIR/" "$STAGING_DIR/workspace/"; then
        log "WARNING: rsync workspace failed"
        return 1
    fi
    if [ -d "$LANCEDB_DIR" ]; then
        if ! rsync -a --delete --exclude='.git' "$LANCEDB_DIR/" "$STAGING_DIR/lancedb/"; then
            log "WARNING: rsync lancedb failed"
            return 1
        fi
    fi
}

# ---- GitHub backup ----
backup_github() {
    local repo_url
    repo_url=$(jq -r '.repo_url' "$CONFIG_FILE")

    sync_to_staging || return 1
    cd "$STAGING_DIR" || { log "Failed to cd to $STAGING_DIR"; return 1; }

    git init -q 2>/dev/null || true
    git remote add origin "$repo_url" 2>/dev/null || true

    git add -A
    local date_stamp
    date_stamp=$(date '+%Y-%m-%d %H:%M')
    git commit -m "backup: $date_stamp" --allow-empty -q 2>/dev/null || true
    git push -u origin main -q 2>/dev/null || git push -u origin master -q 2>/dev/null || {
        log "GitHub push failed"
        return 1
    }

    log "GitHub backup completed ($date_stamp)"
}

# ---- B2 backup ----
backup_b2() {
    local remote
    remote=$(jq -r '.remote' "$CONFIG_FILE")

    sync_to_staging || return 1

    local date_stamp
    date_stamp=$(date '+%Y-%m-%d')
    rclone sync "$STAGING_DIR" "$remote/$date_stamp/" --quiet || {
        log "B2 sync failed"
        return 1
    }

    # Retention: keep last 7 days
    local cutoff
    cutoff=$(date -d '7 days ago' '+%Y-%m-%d' 2>/dev/null || date -v-7d '+%Y-%m-%d' 2>/dev/null)
    if [ -n "$cutoff" ]; then
        rclone lsf "$remote/" --dirs-only 2>/dev/null | while read -r dir; do
            dir_date="${dir%/}"
            if [[ "$dir_date" < "$cutoff" ]]; then
                rclone purge "$remote/$dir_date" --quiet 2>/dev/null || true
            fi
        done
    fi

    log "B2 backup completed ($date_stamp)"
}

# ---- Main ----
main() {
    # First-run setup
    if [ ! -f "$CONFIG_FILE" ]; then
        setup_backup
    fi

    local method
    method=$(jq -r '.method' "$CONFIG_FILE")

    case $method in
        github) backup_github || { log "Backup failed"; exit 1; } ;;
        b2)     backup_b2 || { log "Backup failed"; exit 1; } ;;
        *)      log "Unknown backup method: $method"; exit 1 ;;
    esac
}

main "$@"
