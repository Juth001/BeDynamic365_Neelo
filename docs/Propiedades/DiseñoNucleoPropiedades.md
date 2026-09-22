# Diseño: núcleo de propiedades (NEE - Propiedades)

**Estado: propuesta aprobada, pendiente de implementar.**

Módulo común que centraliza el conocimiento de "propiedad" para que el asistente de creación y todas las importaciones (Pleo, Airbnb, Booking y futuras) compartan configuración y lógica, en vez de duplicarla.

## Decisión de partida (Opción A)

Los tres destinos de la analítica por propiedad quedan así:

- **Ingresos de reservas** (Airbnb/Booking): se facturan como **producto + variante** (como hoy) y se analizan **por dimensión PROPIEDAD**. No generan movimientos de proyecto.
- **Costes**: se imputan al **proyecto de la propiedad, por tarea** — Pleo ya lo hace (facturas de compra con proyecto/tarea según el tipo de gasto); las comisiones de canal se suman en la fase 3.
- **Rentabilidad completa** por propiedad: cruce por dimensión (ingresos + gastos); el proyecto aporta el detalle de costes por tarea contra el presupuesto del asistente.

Motivo: en las líneas de venta, BC solo admite proyecto/tarea en líneas de tipo **Cuenta contable** (la validación de `Job Task No.` exige ese tipo; los campos existen en la tabla 37 pero no son utilizables en líneas de Producto). Meter los ingresos en el proyecto obligaría a abandonar el modelo producto+variantes de la facturación de reservas (Opción B, descartada). Si algún día se quiere el proyecto como cuadro de mando completo, esa opción queda documentada aquí como alternativa.

## Situación actual (duplicación a eliminar)

| Módulo | Configuración propia hoy |
|---|---|
| Asistente propiedades | Dimensiones PROPIEDAD y TIPOPROPIEDAD, plantilla de tareas, plantilla de producto, cliente proyectos |
| Pleo | "Project Dimension Code" propio; tarea por tipo de gasto (mapeo) con lookup a la plantilla del asistente |
| Airbnb | "Property Dimension Code" propio |
| Booking | El suyo propio |

Cuatro sitios donde configurar la misma dimensión; la lógica propiedad→proyecto→tarea nacería copiada en tres módulos.

## Módulo núcleo propuesto

Carpeta `NEE - Propiedades`, namespace `BeDynamic.PropertyCore`, IDs **82000–82019**.

| Objeto | Responsabilidad |
|---|---|
| Tabla + página **Property Core Setup** | Configuración única: dimensión de propiedad, dimensión de tipo de propiedad. (Futuro: cualquier dato transversal de propiedades.) |
| Tabla + página **Plantilla de tareas** | Se muda desde el asistente (hoy 82402/82403). Define la estructura canónica de tareas de cualquier proyecto de propiedad (10 Mobiliario … 70 Otro) con su línea de planificación opcional. |
| Codeunit **Property Resolver** | Dado un código de propiedad → qué existe en BC: producto, valor de dimensión, proyecto, ubicación de activo fijo. Único sitio que sabe que "propiedad = mismo código en todos los maestros". |
| Codeunit **Property Job Imputation** | Dado (código de propiedad, tarea) → valida y devuelve proyecto + tarea con las reglas ya escritas para Pleo: proyecto existe / abierto / no bloqueado, tarea existe y es de tipo Registro. Lo consumen Pleo (refactor), Airbnb y Booking (comisiones) y cualquier integración futura. |

**Lo que NO se centraliza**: el mapeo "concepto → tarea" es conocimiento de cada integración (tipo de gasto de Pleo → tarea; comisión de Airbnb → tarea) y vive en su mapeo/setup, junto a su cuenta contable, como ya hace Pleo.

## Uso por integración

- **Asistente de propiedades**: pasa a leer dimensiones y plantilla de tareas del núcleo. Sin cambio funcional.
- **Pleo**: refactor de `ResolveJobTask` para delegar en el imputador del núcleo. El mapeo de tipos de gasto conserva su columna "Tarea de proyecto" (el lookup pasa a la tabla del núcleo). Sin cambio funcional.
- **Airbnb / Booking**: campo nuevo "Tarea comisiones" en cada setup. En modo **cuenta contable**, el diario de comisión lleva proyecto + tarea (los diarios sí lo admiten); requiere añadir una tarea de comisiones a la plantilla (p.ej. **80 Comisiones Canal**, o una por canal). En modo **cargo a proveedor** no hay imputación en la importación: el cargo es un anticipo y el gasto real llega con la factura del proveedor del canal.
- **Ingresos**: sin cambios — dimensión PROPIEDAD en factura y asientos, como hoy.

## Fases

1. **Núcleo**: crear módulo con setup + plantilla de tareas + resolutor + imputador. La plantilla de tareas se mueve de carpeta pero **conserva su ID de tabla** (82402), así que los datos sobreviven; solo cambia el namespace de los objetos.
2. **Refactor sin cambio funcional**: asistente y Pleo consumen el núcleo. El setup del núcleo se siembra desde los setups existentes (dimensiones ya configuradas). Los campos de dimensión duplicados de los setups de módulo se mantienen como *override* opcional (vacío = usar el núcleo) o se marcan obsoletos con calma.
3. **Comisiones de canal**: tarea 80 en la plantilla, campo "Tarea comisiones" en setups de Airbnb y Booking, proyecto/tarea en sus diarios de comisión (modo cuenta contable).
4. **(Opcional, futuro)** Página/informe "Rentabilidad por propiedad": ingresos y gastos por dimensión + detalle de costes por tarea vs presupuesto del proyecto.

Fases 1 y 2 conviene hacerlas juntas (refactor de una tarde); la 3 detrás, independiente.

## Compatibilidad

- Ningún cambio de esquema destructivo: las tablas existentes no cambian de ID ni pierden campos ya publicados.
- El cambio de namespace de la plantilla de tareas no afecta a datos (el ID de tabla no cambia); solo hay que recompilar las referencias (mapeo de Pleo, asistente).
- Los campos de dimensión de los setups de módulo no se eliminan hasta que todo el mundo lea del núcleo.
