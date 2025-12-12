Update ~/.claude/settings.json to configure the statusLine setting as follows:

  ```json
  "statusLine": {
    "type": "command",
    "command": "~/.claude/plugins/marketplaces/chleosl-plugins/plugins/statusline-chleosl/statusline.sh",
    "padding": 0
  }

If statusLine doesn't exist, add it. If it exists, replace it with the above configuration.
