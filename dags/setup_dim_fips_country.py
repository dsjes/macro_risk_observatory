"""手動觸發,載入 FIPS 10-4 → ISO-3 國碼對照表到 mart。

GDELT 的 ActionGeo_CountryCode 是 FIPS 10-4 兩碼,Plotly choropleth 需要 ISO-3,
所以另建這張表,和 CAMEO.country.txt(CAMEO 三碼)是不同的代碼體系。
來源 GeoNames countryInfo.txt(CC BY 4.0)。
"""

import os
from datetime import datetime

from airflow.decorators import dag, task

SOURCE_URL = "https://download.geonames.org/export/dump/countryInfo.txt"
PROJECT = os.environ["GCP_PROJECT_ID"]
LOCATION = os.environ.get("BQ_LOCATION", "US")

# GeoNames 沒有、但 GDELT 會出現的 FIPS 代碼
OVERRIDES = [
    {"fips_code": "GZ", "iso3_code": "PSE", "country_name": "Gaza Strip"},
]


@dag(
    dag_id="setup_dim_fips_country",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
)
def setup_dim_fips_country():
    @task
    def load():
        import pandas as pd
        from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
        from google.cloud import bigquery

        # keep_default_na=False:避免字串 "NA" 被當成缺值
        df = pd.read_csv(
            SOURCE_URL,
            sep="\t",
            comment="#",
            header=None,
            dtype=str,
            keep_default_na=False,
            usecols=[1, 3, 4],
            names=["iso3_code", "fips_code", "country_name"],
        )
        # 少數領地(如 Aland Islands)沒有 FIPS 代碼
        df = df[df["fips_code"] != ""]
        df = pd.concat([df, pd.DataFrame(OVERRIDES)]).drop_duplicates(
            "fips_code", keep="last"
        )

        columns = ["fips_code", "iso3_code", "country_name"]
        client = BigQueryHook().get_client(project_id=PROJECT, location=LOCATION)
        client.load_table_from_json(
            df[columns].to_dict("records"),
            f"{PROJECT}.mart.dim_fips_country",
            job_config=bigquery.LoadJobConfig(
                schema=[bigquery.SchemaField(c, "STRING") for c in columns],
                write_disposition="WRITE_TRUNCATE",
            ),
        ).result()

    load()


setup_dim_fips_country()
