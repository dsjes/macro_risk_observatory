CREATE TABLE IF NOT EXISTS `{{ params.project }}.staging.stg_event` (
event_id                 INT64     NOT NULL OPTIONS (description = 'GDELT 事件唯一 ID(原欄位 GLOBALEVENTID),也是 MERGE 比對的鍵'),
sql_date                 INT64     OPTIONS (description = 'GDELT SQLDATE,事件發生日 YYYYMMDD'),
date_added               INT64     OPTIONS (description = 'GDELT DATEADDED,寫入 GDELT 的時間 YYYYMMDDHHMMSS'),

-- Actor 1
actor1_code STRING,
actor1_name STRING,
actor1_country_code STRING,
actor1_type1_code STRING,
actor1_type2_code STRING,

-- Actor 2
actor2_code STRING,
actor2_name STRING,
actor2_country_code STRING,
actor2_type1_code STRING,
actor2_type2_code STRING,

-- 事件類型
event_code STRING, event_root_code STRING, quad_class INT64,

-- 強度與報導量
goldstein_scale FLOAT64,
num_mentions INT64,
num_sources INT64,
num_articles INT64,
avg_tone FLOAT64,

-- 地點
action_geo_country_code STRING,
action_geo_lat FLOAT64,
action_geo_long FLOAT64,

-- 來源
source_url STRING,

-- 衍生與 pipeline metadata
event_date               DATE      OPTIONS (description = '由 sql_date 轉換'),
added_date               DATE      NOT NULL OPTIONS (description = '由 date_added 轉換,作為分區欄位'),
batch_id                 STRING    NOT NULL OPTIONS (description = 'Airflow 批次 ID,例如 run_id'),
ingested_at              TIMESTAMP NOT NULL OPTIONS (description = '寫入 staging 的時間')
)
PARTITION BY added_date
OPTIONS (
    partition_expiration_days = 7,
    description = 'Incremental GDELT events, kept 7 days for debugging and replay'
);