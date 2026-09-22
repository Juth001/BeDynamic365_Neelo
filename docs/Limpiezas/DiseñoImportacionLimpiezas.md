# Diseño funcional — Importación del CSV de gastos de limpieza

**Módulo:** Neelo Core Solutions by BeDynamic · Importación limpiezas
**Audiencia:** usuarios de administración / contabilidad
**Última revisión:** 28/07/2026

---

## 1. Qué resuelve este módulo

El proveedor de limpieza factura sus servicios de forma **global** (una factura mensual con la base imponible total), pero el gasto real corresponde a **muchas propiedades distintas**, cada una con su proyecto, su tarea y sus dimensiones analíticas.

El flujo es el siguiente:

1. La **factura de compra** del proveedor se registra de forma normal en Business Central, cargando todo el gasto (base imponible) en una **cuenta puente**. El IVA se liquida aquí, con la factura.
2. El proveedor envía un **CSV con el detalle** de los servicios prestados: fecha, propiedad, servicio, cantidad e importe de cada actuación.
3. El módulo importa ese CSV a una **hoja de trabajo** (staging), lo **valida** contra el catálogo de servicios y las propiedades, y comprueba que el detalle **cuadra con la base imponible** de la factura.
4. Con todo validado, genera un **diario de reclasificación** que abona la cuenta puente (dejándola a cero) y carga las **cuentas de gasto reales** con proyecto, tarea, dimensiones y cantidad. Es un asiento solo contable/analítico: **sin IVA**, porque el IVA ya se registró con la factura.

El detalle completo del fichero queda archivado en la hoja de importación aunque el asiento se registre agregado.

---

## 2. Configuración necesaria

### 2.1 Configuración gestión propiedades (grupo "Servicios de limpieza")

Ruta: **Configuración → Configuración de propiedades**, grupo *Servicios de limpieza*.

| Campo | Obligatorio | Para qué sirve |
|---|---|---|
| **Proveedor habitual limpiezas** | Recomendado | Proveedor que se propone al importar el fichero. Si el CSV no trae columna de proveedor, las filas se importan a su nombre. |
| **Cuenta puente limpiezas** | Sí | Cuenta donde se registró el gasto global de la factura del proveedor. La reclasificación la abona para dejarla a cero. Debe admitir registro directo. |
| **Modo registro limpiezas** | Sí | **Agregado**: una línea de diario por propiedad + servicio + mes. **Detallado**: una línea de diario por cada fila del fichero. En ambos casos el detalle se conserva en la hoja. |
| **Trabajar con** | Sí | Origen de las dimensiones de propiedad que heredan las líneas del diario: las dimensiones predeterminadas de la **ficha de propiedad**, o las del **producto** asociado a la propiedad. |
| **Registrar reclasificación automáticamente** | No | Activado: el diario se registra solo al generarlo (exige que la sección esté vacía de otras líneas). Desactivado: el diario queda preparado para revisarlo, y el sistema ofrece abrirlo. |
| **Libro diario reclasificación** | Sí | Libro de diario general (no periódico) donde se generan las líneas. |
| **Sección diario reclasificación** | Sí | Sección del libro. Conviene una **sección dedicada** a limpiezas, sobre todo con registro automático: se registra la sección completa. |
| **Tolerancia cuadre factura** | No (0 por defecto) | Diferencia máxima en euros admitida entre la base imponible de la factura y la suma de las líneas del fichero asignadas a ella. |
| **Validar periodo contable** | No | Al validar líneas, exige que la fecha de registro caiga en un periodo contable definido y no cerrado. |
| **Validar fechas conf. contabilidad** | No | Al validar líneas, comprueba la fecha contra "Permitir registro desde/hasta" de la Configuración de contabilidad. |
| **Validar fechas conf. usuarios** | No | Igual, pero contra los límites del usuario actual en la Configuración de usuarios (si el usuario no tiene registro ahí, no aplica). |

> **Sobre las tres validaciones de fecha**: replican los controles del estándar pero en el momento de la validación de la hoja, para ver el problema antes de generar el diario. Con las tres desactivadas solo se exige que la línea tenga fecha de servicio; en ese caso el control estándar seguirá aplicándose **al registrar** el diario.

