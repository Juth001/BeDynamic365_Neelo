# Manual técnico y funcional — Importación de facturación a particulares

**Módulo de la app:** Neelo Core Solutions by BeDynamic · **Namespace:** `Neelo.RecurringInvoicing` (con apoyo de `BeDynamic.PropertyManagement`)
**Plataforma:** Business Central 28 (localización española — Cartera ES)
**Rango de objetos:** 81000–81026 (facturación recurrente) · 82500–82599 (propiedades)
**Última actualización:** 2026-09-15

> Este manual describe la importación con la **plantilla de particulares**. Es un segundo layout del mismo módulo de facturación recurrente, así que todo lo común (configuración por cliente, Banco de Gestión, remesas de Cartera) se describe en el [Manual técnico y funcional](Manual-Tecnico-Funcional.md) y aquí solo se detalla lo específico de esta plantilla, incluidas **todas las validaciones** de cada paso.

---

## 1. Visión general

La plantilla de particulares sirve para facturar **alquileres a particulares por propiedad**. Cada fila del CSV es un cargo a un cliente por una **propiedad** (y opcionalmente una **habitación**), con su importe y, si se desea, tres dimensiones analíticas (línea de negocio, canal y unidad).

Diferencias con la plantilla estándar de colaboradores:

| Aspecto | Plantilla estándar | Plantilla de particulares |
|---|---|---|
| Qué se factura en la línea | La **cuenta/producto/recurso** de la configuración de facturación del cliente. | El **producto de la propiedad** de la fila del CSV, con la **habitación** como variante. La cuenta de la configuración se ignora. |
| Columna 4 | Documento externo. | **Propiedad** (nº de producto). Se vuelca también al nº de documento externo de la factura. |
| CIF/NIF | Obligatorio. | Opcional: si va vacío, el cliente se localiza por el **ID BC**. |
| Fila de cabecera | Según la marca *Tiene cabecera* del Setup. | Se **detecta automáticamente**. |
| Dimensiones | No. | Tres columnas opcionales al final: **línea de negocio**, **canal** y **unidad**. |
| Vínculo con el módulo de propiedades | No. | Los códigos de facturación marcados como **Alquiler** enlazan la factura con la **reserva** de la propiedad; los marcados como **Fianza** no facturan: contabilizan el cobro y crean la **fianza**. |

El flujo es el mismo de siempre, con una acción de importación propia:

```
   ┌──────────────────────┐    ┌────────────┐    ┌──────────────────────┐    ┌──────────┐
   │ 1. IMPORTAR          │ ─▶ │ 2. VALIDAR │ ─▶ │ 3. GENERAR/REGISTRAR │ ─▶ │ 4. ARCHIVAR│
   │ (Import Individuals  │    │  (staging) │    │  Factura / Fianza    │    │ (opcional)│
   │  CSV)                │    │            │    │                      │    │          │
   └──────────────────────┘    └────────────┘    └──────────────────────┘    └──────────┘
     Lote nuevo, líneas          Validada /         Procesada / Ignorada       Archivo de
     en "Pendiente"              Error                                          importación
```

---

## 2. Conceptos clave

| Concepto | Descripción |
|---|---|
| **Lote** | Cada importación crea un lote con código `IMP` + fecha y hora (p. ej. `IMP20260915103015`). Todas las líneas del fichero pertenecen a ese lote. |
| **Línea de staging** | Fila del CSV convertida en línea de la tabla intermedia *Buffer Importación Facturas*, donde se valida antes de generar nada. |
| **Código de facturación** | Columna 1 del CSV (p. ej. `ALQ`, `FIANZA`). Se define en la tabla maestra *Códigos de Facturación* y se configura **por cliente**. |
| **Configuración de facturación del cliente** | Fila cliente + código de facturación con la agrupación, el Banco de Gestión, la unidad de medida y las marcas **Alquiler** y **Fianza**. En esta plantilla su cuenta solo se usa en fianzas (cuenta de pasivo de fianzas) y en filas sin propiedad. |
| **Propiedad** | Columna 4. Es el **nº de producto** que se factura. Cuando el código de facturación es de alquiler o fianza debe existir además como *Propiedad* del módulo de propiedades **con el mismo código** (así las crea el asistente de propiedades). |
| **Habitación** | Columna 5. Es la **variante** del producto. En códigos de alquiler o fianza debe existir además como *Subpropiedad* de la propiedad **con el mismo código**. |
| **Habitación maestra** | Código definido en *Configuración de propiedades* → *Código de habitación maestra*. En el CSV significa "propiedad completa": la factura lleva esa variante, pero la reserva y la fianza se crean **sin habitación**. |
| **Reserva** | Registro del módulo de propiedades que une propiedad, habitación, inquilino y fechas. Los códigos de alquiler y fianza la buscan y, si no existe, la **crean** en estado *Pendiente*. |
| **Fianza** | Depósito del inquilino. Los códigos de fianza crean la fianza, la marcan *Cobrada* y contabilizan el cobro en el banco contra la cuenta de fianzas. |
| **Línea de negocio / Canal / Unidad** | Columnas 10 a 12. Valores de las tres dimensiones configuradas en el Setup, que se estampan en la cabecera y en las líneas del documento generado. |
| **Banco de Gestión** | Banco que gestiona el cobro. Sale de la configuración de facturación del cliente y se propaga a la factura, los movimientos y la Cartera. En fianzas es el banco donde se contabiliza el cobro. |
| **Agrupación** | *Agrupada* (una factura por cliente, código y fecha de registro) o *Individual* (una factura por línea). |

---

## 3. Objetos implicados (referencia técnica)

