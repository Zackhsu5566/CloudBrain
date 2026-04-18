#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cloud Brain — Deployment Script
# Deploys OpenClaw + workspace + config on a fresh Ubuntu VPS
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE_DIR="$OPENCLAW_DIR/workspace"
ENV_FILE="$OPENCLAW_DIR/.env"
LOG_FILE="/tmp/cloud-brain-deploy.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

# ---- Step 1: System prep ----
system_prep() {
    echo "=== Step 1: System Preparation ==="
    apt update && apt upgrade -y
    apt install -y curl git jq python3 python3-pip python3-venv
    ok "System packages installed"

    # Set system timezone from HEARTBEAT.md config
    local tz
    tz=$(grep -oP '^TIMEZONE=\K\S+' "$SCRIPT_DIR/workspace/HEARTBEAT.md" 2>/dev/null || echo "UTC")
    timedatectl set-timezone "$tz"
    ok "System timezone set to $tz"
}

# ---- Step 2: Install OpenClaw ----
install_openclaw() {
    echo "=== Step 2: Install OpenClaw ==="
    curl -fsSL https://openclaw.ai/install.sh | bash

    # Verify version
    local version
    version=$(openclaw --version 2>/dev/null || echo "unknown")
    echo "OpenClaw version: $version"

    # Check AVX2 support
    if grep -q 'avx2' /proc/cpuinfo 2>/dev/null; then
        ok "AVX2 supported"
    else
        fail "AVX2 not found — some features may not work"
    fi

    ok "OpenClaw installed (version: $version)"
}

# ---- Step 3: Copy workspace ----
copy_workspace() {
    echo "=== Step 3: Copy Workspace ==="
    mkdir -p "$WORKSPACE_DIR"
    # Use -T to treat target as the directory itself (no nesting).
    # Previous form `cp -r src/ dst/` created dst/src/ when dst already existed.
    cp -rT "$SCRIPT_DIR/workspace" "$WORKSPACE_DIR"
    # OpenClaw's install wizard may have already created default BOOTSTRAP.md /
    # IDENTITY.md under WORKSPACE_DIR — those drive the "hatching" flow and
    # conflict with our pre-written SOUL.md persona, so remove them.
    rm -f "$WORKSPACE_DIR/BOOTSTRAP.md" "$WORKSPACE_DIR/IDENTITY.md"
    ok "Workspace copied to $WORKSPACE_DIR"
}

# ---- Step 4: Copy config ----
copy_config() {
    echo "=== Step 4: Copy Config ==="
    cp "$SCRIPT_DIR/config/openclaw.json" "$OPENCLAW_DIR/openclaw.json"
    ok "Config copied to $OPENCLAW_DIR/openclaw.json"
}

# ---- Step 5: Setup secrets ----
setup_secrets() {
    echo "=== Step 5: Configure API Keys ==="
    mkdir -p "$OPENCLAW_DIR"

    echo "Enter your API keys (they will be saved to $ENV_FILE):"
    echo ""

    read -rp "Telegram Bot Token: " tg_token
    read -rsp "MiniMax API Key: " mm_key; echo
    read -rsp "Anthropic API Key: " anth_key; echo

    cat > "$ENV_FILE" <<ENVEOF
TELEGRAM_BOT_TOKEN=$tg_token
MINIMAX_API_KEY=$mm_key
ANTHROPIC_API_KEY=$anth_key
# Phase 3 (uncomment when ready):
# GOOGLE_CALENDAR_OAUTH=
# BACKBLAZE_B2_KEY=
ENVEOF

    chmod 600 "$ENV_FILE"
    ok "Secrets saved to $ENV_FILE (chmod 600)"

    # Try envsubst on config if needed
    if command -v envsubst &> /dev/null; then
        if [ -n "$tg_token" ] && [ -n "$mm_key" ] && [ -n "$anth_key" ]; then
            export TELEGRAM_BOT_TOKEN="$tg_token"
            export MINIMAX_API_KEY="$mm_key"
            export ANTHROPIC_API_KEY="$anth_key"
            envsubst < "$OPENCLAW_DIR/openclaw.json" > "$OPENCLAW_DIR/openclaw.json.tmp"
            mv "$OPENCLAW_DIR/openclaw.json.tmp" "$OPENCLAW_DIR/openclaw.json"
            chmod 600 "$OPENCLAW_DIR/openclaw.json"
            ok "Secrets injected into openclaw.json"
        else
            fail "One or more API keys are empty — skipping envsubst"
        fi
    fi
}

# ---- Step 6: Install plugins ----
install_plugins() {
    echo "=== Step 6: Install Plugins ==="
    openclaw plugins install memory-lancedb-pro || { fail "memory-lancedb-pro install failed"; exit 1; }
    openclaw plugins install lossless-claw-enhanced || { fail "lossless-claw-enhanced install failed"; exit 1; }
    ok "Plugins installed"
}

