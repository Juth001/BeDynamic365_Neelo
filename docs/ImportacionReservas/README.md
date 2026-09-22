# NEE - Importación de reservas y fianzas

Carga en Business Central el fichero de cuadre de reservas y fianzas del sistema de origen: crea los inquilinos que falten, las reservas con sus dimensiones y las fianzas con su saldo.

## Uso

Buscar **"Hoja importación reservas"** (o abrirla desde el Role Center, pestaña *Importaciones*). El flujo tiene cuatro pasos:

1. **Importar fichero**: se elige el CSV y se carga en un lote nuevo. A continuación se reparte por empresa y se valida lo que se queda aquí, todo seguido.
2. **Distribuir por empresa**: las reservas de otras empresas se envían a la hoja de importación de la suya (ver abajo). Se puede volver a lanzar por separado.
3. **Revisar**: cada línea queda en *Validada*, *Con avisos* o *Error*, con el motivo al lado. Se puede corregir lo que haga falta en los maestros y volver a **Validar**.
4. **Procesar**: crea inquilinos, reservas y fianzas de las líneas validadas y de las que solo tienen avisos. Las que están en error se quedan fuera, y el mensaje final dice cuántas.

Las propiedades y las subpropiedades **tienen que existir antes**: la importación no las crea, las busca.

## Un fichero, varias empresas

El fichero viene mezclado: trae reservas de todas las gestoras. El **segundo segmento del código de propiedad** dice de cuál es cada una — en `ES-`**`01`**`-01-065` ese `01` es la gestora—, y cada gestora apunta a una empresa de Business Central en el campo *Empresa* de **Empresas gestoras de propiedades**. La tabla es compartida entre empresas: se mantiene una sola vez y vale también para la importación de Pleo.

Al distribuir, las líneas que no son de la empresa actual se copian con `ChangeCompany` a la hoja de importación de su empresa y desaparecen de esta. Después hay que **cambiar a esa empresa**, abrir la hoja, elegir el mismo lote y validar y procesar allí. El mensaje del reparto dice cuántas líneas se quedan y cuántas van a cada empresa.

Una línea se queda aquí y en error si el código de propiedad no lleva un segmento que corresponda a ninguna gestora, si la gestora no tiene empresa asignada, o si esa empresa no existe en la base de datos. Reenviar el mismo lote dos veces no duplica nada: si la línea ya está en el destino con ese lote, se avisa y no se copia.

### Por qué se mueve el staging y no la reserva

Se podría pensar en crear la reserva directamente en la otra empresa con `ChangeCompany`, pero no funcionaría. Los desencadenadores de tabla se ejecutan siempre en el contexto de la **empresa actual**, de modo que el nº de reserva saldría de la serie numérica de esta empresa y no de la del destino, y el Id del conjunto de dimensiones apuntaría a un conjunto de esta empresa, que en la otra significa algo distinto o directamente no existe.

Moviendo la hoja de importación —que no tiene series numéricas ni dimensiones, solo datos— cada empresa crea sus reservas de forma nativa, con su numeración y sus dimensiones correctas.

## El fichero

Separador `;`, decimales con coma, fechas `dd/mm/aaaa`. Se detecta la codificación por el BOM y se admiten importes con y sin separador de miles (`550` y `1.500,00`).

Se descartan las filas que no traen Id de reserva o que no traen ninguna fecha válida: con eso caen la fila de títulos, la de instrucciones y la de totales del final. El mensaje de la importación dice cuántas filas se han descartado, para que no pase inadvertido.

| # | Columna | Destino |
|---|---|---|
| 1 | ID reserva | `Id externo` de la reserva. **Es la clave**: identifica una reserva ya cargada |
| 2 | Código reserva | `Cód. externo`. No se repite entre reservas, pero puede venir vacío |
| 3 | Huésped / Cliente | Inquilino, buscado por nombre y creado si no existe |
| 4 | Propiedad / Unidad | solo descriptivo |
| 5 | ID interno propiedad | Propiedad de la reserva |
| 6 | ID interno unidad | Subpropiedad |
| 7-8 | Check-in / Check-out | Fechas de la reserva |
| 9 | Fianza | `Importe` de la fianza |
| 10 | Cantidad devuelta | `Importe devuelto` de la fianza |
| 11 | Cantidad descontada | `Importe retenido` de la fianza |
| 12 | Balance de fianzas | se recalcula y se contrasta |
| 13 | Tipo cliente | Ficha del inquilino; la reserva lo hereda |
| 14 | Tipo huésped | Reserva |
| 15 | Canal | Dimensión de canal de la reserva |
| 16 | Noches | se contrasta con el check-out menos el check-in |
| 17 | Importe contrato | `Importe alquiler` de la reserva |
| 18 | Renta mensual | `Renta mensual` de la reserva |
| 19-21 | notas sin título | `Observaciones origen`, unidas en una |

Ojo con dos detalles del formato: la fila de títulos parte `"Cantidad Devuelta"` en dos líneas dentro del campo entrecomillado, y **las columnas 10 y 11 se llaman igual** aunque una es la devolución y la otra el descuento. Por eso se lee por posición.

### Cómo se resuelve la subpropiedad

Primero por el campo **`Id externo`** de la subpropiedad, que es donde debería estar el código del origen. Si no está informado, por el patrón del código: el último segmento es el número de habitación, de modo que `ES-01-01-065-006` es la H6. El sufijo `000` significa la propiedad completa, que en el modelo de datos es una reserva **sin subpropiedad**.

Si el Id de unidad no empieza por el código de la propiedad, la línea sale con aviso.

## Errores y avisos

Un **error** impide crear la reserva:

