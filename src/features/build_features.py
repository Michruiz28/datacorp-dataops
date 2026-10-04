import pandas as pd


def add_season_features(df: pd.DataFrame) -> pd.DataFrame:
    """Crea variables de temporada a partir de fecha_venta."""
    df = df.copy()
    df["fecha_venta"] = pd.to_datetime(df["fecha_venta"], format="%Y-%m-%d")
    df["mes"] = df["fecha_venta"].dt.month
    df["trimestre"] = df["fecha_venta"].dt.quarter
    return df
