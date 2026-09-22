namespace BeDynamic.Core;

using Microsoft.Purchases.Vendor;

/// <summary>
/// Muestra el "Saldo periodo" (Net Change) en la lista de proveedores, junto al saldo (DL).
/// El importe respeta el filtro de fecha de la lista, que por defecto llega hasta la fecha de trabajo.
/// </summary>
pageextension 82900 "BeDyn Vendor List Ext" extends "Vendor List"
{
    layout
    {
        addbefore("Balance (LCY)")
        {
            field("BeDyn Net Change"; Rec."Net Change")
            {
                ApplicationArea = All;
                ToolTip = 'Especifica el saldo del proveedor en el periodo del filtro de fecha (por defecto, hasta la fecha de trabajo). Se calcula a partir de los movimientos detallados de proveedor.';
            }
        }
    }
}
