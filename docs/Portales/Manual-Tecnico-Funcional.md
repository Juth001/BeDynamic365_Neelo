# Manual técnico y funcional — Importación de portales de venta (Airbnb y Booking)

**Módulo de la app:** Neelo Core Solutions by BeDynamic · **Namespace:** `BeDynamic.PortalImport` (con apoyo de `BeDynamic.PropertyManagement` y `Neelo.RecurringInvoicing`)
**Plataforma:** Business Central 28 (localización española)
**Rango de objetos:** 82600–82604
**Última actualización:** 2026-09-15

> Este manual describe la importación de los CSV de **Airbnb** (export de transacciones) y **Booking** (export de payouts): configuración, formato de cada fichero, flujo de trabajo, contabilización y **todas las validaciones** de cada paso. El resumen de diseño está en el [README](README.md) del módulo.

---

## 1. Visión general

La herramienta carga en una hoja de trabajo los movimientos que exportan los portales, los valida contra la configuración y el mapeo de alojamientos, y contabiliza cada uno según su tipo:

| Tipo de movimiento | Airbnb | Booking | Qué se contabiliza |
|---|---|---|---|
| **Reserva** | Fila *Reserva* / *Reservation* | Fila *Reserva* con estado OK (o cancelada, si se configura) | **Factura de venta** al cliente genérico por el **bruto** (IVA incluido) con una línea del producto de la propiedad, más un **diario de comisiones** que descuenta de esa factura lo que retiene el portal. El cliente queda pendiente solo del neto. |
| **Ajuste de resolución** | Filas cuyo tipo contiene *Ajuste* / *Resolución* | — | Igual que una reserva; si el importe es negativo, **abono de venta** con la comisión en signo invertido. |
| **Otro** | Cualquier otro tipo | Cualquier otro tipo | Igual que una reserva o un ajuste según el signo. El código de reserva es opcional. |
| **Payout** | Fila *Payout* | Fila *(Payout)* | **Diario**: cargo al banco del canal y abono al cliente genérico como pago a cuenta, sin aplicar. Activable por configuración. |

Puntos clave del diseño:

- El **canal se detecta solo** por la cabecera del CSV. No hay que elegir Airbnb o Booking.
- Cada movimiento tiene un **Id. externo** con prefijo de canal (`AB:` / `BK:`) que impide importarlo dos veces, en cualquier lote y también contra el histórico archivado.
- La **propiedad** se resuelve con el **mapeo de alojamientos** (nombre del alojamiento en Airbnb, ID numérico en Booking) y se factura como **producto** con el mismo código, con la **variante** del mapeo o la variante por defecto.
- Todo lleva las dimensiones de **propiedad** y de **canal**.
- El **registro automático** se toma del parámetro *Registrar automáticamente* de la configuración de facturación recurrente. Activo: factura y diarios se registran. Desactivado: la factura queda en borrador y los diarios se dejan en el libro y sección de pagos configurados.
- Cada paso deja **marca en la línea** (borrador creado, factura registrada, comisión registrada), de modo que reprocesar una línea que falló a medias no duplica documentos.

```
   ┌──────────────────┐    ┌──────────────────┐    ┌──────────────┐    ┌──────────────┐
   │ 1. IMPORTAR CSV  │ ─▶ │ 2. REVISAR /     │ ─▶ │ 3. PROCESAR  │ ─▶ │ 4. ARCHIVAR  │
   │ (canal auto,     │    │    REVALIDAR     │    │ (factura +   │    │ (histórico)  │
   │  valida al cargar)│    │ (mapeo, estado)  │    │  comisión /  │    │              │
   │                  │    │                  │    │  payout)     │    │              │
   └──────────────────┘    └──────────────────┘    └──────────────┘    └──────────────┘
     Lote PT…               Validada / Error /      Registrada           Fuera de la hoja,
     Pendiente → Validada    Omitida                                       sigue deduplicando
```

---

## 2. Conceptos clave

| Concepto | Descripción |
|---|---|
| **Lote** | Cada importación crea un lote `PT` + fecha y hora (p. ej. `PT20260915103015`). La hoja queda filtrada por él tras importar. |
| **Canal** | Portal de origen del movimiento: Airbnb o Booking (el enum contempla otros para el futuro). Determina el formato del CSV, el proveedor, el banco de payouts, el valor de dimensión de canal y la unidad de medida de ventas. |
| **Portal** | Registro del maestro *Portales* del módulo de propiedades. Cada canal se ancla al portal que tenga ese *Canal de importación* (solo uno por canal). Se autocrea (`AIRBNB`, `BOOKING`) si falta. |
| **Alojamiento y mapeo** | Clave del alojamiento en el CSV: el **nombre** en Airbnb, el **ID** en Booking. El mapeo de alojamientos asigna cada clave (por portal) a una **propiedad** y, opcionalmente, una **variante**. |
| **Propiedad (producto)** | Código de propiedad = código de producto = valor de dimensión, tal y como los crea el asistente de propiedades. La reserva se factura con ese producto. |
| **Variante** | Variante del producto con la que se factura: la del mapeo, si no la de la línea, y si no la *Variante por defecto* de la configuración. |
| **Cliente genérico** | Cliente único al que se facturan todas las reservas de los portales. El código de reserva va como nº de documento externo. |
| **Comisiones** | Lo que retiene el portal: comisión de servicio y comisión por pago rápido (Airbnb); comisión, cargo por servicio de pagos e IVA (Booking). Se descuentan de la factura contra el **proveedor del canal** o contra una **cuenta contable**. |
| **Payout** | Transferencia del portal al banco. Se contabiliza banco contra cliente genérico, sin aplicar. En Booking, el *grupo de payout* enlaza el pago con sus reservas. |
| **Id. externo** | Identificador único del movimiento para deduplicar: `AB:P:<referencia>`, `AB:R:<confirmación>:<fecha>:<importe>`, `AB:A:…`, `AB:O:…`, `BK:P:<grupo>`, `BK:R:<referencia>:<grupo>`, `BK:O:…`. |
| **Estados** | *Pendiente*, *Validada*, *Error*, *Registrada*, *Omitida*. El estado es **editable** en la hoja para forzar casos concretos. |

