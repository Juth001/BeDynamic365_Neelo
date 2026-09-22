# Manual técnico y funcional — Importación CSV y Facturación Recurrente

**Módulo de la app:** Neelo Core Solutions by BeDynamic · **Namespace:** `Neelo.RecurringInvoicing`
**Plataforma:** Business Central (localización española — Cartera ES)
**Rango de objetos:** 81000–81026
**Última actualización:** 2026-07-26

---

## 1. Visión general

Esta solución permite **importar un fichero CSV** con líneas a facturar, **revisarlas y validarlas** en una tabla intermedia (*staging*) y, finalmente, **generar y registrar facturas de venta** en Business Central de forma masiva.

Además, propaga un **Banco de Gestión** desde la ficha del cliente hasta la factura registrada, los movimientos de cliente y la **Cartera (localización española)**, de modo que las **remesas de cobro** puedan filtrarse por el banco que gestiona cada documento.

El proceso se resume en tres pasos:

```
   ┌────────────┐      ┌────────────┐      ┌──────────────────┐
   │ 1. IMPORTAR│ ───▶ │ 2. VALIDAR │ ───▶ │ 3. GENERAR/       │
   │   (CSV)    │      │  (staging) │      │    REGISTRAR      │
   └────────────┘      └────────────┘      └──────────────────┘
     Lote nuevo          Pendiente            Factura de venta
   con líneas en        → Validada /         (borrador o registrada)
     "Pendiente"        → Error
```

---

## 2. Conceptos clave

| Concepto | Descripción |
|---|---|
| **Lote (Import Batch)** | Cada importación crea un lote con un código único (p. ej. `IMP20260624103015`). Todas las líneas del fichero pertenecen a ese lote. |
| **Línea de staging** | Cada fila del CSV se convierte en una línea de la tabla intermedia *Buffer Importación Facturas*, donde se revisa antes de facturar. |
| **Código de Facturación** | Código de la columna A del CSV (p. ej. `REC`, `EXTRA`). Se define en la tabla maestra *Códigos de Facturación* y se configura **por cliente** (tabla *Customer Billing*) con su cuenta, banco y agrupación. |
| **Banco de Gestión** | Banco que gestiona el cobro. Se define en cada **fila de facturación del cliente** (cliente + código) y se propaga a la factura, los movimientos y la Cartera. |
| **Agrupación (Grouping)** | Modo de facturación de cada fila de facturación: **Agrupada** (una factura por cliente, código y fecha de registro) o **Individual** (una factura por línea). |
| **Cuenta (Tipo / Nº)** | Producto, recurso o cuenta contable que se factura en la línea. Se configura en cada fila de facturación del cliente. |

---

## 3. Inventario de objetos (referencia técnica)

