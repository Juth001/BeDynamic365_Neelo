# NEE - Sales Portal Importations

Herramienta unificada de importación de los portales de venta. Sustituyó a los módulos "NEE - Importación AirBnB" y "NEE - ImportarCSVBooking" (retirados del proyecto el 25/07/2026): una sola hoja de importación, un solo mapeo de alojamientos y un único motor de contabilización. Hoy procesa los CSV de **Airbnb** (transacciones) y **Booking** (payouts); el maestro de canales contempla además Idealista, MeIT, Housing Anywhere, Spotahome y Hostify para futuras incorporaciones.

> Manual completo (configuración, formato de los CSV, contabilización y todas las validaciones de cada paso): [Manual técnico y funcional](Manual-Tecnico-Funcional.md).

## Flujo

1. **Importar CSV** desde la hoja *Importación Portales de Venta*. El canal se detecta automáticamente por la cabecera del fichero. Cada importación crea un lote y las líneas se validan al cargar.
2. **Revisar**: hoja coloreada por estado, con el **estado editable** para forzar casos concretos. Los alojamientos desconocidos se auto-crean en el mapeo (sin propiedad) para completarlos.
3. **Revalidar** las líneas corregidas y **Procesar** las validadas.
4. **Archivar**: la acción *Archivar procesadas* mueve las líneas registradas de la vista actual a la tabla de **histórico** y las quita de la hoja.

## Mapeo y maestro de Portales

Cada alojamiento (nombre en Airbnb, ID en Booking) se asigna a su **propiedad** en el mapeo de alojamientos. El mapeo se ancla al maestro de **Portales** del módulo de propiedades: cada portal indica su **Canal de importación** y solo un portal puede tener cada canal (el portal del canal se auto-crea si falta).

## Contabilización (modelo factura, ambos canales)

- **Reserva** → factura de venta al cliente genérico por el **bruto** (IVA incluido; el grupo IVA de la configuración calcula la base hacia atrás), con línea del producto de la propiedad (código producto = código propiedad, con la variante por defecto, auto-creable). Con noches informadas, la línea lleva **cantidad = noches** en la unidad de medida configurada por canal y **precio = bruto/noches** (el importe de línea se fuerza al bruto exacto, sin desvíos de redondeo); la unidad se crea en el producto si falta. El código de la reserva va como nº de documento externo. Las **comisiones** (comisión + comisión de pagos + IVA retenido en Booking) se descuentan de la factura con un diario aplicado a ella, contra el **proveedor del canal** (pago a cuenta, pendiente de netear con su factura real) o contra la **cuenta de comisiones** (el IVA de Booking a su propia cuenta si se configura). El cliente queda pendiente solo del neto.
- **Ajuste de resolución** (Airbnb) y **tipo Otro** → mismo esquema pero como **abono de venta** cuando el importe es negativo, con la comisión en signo invertido; si el bruto viene vacío se reconstruye desde el neto y las comisiones. Los positivos se facturan como una reserva. En Otro el código de reserva es opcional (sin él, el nº de documento se genera desde la línea y no hay deduplicación).
- **Payout** → cargo al **banco del canal** y abono al cliente genérico como pago a cuenta, sin aplicar (activable por configuración).
- Reservas **canceladas** de Booking: se facturan o se omiten para revisión manual, según configuración.
- Todo con las dimensiones de **propiedad** y de **canal** (valor por canal, p. ej. AIRBNB / BOOKING).
- Fechas: Airbnb, la fecha del movimiento; Booking, la **fecha del pago**.
- **Registro automático**: se reutiliza el parámetro **"Post Automatically"** de la configuración de Recurring Invoicing (compartido con la importación de colaboradores). Activo, factura/abono y diarios se registran directamente; desactivado, el documento queda en **borrador** y los pagos (comisiones y payouts) se dejan **sin registrar** en el libro y sección del diario de pagos configurados, sin aplicación (el usuario aplica y registra).
- Reintentos idempotentes con marcas por paso en el buffer (borrador de factura, factura registrada, comisión registrada), sin duplicar documentos; las noches y el precio se aplican también al reutilizar un borrador existente.

## Deduplicación e histórico

Cada línea lleva un **Id. externo** con prefijo de canal (`AB:`/`BK:`) que evita importar dos veces el mismo movimiento, en cualquier lote del staging **y también contra el histórico** de líneas archivadas: se pueden re-exportar periodos solapados sin duplicar contabilidad, incluso después de archivar.

El histórico de los módulos antiguos de Airbnb y Booking se migró al buffer con los mismos prefijos antes de retirarlos (la migración debía ejecutarse con la versión anterior instalada; el codeunit de migración ya no existe).

## Objetos

| Objeto | ID | Nombre |
|---|---|---|
| Enum | 82600 | BeDyn Portal Channel (Airbnb, Booking, Idealista, MeIT, Housing Anywhere, Spotahome, Hostify) |
| Enum | 82601 | BeDyn Portal Row Type (Reserva, Payout, Ajuste de resolución, Otro) |
| Enum | 82602 | BeDyn Portal Line Status |
| Enum | 82603 | BeDyn Portal Commission Mode |
| Table | 82600 | BeDyn Portal Setup |
| Table | 82601 | BeDyn Portal Import Buffer |
| Table | 82602 | BeDyn Portal Listing Mapping |
| Table | 82603 | BeDyn Portal Import Archive (histórico) |
| Codeunit | 82600 | BeDyn Portal CSV Reader |
| Codeunit | 82601 | BeDyn Portal Validation |
| Codeunit | 82602 | BeDyn Portal Import Process |
| Codeunit | 82604 | BeDyn Portal Channel Mgt. |
| TableExtension | 82600 | BeDyn Portal Ext (campo "Canal de importación" en Portal) |
| PageExtension | 82600 | BeDyn Portal List Ext |
| Page | 82600 | BeDyn Portal Setup |
| Page | 82601 | BeDyn Portal Import Worksheet |
| Page | 82602 | BeDyn Portal Listing Mapping |
| Page | 82603 | BeDyn Portal Import Archive |
| PermissionSet | 82600 | BeDyn Portal Import |

> El codeunit 82603 (BeDyn Portal Migration, migración puntual del histórico) se eliminó junto con los módulos antiguos.