---

## 3. Objetos implicados (referencia técnica)

| Objeto | ID | Nombre | Papel |
|---|---|---|---|
| Table | 82600 | BeDyn Portal Setup | Configuración única del módulo (apartado 4.1). |
| Table | 82601 | BeDyn Portal Import Buffer | Hoja de trabajo (staging): datos del CSV, propiedad y variante resueltas, estado, mensajes, marcas de reintento. |
| Table | 82602 | BeDyn Portal Listing Mapping | Mapeo de alojamientos (portal + clave) a propiedad y variante. |
| Table | 82603 | BeDyn Portal Import Archive | Histórico de líneas archivadas, con fecha y usuario. Participa en la deduplicación. |
| TableExt | 82600 | BeDyn Portal Ext | Campo *Canal de importación* en el maestro *Portal* (82503 del módulo de propiedades), único por canal. |
| Page | 82600 | BeDyn Portal Setup | Configuración. |
| Page | 82601 | BeDyn Portal Import Worksheet | Hoja *Importación Portales de Venta*: importar, revalidar, procesar, ver documento, archivar. |
| Page | 82602 | BeDyn Portal Listing Mapping | Mapeo de alojamientos. |
| Page | 82603 | BeDyn Portal Import Archive | Histórico. |
| PageExt | 82600 | BeDyn Portal List Ext | Columna *Canal de importación* en la lista de portales. |
| Codeunit | 82600 | BeDyn Portal CSV Reader | Detección de codificación y canal, parseo, deduplicación e inserción en la hoja. |
| Codeunit | 82601 | BeDyn Portal Validation | Validación de cada línea (apartado 7.2). Crea portal, mapeo, unidad de medida y variante cuando la configuración lo permite. |
| Codeunit | 82602 | BeDyn Portal Import Process | Contabilización: factura o abono, diario de comisiones y diario de payout (apartado 8). |
| Codeunit | 82604 | BeDyn Portal Channel Mgt. | Puente entre el canal y el maestro de portales. |
| Enum | 82600–82603 | Channel, Row Type, Line Status, Commission Mode | Canal, tipo de movimiento, estado de línea y tratamiento de comisiones. |
| PermissionSet | 82600 | BeDyn Portal Import | Permisos del módulo. |
| Page | 82538 | BeDyn Property Manager RC | Role Center: *Importaciones → Hoja importación portales*, *Archivos → Histórico importación portales*, *Portales → Portales*, *Configuración → Configuración portales* y *Mapeo alojamientos portales*. |

---

## 4. Configuración previa (checklist)

### 4.1 Configuración de portales

Role Center → *Configuración* → **Configuración portales**.

| Pestaña | Campo | Uso |
|---|---|---|
| General | **Codificación del fichero** | Solo se usa cuando el CSV no trae BOM. *UTF-8* intenta leerlo como UTF-8 y, si no es legible, como Windows; *Windows (ANSI)* fuerza ANSI. Si los acentos salen mal, cambie esta opción. |
| General | **Contabilizar payouts** | Activo: las filas Payout generan el diario banco contra cliente genérico. Desactivado: se marcan *Omitida*. |
| General | **Contabilizar reservas canceladas** | Solo Booking. Activo: las reservas con estado *Cancelada* se facturan como las OK. Desactivado: se marcan *Omitida* para revisión manual. |
| General | **Libro diario de pagos / Sección diario de pagos** | Obligatorios cuando el registro automático está desactivado: ahí se dejan las líneas de comisiones y payouts sin registrar. |
| Ventas | **Cliente genérico** | Obligatorio. Cliente de todas las facturas de reservas. |
| Ventas | **Grupo IVA producto (ventas)** | Obligatorio. Se fuerza en la línea de la factura; los importes vienen con IVA incluido y BC calcula la base hacia atrás. |
| Ventas | **Variante por defecto** | Variante que se usa cuando ni el mapeo ni la línea indican una. Cada producto de propiedad debe tenerla (o activar la autocreación). Vacía: las líneas se crean sin variante. |
| Ventas | **Auto-crear variante por defecto** | Si el producto no tiene la variante efectiva, la validación la crea con descripción "Descripción producto - Variante". |
| Comisiones | **Tratamiento comisiones** | *Cargo a proveedor*: lo retenido se carga al proveedor del canal como pago a cuenta, a netear con su factura real. *Cuenta contable*: lo retenido va a la cuenta de comisiones. |
| Comisiones | **Cuenta comisiones** | Obligatoria en modo cuenta contable. Cuenta de registro con *Registro directo*. |
| Comisiones | **Cuenta IVA comisiones** | Opcional, modo cuenta contable: el IVA que retiene Booking va a esta cuenta; vacía, va a la de comisiones. |
| Airbnb | **Proveedor Airbnb** | Obligatorio en modo cargo a proveedor cuando hay comisiones. |
| Airbnb | **Banco payouts Airbnb** | Obligatorio para contabilizar payouts de Airbnb. |
| Airbnb | **Valor de canal Airbnb** | Valor de la dimensión de canal (p. ej. `AIRBNB`). Obligatorio si hay dimensión de canal configurada. |
| Airbnb | **Ud. medida ventas Airbnb** | Normalmente noches. Con noches informadas, la línea lleva cantidad = noches y precio = bruto / noches. Se crea en el producto con factor 1 si falta. Vacía: cantidad 1 y el bruto como precio. |
| Booking | **Proveedor Booking / Banco payouts Booking / Valor de canal Booking / Ud. medida ventas Booking** | Lo mismo para Booking. |
| Dimensiones | **Dimensión para la propiedad** | Dimensión donde se vuelca el código de propiedad (p. ej. `PROPIEDAD`). Vacía: la propiedad no se traslada como dimensión. |
| Dimensiones | **Auto-crear valores de dimensión** | Crea el valor de dimensión de la propiedad al contabilizar si no existe (con el nombre del mapeo o del alojamiento). Desactivado, la línea da error al procesar. |
| Dimensiones | **Auto-crear mapeo de alojamientos** | Da de alta los alojamientos desconocidos en el mapeo (sin propiedad) y el portal del canal si falta. |
| Dimensiones | **Dimensión para el canal** | Dimensión que identifica el canal (p. ej. `CANAL`). Vacía: el canal no se traslada. |

