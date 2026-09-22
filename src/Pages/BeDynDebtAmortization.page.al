namespace Neelo.DebtManagement;

page 81102 "BeDyn Debt Amortization"
{
    PageType = ListPart;
    SourceTable = "BeDyn Debt Amortization Line";
    Caption = 'Cuadro de amortización';
    ApplicationArea = All;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Amortization Date"; Rec."Amortization Date")
                {
                }
                field("Principal Amount"; Rec."Principal Amount")
                {
                }
                field("Interest Amount"; Rec."Interest Amount")
                {
                }
                field("Total Amount"; Rec."Total Amount")
                {
                }
                field(Paid; Rec.Paid)
                {
                }
            }
        }
    }
}
