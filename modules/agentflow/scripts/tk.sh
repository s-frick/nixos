# tk - ticket worktrees as tmux sessions
#
#   tk new <name> [base] [-p prompt]   worktree <repo>.wt/<name>, branch feat/<name>
#   tk ls                              pick a worktree of this repo
#   tk done [-f]                       remove current worktree + session
#
# Untracked .env* files of the main worktree are copied, .envrc is allowed.
# Window layout: optional .tmux-layout, see tmux-layout.

usage() {
  cat <<'EOF'
tk new <name> [base] [-p prompt]   worktree <repo>.wt/<name>, branch feat/<name>
tk ls                              pick a worktree of this repo
tk done [-f]                       remove current worktree + session
EOF
  exit "${1:-0}"
}

die() {
  echo "tk: $*" >&2
  exit 1
}

main_worktree() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || die "not in a git repo"
  dirname "$common"
}

cmd_new() {
  local name="" base="" prompt=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      -p) prompt=$2; shift 2 ;;
      -h) usage ;;
      *) if [[ -z $name ]]; then name=$1; else base=$1; fi; shift ;;
    esac
  done
  [[ -n $name ]] || usage 1

  local main repo wt branch
  main=$(main_worktree)
  repo=$(basename "$main")
  wt="$(dirname "$main")/$repo.wt/$name"
  branch="${TK_BRANCH_PREFIX-feat/}$name"

  if [[ ! -d $wt ]]; then
    if git -C "$main" remote get-url origin >/dev/null 2>&1; then
      git -C "$main" fetch -q origin || echo "tk: fetch failed, using local refs" >&2
    fi
    if [[ -z $base ]]; then
      base=$(git -C "$main" symbolic-ref -q --short refs/remotes/origin/HEAD) || base=HEAD
    fi

    mkdir -p "$(dirname "$wt")"
    if git -C "$main" show-ref -q --verify "refs/heads/$branch"; then
      git -C "$main" worktree add "$wt" "$branch"
    else
      git -C "$main" worktree add -b "$branch" "$wt" "$base"
    fi

    # Untracked env files (.env, .envrc, ...) are not part of the checkout
    for f in "$main"/.env*; do
      [[ -f $f && ! -e $wt/${f##*/} ]] || continue
      git -C "$main" ls-files --error-unmatch "${f##*/}" >/dev/null 2>&1 || cp -a "$f" "$wt/"
    done

    if [[ -f $wt/.envrc ]] && command -v direnv >/dev/null; then
      direnv allow "$wt"
    fi
  fi

  TK_PROMPT=$prompt tmux-sessionizer "$wt"
}

cmd_ls() {
  local main sel
  main=$(main_worktree)
  sel=$(
    git -C "$main" worktree list --porcelain | sed -n 's/^worktree //p' |
      fzf --prompt='worktree > ' \
        --preview 'git -C {} log --oneline --decorate -10; echo; git -C {} status -s' \
        --preview-window=right:60%
  ) || exit 0
  tmux-sessionizer "$sel"
}

cmd_done() {
  local force=""
  [[ ${1:-} == -f ]] && force=--force

  local wt main branch parent session main_session
  wt=$(git rev-parse --show-toplevel 2>/dev/null) || die "not in a git repo"
  main=$(main_worktree)
  [[ $wt != "$main" ]] || die "in main worktree, nothing to do"

  if [[ -z $force && -n $(git -C "$wt" status --porcelain) ]]; then
    git -C "$wt" status -s
    die "worktree dirty, use 'tk done -f' to discard"
  fi

  branch=$(git -C "$wt" branch --show-current)
  parent=$(basename "$(dirname "$wt")")
  session="${parent%.wt}/$(basename "$wt")"
  session=${session//[.:]/_}
  main_session=$(basename "$main")
  main_session=${main_session//[.:]/_}

  cd "$main"
  git worktree remove $force "$wt"
  rmdir "$(dirname "$wt")" 2>/dev/null || true
  if [[ -n $branch ]] && ! git branch -d "$branch" 2>/dev/null; then
    echo "tk: kept branch $branch (not merged)"
  fi

  if [[ -n ${TMUX:-} ]] && tmux has-session -t "=$session" 2>/dev/null; then
    if [[ $(tmux display -p '#{session_name}') == "$session" ]]; then
      if tmux has-session -t "=$main_session" 2>/dev/null; then
        tmux switch-client -t "=$main_session"
      else
        tmux switch-client -l 2>/dev/null || true
      fi
    fi
    tmux kill-session -t "=$session"
  fi
}

case ${1:-} in
  new) shift; cmd_new "$@" ;;
  ls) shift; cmd_ls "$@" ;;
  done) shift; cmd_done "$@" ;;
  -h | --help | help | "") usage ;;
  *) die "unknown command '$1'" ;;
esac
