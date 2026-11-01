import os
from datetime import datetime
from pathlib import Path

from airflow.decorators import dag, task
from airflow.models.param import Param

SQL_FOLDER_PATH = Path("/opt/airflow/sql")
PROJECT = os.environ["GCP_PROJECT_ID"]
LOCATION = os.environ.get("BQ_LOCATION", "US")


def run_sql(relative_path: str, **sql_params) -> None:
    from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
    from jinja2 import StrictUndefined, Template

    client = BigQueryHook().get_client(project_id=PROJECT, location=LOCATION)
    sql = Template(
        (SQL_FOLDER_PATH / relative_path).read_text(), undefined=StrictUndefined
    ).render(params={"project": PROJECT, **sql_params})
    client.query(sql).result()


@dag(
    dag_id="gdelt_daily_elt",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    params={"target_execution_date": Param(None, type=["null", "string"])},
)
def gdelt_daily_elt():
    @task
    def extract_stg_event(ds=None, run_id=None, params=None) -> str:
        target_execution_date = params["target_execution_date"] or ds
        run_sql(
            "extract/stg_event.sql",
            target_execution_date=target_execution_date,
            batch_id=run_id,
        )
        return target_execution_date

    @task
    def merge_fct_event(target_execution_date: str, run_id=None):
        run_sql(
            "transform/merge_fct_event.sql",
            target_execution_date=target_execution_date,
            batch_id=run_id,
        )

    @task
    def check_quality(): ...

    @task
    def refresh_mviews(): ...

    target_execution_date = extract_stg_event()
    (merge_fct_event(target_execution_date) >> check_quality() >> refresh_mviews())


gdelt_daily_elt()
