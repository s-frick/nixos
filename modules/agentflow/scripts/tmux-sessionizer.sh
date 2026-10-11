# tmux-sessionizer [dir]
# Without argument: fzf over AGENTFLOW_PATHS (one level deep, *.wt excluded).
# Worktrees in <repo>.wt/<name> become session "<repo>/<name>".

if [[ $# -ge 1 ]]; then
  selected=$1
else
  # shellcheck disable=SC2086 # AGENTFLOW_PATHS is a space separated list
  selected=$(
    find $AGENTFLOW_PATHS -mindepth 1 -maxdepth 1 -type d -not -name '*.wt' 2>/dev/null |
      fzf --preview 'eza --tree --level=2 --color=always --git-ignore {}' \
        --preview-window=right:60%
  ) || exit 0
fi

[[ -z $selected ]] && exit 0
selected=$(realpath "$selected")

parent=$(basename "$(dirname "$selected")")
if [[ $parent == *.wt ]]; then
  name="${parent%.wt}/$(basename "$selected")"
else
  name=$(basename "$selected")
fi
name=${name//[.:]/_}

if ! tmux has-session -t "=$name" 2>/dev/null; then
  tmux-layout "$name" "$selected"
fi

if [[ -z ${TMUX:-} ]]; then
  tmux attach -t "=$name"
else
  tmux switch-client -t "=$name"
fi
