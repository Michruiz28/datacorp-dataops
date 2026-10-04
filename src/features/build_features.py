import pandas as pd

FORMATOS_FECHA = ("%Y-%m-%d", "%d/%m/%Y")


def _parsear_fecha(serie: pd.Series) -> pd.Series:
    """Intenta parsear la fecha con los formatos admitidos."""
    for formato in FORMATOS_FECHA:
        try:
            return pd.to_datetime(serie, format=formato)
        except ValueError:
            continue
    raise ValueError("Formato de fecha_venta no reconocido")


def add_season_features(df: pd.DataFrame) -> pd.DataFrame:
    """Crea variables de temporada a partir de fecha_venta."""
    df = df.copy()
    df["fecha_venta"] = _parsear_fecha(df["fecha_venta"])
    df["mes"] = df["fecha_venta"].dt.month
    df["trimestre"] = df["fecha_venta"].dt.quarter
    return df