### 4.2 Registro automático

*Configuración facturación recurrente* → **Registrar automáticamente**. Es el mismo parámetro que usa la importación de colaboradores. Activo: factura o abono y diarios se registran directamente. Desactivado: el documento queda en borrador, las líneas de diario se dejan en el libro y sección de pagos sin aplicación, y el usuario aplica y registra.

### 4.3 Maestro de portales

Role Center → *Portales* → **Portales**. El portal de cada canal debe tener *Canal de importación* = Airbnb o Booking. Solo un portal puede tener cada canal; asignar un canal ya usado da error «El portal … ya tiene asignado el canal de importación …». Con *Auto-crear mapeo de alojamientos* activo, el portal se crea solo (`AIRBNB` / `BOOKING`) o se asigna el canal a un portal existente con ese código.

### 4.4 Mapeo de alojamientos

Role Center → *Configuración* → **Mapeo alojamientos portales**. Una fila por portal y clave de alojamiento:

| Campo | Uso |
|---|---|
| **Portal** | Portal del canal. |
| **Clave alojamiento** | Nombre del alojamiento tal y como viene en Airbnb; ID numérico en Booking. |
| **Alojamiento** | Nombre informativo; en Booking se rellena al importar. |
| **Cód. propiedad** | Producto de la propiedad. Al validarlo, si hay dimensión de propiedad y el valor no existe, exige que la autocreación de valores esté activa; rellena el nombre desde el valor de dimensión o el producto. Al cambiarlo se limpia la variante. |
| **Cód. variante** | Variante del producto con la que se facturan las reservas de ese alojamiento (p. ej. la habitación). Requiere código de propiedad. |

### 4.5 Datos maestros de Business Central

- **Cliente genérico** con grupo contable cliente, grupo registro negocio general y grupo registro IVA negocio.
- **Productos de las propiedades** con el mismo código que la propiedad, no bloqueados para ventas, con grupo registro producto general y una combinación válida en *Configuración registro IVA* con el grupo IVA producto de la configuración. Se recomienda tipo *Servicio*.
- **Proveedores** de Airbnb y Booking (modo cargo a proveedor). Al validar el nº de cuenta se limpian la forma de pago y la contrapartida de la línea de diario, para que las patas se compensen entre sí.
- **Bancos** de payouts, no bloqueados.
- **Dimensiones** de propiedad y canal con sus valores (`AIRBNB`, `BOOKING`).
- **Libro y sección de diario de pagos** si el registro automático está desactivado.
- **Series numéricas** de facturas y abonos de venta.

### 4.6 Permisos

Conjunto de permisos **BeDyn Portal Import** (82600). Incluye lectura, inserción y modificación de portales, variantes de producto, unidades de medida de producto y líneas de diario, y lectura de la configuración de facturación recurrente. Para registrar documentos y diarios hacen falta además los permisos estándar de ventas y contabilidad.

---

## 5. Formato de los ficheros CSV

Ambos ficheros usan **separador coma**, campos entre comillas cuando contienen comas o saltos de línea, y comillas escapadas como `""`. La cabecera se reconoce por el **título** de cada columna, sin distinguir mayúsculas, acentos ni caracteres de codificación, así que el **orden de las columnas es libre** y las columnas no reconocidas se ignoran.

### 5.1 Airbnb: export de transacciones (español o inglés)

Se detecta como Airbnb cuando existen las columnas **Fecha/Date** y **Tipo/Type**.

| Columna (ES / EN) | Campo de la hoja | Uso |
|---|---|---|
| Fecha / Date | Fecha | Fecha de registro de todos los movimientos. Formato `MM/dd/yyyy`. |
| Fecha de llegada estimada / Arriving by date | Fecha llegada estimada | Informativo (payouts). |
| Tipo / Type | Tipo | `Payout` → Payout; `Reserva`/`Reservation` → Reserva; contiene `Ajuste`, `Adjustment`, `Resoluc` o `Resolut` → Ajuste de resolución; otro → Otro. |
| Código de confirmación / Confirmation code | Cód. reserva (20) | Identificador de la reserva; nº de documento externo de la factura y parte del Id. externo. |
| Fecha de la reserva / Booking date | Fecha reserva | Informativo. |
| Fecha de inicio / Start date | Fecha inicio | Descripción de la línea de factura. |
| Fecha de finalización / End date | Fecha fin | Descripción de la línea de factura. |
| Noches / Nights | Noches | Cantidad de la línea de factura (si hay unidad de medida configurada). |
| Viajero / Guest | Viajero (100) | Descripción de la línea de factura. |
| Alojamiento / Listing | Alojamiento (100) | **Clave del mapeo**. |
| Detalles / Details | Detalles (250) | Descripción de la línea en el tipo Otro; banco destino en payouts. Se quitan los saltos de línea. |
| Código de referencia / Reference code | Cód. referencia (50) | Id. externo y nº de documento externo del payout. |
| Moneda / Currency | Divisa (10) | Solo se admite EUR (o vacío). |
| Importe / Amount | Importe (neto) | Neto que abona Airbnb. |
| Cobrado / Paid out | Cobrado | Importe del payout. |
| Comisión de servicio / Service fee | Comisión canal | Comisión principal. |
| Comisión por Pago rápido / Fast pay fee | Comisión pagos | Comisión adicional. |
| Gastos de limpieza / Cleaning fee | Gastos de limpieza | Informativo (ya incluido en el bruto). |
| Ingresos brutos / Gross earnings | Importe bruto | Importe de la factura. |
| Impuestos liquidados por Airbnb / Occupancy taxes | Impuestos | Informativo. |
| Año fiscal / Earnings year | Año fiscal | Informativo. |

