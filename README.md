# NEE-CoreSolutions

App AL para **Microsoft Dynamics 365 Business Central**: *Neelo Core Solutions by BeDynamic* — soluciones core de negocio para Neelo (gestión de propiedades de alquiler y automatización de su facturación y contabilidad).

- **Publisher:** BeDynamic · **Rango de IDs:** 80000–89999 · **Runtime:** 15.0
- Un único proyecto/app (un solo `app.json`); se compila contra los símbolos de BC 28.x ES de `.alpackages`.

## Módulos funcionales

| Módulo | Qué hace | IDs | Documentación |
|---|---|---|---|
| **Núcleo de propiedades** | Propiedades, subpropiedades (habitaciones ligadas a variantes de producto), reservas, propietarios, tipos, textos de marketing con traducciones, galería de imágenes, portales e inventario de amenities | 82500–82599 | [Diseño](docs/Propiedades/DiseñoNucleoPropiedades.md) |
| **Asistente creación de propiedades** | Alta guiada de una propiedad: producto con variantes, valor de dimensión, proyecto con tareas y ficha de propiedad, con código `País-Empresa-Tipo-Secuencial` | 82400–82403 | [README](docs/AsistentePropiedades/README.md) |
| **Facturación recurrente (colaboradores)** | Importa el CSV de cuotas a facturar, genera facturas de venta agrupadas/individuales y propaga el Banco de Gestión hasta las remesas de Cartera | 81000–81026 | [README](docs/Colaboradores/README.md) · [Manual técnico](docs/Colaboradores/Manual-Tecnico-Funcional.md) · [Manual de usuario](docs/Colaboradores/Manual-Usuario.md) · [Manual particulares](docs/Colaboradores/Manual-Particulares.md) |
| **Importación Pleo** | Contabiliza los gastos de tarjetas Pleo desde su CSV: facturas de compra con pago contra el banco-monedero, CAPEX a activos fijos, recargas y cashbacks | 82100–82107 | [Diseño](docs/Pleo/DiseñoImportacionPleo.md) |
| **Sales Portal Importations** | Importación multicanal de los CSV de los portales de venta (Airbnb y Booking): facturas de reserva, comisiones y payouts, con deduplicación e histórico | 82600–82604 | [README](docs/Portales/README.md) · [Manual técnico](docs/Portales/Manual-Tecnico-Funcional.md) |
| **Importación Limpiezas** | Importa el detalle mensual del proveedor de limpiezas/lavandería/amenities, lo cuadra contra su factura registrada y genera el diario de reclasificación por propiedad y tarea de proyecto | 82700–82703 | — |
| **Ajustes generales** | Personalizaciones de páginas estándar sin módulo propio: campo *Saldo periodo* en la lista de proveedores | 82900–82999 | — |

## Estructura del repositorio

```
src/                Todo el código AL, en subcarpetas por tipo de objeto:
  Tables/  TableExtensions/  Pages/  PageExtensions/
  Codeunits/  Enums/  Reports/  PermissionSets/  Profiles/
docs/               Documentación funcional, por módulo
Translations/       XLIFF (feature TranslationFile)
app.json            Manifiesto único de la app
```

## Cómo compilar

1. Abrir la carpeta en VS Code con la extensión **AL** (`ms-dynamics-smb.al`).
2. `AL: Download Symbols` si `.alpackages` está vacío (tenant español).
3. `Ctrl+Shift+B` para compilar y publicar con `launch.json`.

## Convenciones

- Commits directos a `main` tras cada cambio que compila.
- Los módulos nuevos usan objetos con prefijo `BeDyn` y captions en español directamente en el código; el módulo de colaboradores mantiene captions en inglés (traducción vía XLIFF pendiente).
- Al eliminar físicamente campos o tablas, el despliegue requiere sincronización *ForceSync* (con pérdida de los datos de esos campos).