### 2.2 Tabla de servicios

Ruta: **Alquiler y reservas → Servicios** (o desde la configuración, acción *Servicios*).

Aquí viven los códigos de servicio genéricos (LIMPIEZA, LAVANDERIA, AMENITIE...) con su descripción y sus **dimensiones predeterminadas** (acción *Dimensiones*). Estas dimensiones se añaden a cada línea del diario de reclasificación que genere ese servicio.

### 2.3 Catálogo de servicios por proveedor

Ruta: **Configuración de propiedades → Catálogo de servicios por proveedor** (también desde Servicios, acción *Servicios por proveedor*).

Cada proveedor tiene su catálogo: qué servicios presta y en qué condiciones. **Sin catálogo no se puede importar** el fichero de ese proveedor.

| Campo | Para qué sirve |
|---|---|
| **Proveedor + Código** | El código debe coincidir con la columna *servicio* del fichero (en mayúsculas y sin acentos: el fichero puede traer "LAVANDERÍA" y casará con "LAVANDERIA"). |
| **Unidad** | Unidad de la cantidad (h, kg, kits...); aparece en descripciones y mensajes. |
| **Cuenta de gasto** | Cuenta contable real donde la reclasificación carga este servicio. **Obligatoria para validar.** |
| **Tarea estándar** | Tarea del proyecto de propiedad a la que se imputa el servicio (de la plantilla de tareas de propiedad). **Obligatoria para validar.** Si el proyecto de una propiedad no la tiene, se crea automáticamente. |
| **Precio pactado** | Precio unitario acordado. Valida el fichero: importe = cantidad × precio. Con 0 no se valida el precio. |
| **Bloqueado** | Un servicio bloqueado no cuenta como catálogo activo. |

La acción **Crear servicios estándar** crea de golpe LIMPIEZA (h), LAVANDERIA (kg) y AMENITIE (kits) para el proveedor habitual; después hay que completar cuenta, tarea y precio.

**Precios por propiedad** (acción *Precios por propiedad*): permite un precio negociado distinto para una propiedad concreta, que prevalece sobre el precio pactado general del catálogo.

### 2.4 Propiedades y proyectos

- Cada código de propiedad del fichero debe existir como **ficha de propiedad**. La propiedad determina el **proyecto**: el de su ficha o, en su defecto, el proyecto con su mismo código (convención del asistente de altas).
- El proyecto debe estar **abierto y no bloqueado**.
- Las **dimensiones** que hereda el diario dependen del parámetro *Trabajar con*: las predeterminadas de la ficha de propiedad o las del producto asociado.

### 2.5 La factura del proveedor

Antes de reclasificar, la **factura de compra debe estar registrada** cargando su base imponible en la **cuenta puente**. El módulo no registra la factura: la toma como referencia de cuadre y como número de documento del asiento.

La vista **Facturas limpieza pendientes** (desde la configuración) muestra las facturas del proveedor con su importe asignado, reclasificado y pendiente de distribuir.

---

## 3. La plantilla CSV

Hay una plantilla de ejemplo en `docs/Limpiezas/Plantilla-Importacion-Limpiezas.csv`.

**Formato del fichero:**

- Separador: **punto y coma (;)**
- Decimales: **coma** (también admite formato 1.234,56 y símbolo de moneda)
- Fechas: **d/M/yyyy** (2/01/2025 y 02/01/2025 valen igual)
- Codificación: UTF-8 o ANSI de Windows — se detecta sola (los CSV re-guardados por Excel funcionan)
- La primera fila es la **cabecera** y se ignora automáticamente
- Los importes son **SIN IVA**

**Columnas, en este orden:**

