"""手動觸發,載入 GDELT 的 CAMEO 對照表到 mart。"""

import os
from datetime import datetime

from airflow.decorators import dag, task

BASE_URL = "https://www.gdeltproject.org/data/lookups"
PROJECT = os.environ["GCP_PROJECT_ID"]
LOCATION = os.environ.get("BQ_LOCATION", "US")

LOOKUPS = {
    "dim_cameo": ("CAMEO.eventcodes.txt", ["cameo_code", "description"]),
    "dim_cameo_country": ("CAMEO.country.txt", ["country_code", "country_name"]),
    "dim_cameo_type": ("CAMEO.type.txt", ["type_code", "type_name"]),
}


@dag(
    dag_id="setup_dim_cameo",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
)
def setup_dim_cameo():
    @task
    def load(table, source_file, columns):
        import pandas as pd
        from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
        from google.cloud import bigquery

        # dtype=str 才能保留 "010" 這類資料
        df = pd.read_csv(
            f"{BASE_URL}/{source_file}", sep="\t", dtype=str, header=0, names=columns
        )
        schema = [bigquery.SchemaField(c, "STRING") for c in columns]

        if table == "dim_cameo":
            # root_code 01-05 / 06-09 / 10-13 / 14-20 依序對應 QuadClass 1-4
            df["root_code"] = df["cameo_code"].str[:2]
            df["quad_class"] = pd.cut(
                df["root_code"].astype(int), [0, 5, 9, 13, 20], labels=[1, 2, 3, 4]
            ).astype(int)
            df["is_conflict"] = df["quad_class"] >= 3
            schema += [
                bigquery.SchemaField("root_code", "STRING"),
                bigquery.SchemaField("quad_class", "INT64"),
                bigquery.SchemaField("is_conflict", "BOOL"),
            ]

        client = BigQueryHook().get_client(project_id=PROJECT, location=LOCATION)
        client.load_table_from_json(
            df.to_dict("records"),
            f"{PROJECT}.mart.{table}",
            job_config=bigquery.LoadJobConfig(
                schema=schema, write_disposition="WRITE_TRUNCATE"
            ),
        ).result()

    for table, (source_file, columns) in LOOKUPS.items():
        load.override(task_id=f"load_{table}")(table, source_file, columns)


setup_dim_cameo()
