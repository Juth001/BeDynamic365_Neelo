# Importación de Gastos Pleo — Guía de Configuración y Reglas de Negocio

> Guía operativa: qué configurar, qué implica cada opción, cómo se importa y valida el CSV y qué reglas de negocio aplica el procesado. El detalle técnico está en [DiseñoImportacionPleo.md](DiseñoImportacionPleo.md).
>
> Fecha: 15/07/2026 · actualizado 22/09/2026

---

## 1. Qué configurar y sus implicaciones

### 1.1 Configuración Importación Pleo — grupo General

| Campo | Qué es | Implicaciones |
|---|---|---|
| **Banco Pleo (banco puente)** | Cuenta bancaria BC que representa el monedero de Pleo | Contra él se registran: los pagos de las facturas, los gastos extraordinarios, las recargas y los cashbacks. **Obligatorio** si la acción es "Registrar y pagar", si hay empleados no deducibles o si se procesan recargas/cashbacks |
| **Acción tras importar** | Qué se hace con cada compra | *Solo borrador*: crea la factura sin registrar (se registra a mano desde BC; la línea se archiva como "Documento creado"). *Registrar*: registra la factura sin pago. *Registrar y pagar*: además liquida el pago contra el banco Pleo. ⚠️ Recargas, cashbacks y gastos extraordinarios **ignoran esta opción**: siempre se registran directamente |
| **Prefijo nº factura proveedor** (`PLEO-`) | Prefijo + nº de recibo Pleo | Forma el "Nº factura proveedor" de las facturas y el nº de documento de los diarios (p. ej. `PLEO-2601217`). Facilita localizar el origen de cualquier asiento |
| **Codificación del fichero** | UTF-8 / Windows (ANSI) | Solo actúa como desempate cuando el CSV no permite detectar la codificación automáticamente (ver §2.1). En la práctica casi nunca hay que tocarla |

### 1.2 Grupo Compras

| Campo | Qué es | Implicaciones |
|---|---|---|
| **Proveedor genérico** | Fallback de proveedor | Se usa cuando el proveedor de Pleo no está mapeado o el mapeo está incompleto. El nombre real del comercio se conserva en la descripción de la línea. **Si está vacío y falta un mapeo → la línea queda en error** |
| **Cuenta de gasto por defecto** | Fallback de cuenta | Se usa cuando la categoría de Pleo no está mapeada, no tiene cuenta asignada o viene vacía. Si está vacía y falta el mapeo → error |
| **Grupo IVA producto (único)** | Grupo de IVA forzado en TODAS las líneas de compra | Los importes de Pleo vienen **con IVA incluido**; BC calcula la base hacia atrás con este grupo. **Obligatorio** para compras normales (los gastos extraordinarios no lo necesitan). Debe existir la combinación en la configuración de registro de IVA de los proveedores usados |
| **Auto-crear mapeo de proveedores / categorías / compradores** | Alta automática de códigos, categorías y empleados desconocidos | Los códigos, categorías y empleados nuevos del CSV se dan de alta solos en las tablas de mapeo, **sin destino**, para completarlos después y revalidar. Si se desactivan, los desconocidos simplemente usan el fallback (o dan error) sin dejar rastro en el mapeo |
| **Cuenta gastos extraordinarios** | Cuenta de los gastos no deducibles sin justificante | Destino del diario directo banco Pleo → gasto (sin IVA, sin factura). **Obligatoria si hay empleados marcados "No deducible"**; debe permitir registro directo |

### 1.3 Grupo CAPEX / Activos fijos

| Campo | Qué es | Implicaciones |
|---|---|---|
| **Auto-crear activos fijos** | Alta automática del activo de la propiedad | Si no existe activo que cumpla ubicación (+ clase/subclase del mapeo), se crea con descripción = nombre de la propiedad. Si está desactivado y no existe → error |
| **Subclase activo fijo** | Subclase por defecto | Solo se usa al crear activos cuando el mapeo de la categoría **no** indica clase ni subclase |
| **Grupo contable activo fijo** | Grupo del libro de amortización | Si está vacío, se toma el grupo por defecto de la subclase efectiva |
| **Libro de amortización** | Libro para el activo y la línea de compra | Si está vacío, se usa el libro por defecto de la configuración de activos fijos de BC |

