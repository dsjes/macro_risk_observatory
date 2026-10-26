# Macro-Risk Observatory

以 [GDELT](https://www.gdeltproject.org/) 全球事件資料為基礎的地緣風險觀測平台。資料每日自動更新到 BigQuery,並透過儀表板呈現各國風險、雙邊關係(如美中、烏俄)的變化,以及資料管線的運作狀態。

## 功能

- **GeoRisk Map**:各國風險分數地圖與排行榜。
- **Dyad Watch**:雙邊局勢走勢,可檢視衝突事件佔比、事件強度與語調的變化。
- **Pipeline Health**:資料新鮮度、每日處理筆數與查詢成本。

## 技術架構

BigQuery、Apache Airflow、Polars、Streamlit、Docker

```
GDELT events ─┐
              ├─► Airflow ─► BigQuery (Staging ─► Star Schema ─► Materialized Views) ─► Polars ─► Streamlit
CAMEO codes ──┘
```

## 快速開始

### 前置需求

- Docker 與 Docker Compose
- 已啟用 BigQuery API 的 GCP 專案
- 一個 service account(角色:`BigQuery Job User`、`BigQuery Data Editor`)及其 JSON key

### 設定

1. 複製環境變數範本並填值:

   ```bash
   cp .env.example .env
   ```

   | 變數 | 說明 |
   | --- | --- |
   | `AIRFLOW_UID` | macOS 用 `50000`;Linux 設為 `$(id -u)` |
   | `AIRFLOW_FERNET_KEY` | `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"` |
   | `AIRFLOW_WEBSERVER_SECRET_KEY` | 隨機字串,例如 `openssl rand -hex 32` |
   | `AIRFLOW_ADMIN_USER` / `AIRFLOW_ADMIN_PASSWORD` | Airflow 管理者帳密 |
   | `GCP_PROJECT_ID` | GCP 專案 ID |
   | `BQ_LOCATION` | BigQuery location,預設 `US` |

2. 將 service account key 存為 `secrets/gcp-key.json`。

### 啟動

```bash
docker compose up -d --build
```

開啟 http://localhost:8080,以 `.env` 中的管理者帳密登入 Airflow。

```bash
docker compose down        # 停止服務
docker compose down -v     # 停止並清除資料庫
```

## 專案結構

```
├── dags/        # Airflow DAG
├── sql/         # SQL 腳本
├── plugins/     # Airflow plugins
├── secrets/     # GCP key(不進版控)
├── Dockerfile
├── docker-compose.yaml
└── .env.example
```
