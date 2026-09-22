namespace BeDynamic.PropertyManagement;

page 82541 "BeDyn Prop. Text Transl. Card"
{
    PageType = Card;
    SourceTable = "BeDyn Prop. Text Translation";
    Caption = 'Traducción de texto';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad a la que pertenece la traducción.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                }
                field("Text Type"; Rec."Text Type")
                {
                    ApplicationArea = All;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                }
            }
            group(ContentGroup)
            {
                Caption = 'Contenido';

                field(ContentText; ContentValue)
                {
                    ApplicationArea = All;
                    Caption = 'Contenido';
                    ExtendedDatatype = RichContent;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Texto traducido, con formato enriquecido.';

                    trigger OnValidate()
                    begin
                        Rec.SetContent(ContentValue);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ContentValue := Rec.GetContent();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ContentValue);
    end;

    var
        ContentValue: Text;
}