### 1.4 Grupo Dimensiones

| Campo | Qué es | Implicaciones |
|---|---|---|
| **Dimensión para el proyecto** | Dimensión BC donde se vuelca el "Proyecto - Code" de Pleo | Se aplica a facturas, pagos y diarios extraordinarios. Si está vacía, el proyecto no se traslada a dimensiones |
| **Auto-crear valores de dimensión** | Alta automática de valores | Si el código de proyecto no existe como valor de dimensión, se crea con su nombre. Si está desactivado y no existe → error |

### 1.5 Grupo Recargas de monedero y cashback

| Campo | Qué es | Implicaciones |
|---|---|---|
| **Contabilizar recargas monedero** + **Banco origen** | Diario de recargas | Activado: cada `Wallet Load` genera cargo en banco Pleo / abono en banco origen. Desactivado: las recargas se **omiten** (quedan en la hoja como omitidas) |
| **Contabilizar cashbacks** + **Cuenta ingreso cashback** | Diario de cashbacks | Activado: cargo en banco Pleo / abono en la cuenta de ingresos (p. ej. 759x/778x). Desactivado: se omiten |

### 1.6 Mapeos (mantenimiento continuo)

| Mapeo | Clave | Destino | Notas |
|---|---|---|---|
| **Proveedores** | "Proveedor - Code" del CSV | Proveedor BC | Sin proveedor asignado → se usa el genérico |
| **Categorías** | "Category" del CSV (**nombre exacto** de la categoría de Pleo) | Cuenta de gasto **o** CAPEX + clase/subclase de activo, y tarea de proyecto | CAPEX ignora la cuenta; la clase/subclase determinan qué activo de la propiedad recibe el coste y con qué se crea. Al desmarcar CAPEX se limpian. Se configura en la página *Mapeo Categorías Pleo*; la antigua *Mapeo Tipos de Gasto Pleo* queda oculta y sin uso. Las líneas sin categoría van a la cuenta por defecto. ⚠️ Si se renombra una categoría en Pleo, aparecerá como categoría nueva |
| **Compradores** | "Owner" del CSV (**nombre exacto** del empleado) | Comprador/Vendedor BC + check **"No deducible"** | El comprador se asigna a factura, pago y diario, con prioridad sobre el comprador por defecto del proveedor. "No deducible" activa el tratamiento de gasto extraordinario para los gastos **sin justificante** de ese empleado. ⚠️ Si el empleado cambia su nombre en Pleo, aparecerá como empleado nuevo |

### 1.7 Datos maestros necesarios fuera del módulo

- **Ficha del banco Pleo** con su grupo contable de banco.
- **Cuentas contables** (gasto por defecto, extraordinarios, cashback) con **registro directo** permitido.
- **Configuración de registro del IVA**: la combinación grupo de negocio del proveedor × grupo IVA producto único debe existir con el % soportado correcto.
- **Compradores/Vendedores** con su **dimensión por defecto asignada en la ficha** (p. ej. dimensión COMPRADOR). El módulo fusiona siempre esas dimensiones en todos los registros; si la ficha no las tiene, no hay nada que asignar.
- **Dimensión de proyecto** creada (los valores pueden auto-crearse).
- **Permisos**: conjunto "Importación Pleo" + permisos estándar de compras, diarios y activos fijos del usuario.

### 1.8 Checklist de puesta en marcha (orden recomendado)

