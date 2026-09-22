namespace BeDynamic.PropertyManagement;

page 82540 "BeDyn Prop. Text Translations"
{
    PageType = List;
    SourceTable = "BeDyn Prop. Text Translation";
    Caption = 'Traducciones de textos';
    DelayedInsert = true;
    CardPageId = "BeDyn Prop. Text Transl. Card";

    layout
    {
        area(Content)
        {
            repeater(Translations)
            {
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Text Type"; Rec."Text Type")
                {
                    ApplicationArea = All;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                }
                field(HasContent; Rec.Content.HasValue())
                {
                    ApplicationArea = All;
                    Caption = 'Tiene contenido';
                    Editable = false;
                    ToolTip = 'Indica si la traducción tiene contenido. Abre la ficha para editarlo.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Content);
    end;
}