| Objeto | ID | Nombre | Papel en esta plantilla |
|---|---|---|---|
| Table | 81000 | BeDyn Recurring Inv. Setup | Separador, activo, registro automático, comentarios, precios IVA incluido y los **tres códigos de dimensión** (línea de negocio, canal, unidad). |
| Table | 81001 | BeDyn Invoice Import Buffer | Tabla de staging. Campos propios de esta plantilla: *Property Code*, *Variant Code*, *Business Line Code*, *Channel Code*, *Unit Code*, *Deposit No.* |
| Table | 81002 | BeDyn Customer Billing | Configuración de facturación por cliente, con las marcas **Deposit** (fianza) y **Rental** (alquiler). |
| Table | 81003 | BeDyn Billing Code | Maestro de códigos de facturación. |
| Table | 81004 | BeDyn Invoice Import Archive | Histórico de líneas procesadas o ignoradas. |
| Page | 81003 | BeDyn Invoice Import Buffer (*Invoice Import*) | Página de trabajo: importar, validar, procesar, archivar, navegar al documento. |
| Page | 81002 / 81004 / 81005 / 81006 | Setup, Customer Billing, Billing Codes, Import Archive | Configuración y consulta. |
| Codeunit | 81009 | BeDyn Import Mgt. | Lectura y parseo del CSV. `ImportIndividualsCSV` activa el layout de particulares. |
| Codeunit | 81010 | BeDyn Validation Mgt. | Validación de cada línea (apartado 7.2). |
| Codeunit | 81011 | BeDyn Posting Mgt. | Generación de facturas, enlace con reservas y contabilización de fianzas (apartado 8). |
| Enum | 81005 / 81006 | BeDyn Buffer Status / BeDyn Invoice Grouping | Estados de la línea y modo de agrupación. |
| TableExt | 81015 / 81016 | Sales Header / Sales Invoice Header | Campo *Management Bank* (Banco de Gestión). |
| TableExt | 82500 / 82501 | Sales Header Ext. / Sales Inv. Header Ext. | Campos *Reservation No.* y *Deposit No.*, que pasan de la factura al histórico al registrar. |
| Table | 82500 | BeDyn Property Mgt. Setup | *Código de habitación maestra*, nº de serie de reservas y de fianzas. |
| Table | 82502 / 82503 | BeDyn Property / BeDyn Property Room | Propiedad y subpropiedades (habitaciones). |
| Table | 82507 / 82512 | BeDyn Reservation / BeDyn Deposit | Reservas y fianzas que crea el proceso. |
| Page | 82538 | BeDyn Property Manager RC | Role Center: pestaña *Importaciones* → *Importación facturación recurrente*. |
| PermissionSet | 81000 | BeDyn Recurring Inv. | Permisos del módulo, incluidos inserción y modificación de reservas y fianzas. |

---

## 4. Configuración previa (checklist)

### 4.1 Configuración de facturación recurrente

Role Center → *Configuración* → **Configuración facturación recurrente**.

| Campo | Uso en esta plantilla |
|---|---|
| **Activo** | Obligatorio. Sin esta marca ninguna acción funciona. |
| **Separador CSV** | Carácter separador del fichero. Vacío = `;`. |
| **Tiene cabecera** | No hace falta para esta plantilla: la cabecera se detecta sola. Si está marcada, la primera fila se omite igualmente. |
| **Origen del NIF** | Debe ser *Nº identificación fiscal* (VAT Registration No.). La opción *Campo NIF personalizado* no está implementada y hace fallar la validación de todas las líneas. |
| **Registrar automáticamente** | Marcado: las facturas se registran al procesar. Desmarcado: quedan en borrador. Las fianzas se contabilizan siempre. |
| **Insertar comentarios** | Permite importar filas sin importe como líneas de comentario (solo en códigos agrupados). |
| **Ignorar comentarios** | En códigos individuales, tolera comentarios que no puedan vincularse a una factura. |
| **Precios IVA incluido** | Indica si el importe del CSV lleva el IVA incluido. Se aplica a la cabecera de cada factura y sobrescribe el valor por defecto del cliente. |
| **Cód. dimensión línea de negocio** | Dimensión a la que pertenecen los valores de la columna 10. Obligatoria si el CSV trae esa columna informada. |
| **Cód. dimensión canal** | Dimensión de la columna 11. Obligatoria si el CSV la trae informada. |
| **Cód. dimensión unidad** | Dimensión de la columna 12. Obligatoria si el CSV la trae informada. Los valores que falten **se crean automáticamente**. |

### 4.2 Códigos de facturación

Role Center → *Configuración* → *Códigos de facturación*. Deben existir todos los códigos que vengan en la columna 1 (p. ej. `ALQ` para alquiler y `FIANZA` para fianzas).

### 4.3 Configuración de facturación por cliente

Ficha del cliente → *Relacionado* → *Facturación recurrente*. Una fila por cliente y código de facturación:

| Campo | Uso en esta plantilla |
|---|---|
| **Código facturación** | El de la columna 1. |
| **Tipo facturación** | Informativo (Recurrente / Extra). |
| **Tipo cuenta / Nº cuenta** | En filas del CSV **con propiedad** se ignora: la línea factura el producto de la propiedad. Se usa solo en dos casos: (a) filas **sin propiedad**, que se facturan como en la plantilla estándar; (b) códigos de **fianza**, donde debe ser una **cuenta contable** (la cuenta de pasivo de fianzas). |
| **Cód. variante** | Se ignora en filas con propiedad (la variante viene del CSV). |
| **Unidad de medida predeterminada** | Opcional. Si se informa, se asigna a la línea de factura y **debe existir como unidad del producto de la propiedad**. Útil cuando el producto se vende por DÍA pero este código factura por MES. |
| **Banco de gestión** | Opcional en facturas. **Obligatorio en fianzas**: es el banco donde se contabiliza el cobro. Debe existir y no estar bloqueado. |
| **Agrupación** | Agrupada o Individual. |
| **Alquiler** (Rental) | Marcar en el código de alquiler. Cada línea facturable enlaza su **reserva** (se crea si no existe) y la factura lleva la de la primera línea. Incompatible con *Fianza*. |
| **Fianza** (Deposit) | Marcar en el código de fianza. No se genera factura: se crea la fianza y se contabiliza el cobro. Al marcarlo, el tipo de cuenta pasa a cuenta contable. Incompatible con *Alquiler*. |

