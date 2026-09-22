# NEE - Asistente creación de propiedades

Asistente paso a paso dentro de Business Central para el alta completa de una propiedad de Neelo: producto con variantes por habitación, valor de dimensión, proyecto y ficha de propiedad del módulo de gestión (con una subpropiedad por habitación), con generación automática del código de propiedad.

## Uso

Buscar **"Asistente creación de propiedades"** en el Buscador (o abrirlo desde la página de configuración, acción *Crear propiedad...*). El asistente guía en 6 pasos:

1. **Dirección**: línea de dirección (calle y número, sin código postal), país (2 letras) y propietario. La dirección es la descripción de todas las entidades; el propietario se asigna a la ficha de propiedad.
2. **Empresa gestora**: 01 Tepoz, 02 Erasmus (lista editable).
3. **Tipo de propiedad**: valor de la dimensión de tipos; su nº de orden en la dimensión (el primero siempre es 01) da el tercer segmento del código.
4. **Habitaciones**: N habitaciones → variantes H0 (propiedad completa) más H1…HN. Con 0 (estudio), solo H0.
5. **Plantilla de producto**: plantilla estándar de BC que se aplicará al producto (se propone la de la configuración; se puede cambiar o dejar vacía).
6. **Confirmación**: muestra el código propuesto y el resumen; *Crear* genera todas las entidades y abre la ficha de propiedad. El código es editable (ver abajo).

## El código de propiedad

```
[País]-[Empresa]-[Tipo]-[Secuencial]      p.ej.  ES-01-02-003
  2 letras │ 01 Tepoz │ orden del valor en │ correlativo a 3 cifras
  del país │ 02 Erasmus │ la dim. de tipos │ por País-Empresa-Tipo
           │           │ (el 1º siempre es 01) │
```

El secuencial es el máximo existente + 1 entre los productos con ese prefijo, saltando códigos ya usados por un producto, un valor de dimensión o un proyecto. El código se usa igual en las tres entidades, que quedan enlazadas por él (mismo criterio que la importación de portales de venta: la propiedad se factura como producto y su código es el valor de dimensión).

Este código es solo una **propuesta**: en el paso 6 el campo es editable y se puede sustituir por cualquier otro, respete o no el formato anterior. Al escribirlo se comprueba en el acto que no lo esté usando ya un producto, un valor de dimensión, un proyecto o una propiedad. Dejando el campo vacío se vuelve al código automático. Si se retrocede a pasos anteriores, un código escrito a mano se conserva; el automático se recalcula con los nuevos datos.

## Numeración enlazada de los cuatro maestros

Los cuatro maestros de una propiedad —**producto**, **valor de dimensión**, **proyecto** y **propiedad**— comparten código desde que los crea el asistente. Para que sigan compartiéndolo, la casilla **Numeración enlazada de maestros** de *Configuración gestión propiedades* (activada por defecto) propaga el cambio de código: al renombrar cualquiera de los cuatro se renombran también los otros tres.

El cambio se puede lanzar desde cualquiera de ellos y funciona así:

1. Se comprueba que el usuario tiene marcado **Puede renumerar propiedades** en la configuración de usuarios. Si no lo tiene —o no tiene ficha allí—, el cambio se rechaza con un aviso.
2. Se comprueba que el código nuevo está libre en los cuatro maestros. Si lo ocupa alguno, se avisa y no se hace nada.
3. Se pide confirmación indicando el código actual, el nuevo y en qué maestros se va a cambiar. Si se responde que no, no se cambia nada en ningún sitio.
4. Se renombran los cuatro con el `Rename` estándar de cada tabla, de modo que es el propio Business Central el que arrastra movimientos, documentos, variantes, subpropiedades y dimensiones. Si alguno de los cuatro no pasa sus validaciones, el error deshace toda la operación y los cuatro se quedan como estaban.

Solo entran en el circuito los códigos que corresponden a una **ficha de propiedad**: la propiedad es el maestro que ancla el grupo. Renombrar un producto, un proyecto o un valor de dimensión que no pertenezca a ninguna propiedad funciona como siempre, sin preguntar nada.

Con la casilla desactivada, cada maestro se renombra por su cuenta y los códigos pueden separarse.

### Informe de comparación

El informe **Comparación maestros de propiedad** (buscador, o acción *Comparar maestros de propiedad* en la configuración de gestión de propiedades) recorre las propiedades y, para cada una, dice si existen el producto, el valor de dimensión y el proyecto con su mismo código, y si los campos *Nº producto* y *Nº proyecto* de la ficha apuntan a él. La cabecera resume si cuadra todo o cuántas propiedades tienen diferencias, y al final lista los valores de la dimensión de propiedad que ya no tienen ficha. La opción **Solo diferencias** deja fuera las propiedades correctas.