1. Crear banco Pleo y, si aplica, identificar el banco origen de recargas.
2. Crear proveedor genérico y cuentas (gasto por defecto, extraordinarios, cashback).
3. Definir el grupo IVA producto único y su configuración de registro.
4. Crear la dimensión de proyecto y asignar dimensiones por defecto a los compradores.
5. Rellenar la Configuración Importación Pleo completa.
6. Importar un primer CSV: los mapeos se auto-crean vacíos.
7. Completar los tres mapeos (proveedor BC, cuentas/CAPEX, comprador + no deducible).
8. **Revalidar** las líneas y revisar colores/avisos.
9. "Generar documentos y pagos" con una muestra pequeña y verificar factura, pago, dimensiones e IVA antes de procesar en masa.

---

## 2. Cómo se importa y valida el CSV

### 2.1 Importación (acción "Importar CSV de Pleo...")

1. **Formato esperado**: export estándar de Pleo — separador `;`, decimal coma, fechas `dd/MM/yyyy`, campos entrecomillados (se soportan `;` y saltos de línea dentro de un campo, p. ej. en la nota).
2. **Codificación**: se detecta automáticamente — BOM UTF-16 o UTF-8 manda; sin BOM se valida si el contenido es UTF-8 y, si no (típico CSV re-guardado por Excel en ANSI), se lee como Windows. La opción del setup solo desempata el caso sin BOM.
3. **Cabecera por nombre**: las columnas se localizan por su título (Date, Receipt, Expense type, Amount, Currency, Source description, Category, Owner, Note, Receipt URLs, Expense ID, Proyecto‑Name/Code, Proveedor‑Name/Code…), no por posición. Si no se encuentran "Date" y "Amount", se aborta con aviso.
4. **Lote**: cada importación crea un lote `PL<añomesdíahoraminutoseg>`; la hoja se filtra automáticamente al lote recién importado.
5. **Deduplicación**: cada gasto trae un **Expense ID** único. Si ya existe en la hoja de trabajo **o en el archivo**, la fila se descarta como duplicada. Se pueden re-exportar periodos solapados de Pleo sin riesgo de duplicar contabilidad.
6. Las filas sin fecha ni importe (basura al final del fichero) se ignoran.
7. Tras la carga, el lote se **valida automáticamente**.

### 2.2 Validación (automática tras importar; acción "Revalidar" tras corregir)

Por cada línea pendiente o con error:

| Regla | Resultado si no se cumple |
|---|---|
| Importe ≠ 0 | **Omitida** ("Importe cero") |
| Tipo soportado (compra, recarga, cashback) | **Omitida** ("Tipo de movimiento no soportado") |
| Recarga/cashback con su flag del setup desactivado | **Omitida** (se indica cómo activarlo) |
| Fecha y nº de recibo presentes | **Error** |
| Divisa vacía o EUR | **Error** (solo EUR soportado) |
| **Compra normal**: grupo IVA en setup, proveedor resoluble (mapeo → genérico), cuenta resoluble (mapeo → por defecto) o activo fijo resoluble (CAPEX), valor de dimensión de proyecto existente o auto-creado | **Error** con el motivo concreto |
| **Compra extraordinaria** (empleado no deducible sin justificante): cuenta de gastos extraordinarios y banco Pleo en setup | **Error** |
| **CAPEX**: la línea debe traer proyecto (= propiedad); debe existir o poderse crear el activo con esa ubicación y la clase/subclase del mapeo. Si el código de propiedad supera los 10 caracteres de la ubicación, se compacta quitando separadores (`ES-01-02-024` → `ES0102024`); si ni así cabe → error | **Error** |

**Resolución**: la validación escribe en la línea el proveedor BC, el comprador, la cuenta o el activo fijo y las marcas CAPEX/extraordinario. Esas columnas se pueden **corregir a mano** en la hoja antes de procesar — lo que se ve es lo que se contabiliza.

**Avisos no bloqueantes**: compra **sin URL de recibo** → aviso "Falta el justificante" (línea en amarillo). La línea se procesa igualmente.

