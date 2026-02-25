#!/usr/bin/env bash
set -euo pipefail

# デフォルトブランチ検出
default_branch=$(
  git remote show origin 2>/dev/null \
    | sed -n 's/.*HEAD branch: //p'
)

if [ -z "$default_branch" ]; then
  echo "Error: Could not detect default branch from origin." >&2
  exit 1
fi

echo "Default branch detected: $default_branch"

# デフォルトブランチへ移動 & 最新化
git switch "$default_branch"
git pull
git fetch --prune

# 削除対象ブランチ抽出
gone_branches=$(
  git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads \
  | awk '$2 == "[gone]" {print $1}'
)

if [ -z "$gone_branches" ]; then
  echo
  echo "No branches to delete."
else
  echo
  echo "Deleting branches:"
  for branch in $gone_branches; do
    echo "  - $branch"
    if ! git branch -d "$branch"; then
      echo "    Failed (maybe not fully merged)"
    fi
  done
fi

echo
echo "Done!"
echo
