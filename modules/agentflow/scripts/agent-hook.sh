# agent-hook <event>  -- Claude Code hook, JSON on stdin.
# Marks the agent's tmux window (@agent_state) and sends system notifications.
# Must never fail or block the agent.

set +e
event=${1:-}
input=$(cat)

state=""
case $event in
  prompt | tool) state="●" ;;
  notify) state="✋" ;;
  stop) state="✓" ;;
  end) state="" ;;
  *) exit 0 ;;
esac

where="claude"
visible=0
if [[ -n ${TMUX_PANE:-} ]]; then
  if [[ -n $state ]]; then
    tmux set -w -t "$TMUX_PANE" @agent_state "$state"
  else
    tmux set -w -u -t "$TMUX_PANE" @agent_state
  fi
  where=$(tmux display -p -t "$TMUX_PANE" '#{session_name}:#{window_name}')
  # Visible = active window of a session some client is looking at
  [[ $(tmux display -p -t "$TMUX_PANE" '#{&&:#{window_active},#{session_attached}}') == 1 ]] && visible=1
fi

notify() {
  if command -v dms >/dev/null; then
    dms notify "$1" "$2" --app "Claude Code" >/dev/null 2>&1 && return
  fi
  if command -v notify-send >/dev/null; then
    notify-send -a "Claude Code" "$1" "$2" && return
  fi
  [[ -n ${TMUX_PANE:-} ]] && tmux display-message "$1: $2"
}

case $event in
  notify)
    msg=$(jq -r '.message // "wartet auf Eingabe"' <<<"$input" 2>/dev/null)
    notify "✋ $where" "${msg:-wartet auf Eingabe}"
    ;;
  stop)
    [[ $visible == 1 ]] || notify "✓ $where" "fertig"
    ;;
esac
exit 0
