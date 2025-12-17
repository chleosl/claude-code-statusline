# Claude Code Statusline

Concise, Unobtrusive and low-profile custom statusline for Claude Code CLI shows session stats, context usage, git info, weather, and time.

## Features

- Session stats (lines added/removed)
- Git diff stats (unstaged + staged changes)
- Context window usage with gradient progress bar
- Token count with color coding
- Current git branch and last commit
- Weather info with temperature-based coloring
- Current time with timezone

## Output Format

```
Line 1: +added/-removed (session) +added/-removed (git) | usage% [progress] (tokens) | time
Line 2: branch last_commit_hash last_commit_message
Line 3: location: temp condition icon
Line 4: current_working_directory
```

## Installation

```bash
/plugin marketplace add chleosl/claude-code-statusline-chleosl
/plugin install concise-statusline-chleosl@claude-code-statusline-chleosl
/setup-chleosl-statusline
```

## Image

![Claude Statusline Overview](./assets/claude_statusline_overview.png)
![Claude Statusline Overview](./assets/claude_statusline_overview_bright.png)
<p align="center">
<img src="./assets/claude_statusline_overview_close.png" width="85%">
</p>
<br>

You can Hide the below three lines and show exclusively-only the top line, by

```bash
/toggle-statusline-additionalinfo-collapse
```

<p align="center">
<img src="./assets/claude_statusline_collapsed_overview.png" width="85%">
</p>
