# DataCorp Analytics - Taller DataOps - Michelle Ruiz

Repositorio de la parte práctica del taller donde desarrollamos el diseño de entornos aislados, gestión de datos maestros (MDM) y estrategias de control y replicabilidad.

## Actividad 1: Diseño de Entornos Aislados

### 1.1 Estructura de los tres entornos

| Entorno | Propósito | Acceso | Datos | Infraestructura | Control de código |
|---|---|---|---|---|---|
| DEV | Zona de experimentación donde exploramos datos y probamos modelos sin riesgo. | Científicos e ingenieros de datos (lectura/escritura amplia). | Sintéticos o muestra reducida y anonimizada. Nunca datos reales de clientes. | Recursos pequeños y efímeros (EC2 pequeña, bucket S3 de desarrollo, BD local o contenedor). | Ramas feature y commits libres en la rama propia. |
| QA | Validar de extremo a extremo (integración, regresión, rendimiento) antes de llegar a clientes. | Equipo de QA, DataOps y el pipeline CI/CD. Científicos solo lectura de resultados. | Réplica de PROD con PII anonimizada. | Misma arquitectura que PROD a menor escala (bucket S3 y BD de staging). | Solo se llega por Pull Request aprobado y merge a main para despliegue automático. |
| PROD | Servir a los clientes con un estado estable y confiable. | Muy restringido, solo el pipeline de CD y operaciones con roles de mínimo privilegio para que nadie pueda modificar a mano. | Datos reales completos, con cifrado y auditoría. | RDS con alta disponibilidad (Multi-AZ), backups automáticos, monitoreo y alertas. | Inmutable una vez desplegado, ya que permite solo versiones etiquetadas (`v1.2.0`) con aprobación manual. |

**Justificación de las decisiones**

- **DEV** permite libertad porque el costo de un error es cero (sin datos reales ni clientes). Los datos sintéticos evitan fugas de información sensible y cumplen con la Ley 1581 de 2012 de protección de datos personales.

- **QA** debe parecerse a producción para que las pruebas sean confiables. Se anonimizan los datos personales porque más personas acceden a este entorno y el riesgo de fuga es mayor.

- **PROD**: el acceso restringido y el código inmutable garantizan que sea la fuente de la verdad y que todo cambio quede trazable y reversible. Responde directamente a los problemas presentados de DataCorp.

### 1.2 Diagrama de flujo de un cambio en un modelo predictivo

![Flujo de un cambio en un modelo predictivo de DEV a PROD](docs/img/flujo_cambio_datacorp.png)

**Si la imagen del flujo no se logra visualizar en este archivo README, revisar en los docs de la entrega del taller practico**

**Explicación de cada etapa**

1. **Push a Git (feature branch):** el cambio se guarda en una rama aislada; así main nunca se contamina y queda trazabilidad.

2. **Creación de entorno de preview:** al abrir el Pull Request, se crea automáticamente un entorno temporal para probar el cambio de forma aislada; se destruye al cerrar el PR.

3. **Pruebas automatizadas:** unit tests (pytest), validación de esquema y nulos, y métricas mínimas del modelo. Si fallan, el cambio vuelve a DEV.

4. **Promoción a staging:** tras el code review y el merge a `main`, el pipeline despliega a QA/Staging, donde se ejecutan pruebas de integración, regresión y rendimiento con datos anonimizados.

5. **Liberación a producción:** con la aprobación manual de un responsable, se etiqueta la versión y el pipeline la despliega. Nunca se hace a mano.

6. **Migraciones de datos:** cambios de esquema o tablas, con backup previo y plan de reversa.

7. **Disponibilidad en vivo:** se ejecutan smoke tests; si pasan, el cambio queda activo para los clientes bajo monitoreo continuo. Si fallan, se hace rollback a la versión anterior.

### 1.3 Simulación: falla de un modelo en QA

**Escenario:** el modelo pasa las pruebas en DEV, pero en QA su MAPE sube de 12 % a 31 % (el umbral máximo permitido es 15 %). La causa es que la columna `fecha_venta` llega en otro formato en QA, lo que rompe las variables de temporada.

**Protocolo de actuación**

*Nota: las soluciones se plantearon a partir de una guía dada por Claude al entregarle este escenario.*

