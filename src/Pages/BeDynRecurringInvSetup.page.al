namespace Neelo.RecurringInvoicing;

/// <summary>
/// Setup card (singleton) for recurring / extra invoicing.
/// </summary>
page 81002 "BeDyn Recurring Inv. Setup"
{
    Caption = 'Recurring Invoicing Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "BeDyn Recurring Inv. Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Active; Rec.Active)
                {
                    ToolTip = 'Specifies whether the configuration is enabled for importing and posting invoices.';
                }
                field("Default Posting"; Rec."Default Posting")
                {
                    ToolTip = 'Specifies whether invoices are posted automatically. If disabled, they are left as drafts.';
                }
                field("Insert Comments"; Rec."Insert Comments")
                {
                    ToolTip = 'If enabled, lines without an amount are imported as comments on the invoices. Only for customers with grouped invoicing; if the customer''s invoicing is individual, the line is marked with error.';
                }
                field("Ignore Comments"; Rec."Ignore Comments")
                {
                    ToolTip = 'If enabled, for customers with individual invoicing the comment lines (without amount) that cannot be linked to a specific invoice are ignored. Exception: if the customer has exactly one comment and one billable line, a single invoice is created with both.';
                }
            }
            group(CSV)
            {
                Caption = 'CSV File';

                field("CSV Separator"; Rec."CSV Separator")
                {
                    ToolTip = 'Specifies the CSV field separator character (default ;).';
                }
                field("Has Header"; Rec."Has Header")
                {
                    ToolTip = 'Specifies whether the first CSV row is a header that must be skipped.';
                }
                field("NIF Source"; Rec."NIF Source")
                {
                    ToolTip = 'Specifies the customer field used to locate the customer by Tax ID (CIF/NIF).';
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ToolTip = 'Specifies whether the amounts in the CSV template include VAT. The generated invoices are created with "Prices Including VAT" set accordingly, so the imported amount is always interpreted the same way as in the template.';
                }
                field("Business Line Dim. Code"; Rec."Business Line Dim. Code")
                {
                    ToolTip = 'Specifies the dimension whose values come in the business line column of the individuals CSV (e.g. LINEANEGOCIO). The value is assigned to the header and to every line of the generated invoices.';
                }
                field("Channel Dim. Code"; Rec."Channel Dim. Code")
                {
                    ToolTip = 'Specifies the dimension whose values come in the channel column of the individuals CSV (e.g. CANAL). The value is assigned to the header and to every line of the generated invoices.';
                }
                field("Unit Dim. Code"; Rec."Unit Dim. Code")
                {
                    ToolTip = 'Specifies the dimension whose values come in the unit column of the individuals CSV (e.g. UNIDAD). The value is assigned to the header and to every line of the generated invoices.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
