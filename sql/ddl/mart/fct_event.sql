CREATE TABLE IF NOT EXISTS `{{ params.project }}.mart.fct_event` (
event_id            INT64     NOT NULL OPTIONS (description = 'GDELT 事件唯一 ID(原欄位 GLOBALEVENTID),也是 MERGE 比對的鍵'),
event_date          DATE      NOT NULL OPTIONS (description = '事件發生日,分區欄位'),
date_key            INT64     NOT NULL OPTIONS (description = 'YYYYMMDD,對應 dim_date.date_key'),

-- 行為者(country_code 對應 dim_cameo_country,type_code 對應 dim_cameo_type)
actor1_code STRING,
actor2_code STRING,
actor1_country_code STRING,
actor2_country_code STRING,
actor1_type1_code STRING,
actor2_type1_code STRING,
dyad_key STRING OPTIONS (
    description = '兩邊國家代碼排序後以 - 連接,如 CHN-USA;任一邊缺值則為 NULL'
),

-- 事件類型(cameo_code 對應 dim_cameo)
cameo_code STRING, event_root_code STRING, quad_class INT64,

-- 地點
action_geo_country_code STRING OPTIONS (
    description = '事件發生地國家(FIPS 2 碼,非 CAMEO 3 碼,不能 join dim_cameo_country)'
),
lat FLOAT64,
lon FLOAT64,

-- 強度與報導量
goldstein_scale FLOAT64,
avg_tone FLOAT64,
num_mentions INT64,
num_articles INT64,

-- 來源與 pipeline metadata
source_url          STRING,
batch_id            STRING    OPTIONS (description = '最後一次寫入此列的 Airflow 批次'),
updated_at          TIMESTAMP OPTIONS (description = '最後一次寫入此列的時間')
)
PARTITION BY event_date
CLUSTER BY dyad_key, action_geo_country_code, cameo_code
OPTIONS (
    require_partition_filter = TRUE,
    description = 'GDELT event fact table, one row per event'
);