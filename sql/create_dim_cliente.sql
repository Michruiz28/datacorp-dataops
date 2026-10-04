-- Tabla clientes con el MDM
CREATE TABLE IF NOT EXISTS dim_cliente (
    id_cliente_maestro VARCHAR(20) PRIMARY KEY,
    tipo_documento     VARCHAR(5)  NOT NULL,
    numero_documento   VARCHAR(20) NOT NULL,
    nombre             VARCHAR(120),
    estado_cliente     VARCHAR(15) NOT NULL,
    fecha_corte        DATE        NOT NULL
);