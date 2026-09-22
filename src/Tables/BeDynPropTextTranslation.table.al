namespace BeDynamic.PropertyManagement;

using System.Globalization;

table 82540 "BeDyn Prop. Text Translation"
{
    Caption = 'Traducción texto de propiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Prop. Text Translations";
    DrillDownPageId = "BeDyn Prop. Text Translations";

    fields
    {
        field(1; "Property No."; Code[20])
        {
            Caption = 'Nº propiedad';
            TableRelation = "BeDyn Property";
            NotBlank = true;
        }
        field(2; "Room No."; Code[20])
        {
            Caption = 'Nº subpropiedad';
            TableRelation = "BeDyn Property Room"."Room No." where("Property No." = field("Property No."));
            ToolTip = 'Subpropiedad a la que pertenece la traducción. En blanco, la traducción es del texto de la propiedad.';
        }
        field(3; "Text Type"; Enum "BeDyn Property Text Type")
        {
            Caption = 'Tipo de texto';
            ToolTip = 'Texto que se traduce: marketing, normas de la casa, cómo llegar o acceso.';
        }
        field(4; "Language Code"; Code[10])
        {
            Caption = 'Cód. idioma';
            TableRelation = Language;
            NotBlank = true;
            ToolTip = 'Idioma de la traducción. El texto en el idioma por defecto se mantiene en la propia ficha.';
        }
        field(10; Content; Blob)
        {
            Caption = 'Contenido';
        }
    }

    keys
    {
        key(PK; "Property No.", "Room No.", "Text Type", "Language Code")
        {
            Clustered = true;
        }
    }

    procedure GetContent(): Text
    var
        PropertyTextMgt: Codeunit "BeDyn Property Text Mgt.";
        InStr: InStream;
    begin
        CalcFields(Content);
        if not Content.HasValue() then
            exit('');
        Content.CreateInStream(InStr, TextEncoding::UTF8);
        exit(PropertyTextMgt.ReadAllText(InStr));
    end;

    procedure SetContent(NewContent: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Content);
        if NewContent <> '' then begin
            Content.CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(NewContent);
        end;
        Modify();
    end;
}