| Objeto | ID | Nombre | Función |
|---|---|---|---|
| Table | 81000 | BeDyn Recurring Inv. Setup | Configuración (singleton). |
| Table | 81001 | BeDyn Invoice Import Buffer | Tabla de staging de líneas importadas. |
| Table | 81002 | BeDyn Customer Billing | Configuración de facturación por cliente y código (banco, cuenta, agrupación). |
| Table | 81003 | BeDyn Billing Code | Tabla maestra de códigos de facturación (Código + Descripción). |
| Page | 81002 | BeDyn Recurring Inv. Setup | Ficha de configuración. |
| Page | 81003 | BeDyn Invoice Import Buffer | Lista de revisión/proceso de líneas. |
| Page | 81004 | BeDyn Customer Billing | Lista de configuración de facturación (dato relacionado del cliente). |
| Page | 81005 | BeDyn Billing Codes | Lista maestra de códigos de facturación. |
| Codeunit | 81009 | BeDyn Import Mgt. | Lee y parsea el CSV. |
| Codeunit | 81010 | BeDyn Validation Mgt. | Valida las líneas. |
| Codeunit | 81011 | BeDyn Posting Mgt. | Genera y registra las facturas. |
| Codeunit | 81012 | BeDyn Posting Subscribers | Propaga el Banco de Gestión a factura/movimientos. |
| Codeunit | 81013 | BeDyn Remittance Subscribers | Aplica el filtro de banco en la remesa. |
| Codeunit | 81022 | BeDyn Cartera Subscribers | Propaga el Banco de Gestión a la Cartera. |
| Codeunit | 81024 | BeDyn Remittance Context | Contexto de sesión con el banco de la remesa. |
| Codeunit | 81021 | BeDyn Validation Tests | Pruebas automáticas de la validación. |
| Enum | 81004 | BeDyn Billing Type | Clasificación de la fila de facturación: Recurrente / Extra. |
| Enum | 81005 | BeDyn Buffer Status | Pendiente / Validada / Error / Procesada / Ignorada. |
| Enum | 81006 | BeDyn Invoice Grouping | Agrupada / Individual. |
| Enum | 81007 | BeDyn Billing Concept Type | Cuenta contable / Producto / Recurso (tipo de cuenta). |
| Enum | 81008 | BeDyn NIF Source | Origen del NIF (CIF/NIF estándar o campo personalizado). |
| TableExt | 81015–81018 | BeDyn Sales Header / BeDyn Sales Invoice Header / BeDyn Cust. Ledger Entry / BeDyn Cartera Doc. | Campo *Banco de Gestión*. |
| PageExt | 81019 / 81020 | BeDyn Customer Card / BeDyn Sales Invoice | Muestran la subpágina de facturación y el banco. |
| PageExt | 81023 / 81025 / 81026 | BeDyn Receiv. Cartera Docs / BeDyn Bill Groups / BeDyn Cartera Documents | Soporte y visibilidad del filtro por banco en remesas. |

---

## 4. Configuración inicial (una sola vez)

### 4.1 Ficha de configuración

Busque la página **Configuración Facturación Recurrente** (categoría *Administración*) y complete:

**Grupo General**
- **Activo**: debe estar marcado para poder importar y registrar. *(Si está desmarcado, cualquier acción da el error «La configuración de facturación recurrente no está activa».)*
- **Registrar automáticamente**: si está marcado, las facturas se **registran** al procesar; si se desmarca, se dejan como **borrador** de factura de venta para revisión manual.
- **Insertar Comentarios**: si está marcado, las líneas **sin importe** se importan como líneas de **comentario** (solo en códigos de facturación con agrupación *Agrupada*).
- **Ignorar Comentarios**: en códigos de facturación con agrupación *Individual*, ignora las líneas de comentario que no pueden vincularse a una factura concreta. Excepción: si hay exactamente **1 comentario + 1 línea facturable**, se crea una única factura con ambos.

**Grupo Fichero CSV**
- **Separador CSV**: carácter separador de campos (por defecto `;`).
- **Tiene cabecera**: marque si la primera fila del CSV es una cabecera y debe omitirse.
- **Origen del NIF**: campo del cliente usado para localizarlo por CIF/NIF. *(Actualmente soportado: «CIF/NIF» estándar. La opción «Campo NIF personalizado» aún no está implementada y, si se selecciona, la validación devuelve un error.)*
- **Precios IVA incluido**: marque si los importes de la plantilla CSV llevan el **IVA incluido**. Las facturas generadas se crean con *Precios IVA incluido* según este valor (sobrescribe el valor por defecto de la ficha de cliente), de modo que el importe importado se interpreta siempre igual que en la plantilla.

> El mapeo de cuenta (antes *Concepto Recurrente/Extra* en la configuración) se define ahora **por cliente** en la subpágina *Facturación Recurrente* de la ficha de cliente (ver 4.2).

### 4.2 Datos maestros del cliente

