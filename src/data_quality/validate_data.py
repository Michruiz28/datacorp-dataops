import pandas as pd

MAX_NULOS = 0.10  


def validar_nulos(df: pd.DataFrame, max_nulos: float = MAX_NULOS) -> None:
    """Falla si alguna columna supera el porcentaje de nulos permitido."""
    ratios = df.isna().mean()
    malas = ratios[ratios > max_nulos]
    if not malas.empty:
        raise ValueError(f"Columnas con nulos sobre el umbral")