# ---- Step 6b: Tune memory quality config ----
tune_memory_config() {
    echo "=== Step 6b: Tune Memory Quality Config ==="
    local cfg="$OPENCLAW_DIR/openclaw.json"

    # Applied AFTER plugin setup scripts run, so these override any defaults.
    # Disables noisy auto-capture behaviours and enables quality gates.
    #
    # NOTE: This creates plugins.entries alongside plugins.allow in the config.
    # OpenClaw is expected to treat "allow" as the plugin whitelist and "entries"
    # as per-plugin config overrides. If a future OpenClaw version changes this
    # schema, this section may need updating.
    #
    # lossless-claw-enhanced is left with default settings (no entries here).
    # To customize compression behavior, add a similar block:
    #   .plugins.entries["lossless-claw-enhanced"].config.KEY = VALUE
    jq '
      .hooks = {"internal": {"entries": {"session-memory": {"enabled": false}}}}
      | .plugins.entries["memory-lancedb-pro"].config.captureAssistant = false
      | .plugins.entries["memory-lancedb-pro"].config.sessionStrategy = "none"
      | .plugins.entries["memory-lancedb-pro"].config.admissionControl = {"enabled": true, "preset": "conservative"}
      | .plugins.entries["memory-lancedb-pro"].config.workspaceBoundary = {"userMdExclusive": {"enabled": true}}
      | .plugins.entries["memory-lancedb-pro"].config.memoryCompaction = {"enabled": true}
    ' "$cfg" > /tmp/oc.json && mv /tmp/oc.json "$cfg"

    chmod 600 "$cfg"
    ok "Memory quality gates applied (admissionControl, workspaceBoundary, no session-memory writes)"
}

# ---- Step 7: Setup cron jobs (Phase 3) ----
setup_cron() {
    echo "=== Step 8: Setup Cron Jobs (Phase 3) ==="
    local cron_entry="0 2 * * * $SCRIPT_DIR/nightly.sh >> $OPENCLAW_DIR/logs/nightly-cron.log 2>&1"
    mkdir -p "$OPENCLAW_DIR/logs"
    (crontab -l 2>/dev/null | grep -v "nightly.sh"; echo "$cron_entry") | crontab -
    ok "Cron job added: nightly.sh at 02:00 daily"
}

# ---- Step 9: Security hardening ----
security_hardening() {
    echo "=== Step 9: Security Hardening ==="

    # UFW firewall
    ufw allow OpenSSH
    ufw --force enable
    ok "UFW enabled (SSH only)"

    # Disable SSH password login (replace all matching lines, commented or not)
    sed -i '/^#*\s*PasswordAuthentication/c\PasswordAuthentication no' /etc/ssh/sshd_config
    systemctl restart sshd
    ok "SSH password login disabled"

    # Unattended upgrades
    apt install -y unattended-upgrades
    dpkg-reconfigure -plow unattended-upgrades
    ok "Unattended upgrades enabled"
}

# ---- Step 10: Health check ----
health_check() {
    echo "=== Step 10: Health Check ==="
    local pass=0
    local total=3

    # Check OpenClaw
    if command -v openclaw &> /dev/null; then
        ok "OpenClaw binary found"
        ((pass++))
    else
        fail "OpenClaw binary not found"
    fi

    # Check workspace
    if [ -d "$WORKSPACE_DIR" ] && [ -f "$WORKSPACE_DIR/SOUL.md" ]; then
        ok "Workspace exists with SOUL.md"
        ((pass++))
    else
        fail "Workspace missing or incomplete"
    fi

    # Check env file
    if [ -f "$ENV_FILE" ]; then
        ok "Secrets file exists"
        ((pass++))
    else
        fail "Secrets file missing"
    fi

    echo ""
    echo "Health check: $pass/$total passed"

    if [ "$pass" -eq "$total" ]; then
        ok "Deployment complete! Start OpenClaw and test with Telegram."
    else
        fail "Some checks failed. Review the output above."
    fi
}

# ---- Main ----
main() {
    echo "========================================"
    echo "  Cloud Brain — Deployment"
    echo "========================================"
    echo ""

    # Parse flags
    local skip_firewall=false
    local skip_cron=true       # Phase 3 default skip
    local phase3=false

    for arg in "$@"; do
        case $arg in
            --skip-firewall) skip_firewall=true ;;
            --skip-cron)     skip_cron=true ;;
            --phase3)        phase3=true; skip_cron=false ;;
            --help)
                echo "Usage: ./deploy.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --phase3          Enable Phase 3 steps (cron)"
                echo "  --skip-firewall   Skip UFW and SSH hardening"
                echo "  --skip-cron       Skip cron job setup"
                echo "  --help            Show this help"
                exit 0
                ;;
        esac
    done

    system_prep
    install_openclaw
    copy_workspace
    copy_config
    setup_secrets
    install_plugins
    tune_memory_config

    if [ "$skip_cron" = false ]; then
        setup_cron
    else
        skip "Cron jobs (use --phase3 to enable)"
    fi

    if [ "$skip_firewall" = false ]; then
        security_hardening
    else
        skip "Security hardening (--skip-firewall)"
    fi

    health_check
}

# Source guard: allows restore.sh to source this file for function reuse
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
