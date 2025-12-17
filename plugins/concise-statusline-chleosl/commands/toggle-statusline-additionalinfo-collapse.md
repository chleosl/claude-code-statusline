Toggle the statusline extra info (weather, cwd, and git info on main).

Run this command to toggle:
```bash
current=$(cat ~/.claude/statusline-extra 2>/dev/null || echo "on")
if [ "$current" = "on" ]; then
    echo "off" > ~/.claude/statusline-extra
    echo "Statusline extra info: OFF"
else
    echo "on" > ~/.claude/statusline-extra
    echo "Statusline extra info: ON"
fi
```
