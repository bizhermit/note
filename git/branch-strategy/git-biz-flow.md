# GitBizFlow

## 概要

アジャイルや即リリース、バージョンは常時最新のみといったようなモダンな開発——ができない現場でも崩壊させないためのブランチ戦略。

Bitbucketのカスケードマージモデルを、受託開発／エンタープライズ開発の現実（仕様変更・手動テスト・厳格な証跡）に対応できるように調整した、複数バージョン保守特化型フロー。

## フローイメージ

![img](git-biz-flow.drawio.svg)

## 各ブランチの役割

※ 作業用以外のブランチでコード修正およびコミットは行わない。

### support(s)

リリースバージョン別開発および保守のヘッドブランチ。  

特定のmainブランチが存在しないため、最新バージョンのsupportブランチが実質mainブランチ。  
ステージングとしても利用する。

リリースバージョン／タイミングが異なる機能を並行して実装する場合はブランチを複数用意する。  
マージされた場合、後続バージョンのsupportブランチに対してマージし同期する。  
後続バージョンのsupportブランチがreleaseブランチへマージされた後、削除またはアーカイブする。後続バージョンがリリースされるまでは、hotfix対応が必要な可能性があるため残す。

ブランチ名は `support/<バージョン>` とし、supportブランチ間で前後関係が分かるようにする。  
各supoortブランチの前後関係は **1:1** とする。  
デフォルトブランチはメインバージョンまたは未リリースの最も古いメジャーバージョンのsupportブランチとする。

前バージョンを取り込む（v0への変更をv1にも取り込む）

```bash
git switch support/v1
git fetch
git merge support/v0
```

自動化用GitHubAction: [cascade-merge.yml](./workflows/cascade-merge.yml)  
※ バージョンは `v<major_version>.<minor_version>.<patch_version>` 形式で、数字を `.` で結合するパターンのみ対応  

### feature(s)

機能を実装する作業用ブランチ。  

リリース対象のsupportブランチから作成する。  
featureブランチおよびtestブランチで実装およびテストが終わり次第、元のsupportブランチでリベースして最新化した後、PRを作成・マージする。  
supportブランチへマージ後に削除する。  
ブランチ名は元となるsupportブランチを辿れるように `feature/<supportブランチ名（バージョン）>/<任意の名前>` とする。  
PR作成時にバージョンチェックするGitHubAction: [merge-branch-check.yml](./workflows/merge-branch-check.yml)  

リリースタイミングが不明な機能は、一旦デフォルトブランチから作業ブランチを作成し、supportブランチへのマージを止めておく  
→ ブランチ名に存在しないバージョンを指定すればチェックスクリプトが誤マージを防ぐことは可能  

supportブランチに未マージの場合、リベースでリリースバージョンを変更対応可能。  

リリースタイミングを遅らせる  
```bash
# 対象の作業ブランチに移動する
git switch feature/v0/hoge
# 最新化
git fetch
# `support/v0` から作成した `feature/v0/hoge` を `support/v1` に付け替える
git rebase --onto support/v1 support/v0 feature/v0/hoge
# 履歴が変わったためリモートリポジトリへのプッシュは強制オプションが必要
git push --force-with-lease origin feature/v0/hoge
# バージョンが変わったため、作業ブランチ名を変更
git branch -m feature/v1/hoge
# リモートリポジトリへプッシュ
git push -u origin feature/v1/hoge
# リモートリポジトリから古い名前のブランチを削除
git push origin --delete feature/v0/hoge
```

リリースタイミングを早める  
→ `support/v1` から作成した `feature/v1/hoge` を `support/v0` に付け替える  
```bash
git switch feature/v1/hoge
git fetch
git rebase --onto support/v0 support/v1 feature/v1/hoge
git push --force-with-lease origin feature/v1/hoge
git branch -m feature/v0/hoge
git push -u origin feature/v0/hoge
git push origin --delete feature/v1/hoge
```

supportブランチにマージしている場合は、リバートでsupportブランチから変更を打ち消し更新しfeatureブランチを復元、上記でリベースして対応する。

### test(s)

実装した機能を確認するブランチ。  

ＱＡチームへの提供用、もしくはインフラに制約があってsupportブランチ毎に検証環境を用意できない場合に使用する掃きだめ。  
テスト範囲に応じてsupportブランチまたはfeatureブランチから作成および変更を取り入れる。  
当ブランチをマージする先は存在しない。  

### release(s)

リリースブランチ。  

マージされる度にタグおよびリリースノートを作成する。  
当ブランチをマージする先は存在しない。  

「開発中」と「リリース済み」の境界を明確にし、各機能の本番環境へのリリースタイミングの追跡管理を徹底することが目的。

### hotfix(s)

releaseブランチに対する緊急作業用ブランチ。  

リリース済みsupportブランチからhotfixブランチを作成して作業を行う。  
確認作業を行う場合はhotfixブランチまたはtestブランチを使用する。  
作業完了後にsupportブランチを経由してreleaseブランチへマージにする。  
ブランチ名は元となるsupportブランチを辿れるように `hotfix/<supportブランチ名（バージョン）>/<任意の名前>` とする。  

featureブランチとの違いはほぼないが、CIツール等で以下のような自動化を仕込む際に区別できるように分けておく。

- `feature/*` → マージ時直前にsupportブランチでリベースし最新を担保
- `hotfix/*` → マージ時にパッチバージョンを上げる

## 評価

### メリット

- 複数バージョンの並列開発／保守に対応できる
- testブランチの自由度が高く、実施テストの種類によって柔軟に構築ができる
- ベースsupportから後続supportへ戻すルールによって、後続開発ブランチとの差異を最小化できる

### デメリット

- featureブランチのマージ先が多い（各testブランチ、supportブランチ）
- supportブランチ間で後続supportへマージする作業の難易度が高い
  - → CIツールで自動化する
- 承認プロセスがが緩い（testで確認していなくても、supportブランチやreleaseブランチに出せてしまう）
  - → PRに自動テストのパスを必須とする
- 運用管理者に高い理解度を要求する