# Facturación recurrente — Importación CSV de colaboradores

Módulo de la app **Neelo Core Solutions by BeDynamic** que importa un CSV con líneas a facturar,
las valida en una tabla de *staging* y genera/registra facturas de venta de forma masiva,
propagando el **Banco de Gestión** del cliente hasta la **Cartera española** para poder filtrar
las remesas de cobro por banco.

- **Namespace:** `Neelo.RecurringInvoicing` · **IDs:** 81000–81026
- Desarrollado originalmente como app independiente; desde el 25/07/2026 está integrado en el
  proyecto único (historial previo en
  [Juth001/NEE---ImportarCSVfacturacionesColaboradores](https://github.com/Juth001/NEE---ImportarCSVfacturacionesColaboradores)).
- Captions y tooltips en inglés; la traducción es-ES vía XLIFF está pendiente (feature
  `TranslationFile` activa en la app).

## Documentación

- **[Manual técnico y funcional](Manual-Tecnico-Funcional.md)** — diseño completo: objetos,
  configuración, formato del CSV, validaciones, generación de facturas, propagación del banco y
  remesas, FAQ.
- **[Manual de usuario](Manual-Usuario.md)** — operativa paso a paso.
- **[Manual de particulares](Manual-Particulares.md)** — plantilla de particulares (propiedad,
  habitación y dimensiones), códigos de alquiler y fianza, y todas las validaciones paso a paso.
- **[Plantilla-Importacion.csv](Plantilla-Importacion.csv)** — plantilla del fichero de
  importación.
- **[Plantilla-Importacion-Particulares.csv](Plantilla-Importacion-Particulares.csv)** — plantilla
  del fichero de importación de particulares (propiedad, habitación y dimensiones).

## Resumen funcional

1. **Datos maestros**: catálogo de *Códigos de Facturación* (p. ej. `REC`, `EXTRA`) y, por
   cliente, sus *filas de facturación* (cliente + código → cuenta/producto/recurso a facturar,
   Banco de Gestión y agrupación Agrupada/Individual).
2. **Importar CSV** desde la página *Invoice Import*: cada importación crea un lote y sus líneas
   quedan en staging como `Pending`.
3. **Validar lote**: marca cada línea `Validated` o `Error` con su mensaje (cliente/NIF,
   código de facturación, fila de facturación del cliente, importes…). Se corrige y revalida.
4. **Generar/Registrar**: crea las facturas — **agrupadas** (una por cliente, código y fecha) o
   **individuales** (una por línea) — y según el parámetro **"Post Automatically"** las registra o
   las deja en borrador. Ese mismo parámetro lo reutiliza la importación de portales de venta como
   interruptor global de registro automático.
5. **Remesas**: el Banco de Gestión llega a factura, movimientos de cliente y Cartera; al
   componer una remesa, la lista de documentos se pre-filtra por el banco de la remesa y un
   suscriptor retira los documentos de otro banco.

Otras opciones del setup: separador y cabecera del CSV, origen del NIF, tratamiento de líneas
sin importe como comentarios (`Insert Comments` / `Ignore Comments`) y precios con IVA incluido.

## Pruebas

`src/Codeunits/ValidationTests.codeunit.al` (Subtype = Test) cubre validaciones básicas; requiere
el Test Toolkit. Para AppSource habría que moverlo a una app de test separada.
