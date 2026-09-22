# Manual de Usuario — Importación de facturación de colaboradores

> Documento fuente para maquetación. Los bloques **[CAPTURA]** indican qué pantalla debe fotografiarse y qué debe verse en ella.

El módulo importa un fichero **CSV** con las líneas que hay que facturar, las **valida** contra los datos maestros y **genera** (o registra) las facturas de venta en Business Central. Además, envía cada cobro al **banco correcto** para que las **remesas** salgan bien.

El flujo diario es siempre el mismo: **Importar → Validar → Registrar**.

---

## 1. Antes de empezar (configuración, una sola vez)

### 1.1 Configuración general

Abra **Configuración Facturación Recurrente** (búsquela con *Tell me* / categoría *Administración*).

| Campo | Para qué sirve |
|---|---|
| **Activo** | Debe estar marcado para poder importar y registrar. |
| **Registrar automáticamente** | Marcado: las facturas se registran al procesar. Desmarcado: se quedan en **borrador** para revisarlas. |
| **Insertar Comentarios** | Permite importar líneas **sin importe** como comentarios en la factura (solo en códigos con agrupación *Agrupada*). |
| **Ignorar Comentarios** | En códigos *Individuales*, ignora los comentarios que no puedan vincularse a una factura. |
| **Separador CSV** | Carácter que separa las columnas del fichero (por defecto `;`). |
| **Tiene cabecera** | Marque si la primera fila del CSV es un encabezado y debe omitirse. |
| **Origen del NIF** | Campo del cliente por el que se localiza (CIF/NIF estándar). |

> **[CAPTURA 1]** Ficha *Configuración Facturación Recurrente* con los grupos **General** y **Fichero CSV** visibles y rellenos (Activo marcado, separador `;`).

### 1.2 Códigos de Facturación

Abra **Códigos de Facturación** (*Tell me*) y cree un código por cada tipo de línea que vaya a venir en el CSV, con su descripción.

| Código | Descripción |
|---|---|
| `REC` | Cuota recurrente |
| `EXTRA` | Servicio puntual |

> Estos códigos son los que se escribirán en la **columna 1** del CSV.

> **[CAPTURA 2]** Lista *Códigos de Facturación* con dos o tres filas (REC, EXTRA…) y su descripción.

### 1.3 Facturación por cliente

En la **Ficha de Cliente**, menú **Relacionado → Cliente → Facturación Recurrente**. Cree una fila por cada código de facturación que use ese cliente:

| Columna | Qué indicar |
|---|---|
| **Código Facturación** | Se elige de la maestra de códigos (1.2). |
| **Tipo Facturación** | *Recurrente* o *Extra* (clasificación). |
| **Tipo cuenta** / **Nº cuenta** | Tipo de línea (Cuenta contable / Producto / Recurso) y su número. |
| **Banco de Gestión** | Banco que gestiona el cobro de las facturas de ese código. |
| **Agrupación** | *Agrupada* (una factura por cliente y código) o *Individual* (una por línea). |

> **Truco:** puede cobrar las **recurrentes por un banco** y las **extras por otro**, poniendo un Banco de Gestión distinto en cada fila.

> **[CAPTURA 3]** Página *Facturación Recurrente* de un cliente con **dos filas**: `REC` (Recurrente, Cuenta contable, Banco A, Agrupada) y `EXTRA` (Extra, Banco B, Individual). Es la captura que muestra el valor del sistema.

---

## 2. El fichero CSV

Cada línea del fichero es una línea a facturar. El orden de columnas es **fijo**:

| Col. | Campo | Oblig. | Notas |
|---|---|:---:|---|
| **1** | CÓDIGO FACTURACIÓN | Sí | Localiza la configuración del cliente (p. ej. `REC`). |
| **2** | CIF/NIF | Sí | Localiza el cliente. |
| **3** | FECHA REGISTRO | No | Formato día‑primero `dd/mm/aaaa`. |
| **4** | DOCUMENTO EXTERNO | No | Nº de documento externo de la factura. |
| **5** | CONCEPTO | No | Texto que aparecerá en la línea de factura. |
| **6** | IMPORTE | Sí | Importe a facturar (admite `1.234,56`). |
| **7** | ID BC | No | Nº de cliente BC; solo para desempatar NIF repetidos. |
| **8** | GRUPO IVA PRODUCTO | No | Si se informa, se asigna a la línea (en vez de heredarlo). |