**Código de colores de la hoja** (línea completa): 🔴 rojo = error (con el motivo en "Mensaje") · 🟡 amarillo = aviso (falta justificante) · 🟢 verde = OK (validada, creada, registrada o pagada) · ⚪ gris = omitida.

---

## 3. Reglas de negocio del procesado

Acción "Generar documentos y pagos" — procesa solo las líneas **Validadas** de la selección:

### 3.1 Compras con tarjeta (flujo normal)

- Importe **negativo** → **factura de compra**; importe **positivo** → **abono** (devolución).
- Un documento por movimiento, de una sola línea: cantidad 1, coste directo = |importe|, descripción = comercio + nota.
- **IVA incluido**: la factura se crea con "Precios IVA incluido" y el grupo IVA único del setup; BC calcula la base hacia atrás.
- Fechas de documento y registro = fecha del gasto en Pleo.
- "Nº factura proveedor" = prefijo + nº recibo (evita el duplicado estándar de BC por proveedor).
- **Comprador**: el del mapeo de empleados, con prioridad sobre el comprador por defecto del proveedor.
- **Dimensiones**: proyecto de Pleo + **dimensiones por defecto del comprador, siempre** (facturas, pagos y diarios).
- **CAPEX**: la línea es de tipo Activo fijo (coste de adquisición) contra el activo de la propiedad (ubicación = proyecto) que coincida con la clase/subclase del mapeo; se auto-crea si no existe.
- **Pago** (si la acción es "Registrar y pagar"): diario de pago/reembolso liquidado contra el documento, contrapartida banco Pleo, mismas dimensiones que la factura.

### 3.2 Gastos extraordinarios (no deducibles)

- Se aplican cuando el empleado está marcado **"No deducible"** en el mapeo de compradores **y** el gasto **no tiene justificante** (URL de recibo vacía). Con justificante → flujo normal.
- Diario directo: **banco Pleo → cuenta de gastos extraordinarios**. **Sin IVA** (se limpia cualquier configuración de IVA de la cuenta), sin proveedor y sin factura.
- Lleva comprador, dimensión de proyecto y dimensiones por defecto del comprador.
- Se registra siempre directamente (ignora "Acción tras importar"); no genera fase de pago — el propio asiento ya mueve el banco.

### 3.3 Recargas de monedero y cashback

- **Recarga**: cargo banco Pleo / abono banco origen. **Cashback**: cargo banco Pleo / abono cuenta de ingresos.
- Nº de documento = prefijo + recibo. Se registran directamente.

### 3.4 Robustez y reintentos (idempotencia)

- Si la creación de la factura falla a medias, el borrador incompleto se elimina (no queda basura).
- Si quedó un **borrador creado** de un intento anterior, se reutiliza (no se duplica).
- Si la factura **se registró pero falló el pago**, la línea queda en error con el nº registrado; al reprocesar **solo se reintenta el pago**.
- Antes de pagar se comprueba el importe pendiente del movimiento: si ya está liquidado, **no se paga dos veces**.
- Cada error deja el motivo en la columna "Mensaje"; corregir (mapeos, fichas, setup), **Revalidar** y volver a procesar.

### 3.5 Archivo

- Al terminar el procesado, las líneas con resultado final (documento creado, registrada, pagada) se **mueven automáticamente al Archivo Gastos Pleo** con fecha y usuario. La hoja queda solo con lo pendiente/error/omitido.
- El archivo es de solo lectura, conserva toda la traza (lote, fila CSV, documentos, avisos) y **sigue contando para la deduplicación**.
- Acción manual "Archivar procesadas" para casos con filtros o líneas antiguas.

### 3.6 Límites actuales

- Solo **EUR**.
- Grupo de IVA **único** para todas las compras (Pleo no desglosa IVA).
- Un documento por movimiento (no se agrupan compras del mismo proveedor).
- Los mapeos de compradores y de categorías son por **nombre exacto** del empleado y de la categoría en Pleo.
