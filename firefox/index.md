# FireFox関連

## localhost開発

### localhostでアクセスできない場合

1. アドレスバーに`about:config`と入力
2. `network.proxy.allow_hijacking_localhost`を`true`に変更

## JavaScript

### crypto.randomUUID

http接続時は`crypto.randomUUID`が使えない。httpsの場合は大丈夫そう（ドキュメント見ただけで検証はしていない）。

```js
const getRandomUUID = crypto.randomUUID?.bind(crypto) ?? generateUuidV4;
```

みたいな感じで代替関数が必要。
ChromeやEdgeでは再現しない。
