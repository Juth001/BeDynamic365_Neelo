namespace Neelo.DebtManagement;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.NoSeries;

/// <summary>
/// La serie de numeración de las deudas vive en la configuración de cartera
/// estándar (localización española), en lugar de una configuración propia.
/// </summary>
tableextension 81100 "BeDyn Cartera Setup" extends "Cartera Setup"
{
    fields
    {
        field(81100; "BeDyn Debt Nos."; Code[20])
        {
            Caption = 'Nº serie deuda';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
            ToolTip = 'Serie numérica para las deudas del módulo de gestión de deuda.';
        }
    }
}
