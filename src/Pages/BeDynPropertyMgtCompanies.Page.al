namespace BeDynamic.PropertyWizard;

page 82401 "BeDyn Property Mgt. Companies"
{
    Caption = 'Empresas gestoras de propiedades';
    PageType = List;
    SourceTable = "BeDyn Property Mgt. Company";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Companies)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                }
                field("Main Company"; Rec."Main Company")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.EnsureDefaults();
    end;
}