| Paso | Acción | Herramienta |
|---|---|---|
| 1. Detección | El pipeline detecta MAPE > 15 % y marca el job como fallido. | GitHub Actions, MLflow |
| 2. Bloqueo | Las reglas de protección de rama impiden el merge y la promoción a PROD queda bloqueada automáticamente. | GitHub branch protection |
| 3. Notificación | Alerta al equipo con enlace al log, versión y commit responsable. | Slack/Email desde GitHub Actions |
| 4. Diagnóstico | Se revisan logs, se comparan datos DEV vs QA y métricas contra el modelo base. | Logs del pipeline, MLflow |
| 5. Reproducción | Se recrea el fallo en DEV con el mismo commit y datos (replicabilidad). | Git, DVC, IaC |
| 6. Corrección | Se corrige en una rama `fix/formato-fecha` y se agregan pruebas para ese caso. | Git, pytest |
| 7. Nueva validación | El fix recorre de nuevo todo el flujo: PR, preview, pruebas y staging. | CI/CD |
| 8. Registro | Se documenta el incidente y la lección aprendida (post-mortem sin culpables). | Issue de GitHub |

**Validaciones que habrían evitado el problema:** validación de esquema y tipos (Great Expectations), calidad de datos (nulos, rangos, duplicados), umbrales de métricas contra un modelo base, pruebas de regresión contra la versión en PROD y detección de drift.

**Por qué no llega a producción:** la promoción exige que todas las pruebas de staging pasen, además hay aprobación manual antes de PROD y, finalmente, PROD solo acepta versiones etiquetadas desplegadas por el pipeline.

## Actividad 2: Implementación de MDM

### 2.1 Entidades maestras de DataCorp Analytics

| Entidad maestra | Atributos clave | Fuentes de datos | Reglas de calidad | Data owner |
|---|---|---|---|---|
| Cliente | id_cliente_maestro, tipo y número de documento, nombres, correo, teléfono, ciudad, fecha de registro, estado_cliente | CRM, e-commerce, POS de las tiendas, programa de fidelización | Documento único y válido, correo con formato válido, teléfono normalizado (+57), sin duplicados y campos obligatorios completos | Director Comercial |
| Producto | id_producto_maestro, SKU, descripción, categoría, marca, precio de lista, unidad de medida, estado | ERP, catálogo de proveedores, e-commerce | SKU único; categoría dentro de la taxonomía oficial; precio mayor a 0; sin descripciones vacías | Gerente de Categorías |
| Proveedor | id_proveedor_maestro, NIT, razón social, contacto, condiciones de pago, país, estado | ERP, módulo de compras, contratos | NIT único y válido; razón social normalizada y contacto | Director de Compras |
| Ubicación (tienda o sucursal) | id_ubicacion, nombre, tipo (tienda, bodega, online), dirección, ciudad, coordenadas, región, estado | ERP, POS, sistema de logística | Dirección estandarizada, coordenadas válidas, ciudad y región, código único | Director de Operaciones |
| Finanzas | id_centro_costo, cuenta contable, descripción, moneda, responsable, vigencia | ERP financiero, sistema contable | Código único, moneda válida (COP, USD), vigencia coherente (fecha inicio menor que fecha fin), responsable asignado | Director Financiero (CFO) |

### 2.2 Flujo de consolidación hacia el registro maestro

![Flujo de consolidación MDM de DataCorp Analytics](docs/img/flujo_mdm_datacorp.png)

**Si la imagen del flujo no se logra visualizar en este archivo README, revisar en los docs de la entrega del taller practico**

**Explicación de cada componente**

1. **Fuentes transaccionales:** CRM, ERP, POS, e-commerce y archivos de proveedores. Cada una guarda los datos a su manera, con formatos y claves distintas.
2. **Ingesta a zona de staging:** los datos se copian sin modificarlos a una zona de paso, para no afectar a los sistemas de origen.
3. **Limpieza y estandarización:** se corrigen formatos (fechas, teléfonos, direcciones), se eliminan espacios y se unifican catálogos.
4. **Validación de calidad:** se aplican las reglas del punto 2.1. Los registros que no cumplen van a una cola de excepciones que revisa el data steward.
5. **Matching y deduplicación:** se identifican registros que representan a la misma entidad (por ejemplo, el mismo cliente en CRM y POS).
6. **Resolución de conflictos (survivorship):** cuando hay valores distintos para un mismo atributo, se elige el correcto según reglas definidas (fuente más confiable o dato más reciente).
7. **Registro maestro (golden record):** versión única y confiable de cada entidad, con identificador maestro y trazabilidad de su origen. Aquí actúa la gobernanza: los cambios requieren aprobación.
8. **Sincronización hacia sistemas transaccionales:** el registro maestro se publica de vuelta a CRM, ERP y POS para que todos usen los mismos datos.
9. **Sincronización hacia sistemas analíticos:** el registro maestro alimenta el data warehouse, el feature store y los dashboards, de modo que los modelos y reportes se construyen sobre la misma fuente de la verdad.