En la **Ficha de Cliente**, menú *Relacionado → Cliente → Facturación Recurrente*, defina una fila por cada **código de facturación** que pueda venir en el CSV (columna 1). La clave de cada fila es **código de facturación + nº cuenta**, por lo que un mismo código puede repetirse con cuentas distintas (si hay varias filas, el import usa la primera por nº de cuenta). Cada fila indica:
- **Código Facturación**: se elige de la tabla maestra **Códigos de Facturación** (búsquela por *Tell me*); es lo que se empareja con la columna 1 del CSV (p. ej. `REC`, `EXTRA`). Defina antes los códigos y su descripción en esa tabla maestra.
- **Tipo Facturación**: clasificación *Recurrente* o *Extra* (informativa).
- **Tipo cuenta** y **Cód. cuenta**: tipo de línea de factura (Cuenta contable / Producto / Recurso) y su número (la lista se filtra según el tipo y solo muestra elementos **no bloqueados**; en cuentas contables, de tipo *Registro*).
- **Cód. variante** *(solo productos)*: variante del producto que se estampa en la línea de factura generada. BC estándar **no** asigna ninguna variante por defecto; si el producto tiene variantes y exige variante (*Variante obligatoria si existe*), debe informarse aquí o la validación marcará la línea con error.
- **Unidad medida predeterminada** *(opcional)*: unidad de medida que se pone en la línea de factura generada. Si se deja vacía, se usa la predeterminada del producto/recurso (comportamiento estándar de BC).
- **Banco de Gestión** *(opcional)*: cuenta bancaria que gestiona el cobro de las facturas de ese código. *(No puede estar bloqueada; se valida al introducirla.)* Permite, p. ej., cobrar las recurrentes por un banco y las extras por otro. Si se deja vacío, la factura se genera sin banco y no se filtra en las remesas.
- **Agrupación**: *Agrupada* (una factura por cliente, código y fecha de registro) o *Individual* (una factura por línea).

> Para cada línea del CSV debe existir la fila (cliente + código de facturación) con **cuenta** válida; de lo contrario la línea se marca con error (ver validaciones). El **Banco de Gestión** es opcional, pero si está informado debe existir y no estar bloqueado.

---

## 5. Formato del fichero CSV

La estructura de columnas confirmada es:

| Col. | Campo | Obligatorio | Notas |
|---|---|---|---|
| **A** (1) | **CÓDIGO FACTURACIÓN** | Sí | Código con el que se localiza la fila de facturación del cliente (p. ej. `REC`, `EXTRA`; no distingue mayúsc./minúsc.). Determina cuenta, banco y agrupación de la factura. |
| **B** (2) | **CIF/NIF** | Sí | Se usa para localizar el cliente. |
| **C** (3) | **FECHA REGISTRO** | No | Fecha de registro de la factura. Formato día-primero (`dd/mm/aaaa`). |
| **D** (4) | **DOCUMENTO EXTERNO** | No | Se vuelca al *Nº documento externo* de la factura. |
| **E** (5) | **CONCEPTO** | No | Texto descriptivo; sustituye la descripción del producto/cuenta en la línea de factura. |
| **F** (6) | **IMPORTE** | Sí* | Importe a facturar. (*Vacío = 0 → la validación lo marca con error salvo que sea comentario.) |
| **G** (7) | **ID BC** | No | Nº de cliente BC. **Solo** se usa para **desempatar** cuando el CIF/NIF corresponde a varios clientes (ver punto siguiente). |
| **H** (8) | **GRUPO IVA PRODUCTO** | No | Grupo registro IVA producto. Si viene informado, se **asigna a la línea de factura** (sobrescribe el que se heredaría del producto/cuenta); si viene vacío, la línea usa el del producto/cuenta. Se valida que el grupo exista. |

> **Plantilla oficial** (fila de cabecera incluida), disponible con ejemplos en `docs/Plantilla-Importacion.csv`:
> `CODIGO FACTURACION;CIF/NIF;FECHA REGISTRO;DOCUMENTO EXTERNO;CONCEPTO;IMPORTE;ID BC;GRUPO IVA PRODUCTO`

> **Importante sobre el ID BC:** el **CIF/NIF es siempre el criterio principal** para localizar el cliente. La columna *ID BC* puede venir rellena en todas las filas del fichero de origen (es lo habitual), pero **se ignora** cuando el NIF identifica a un único cliente; únicamente se consulta cuando un mismo NIF corresponde a **varios** clientes, para elegir cuál de ellos es el correcto.

### Reglas de parseo

