#!/usr/bin/env bash
# Commit dirty git submodules, then the parent repo, and print (or run) push commands.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

PUSH=0
DRY_RUN=0
SUBMODULE_MSG=""
PARENT_MSG=""

usage() {
  cat <<'EOF'
Usage: git-commit-and-push-all.sh [options]

Options:
  --push                    Run git push after commits (needs GitHub auth on this machine)
  --dry-run                 Print commit messages and push lines; do not commit
  --submodule-msg "..."     Commit message for dirty submodules (default: auto from git status)
  --parent-msg "..."        Commit message for the parent repo (default: auto from git status)

Examples:
  ./scripts/git-commit-and-push-all.sh
  ./scripts/git-commit-and-push-all.sh --push
  ./scripts/git-commit-and-push-all.sh --dry-run

Run from the repository root. Submodule commits run before the parent so the pointer can be recorded.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --submodule-msg)
      SUBMODULE_MSG="${2:?missing value for --submodule-msg}"
      shift 2
      ;;
    --parent-msg)
      PARENT_MSG="${2:?missing value for --parent-msg}"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Collect changed paths in repo at $1 (absolute or relative). Prints paths, one per line.
collect_changed_paths() {
  local repo_dir="$1"
  (
    cd "$repo_dir"
    git status --porcelain | while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      local path="${line:3}"
      path="${path#\"}"
      path="${path%\"}"
      # Submodule pointer lines look like "_internal/DeepFaceLab (modified content)" — skip for message body
      [[ "$path" == *" (modified content)"* ]] && continue
      [[ "$path" == *" (new commits)"* ]] && continue
      [[ "$path" == *" (untracked content)"* ]] && continue
      printf '%s\n' "$path"
    done
  )
}

