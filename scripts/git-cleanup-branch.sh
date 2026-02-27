#!/usr/bin/env bash
set -euo pipefail

# 作業ディレクトリがクリーンかチェック
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Working directory is not clean." >&2
  echo "Please commit or stash your changes before running this script." >&2
  exit 1
fi

# デフォルトブランチを確実に検出（リモートの変更に自動追従）
echo "Detecting default branch from remote..."
git remote set-head origin -a >/dev/null 2>&1 || true
default_branch=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's!origin/!!' || true)

if [ -z "$default_branch" ] || [ "$default_branch" = "HEAD" ]; then
  echo "Error: Could not detect default branch from origin." >&2
  exit 1
fi

echo "Default branch detected: $default_branch"

# デフォルトブランチへ移動 & 最新化
git switch "$default_branch"
git fetch --prune
git merge --ff-only "@{u}"

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
  echo "$gone_branches" | while IFS= read -r branch; do
    # 空行対策
    if [ -n "$branch" ]; then
      echo "  - $branch"
      if ! git branch -d "$branch"; then
        echo "    Failed (maybe not fully merged)"
      fi
    fi
  done
fi

echo
echo "Done!"
echo