**Reglas de parseo Airbnb**: fechas `MM/dd/yyyy` (si no tienen tres partes se intenta la conversión estándar; si falla, quedan vacías). Importes con el punto o la coma como decimal, según cuál aparezca en último lugar (`519.67` y `"95,33"` conviven en el mismo fichero); un importe no numérico queda a 0. Una fila sin fecha ni tipo se ignora.

### 5.2 Booking: export de payouts (español)

Se detecta como Booking cuando existen las columnas **Tipo/Tipo de transacción** y **Fecha del pago**. El guion `-` significa "sin valor".

| Columna | Campo de la hoja | Uso |
|---|---|---|
| Tipo/Tipo de transacción | Tipo | `(Payout)` → Payout; `Reserva`/`Reservation` → Reserva; otro → Otro. |
| Descripción del cargo | Grupo payout (50) | Identificador del grupo: enlaza el payout con sus reservas. Id. externo del payout. |
| Número de referencia | Cód. reserva (20) | Identificador de la reserva. |
| Fecha de check-in / Fecha de check-out | Fecha inicio / Fecha fin | Descripción de la línea. Formato `yyyy-MM-dd`. |
| Fecha de emisión | Fecha emisión | Fecha de registro alternativa si falta la del pago. |
| Estado de la reserva | Estado reserva (20) | Solo `OK` se procesa; `Cancel…` según configuración; el resto se omite. |
| Habitaciones | Habitaciones | Informativo. |
| Noches | Noches | Cantidad de la línea de factura. |
| ID del alojamiento | ID alojamiento (20) | **Clave del mapeo**. |
| Nombre del alojamiento | Alojamiento (100) | Informativo; rellena el nombre del mapeo. |
| Importe bruto | Importe bruto | Importe de la factura. |
| Comisión | Comisión canal | Negativa en el CSV. |
| Cargo por servicio de los pagos | Comisión pagos | Negativa en el CSV. |
| IVA | IVA comisión | IVA retenido sobre las comisiones. |
| Impuestos | Impuestos | Coherencia de importes. |
| Importe de la transacción | Importe (neto) | Neto de la reserva. |
| Moneda de la transacción | Divisa | Si viene vacía, se usa *Moneda del pago*. |
| Importe a pagar | Importe a pagar | Informativo. |
| Importe del pago | Cobrado | Importe del payout. |
| Fecha del pago | Fecha | **Fecha de registro** de todos los movimientos de Booking. |
| Cuenta bancaria | Cuenta bancaria (portal) | Informativo (máscara `*2632`). |
| ID legal, Nombre legal, País, Tipo de pago, Comisión %, Porcentaje del cargo, Tipo de cambio, Moneda del pago, Frecuencia del pago, Proveedor de servicios de pago | — | No se usan. |

**Reglas de parseo Booking**: fechas ISO `yyyy-MM-dd`; importes con punto decimal; una fila sin tipo ni grupo se ignora.

### 5.3 Ficheros de ejemplo

En esta carpeta hay exports reales: `airbnb_04_2026-04_2026.csv`, `airbnb_05_2026-05_2026.csv`, `airbnb_06_2026-06_2026.csv` (inglés), `airbnb_06_2026-06_2026-2.csv` (español) y `Payout_from_2026-06-01_until_2026-06-30.csv` (Booking).

---

## 6. Flujo de trabajo paso a paso

Todo se hace en la hoja **Importación Portales de Venta**: Role Center → *Importaciones* → **Hoja importación portales**.

| Paso | Acción | Qué hace |
|---|---|---|
| 1 | **Importar CSV...** | Pide el fichero, detecta codificación y canal, crea un lote, inserta las líneas nuevas (las duplicadas se cuentan y se omiten) y **valida el lote automáticamente**. La hoja queda filtrada por el lote. Si la validación ha creado alojamientos nuevos en el mapeo, lo avisa. |
| 2 | Revisar | Colores por estado. En cada línea se pueden editar **Propiedad**, **Variante** y **Estado**. Completar el mapeo de los alojamientos nuevos. |
| 3 | **Revalidar** | Vuelve a validar las líneas seleccionadas (excepto las *Registrada*). |
| 4 | **Procesar** | Contabiliza las líneas *Validada* de la selección, una a una; los errores se anotan en la línea y el proceso continúa. |
| 5 | **Archivar procesadas** | Mueve al histórico las líneas *Registrada* de la vista actual, previa confirmación. |

Acciones auxiliares: **Ver documento** (factura o abono registrado, o el borrador), **Ver todos los lotes**, **Configuración**, **Mapeo alojamientos**, **Histórico**.

Estados y colores:

| Estado | Color | Significado |
|---|---|---|
| **Pendiente** | normal | Importada, aún sin validar (solo si la validación automática no llegó a ejecutarse). |
| **Validada** | verde | Lista para procesar. Amarillo si además tiene un aviso. |
| **Error** | rojo | Falta algo; el motivo está en *Mensaje*. Se puede corregir y revalidar. |
| **Registrada** | verde | Contabilizada; el nº está en *Documento registrado*. |
| **Omitida** | gris | Fuera de alcance por configuración o estado (payouts desactivados, reserva cancelada, tipo no soportado). El motivo está en *Mensaje*. |