> Si un cliente tiene varias filas con el mismo código de facturación y distinta cuenta, el proceso usa la **primera** por nº de cuenta.

### 4.4 Productos y variantes (propiedades y habitaciones)

- La propiedad debe existir como **producto** no bloqueado con el código que se escribe en la columna 4. El asistente de propiedades crea producto, valor de dimensión, proyecto y propiedad con el mismo código.
- Cada habitación debe existir como **variante** del producto, no bloqueada, con el código de la columna 5.
- Si el producto tiene variantes y *Variante obligatoria si existe* está activo (en el producto o, si el producto lo deja en *Predeterminado*, en la *Configuración de inventario*), la columna 5 es obligatoria.
- Si la configuración de facturación tiene unidad de medida, debe estar dada de alta en las **unidades de medida del producto**.
- Para que la factura pueda crearse y registrarse, el producto necesita lo que exige el estándar: grupo registro producto general, grupo registro IVA producto, y una combinación válida con los grupos del cliente. Se recomienda tipo *Servicio* o *No inventariable*, para que el registro no dependa de existencias.

### 4.5 Módulo de propiedades (solo códigos de alquiler y fianza)

- La propiedad debe existir en la tabla *Propiedades* **con el mismo código que el producto**, y la habitación en *Subpropiedades* **con el mismo código que la variante**. Si no coinciden, la validación no encuentra la propiedad o la habitación.
- *Configuración de propiedades* → **Código de habitación maestra**: la variante que representa la propiedad completa. Cuando la columna 5 trae ese código, la reserva y la fianza se crean sin habitación.
- *Configuración de propiedades* → **Nos. reservas** y **Nos. fianzas**: series numéricas necesarias para crear reservas y fianzas.

### 4.6 Dimensiones

- Dar de alta las dimensiones que se vayan a usar y configurar sus códigos en el Setup (4.1).
- Los valores de línea de negocio y canal deben existir y no estar bloqueados. Los de unidad se crean solos si faltan (con el código como nombre).
- Las reglas de dimensiones predeterminadas del estándar (*Código obligatorio*, *Mismo código*) siguen aplicando al crear y registrar el documento.

### 4.7 Clientes

- El NIF debe estar en *Nº identificación fiscal* (VAT Registration No.). Se compara sin espacios, puntos ni guiones y sin distinguir mayúsculas.
- El cliente debe tener **grupo contable cliente** y no estar bloqueado para *Factura* ni *Todo*.
- Si el NIF va vacío en el CSV, la columna 8 (ID BC) debe contener el **nº de cliente** exacto.

### 4.8 Permisos

Asignar el conjunto de permisos **BeDyn Recurring Inv.** (81000). Incluye lectura, inserción y modificación de reservas y fianzas. La creación automática de valores de la dimensión de unidad usa permisos elevados del propio objeto, por lo que no depende del permiso del usuario sobre valores de dimensión.

---

## 5. Formato del fichero CSV

Orden de columnas **fijo**. Separador el del Setup (por defecto `;`).

| Col. | Campo | Oblig. | Campo del buffer | Notas |
|---|---|:---:|---|---|
| **1** | CÓDIGO FACTURACIÓN | Sí | *Billing Code* (20) | Localiza la configuración de facturación del cliente. Se pasa a mayúsculas. |
| **2** | CIF/NIF | No | *VAT Registration No.* (20) | Localiza al cliente. Vacío → se usa el ID BC. |
| **3** | FECHA REGISTRO | No | *Posting Date* | `dd/mm/aaaa`; admite `-` y `.` como separador y año de 2 cifras (20xx). Vacía → la factura toma la fecha de trabajo. |
| **4** | PROPIEDAD | Sí | *Property Code* (20) | Nº de producto. Se copia también a *External Document No.* Mayúsculas. |
| **5** | HABITACIÓN | Según | *Variant Code* (10) | Variante del producto. Obligatoria si el producto exige variante. Mayúsculas. |
| **6** | CONCEPTO | No | *Description* (100) | Descripción de la línea. Admite comillas y saltos de línea dentro de comillas. Se trunca a 100 caracteres. |
| **7** | IMPORTE | Sí | *Amount* | `1.234,56` o `1234.56`. Vacío = 0 (línea de comentario o error, según el Setup). |
| **8** | ID BC | No | *BC Customer No.* (20) | Nº de cliente. Obligatorio si el NIF va vacío; si no, desempate de NIF repetidos. Mayúsculas. |
| **9** | GRUPO IVA PRODUCTO | No | *VAT Prod. Posting Group* (20) | Si se informa, sustituye en la línea al grupo del producto. Mayúsculas. |
| **10** | LÍNEA NEGOCIO | No | *Business Line Code* (20) | Valor de la dimensión de línea de negocio. Mayúsculas. |
| **11** | CANAL | No | *Channel Code* (20) | Valor de la dimensión de canal. Mayúsculas. |
| **12** | UNIDAD | No | *Unit Code* (20) | Valor de la dimensión de unidad. Mayúsculas. |

**Plantilla oficial (con cabecera)**, disponible en [Plantilla-Importacion-Particulares.csv](Plantilla-Importacion-Particulares.csv):

```
CODIGO FACTURACION;CIF/NIF;FECHA REGISTRO;PROPIEDAD;HABITACION;CONCEPTO;IMPORTE;ID BC;GRUPO IVA PRODUCTO;LINEA NEGOCIO;CANAL;UNIDAD
ALQ;12345678A;30/09/2026;PROP-0001;H01;Alquiler septiembre 2026;650,00;C00100;IVA21;LARGA;DIRECTO;MADRID
ALQ;;30/09/2026;PROP-0002;MASTER;Alquiler septiembre 2026;1.250,00;C00101;;LARGA;IDEALISTA;
```

### Reglas de parseo

