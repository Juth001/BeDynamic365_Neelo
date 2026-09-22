namespace BeDynamic.PropertyManagement;

codeunit 82540 "BeDyn Property Text Mgt."
{
    // Utilidades de los textos de propiedades y subpropiedades (marketing,
    // normas de la casa, cómo llegar y acceso). El texto en el idioma por
    // defecto vive en blobs de la propia ficha; las traducciones, en la tabla
    // "Property Text Translation".

    procedure ReadAllText(var InStr: InStream) Content: Text
    var
        Line: Text;
        LF: Char;
    begin
        LF := 10;
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Content = '' then
                Content := Line
            else
                Content += Format(LF) + Line;
        end;
    end;

    // Abre las traducciones de una propiedad (RoomNo = '') o subpropiedad.
    procedure EditTranslations(PropertyNo: Code[20]; RoomNo: Code[20])
    var
        PropertyTextTranslation: Record "BeDyn Prop. Text Translation";
    begin
        PropertyTextTranslation.FilterGroup(2);
        PropertyTextTranslation.SetRange("Property No.", PropertyNo);
        PropertyTextTranslation.SetRange("Room No.", RoomNo);
        PropertyTextTranslation.FilterGroup(0);
        Page.Run(Page::"BeDyn Prop. Text Translations", PropertyTextTranslation);
    end;
}
