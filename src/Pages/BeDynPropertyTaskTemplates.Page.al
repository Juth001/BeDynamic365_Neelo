namespace BeDynamic.PropertyWizard;

page 82403 "BeDyn Property Task Templates"
{
    Caption = 'Plantilla tareas de propiedad';
    PageType = List;
    SourceTable = "BeDyn Property Task Template";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Tasks)
            {
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Planning Type"; Rec."Planning Type")
                {
                    ApplicationArea = All;
                }
                field("Planning No."; Rec."Planning No.")
                {
                    ApplicationArea = All;
                }
                field("Planning Quantity"; Rec."Planning Quantity")
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
