namespace Neelo.RecurringInvoicing;

/// <summary>
/// Billing configuration list for a customer, opened as related data from the Customer card.
/// </summary>
page 81004 "BeDyn Customer Billing"
{
    Caption = 'Recurring Invoicing';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "BeDyn Customer Billing";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Billing Code"; Rec."Billing Code")
                {
                    ToolTip = 'Specifies the billing code that column 1 of the CSV is matched against to pick this configuration (e.g. REC).';
                }
                field("Billing Type"; Rec."Billing Type")
                {
                    ToolTip = 'Specifies whether this configuration is for recurring or extra (one-off) invoicing.';
                }
                field(Deposit; Rec.Deposit)
                {
                    ToolTip = 'Specifies that this billing code is a deposit: no invoice is generated. The amount is posted to the G/L account of this row with the Management Bank as counterpart, and the deposit is linked to the active reservation of the property (created if there is none).';
                }
                field(Rental; Rec.Rental)
                {
                    ToolTip = 'Specifies that this billing code is a rental: besides generating the invoice, the active reservation of the property of each line is looked up (and created if there is none) and its number is stamped on the invoice.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ToolTip = 'Specifies the sales line type used on the invoice line (G/L account, item or resource).';
                }
                field("Account No."; Rec."Account No.")
                {
                    ToolTip = 'Specifies the G/L account, item or resource number used on the invoice line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the item variant used on the invoice line when the account is an item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ToolTip = 'Specifies the unit of measure used on the generated invoice line. If empty, the default unit of measure of the item or resource is used.';
                }
                field("Management Bank"; Rec."Management Bank")
                {
                    ToolTip = 'Specifies the bank that manages the collection for invoices generated with this billing code. It is propagated to Cartera to filter the remittance.';
                }
                field("Invoice Grouping"; Rec."Invoice Grouping")
                {
                    ToolTip = 'Specifies whether the lines with this billing code are grouped into one invoice or one invoice is issued per line.';
                }
            }
        }
    }
}
