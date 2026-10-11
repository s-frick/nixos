# agent-next  -- jump to the next agent waiting for input, else the next finished one.
# Jumping to a finished agent clears its mark.

current=$(tmux display -p '#{window_id}')
list=$(tmux list-windows -a -F '#{@agent_state}	#{session_id}	#{window_id}')

target=""
for want in "✋" "✓"; do
  target=$(awk -F'\t' -v s="$want" -v cur="$current" '$1 == s && $3 != cur { print $2 "\t" $3; exit }' <<<"$list")
  [[ -n $target ]] && break
done

if [[ -z $target ]]; then
  tmux display-message "no agent waiting"
  exit 0
fi

sid=${target%%	*}
wid=${target##*	}
tmux switch-client -t "$sid"
tmux select-window -t "$wid"
if [[ $(tmux show -wv -t "$wid" @agent_state 2>/dev/null) == "✓" ]]; then
  tmux set -w -u -t "$wid" @agent_state
fi
