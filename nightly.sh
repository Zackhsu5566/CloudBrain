#!/usr/bin/env bash
set -euo pipefail

# Read timezone from HEARTBEAT.md, fallback to UTC
WORKSPACE="${HOME}/.openclaw/workspace"
CONFIGURED_TZ=$(grep -oP '^TIMEZONE=\K\S+' "$WORKSPACE/HEARTBEAT.md" 2>/dev/null || echo "UTC")
export TZ="$CONFIGURED_TZ"

LOCK_FILE="/tmp/cloud-brain-nightly.lock"
LOG_DIR="$HOME/.openclaw/logs"
LOG_FILE="$LOG_DIR/nightly.log"
WORKSPACE="$HOME/.openclaw/workspace"

mkdir -p "$LOG_DIR"

exec 200>"$LOCK_FILE"
flock -n 200 || { echo "$(date): nightly.sh already running, exiting" >> "$LOG_FILE"; exit 0; }

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"; }

log "=== Nightly run started ==="

# Step 0: Scaffolding (ensure required dirs/files exist)
log "Step 0: Scaffolding..."
mkdir -p "$WORKSPACE/skills"
[ -f "$WORKSPACE/skills/INDEX.md" ] || echo "# Skills Index" > "$WORKSPACE/skills/INDEX.md"
[ -f "$WORKSPACE/USER-INSIGHTS.md" ] || cat > "$WORKSPACE/USER-INSIGHTS.md" <<'SCAFFOLD_EOF'
# User Insights

> Last updated: never (awaiting first nightly run)
> Sources analyzed: daily/, habits/, journal/

## Behavioral Patterns

## Goal Drift

## Communication Preferences (observed)

## Dormant Patterns
SCAFFOLD_EOF
mkdir -p "$WORKSPACE/wiki"
[ -f "$WORKSPACE/wiki/index.md" ] || cat > "$WORKSPACE/wiki/index.md" <<'SCAFFOLD_EOF'
# Wiki Index

> Last updated: never (awaiting first nightly run)
> Total entities: 0
SCAFFOLD_EOF
[ -f "$WORKSPACE/wiki/log.md" ] || cat > "$WORKSPACE/wiki/log.md" <<'SCAFFOLD_EOF'
# Wiki Log

> Chronological record of wiki maintenance operations.
> Appended by nightly.sh Steps 1a and 1b.
SCAFFOLD_EOF
[ -f "$WORKSPACE/cache.md" ] || cat > "$WORKSPACE/cache.md" <<'SCAFFOLD_EOF'
# Hot Cache

> Auto-maintained. Entries expire after 72h unless pinned.
> Last updated: never (awaiting first session-end)

## Active Threads

## Pending Questions

## Recent Decisions
SCAFFOLD_EOF
log "Step 0: Scaffolding done"

# Step 1a: Wiki Maintenance — scan & link
log "Step 1a: Wiki scan & link starting..."
SINCE=$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
PROMPT_FILE=$(mktemp)
cat > "$PROMPT_FILE" <<PROMPT_EOF
You are performing nightly Wiki Maintenance (Phase 1: Scan & Link). Today's date is $(date '+%Y-%m-%d').

1. SCAN: Find all .md files in the workspace modified since $SINCE (exclude wiki/ directory, INDEX.md and index.md files, and immutable directories journal/ and daily/). For each file, identify concepts that should have [[wiki-links]] but don't. Add the links inline.

2. ENTITY CHECK: For concepts appearing in 2+ different files that don't have an entity page yet, evaluate if they meet the entity creation threshold defined in AGENTS.md Wiki-Links section (must pass 2+ file hard gate AND not be generic terms; must have concrete insight worth recording). If yes, create wiki/{kebab-case}.md with category frontmatter, summary, Related links, and Sources.

3. CONTRADICTION CHECK: For each entity page updated in steps 1-2 (new source added or existing source claim changed): if the entity has only 1 source (just created), skip — there is nothing to compare. Otherwise, compare the new claim against all existing claims in that entity's ## Sources. If claims conflict about the same fact (e.g., one source says "needs < 1 GPU" and another says "requires multi-GPU"), append to the entity's ## Contradictions section using the format defined in AGENTS.md (use source file mtime as the date). Do NOT flag cross-entity differences as contradictions.

4. LOG: After completing steps 1-3, append an entry to wiki/log.md in this format:

## YYYY-MM-DD — Ingest (Step 1a)
- Scanned: N files modified since yesterday
- Wiki-links added: N (list filenames)
- Entities created: N — list each as wiki/{name}.md [{category}]
- Entities updated: N — list each with what changed (new source, updated summary)
- Contradictions flagged: N (list entity names)