| # | Columna | Obligatoria | Contenido |
|---|---|---|---|
| 1 | fecha | Sí | Fecha del servicio (d/M/yyyy). Las filas sin fecha válida se ignoran. |
| 2 | propiedad | Sí | Código de la propiedad (p. ej. ES-01-01-001). |
| 3 | servicio | Sí | Código del servicio del catálogo (LIMPIEZA, LAVANDERIA...). Acentos y minúsculas se normalizan solos. |
| 4 | cantidad | Sí | Cantidad (horas, kg, kits...). |
| 5 | coste unidad | Informativa | Precio unitario del proveedor. Solo sirve para comprobar la coherencia de la fila; el precio que valida es el pactado. |
| 6 | total servicio | Sí | Importe de la fila sin IVA. Debe ser cantidad × precio pactado. |
| 7 | proveedor | Opcional | Código de proveedor de la fila. Vacía: se usa el proveedor elegido al iniciar la importación. Permite ficheros multi-proveedor. |
| 8 | factura compra a reclasificar | Opcional | Nº de la factura de compra registrada donde vino facturado este servicio. Vacía: la factura se asigna después en la hoja. |

**Ejemplo:**

```csv
fecha;propiedad;servicio;cantidad;coste unidad;total servicio;proveedor;factura compra a reclasificar
01/07/2026;ES-01-01-001;LIMPIEZA;2,5;9;22,5;P00010;FC26-00123
01/07/2026;ES-01-01-002;LAVANDERIA;4;1,5;6;P00010;FC26-00123
02/07/2026;ES-01-01-001;AMENITIE;1;12;12;P00010;FC26-00123
03/07/2026;ES-01-02-010;LIMPIEZA;3;9;27;;
```

**Filas que se ignoran** (se cuentan como "ignoradas" en el mensaje final, sin dar error): la cabecera, las filas vacías, las filas sin fecha válida (incluidas fechas imposibles como 31/04) y las filas con cantidad e importe a cero.

**Aviso no bloqueante**: si total ≠ cantidad × coste unidad (con margen de 2 céntimos), la fila se importa igualmente con un texto en la columna *Aviso*.

---

## 4. Paso a paso: importación

Ruta: **Importaciones → Hoja importación limpiezas**, acción **Importar CSV**.

1. El sistema propone el **proveedor habitual** de la configuración (se puede aceptar o elegir otro de la lista). El proveedor debe tener **catálogo activo**; si no, la importación se corta con un error.
2. Se selecciona el fichero CSV.
3. Cada fila útil se convierte en una **línea de la hoja** en estado **Pendiente**, agrupada bajo un **lote** con código `LIMP + fecha y hora` (p. ej. `LIMP20260728093015`). Al terminar, la hoja queda filtrada por ese lote.
4. Mensaje final: nº de líneas importadas, lote y filas ignoradas.

En la hoja, cada línea muestra: fecha de servicio (editable), propiedad, proveedor, servicio, cantidad, importe, precio pactado, factura, estado, error y aviso. Las líneas se colorean según su estado.

---

## 5. Paso a paso: validación

### 5.1 Asignar la factura

Si el fichero no traía la columna de factura, hay dos caminos:

- **Acción "Asignar factura..."**: sobre las líneas seleccionadas (deben ser todas del mismo proveedor). Abre el histórico de facturas de compra **filtrado por el proveedor y por facturas aún sin dimensionar**, y asigna la elegida a todas las líneas.
- **Campo "Nº factura registrada"** en cada línea: su lista desplegable aplica el mismo filtro (facturas del proveedor de la línea, no dimensionadas).

Si se teclea a mano una factura inexistente, de otro proveedor o ya dimensionada, el sistema la rechaza en el momento o en la validación.

### 5.2 Comprobar cuadre (opcional, en cualquier momento)

La acción **Comprobar cuadre** muestra, por cada factura presente en la selección (estén las líneas en el estado que estén):

> Factura FC26-00123: base 1.250,00, asignado 1.250,00 (reclasificado 0,00), diferencia 0,00.

- **Base**: base imponible de la factura registrada.
- **Asignado**: suma de todas las líneas de la hoja (cualquier estado) con esa factura.
- **Reclasificado**: la parte ya reclasificada en procesos anteriores.
- **Diferencia**: base − asignado. Para poder reclasificar debe quedar dentro de la tolerancia.

### 5.3 Validar líneas

