namespace BeDynamic.PleoImport;

permissionset 82100 "BeDyn Pleo Import"
{
    Caption = 'Importación Pleo';
    Assignable = true;

    Permissions =
        table "BeDyn Pleo Setup" = X,
        tabledata "BeDyn Pleo Setup" = RIMD,
        table "BeDyn Pleo Import Buffer" = X,
        tabledata "BeDyn Pleo Import Buffer" = RIMD,
        table "BeDyn Pleo Vendor Mapping" = X,
        tabledata "BeDyn Pleo Vendor Mapping" = RIMD,
        table "BeDyn Pleo Expense Type Map" = X,
        tabledata "BeDyn Pleo Expense Type Map" = RIMD,
        table "BeDyn Pleo Purchaser Mapping" = X,
        tabledata "BeDyn Pleo Purchaser Mapping" = RIMD,
        table "BeDyn Pleo Expense Archive" = X,
        tabledata "BeDyn Pleo Expense Archive" = RIMD,
        table "BeDyn Pleo Posting Preview" = X,
        tabledata "BeDyn Pleo Posting Preview" = RIMD,
        codeunit "BeDyn Pleo CSV Reader" = X,
        codeunit "BeDyn Pleo Validation" = X,
        codeunit "BeDyn Pleo Import Process" = X,
        page "BeDyn Pleo Setup" = X,
        page "BeDyn Pleo Import Worksheet" = X,
        page "BeDyn Pleo Vendor Mapping" = X,
        page "BeDyn Pleo Expense Type Map" = X,
        page "BeDyn Pleo Purchaser Mapping" = X,
        page "BeDyn Pleo Expense Archive" = X,
        page "BeDyn Pleo Posting Preview" = X;
}