- **Cabecera**: la primera fila se considera cabecera y se omite cuando ni su columna 3 es una fecha ni su columna 7 es un importe (ambas traen títulos). También se omite si *Tiene cabecera* está marcado. Una fila de datos con la fecha mal escrita pero con importe numérico no se descarta: se importa con el error de fecha.
- **Comillas**: campos entre `"…"`, comillas escapadas como `""`, y saltos de línea dentro de comillas (se convierten en espacio).
- **Importe**: si hay coma, la coma es el decimal y los puntos son millares. Si solo hay puntos y el último grupo tiene 3 cifras, el punto es de millares; en otro caso es decimal.
- **Fecha**: día-mes-año. Separadores `/`, `-` o `.`. Año de 2 cifras = 20xx.
- **Filas vacías**: se ignoran.
- **Longitudes**: los textos más largos que el campo de destino se **truncan** sin aviso (ver tabla).
- **Mayúsculas**: código de facturación, propiedad, habitación, ID BC, grupo IVA y las tres dimensiones se pasan a mayúsculas. El NIF y el concepto se guardan tal cual.

---

## 6. Flujo de trabajo paso a paso

Todo se hace en la página **Invoice Import** (*Importación Facturas*): Role Center → pestaña *Importaciones* → **Importación facturación recurrente**.

| Paso | Acción | Qué hace |
|---|---|---|
| 1 | **Import Individuals CSV** | Pide el fichero, crea un lote y deja sus líneas en *Pendiente* (o *Error* si el importe o la fecha no se pudieron leer). La página queda filtrada por el lote nuevo. |
| 2 | **Validate Batch** | Valida todas las líneas *Pendiente*, *Error* y *Validada* del lote de la línea seleccionada. Cada una pasa a *Validada* o *Error* con su mensaje. Se puede repetir tantas veces como haga falta. |
| 3 | **Post Batch** | Procesa todas las líneas *Validada* del lote: genera y registra (o deja en borrador) las facturas y contabiliza las fianzas. Las líneas pasan a *Procesada* (o *Ignorada* si son comentarios sin factura). |
| 3 alt. | **Process Selected Lines** | Igual, pero solo con las líneas *Validada* seleccionadas. |
| 4 | **Archive Processed Lines** | Mueve al archivo las líneas *Procesada* e *Ignorada* dentro del filtro actual, previa confirmación. |

Acciones auxiliares:

- **Navigate to Generated Document**: abre la factura registrada, el borrador o, en líneas de fianza, la ficha de la fianza.
- **Delete Batch**: borra todas las líneas del lote seleccionado, previa confirmación. No deshace documentos ya generados.
- **Create Customer**: crea un cliente desde plantilla y abre su ficha (para NIF que no existen).
- **Import Archive**: abre el histórico. **Show All Batches**: quita el filtro de lote.

Estados de una línea:

| Estado | Color | Significado |
|---|---|---|
| **Pendiente** | normal | Importada, sin validar. |
| **Validada** | verde | Lista para procesar. Ya tiene cliente, agrupación y banco resueltos. |
| **Error** | rojo | Falta algo; el motivo está en *Mensaje de error*. |
| **Procesada** | negrita | Factura o fianza generada; el nº está en *Nº documento generado*. |
| **Ignorada** | gris | Comentario que no pudo vincularse a una factura. |

---

## 7. Validaciones que realiza la solución, paso a paso

> Los mensajes se muestran en el idioma de la traducción instalada; sin traducción aparecen en inglés. Aquí se transcriben en castellano.

### 7.1 Al importar

| # | Comprobación | Resultado si falla |
|---|---|---|
| 1 | El Setup tiene la marca **Activo**. | Error «La configuración de facturación recurrente no está activa.» No se importa nada. |
| 2 | Se selecciona un fichero en el diálogo. | Si se cancela, no pasa nada. |
| 3 | El fichero tiene contenido y al menos una fila con datos. | Mensaje «No se importó ninguna línea del fichero.» No se crea lote. |
| 4 | Primera fila: si *Tiene cabecera* está marcado, o si ni la columna 3 es una fecha ni la columna 7 es un importe, se trata como cabecera. | Se omite. Una primera fila de datos con fecha mal escrita pero importe numérico no se descarta: se importa con estado *Error*. |
| 5 | Filas cuyos campos están todos en blanco. | Se ignoran. |
| 6 | **Fecha de registro** (col. 3): si viene informada, debe ser convertible a fecha. | La línea se crea con estado **Error** y mensaje «Fecha de registro no válida: "…".» Una fecha vacía no es error. |
| 7 | **Importe** (col. 7): si viene informado, debe ser numérico. | La línea se crea con estado **Error** y mensaje «Importe no numérico: "…".» Un importe vacío se guarda como 0 y lo decide la validación. |
| 8 | Longitud de los textos. | Se truncan a la longitud del campo (concepto a 100, códigos a 20, habitación a 10). Sin aviso. |

Al terminar se muestra «N líneas importadas en el lote IMP…». Las líneas con error de parseo se pueden corregir a mano en la página (fecha, importe) y validar después.

### 7.2 Al validar

Precondición: el Setup debe estar **Activo** (error estándar «Activo debe tener un valor…»). Se validan las líneas *Pendiente*, *Error* y *Validada* del lote; las *Procesada* e *Ignorada* no se tocan.

Cada línea se valida en este orden y se guarda el **primer** error encontrado. Al empezar se limpian el mensaje, el nº de cliente, la marca de comentario y el banco.