> El **estado es editable**. Por ejemplo, una línea *Omitida* puede ponerse en *Validada* a mano para forzar su contabilización, o una *Validada* en *Omitida* para no procesarla. Úselo con criterio: al forzar una línea se saltan las comprobaciones que la habían omitido.

---

## 7. Validaciones que realiza la solución, paso a paso

### 7.1 Al importar

| # | Comprobación | Resultado si falla |
|---|---|---|
| 1 | Se selecciona un fichero `.csv`. | Si se cancela, no pasa nada. |
| 2 | El fichero tiene contenido. | Error «El fichero está vacío.» |
| 3 | **Codificación**: BOM `FF FE` → UTF-16; BOM `EF BB BF` → UTF-8; sin BOM, según *Codificación del fichero* (UTF-8 validado, si no Windows). | Si aun así no se puede leer, error estándar de lectura. Síntoma habitual: acentos mal en los nombres de alojamiento. |
| 4 | **Cabecera** (primera línea no vacía): debe contener las columnas de Booking (*Tipo/Tipo de transacción* y *Fecha del pago*) o las de Airbnb (*Fecha* y *Tipo*). Booking tiene prioridad. | Error «No se reconoce la cabecera: no es el export de transacciones de Airbnb … ni el de payouts de Booking … Revisa que el separador sea la coma (,).» No se crea lote. |
| 5 | Líneas lógicas: si una línea física deja una comilla abierta, se une con la siguiente. | — |
| 6 | Filas vacías: Airbnb sin fecha ni tipo; Booking sin tipo ni grupo. | Se ignoran sin contar. |
| 7 | **Duplicados**: el Id. externo no puede existir en la hoja (cualquier lote) ni en el histórico. | La fila se omite y se cuenta como duplicada. Las filas sin Id. externo (sin código de reserva o referencia) no se deduplican. |
| 8 | Fechas e importes no interpretables. | Quedan vacíos o a 0 sin aviso; la validación los detectará (fecha vacía, importe cero). |
| 9 | Longitudes. | Los textos se truncan al tamaño del campo (código de reserva 20, alojamiento 100, detalles 250…). |

Al terminar: «Lote PT… (Airbnb): N líneas importadas, M duplicadas omitidas.» y, si procede, «Se han creado X alojamientos nuevos en el mapeo…». A continuación se ejecuta la validación del lote (7.2).

### 7.2 Al validar (automática tras importar, o acción *Revalidar*)

Se validan todas las líneas del lote (o de la selección) salvo las *Registrada*. A diferencia de otros módulos, aquí se **acumulan todos los errores** de la línea en *Mensaje*, y los **avisos** (no bloqueantes) en *Aviso*. La validación además **crea datos** cuando la configuración lo permite: el portal del canal, el alojamiento en el mapeo, la unidad de medida en el producto y la variante por defecto.

**Bloque A — Según el tipo de movimiento**

| Tipo | Comprobación | Resultado |
|---|---|---|
| Reserva Booking | Estado distinto de `OK`. Si empieza por `CANCEL` y *Contabilizar reservas canceladas* está activo, se admite. | *Omitida*: «Reserva con estado "…": cancelaciones y ajustes están fuera de alcance, revísala manualmente.» |
| Payout | *Contabilizar payouts* desactivado. | *Omitida*: «Payout: omitido (activar "Contabilizar payouts" en la configuración para contabilizarlo).» |
| Tipo desconocido | Ningún tipo del enum (no debería darse). | *Omitida*: «Tipo de movimiento no soportado…» |

**Bloque B — Reservas, ajustes de resolución y tipo Otro**

| # | Comprobación | Mensaje si falla |
|---|---|---|
| 1 | Código de reserva informado (no exigido en tipo Otro). | «Falta el código de la reserva.» |
| 2 | Clave de alojamiento informada (nombre en Airbnb, ID en Booking). | «Falta el alojamiento.» |
| 3 | **Portal del canal**: existe un portal con ese *Canal de importación*. Con autocreación de mapeos se crea. | «Ningún portal del maestro tiene el canal de importación …: asígnalo en la lista de Portales y revalida.» |
| 4 | **Mapeo**: existe la fila portal + clave. Si no, con autocreación se da de alta sin propiedad. | «Alojamiento sin mapear: complétalo en el mapeo de alojamientos y revalida.» |
| 5 | El mapeo tiene código de propiedad (solo se copia a la línea si la línea lo tiene vacío, para respetar correcciones manuales; la variante del mapeo solo si la propiedad de la línea coincide con la del mapeo). | «El mapeo del alojamiento no tiene código de propiedad.» |
| 6 | Importe neto distinto de cero. | «El importe neto de la reserva es cero.» |
| 7 | Importe bruto distinto de cero (solo tipo Reserva; en ajustes y Otro se reconstruye al contabilizar). | «El importe bruto de la reserva es cero: no se puede facturar.» |
| 8 | Cliente genérico configurado. | «Falta el cliente genérico en la configuración.» |
| 9 | Grupo IVA producto de ventas configurado. | «Falta el grupo IVA producto de ventas en la configuración (los importes vienen con IVA incluido).» |
| 10 | **Producto** con el código de la propiedad. Si existe y hay unidad de medida de ventas del canal, se crea en el producto con factor 1 si falta. | «No existe ningún producto con el código …: la propiedad se factura como producto y debe existir un producto con el mismo código que el valor de dimensión.» |
| 11 | **Variante efectiva** (línea, mapeo o por defecto) existe en el producto. Con *Auto-crear variante por defecto* se crea. | «El producto … no tiene la variante … indicada como variante por defecto en la configuración: créala en el producto, activa "Auto-crear variante por defecto" o vacía el campo de la configuración.» |
| 12 | Si hay comisiones (comisión, comisión de pagos o IVA distintos de 0): en modo *Cargo a proveedor*, proveedor del canal configurado; en modo *Cuenta contable*, cuenta de comisiones configurada. | «Falta el proveedor de … en la configuración (necesario en modo cargo a proveedor).» / «Falta la cuenta de comisiones en la configuración (necesaria en modo cuenta contable).» |
| 13 | Si hay comisiones y el registro automático está desactivado: libro y sección de pagos configurados. | «Registro automático desactivado: indica el libro diario y la sección de pagos en la configuración de portales.» |
| 14 | **Coherencia de importes** (aviso, no bloquea). Airbnb: neto + comisión + comisión de pagos = bruto (±0,01), solo si hay bruto. Booking: bruto + comisión + cargo + IVA + impuestos = neto (±0,02). | Aviso «Los importes no cuadran: neto … + comisiones … <> bruto ….» / «Los importes no cuadran: bruto … + comisiones/IVA … <> neto ….» |

