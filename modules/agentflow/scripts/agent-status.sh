# agent-status  -- summary for the tmux status line, e.g. "✋2 ✓1 ●3"

tmux list-windows -a -F '#{@agent_state}' 2>/dev/null |
  awk '$0 != "" { n[$0]++ }
       END {
         split("✋ ✓ ●", order, " ")
         for (i = 1; i <= 3; i++) if (n[order[i]]) printf "%s%d ", order[i], n[order[i]]
       }'