- la propiedad no existe, o no se ha podido identificar la subpropiedad;
- el canal no existe como valor de la dimensión de canal (los canales no se crean solos: son valores de dimensión y se dan de alta a mano);
- las fechas faltan o el check-out no es posterior al check-in;
- el Id o el código de reserva se repiten dentro del fichero, o el código ya lo tiene otra reserva distinta;
- **la reserva se solapa** con otra de la misma subpropiedad. Una reserva de la propiedad completa choca con cualquier subpropiedad y al revés. Se comprueba contra las reservas ya existentes y contra las demás filas del propio fichero.

Un **aviso** deja importar pero señala que el fichero no cuadra:

- las noches del fichero no coinciden con las que van del check-in al check-out;
- el balance de la fianza no cuadra con `fianza − devuelto − descontado`;
- la cantidad descontada es negativa, o la devuelta supera la fianza;
- la propiedad no tiene comunicada la dimensión PROPIEDAD, así que la reserva nacerá sin ella;
- la reserva ya estaba cargada (según la configuración).

## Contabilidad de las fianzas

Al procesar una fianza con importe se registra su asiento: **cargo en la cuenta puente** y **abono en la cuenta de fianzas**, por el importe entregado por el inquilino y sin IVA.

- **Nº de documento**: el nº de la reserva.
- **Nº de documento externo**: el *Cód. externo* de la reserva (el código del sistema de origen, `HD10WHZHGS`).
- **Fecha de registro**: la fecha de trabajo. El fichero es un cuadre de lo que hay retenido *hoy*, y registrar cada fianza en su fecha de check-in daría de lleno en periodos cerrados y, en las reservas futuras, en fechas por venir.
- **Dimensiones**: las de la reserva, así que el asiento lleva PROPIEDAD y el canal.

El asiento se puede consultar desde la ficha de la fianza con **Movimientos contables** (los dos apuntes) o con **Navegar** (todo lo registrado con ese documento). La ficha guarda el *Nº documento contable* y la *Fecha registro contable*, y con ellos evita registrar dos veces la misma fianza.

Si prefieres importar sin contabilizar, se desactiva con *Contabilizar fianzas al importar* y luego se registra fianza a fianza con la acción **Registrar asiento**. El registro va dentro de la misma transacción que el resto de la línea: si falla (periodo cerrado, cuenta bloqueada), se deshace la línea entera y queda con el motivo.

> **Solo se contabiliza el cobro.** Las devoluciones y retenciones no generan apunte, ni aquí ni en el flujo manual. Para las fianzas que el fichero trae ya devueltas, la cuenta de fianzas reflejará el importe bruto cobrado y no el saldo vivo.

## Configuración

En **Configuración gestión propiedades**, grupo *Importación de reservas*:

| Campo | Uso |
|---|---|
| Dimensión canal | Dimensión cuyos valores son los canales (Direct, website, Gestion…). El canal de cada reserva se guarda como valor de esta dimensión. |
| Reservas ya cargadas | Qué hacer cuando llega una reserva cuyo Id externo ya existe: *Avisar sin modificar* (por defecto, enumera las diferencias y no toca nada), *Actualizar*, o *Dar error*. |
| Crear inquilinos y tipos que falten | Da de alta automáticamente inquilinos, tipos de cliente y tipos de huésped. Activado por defecto. |

## Decisiones que conviene conocer

**Los inquilinos se casan por nombre normalizado**, ignorando acentos, mayúsculas y espacios de más, porque en el origen conviven "Sergio Ramón" y "Sergio Ramon" para la misma persona. Aun así el nombre es un criterio débil: la columna *Alta de inquilino* de la hoja deja ver qué inquilinos se van a crear antes de procesar.

**El importe del alquiler lo manda el fichero**, no la lista de precios de la propiedad. Se asigna directamente después de validar propiedad y fechas, porque esas validaciones recalculan el importe.

**El estado de la reserva sale de sus fechas** contra la fecha de trabajo: pasada, queda con check-out registrado; en curso, con check-in; futura, confirmada.

**Las fianzas se escriben por asignación directa**, sin pasar por las validaciones de la ficha. Esas validaciones están pensadas para el flujo manual (no dejan retocar una fianza ya devuelta) y aquí lo que se hace es reflejar el cuadre tal y como viene. El descuento negativo del origen no se propaga: se avisa y se guarda a cero.

**Cada línea se procesa en su propia transacción**: si una falla, se deshace solo esa y queda marcada con el error, sin tirar abajo el resto del lote.

## Objetos

| Objeto | ID | Nombre |
|---|---|---|
| Table | 82800 | BeDyn Res. Import Line |
| Table | 82801 | BeDyn Customer Type |
| Table | 82802 | BeDyn Guest Type |
| Enum | 82800 | BeDyn Res. Import Status |
| Enum | 82801 | BeDyn Res. Duplicate Action |
| Page | 82800 | BeDyn Res. Import Wksh. |
| Page | 82801 | BeDyn Customer Types |
| Page | 82802 | BeDyn Guest Types |
| Codeunit | 82800 | BeDyn Res. CSV Reader |
| Codeunit | 82801 | BeDyn Res. Import Validation |
| Codeunit | 82802 | BeDyn Res. Import Process |
| Codeunit | 82803 | BeDyn Res. Import Router (reparto por empresa) |
| PermissionSet | 82800 | BeDyn Res. Import |

Campos nuevos en tablas existentes: `Id externo`, `Cód. externo`, `Tipo de cliente`, `Tipo de huésped`, `Cód. canal`, `Renta mensual`, `Observaciones origen` y el conjunto de dimensiones en **Reserva**; `Tipo de cliente` en **Inquilino**; `Importe devuelto` en **Fianza**.
