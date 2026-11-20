#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
# Subscription rate limits (absent for API users / before the first response)
SESSION_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
WEEK_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)

# Gruvbox dark palette (24-bit)
AQUA='\033[38;2;142;192;124m'; GREEN='\033[38;2;184;187;38m'; YELLOW='\033[38;2;250;189;47m'
RED='\033[38;2;251;73;52m'; DARK_YELLOW='\033[38;2;215;153;33m'; BLUE='\033[38;2;131;165;152m'
PURPLE='\033[38;2;211;134;155m'; GRAY='\033[38;2;146;131;116m'; RESET='\033[0m'
SEP="${GRAY} | ${RESET}"

# Colored 10-segment bar + percentage for $1 (0-100)
bar() {
  local pct=$1 color filled fill pad
  if [ "$pct" -ge 90 ]; then color="$RED"
  elif [ "$pct" -ge 70 ]; then color="$YELLOW"
  else color="$GREEN"; fi
  filled=$((pct / 10)); [ "$filled" -gt 10 ] && filled=10
  printf -v fill "%${filled}s"; printf -v pad "%$((10 - filled))s"
  printf '%s' "${color}${fill// /█}${pad// /░} ${pct}%${RESET}"
}

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

BRANCH=""
git --no-optional-locks rev-parse --git-dir > /dev/null 2>&1 && BRANCH="${SEP}🌿 ${PURPLE}$(git --no-optional-locks branch --show-current 2>/dev/null)${RESET}"

LIMITS=""
[ -n "$SESSION_PCT" ] && LIMITS="${SEP}⚡ $(bar "$SESSION_PCT")"
[ -n "$WEEK_PCT" ] && LIMITS="${LIMITS}${SEP}📅 ${WEEK_PCT}%"

COST_FMT=$(printf '$%.2f' "$COST")
echo -e "${AQUA}[$MODEL]${RESET} 📁 ${BLUE}${DIR##*/}${RESET}${BRANCH}${SEP}$(bar "$PCT")${SEP}${DARK_YELLOW}${COST_FMT}${RESET}${LIMITS}${SEP}⏱️ ${MINS}m ${SECS}s"