### 2.3 Políticas de gobernanza del dato maestro "Cliente"

**1. Definición de "cliente activo"**

Cliente que tiene al menos una compra completada (no cancelada ni devuelta) en los últimos 12 meses contados desde la fecha de corte.

| Estado | Criterio |
|---|---|
| Activo | Última compra completada hace 12 meses o menos |
| Inactivo | Última compra hace más de 12 y hasta 24 meses |
| Perdido | Última compra hace más de 24 meses |
| Prospecto | Registrado pero sin compras |

**2. Reglas de limpieza y duplicación**
**Puntuaciones referidas por Claude**

- Nombres: sin espacios dobles, en formato Título; sin caracteres especiales.
- Correo: en minúsculas y con formato válido.
- Teléfono: formato nacional.
- Documento: tipo y número obligatorios; no se admiten ceros ni valores de prueba.
- Duplicados exactos: mismo tipo y número de documento. Se fusionan automáticamente.
- Duplicados probables: coincidencia aproximada de nombre, fecha de nacimiento y correo, con puntuación de similitud:
  - Mayor o igual a 0.95: fusión automática.
  - Entre 0.80 y 0.95: revisión manual del data.
  - Menor a 0.80: revisión manual para confirmar que son registros distintos.
- Todas las fusiones quedan registradas y se pueden revertir.
- Regla de supervivencia: ante conflictos prevalece el dato verificado más reciente de la fuente más confiable.

**3. Flujo de aprobación para cambios**

1. Solicitud de cambio (usuario autorizado o proceso automático).
2. Validación automática de las reglas de calidad.
3. Revisión del data steward de Clientes.
4. Aprobación del data owner (Director Comercial) si el cambio afecta atributos críticos (documento, estado, definición de cliente activo).
5. Publicación en el registro maestro y sincronización a los sistemas.
6. Registro en el log de auditoría (quién, qué, cuándo y por qué).

**4. Políticas de acceso y seguridad**

- Control de acceso por roles y principio de mínimo privilegio.
- Solo el data steward y los procesos autorizados escriben en el maestro; los demás roles tienen lectura.
- Datos personales (PII) anonimizados en DEV y QA.
- Cifrado en reposo y en tránsito.
- Auditoría constante de accesos y cambios.
- Cumplimiento de la Ley 1581 de 2012: autorización del titular, derecho de consulta, rectificación y supresión, y tiempos de retención definidos.

### 2.4 Simulación: conflicto en la definición de "cliente activo"

**Escenario (datos hipotéticos):** dos fuentes manejan definiciones distintas.

| Fuente | Definición de "cliente activo" | Clientes activos reportados |
|---|---|---|
| CRM (área de Marketing) | Inició sesión o abrió un correo en los últimos 90 días | 120.000 |
| ERP/POS (área Comercial) | Realizó al menos una compra en los últimos 12 meses | 85.000 |

**Problema:** el modelo de predicción de abandono se entrenó con la definición del CRM, y el dashboard de ventas usa la del ERP. Los reportes no coinciden, la dirección desconfía de las cifras y nadie puede explicar por qué el modelo da otros resultados.

**Cómo lo resuelve MDM**

1. **Detección:** el proceso de matching evidencia que el mismo atributo tiene reglas distintas en cada fuente.
2. **Decisión de gobernanza:** el comité de gobernanza, con el data owner de Cliente, define una única definición oficial con la compra completada en los últimos 12 meses.
3. **Cálculo centralizado:** el atributo estado_cliente se calcula una sola vez en el registro maestro y se distribuye a todos los sistemas.
4. **Atributos separados:** la definición del CRM no se pierde solo se conserva con otro nombre (usuario_activo_app) para evitar confusiones.
5. **Versionado:** la definición queda documentada como v1.0 con fecha de vigencia en el glosario.

**Impacto en la replicabilidad de modelos**

- Cada modelo registra la versión de la definición con la que se entrenó (por ejemplo, `definicion_cliente_activo=v1.0`)
- Si la definición cambia a v2.0, los modelos antiguos pueden recrearse con v1.0 y compararse con los nuevos.
- Sin MDM no se podría saber con cuál definición se entrenó cada modelo, y los resultados serían imposibles de replicar.