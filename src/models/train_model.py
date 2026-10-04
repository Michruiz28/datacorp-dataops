# Este codigo es una referencia de una peticion realizada a Claude
import yaml

def cargar_parametros(ruta: str = "config/model_params.yaml") -> dict:
    with open(ruta, encoding="utf-8") as f:
        return yaml.safe_load(f)


if __name__ == "__main__":
    params = cargar_parametros()
    print(f"Entrenando modelo {params['model']['name']} con {params['model']['algorithm']}")