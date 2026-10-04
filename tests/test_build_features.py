import pandas as pd

from src.features.build_features import add_season_features


def test_formato_iso():
    df = pd.DataFrame({"fecha_venta": ["2026-09-15"]})
    out = add_season_features(df)
    assert out.loc[0, "mes"] == 9
    assert out.loc[0, "trimestre"] == 3