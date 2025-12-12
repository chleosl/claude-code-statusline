#!/bin/bash
#
# Claude Code Custom Statusline
#
# A customizable statusline script for Claude Code CLI.
# Displays session stats, context usage, git info, weather, and time.
#
# Output format (4 lines):
#   Line 1: +added/-removed (session) +added/-removed (git) | usage% [progress] (tokens) | time
#   Line 2: branch last_commit_hash last_commit_message
#   Line 3: location: temp condition icon
#   Line 4: current_working_directory
#
# Dependencies: jq, curl, git, awk
#
# Configuration:
#   ~/.claude/statusline-blink  - Set to "on" to enable blinking progress indicator
#

# Read stdin JSON data from Claude Code
input=$(cat)

# === Color Codes ===
GREEN="\033[32m"
RED="\033[31m"
MAGENTA="\033[35m"
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

# === Session Statistics ===
# Lines added/removed during this Claude Code session
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# === Context Window Usage ===
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

total_tokens=$((total_input + total_output))
if [ "$context_size" -gt 0 ]; then
    usage_percent=$(awk "BEGIN {printf \"%.0f\", ($total_tokens / $context_size) * 100}")
else
    usage_percent="0"
fi

# === Progress Bar ===
# 10-segment bar with gradient coloring based on usage
bar_length=10
filled=$((usage_percent / 10))
remainder=$((usage_percent % 10))

# Optional blink effect for current position indicator
blink_enabled="off"
[ -f ~/.claude/statusline-blink ] && blink_enabled=$(cat ~/.claude/statusline-blink)

# Gradient colors for partial segment (cycles 0-4, 5-9: gray → red)
PARTIAL_COLORS=(
    "\033[38;5;250m"    # 0: light gray
    "\033[38;5;181m"    # 1: light pink
    "\033[38;5;217m"    # 2: light red
    "\033[38;5;131m"    # 3: dark red
    "\033[38;5;88m"     # 4: deep red
    "\033[38;5;250m"    # 5: light gray
    "\033[38;5;181m"    # 6: light pink
    "\033[38;5;217m"    # 7: light red
    "\033[38;5;131m"    # 8: dark red
    "\033[38;5;88m"     # 9: deep red
)

# Gradient colors for token count display (0-100%: gray → red)
TOKEN_COLORS=(
    "\033[38;5;250m"    # 0-9%
    "\033[38;5;248m"    # 10-19%
    "\033[38;5;245m"    # 20-29%
    "\033[38;5;243m"    # 30-39%
    "\033[38;5;240m"    # 40-49%
    "\033[38;5;181m"    # 50-59%
    "\033[38;5;174m"    # 60-69%
    "\033[38;5;131m"    # 70-79%
    "\033[38;5;124m"    # 80-89%
    "\033[38;5;88m"     # 90-100%
)

# Build progress bar string
progress_bar=""

# Filled segments
if [ "$filled" -gt 0 ]; then
    progress_bar="${DIM}$(printf '%0.s▮' $(seq 1 $filled))${RESET}"
fi

# Current position indicator (0-4: _, 5-9: ▯)
if [ "$filled" -lt 10 ]; then
    PARTIAL_COLOR="${PARTIAL_COLORS[$remainder]}"
    if [ "$remainder" -le 4 ]; then
        partial="_"
    else
        partial="▯"
    fi
    if [ "$blink_enabled" = "on" ]; then
        progress_bar="${progress_bar}${PARTIAL_COLOR}\033[5m${partial}\033[0m"
    else
        progress_bar="${progress_bar}${PARTIAL_COLOR}${partial}${RESET}"
    fi
fi

# Empty segments
total_filled=$((filled + (filled < 10 ? 1 : 0)))
empty=$((bar_length - total_filled))
[ "$empty" -gt 0 ] && progress_bar="${progress_bar}${DIM}$(printf '%0.s_' $(seq 1 $empty))${RESET}"

# === Git Information ===
cwd=$(echo "$input" | jq -r '.workspace.current_dir // "."')

git_branch_raw=$(cd "$cwd" 2>/dev/null && git --no-optional-locks branch --show-current 2>/dev/null || echo "-")
git_last_commit=$(cd "$cwd" 2>/dev/null && git --no-optional-locks log -1 --format='%h %s' 2>/dev/null | head -c 60 || echo "-")
git_info_line="${MAGENTA}${git_branch_raw}${RESET} ${DIM}${git_last_commit}${RESET}"