| # | Validación | Condición | Mensaje si falla |
|---|---|---|---|
| 1 | **Origen del NIF** | El Setup no puede estar en *Campo NIF personalizado*. | «El origen "Campo NIF personalizado" no está implementado todavía.» |
| 2 | **Cliente por NIF** | El NIF normalizado (mayúsculas, sin espacios, puntos ni guiones) se compara con el *Nº identificación fiscal* de todos los clientes. | 0 coincidencias: «No se encontró ningún cliente con el NIF "…".» |
| | | Varias coincidencias: el ID BC (col. 8) debe ser uno de esos clientes. | «El NIF "…" corresponde a más de un cliente; indique el ID BC para elegir uno.» |
| 2b | **Cliente por ID BC** (NIF vacío) | Si el NIF va vacío, el ID BC debe ser un nº de cliente existente. | «No se encontró ningún cliente con el NIF "".» |
| 3 | **Cliente no bloqueado** | Bloqueado distinto de *Factura* y de *Todo*. | «El cliente … está bloqueado (…).» |
| 4 | **Grupo contable cliente** | Debe estar informado. | «El cliente … no tiene grupo contable de cliente.» |
| 5 | **Configuración de facturación** | Debe existir la fila cliente + código de facturación (col. 1). Un código vacío también falla. | «El cliente … no tiene la configuración de facturación "…".» |
| 6 | **Rama según el tipo de fila** | A partir de aquí el camino depende de la configuración y de la línea: | |
| 6a | *Código de fianza* (fila con **Fianza**) | Importe distinto de 0. | «El importe no puede ser cero.» |
| | | La columna propiedad debe venir informada. | «Las líneas de fianza deben traer la propiedad en la columna de propiedad; impórtelas con el layout de particulares.» |
| | | La propiedad existe en el módulo de propiedades. | «La propiedad … no existe.» |
| | | Propiedad **por subpropiedades**: la habitación es obligatoria (no vale la maestra) y debe existir como subpropiedad. | «La propiedad … se alquila por habitaciones; indique la habitación en el CSV.» / «La habitación … no existe en la propiedad ….» |
| | | Propiedad **completa**: la habitación debe ir vacía o ser la maestra. | «La propiedad … se alquila completa; deje la habitación vacía o use el código de habitación maestra en lugar de ….» |
| | | El tipo de cuenta de la fila de facturación es *Cuenta contable*. | «Código de fianza …: el tipo de cuenta debe ser Cuenta contable (la cuenta de pasivo de fianzas).» |
| | | La fila de facturación tiene Banco de Gestión. | «Código de fianza …: el Banco de Gestión (contrapartida del asiento) es obligatorio.» |
| | | La cuenta contable existe, no está bloqueada y es de tipo *Registro*. | «La cuenta … (Cuenta contable) no existe o está bloqueada.» |
| 6b | *Importe 0* (sin fianza) | *Insertar comentarios* desactivado. | «El importe no puede ser cero.» |
| | | Activado + código **Individual** sin *Ignorar comentarios*. | «Las líneas sin importe solo pueden importarse como comentarios cuando el código de facturación usa facturación agrupada; el código "…" del cliente … usa facturación individual.» |
| | | En otro caso la línea se marca **Comentario** y sigue validando (no se comprueba el producto). | |
| 6c | *Importe ≠ 0 y propiedad informada* | El producto de la propiedad existe y no está bloqueado. | «La propiedad … no existe como producto o está bloqueada.» |
| | | Si hay habitación: es una variante existente y no bloqueada del producto. | «La variante … del producto … no existe o está bloqueada.» |
| | | Si no hay habitación: el producto no exige variante (*Variante obligatoria si existe* del producto o de la configuración de inventario, cuando el producto tiene variantes activas). | «El producto … requiere variante; indique la habitación en el CSV.» |
| | | Si la fila de facturación tiene unidad de medida: existe para ese producto. | «La unidad de medida … de la configuración de facturación no existe para el producto …. Añádala a las unidades de medida del producto.» |
| 6d | *Importe ≠ 0 y propiedad vacía* | La línea se trata como en la plantilla estándar: se valida la cuenta de la fila de facturación (existe, no bloqueada, tipo *Registro* si es cuenta contable), su variante y su unidad de medida. | «La cuenta … (…) no existe o está bloqueada.» / «La variante … del producto … no existe o está bloqueada.» / «El producto … requiere variante; indíquela en la configuración de facturación "…".» / «La unidad de medida … no existe para … ….» |
| 7 | **Código de alquiler** (fila con **Alquiler**, líneas que no son comentario) | La columna propiedad debe venir informada. | «Las líneas de alquiler deben traer la propiedad en la columna de propiedad; impórtelas con el layout de particulares.» |
| | | La propiedad existe en el módulo de propiedades. | «La propiedad … no existe.» |
| | | Propiedad **por subpropiedades**: la habitación es obligatoria (no vale la maestra) y debe existir como subpropiedad. | «La propiedad … se alquila por habitaciones; indique la habitación en el CSV.» / «La habitación … no existe en la propiedad ….» |
| | | Propiedad **completa**: la habitación debe ir vacía o ser la maestra. | «La propiedad … se alquila completa; deje la habitación vacía o use el código de habitación maestra en lugar de ….» |
| 8 | **Banco de Gestión** (si la fila lo tiene) | Existe y no está bloqueado. | «El Banco de Gestión … no existe o está bloqueado.» |
| 9 | **Grupo IVA producto** (col. 9, si viene) | Existe. | «El grupo registro IVA producto "…" no existe.» |
| 10 | **Línea de negocio** (col. 10, si viene) | El Setup tiene *Cód. dimensión línea de negocio*. | «El CSV trae una línea de negocio pero el "Cód. dimensión línea de negocio" no está configurado en la configuración de facturación recurrente.» |
| | | El valor existe en esa dimensión y no está bloqueado. | «La línea de negocio … no existe como valor de la dimensión … o está bloqueada.» |
| 11 | **Canal** (col. 11, si viene) | El Setup tiene *Cód. dimensión canal*. | «El CSV trae un canal pero el "Cód. dimensión canal" no está configurado…» |
| | | El valor existe y no está bloqueado. | «El canal … no existe como valor de la dimensión … o está bloqueado.» |
| 12 | **Unidad** (col. 12, si viene) | El Setup tiene *Cód. dimensión unidad*. | «El CSV trae una unidad pero el "Cód. dimensión unidad" no está configurado…» |
| | | Si el valor no existe, **se crea** en la dimensión con el código como nombre. Si existe y está bloqueado, falla. | «La unidad … de la dimensión … está bloqueada.» |

