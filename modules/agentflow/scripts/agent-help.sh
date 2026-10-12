# agent-help                     print agentflow cheat sheet
# agent-help --popup <client>    show it top right on <client>, closes on key or after 10s

if [[ ${1:-} == --popup ]]; then
  sleep 0.3 # wait for the sessionizer popup to close, one popup per client
  exec tmux display-popup -c "$2" -x R -y 0 -w 50 -h 17 -T ' agentflow ' -E "$0 --wait"
fi

cat <<'EOF2'
 prefix f   project picker (sessionizer)
 prefix W   new ticket worktree
 prefix w   pick worktree of this repo
 prefix D   tk done (remove worktree)
 prefix a   jump to next waiting agent
 prefix A   pick agent
 prefix H   this help

 tk new <name> [base] [-p prompt]
 tk ls | tk done [-f]
 .tmux-layout: "<window> [cmd]"
 $TK_SLOT: per-session 0-99
EOF2

if [[ ${1:-} == --wait ]]; then
  read -rsn1 -t 10 || true
fi
