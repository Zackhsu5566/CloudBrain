# 事前準備 — 部署 CloudBrain 之前

在開始部署之前，你需要準備好以下東西。這份指南會一步一步帶你完成。

---

## 1. Telegram Bot 設定

CloudBrain 透過 Telegram 和你溝通。需要一個 Telegram Bot。

### 1.1 建立 Bot

1. 開啟 Telegram，搜尋 **@BotFather**
2. 傳送 `/newbot`
3. 輸入 Bot 名稱（例如 `CloudBrain`）
4. 輸入 Bot username（必須以 `bot` 結尾，例如 `yourname_cloudbrain_bot`）
5. BotFather 會回傳一個 **Token**，長這樣：
   ```
   123456789:ABCdefGHIjklMNO...
   ```
   **把這個 Token 記下來**，稍後需要輸入到部署腳本。

### 1.2 取得你的 Chat ID

1. 搜尋 **@userinfobot**，傳送任意訊息
2. 它會回傳你的 **Chat ID**，長這樣：
   ```
   ID: 123456789
   ```
   **把這個數字記下來**，這用來驗證只有你能和 Bot 說話。

### 1.3 測試 Bot（選做）

1. 在 Telegram 搜尋你的 Bot（用 username 搜尋）
2. 點 **Start** 或傳送 `/start`
3. 確認 Bot 沒有回應（這是正常的，Bot 需要等 OpenClaw 啟動後才會回話）

---

## 2. MiniMax API Key

CloudBrain 使用 MiniMax 作主力模型。

### 2.1 申請帳號

1. 前往 [MiniMax 官網](https://platform.minimax.io)
2. 點 **Sign Up** 註冊帳號（可用 Google 登入）
3. 完成驗證

### 2.2 購買 Token Plan

1. 前往 [MiniMax Token Plan](https://platform.minimax.io/subscribe/token-plan)
2. 選擇適合的方案：
   - **Pay-as-you-go**：用多少算多少，最彈性
   - **預付額度**：較便宜，適合固定用量

**推薦從 Pay-as-you-go 開始**，每月約 $5-10 USD 足夠日常使用。

### 2.3 取得 API Key

1. 進 **Dashboard** → **API Keys**
2. 點 **Create New Key**
3. 複製 Key（只會顯示一次，請妥善保存）

---

## 3. Anthropic API Key（選做，Fallback）

如果 MiniMax 失敗，CloudBrain 會自動切到 Claude Opus 作為 Fallback。

### 3.1 申請帳號

1. 前往 [Anthropic Console](https://console.anthropic.com)
2. 點 **Sign Up** 註冊帳號
3. 設定付款方式（需要信用卡）

### 3.2 購買 Credits

1. 進 **Settings** → **Billing**
2. 購買 Credits（**最少 $5 起**）
3. Claude Opus 價格約 $0.015 / 1K tokens，建議只用作 Fallback

### 3.3 取得 API Key

1. 進 **API Keys** 頁面
2. 點 **Create Key**
3. 複製並妥善保存

---

## 4. VPS（Virtual Private Server）

CloudBrain 需要一台 24/7 運作的伺服器。

**推薦使用 [Hostinger VPS](https://www.hostinger.com/vps)**，價格實惠且支援 Ubuntu。

### 最低需求

- 1 vCPU
- 4 GB RAM
- 50 GB SSD
- Ubuntu 24.04 LTS

### 申請後確認

1. 確認你收到 VPS 的 IP 位址和 root 密碼
2. 確認已選擇 **Ubuntu 24.04 LTS** 作為作業系統
3. 測試 SSH 可以連線：
   ```bash
   ssh root@你的VPS_IP
   ```

---

## 5. 確認你有的東西

在開始部署之前，確認你有以下資料：

| 需要的東西 | 範例 |
|-----------|------|
| Telegram Bot Token | `123456789:ABCdefGHIjklMNO...` |
| 你的 Chat ID | `123456789` |
| MiniMax API Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| Anthropic API Key（選做）| `sk-ant-...` |
| VPS IP | `123.456.789.123` |
| VPS root 密碼 | （你設定的） |

---

## 下一步

東西都準備好了嗎？回到 [README.md](README.md) 開始部署。