La acción **Validar líneas** procesa las líneas seleccionadas en estado Pendiente o Error y las deja en **Validada** o en **Error** (con el motivo en la columna *Mensaje*). Comprobaciones, en orden:

1. **Proveedor y catálogo** — el proveedor de la línea existe y el servicio está en su catálogo.
2. **Fecha** — la línea tiene fecha de servicio. La fecha de registro prevista (fin del mes del servicio) se comprueba según las opciones de configuración activas: periodo contable definido y no cerrado, límites de la configuración de contabilidad y/o límites del usuario actual.
3. **Propiedad → proyecto** — la propiedad existe y su proyecto está abierto y sin bloquear. El proyecto queda anotado en la línea.
4. **Cuenta y tarea** — el servicio del catálogo tiene cuenta de gasto y tarea estándar. Si la tarea no existe aún en el proyecto de esa propiedad, **se crea automáticamente** (tipo Registro).
5. **Precio pactado** — se compara el importe con cantidad × precio, con margen de redondeo de 2 céntimos. El precio se resuelve del más específico al más general: precio por propiedad → precio pactado del catálogo. Con precio 0 no se compara. **Una desviación no bloquea**: la línea queda validada con el motivo en la columna *Aviso*. Marcando **"Admitir desviación precio"** y revalidando, el aviso desaparece.
6. **Factura** — la línea tiene factura asignada; la factura existe, es del proveedor de la línea y **no está ya dimensionada** por una reclasificación anterior.

Las líneas en Error se pueden corregir (editar la fecha, la factura, marcar desviación, completar el catálogo...) y volver a validar las veces que haga falta.

---

## 6. Generación del asiento de reclasificación

Acción **Generar reclasificación** sobre la selección. El proceso trabaja **factura a factura**.

### 6.1 Comprobaciones previas al asiento

1. **Configuración completa**: cuenta puente, libro y sección de diario configurados.
2. **Sin líneas a medias**: si en la selección hay líneas validadas **sin factura**, el proceso se detiene (hay que asignarla antes).
3. **Hay algo que hacer**: al menos una línea validada con factura.
4. **Sección limpia** (solo con registro automático): la sección de diario no puede contener otras líneas ajenas, porque se registra completa.
5. **Cuadre por factura**: para cada factura, la suma de sus líneas **validadas** más las **ya reclasificadas** debe cubrir la **base imponible** dentro de la tolerancia configurada. Si no cuadra, error con el detalle (base, asignado, diferencia, tolerancia) y no se genera nada de esa selección.
6. **Todas las líneas de la factura tienen fecha de servicio** (necesaria para calcular la fecha de registro).

### 6.2 Cómo se monta el asiento y de dónde sale cada dato

Por cada factura se generan líneas de diario general así:

| Dato del diario | De dónde se toma |
|---|---|
| **Nº documento** | El nº de la factura de compra (también como nº documento externo). |
| **Fecha registro** | **Último día del mes** del servicio más reciente de la factura. Una única fecha para todo el documento. |
| **Cuenta (Debe)** | Cuenta de gasto del servicio en el **catálogo del proveedor**. |
| **Proyecto y tarea** | El proyecto resuelto desde la **propiedad** y la tarea estándar del **catálogo**. |
| **Cantidad (proyecto)** | La cantidad de la línea (horas, kg, kits) — modo detallado — o la suma del grupo — modo agregado. |
| **Descripción** | `Servicio + mes (o fecha) + propiedad + (cantidad unidad)`. P. ej. `Limpieza 07/2026 ES-01-01-001 (12,5 h)`. |
| **Dimensiones** | Suma de tres orígenes, por este orden: predeterminadas del **proyecto**, de la **propiedad o su producto** (según *Trabajar con*) y del **servicio** (tabla de servicios). En caso de conflicto prevalece la última. |
| **IVA** | Ninguno: los grupos de registro de IVA se limpian expresamente. Es una reclasificación entre cuentas. |

- **Modo agregado**: una línea de gasto por cada combinación propiedad + servicio + mes.
- **Modo detallado**: una línea de gasto por cada fila del fichero, con su fecha en la descripción.

