# Este codigo es una referencia de una peticion realizada a Claude
from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="ventas_forecast",
    start_date=datetime(2026, 10, 1),
    schedule="@weekly",
    catchup=False,
) as dag:
    validar = BashOperator(
        task_id="validar_datos",
        bash_command="python src/data_quality/validate_data.py",
    )
    entrenar = BashOperator(
        task_id="entrenar_modelo",
        bash_command="python src/models/train_model.py",
    )
    validar >> entrenar