- **Separador**: el configurado en el *Setup* (por defecto `;`).
- **Cabecera**: si *Tiene cabecera* está activo, se omite la primera fila.
- **Comillas y multilínea**: se admiten campos entre comillas `"…"`, comillas escapadas (`""`) y conceptos que ocupan **varias líneas físicas** (los saltos de línea dentro de comillas se convierten en espacios).
- **Importe**: admite formato español (`1.234,56`) e inglés (`1234.56`). Regla: si hay coma, la coma es el separador decimal y los puntos son de millares; si solo hay puntos y el último grupo tiene 3 dígitos, el punto se trata como separador de millares.
- **Fecha**: formato día-primero. Admite separadores `/`, `-` o `.` y año de 2 o 4 dígitos (años de 2 dígitos se interpretan como 20xx). Si la fecha viene **vacía**, la factura usará la fecha por defecto del sistema; si viene pero **no es válida**, la línea se marca con error.
- **Filas vacías**: se ignoran.

### Plantilla de particulares

Para la facturación a **particulares** (alquileres por propiedad) existe un segundo layout, importado con la acción **Import Individuals CSV** de la página *Importación Facturas* (procedimiento `ImportIndividualsCSV` del codeunit *Import Mgt.*). Respecto al estándar, la columna 4 pasa a ser la **propiedad** (nº de producto), se inserta la **habitación** (variante) antes del concepto y se añaden al final tres columnas opcionales de dimensiones:

| Col. | Campo | Oblig. | Campo del buffer / uso |
|---|---|:---:|---|
| **1** | CÓDIGO FACTURACIÓN | Sí | *Billing Code*. Igual que en el estándar. |
| **2** | CIF/NIF | No | *VAT Registration No.* Puede venir vacío: el cliente se resuelve entonces directamente por *ID BC*. |
| **3** | FECHA REGISTRO | No | *Posting Date*. Mismo parseo que el estándar. |
| **4** | PROPIEDAD | Sí | *Property Code*. Nº de producto que se factura en la línea (tipo Producto) en lugar de la cuenta/producto de la configuración de facturación. Se copia también a *External Document No.* |
| **5** | HABITACIÓN | Según | *Variant Code*. Variante del producto; obligatoria cuando el producto tiene variantes y *Variante obligatoria si existe* lo exige. El *Código de habitación maestra* del Setup de propiedades equivale a la propiedad completa (reserva sin habitación). |
| **6** | CONCEPTO | No | *Description*. |
| **7** | IMPORTE | Sí | *Amount*. Mismo parseo que el estándar. |
| **8** | ID BC | No | *BC Customer No.* Obligatorio si el NIF va vacío; en caso contrario, desempate de NIF repetidos. |
| **9** | GRUPO IVA PRODUCTO | No | *VAT Prod. Posting Group*. Igual que en el estándar. |
| **10** | LÍNEA NEGOCIO | No | *Business Line Code*. Valor de la dimensión configurada en *Business Line Dimension Code* del Setup. |
| **11** | CANAL | No | *Channel Code*. Valor de la dimensión configurada en *Channel Dimension Code* del Setup. |
| **12** | UNIDAD | No | *Unit Code*. Valor de la dimensión configurada en *Unit Dimension Code* del Setup. |

> **Plantilla oficial** (fila de cabecera incluida), disponible con ejemplos en `docs/Colaboradores/Plantilla-Importacion-Particulares.csv`:
> `CODIGO FACTURACION;CIF/NIF;FECHA REGISTRO;PROPIEDAD;HABITACION;CONCEPTO;IMPORTE;ID BC;GRUPO IVA PRODUCTO;LINEA NEGOCIO;CANAL;UNIDAD`

El detalle completo de esta plantilla (configuración, códigos de alquiler y fianza y todas las validaciones de cada paso) está en el [Manual de particulares](Manual-Particulares.md).

Particularidades de este layout:

- **Cabecera**: se detecta automáticamente (si ni la columna 3 de la primera fila es una fecha ni la columna 7 es un importe, la fila se omite), con independencia de *Tiene cabecera*.
- **Mayúsculas**: código de facturación, propiedad, habitación, ID BC, grupo IVA y las tres dimensiones se pasan a mayúsculas al importar.
- **Validación del producto**: la propiedad debe existir como producto no bloqueado; la habitación, como variante no bloqueada del producto; y la unidad de medida de la configuración de facturación debe existir para el producto.
- **Dimensiones**: cada valor debe existir y no estar bloqueado en la dimensión configurada. Si el CSV trae un valor y la dimensión correspondiente no está configurada en el Setup, la línea da error. Los valores se estampan en la cabecera y en las líneas de la factura (o en la línea de diario, en códigos de fianza).
- **Códigos de alquiler y fianza**: la propiedad debe existir además como *Propiedad* del módulo de propiedades y la habitación debe corresponder a su tipo de alquiler (subpropiedad existente si se alquila por subpropiedades; vacía o maestra si se alquila completa), porque se vincula la reserva.

