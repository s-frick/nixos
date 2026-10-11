# agent-pick  -- fzf over all windows that run an agent, preview = pane content.

sel=$(
  tmux list-windows -a -F '#{?@agent_state,#{@agent_state},·}	#{session_name}:#{window_index}	#{window_name}	#{window_id}' |
    awk -F'\t' '$1 != "·"' |
    fzf --delimiter='\t' --with-nth=1,2,3 --prompt='agent > ' \
      --preview 'tmux capture-pane -ep -t {4} | tail -n 40' \
      --preview-window=right:65%
) || exit 0

wid=$(cut -f4 <<<"$sel")
tmux switch-client -t "$(tmux display -p -t "$wid" '#{session_id}')"
tmux select-window -t "$wid"
