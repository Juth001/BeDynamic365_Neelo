namespace BeDynamic.PleoImport;

page 82100 "BeDyn Pleo Setup"
{
    Caption = 'Configuración Importación Pleo';
    PageType = Card;
    SourceTable = "BeDyn Pleo Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Pleo Bank Account No."; Rec."Pleo Bank Account No.")
                {
                    ApplicationArea = All;
                }
                field("Post Action"; Rec."Post Action")
                {
                    ApplicationArea = All;
                }
                field("Vendor Invoice No. Prefix"; Rec."Vendor Invoice No. Prefix")
                {
                    ApplicationArea = All;
                }
                field("File Encoding"; Rec."File Encoding")
                {
                    ApplicationArea = All;
                }
            }
            group(Compras)
            {
                Caption = 'Compras';
                field("Generic Vendor No."; Rec."Generic Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Default G/L Account No."; Rec."Default G/L Account No.")
                {
                    ApplicationArea = All;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Vendor Mapping"; Rec."Auto Create Vendor Mapping")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Expense Map"; Rec."Auto Create Expense Map")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Purchaser Mapping"; Rec."Auto Create Purchaser Mapping")
                {
                    ApplicationArea = All;
                }
                field("Extraord. Expense G/L Account"; Rec."Extraord. Expense G/L Account")
                {
                    ApplicationArea = All;
                }
            }
            group(Capex)
            {
                Caption = 'CAPEX / Activos fijos';
                field("Auto Create Fixed Assets"; Rec."Auto Create Fixed Assets")
                {
                    ApplicationArea = All;
                }
                field("FA Subclass Code"; Rec."FA Subclass Code")
                {
                    ApplicationArea = All;
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = All;
                }
                field("FA Depreciation Book Code"; Rec."FA Depreciation Book Code")
                {
                    ApplicationArea = All;
                }
            }
            group(Dimensiones)
            {
                Caption = 'Dimensiones';
                field("Project Dimension Code"; Rec."Project Dimension Code")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Dim. Values"; Rec."Auto Create Dim. Values")
                {
                    ApplicationArea = All;
                }
                field("Default Project Code"; Rec."Default Project Code")
                {
                    ApplicationArea = All;
                }
            }
            group(Monedero)
            {
                Caption = 'Recargas de monedero y cashback';
                field("Process Wallet Loads"; Rec."Process Wallet Loads")
                {
                    ApplicationArea = All;
                }
                field("Wallet Origin Bank Account"; Rec."Wallet Origin Bank Account")
                {
                    ApplicationArea = All;
                }
                field("Process Cashbacks"; Rec."Process Cashbacks")
                {
                    ApplicationArea = All;
                }
                field("Cashback G/L Account No."; Rec."Cashback G/L Account No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(VendorMapping)
            {
                Caption = 'Mapeo proveedores Pleo';
                ApplicationArea = All;
                Image = VendorLedger;
                RunObject = page "BeDyn Pleo Vendor Mapping";
                ToolTip = 'Abre la tabla de equivalencias entre el código de proveedor de Pleo y el proveedor de Business Central.';
            }
            action(ExpenseMap)
            {
                Caption = 'Mapeo tipos de gasto Pleo';
                ApplicationArea = All;
                Image = ChartOfAccounts;
                RunObject = page "BeDyn Pleo Expense Type Map";
                ToolTip = 'Abre la tabla de equivalencias entre el "Tipo Gasto" de Pleo y la cuenta contable de gasto.';
            }
            action(PurchaserMapping)
            {
                Caption = 'Mapeo compradores Pleo';
                ApplicationArea = All;
                Image = SalesPerson;
                RunObject = page "BeDyn Pleo Purchaser Mapping";
                ToolTip = 'Abre la tabla de equivalencias entre el empleado de Pleo y el comprador/vendedor de Business Central.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