If no changes were made, still append an entry with all counts as 0.

Work silently. Write results to the filesystem. Do not output conversation.
PROMPT_EOF
openclaw agent --agent main --message "$(cat "$PROMPT_FILE")" >> "$LOG_FILE" 2>&1 || true
rm -f "$PROMPT_FILE"
sleep 2
log "Step 1a: Wiki scan & link completed"

# Step 1b: Wiki Maintenance — cross-reference & index rebuild
log "Step 1b: Wiki cross-reference & index starting..."
PROMPT_FILE=$(mktemp)
cat > "$PROMPT_FILE" <<PROMPT_EOF
You are performing nightly Wiki Maintenance (Phase 2: Cross-Reference & Index). Today's date is $(date '+%Y-%m-%d').

Note: when scanning wiki/*.md for entity pages, skip index.md and any _*.md sub-index files — these are not entity pages.

1. CROSS-REFERENCE (incremental): Find wiki/*.md entity pages created or modified since yesterday. For each such page:
   - If it references [[concept-B]] in Related or Sources, check that wiki/concept-B.md also lists [[concept-A]] in its Related section
   - Add missing bidirectional links
   - On Sundays only: perform a full scan of ALL wiki/*.md pages for consistency (if more than 50 pages, process in batches of 25)

2. ORPHAN DETECTION: Find wiki/*.md entity pages that are not referenced by any file outside wiki/. Add to Orphaned section in wiki/index.md with the date first detected. Auto-delete orphans that have been orphaned for 90+ days AND have minimal content (summary < 2 sentences, no Related links). Log any deletions. Additionally, scan all wiki/*.md entity pages for ## Contradictions entries tagged [resolved: YYYY-MM-DD — ...] where the resolution date is older than 30 days. Remove those resolved entries to keep pages clean.

3. REBUILD INDEX: Read all wiki/*.md frontmatter, group by category, write wiki/index.md with the category listing and orphaned section. If any category exceeds 30 entities, split it into a sub-index file (wiki/_category.md) and link from the main index.

4. LOG: After completing steps 1-3, append an entry to wiki/log.md in this format (always create its own heading — Step 1a and 1b run as independent agent calls with no shared context):

## YYYY-MM-DD — Lint (Step 1b)
- Bidirectional fixes: N (list pairs)
- Orphans detected: N (list names)
- Orphans deleted: N (list names, with reason)
- Resolved contradictions cleaned: N (list names, removed entries older than 30 days)
- Index rebuilt: N entities across M categories

If no changes were made, still append an entry with all counts as 0.

Work silently. Write results to the filesystem. Do not output conversation.
PROMPT_EOF
openclaw agent --agent main --message "$(cat "$PROMPT_FILE")" >> "$LOG_FILE" 2>&1 || true
rm -f "$PROMPT_FILE"
sleep 2
log "Step 1b: Wiki cross-reference & index completed"

# Step 2: Dreaming (scan recent files, extract to lancedb, update INDEX.md)
# WARNING: `openclaw run --prompt` is assumed syntax. Verify after Phase 1.
log "Step 2: Dreaming starting..."
# Use yesterday to catch files modified since previous evening (cron runs at 02:00)
SINCE=$(date -d 'yesterday' '+%Y-%m-%d' 2>/dev/null || date -v-1d '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
DREAM_DIRS=("journal" "inbox" "business" "notes")
for dir in "${DREAM_DIRS[@]}"; do
    TARGET="$WORKSPACE/$dir"
    if [ -d "$TARGET" ]; then
        CHANGED=$(find "$TARGET" -name "*.md" -newermt "$SINCE" -not -name "INDEX.md" 2>/dev/null || true)
        if [ -n "$CHANGED" ]; then
            log "  Dreaming: processing $dir/ ($(echo "$CHANGED" | wc -l) files)"
            while IFS= read -r f; do
                # Write file content to temp file to avoid shell injection from markdown content
                PROMPT_FILE=$(mktemp)
                cat > "$PROMPT_FILE" <<PROMPT_EOF
You are running in Dreaming mode. Read the following file and extract: preferences, decisions, commitments, goal changes, emotional patterns, key insights. Exclude plain facts, daily trivia, and content already stored. Store extracted items to memory. File content:

$(cat "$f")
PROMPT_EOF
                openclaw agent --agent main --message "$(cat "$PROMPT_FILE")" >> "$LOG_FILE" 2>&1 || true
                rm -f "$PROMPT_FILE"
                sleep 1  # Rate limit: avoid hitting Jina Embedding API limits
            done <<< "$CHANGED"
        fi
    fi
done
# Update INDEX.md files
for dir in "${DREAM_DIRS[@]}"; do
    IDX="$WORKSPACE/$dir/INDEX.md"
    if [ -d "$WORKSPACE/$dir" ]; then
        openclaw agent --agent main --message "Update the INDEX.md file at ${IDX}. Scan all .md files in ${WORKSPACE}/${dir}/. Generate a summary with: Stats (file count, last added), Recent Entries (last 5), Key Themes, Flags. Keep it under 50 lines." >> "$LOG_FILE" 2>&1 || true
    fi
done
log "Step 2: Dreaming completed"

# Step 2b: Behavioral fact extraction (scan 7-day window for user modeling)
log "Step 2b: Behavioral fact extraction starting..."
DATE=$(date '+%Y-%m-%d')
DATETIME=$(date '+%Y-%m-%d %H:%M')
SINCE_7D=$(date -d '7 days ago' '+%Y-%m-%d' 2>/dev/null || date -v-7d '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
BEHAVIOR_DIRS=("daily" "habits" "journal")
BEHAVIOR_TEMP=$(mktemp)
BEHAVIOR_FILE_LIST=()
for dir in "${BEHAVIOR_DIRS[@]}"; do
    TARGET="$WORKSPACE/$dir"
    if [ -d "$TARGET" ]; then
        while IFS= read -r f; do
            [ -n "$f" ] && BEHAVIOR_FILE_LIST+=("$f")
        done < <(find "$TARGET" -name "*.md" -newermt "$SINCE_7D" -not -name "INDEX.md" 2>/dev/null || true)
    fi
done
if [ ${#BEHAVIOR_FILE_LIST[@]} -gt 0 ]; then
    PROMPT_FILE=$(mktemp)
    cat > "$PROMPT_FILE" <<'PROMPT_EOF'
You are analyzing workspace files for behavioral patterns. Extract ONLY behavioral facts from the following files — things the user did or didn't do, habits tracked, goals mentioned or missed, mood indicators. Output as a bullet list of factual observations. Do NOT interpret or infer — just extract facts.

Files:
PROMPT_EOF
    for f in "${BEHAVIOR_FILE_LIST[@]}"; do
        echo "--- $(basename "$f") ---" >> "$PROMPT_FILE"
        cat "$f" >> "$PROMPT_FILE"
        echo "" >> "$PROMPT_FILE"
    done
    openclaw agent --agent main --message "$(cat "$PROMPT_FILE")" > "$BEHAVIOR_TEMP" 2>> "$LOG_FILE" || true
    rm -f "$PROMPT_FILE"
    log "  Step 2b: processed ${#BEHAVIOR_FILE_LIST[@]} files"
else
    log "  Step 2b: no recent files found, skipping"
fi
log "Step 2b: Behavioral fact extraction completed"

# Step 2c: Dialectic reasoning (update USER-INSIGHTS.md)
log "Step 2c: Dialectic reasoning starting..."
INSIGHTS_FILE="$WORKSPACE/USER-INSIGHTS.md"
if [ -s "$BEHAVIOR_TEMP" ]; then
    PROMPT_FILE=$(mktemp)
    INSIGHTS_TEMP=$(mktemp)
    # Build prompt in segments to avoid shell injection from markdown content
    cat > "$PROMPT_FILE" <<PROMPT_HEADER
Today's date is $DATE. You are updating a behavioral insights file about a user. You have two inputs:

1. CURRENT INSIGHTS (may be empty if first run):
PROMPT_HEADER
    # Append file contents as raw data (not shell-interpolated)
    cat "$INSIGHTS_FILE" >> "$PROMPT_FILE" 2>/dev/null || echo "(empty — first run)" >> "$PROMPT_FILE"
    cat >> "$PROMPT_FILE" <<PROMPT_MID

2. NEW BEHAVIORAL FACTS (from the past 7 days):
PROMPT_MID
    cat "$BEHAVIOR_TEMP" >> "$PROMPT_FILE"
    cat >> "$PROMPT_FILE" <<PROMPT_TAIL

For each existing insight:
- If new facts REINFORCE it → keep it, raise confidence (low→medium, medium→high)
- If new facts CONTRADICT it → lower confidence. If already low → move to ## Dormant Patterns with [dormant since: $DATE] (do NOT delete)
- If no new evidence either way → keep as-is
- To check dormancy: compare the "Last updated" date in the file header with today's date ($DATE). Insights with [confidence: low] unchanged for 14+ days → move to Dormant

For new patterns not yet captured:
- Add with confidence: low (if seen once) or medium (if seen 3+ times)

For dormant patterns:
- If a dormant pattern reappears in new facts → promote it back to the active section, preserve its occurrence count, set confidence based on recurrence strength

Output the complete updated USER-INSIGHTS.md file in this exact format:

# User Insights

> Last updated: $DATETIME (nightly dreaming)
> Sources analyzed: daily/, habits/, journal/

## Behavioral Patterns
{bullets with [confidence: X | based on: Y]}

## Goal Drift
{bullets with [confidence: X | based on: Y]}

## Communication Preferences (observed)
{bullets with [confidence: X | based on: Y]}

## Dormant Patterns
{bullets with [originally detected: X | dormant since: Y | occurrences: N]}
PROMPT_TAIL
    openclaw agent --agent main --message "$(cat "$PROMPT_FILE")" > "$INSIGHTS_TEMP" 2>> "$LOG_FILE" || true
    rm -f "$PROMPT_FILE"
    # Validate output before overwriting
    if [ -f "$INSIGHTS_TEMP" ] && \
       [ "$(grep -c '^## ' "$INSIGHTS_TEMP" 2>/dev/null)" -ge 4 ] && \
       [ "$(wc -l < "$INSIGHTS_TEMP" 2>/dev/null)" -gt 10 ]; then
        cp "$INSIGHTS_TEMP" "$INSIGHTS_FILE"
        log "  Step 2c: USER-INSIGHTS.md updated successfully"
    else
        log "  Step 2c: VALIDATION FAILED — output missing headers or too short, preserving old file"
    fi
    rm -f "$INSIGHTS_TEMP"
else
    log "  Step 2c: no behavioral data from Step 2b, skipping"
fi
rm -f "$BEHAVIOR_TEMP"
log "Step 2c: Dialectic reasoning completed"

# Step 2d: Memory review (bidirectional prune/merge, write to daily/)
log "Step 2d: Memory review starting..."
DAILY_FILE="$WORKSPACE/daily/$DATE.md"
PROMPT_FILE=$(mktemp)
cat > "$PROMPT_FILE" <<PROMPT_EOF
Today's date is $DATE. You are performing nightly memory maintenance. Use your memory_store tool to:

1. List memory entries. For each entry, check if it is:
   - OUTDATED: references events/goals that are no longer relevant
   - DUPLICATE: substantially overlaps with another entry
   - STALE: trivial or low-value information that doesn't aid future conversations

2. For outdated/duplicate/stale entries: delete them via memory_store.

3. Bidirectional sync with USER-INSIGHTS.md:
   - If a memory entry was deleted from LanceDB and USER-INSIGHTS.md references the same topic, move that insight to ## Dormant Patterns (do not leave ghost entries).
   - For insights with [confidence: low] not reinforced in 14+ days: move to ## Dormant Patterns (do not hard-delete — they may recur).
   - Write the updated USER-INSIGHTS.md back to disk.

4. Write a summary to daily/$DATE.md under a ## Memory Review section:
   - Merged: X items (list summaries)
   - Removed: Y items (list summaries)
   - Flagged for confirmation: Z items (list summaries — things you're unsure about deleting)

5. Session-end dedup: entries tagged with [source: session-end] were captured with fresher context during the 22:00 extraction. If a Dreaming-extracted entry substantially overlaps with a session-end entry, keep the session-end entry and prune the Dreaming duplicate.

6. Hot Cache cleanup: Read cache.md. Remove entries whose [expires: YYYY-MM-DD] date has passed (compare against today's date: $DATE). Leave [pinned] entries untouched. If a thread has been active for 3+ sessions (check Active Threads dates), suggest pinning it by adding a comment: <!-- consider pinning: active for N sessions -->. Update the "Last updated" timestamp.

If there are no actions to take, do NOT write a Memory Review section.
PROMPT_EOF
openclaw agent --agent main --message "$(cat "$PROMPT_FILE")" >> "$LOG_FILE" 2>&1 || true
rm -f "$PROMPT_FILE"
sleep 1  # Rate limit
log "Step 2d: Memory review completed"

# Step 3: Backup
log "Step 3: Backup starting..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -x "$SCRIPT_DIR/backup.sh" ]; then
    if "$SCRIPT_DIR/backup.sh" >> "$LOG_FILE" 2>&1; then
        log "Step 3: Backup completed"
    else
        log "Step 3: Backup FAILED (exit $?)"
    fi
else
    log "Step 3: backup.sh not found or not executable, skipping"
fi

log "=== Nightly run finished ==="