---

## 6. Flujo de trabajo (operativa)

Todo se realiza desde la página **Importación Facturas** (categoría *Tareas*).

### Paso 1 — Importar CSV
Acción **Importar CSV** → seleccione el fichero. Se crea un **lote nuevo** y todas las líneas quedan en estado **Pendiente**. Se muestra cuántas líneas se importaron y el código de lote. Para la plantilla de particulares, acción **Import Individuals CSV** (ver *Plantilla de particulares* en el apartado 5).

### Paso 2 — Validar lote
Acción **Validar lote** (sobre cualquier línea del lote). Cada línea pasa a **Validada** o **Error**. Las líneas con error muestran el detalle en *Mensaje de error* (en rojo). Puede corregir datos maestros (cliente, banco, concepto…) y **volver a validar** las veces que necesite.

### Paso 3 — Generar / Registrar
- **Registrar lote**: procesa **todas** las líneas *Validadas* del lote.
- **Procesar líneas seleccionadas**: procesa solo las líneas *Validadas* que estén seleccionadas.

Según el *Setup*, las facturas se **registran** (si *Registrar automáticamente* está activo) o se dejan en **borrador**. La línea pasa a **Procesada** y se guarda el *Nº documento generado*.

### Acciones auxiliares
- **Eliminar lote**: borra todas las líneas del lote (pide confirmación).
- **Ver todos los lotes**: quita el filtro de lote.
- **Navegar al documento generado**: abre la factura (registrada o borrador) de la línea.
- **Crear cliente**: crea un cliente desde plantilla y abre su ficha (útil cuando el NIF no existe).

---

## 7. Validaciones que realiza la solución

> **Principio de localización del cliente:** el cliente se identifica **siempre por el CIF/NIF**. El *ID BC* nunca sustituye a esa búsqueda; solo actúa como desempate cuando el NIF está duplicado entre varios clientes.

Al **validar** cada línea se comprueba, en este orden, y se captura el **primer** error encontrado:

| # | Validación | Mensaje / Resultado |
|---|---|---|
| 1 | **Cliente por CIF/NIF** | El NIF se normaliza (mayúsculas, sin espacios/puntos/guiones) y se busca el cliente. |
| | → No existe | «No se encontró ningún cliente con el NIF "…".» |
| | → Varios clientes con el mismo NIF | Se usa la columna **ID BC** para elegir; si está vacía o no coincide con ninguno de ellos: «El NIF "…" corresponde a más de un cliente; indique el ID BC para elegir uno.» |
| 2 | **Cliente bloqueado** | «El cliente … está bloqueado (…).» (bloqueos *Factura* o *Todos*). |
| 3 | **Grupo contable de cliente** | «El cliente … no tiene grupo contable de cliente.» |
| 4 | **Configuración de facturación** | «El cliente … no tiene la configuración de facturación "…".» (no existe la fila cliente + código de facturación de la columna 1). |
| 5 | **Importe / cuenta** | Si el importe es 0: ver tratamiento de comentarios (abajo). Si no, se valida la **cuenta** de la fila: «La cuenta … (…) no existe o está bloqueada.» (cuenta/producto/recurso existente, no bloqueado y, en cuentas, de tipo *Registro*). |
| 6 | **Variante** (solo productos) | Si la fila tiene variante: «La variante … del producto … no existe o está bloqueada.» Si no la tiene pero el producto la exige (*Variante obligatoria si existe*): «El producto … requiere variante; indíquela en la configuración de facturación "…".» |
| 7 | **Unidad de medida** (solo si la fila la tiene; es opcional) | «La unidad de medida … no existe para … ….» (debe existir para el producto/recurso). |
| 8 | **Banco válido / no bloqueado** (solo si la fila tiene banco; es opcional) | «El Banco de Gestión … no existe o está bloqueado.» |
| 9 | **Grupo IVA producto** (si viene en el CSV) | «El grupo registro IVA producto "…" no existe.» |

