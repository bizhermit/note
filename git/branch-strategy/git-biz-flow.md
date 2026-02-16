# GitBizFlow

## 概要

アジャイルや即リリース、バージョンは常時最新のみといったようなモダンな開発——ができない現場でも崩壊させないためのブランチ戦略。

Bitbucketのカスケードマージモデルを、受託開発／エンタープライズ開発の現実（仕様変更・手動テスト・厳格な証跡）に対応できるように調整した、複数バージョン保守特化型汎用フロー。

## フローイメージ

![img](git-biz-flow.drawio.svg)

## 各ブランチの役割

※ 作業用以外のブランチでコード修正およびコミットは行わない。

### support(s)

リリースバージョン別開発および保守のヘッドブランチ。  
特定のmainブランチが存在しないため、supportブランチが実質mainブランチ。  

リリースバージョン／タイミングが異なる機能を並行して実装する場合はブランチを複数用意する。  
マージされた場合、後続バージョンのsupportブランチに対してマージし同期する。  
後続バージョンのsupportブランチがreleaseブランチへマージされた後、削除またはアーカイブする。後続バージョンがリリースされるまでは、hotfix対応が必要な可能性があるため残す。

ブランチ名は `support/<バージョン>` とし、supportブランチ間で前後関係が分かるようにする。  
メインバージョンをデフォルトブランチとして設定する。迷う場合は未リリースの最も古いバージョンとする（結局状況次第）。

前バージョンを取り込む（v0への変更をv1にも取り込む）

```bash
git switch support/v1
git merge support/v0
```

### feature(s)

機能を実装する作業用ブランチ。  

リリース対象のsupportブランチから作成する。  
featureブランチおよびtestブランチで実装およびテストが終わり次第、元のsupportブランチにPRを作成・マージする。  
supportブランチへマージ後に削除する。  
ブランチ名は元となるsupportブランチを辿れるように `feature/<supportブランチ名（バージョン）>/<任意の名前>` とする。  

supportブランチに未マージの場合、リベースでリリースバージョンを変更対応可能。  

リリースタイミングを遅らせる  
→ `support/v0` から作成した `feature/v0/hoge` を `support/v1` に付け替える  
```bash
git switch feature/v0/hoge
git fetch
git rebase --onto support/v1 support/v0 feature/v0/hoge
git branch -M feature/v1/hoge
```

リリースタイミングを早める  
→ `support/v1` から作成した `feature/v1/hoge` を `support/v0` に付け替える  
```bash
git switch feature/v1/hoge
git fetch
git rebase --onto support/v0 support/v1 feature/v1/hoge
git branch -M feature/v0/hoge
```

supportブランチにマージしている場合は、リバートでsupportブランチから変更を打ち消し更新しfeatureブランチを復元、上記でリベースして対応する。

### test(s)

実装した機能を確認するブランチ。  
インフラに制約があっても何とかするための検証用の掃きだめ。ＱＡチームへの提供用。  

テスト範囲に応じてsupportブランチまたはfeatureブランチから作成および変更を取り入れる。  
当ブランチをマージする先は存在しない。  

そもそもテストはCI/CDで自動化したい。  

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

featureブランチとの違いはほぼないが、CIツール等で以下のような自動化を仕込む際に区別できるように分けておく。

- `feature/*` → マージ時直前にsupportブランチでリベースし最新を担保
- `hotfix/*` → マージ時にパッチバージョンを上げる

## フロー運用

1. supportからfeatureを作成して機能を実装する
2. featureからtestへPRを作成しレビューを行う
3. testで確認し、不備があればfeatureで再修正して再度testへPRを作成
4. testで検証完了後、featureをsupportへマージする
5. 後続supportが存在する場合は、基点supportから後続supportへマージする
6. supportからreleaseにマージしてリリース
7. releaseに対する修正は、support経由でhotfixを作成し行う

## 評価

### メリット

- 複数バージョンの並列開発／保守に対応できる
- testブランチの自由度が高く、実施テストの種類によって柔軟に構築ができる
- releaseからsupport、ベースsupportから後続supportへ戻すルールによって、後続開発ブランチとの差異を最小化できる

### デメリット

- featureブランチのマージ先が多い（各testブランチ、supportブランチ）
- supportブランチ間で後続supportへマージする作業の難易度が高い
  - → CIツールで自動化する
- 承認プロセスがが緩い（testで確認していなくても、supportブランチやreleaseブランチに出せてしまう）
  - → PRに自動テストのパスを必須とする