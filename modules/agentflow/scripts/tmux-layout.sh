# tmux-layout <session> <dir>
# Creates a detached session in <dir>. Windows come from <dir>/.tmux-layout,
# the main worktree's .tmux-layout, or $AGENTFLOW_DEFAULT_LAYOUT.
# Layout format: one window per line, "<name> [command...]", '#' comments.
# If TK_PROMPT is set, it is appended to the command of the "agent" window.

session=$1
dir=$2

layout_file=""
main_dir=""
if common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  main_dir=$(dirname "$common")
fi
for f in "$dir/.tmux-layout" "${main_dir:+$main_dir/.tmux-layout}"; do
  if [[ -n $f && -f $f ]]; then
    layout_file=$f
    break
  fi
done

if [[ -n $layout_file ]]; then
  layout=$(cat "$layout_file")
else
  layout=$AGENTFLOW_DEFAULT_LAYOUT
fi

# Stable per-session slot (0-99), e.g. for port offsets in .envrc
slot=$(( $(printf '%s' "$session" | cksum | cut -d' ' -f1) % 100 ))

first=""
while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  [[ -z $line || $line == \#* ]] && continue
  wname=${line%%[[:space:]]*}
  cmd=${line#"$wname"}
  cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  if [[ $wname == agent && -n ${TK_PROMPT:-} && -n $cmd ]]; then
    cmd="$cmd $(printf '%q' "$TK_PROMPT")"
  fi

  if [[ -z $first ]]; then
    wid=$(tmux new-session -d -s "$session" -n "$wname" -c "$dir" -e "TK_SLOT=$slot" -P -F '#{window_id}')
    first=$wid
  else
    wid=$(tmux new-window -d -t "=$session:" -n "$wname" -c "$dir" -e "TK_SLOT=$slot" -P -F '#{window_id}')
  fi
  if [[ -n $cmd ]]; then
    tmux send-keys -t "$wid" "$cmd" Enter
  fi
done <<<"$layout"

if [[ -z $first ]]; then
  tmux new-session -d -s "$session" -c "$dir" -e "TK_SLOT=$slot"
else
  tmux select-window -t "$first"
fi