Durante la **importación** (antes de validar) también se detectan:
- **Importe no numérico**: «Importe no numérico: "…".»
- **Fecha de registro no válida**: «Fecha de registro no válida: "…".»

### Tratamiento de líneas sin importe (comentarios)
- *Insertar Comentarios* **desactivado** → error «El importe no puede ser cero.»
- *Insertar Comentarios* **activado** + código de facturación **Agrupado** → la línea se importa como **comentario** (sin importe).
- *Insertar Comentarios* **activado** + código de facturación **Individual**:
  - Sin *Ignorar Comentarios* → error «Las líneas sin importe solo pueden importarse como comentarios cuando el código de facturación usa agrupación…».
  - Con *Ignorar Comentarios* → el comentario se mantiene y el registro decide: si hay **1 comentario + 1 línea** se combinan en una factura; en otro caso el comentario se marca **Ignorada**.

---

## 8. Generación de facturas (detalle)

Las líneas validadas se agrupan **por cliente y código de facturación** y se procesan según el modo de *Agrupación* de esa fila. El **Banco de Gestión** y la **cuenta** de la factura salen de esa fila (así se pueden cobrar, p. ej., las recurrentes por un banco y las extras por otro). La cabecera se crea con *Precios IVA incluido* según la opción **Precios IVA incluido** de la configuración (ver 4.1).

**Código Agrupado**
- Se crea **una factura por cada fecha de registro**: todas las líneas de ese cliente y código con la **misma *Fecha Registro*** del CSV (incluidos comentarios) van a la misma factura.

**Código Individual**
- **Una factura por cada línea** facturable.
- Excepción (con *Ignorar Comentarios*): 1 comentario + 1 línea → una sola factura con ambos.
- Los comentarios que no pueden vincularse se marcan **Ignorada**.

**En la cabecera de cada factura se vuelca:**
- **Cliente** y su **Banco de Gestión**.
- **Fecha de registro** y **Fecha de documento** = *Fecha Registro* del CSV (si viene informada). En facturas agrupadas es la fecha común a todas las líneas del grupo.
- **Nº documento externo** = *Documento Externo* del CSV (si viene informado).

**En cada línea de factura:**
- Tipo y Nº de **cuenta** según la fila de facturación del cliente (código de la columna 1).
- Cantidad = 1, Precio unitario = *Importe* del CSV.
- Descripción = *Concepto* del CSV (sustituye la descripción del producto/cuenta).
- Las líneas de comentario se crean con tipo en blanco y solo la descripción.

---

## 9. Propagación del Banco de Gestión y remesas

El **Banco de Gestión** de la **fila de facturación** (según el código de la columna 1) se estampa en la factura generada y se propaga automáticamente a:
- La **factura registrada** (se copia desde la factura de venta por `TransferFields`).
- Los **movimientos de cliente**.
- Los **documentos de Cartera** (localización española) al registrar, leyéndolo de la factura registrada.

> Las facturas creadas **fuera del import** (a mano) no reciben banco automáticamente; puede informarlo en el campo *Banco de Gestión* de la factura.

En las **remesas (Cartera ES)**, al **insertar documentos a cobrar** en una remesa (página *Documentos Cartera*):
- La selección se **filtra automáticamente** por el banco de la remesa: solo se muestran e insertan los documentos cuyo Banco de Gestión esté **vacío** o **coincida** con el banco del grupo de remesa. La columna *Banco de Gestión* es visible para ordenar/consultar.
- Como **salvaguarda adicional**, tras la inserción se **eliminan** del grupo los documentos cuyo Banco de Gestión esté informado y **no coincida** con el banco de la remesa (cubre también documentos añadidos por otras vías). Los documentos **sin** Banco de Gestión no se tocan.

> *Técnico:* el filtro se aplica suscribiéndose al evento `OnInsertReceivableDocsOnAfterSetFilters` de la codeunit estándar `CarteraManagement`, que se dispara justo antes de mostrar la página de selección de documentos.

---