Resultado:

- **Sin errores**: la línea pasa a *Validada* y se copian a ella la **agrupación** y el **Banco de Gestión** de la fila de facturación. El *Nº cliente* queda resuelto.
- **Con error**: la línea pasa a *Error* con el mensaje. El *Nº cliente* se conserva si se llegó a resolver, lo que ayuda a localizar la configuración que falta.
- Al terminar se muestra «N líneas validadas, M con errores (lote …)».

> **Puntos que la validación no comprueba** y que sí exigirá el estándar al generar el documento: grupos contables del producto y del cliente, configuración de registro de IVA, dimensiones predeterminadas obligatorias, series numéricas y fechas de registro permitidas. Ver 7.3.

### 7.3 Al generar / registrar

**Comprobaciones propias del módulo**

| # | Comprobación | Resultado si falla |
|---|---|---|
| 1 | El Setup está **Activo**. | Error estándar de campo obligatorio. |
| 2 | *Post Batch*: hay líneas *Validada* en el lote. | «No hay líneas validadas en el lote ….» |
| 3 | *Process Selected Lines*: hay líneas *Validada* en la selección. | «No hay líneas validadas en la selección.» Las líneas seleccionadas en otro estado se saltan. |
| 4 | Por cada pareja cliente + código de facturación se relee la configuración de facturación (primera fila por nº de cuenta). | Si se borró desde la validación: error estándar «El registro no existe». |
| 5 | Códigos de alquiler y fianza: *Nos. reservas* y *Nos. fianzas* de *Configuración de propiedades* informados (solo si hay que crear la reserva o la fianza). | Error estándar de campo obligatorio. |
| 6 | Fianzas: la fecha de registro de la línea debe estar informada (es la fecha del asiento). | Error estándar «Fecha registro debe tener un valor» al contabilizar. |

**Comprobaciones del estándar que se disparan al crear el documento**

Al crear la cabecera y las líneas se ejecutan las validaciones normales de Business Central. Las más habituales en esta plantilla:

- **Cabecera**: cliente con grupo contable cliente, grupo registro negocio general y grupo registro IVA negocio; nº de serie de facturas de venta; fecha de registro válida.
- **Línea de producto**: el producto no debe estar *Bloqueado para ventas* (tampoco la variante); debe tener grupo registro producto general y grupo registro IVA producto; debe existir la combinación en *Configuración registro general* y en *Configuración registro IVA* con los grupos del cliente; la unidad de medida de la fila de facturación debe existir para el producto; el grupo IVA producto del CSV, si viene, sustituye al del producto y debe combinar con el grupo del cliente.
- **Dimensiones**: al estampar línea de negocio, canal y unidad se combinan con las dimensiones predeterminadas del cliente y del producto (entre ellas la dimensión PROPIEDAD del asistente). Si una dimensión está configurada como *Código obligatorio* o *Mismo código* y el valor no cuadra, el registro falla.
- **Reservas** (códigos de alquiler y fianza): al crear una reserva nueva se validan la propiedad (momento de facturación, contrato, importe de alquiler y dimensiones predeterminadas de la propiedad) y el inquilino, si el cliente tiene exactamente uno vinculado. El tipo de alquiler ya se comprobó al validar; no se comprueba disponibilidad, y la reserva queda *Pendiente* para completarla a mano (fecha fin, contrato).

**Comprobaciones al registrar** (solo con *Registrar automáticamente*; las fianzas se contabilizan siempre)

- **Factura**: todas las de *Registrar ventas*: fecha dentro de los periodos permitidos de la configuración de contabilidad o del usuario, cantidades e importes, disponibilidad si el producto es inventariable con *Impedir inventario negativo*, dimensiones, etc.
- **Fianza**: las de *Diario general*: banco existente y no bloqueado, cuenta de fianzas con *Registro directo*, fecha permitida, dimensiones obligatorias.

**Comportamiento ante un error a mitad de lote**

El proceso recorre las parejas cliente + código y genera los documentos uno a uno. Si uno falla, se muestra el error y el proceso se detiene; lo ya hecho se conserva de forma coherente:

- Antes de registrar cada factura, sus líneas del buffer se marcan *Procesada* con el nº del **borrador** y se confirman en base de datos. Si el registro falla, el borrador queda creado y enlazado a sus líneas, que ya no se vuelven a facturar. Corrija la causa y registre el borrador desde *Navigate to Generated Document* (o desde la lista de facturas de venta): la línea del buffer sigue llevando al documento aunque se registre a mano.
- Tras registrar cada factura, las líneas se actualizan con el nº de la **factura registrada** y se confirman de nuevo. No puede quedar una factura registrada con sus líneas en *Validada*.
- Cada **fianza** se confirma al terminar: si falla la quinta, las cuatro anteriores quedan hechas y marcadas; la que falló se deshace entera (fianza, reserva y asiento).
- Al volver a lanzar *Post Batch* solo se procesan las líneas que siguen en *Validada*.

### 7.4 Al archivar y al borrar

| Acción | Comprobación | Resultado |
|---|---|---|
| **Archive Processed Lines** | Pregunta de confirmación. Solo se mueven las líneas *Procesada* e *Ignorada* dentro del filtro actual. | Se copian al archivo con fecha, hora y usuario, y se borran del buffer. Mensaje «N líneas archivadas». |
| **Delete Batch** | Debe haber una línea seleccionada con lote; pregunta de confirmación (por defecto *No*). | Se borran todas las líneas del lote, en cualquier estado. Los documentos ya generados **no** se tocan. |

---

## 8. Generación de documentos (detalle)

### 8.1 Agrupación

Las líneas validadas se agrupan por **cliente + código de facturación** y cada grupo se procesa según su fila de facturación:

| Fila de facturación | Resultado |
|---|---|
| **Fianza** | Una fianza y un asiento **por cada línea**. Sin factura. |
| **Agrupada** | Una factura **por cada fecha de registro** del grupo, con todas sus líneas (y comentarios) en el orden de importación. |
| **Individual** | Una factura **por cada línea** facturable. Excepción: exactamente 1 comentario + 1 línea → una sola factura con ambos. El resto de comentarios se marcan *Ignorada*. |

