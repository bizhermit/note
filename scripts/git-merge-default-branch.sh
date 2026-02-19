#!/usr/bin/env bash
set -euo pipefail

# Git repo か安全にチェック
safe_git_check() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

if ! safe_git_check; then
  echo "Not a git repository. Skipping."
  exit 0
fi

# 現在のブランチ
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $current_branch"

# default branch 検出
default_branch=$(
  git remote show origin 2>/dev/null \
    | sed -n 's/.*HEAD branch: //p'
)

if [ -z "$default_branch" ]; then
  echo "Error: Could not detect default branch from origin." >&2
  exit 1
fi

echo "Default branch detected: $default_branch"

# fetch
git fetch --prune

# default branch を最新化
echo "Switching to default branch: $default_branch"
git switch "$default_branch"

echo "Pulling latest changes..."
git pull

# 元のブランチへ戻る
echo "Switching back to $current_branch"
git switch "$current_branch"

# マージ
echo "Merging $default_branch into $current_branch..."
if git merge "$default_branch"; then
  echo "Merge completed successfully."
else
  echo
  echo "Merge conflict detected!"
  echo "Please resolve the conflict manually."
  exit 1
fi

echo
echo "Done!"