## 10. Tips y buenas prácticas

1. **Prepare los datos maestros antes de importar.** Que todos los clientes tengan **CIF/NIF** y **grupo contable**, y que cada **código de facturación** que use el CSV exista en la subpágina *Facturación Recurrente* del cliente con una **cuenta** válida (y, si quiere remesar por banco, su **Banco de Gestión**). Así la validación pasa a la primera.
2. **Valide siempre antes de registrar.** El estado por colores ayuda: 🔴 Error, 🟢 Validada, azul = Procesada, gris = Ignorada.
3. **Use la columna ID BC solo cuando haga falta.** La búsqueda normal es por NIF; rellene *ID BC* únicamente en clientes que comparten CIF/NIF (p. ej. matrices/filiales) para resolver la ambigüedad.
4. **Pruebe con *Registrar automáticamente* desactivado.** En las primeras cargas deje las facturas en **borrador** para revisarlas antes de registrar; cuando el flujo esté validado, actívelo.
5. **Conceptos (texto) por línea.** La columna *Concepto* del CSV sobrescribe la descripción del producto/cuenta: úsela para que la factura muestre el detalle deseado.
6. **Comentarios.** Si necesita texto adicional en códigos de facturación **agrupados**, active *Insertar Comentarios* y añada filas sin importe. Recuerde que en códigos **individuales** los comentarios sueltos se ignoran (salvo el caso 1+1).
7. **Formato de fecha e importe.** Mantenga las fechas en `dd/mm/aaaa` y revise el separador decimal. Si el origen exporta importes con punto de millares, el parser lo interpreta, pero conviene homogeneizar.
8. **Separador y cabecera coherentes con el fichero.** Si el CSV cambia de origen, verifique en el *Setup* el separador y si lleva fila de cabecera.
9. **Un lote por carga.** Importe cada fichero por separado; si algo sale mal, **Eliminar lote** deja todo limpio para reintentar.
10. **Banco de Gestión = control de remesas.** Asignar bien el banco en cada fila de facturación del cliente es lo que permite filtrar las remesas por banco; revíselo en clientes nuevos.

---

## 11. Resolución de problemas (FAQ)

| Síntoma | Causa probable | Solución |
|---|---|---|
| «La configuración… no está activa» | *Activo* desmarcado en el *Setup*. | Marque **Activo**. |
| No se importa ninguna línea | Fichero vacío, separador incorrecto o todas las filas vacías. | Revise separador y contenido del CSV. |
| Todas las filas se desplazan / datos en columnas erróneas | Separador del *Setup* distinto al del fichero. | Ajuste **Separador CSV**. |
| «El importe no puede ser cero» | Línea sin importe con *Insertar Comentarios* desactivado. | Corrija el importe o active *Insertar Comentarios* (códigos agrupados). |
| «No se encontró ningún cliente con el NIF» | El cliente no existe o el NIF no coincide. | Cree el cliente (acción **Crear cliente**) o corrija el NIF. |
| «…corresponde a más de un cliente» | Varios clientes con el mismo NIF y sin *ID BC*. | Rellene la columna **ID BC** con el nº de cliente correcto. |
| «…no tiene la configuración de facturación "…"» | No existe la fila cliente + código de la columna 1 del CSV. | Cree la fila en la subpágina *Facturación Recurrente* del cliente. |
| «La cuenta … no existe o está bloqueada» | *Tipo/Cód. cuenta* de la fila de facturación inexistente, bloqueado o (en cuentas contables) no de tipo *Registro*. | Revise la cuenta en la subpágina *Facturación Recurrente* del cliente. |
| «El producto … requiere variante» | El producto tiene variantes y exige variante, pero la fila de facturación no tiene *Cód. variante*. | Informe el **Cód. variante** en la subpágina *Facturación Recurrente* del cliente. |
| «La variante … no existe o está bloqueada» | El *Cód. variante* de la fila no existe para ese producto o está bloqueado. | Revise la variante en la subpágina *Facturación Recurrente*. |
| «La unidad de medida … no existe» | La *Unidad medida predeterminada* de la fila no existe para el producto/recurso. | Revise la unidad de medida en la subpágina *Facturación Recurrente* (debe estar dada de alta en las unidades de medida del producto/recurso). |
| «El grupo registro IVA producto "…" no existe» | Columna H del CSV con un grupo IVA inexistente. | Corrija el valor del CSV o cree el grupo registro IVA producto. |
| «Fecha de registro no válida» | Formato de fecha no reconocido. | Use `dd/mm/aaaa`. |
| Documento de remesa desaparece del grupo | Su Banco de Gestión no coincide con el de la remesa. | Use la remesa del banco correcto o ajuste el Banco de Gestión de la fila de facturación (para facturas futuras). |

