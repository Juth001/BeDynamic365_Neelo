namespace BeDynamic.PortalImport;

using BeDynamic.PropertyManagement;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Neelo.RecurringInvoicing;

permissionset 82600 "BeDyn Portal Import"
{
    Caption = 'Importación portales de venta';
    Assignable = true;

    Permissions =
        table "BeDyn Portal Setup" = X,
        tabledata "BeDyn Portal Setup" = RIMD,
        table "BeDyn Portal Import Buffer" = X,
        tabledata "BeDyn Portal Import Buffer" = RIMD,
        table "BeDyn Portal Listing Mapping" = X,
        tabledata "BeDyn Portal Listing Mapping" = RIMD,
        table "BeDyn Portal Import Archive" = X,
        tabledata "BeDyn Portal Import Archive" = RIMD,
        tabledata "BeDyn Portal" = RIM,
        tabledata "Item Variant" = RI,
        tabledata "Item Unit of Measure" = RI,
        tabledata "BeDyn Recurring Inv. Setup" = R,
        tabledata "Gen. Journal Template" = R,
        tabledata "Gen. Journal Batch" = R,
        tabledata "Gen. Journal Line" = RIM,
        codeunit "BeDyn Portal CSV Reader" = X,
        codeunit "BeDyn Portal Validation" = X,
        codeunit "BeDyn Portal Import Process" = X,
        codeunit "BeDyn Portal Channel Mgt." = X,
        page "BeDyn Portal Setup" = X,
        page "BeDyn Portal Import Worksheet" = X,
        page "BeDyn Portal Import Archive" = X,
        page "BeDyn Portal Listing Mapping" = X;
}
