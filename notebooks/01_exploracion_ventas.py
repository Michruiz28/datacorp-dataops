# %% [markdown]
# Exploración de ventas (entorno DEV)
# Objetivo: revisar la calidad de los datos de ventas antes de modelar.
#
# Este archivo es un notebook exportado a .py: cada celda empieza con `# %%`.
# Se versiona el .py y no el .ipynb porque el .ipynb guarda salidas (tablas,
# gráficos) que pueden contener datos reales y hace ilegibles los cambios en Git.
### Archivo exploracion de ventas editado sobre una referencia dada por Claude

# %% Cargar datos
import pandas as pd

# En DEV se usan datos sintéticos. En un caso real se leería el dato versionado df = pd.read_csv("data/raw/ventas_2026-09.csv")
df = pd.DataFrame({
    "fecha_venta": ["2026-09-01", "2026-09-02", "2026-09-03", "2026-09-04"],
    "producto": ["A", "B", "A", "C"],
    "unidades": [10, 5, None, 8],
    "valor": [100000, 52000, 98000, 81000],
})

# %% Tamaño y tipos de datos
print(df.shape)
print(df.dtypes)

# %% Porcentaje de nulos por columna
print(df.isna().mean())

# %% Formato de las fechas
print(df["fecha_venta"].head())
# Hallazgo: en QA las fechas llegan como dd/mm/yyyy (ver punto 1.3 y el PR del 3.3).

# %% Resumen estadístico
print(df.describe())