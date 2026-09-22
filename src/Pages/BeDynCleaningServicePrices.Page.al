namespace BeDynamic.CleaningImport;

page 82703 "BeDyn Cleaning Service Prices"
{
    PageType = List;
    SourceTable = "BeDyn Cleaning Service Price";
    Caption = 'Precios de servicios por propiedad';
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Prices)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                }
                field("Service Code"; Rec."Service Code")
                {
                }
                field("Property Code"; Rec."Property Code")
                {
                }
                field(Price; Rec.Price)
                {
                }
            }
        }
    }
}
