namespace BeDynamic.CleaningImport;

enum 82702 "BeDyn Cleaning Posting Mode"
{
    Extensible = false;
    Caption = 'Modo registro limpiezas';

    value(0; Aggregated)
    {
        Caption = 'Agregado por propiedad y servicio al mes';
    }
    value(1; Detailed)
    {
        Caption = 'Detallado: una línea por fila del fichero';
    }
}