**Bloque C — Payouts**

| # | Comprobación | Mensaje si falla |
|---|---|---|
| 1 | Airbnb: código de referencia informado. | «Falta el código de referencia del payout.» |
| 2 | Booking: grupo de payout informado. | «Falta el identificador del grupo de payout ("Descripción del cargo").» |
| 3 | Booking: si trae alojamiento, se resuelve la propiedad como en el bloque B (para la dimensión del asiento), con sus mismos errores. | Ver B.3 a B.5. |
| 4 | Booking: **conciliación del grupo** (aviso). Debe haber reservas del grupo en la hoja y la suma de sus netos debe coincidir con el importe cobrado (±0,02). | Aviso «No hay reservas del grupo en la hoja de importación.» / «El payout (…) no cuadra con la suma de sus reservas (…).» |
| 5 | Importe cobrado distinto de cero. | «El importe cobrado del payout es cero.» |
| 6 | Banco de payouts del canal configurado. | «Falta el banco de los payouts de … en la configuración.» |
| 7 | Cliente genérico configurado. | «Falta el cliente genérico en la configuración.» |
| 8 | Registro automático desactivado: libro y sección de pagos configurados. | «Registro automático desactivado: indica el libro diario y la sección de pagos…» |

**Bloque D — Comunes a todos los tipos**

| # | Comprobación | Mensaje si falla |
|---|---|---|
| 1 | Fecha del movimiento informada (Airbnb: *Fecha*; Booking: *Fecha del pago* o, en su defecto, *Fecha de emisión*). | «Falta la fecha del movimiento.» |
| 2 | Divisa vacía o `EUR`. | «Divisa no soportada (…): solo se admite EUR.» |
| 3 | Si hay dimensión de canal configurada, el valor de canal del portal está informado. | «La dimensión de canal está configurada sin valor para …: indícalo en la configuración.» |

**Resultado**: con algún error, la línea queda en *Error* con todos los mensajes concatenados; sin errores, en *Validada* (con el aviso, si lo hay). Las marcas de reintento (*Borrador factura*, *Factura registrada*, *Comisión registrada*) se conservan al revalidar.

> **Lo que la validación no comprueba** y sí exigirá Business Central al contabilizar: grupos contables del cliente y del producto, configuración de registro de IVA, dimensiones predeterminadas obligatorias, series numéricas, periodos de registro permitidos, bloqueos de proveedor o banco, existencia del valor de dimensión de la propiedad (ver 7.3).

### 7.3 Al procesar

**Comprobaciones previas de la acción**

| # | Comprobación | Resultado si falla |
|---|---|---|
| 1 | Cliente genérico configurado. | Error estándar de campo obligatorio; no se procesa nada. |
| 2 | Registro automático desactivado: libro y sección de pagos configurados. | Error estándar de campo obligatorio. |
| 3 | Hay líneas *Validada* en la selección. | Mensaje «No hay líneas validadas pendientes de procesar en el filtro actual.» |

**Por cada reserva, ajuste u Otro** (los errores se capturan por línea; la línea pasa a *Error* con el texto y el proceso sigue con la siguiente):

| Paso | Qué se hace | Comprobaciones y errores |
|---|---|---|
| 1 | Tipo de documento: **abono** si es ajuste u Otro con bruto negativo (bruto vacío = neto + comisiones); si no, **factura**. | — |
| 2 | Si la línea aún no tiene la factura registrada: se reutiliza el **borrador** de un intento anterior (si sigue existiendo, refrescando variante, cantidad, precio y descripción) o se **crea** el documento. | Valor de dimensión de la propiedad: si no existe y la autocreación está desactivada, «El valor … no existe en la dimensión … y la creación automática está desactivada.» Validaciones estándar de cabecera y línea (cliente, producto, IVA, dimensiones). Si la creación falla a medias, el borrador incompleto se elimina. |
| 3 | Registro automático activo: se **registra** (envío + factura; la fecha de trabajo se iguala temporalmente a la de registro para evitar el aviso de fecha distinta). | «Error al registrar el documento de la reserva …: <error estándar>». El borrador se conserva y se reutiliza en el siguiente intento. Éxito: *Factura registrada* = sí, *Documento registrado* = nº registrado. |
| 3b | Registro automático desactivado: el borrador queda como resultado de la línea. | *Documento registrado* = nº del borrador. |
| 4 | Si hay comisiones y aún no están registradas: **diario de comisiones** (7.3 y 8.3). | «Error al descontar la comisión de la reserva …: <error estándar>». Éxito: *Comisión registrada* = sí. |
| 5 | Línea a *Registrada*, mensaje limpio. | — |

**Por cada payout**:

