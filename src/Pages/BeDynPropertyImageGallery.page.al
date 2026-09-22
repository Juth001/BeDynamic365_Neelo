namespace BeDynamic.PropertyManagement;

using System.Integration;
using System.Utilities;

page 82535 "BeDyn Property Image Gallery"
{
    PageType = CardPart;
    SourceTable = "BeDyn Property Image";
    Caption = 'Galería de imágenes';
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            field(Image; Rec.Image)
            {
                ApplicationArea = All;
                ShowCaption = false;
                ToolTip = 'Imagen actual de la galería.';
            }
            field(PositionText; GetPositionText())
            {
                ApplicationArea = All;
                Caption = 'Imagen';
                Editable = false;
                ToolTip = 'Posición de la imagen actual dentro de la galería.';
            }
            field("File Name"; Rec."File Name")
            {
                ApplicationArea = All;
                Caption = 'Archivo';
                Editable = false;
                ToolTip = 'Nombre del archivo de la imagen.';
            }
            // Temporizador del pase automático: un WebPageViewer con un setTimeout en
            // JavaScript que notifica a AL (trigger Callback) cada 5 segundos. Es el
            // patrón recomendado desde que se retiró el add-in PingPong.
            usercontrol(Timer; WebPageViewer)
            {
                ApplicationArea = All;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    TimerReady := true;
                    ArmTimer();
                end;

                trigger Callback(data: Text)
                begin
                    if AutoPlay then
                        AdvanceImage();
                    ArmTimer();
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PreviousImage)
            {
                ApplicationArea = All;
                Caption = 'Anterior';
                Image = PreviousRecord;
                Enabled = HasImages;
                ToolTip = 'Muestra la imagen anterior. Pausa el pase automático.';

                trigger OnAction()
                begin
                    AutoPlay := false;
                    ArmTimer();
                    if Rec.Next(-1) <> 0 then
                        CurrPage.Update(false);
                end;
            }
            action(NextImage)
            {
                ApplicationArea = All;
                Caption = 'Siguiente';
                Image = NextRecord;
                Enabled = HasImages;
                ToolTip = 'Muestra la imagen siguiente. Pausa el pase automático.';

                trigger OnAction()
                begin
                    AutoPlay := false;
                    ArmTimer();
                    if Rec.Next(1) <> 0 then
                        CurrPage.Update(false);
                end;
            }
            action(PlaySlideshow)
            {
                ApplicationArea = All;
                Caption = 'Reproducir';
                Image = Start;
                Visible = not AutoPlay;
                ToolTip = 'Reanuda el pase automático de imágenes.';

                trigger OnAction()
                begin
                    AutoPlay := true;
                    ArmTimer();
                end;
            }
            action(PauseSlideshow)
            {
                ApplicationArea = All;
                Caption = 'Pausar';
                Image = Pause;
                Visible = AutoPlay;
                ToolTip = 'Detiene el pase automático de imágenes.';

                trigger OnAction()
                begin
                    AutoPlay := false;
                    ArmTimer();
                end;
            }
            action(ShowGrid)
            {
                ApplicationArea = All;
                Caption = 'Ver parrilla';
                Image = ShowMatrix;
                ToolTip = 'Abre las imágenes en una lista que puede verse como iconos o iconos grandes con el selector de diseño (arriba a la derecha de la lista), igual que la lista de productos.';

                trigger OnAction()
                var
                    PropertyImage: Record "BeDyn Property Image";
                begin
                    PropertyImage.Copy(Rec);
                    Page.Run(Page::"BeDyn Property Image List", PropertyImage);
                end;
            }
            action(ImportImage)
            {
                ApplicationArea = All;
                Caption = 'Añadir';
                Image = Import;
                ToolTip = 'Añade una imagen a la galería desde un archivo.';

                trigger OnAction()
                begin
                    ImportFromDevice();
                end;
            }
            action(ExportImage)
            {
                ApplicationArea = All;
                Caption = 'Exportar';
                Image = Export;
                Enabled = HasImages;
                ToolTip = 'Exporta la imagen actual a un archivo.';

                trigger OnAction()
                begin
                    ExportToFile();
                end;
            }
            action(DeleteImage)
            {
                ApplicationArea = All;
                Caption = 'Eliminar';
                Image = Delete;
                Enabled = HasImages;
                ToolTip = 'Elimina la imagen actual de la galería.';

                trigger OnAction()
                begin
                    DeleteCurrent();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        AutoPlay := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HasImages := Rec."Line No." <> 0;
    end;

    // Re-arma el temporizador: cada SetContent sustituye el documento anterior (y su
    // setTimeout pendiente), por lo que nunca hay dos temporizadores a la vez.
    local procedure ArmTimer()
    begin
        if not TimerReady then
            exit;
        if AutoPlay then
            CurrPage.Timer.SetContent(StrSubstNo(TimerHtmlTok, AutoPlayOnTxt), TimerScriptTok)
        else
            CurrPage.Timer.SetContent(StrSubstNo(TimerHtmlTok, AutoPlayOffTxt), TimerScriptTok);
    end;

    // Avanza a la siguiente imagen (vuelve a la primera al llegar al final). Solo actúa
    // cuando hay más de una imagen para no refrescar la página sin necesidad.
    local procedure AdvanceImage()
    var
        PropertyImage: Record "BeDyn Property Image";
    begin
        PropertyImage.Copy(Rec);
        if PropertyImage.Count() < 2 then
            exit;
        if Rec.Next(1) = 0 then
            if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure GetPositionText(): Text
    var
        PropertyImage: Record "BeDyn Property Image";
        Index: Integer;
        Total: Integer;
    begin
        if Rec."Line No." = 0 then
            exit('');
        PropertyImage.Copy(Rec);
        Total := PropertyImage.Count();
        PropertyImage.SetFilter("Line No.", '<=%1', Rec."Line No.");
        Index := PropertyImage.Count();
        exit(StrSubstNo(PositionTxt, Index, Total));
    end;

    local procedure ImportFromDevice()
    var
        PropertyImage: Record "BeDyn Property Image";
        PicInStream: InStream;
        FromFileName: Text;
        PropertyNo: Code[20];
        RoomNo: Code[20];
    begin
        GetContext(PropertyNo, RoomNo);
        if PropertyNo = '' then
            Error(NoContextErr);
        if not UploadIntoStream(SelectPictureTxt, '', FileFilterTxt, FromFileName, PicInStream) then
            exit;

        PropertyImage."Property No." := PropertyNo;
        PropertyImage."Room No." := RoomNo;
        PropertyImage."Line No." := GetNextLineNo(PropertyNo, RoomNo);
        PropertyImage."File Name" := CopyStr(FromFileName, 1, MaxStrLen(PropertyImage."File Name"));
        PropertyImage.Image.ImportStream(PicInStream, FromFileName);
        PropertyImage.Insert(true);
        CurrPage.Update(false);
    end;

    local procedure ExportToFile()
    var
        TempBlob: Codeunit "Temp Blob";
        PicInStream: InStream;
        PicOutStream: OutStream;
        FileName: Text;
    begin
        if Rec."Line No." = 0 then
            exit;
        TempBlob.CreateOutStream(PicOutStream);
        if not Rec.Image.ExportStream(PicOutStream) then
            exit;
        TempBlob.CreateInStream(PicInStream);
        FileName := Rec."File Name";
        if FileName = '' then
            FileName := Rec."Property No." + '_' + Format(Rec."Line No.") + '.jpg';
        DownloadFromStream(PicInStream, '', '', '', FileName);
    end;

    local procedure DeleteCurrent()
    begin
        if Rec."Line No." = 0 then
            exit;
        if not Confirm(DeleteImageQst) then
            exit;
        Rec.Delete(true);
        if Rec.Next(-1) = 0 then
            if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    // El contexto (propiedad/subpropiedad) llega por los filtros del SubPageLink, también
    // cuando la galería está vacía y no hay registro actual.
    local procedure GetContext(var PropertyNo: Code[20]; var RoomNo: Code[20])
    begin
        Rec.FilterGroup(4);
        if Rec.GetFilter("Property No.") <> '' then
            PropertyNo := Rec.GetRangeMin("Property No.");
        if Rec.GetFilter("Room No.") <> '' then
            RoomNo := Rec.GetRangeMin("Room No.");
        Rec.FilterGroup(0);
        if PropertyNo = '' then begin
            if Rec.GetFilter("Property No.") <> '' then
                PropertyNo := Rec.GetRangeMin("Property No.");
            if Rec.GetFilter("Room No.") <> '' then
                RoomNo := Rec.GetRangeMin("Room No.");
        end;
    end;

    local procedure GetNextLineNo(PropertyNo: Code[20]; RoomNo: Code[20]): Integer
    var
        PropertyImage: Record "BeDyn Property Image";
    begin
        PropertyImage.SetRange("Property No.", PropertyNo);
        PropertyImage.SetRange("Room No.", RoomNo);
        if PropertyImage.FindLast() then
            exit(PropertyImage."Line No." + 10000);
        exit(10000);
    end;

    var
        HasImages: Boolean;
        AutoPlay: Boolean;
        TimerReady: Boolean;
        // rgb() en lugar de #666: CodeCop interpreta "#6" como placeholder de diálogo.
        TimerHtmlTok: Label '<div style="font-family:''Segoe UI'',sans-serif;font-size:12px;color:rgb(102,102,102);text-align:center;">%1</div>', Locked = true, Comment = '%1 = Texto de estado';
        TimerScriptTok: Label 'setTimeout(function(){ window.parent.postMessage({ message: "tick", messageType: "Callback" }, "*"); }, 5000);', Locked = true;
        AutoPlayOnTxt: Label 'Pase automático activado';
        AutoPlayOffTxt: Label 'Pase automático en pausa';
        PositionTxt: Label '%1 de %2', Comment = '%1 = Posición, %2 = Total';
        SelectPictureTxt: Label 'Seleccione una imagen';
        FileFilterTxt: Label 'Archivos de imagen (*.jpg;*.jpeg;*.png;*.gif;*.bmp)|*.jpg;*.jpeg;*.png;*.gif;*.bmp', Locked = true;
        DeleteImageQst: Label '¿Desea eliminar la imagen actual?';
        NoContextErr: Label 'Abra la galería desde una propiedad o subpropiedad para añadir imágenes.';
}
