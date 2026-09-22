namespace BeDynamic.CleaningImport;

using Microsoft.Purchases.History;

tableextension 82700 "BeDyn Purch. Inv. Header" extends "Purch. Inv. Header"
{
    fields
    {
        field(82700; "BeDyn Dimensioned"; Boolean)
        {
            Caption = 'Dimensionada';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'La factura ya se ha reclasificado/redimensionado desde la hoja de importación de limpiezas. Una factura dimensionada no admite nuevas líneas de reclasificación.';
        }
    }
}