**Plantilla oficial (con cabecera):**

```
CODIGO FACTURACION;CIF/NIF;FECHA REGISTRO;DOCUMENTO EXTERNO;CONCEPTO;IMPORTE;ID BC;GRUPO IVA PRODUCTO
REC;B12345678;30/06/2026;DOC-0001;Cuota mensual de servicio;120,50;C00010;IVA21
EXTRA;A87654321;30/06/2026;DOC-0002;Servicio adicional puntual;1.250,00;C00020;
```

Reglas útiles: el **separador** y la **cabecera** deben coincidir con lo configurado (1.1); las **fechas** van en `dd/mm/aaaa`; los **importes** admiten formato español; los conceptos entre comillas pueden ocupar varias líneas.

> **[CAPTURA 4]** El CSV de ejemplo abierto (Excel o Bloc de notas) mostrando la fila de cabecera y dos filas de datos.

### 2.1 Plantilla de particulares

Para la facturación a **particulares** (alquileres por propiedad) existe una segunda plantilla, que se carga con la acción **Import Individuals CSV** de la misma página *Importación Facturas*. Las diferencias con la estándar: la columna 4 lleva la **propiedad** (nº de producto) en lugar del documento externo, se añade la **habitación** (variante) antes del concepto y, al final, tres columnas opcionales de dimensiones.

| Col. | Campo | Oblig. | Notas |
|---|---|:---:|---|
| **1** | CÓDIGO FACTURACIÓN | Sí | Localiza la configuración del cliente (p. ej. `ALQ`). |
| **2** | CIF/NIF | No | Puede ir vacío; entonces el cliente se localiza por *ID BC*. |
| **3** | FECHA REGISTRO | No | Formato día-primero `dd/mm/aaaa`. |
| **4** | PROPIEDAD | Sí | Nº de producto de la propiedad. Se factura como producto de la línea y se vuelca también al nº de documento externo. |
| **5** | HABITACIÓN | Según | Variante del producto. Obligatoria si el producto exige variante. El código de habitación maestra equivale a la propiedad completa. |
| **6** | CONCEPTO | No | Texto que aparecerá en la línea de factura. |
| **7** | IMPORTE | Sí | Importe a facturar (admite `1.234,56`). |
| **8** | ID BC | No | Nº de cliente BC. Obligatorio si el NIF va vacío; si no, solo desempata NIF repetidos. |
| **9** | GRUPO IVA PRODUCTO | No | Si se informa, se asigna a la línea (en vez de heredarlo). |
| **10** | LÍNEA NEGOCIO | No | Valor de la dimensión *Línea de negocio* configurada en el Setup. |
| **11** | CANAL | No | Valor de la dimensión *Canal* configurada en el Setup. |
| **12** | UNIDAD | No | Valor de la dimensión *Unidad* configurada en el Setup. |

**Plantilla oficial (con cabecera)**, disponible en [Plantilla-Importacion-Particulares.csv](Plantilla-Importacion-Particulares.csv):

```
CODIGO FACTURACION;CIF/NIF;FECHA REGISTRO;PROPIEDAD;HABITACION;CONCEPTO;IMPORTE;ID BC;GRUPO IVA PRODUCTO;LINEA NEGOCIO;CANAL;UNIDAD
ALQ;12345678A;30/09/2026;PROP-0001;H01;Alquiler septiembre 2026;650,00;C00100;IVA21;LARGA;DIRECTO;MADRID
ALQ;;30/09/2026;PROP-0002;MASTER;Alquiler septiembre 2026;1.250,00;C00101;;LARGA;IDEALISTA;
```

La fila de cabecera de esta plantilla se detecta automáticamente, con independencia de la marca *Tiene cabecera* del Setup. La explicación completa de esta plantilla y de sus validaciones está en el [Manual de particulares](Manual-Particulares.md). Si el fichero trae línea de negocio, canal o unidad, la dimensión correspondiente debe estar configurada en el Setup; de lo contrario la línea da error al validar.

---

## 3. Importar y facturar (día a día)

Todo se hace desde la página **Importación Facturas** (*Tell me* / categoría *Tareas*).

