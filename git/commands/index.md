# Gitコマンド

## リモートリポジトリ

### リモートリポジトリ確認

```bash
git remote -v
```

### リモートリポジトリ追加

```bash
git remote add [remote-name] [url]
# e.g.
git remote add origin https://github.com/bizhermit/note.git
```

### リモートリポジトリ削除

```bash
git remote remove [remote-name]
# e.g.
git remote remove origin
```

### リモートリポジトリ変更

```bash
git remote set-url [remote-name] [url]
```

## ブランチ

### ブランチ確認

```bash
git branch
```

リモート含めて

```bash
git branch -a
```

### ブランチ作成

```bash
git switch -c [new-branch-name]
# e.g.
git switch -c feature/new-feature
```

### ブランチ切替

```bash
git switch [target-branch-name]
```

### マージ

```bash
git switch [dest-branch-name]
git merge --no-ff [src-branch-name] -m "[comment]"
# e.g.
git switch main
git merge --no-ff feature/new-feature -m "feat: add new feature."
```

### マージ取り消し

#### コンフリクト対応前

```bash
git merge --abort
```

#### コンフリクト対応後（マージ前）

```bash
git reset --hard HEAD
```

#### マージ後

```bash
git revert --hard ORIG_HEAD
```

### ブランチ削除

```bash
git branch -d [target-branch-name]
```

未コミットが有る場合等に強制削除

```bash
git branch -D [target-branch-name]
```

### リモートのブランチ削除

```bash
git push [remote-name] :[target-branch-name]
# e.g.
git push origin :feature/new-feature
```

### ブランチ同期

```bash
git fetch -p
```

### ブランチ名変更

```bash
git branch -m [old-branch-name] [new-branch-name]
# e.g.
git branch -m master main
```

強制？

```bash
git branch -M [old-branch-name] [new-branch-name]
```

### 親ブランチ確認

```bash
git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -1 | awk -F'[]~^[]' '{print $2}'
```

### 親ブランチ変更

```bash
git rebase [branch-name]
```

### リモートで削除されたブランチをローカルからも削除

```bash
git switch main && git pull && git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d
```


## 変更管理

### ステージ

```bash
git add [file-name]
```

全部の場合は

```bash
git add .
```

### コミット（ローカル）

ステージした状態で

```bash
git commit -m "[comment]"
```

### コミット取り消し

#### 直前

```bash
git reset --soft HEAD
```

#### 回数指定

```bash
git reset --soft HEAD~{n}
# e.g. ２つ前までのコミットを削除
git reset --soft HEAD~2
```

#### コミットID指定

```bash
git reset --soft [commit-id]
```

### リモートリポジトリに公開

```bash
git push [remote-name] [branch-name]
# e.g.
git push origin main
```

### ローカルリポジトリをリモートリポジトリで更新

```bash
git fetch [remote-name]
# e.g.
git fetch
git fetch origin
```

### ワークツリーをローカルリポジトリで更新

```bash
git merge [remote-name]/[branch-name]
# e.g.
git merge
git merge origin/main
```

### ローカルリポジトリをリモートリポジトリで更新 ＆ ワークツリーをローカルリポジトリで更新

```bash
git pull [remote-name] [branch-name]
# e.g.
git pull
git pull origin main
```

## タグ

### タグ作成

```bash
git tag "[tag-name]"
git push [remote-name] tags/[tag-name]
# e.g.
git tag v1.0.0
git push origin tags/v1.0.0
```

### タグ削除

```bash
git tag -d [tag-name]
git push origin :[tag-name]
```

### タグ確認（リモート）

```bash
git ls-remote --tags
```

## その他

### マージをデフォルトでNonFastForward

```bash
git config --add merge.ff false
git config --add pull.ff only
```

### git管理から除外せず、ワークツリーの変更を無視（リモートが更新されても上書きしない）

```bash
git update-index --skip-worktree [target-file-name]
```

解除

```bash
git update-index --no-skip-worktree [target-file-name]
```

### git管理から除外せず、ワークツリーの変更を無視（リモートが更新されたら上書きする）

```bash
git update-index --assume-unchanged [target-file-name]
```

解除

```bash
git update-index --no-assume-unchanged [target-file-name]
```