## Configuración

Página **Configuración asistente propiedades**:

| Campo | Uso |
|---|---|
| Dimensión tipo de propiedad | Dimensión cuyos valores son los tipos (por defecto `TIPOPROPIEDAD`). |
| Dimensión propiedad | Dimensión donde se crea el valor de cada propiedad (por defecto `PROPIEDAD`), asignada como dimensión por defecto al producto y al proyecto. |
| Plantilla de producto | Plantilla de producto estándar de BC que el asistente propone en el paso 5 (aporta tipo, unidad de medida, grupos de registro y dimensiones de la plantilla). Vacía = producto sin esos datos, a completar a mano. |
| Cliente genérico proyectos | Cliente que se asigna a los proyectos de propiedad creados por el asistente. |

**Empresas gestoras**: lista propia (se precarga con 01 Tepoz y 02 Erasmus la primera vez), **compartida entre todas las empresas** de la base de datos y con el check *Empresa principal* (titular del monedero Pleo; solo puede haber una), editable desde la acción *Empresas gestoras* de la configuración.

**Plantilla de tareas**: lista de las tareas que se crean en cada proyecto de propiedad, editable desde la acción *Plantilla de tareas*. Se precarga con 10 Mobiliario, 20 Material Obra, 30 Decoración, 40 Mantenimiento, 50 Electrodomésticos, 60 Menaje y 70 Otro. Cada tarea puede indicar opcionalmente tipo (cuenta contable, producto o recurso), nº y cantidad: en ese caso el asistente crea además una línea de planificación de tipo presupuesto para la tarea.

## Entidades creadas por cada alta

| Entidad | Código | Descripción |
|---|---|---|
| Producto | código de propiedad | línea de dirección |
| Variantes H0…HN | H0 = propiedad completa, H1…HN = una por habitación | `Dirección - H0` … `Dirección - HN` |
| Valor de la dimensión propiedad | código de propiedad | línea de dirección |
| Proyecto | código de propiedad | línea de dirección, con el cliente genérico de proyectos |
| Tareas del proyecto | según la plantilla de tareas (10 Mobiliario … 70 Otro) | de la plantilla |
| Líneas de planificación | una por tarea que tenga tipo y nº en la plantilla (presupuesto, fecha de trabajo) | de la cuenta/producto/recurso |
| Propiedad (módulo de gestión) | código de propiedad | línea de dirección, con propietario, país, tipo de alquiler según habitaciones y enlazada al producto y al proyecto |
| Subpropiedades H1…HN | una por habitación, enlazada a su variante (la master, si está configurada, se enlaza a H0) | `Dirección - H1` … `Dirección - HN` |

Al producto y al proyecto se les asignan como dimensiones por defecto la **propiedad** recién creada y el **tipo de propiedad** elegido, antes de crear las tareas, de modo que las tareas y sus líneas de planificación las heredan. Si la plantilla de producto ya traía alguna de esas dimensiones sin valor, el asistente completa el valor.

## Objetos

| Objeto | ID | Nombre |
|---|---|---|
| Table | 82400 | BeDyn Property Setup |
| Table | 82401 | BeDyn Property Mgt. Company |
| Table | 82402 | BeDyn Property Task Template |
| Page | 82400 | BeDyn Property Setup |
| Page | 82401 | BeDyn Property Mgt. Companies |
| Page | 82403 | BeDyn Property Task Templates |
| Page | 82402 | BeDyn Property Wizard (NavigatePage) |
| Codeunit | 82400 | BeDyn Property Creation |
| Codeunit | 82507 | BeDyn Property Code Sync (numeración enlazada de los 4 maestros) |
| Codeunit | 82508 | BeDyn Property Upgrade (activa la numeración enlazada en bases ya instaladas) |
| Report | 82502 | BeDyn Property Code Check (comparación de los 4 maestros) |
| TableExtension | 82502 | BeDyn User Setup (campo *Puede renumerar propiedades*) |
| PageExtension | 82500 | BeDyn User Setup Ext |
| PageExtension | 82400 | BeDyn Item List Ext (acción *Actualizar Dimensión propiedad* en la lista de productos) |
| PermissionSet | 82400 | BeDyn Property Wiz. |

## Otros ficheros

- **[SystemPromptAsistentePropiedades.md](SystemPromptAsistentePropiedades.md)** — especificación original del flujo en forma de system prompt para un agente de IA externo con acceso a BC (vía MCP o API). La extensión AL implementa este mismo flujo de forma nativa; el prompt queda como documentación y como alternativa si algún día se quiere operar por chat.
