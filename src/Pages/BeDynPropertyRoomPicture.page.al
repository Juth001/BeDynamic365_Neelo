namespace BeDynamic.PropertyManagement;

using System.Device;
using System.Environment;

page 82520 "BeDyn Property Room Picture"
{
    PageType = CardPart;
    SourceTable = "BeDyn Property Room";
    Caption = 'Imagen subpropiedad';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            field(Picture; Rec.Picture)
            {
                ApplicationArea = All;
                ShowCaption = false;
                ToolTip = 'Imagen de la subpropiedad.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TakePicture)
            {
                ApplicationArea = All;
                Caption = 'Hacer foto';
                Image = Camera;
                Visible = CameraAvailable;
                ToolTip = 'Activa la cámara del dispositivo para hacer una foto.';

                trigger OnAction()
                begin
                    TakeNewPicture();
                end;
            }
            action(ImportPicture)
            {
                ApplicationArea = All;
                Caption = 'Importar';
                Image = Import;
                ToolTip = 'Importa una imagen desde un archivo.';

                trigger OnAction()
                begin
                    ImportFromDevice();
                end;
            }
            action(ExportPicture)
            {
                ApplicationArea = All;
                Caption = 'Exportar';
                Image = Export;
                Enabled = HasPicture;
                ToolTip = 'Exporta la imagen a un archivo.';

                trigger OnAction()
                begin
                    ExportToFile();
                end;
            }
            action(DeletePicture)
            {
                ApplicationArea = All;
                Caption = 'Eliminar';
                Image = Delete;
                Enabled = HasPicture;
                ToolTip = 'Elimina la imagen de la subpropiedad.';

                trigger OnAction()
                begin
                    if not Confirm(DeleteImageQst) then
                        exit;
                    Clear(Rec.Picture);
                    Rec.Modify(true);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Camera: Codeunit Camera;
    begin
        CameraAvailable := Camera.IsAvailable();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HasPicture := Rec.Picture.Count > 0;
    end;

    local procedure TakeNewPicture()
    var
        Camera: Codeunit Camera;
        PicInStream: InStream;
        PictureName: Text;
    begin
        Rec.TestField("Property No.");
        Rec.TestField("Room No.");
        if not ConfirmOverride() then
            exit;
        if not Camera.GetPicture(PicInStream, PictureName) then
            exit;
        Clear(Rec.Picture);
        Rec.Picture.ImportStream(PicInStream, PictureName);
        Rec.Modify(true);
    end;

    local procedure ImportFromDevice()
    var
        PicInStream: InStream;
        FromFileName: Text;
    begin
        Rec.TestField("Property No.");
        Rec.TestField("Room No.");
        if not ConfirmOverride() then
            exit;
        if not UploadIntoStream(SelectPictureTxt, '', FileFilterTxt, FromFileName, PicInStream) then
            exit;
        Clear(Rec.Picture);
        Rec.Picture.ImportStream(PicInStream, FromFileName);
        Rec.Modify(true);
    end;

    local procedure ExportToFile()
    var
        TenantMedia: Record "Tenant Media";
        PicInStream: InStream;
        FileName: Text;
    begin
        if Rec.Picture.Count = 0 then
            exit;
        if not TenantMedia.Get(Rec.Picture.Item(1)) then
            exit;
        TenantMedia.CalcFields(Content);
        if not TenantMedia.Content.HasValue() then
            exit;
        TenantMedia.Content.CreateInStream(PicInStream);
        FileName := Rec."Property No." + '_' + Rec."Room No." + GetExtension(TenantMedia."Mime Type");
        DownloadFromStream(PicInStream, '', '', '', FileName);
    end;

    local procedure ConfirmOverride(): Boolean
    begin
        if Rec.Picture.Count = 0 then
            exit(true);
        exit(Confirm(OverrideImageQst));
    end;

    local procedure GetExtension(MimeType: Text): Text
    begin
        case MimeType of
            'image/png':
                exit('.png');
            'image/gif':
                exit('.gif');
            'image/bmp':
                exit('.bmp');
            else
                exit('.jpg');
        end;
    end;

    var
        CameraAvailable: Boolean;
        HasPicture: Boolean;
        SelectPictureTxt: Label 'Seleccione una imagen';
        FileFilterTxt: Label 'Archivos de imagen (*.jpg;*.jpeg;*.png;*.gif;*.bmp)|*.jpg;*.jpeg;*.png;*.gif;*.bmp', Locked = true;
        OverrideImageQst: Label 'La subpropiedad ya tiene una imagen. ¿Desea reemplazarla?';
        DeleteImageQst: Label '¿Desea eliminar la imagen?';
}
