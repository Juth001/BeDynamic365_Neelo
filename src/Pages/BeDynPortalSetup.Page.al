namespace BeDynamic.PortalImport;

page 82600 "BeDyn Portal Setup"
{
    Caption = 'Configuración Importación Portales de Venta';
    PageType = Card;
    SourceTable = "BeDyn Portal Setup";
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

                field("File Encoding"; Rec."File Encoding")
                {
                    ApplicationArea = All;
                }
                field("Process Payouts"; Rec."Process Payouts")
                {
                    ApplicationArea = All;
                }
                field("Process Cancelled Reservations"; Rec."Process Cancelled Reservations")
                {
                    ApplicationArea = All;
                }
                field("Payment Journal Template"; Rec."Payment Journal Template")
                {
                    ApplicationArea = All;
                }
                field("Payment Journal Batch"; Rec."Payment Journal Batch")
                {
                    ApplicationArea = All;
                }
            }
            group(Sales)
            {
                Caption = 'Ventas';

                field("Generic Customer No."; Rec."Generic Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Sales VAT Prod. Posting Group"; Rec."Sales VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                }
                field("Default Variant Code"; Rec."Default Variant Code")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Default Variant"; Rec."Auto Create Default Variant")
                {
                    ApplicationArea = All;
                }
            }
            group(Commissions)
            {
                Caption = 'Comisiones';

                field("Commission Treatment"; Rec."Commission Treatment")
                {
                    ApplicationArea = All;
                }
                field("Commission G/L Account"; Rec."Commission G/L Account")
                {
                    ApplicationArea = All;
                }
                field("Fee VAT G/L Account"; Rec."Fee VAT G/L Account")
                {
                    ApplicationArea = All;
                }
            }
            group(Airbnb)
            {
                Caption = 'Airbnb';

                field("Airbnb Vendor No."; Rec."Airbnb Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Airbnb Payout Bank Account"; Rec."Airbnb Payout Bank Account")
                {
                    ApplicationArea = All;
                }
                field("Airbnb Channel Dim. Value"; Rec."Airbnb Channel Dim. Value")
                {
                    ApplicationArea = All;
                }
                field("Airbnb Sales UoM Code"; Rec."Airbnb Sales UoM Code")
                {
                    ApplicationArea = All;
                }
            }
            group(Booking)
            {
                Caption = 'Booking';

                field("Booking Vendor No."; Rec."Booking Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Booking Payout Bank Account"; Rec."Booking Payout Bank Account")
                {
                    ApplicationArea = All;
                }
                field("Booking Channel Dim. Value"; Rec."Booking Channel Dim. Value")
                {
                    ApplicationArea = All;
                }
                field("Booking Sales UoM Code"; Rec."Booking Sales UoM Code")
                {
                    ApplicationArea = All;
                }
            }
            group(Dimensions)
            {
                Caption = 'Dimensiones';

                field("Property Dimension Code"; Rec."Property Dimension Code")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Dim. Values"; Rec."Auto Create Dim. Values")
                {
                    ApplicationArea = All;
                }
                field("Auto Create Listing Mapping"; Rec."Auto Create Listing Mapping")
                {
                    ApplicationArea = All;
                }
                field("Channel Dimension Code"; Rec."Channel Dimension Code")
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
            action(Worksheet)
            {
                Caption = 'Hoja de importación';
                ApplicationArea = All;
                Image = Worksheet;
                RunObject = page "BeDyn Portal Import Worksheet";
                ToolTip = 'Abre la hoja de importación de movimientos de los portales.';
            }
            action(ListingMapping)
            {
                Caption = 'Mapeo alojamientos';
                ApplicationArea = All;
                Image = Dimensions;
                RunObject = page "BeDyn Portal Listing Mapping";
                ToolTip = 'Abre el mapeo de alojamientos de los portales a propiedades.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Worksheet_Promoted; Worksheet) { }
                actionref(ListingMapping_Promoted; ListingMapping) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