### Paso 1 — Importar CSV
Pulse **Importar CSV** y seleccione el fichero. Se crea un **lote** y todas las líneas quedan en estado **Pendiente**. Se indica cuántas líneas se han importado. Para la plantilla de particulares (apartado 2.1) pulse **Import Individuals CSV**.

### Paso 2 — Validar lote
Pulse **Validar lote**. Cada línea pasa a **Validada** o **Error**. Las que tengan error muestran el motivo en *Mensaje de error*; corrija los datos maestros y vuelva a validar las veces que haga falta.

**Estados de una línea:**

- **Pendiente** — importada, aún sin validar.
- **Validada** — lista para facturar.
- **Error** — falta algo; revise el mensaje.
- **Procesada** — factura generada (se guarda el nº de documento).
- **Ignorada** — comentario que no se pudo vincular.

### Paso 3 — Generar / Registrar
- **Registrar lote**: procesa **todas** las líneas *Validadas* del lote.
- **Procesar líneas seleccionadas**: procesa solo las líneas *Validadas* seleccionadas.

Según la configuración, las facturas se **registran** o se dejan en **borrador**.

**Acciones auxiliares:** *Eliminar lote*, *Ver todos los lotes*, *Navegar al documento generado* y *Crear cliente*.

> **[CAPTURA 5]** Página *Importación Facturas* con un lote que tenga líneas en **varios estados** (una Validada en verde, una en Error en rojo, una Procesada), para que se aprecie el código de colores y el *Mensaje de error*.

---

## 4. Cómo se generan las facturas

Las líneas se agrupan **por cliente y por código de facturación**, y cada factura toma el **banco** y la **cuenta** de esa fila de configuración:

- **Código Agrupado** → una sola factura con todas las líneas de ese cliente y código.
- **Código Individual** → una factura por cada línea con importe.
- **Comentarios** (líneas sin importe) → solo en códigos agrupados; caso especial: 1 comentario + 1 línea se combinan.

> **[CAPTURA 6]** Una factura de venta generada, mostrando en la cabecera el **Banco de Gestión** y, en las líneas, la cuenta y el concepto tomados de la configuración.

---

## 5. Remesas por banco

El **Banco de Gestión** de cada factura viaja hasta la **Cartera** (localización española). Al **insertar documentos** en una remesa, solo se ofrecen los documentos cuyo banco esté **vacío** o **coincida** con el banco de la remesa. Así, las facturas recurrentes y las extras acaban en la remesa de su banco correspondiente.

> **[CAPTURA 7]** Selección de documentos de una remesa, con la columna *Banco de Gestión* visible y filtrada al banco del grupo.

---

## 6. Errores frecuentes y solución

| Mensaje | Causa | Solución |
|---|---|---|
| «La configuración… no está activa» | *Activo* desmarcado. | Marque **Activo** en la configuración. |
| «No se encontró ningún cliente con el NIF…» | El NIF no existe o está mal. | Revise el CIF/NIF del cliente o créelo. |
| «…corresponde a más de un cliente» | Varios clientes con el mismo NIF. | Rellene la columna **ID BC** con el cliente correcto. |
| «El cliente… no tiene la configuración de facturación "…"» | Falta la fila cliente + código. | Créela en *Facturación Recurrente* del cliente. |
| «…no tiene Banco de Gestión» | Falta el banco en la fila. | Asigne el **Banco de Gestión**. |
| «La cuenta… no existe o está bloqueada» | Cuenta/producto mal o bloqueado. | Revise el *Tipo cuenta* / *Nº cuenta* de la fila. |
| «El importe no puede ser cero» | Línea sin importe y sin comentarios. | Ponga importe o active *Insertar Comentarios*. |

---

## 7. Buenas prácticas

1. **Prepare los datos maestros antes de importar**: clientes con CIF/NIF y grupo contable, y una fila de *Facturación Recurrente* (con banco y cuenta) por cada código que use el CSV.
2. **Valide siempre antes de registrar**: guíese por los colores del estado.
3. **Use *ID BC* solo cuando el NIF esté repetido** entre varios clientes.
4. **Primeras cargas en borrador**: desactive *Registrar automáticamente* hasta comprobar que todo sale bien.
5. **Un lote por fichero**: si algo falla, *Eliminar lote* deja todo limpio para reintentar.
