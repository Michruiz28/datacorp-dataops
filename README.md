\# DataCorp Analytics - Taller DataOps - Michelle Ruiz



Repositorio de la parte practica del taller donde desarrollamos el diseño de entornos aislados, gestión de datos maestros (MDM) y estrategias de control y replicabilidad.



\## Actividad 1: Diseño de Entornos Aislados



\### 1.1 Estructura de los tres entornos



| Entorno | Propósito | Acceso | Datos | Infraestructura | Control de código |

|---|---|---|---|---|---|

|DEV| Zona de experimentación donde exploramos datos y probamos modelos sin riesgo. | Científicos e ingenieros de datos (lectura/escritura amplia). | Sintéticos o muestra reducida y anonimizada. Nunca datos reales de clientes. | Recursos pequeños y efímeros (EC2 pequeña, bucket S3 de desarrollo, BD local o contenedor). | Ramas feature y commits libres en la rama propia. |

|QA| Validar de extremo a extremo (integración, regresión, rendimiento) antes de llegar a clientes. | Equipo de QA, DataOps y el pipeline CI/CD. Científicos solo lectura de resultados. | Réplica de PROD con PII anonimizada. | Misma arquitectura que PROD a menor escala (bucket S3 y BD de staging). | Solo se llega por Pull Request aprobado y merge a main para despliegue automático. |

|PROD| Servir a los clientes con un estado estable y confiable. | Muy restringido, solo el pipeline de CD y operaciones con roles de mínimo privilegio para que nadie pueda modificar a mano | Datos reales completos, con cifrado y auditoría. | RDS con alta disponibilidad (Multi-AZ), backups automáticos, monitoreo y alertas. | Inmutable una vez desplegado ya que permite solo versiones etiquetadas (`v1.2.0`) con aprobación manual. |



Justificación de las decisiones



\-En DEV permite libertad porque el costo de un error es cero (sin datos reales ni clientes). Los datos sintéticos evitan fugas de información sensible y cumplen con la Ley 1581 de 2012 de protección de datos personales.

\-QA debe parecerse a producción para que las pruebas sean confiables. Se anonimizan los datos personales porque más personas acceden a este entorno y el riesgo de fuga es mayor.

\- En PROD el acceso restringido y el código inmutable garantizan que sea la fuente de la verdad y que todo cambio quede trazable y reversible. Responde directamente a los problemas presentados de DataCorp.



\### 1.2 Diagrama de flujo de un cambio en un modelo predictivo



!\[Flujo de un cambio en un modelo predictivo de DEV a PROD](docs/img/flujo\_cambio\_datacorp.png)



Explicación de cada etapa



1\. Push a Git (feature branch): el cambio se guarda en una rama aislada; así main nunca se contamina y queda trazabilidad.

2\. Creación de entorno de preview: al abrir el Pull Request, se crea automáticamente un entorno temporal para probar el cambio de forma aislada; se destruye al cerrar el PR.

3\. Pruebas automatizadas: unit tests (pytest), validación de esquema y nulos, y métricas mínimas del modelo. Si fallan, el cambio vuelve a DEV.

4\. Promoción a staging: tras el code review y el merge a `main`, el pipeline despliega a QA/Staging, donde se ejecutan pruebas de integración, regresión y rendimiento con datos anonimizados.

5\. Liberación a producción: con la aprobación manual de un responsable, se etiqueta la versión y el pipeline la despliega. Nunca se hace a mano.

6\. Migraciones de datos: cambios de esquema o tablas, con backup previo y plan de reversa.

7\. Disponibilidad en vivo: se ejecutan smoke tests; si pasan, el cambio queda activo para los clientes bajo monitoreo continuo. Si fallan, se hace rollback a la versión anterior.



\### 1.3 Simulación: falla de un modelo en QA



\*\*Escenario:\*\* el modelo `demand\_forecast v1.4.0` pasa las pruebas en DEV, pero en QA su MAPE sube de 12 % a 31 % (umbral máximo permitido: 15 %). La causa es que la columna `fecha\_venta` llega en otro formato en QA, lo que rompe las variables de temporada.



\*\*Protocolo de actuación\*\*



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



\*\*Validaciones que habrían evitado el problema:\*\* validación de esquema y tipos (Great Expectations, Pandera), calidad de datos (nulos, rangos, duplicados), umbrales de métricas contra un modelo base, pruebas de regresión contra la versión en PROD y detección de drift.



\*\*Por qué no llega a producción:\*\* (1) la promoción exige que todas las pruebas de staging pasen; (2) hay aprobación manual antes de PROD; (3) PROD solo acepta versiones etiquetadas desplegadas por el pipeline.