### 8.2 Cabecera de la factura

| Campo | Origen |
|---|---|
| Tipo / Nº | Factura de venta; nº de la serie estándar. |
| Cliente | El resuelto en la validación. |
| Precios IVA incluido | *Precios IVA incluido* del Setup (sobrescribe el valor del cliente). |
| Banco de Gestión | De la fila de facturación. |
| Fecha registro y fecha documento | *Fecha registro* del CSV, si viene; si no, la fecha de trabajo. En facturas agrupadas es la fecha común del grupo. |
| Nº documento externo | **Propiedad** de la primera línea de la factura. |
| Nº reserva | Solo en códigos de alquiler: la reserva de la primera línea (ver 8.5). |
| Dimensiones | Línea de negocio, canal y unidad de la **primera línea**, sobre las dimensiones predeterminadas del cliente. Se actualizan las dimensiones globales 1 y 2. |

### 8.3 Líneas de la factura

| Campo | Origen |
|---|---|
| Tipo / Nº | *Producto* / **propiedad** del CSV. Si la fila del CSV no trae propiedad, se usa la cuenta de la fila de facturación como en la plantilla estándar. |
| Cód. variante | **Habitación** del CSV (también cuando es la maestra). |
| Unidad de medida | La de la fila de facturación, si la tiene; si no, la del producto. Se valida antes del precio para no pisar el importe del CSV. |
| Grupo IVA producto | El del CSV, si viene; si no, el del producto. |
| Cantidad / Precio unitario | 1 / **Importe** del CSV. |
| Descripción | **Concepto** del CSV (sustituye a la del producto). |
| Dimensiones | Línea de negocio, canal y unidad **de esa línea**, sobre las dimensiones predeterminadas del producto (incluida PROPIEDAD). En facturas agrupadas cada línea conserva su valor aunque difiera del de la cabecera. |
| Comentarios | Tipo en blanco y solo descripción. |

### 8.4 Registro o borrador

Con *Registrar automáticamente* la factura se registra (envío + factura) y la línea del buffer guarda el nº de la **factura registrada**. Sin la marca, queda en borrador y se guarda el nº del **borrador**. En ambos casos el estado pasa a *Procesada*.

### 8.5 Códigos de alquiler: enlace con la reserva

Para cada línea facturable se busca la **reserva activa** (Pendiente, Confirmada o Con check-in) de la propiedad y habitación. La habitación maestra equivale a "sin habitación". La elección tiene en cuenta al cliente a través de la ficha del **inquilino** (campo *Nº cliente*):

- Si el cliente tiene inquilinos vinculados, solo se reutilizan las reservas de **sus** inquilinos (primero la que cubre la fecha de registro, después la más reciente) o las reservas **sin inquilino** creadas por el propio proceso. Las reservas de otros inquilinos nunca se reutilizan.
- Si el cliente no tiene ningún inquilino vinculado, se toma la reserva activa más reciente.

Si no hay ninguna que sirva, se **crea** una reserva *Pendiente* con la propiedad, la habitación, la fecha de registro del CSV como fecha de inicio y el inquilino del cliente (si tiene exactamente uno), sin fecha fin, para completarla después.

La cabecera de la factura lleva la reserva de su primera línea, y ese nº pasa a la factura registrada. En facturas agrupadas con varias propiedades solo la primera queda en la cabecera, pero se garantiza la reserva de todas las líneas.

### 8.6 Códigos de fianza: fianza y asiento de cobro

Por cada línea:

1. Se busca o crea la **reserva** igual que en 8.5.
2. Se crea la **fianza** (nº de la serie *Nos. fianzas*) enlazada a la reserva, que le aporta propiedad, habitación e inquilino, con el importe del CSV.
3. Se contabiliza el **cobro** con una línea de diario registrada directamente (sin sección de diario):
   - Cuenta: **banco** = Banco de Gestión de la fila de facturación, con el importe del CSV (cargo).
   - Contrapartida: **cuenta contable** = nº de cuenta de la fila de facturación (abono), sin IVA.
   - Nº documento = nº de la fianza. Nº documento externo = propiedad. Descripción = concepto. Fecha = fecha de registro del CSV.
   - Dimensiones: línea de negocio, canal y unidad del CSV.
4. La fianza pasa a **Cobrada**, con fecha de cobro, y queda **registrada**: *Nº documento cobro*, *Nº documento contable* y *Fecha registro contable* toman el nº de la fianza y la fecha del asiento. Desde la ficha se navega a los movimientos contables y la acción *Registrar asiento* queda deshabilitada.
5. La línea del buffer pasa a *Procesada* con el nº de la fianza en *Nº documento generado* y en *Nº fianza*.

> El asiento del CSV (banco contra cuenta de fianzas) sustituye al de la ficha de fianza (cuenta puente contra cuenta de fianzas): representan el mismo cobro y solo debe existir uno. Por eso la fianza importada queda marcada como registrada.

### 8.7 Banco de Gestión y remesas

El Banco de Gestión de la factura se propaga a la factura registrada, los movimientos de cliente y la Cartera, y filtra las remesas de cobro. Ver apartado 9 del [Manual técnico y funcional](Manual-Tecnico-Funcional.md).

---

## 9. Ejemplos

**Alquiler mensual, código agrupado.** Dos líneas del mismo cliente con código `ALQ` (agrupada, alquiler) y la misma fecha, propiedades `PROP-0001/H01` y `PROP-0001/H02` → una factura con dos líneas de producto `PROP-0001`, variantes `H01` y `H02`, nº documento externo `PROP-0001`, reserva de `H01` en la cabecera, y las reservas de ambas habitaciones garantizadas.

**Cliente sin NIF.** Fila con NIF vacío e ID BC `C00101` → se factura al cliente `C00101` sin buscar por NIF. Si `C00101` no existe: «No se encontró ningún cliente con el NIF "".»

