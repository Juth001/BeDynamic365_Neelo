namespace Neelo.RecurringInvoicing;

/// <summary>
/// Maintains the master list of billing codes.
/// </summary>
page 81005 "BeDyn Billing Codes"
{
    Caption = 'Billing Codes';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "BeDyn Billing Code";

    layout
    {
        area(Content)
        {
            repeater(Codes)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the billing code (matched against column 1 of the CSV).';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the billing code.';
                }
            }
        }
    }
}
