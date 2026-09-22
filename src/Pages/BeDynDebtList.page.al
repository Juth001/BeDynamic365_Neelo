namespace Neelo.DebtManagement;

page 81100 "BeDyn Debt List"
{
    PageType = List;
    SourceTable = "BeDyn Debt";
    CardPageId = "BeDyn Debt Card";
    Caption = 'Deudas';
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Debts)
            {
                field("No."; Rec."No.")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Entity; Rec.Entity)
                {
                }
                field("Entity Name"; Rec."Entity Name")
                {
                }
                field("Start Date"; Rec."Start Date")
                {
                }
                field("End Date"; Rec."End Date")
                {
                }
                field(Capital; Rec.Capital)
                {
                }
                field("Interest Rate %"; Rec."Interest Rate %")
                {
                }
                field("No. of Installments"; Rec."No. of Installments")
                {
                }
                field("Pending Principal"; Rec."Pending Principal")
                {
                }
                field("Pending Interest"; Rec."Pending Interest")
                {
                }
                field("Pending Total"; Rec."Pending Total")
                {
                }
            }
        }
    }
}