# Infer a subject + body from changed paths. Writes "subject\n\nbody" to stdout.
generate_commit_message() {
  local repo_dir="$1"
  local -a paths=()
  while IFS= read -r p; do
    [[ -n "$p" ]] && paths+=("$p")
  done < <(collect_changed_paths "$repo_dir")

  if [[ ${#paths[@]} -eq 0 ]]; then
  # Parent may only show submodule as dirty before add — include submodule paths from status
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      local path="${line:3}"
      path="${path#\"}"
      path="${path%\"}"
      if [[ "$path" == *"/"* && "$path" != *" "* ]]; then
        paths+=("$path")
      elif [[ "$line" =~ ^[MADRCU?][MADRCU?][[:space:]] ]]; then
        paths+=("${line:3}")
      fi
    done < <(cd "$repo_dir" && git status --porcelain)
  fi

  [[ ${#paths[@]} -eq 0 ]] && return 1

  declare -A buckets=()
  for p in "${paths[@]}"; do
    p="${p%% *}"
    local bucket
    case "$p" in
      README*|*.md) bucket="docs" ;;
      *.sh) bucket="workflow scripts" ;;
      .gitmodules|third_party/*) bucket="submodules" ;;
      _internal/*) bucket="DeepFaceLab submodule" ;;
      requirements*) bucket="dependencies" ;;
      XSegEditor/*) bucket="XSeg editor" ;;
      core/*|main.py|mainscripts/*|facelib/*) bucket="DeepFaceLab" ;;
      scripts/*) bucket="repo tooling" ;;
      5_*|4_*|6_*|7_*|8_*|9_*) bucket="DFL pipeline scripts" ;;
      *)
        bucket="$(dirname "$p")"
        [[ "$bucket" == "." ]] && bucket="root"
        ;;
    esac
    buckets["$bucket"]=1
  done

  local -a names=()
  while IFS= read -r b; do
    [[ -n "$b" ]] && names+=("$b")
  done < <(printf '%s\n' "${!buckets[@]}" | LC_ALL=C sort)

  local subject
  local n="${#names[@]}"
  if [[ "$n" -eq 0 ]]; then
    subject="Update tracked files."
  elif [[ "$n" -eq 1 ]]; then
    subject="Update ${names[0]}."
  elif [[ "$n" -eq 2 ]]; then
    subject="Update ${names[0]} and ${names[1]}."
  else
    subject="Update ${names[0]}, ${names[1]}, and related changes."
  fi

  local body="Changed files:"
  local i=0
  for p in "${paths[@]}"; do
  p="${p%% *}"
    body+=$'\n'" - $p"
    i=$((i + 1))
    [[ "$i" -ge 25 ]] && body+=$'\n'" - ..."; break
  done

  printf '%s\n\n%s' "$subject" "$body"
}

commit_with_message() {
  local repo_dir="$1"
  local msg="${2:-}"
  if [[ -z "$msg" ]]; then
    msg="$(generate_commit_message "$repo_dir")" || return 1
    echo "Auto-generated commit message:"
    echo "$msg"
    echo ""
  fi
  local subject="${msg%%$'\n'*}"
  local body="${msg#*$'\n'}"
  if [[ "$body" == "$msg" ]]; then
    body=""
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] Would commit in $repo_dir"
    return 0
  fi
  if [[ -n "$body" ]]; then
    git -C "$repo_dir" commit -m "$subject" -m "$body"
  else
    git -C "$repo_dir" commit -m "$subject"
  fi
}

submodule_paths=()
if [[ -f .gitmodules ]]; then
  while IFS= read -r _path; do
    [[ -n "$_path" ]] && submodule_paths+=("$_path")
  done < <(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
fi

submodule_dirty=0
for rel in "${submodule_paths[@]}"; do
  if [[ ! -d "$rel" ]]; then
    continue
  fi
  if [[ -n "$(git -C "$rel" status --porcelain 2>/dev/null)" ]]; then
    submodule_dirty=1
    break
  fi
done

for rel in "${submodule_paths[@]}"; do
  [[ -d "$rel" ]] || continue
  if [[ -z "$(git -C "$rel" status --porcelain 2>/dev/null)" ]]; then
    continue
  fi
  if [[ "$DRY_RUN" -ne 1 ]]; then
    git -C "$rel" add -u
    git -C "$rel" add -A 2>/dev/null || true
  fi
  if [[ -n "$(git -C "$rel" status --porcelain)" ]]; then
    echo "=== Submodule: $rel ==="
    local_msg="$SUBMODULE_MSG"
    if [[ -z "$local_msg" ]]; then
      local_msg="$(generate_commit_message "$ROOT/$rel")"
      echo "Auto-generated commit message:"
      echo "$local_msg"
      echo ""
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[dry-run] Would commit submodule $rel"
    else
      commit_with_message "$ROOT/$rel" "$local_msg"
      echo "Committed submodule: $rel ($(git -C "$rel" rev-parse --short HEAD))"
    fi
  fi
done

parent_dirty=0
if [[ -n "$(git status --porcelain)" ]]; then
  parent_dirty=1
fi

if [[ "$parent_dirty" -eq 1 ]]; then
  if [[ "$DRY_RUN" -ne 1 ]]; then
    git add -u
    for rel in "${submodule_paths[@]}"; do
      git add "$rel" 2>/dev/null || true
    done
    git add -A 2>/dev/null || true
  fi
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "=== Parent repository ==="
    local_parent_msg="$PARENT_MSG"
    if [[ -z "$local_parent_msg" ]]; then
      local_parent_msg="$(generate_commit_message "$ROOT")"
      echo "Auto-generated commit message:"
      echo "$local_parent_msg"
      echo ""
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "[dry-run] Would commit parent"
    else
      commit_with_message "$ROOT" "$local_parent_msg"
      echo "Committed parent: $(git rev-parse --short HEAD)"
    fi
  fi
fi

if [[ "$submodule_dirty" -eq 0 && "$parent_dirty" -eq 0 ]]; then
  echo "Working tree clean; nothing to commit."
fi

PUSH_LINES=()
for rel in "${submodule_paths[@]}"; do
  [[ -d "$rel" ]] || continue
  branch="$(git -C "$rel" rev-parse --abbrev-ref HEAD)"
  ahead="$(git -C "$rel" rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)"
  if [[ "$ahead" -gt 0 ]]; then
    PUSH_LINES+=("cd \"$ROOT/$rel\" && git push origin \"$branch\"")
  fi
done

parent_branch="$(git rev-parse --abbrev-ref HEAD)"
parent_ahead="$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)"
if [[ "$parent_ahead" -gt 0 ]]; then
  PUSH_LINES+=("cd \"$ROOT\" && git push origin \"$parent_branch\"")
fi

echo ""
echo "========== Push (submodule first, then parent) =========="
if [[ ${#PUSH_LINES[@]} -eq 0 ]]; then
  echo "Already up to date with origin."
else
  for line in "${PUSH_LINES[@]}"; do
    echo "$line"
  done
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo ""
    echo "[dry-run] No push executed."
  elif [[ "$PUSH" -eq 1 ]]; then
    echo ""
    echo "Running push..."
    for line in "${PUSH_LINES[@]}"; do
      eval "$line"
    done
    echo "Push finished."
  else
    echo ""
    echo "Copy/paste the lines above in your terminal (or re-run with --push)."
  fi
fi