| Paso | Qué se hace | Comprobaciones y errores |
|---|---|---|
| 1 | Salvaguarda: si *Contabilizar payouts* se desactivó después de validar, la línea pasa a *Omitida*. | — |
| 2 | **Diario del payout**: banco del canal contra cliente genérico (8.4). | «Error al registrar el payout: <error estándar>» (banco bloqueado, fecha no permitida, dimensión obligatoria…). Éxito: *Registrada*, *Documento registrado* = `AB`/`BK` + nº de línea. |

**Reintentos**: una línea en *Error* se corrige, se **revalida** y se vuelve a **procesar**. Gracias a las marcas, se retoma en el paso que falló: no se crea otra factura si ya hay borrador, no se registra dos veces la factura ni la comisión. Antes de registrar cada documento y cada diario se hace commit, así que lo ya contabilizado se conserva aunque falle lo siguiente.

Al terminar: «Proceso terminado: N líneas procesadas correctamente, M con error.»

### 7.4 Al archivar

| Comprobación | Resultado |
|---|---|
| Hay líneas *Registrada* en la vista actual (se respetan los filtros, p. ej. el lote). | Mensaje «No hay líneas registradas que archivar en la vista actual.» |
| Confirmación «¿Quieres archivar N líneas registradas?…». | Se copian al histórico con fecha y usuario y se borran de la hoja. Mensaje «N líneas movidas al histórico.» |

Las líneas archivadas siguen contando para la **deduplicación**: reexportar un periodo ya archivado no vuelve a contabilizarlo.

---

## 8. Contabilización (detalle)

### 8.1 Factura o abono de la reserva

| Campo | Origen |
|---|---|
| Tipo | Factura; abono en ajustes de resolución y tipo Otro con bruto negativo. |
| Cliente | Cliente genérico. |
| Fecha de registro y de documento | *Fecha* del movimiento (Airbnb: fecha de la transacción; Booking: fecha del pago). |
| Precios IVA incluido | Sí, siempre. |
| Nº documento externo | Código de reserva. |
| Dimensiones de cabecera | Propiedad (si hay dimensión configurada) y canal (valor del portal). Se actualizan las dimensiones globales 1 y 2. |
| Línea: producto / variante | Código de la propiedad / variante efectiva (línea, mapeo o por defecto). |
| Línea: grupo IVA producto | El de la configuración (fuerza el cálculo de la base hacia atrás). |
| Línea: unidad de medida | La de ventas del canal, si está configurada (se crea en el producto si falta). |
| Línea: cantidad y precio | Con noches y unidad configurada: cantidad = noches, precio = \|bruto\| / noches, y el importe de línea se fuerza a \|bruto\| exacto. Sin noches: cantidad 1 y precio = \|bruto\|. |
| Línea: descripción | «4 noches del 30/05/2026 - 03/06/2026 Nombre viajero» (sin viajero, el alojamiento). Sin fechas o noches: «Airbnb HMQZKHSNA2 Nombre». Ajustes: prefijo «Ajuste resolución». Tipo Otro: el texto de *Detalles*. |

### 8.2 Registro o borrador

Con *Registrar automáticamente*: envío + factura con *Registrar ventas*; la línea guarda el nº registrado y limpia el borrador. Sin él: el borrador queda como documento de la línea y la acción *Ver documento* lo abre.

### 8.3 Diario de comisiones

Un único asiento equilibrado, con nº de documento = código de reserva (o `AB`/`BK` + nº de línea en tipo Otro sin código), fecha = fecha del movimiento, tipo documento *Pago*, dimensiones de propiedad y canal:

| Pata | Cuenta | Importe (factura) | Importe (abono) |
|---|---|---|---|
| 1 | Cliente genérico, **aplicada** a la factura o abono registrado (solo con registro automático; en modo manual el usuario aplica al registrar). | −(comisión + comisión de pagos + IVA) | +(…) |
| 2, modo proveedor | Proveedor del canal. | +total retenido | −total retenido |
| 2, modo cuenta | Cuenta de comisiones (sin IVA: se limpia la configuración de registro de la cuenta). | +comisiones (sin el IVA si hay cuenta de IVA) | − |
| 3, modo cuenta con cuenta de IVA | Cuenta IVA comisiones. | +IVA retenido | − |

La forma de pago y la contrapartida que arrastra el cliente o el proveedor se limpian para que las patas se compensen entre sí. Con registro automático se registra con *Gen. Jnl.-Post Line*; sin él, las líneas se insertan en el libro y sección de pagos configurados, sin aplicación.

### 8.4 Diario del payout

Una línea de diario, tipo *Pago*, nº de documento `AB`/`BK` + nº de línea: cargo al **banco de payouts del canal** por el importe cobrado, contrapartida **cliente genérico** (pago a cuenta, sin aplicar), nº de documento externo = código de referencia (Airbnb) o grupo de payout (Booking), descripción «Payout Airbnb 30/06/2026», dimensiones de canal y, si se resolvió, de propiedad. La aplicación contra las facturas pendientes se hace a mano.

### 8.5 Dimensiones

- **Propiedad**: valor = código de propiedad en la dimensión configurada. Si no existe, se crea al contabilizar con el nombre del mapeo o del alojamiento (o error si la autocreación está desactivada).
- **Canal**: valor configurado por canal en la dimensión de canal.
- Se estampan en la cabecera de la factura (las líneas heredan) y en todas las líneas de diario.

---

## 9. Ejemplos

**Reserva Airbnb en noches.** Fila Reserva `HMQZKHSNA2`, 3 noches del 29/04 al 02/05, alojamiento *Fully Equipped Studio in Lavapiés* mapeado a `PROP-0001`, bruto 360,00, neto 304,20, comisión 55,80, unidad de ventas `NOCHE` → factura al cliente genérico de 360,00 IVA incluido con una línea `PROP-0001`, 3 NOCHE a 120,00, descripción «3 noches del 29/04/2026 - 02/05/2026 Cristal Huaira», nº documento externo `HMQZKHSNA2`; diario: cliente −55,80 aplicado a la factura y proveedor Airbnb +55,80. El cliente queda pendiente de 304,20.