---

## 12. Limitaciones conocidas

- El origen del NIF **«Campo NIF personalizado»** aún no está implementado (la validación devuelve error si se selecciona).
- La desambiguación por **ID BC** requiere que el valor sea **uno de los clientes** que comparten ese NIF; si no coincide, la línea queda en error (no se elige un cliente arbitrario).
- La estructura de columnas del CSV es **posicional** (A–H); cambios en el orden de columnas requieren ajuste de la solución.

---

## 13. Historial de versiones

| Fecha | Cambio |
|---|---|
| 2026-09-15 | Se documenta la **plantilla de particulares** (12 columnas: propiedad, habitación, línea de negocio, canal y unidad) y se añade `docs/Colaboradores/Plantilla-Importacion-Particulares.csv` con ejemplos. Nuevo [Manual de particulares](Manual-Particulares.md) con la configuración, los códigos de alquiler y fianza y las validaciones de cada paso. Correcciones en la plantilla de particulares: detección de cabecera por fecha e importe, validación del tipo de alquiler de la propiedad, marcas del buffer confirmadas al registrar cada factura, fianza importada marcada como registrada y reserva elegida por el inquilino del cliente. |
| 2026-07-13 | Versión **1.0.0.1**: se protege el código de la extensión (sin depuración ni descarga de código fuente). Revisión del manual: conceptos clave y FAQ alineados con la configuración de facturación por cliente; referencia a la plantilla `docs/Plantilla-Importacion.csv`. |
| 2026-07-08 | La configuración de facturación del cliente deja de mostrarse incrustada en la ficha y pasa a **dato relacionado** (*Relacionado → Cliente → Facturación Recurrente*). Nueva tabla maestra **Códigos de Facturación** (Código + Descripción) enlazada con el campo *Código Facturación*. |
| 2026-07-08 | **Configuración de facturación por cliente** (tabla *Customer Billing*): la columna 1 del CSV pasa a ser un **Código Facturación** que localiza, por cliente, la **cuenta**, el **Banco de Gestión** y la **agrupación** de la factura. Se retiran del cliente los campos *Agrupación* y *Banco de Gestión* y del *Setup* el mapeo de concepto REC/Extra. El banco se propaga ahora desde la factura generada (no desde el cliente), lo que permite cobrar cada código por un banco distinto. |
| 2026-07-08 | Nueva columna **Grupo IVA Producto** (H): si viene informada, el grupo registro IVA producto se asigna a la línea de factura en lugar de heredarlo del producto/cuenta; se valida que exista. |
| 2026-06-24 | Remesas: el filtro por banco se aplica ahora sobre la página real de selección (*Documentos Cartera*, 7000003) mediante el evento `OnInsertReceivableDocsOnAfterSetFilters`, de modo que solo se ofrecen documentos del banco de la remesa (o sin banco). |
| 2026-06-24 | Plantilla definitiva del CSV: 7 columnas `TIPO;CIF/NIF;FECHA REGISTRO;DOCUMENTO EXTERNO;CONCEPTO;IMPORTE;ID BC` (se retira la columna *Nombre*, que no se utilizaba). |
| 2026-06-24 | Nueva columna **ID BC** como desempate cuando el CIF/NIF corresponde a varios clientes (la búsqueda principal sigue siendo por NIF). |
| 2026-06-24 | Nuevas columnas **Fecha Registro** y **Documento Externo**, que se vuelcan a la fecha de registro/documento y al nº de documento externo de la factura. |

---

*Documento del módulo de facturación recurrente de `Neelo Core Solutions by BeDynamic`. Ante dudas funcionales, contacte con el equipo de BeDynamic.*