# Git diff stats (unstaged + staged)
git_stats=$(cd "$cwd" 2>/dev/null && git --no-optional-locks diff --numstat 2>/dev/null && git --no-optional-locks diff --cached --numstat 2>/dev/null)
if [ -n "$git_stats" ]; then
    git_added=$(echo "$git_stats" | awk '{sum+=$1} END {print sum+0}')
    git_removed=$(echo "$git_stats" | awk '{sum+=$2} END {print sum+0}')
else
    git_added=0
    git_removed=0
fi

# === Weather ===
# Fetches current weather from wttr.in
weather_raw=$(curl -s "wttr.in/?format=%l|%c|%t|%C" 2>/dev/null || echo "N/A|N/A|N/A|N/A")

if [ "$weather_raw" != "N/A|N/A|N/A|N/A" ]; then
    IFS='|' read -r location icon temp condition <<< "$weather_raw"
    temp_num=$(echo "$temp" | grep -oP '[-+]?\d+' | head -1)

    # Temperature-based coloring
    if [ -n "$temp_num" ]; then
        if [ "$temp_num" -le -10 ]; then
            TEMP_COLOR="\033[38;5;21m"   # dark blue (very cold)
        elif [ "$temp_num" -le 0 ]; then
            TEMP_COLOR="\033[38;5;51m"   # cyan (cold)
        elif [ "$temp_num" -le 10 ]; then
            TEMP_COLOR="\033[38;5;51m"   # cyan (cool)
        elif [ "$temp_num" -le 20 ]; then
            TEMP_COLOR="\033[32m"         # green (comfortable)
        elif [ "$temp_num" -le 30 ]; then
            TEMP_COLOR="\033[33m"         # yellow (warm)
        else
            TEMP_COLOR="\033[31m"         # red (hot)
        fi
    else
        TEMP_COLOR="${RESET}"
    fi

    weather="${BOLD}${location}${RESET}: ${TEMP_COLOR}${temp}${RESET} ${DIM}${condition}${RESET} ${icon}"
else
    weather="N/A"
fi

# === Current Time ===
# Displays timezone abbreviation, offset, and datetime
tz_abbr=$(date +%Z)
tz_offset=$(date +%z)

# Simplify offset display (+0900 → +9)
if [ "${tz_offset:3:2}" = "00" ]; then
    tz_display="${tz_offset:0:1}$((10#${tz_offset:1:2}))"
else
    tz_display="$tz_offset"
fi
current_time=$(date "+${tz_abbr} ${tz_display} %Y-%m-%d %H:%M")

# === Format Token Display ===
# 10K+: no decimal, <10K: one decimal
if [ "$total_tokens" -ge 10000 ]; then
    tokens_display=$(awk "BEGIN {printf \"%.0fK\", $total_tokens / 1000}")
elif [ "$total_tokens" -ge 1000 ]; then
    tokens_display=$(awk "BEGIN {printf \"%.1fK\", $total_tokens / 1000}")
else
    tokens_display="$total_tokens"
fi

# Token color based on usage percentage
token_color_idx=$((usage_percent / 10))
[ "$token_color_idx" -gt 9 ] && token_color_idx=9
TOKEN_COLOR="${TOKEN_COLORS[$token_color_idx]}"

# === Output ===
printf "${GREEN}+%d${RESET}${DIM}/${RESET}${RED}-%d${RESET} ${GREEN}+%d${RESET}${DIM}/${RESET}${RED}-%d${RESET} ${MAGENTA}|${RESET} ${DIM}%s%%${RESET} ${DIM}[${RESET}%b${DIM}]${RESET} ${DIM}(${RESET}${TOKEN_COLOR}%s${RESET}${DIM})${RESET} ${MAGENTA}|${RESET} ${DIM}%s${RESET}\n%b\n%b\n${DIM}%s${RESET}" \
    "$lines_added" \
    "$lines_removed" \
    "$git_added" \
    "$git_removed" \
    "$usage_percent" \
    "$progress_bar" \
    "$tokens_display" \
    "$current_time" \
    "$git_info_line" \
    "$weather" \
    "$cwd"
