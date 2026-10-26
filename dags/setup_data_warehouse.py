import os
from datetime import datetime
from pathlib import Path

from airflow.decorators import dag, task

DDL_PATH = Path("/opt/airflow/sql/ddl")
PROJECT = os.environ["GCP_PROJECT_ID"]
LOCATION = os.environ.get("BQ_LOCATION", "US")


def bq_client():
    from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook

    return BigQueryHook().get_client(project_id=PROJECT, location=LOCATION)


@dag(
    dag_id="setup_data_warehouse",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
)
def setup_dw():
    @task
    def create_datasets():
        from google.cloud import bigquery

        client = bq_client()
        # sql/ddl/<dataset>/ 的資料夾名稱就是 dataset 名稱
        for folder in DDL_PATH.iterdir():
            dataset = bigquery.Dataset(f"{PROJECT}.{folder.name}")
            dataset.location = LOCATION
            client.create_dataset(dataset, exists_ok=True)

    @task
    def create_table(ddl_file):
        from jinja2 import StrictUndefined, Template

        sql = Template(Path(ddl_file).read_text(), undefined=StrictUndefined).render(
            params={"project": PROJECT}
        )
        bq_client().query(sql).result()

    tables = [
        create_table.override(task_id=f"create_{f.stem}")(str(f))
        for f in sorted(DDL_PATH.glob("*/*.sql"))
    ]
    create_datasets() >> tables


setup_dw()
