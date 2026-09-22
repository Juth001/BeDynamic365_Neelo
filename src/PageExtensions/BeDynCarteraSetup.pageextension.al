namespace Neelo.DebtManagement;

using Microsoft.Finance.ReceivablesPayables;

pageextension 81100 "BeDyn Cartera Setup" extends "Cartera Setup"
{
    layout
    {
        addlast(content)
        {
            group(BeDynDebtMgt)
            {
                Caption = 'Gestión deuda';

                field("BeDyn Debt Nos."; Rec."BeDyn Debt Nos.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