**Payout Airbnb.** Fila Payout con referencia `G-7ONW…`, cobrado 304,20 → diario banco Airbnb +304,20 contra cliente genérico, sin aplicar. Id. externo `AB:P:G-7ONW…`.

**Reserva Booking.** Fila Reserva `6184346221` del grupo `N6XqLBjdKCdFyJwa`, estado OK, 4 noches, alojamiento `13355074`, bruto 800,25, comisión −136,04, cargo −10,40, IVA −30,75, neto 623,06 → factura de 800,25 y diario de 177,19 contra el proveedor Booking (o cuenta de comisiones 146,44 + cuenta IVA 30,75). El payout `(Payout)` del mismo grupo por 920,46 se concilia con la suma de los netos de sus reservas; si no cuadra, aviso.

**Reserva cancelada en Booking.** Estado `Cancelada` con *Contabilizar reservas canceladas* desactivado → *Omitida* con el motivo. Para facturarla igualmente, activar el parámetro y revalidar, o cambiar el estado a *Validada* a mano.

**Alojamiento nuevo.** Al importar aparece un alojamiento desconocido → se crea en el mapeo sin propiedad, la línea queda en *Error* «Alojamiento sin mapear…» y la importación avisa. Completar el mapeo y *Revalidar*.

---

## 10. Resolución de problemas (FAQ)

| Síntoma | Causa probable | Solución |
|---|---|---|
| «No se reconoce la cabecera…» | El fichero no es el export esperado, el separador no es la coma, o Booking en un idioma distinto del español. | Exportar de nuevo el fichero correcto; Booking debe exportarse en español. |
| Acentos mal en los alojamientos y el mapeo no coincide. | Codificación sin BOM mal detectada. | Cambiar *Codificación del fichero* y reimportar (borrar antes las líneas mal importadas). |
| «Alojamiento sin mapear…» | Alojamiento nuevo o renombrado en el portal. | Completar la propiedad en el mapeo y revalidar. En Airbnb el mapeo es por nombre: si el anfitrión renombra el anuncio, hay que mapearlo de nuevo. |
| «No existe ningún producto con el código …» | La propiedad del mapeo no tiene producto con el mismo código. | Crear el producto (o la propiedad con el asistente) o corregir el mapeo. |
| «El producto … no tiene la variante …» | Variante por defecto o del mapeo inexistente en el producto. | Crearla, activar *Auto-crear variante por defecto* o vaciar el campo. |
| Aviso «Los importes no cuadran…» | El CSV trae importes con redondeos o columnas inesperadas. | Revisar la fila; el aviso no bloquea. |
| Aviso «El payout … no cuadra con la suma de sus reservas…» | Faltan reservas del grupo (están en otro fichero, archivadas o canceladas). | Importar el fichero completo del periodo; si el grupo está en el histórico, el aviso es esperado. |
| «Error al registrar el documento de la reserva …: …» | Validación estándar: grupos contables, IVA, dimensión obligatoria, periodo cerrado, producto bloqueado para ventas. | Corregir el maestro, revalidar y procesar; el borrador se reutiliza. |
| «Error al descontar la comisión …: Tipo mov. o Tipo contrapartida deben ser…» | Forma de pago del cliente o proveedor con cuenta de contrapartida. | El módulo la limpia; si persiste, revisar la forma de pago del cliente genérico y del proveedor. |
| Línea *Registrada* pero la factura sigue en borrador. | Registro automático desactivado. | Es el comportamiento esperado: registrar el borrador y las líneas del diario de pagos a mano. |
| Se importan 0 líneas y todas cuentan como duplicadas. | Periodo ya importado (hoja o histórico). | Nada que hacer; si de verdad hay que reimportar, borrar las líneas o el histórico correspondiente. |
| Se creó el portal `AIRBNB` o `BOOKING` solo. | Autocreación de mapeos activa y ningún portal tenía el canal. | Asignar el canal al portal correcto y, si sobra, borrar el autocreado tras mover sus mapeos. |

---

## 11. Limitaciones conocidas

- Solo se admiten movimientos en **EUR**.
- Booking solo se reconoce en su export en **español**; Airbnb en español o inglés.
- Los movimientos sin identificador (reservas sin código, tipo Otro sin código) **no se deduplican**.
- El mapeo de Airbnb es por **nombre** del alojamiento: un cambio de nombre en el portal obliga a mapearlo de nuevo.
- Las reservas de Booking con estado distinto de OK o cancelada se omiten; no hay tratamiento automático de modificaciones o ajustes de Booking.
- Los payouts se contabilizan **sin aplicar** a las facturas; la aplicación es manual.
- El estado de la línea es editable: forzar una línea omitida a *Validada* salta las comprobaciones que la omitieron.
- Fechas e importes no interpretables no dan error de parseo; quedan vacíos o a 0 y solo se detectan si otra validación los exige.
- Al igualar temporalmente la fecha de trabajo a la de registro se evita el aviso de fecha distinta, pero no la comprobación de periodos de registro permitidos.

---

## 12. Historial de versiones

| Fecha | Cambio |
|---|---|
| 2026-09-15 | Primera versión del manual. Cubre los formatos de Airbnb y Booking, la configuración, el flujo, la contabilización de reservas, ajustes, tipo Otro y payouts, y las validaciones de importación, validación, proceso y archivo. |

---

*Documento del módulo de importación de portales de venta de `Neelo Core Solutions by BeDynamic`. Ante dudas funcionales, contacte con el equipo de BeDynamic.*