Al final se añade **una línea de abono a la cuenta puente** por el total reclasificado de la factura, con descripción `Reclasificación fra. FC26-00123 servicios limpieza`. El asiento queda cuadrado:

| Cuenta | Debe | Haber |
|---|---|---|
| 6280001 Limpieza (proyecto ES-01-01-001, dim. propiedad) | 322,50 | |
| 6280002 Lavandería (proyecto ES-01-01-002, dim. propiedad) | 96,00 | |
| 6280003 Amenities (proyecto ES-01-01-001, dim. propiedad) | 60,00 | |
| **Cuenta puente limpiezas** | | **478,50** |

Además, en el mismo momento de generar el diario:

- La factura se marca como **dimensionada** (deja de ofrecerse en los lookups y de admitir nuevas líneas).
- Las líneas de la hoja pasan a estado **Reclasificada**, con el nº de documento y la fecha de registro anotados.

### 6.3 Registro contable

- **Sin registro automático** (recomendado al empezar): el diario queda preparado en el libro/sección configurados y el sistema **pregunta si quieres abrirlo**. Se revisa y se registra con el botón estándar *Registrar* del diario. Al registrar, los controles estándar de BC aplican igualmente (fechas permitidas, dimensiones obligatorias...).
- **Con registro automático**: el diario se registra en el acto y se informa del nº de líneas registradas.

El registro genera los movimientos contables y, por llevar proyecto y tarea, los **movimientos de proyecto** correspondientes con su cantidad: el gasto queda imputado a cada propiedad tanto contable como analíticamente, y la cuenta puente queda saldada.

### 6.4 Si algo sale mal después de generar

Si el diario generado **se eliminó sin registrar**, la acción **Reabrir líneas** devuelve las líneas Reclasificadas a Validada y limpia la referencia al documento, para poder generar de nuevo. *Atención*: si el diario ya se registró, reabrir no deshace el asiento — la reclasificación contable seguirá existiendo. En ese caso el ajuste debe hacerse por diario manual, y la marca "dimensionada" de la factura quitarse a mano si procede.

---

## 7. Ciclo de vida de una línea

```
Importada (Pendiente)
   │  Validar líneas
   ├─────────────► Error ──(corregir y revalidar)──► Validada
   └─────────────► Validada
                      │  Generar reclasificación (cuadre OK)
                      ▼
                 Reclasificada ──(Reabrir líneas, solo si el diario no se registró)──► Validada
```

---

## 8. Errores frecuentes y su solución

| Mensaje | Causa | Solución |
|---|---|---|
| El proveedor no tiene servicios activos en el catálogo | Falta catálogo del proveedor | Crear el catálogo (o *Crear servicios estándar*) antes de importar |
| El servicio X no existe en el catálogo del proveedor | Código del fichero no casa con el catálogo | Añadir el servicio al catálogo o corregir el fichero |
| La fecha de registro no tiene periodo contable definido / cae en periodo cerrado / fuera del rango permitido | Validaciones de fecha activas en configuración | Abrir el periodo, ajustar "Permitir registro desde/hasta" o desactivar la comprobación correspondiente |
| No existe la propiedad X / la propiedad no tiene proyecto | Código de propiedad incorrecto o alta incompleta | Corregir el código o completar la ficha de propiedad y su proyecto |
| (Aviso, no bloquea) El importe no cuadra con cantidad × precio | Precio del fichero distinto del pactado | La línea valida igualmente; corregir catálogo/precio por propiedad o el fichero, o marcar *Admitir desviación precio* para quitar el aviso |
| La línea no tiene factura de compra a reclasificar | Ni el fichero ni la hoja la asignaron | Usar *Asignar factura...* o el campo de la línea |
| La factura X ya se ha dimensionado | Esa factura ya se reclasificó | Asignar la factura correcta; el lookup solo ofrece facturas pendientes |
| La factura no cuadra: base X, líneas Y, diferencia Z | El detalle no cubre la base imponible | Completar/corregir líneas, o ajustar la tolerancia si es una diferencia de redondeo asumida |
| La sección de diario contiene otras líneas | Registro automático con sección compartida | Vaciar la sección o dedicar una exclusiva a limpiezas |