**Fianza.** Fila con código `FIANZA` (fianza, cuenta contable 561000, banco BANCO1), propiedad `PROP-0002` y habitación `MASTER` → reserva de la propiedad completa (se crea si no existe), fianza cobrada por el importe y asiento BANCO1 contra 561000 con nº de documento el de la fianza.

**Propiedad completa sin habitación en un producto con variantes obligatorias.** Fila con habitación vacía → «El producto PROP-0002 requiere variante; indique la habitación en el CSV.» Solución: poner el código de habitación maestra en la columna 5.

---

## 10. Resolución de problemas (FAQ)

| Síntoma | Causa probable | Solución |
|---|---|---|
| Todas las líneas dan «El origen "Campo NIF personalizado" no está implementado». | *Origen del NIF* del Setup mal configurado. | Ponerlo en *Nº identificación fiscal*. |
| «La propiedad … no existe como producto o está bloqueada.» | La columna 4 no coincide con un nº de producto, o el producto está bloqueado. | Comprobar el código en la lista de productos (se compara en mayúsculas). |
| «La propiedad … no existe.» en un código de alquiler o fianza. | La propiedad existe como producto pero no en el módulo de propiedades, o con otro código. | Dar de alta la propiedad con el mismo código que el producto (o usar el asistente). |
| «La habitación … no existe en la propiedad ….» | La variante existe pero la subpropiedad no, o su código difiere. | Crear la subpropiedad con el mismo código que la variante, o usar el código de habitación maestra. |
| «La propiedad … se alquila por habitaciones; indique la habitación en el CSV.» | Propiedad de tipo *Por subpropiedades* con la habitación vacía o con el código maestro. | Indicar la subpropiedad concreta en la columna 5. |
| «La propiedad … se alquila completa; deje la habitación vacía o use el código de habitación maestra…» | Propiedad de tipo *Propiedad completa* con una habitación concreta en la columna 5. | Dejar la columna 5 vacía o poner el código de habitación maestra. |
| «El producto … requiere variante; indique la habitación en el CSV.» | Producto con variantes y *Variante obligatoria si existe*. | Informar la columna 5 (habitación o código maestro). |
| «La unidad de medida … de la configuración de facturación no existe para el producto ….» | La fila de facturación tiene unidad (p. ej. MES) que el producto no tiene. | Añadir la unidad al producto o quitarla de la fila de facturación. |
| «El CSV trae una línea de negocio pero el "Cód. dimensión…" no está configurado…» | Falta el código de dimensión en el Setup. | Configurarlo (4.1) o vaciar la columna en el CSV. |
| «Código de fianza …: el Banco de Gestión … es obligatorio.» | La fila de facturación de fianza no tiene banco. | Informar el Banco de Gestión en esa fila. |
| Al procesar: «Grupo registro producto general debe tener un valor…» o error de *Configuración registro IVA*. | El producto de la propiedad no tiene grupos contables o falta la combinación con los del cliente. | Completar la ficha del producto y las configuraciones de registro. |
| Al procesar: error de dimensión *Código obligatorio* / *Mismo código*. | Dimensión predeterminada del cliente o del producto incompatible con los valores del CSV. | Ajustar las dimensiones predeterminadas o los valores del CSV. |
| Al procesar fianzas: «Fecha registro debe tener un valor». | La línea de fianza no trae fecha de registro. | Informar la columna 3 (o la fecha en la línea del buffer) y revalidar. |
| El proceso se detuvo con error a mitad de lote. | Un documento no pasó las validaciones de creación o registro (ver 7.3). | Las líneas ya procesadas están enlazadas a su documento (registrado o borrador). Corrija la causa, registre el borrador pendiente desde *Navigate to Generated Document* y vuelva a lanzar *Post Batch* para el resto. |
| Se creó una reserva *Pendiente* sin inquilino. | No había reserva activa que sirviera y el cliente no tiene exactamente un inquilino vinculado (campo *Nº cliente* de la ficha de inquilino). | Completar la reserva (inquilino, fechas, contrato) y vincular el inquilino al cliente para las próximas importaciones. |

---

## 11. Limitaciones conocidas

- *Origen del NIF* = *Campo NIF personalizado* no está implementado.
- Para códigos de alquiler y fianza, el código de propiedad debe ser idéntico al nº de producto y el de habitación al de variante. No hay tabla de correspondencia.
- En facturas agrupadas, el nº de documento externo, la reserva de la cabecera y las dimensiones de la cabecera salen de la **primera línea** del grupo.
- La reserva solo se distingue por cliente cuando los inquilinos tienen informado el *Nº cliente*; sin ese vínculo se toma la reserva activa más reciente. Las reservas creadas por el proceso no comprueban disponibilidad.
- Los valores de la dimensión de unidad se crean automáticamente con el código como nombre; línea de negocio y canal no.
- Los textos se truncan a la longitud del campo sin aviso (concepto a 100 caracteres).
- Un error de registro detiene el lote; hay que registrar a mano el borrador que quedó enlazado y relanzar el resto (ver 7.3).
- No se comprueba que la propiedad pertenezca al cliente o al propietario indicado.

---

## 12. Historial de versiones

| Fecha | Cambio |
|---|---|
| 2026-09-15 | Correcciones derivadas de la revisión: detección de cabecera por fecha e importe, validación del tipo de alquiler de la propiedad, marcas del buffer confirmadas antes y después de registrar cada factura, fianza importada marcada como registrada, y reserva elegida por el inquilino del cliente. |
| 2026-09-15 | Primera versión del manual. Cubre la plantilla de 12 columnas (propiedad, habitación, línea de negocio, canal y unidad), los códigos de alquiler y fianza, y las validaciones de importación, validación, generación y archivo. |

---

*Documento del módulo de facturación recurrente de `Neelo Core Solutions by BeDynamic`. Ante dudas funcionales, contacte con el equipo de BeDynamic.*
