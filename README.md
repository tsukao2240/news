# Tech News Summarizer

テクノロジーニュースとAIエージェント・LLMニュースを自動で要約してDiscordに投稿するn8nワークフローです。

## ワークフロー

| ワークフロー | 説明 | 実行時刻 | Discordチャンネル |
|---|---|---|---|
| Tech News Summarizer | バックエンドエンジニア向けニュース | 毎日 8:00 | `DISCORD_WEBHOOK_URL` |
| AI Agent News | AIエージェント・LLM向けニュース | 毎日 8:30 | `DISCORD_WEBHOOK_URL_AI` |

## ニュースソース

**Tech News Summarizer**
- Hacker News / Lobsters / The New Stack
- はてなブックマーク（ITカテゴリ）
- TechCrunch / The Verge / Publickey

**AI Agent News**
- Hacker News / Lobsters
- Simon Willison's Blog / HuggingFace Blog
- Towards Data Science / MIT Technology Review

## セットアップ手順

### 1. 環境変数の設定

```bash
cp .env.example .env.production
```

`.env.production` を編集して以下を設定：

| 変数 | 説明 |
|---|---|
| `N8N_USER` | n8nログインユーザー名 |
| `N8N_PASSWORD` | n8nログインパスワード |
| `N8N_HOST` | サーバーのIPアドレス |
| `ANTHROPIC_API_KEY` | Claude APIキー（[取得先](https://console.anthropic.com/settings/keys)） |
| `DISCORD_WEBHOOK_URL` | 既存チャンネルのWebhook URL |
| `DISCORD_WEBHOOK_URL_AI` | AIニュースチャンネルのWebhook URL |
| `N8N_API_KEY` | n8n REST APIキー（デプロイ自動化に必要） |

### 2. Discord Webhook URLの取得

1. Discordでチャンネルを作成（Tech用・AI用の2つ）
2. チャンネル設定 → 連携サービス → ウェブフック → 新しいウェブフック
3. URLをコピーして `.env.production` に設定

### 3. n8n APIキーの取得

1. n8n UIにアクセス
2. 右上アバター → Settings → API → Create API Key
3. 生成されたキーを `N8N_API_KEY` に設定

### 4. デプロイ

```bash
./deploy.sh
```

初回はワークフローが存在しないためAPIでの更新がエラーになります。n8n UIから手動でインポートしてください：

1. n8n UI → 右上メニュー → Import from File
2. `workflows/tech-news-summarizer.json` をインポート
3. `workflows/ai-agent-news.json` をインポート
4. 各ワークフローを「Active」に切り替え

2回目以降は `./deploy.sh` だけで自動更新されます。

## デプロイの仕組み

`deploy.sh` は以下を自動実行します：

1. ローカルのファイルをサーバーに転送（rsync）
2. Dockerコンテナを再起動
3. n8nの起動を待機（最大60秒）
4. n8n REST APIでワークフローを更新

**※ `n8n import:workflow` CLIは使用しない**（起動中のn8nと競合してサーバーがOOMで落ちるため）

## トラブルシューティング

### アクセスできない

- `http://` でアクセスしているか確認（ブラウザが `https://` に強制リダイレクトする場合あり）
- `docker ps` でコンテナが起動しているか確認

### Discordに投稿されない

- Webhook URLが正しいか確認
- n8nのエラーログを確認: `docker compose logs news-n8n`

### Claude APIエラー

- APIキーが正しいか確認（[Console](https://console.anthropic.com/)）

## コマンド

```bash
# デプロイ（ファイル転送 + コンテナ再起動 + ワークフロー更新）
./deploy.sh

# コンテナの状態確認
ssh oracle-news "docker compose -f ~/news/docker-compose.yml ps"

# ログの確認
ssh oracle-news "docker logs news-n8n --tail=50"

# コンテナの再起動のみ
ssh oracle-news "cd ~/news && docker compose --env-file .env.production restart"
```

## ライセンス

MIT
