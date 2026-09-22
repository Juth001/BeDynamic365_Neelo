namespace Neelo.DebtManagement;

using Microsoft.Finance.ReceivablesPayables;

permissionset 81100 "BeDyn Debt Mgt."
{
    Assignable = true;
    Caption = 'BeDyn Gestión deuda';
    Permissions = tabledata "BeDyn Debt" = RIMD,
        tabledata "BeDyn Debt Amortization Line" = RIMD,
        tabledata "Cartera Setup" = R,
        table "BeDyn Debt" = X,
        table "BeDyn Debt Amortization Line" = X,
        codeunit "BeDyn Debt Amortization Calc" = X,
        page "BeDyn Debt Amortization" = X,
        page "BeDyn Debt Card" = X,
        page "BeDyn Debt List" = X;
}
