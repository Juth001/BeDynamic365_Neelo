namespace BeDynamic.PropertyManagement;

using Microsoft.Inventory.Item;
using System.Utilities;

codeunit 82504 "BeDyn Property Image Import"
{
    // Importa imágenes desde un CSV con columnas: nº propiedad; nº subpropiedad; URL.
    // La URL puede ser un archivo o una carpeta compartida de Google Drive ("Cualquier
    // persona con el enlace"). Con una carpeta se importan todas sus imágenes: si la
    // subpropiedad va en blanco, cada archivo se asigna a la subpropiedad cuyo código (o id
    // externo) coincide con el inicio del nombre del archivo (p. ej. "H1_salon.jpg");
    // sin coincidencia queda como imagen general de la propiedad.
    // Todas las imágenes se guardan en la galería (tabla Property Image). La primera de
    // cada destino se usa además como portada: se inserta en el producto (propiedad) o en
    // la variante (subpropiedad) y la sincronización automática la propaga.

    // Permite lanzarlo con RunObject desde el Role Center, que no admite triggers.
    trigger OnRun()
    begin
        ImportFromCsv();
    end;

    procedure ImportFromCsv()
    var
        CsvInStream: InStream;
        Window: Dialog;
        FileName: Text;
        Line: Text;
        ErrorText: Text;
        Errors: TextBuilder;
        LineNo: Integer;
        ImportedInLine: Integer;
        ImportedCount: Integer;
        ErrorCount: Integer;
    begin
        if not UploadIntoStream(SelectFileTxt, '', CsvFilterTxt, FileName, CsvInStream) then
            exit;

        if GuiAllowed() then
            Window.Open(ImportingTxt);

        while not CsvInStream.EOS() do begin
            CsvInStream.ReadText(Line);
            LineNo += 1;
            if GuiAllowed() then
                Window.Update(1, LineNo);
            Line := Line.Trim();
            if (Line <> '') and not ((LineNo = 1) and IsHeaderLine(Line)) then
                if ImportLine(Line, ImportedInLine) then
                    ImportedCount += ImportedInLine
                else begin
                    ErrorCount += 1;
                    ErrorText := LastLineError;
                    if ErrorText = '' then
                        ErrorText := GetLastErrorText();
                    Errors.AppendLine(StrSubstNo(LineErrorTxt, LineNo, ErrorText));
                end;
        end;

        if GuiAllowed() then
            Window.Close();

        if ErrorCount = 0 then
            Message(ImportedMsg, ImportedCount)
        else
            Message(ImportedWithErrorsMsg, ImportedCount, ErrorCount, Errors.ToText());
    end;

    // Importa todas las imágenes de la carpeta de Drive configurada en la subpropiedad.
    procedure ImportRoomDriveFolder(var PropertyRoom: Record "BeDyn Property Room")
    var
        Property: Record "BeDyn Property";
        ImportedCount: Integer;
    begin
        PropertyRoom.TestField("Drive Folder URL");
        if not IsFolderUrl(PropertyRoom."Drive Folder URL") then
            Error(NotFolderUrlErr, PropertyRoom."Drive Folder URL");
        Property.Get(PropertyRoom."Property No.");
        LastLineError := '';
        ImportedCount := ImportFolder(Property, PropertyRoom."Room No.", GetFolderId(PropertyRoom."Drive Folder URL"));
        if (ImportedCount = 0) and (LastLineError <> '') then
            Error(LastLineError);
        Message(ImportedMsg, ImportedCount);
    end;

    local procedure ImportLine(Line: Text; var ImportedInLine: Integer): Boolean
    begin
        LastLineError := '';
        ImportedInLine := 0;
        exit(TryImportLine(Line, ImportedInLine) and (LastLineError = ''));
    end;

    [TryFunction]
    local procedure TryImportLine(Line: Text; var ImportedInLine: Integer)
    var
        Property: Record "BeDyn Property";
        PropertyRoom: Record "BeDyn Property Room";
        TempBlob: Codeunit "Temp Blob";
        Values: List of [Text];
        PropertyNo: Code[20];
        RoomNo: Code[20];
        Url: Text;
        FileId: Text;
        SourceId: Text;
        FileName: Text;
    begin
        Values := Line.Split(GetSeparator(Line));
        if Values.Count() < 3 then begin
            LastLineError := TooFewColumnsErr;
            exit;
        end;
        PropertyNo := CopyStr(CleanValue(Values.Get(1)).ToUpper(), 1, MaxStrLen(PropertyNo));
        RoomNo := CopyStr(CleanValue(Values.Get(2)).ToUpper(), 1, MaxStrLen(RoomNo));
        Url := CleanValue(Values.Get(3));

        if not Url.ToLower().StartsWith('http') then begin
            LastLineError := StrSubstNo(InvalidUrlErr, Url);
            exit;
        end;
        if not Property.Get(PropertyNo) then begin
            LastLineError := StrSubstNo(PropertyNotFoundErr, PropertyNo);
            exit;
        end;
        if RoomNo <> '' then
            if not PropertyRoom.Get(PropertyNo, RoomNo) then begin
                LastLineError := StrSubstNo(RoomNotFoundErr, RoomNo, PropertyNo);
                exit;
            end;

        if IsFolderUrl(Url) then begin
            ImportedInLine := ImportFolder(Property, RoomNo, GetFolderId(Url));
            exit;
        end;

        FileId := ExtractDriveFileId(Url);
        SourceId := FileId;
        if SourceId = '' then
            SourceId := Url;
        if ImageExists(Property."No.", SourceId) then
            exit; // ya importada: línea correcta con 0 imágenes nuevas
        if not DownloadImage(NormalizeFileUrl(Url, FileId), TempBlob) then
            exit;
        if FileId <> '' then
            FileName := FileId
        else
            FileName := GetFileNameFromUrl(Url);
        AddImage(Property, RoomNo, FileName, SourceId, TempBlob, true);
        ImportedInLine := 1;
    end;

    // Descarga el listado público de la carpeta y añade sus imágenes a la galería. La
    // primera imagen de cada destino (propiedad o subpropiedad) se establece como portada.
    local procedure ImportFolder(Property: Record "BeDyn Property"; ForcedRoomNo: Code[20]; FolderId: Text) ImportedCount: Integer
    var
        TempBlob: Codeunit "Temp Blob";
        CoveredTargets: Dictionary of [Text, Boolean];
        FileIds: List of [Text];
        FileNames: List of [Text];
        Html: Text;
        FileName: Text;
        TargetRoom: Code[20];
        MakeCover: Boolean;
        i: Integer;
    begin
        if FolderId = '' then begin
            LastLineError := StrSubstNo(NotFolderUrlErr, FolderId);
            exit(0);
        end;
        if not DownloadText(FolderViewUrlTok + FolderId, Html) then begin
            LastLineError := StrSubstNo(FolderListErr, FolderId);
            exit(0);
        end;
        ParseFolderListing(Html, FileIds, FileNames);
        if FileIds.Count() = 0 then begin
            LastLineError := StrSubstNo(EmptyFolderErr, FolderId);
            exit(0);
        end;

        for i := 1 to FileIds.Count() do begin
            FileName := FileNames.Get(i);
            if IsImageFile(FileName) then
                if not ImageExists(Property."No.", FileIds.Get(i)) then begin
                    Clear(TempBlob);
                    if DownloadImage(DownloadUrlTok + FileIds.Get(i), TempBlob) then begin
                        if ForcedRoomNo <> '' then
                            TargetRoom := ForcedRoomNo
                        else
                            TargetRoom := MatchRoomFromFileName(Property."No.", FileName);
                        MakeCover := not CoveredTargets.ContainsKey(Format(TargetRoom));
                        AddImage(Property, TargetRoom, FileName, FileIds.Get(i), TempBlob, MakeCover);
                        if MakeCover then
                            CoveredTargets.Add(Format(TargetRoom), true);
                        ImportedCount += 1;
                    end;
                end;
        end;

        if ImportedCount > 0 then
            LastLineError := '';
    end;

    // El listado público de una carpeta compartida se obtiene de la vista
    // "embeddedfolderview", que devuelve HTML estático con una entrada por archivo:
    // id="entry-<id de archivo>" ... class="flip-entry-title"><nombre></div>
    local procedure ParseFolderListing(Html: Text; var FileIds: List of [Text]; var FileNames: List of [Text])
    var
        Chunks: List of [Text];
        Chunk: Text;
        Id: Text;
        Name: Text;
        Pos: Integer;
        IsFirst: Boolean;
    begin
        Chunks := Html.Split('id="entry-');
        IsFirst := true;
        foreach Chunk in Chunks do
            if IsFirst then
                IsFirst := false
            else begin
                Pos := Chunk.IndexOf('"');
                if Pos > 1 then begin
                    Id := Chunk.Substring(1, Pos - 1);
                    Name := '';
                    Pos := Chunk.IndexOf(EntryTitleTok);
                    if Pos > 0 then begin
                        Name := Chunk.Substring(Pos + StrLen(EntryTitleTok));
                        Pos := Name.IndexOf('<');
                        if Pos > 1 then
                            Name := Name.Substring(1, Pos - 1)
                        else
                            Name := '';
                    end;
                    if (Id <> '') and (Name <> '') then begin
                        FileIds.Add(Id);
                        FileNames.Add(DecodeHtml(Name));
                    end;
                end;
            end;
    end;

    local procedure DecodeHtml(Value: Text): Text
    begin
        Value := Value.Replace('&#39;', '''');
        Value := Value.Replace('&quot;', '"');
        Value := Value.Replace('&lt;', '<');
        Value := Value.Replace('&gt;', '>');
        Value := Value.Replace('&nbsp;', ' ');
        Value := Value.Replace('&amp;', '&');
        exit(Value);
    end;

    // Asigna la imagen a la subpropiedad cuyo nº o id externo coincide con el inicio del
    // nombre del archivo (separado por '_', '-', '.' o espacio).
    local procedure MatchRoomFromFileName(PropertyNo: Code[20]; FileName: Text): Code[20]
    var
        PropertyRoom: Record "BeDyn Property Room";
        BaseName: Text;
    begin
        BaseName := FileName.ToUpper();
        if BaseName.LastIndexOf('.') > 1 then
            BaseName := BaseName.Substring(1, BaseName.LastIndexOf('.') - 1);
        PropertyRoom.SetRange("Property No.", PropertyNo);
        if PropertyRoom.FindSet() then
            repeat
                if NameMatchesTag(BaseName, PropertyRoom."Room No.") then
                    exit(PropertyRoom."Room No.");
                if NameMatchesTag(BaseName, PropertyRoom."External Id") then
                    exit(PropertyRoom."Room No.");
            until PropertyRoom.Next() = 0;
        exit('');
    end;

    local procedure NameMatchesTag(BaseName: Text; Tag: Text): Boolean
    begin
        if Tag = '' then
            exit(false);
        Tag := Tag.ToUpper();
        if BaseName = Tag then
            exit(true);
        exit(BaseName.StartsWith(Tag + '_') or BaseName.StartsWith(Tag + '-') or
             BaseName.StartsWith(Tag + '.') or BaseName.StartsWith(Tag + ' '));
    end;

    local procedure AddImage(Property: Record "BeDyn Property"; RoomNo: Code[20]; FileName: Text; SourceId: Text; var TempBlob: Codeunit "Temp Blob"; MakeCover: Boolean)
    var
        PropertyImage: Record "BeDyn Property Image";
        PicInStream: InStream;
    begin
        TempBlob.CreateInStream(PicInStream);
        PropertyImage."Property No." := Property."No.";
        PropertyImage."Room No." := RoomNo;
        PropertyImage."Line No." := GetNextLineNo(Property."No.", RoomNo);
        PropertyImage."File Name" := CopyStr(FileName, 1, MaxStrLen(PropertyImage."File Name"));
        PropertyImage."Source Id" := CopyStr(SourceId, 1, MaxStrLen(PropertyImage."Source Id"));
        PropertyImage.Image.ImportStream(PicInStream, FileName, GetMimeType(FileName));
        PropertyImage.Insert(true);
        if MakeCover then
            SetCover(Property, RoomNo, TempBlob, FileName);
    end;

    // La portada se guarda en el producto (propiedad) o en la variante (subpropiedad);
    // la sincronización automática la propaga a la propiedad y a la subpropiedad.
    local procedure SetCover(Property: Record "BeDyn Property"; RoomNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; FileName: Text)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PropertyRoom: Record "BeDyn Property Room";
        PicInStream: InStream;
    begin
        if Property."Item No." = '' then
            exit;
        if RoomNo = '' then begin
            if not Item.Get(Property."Item No.") then
                exit;
            TempBlob.CreateInStream(PicInStream);
            Clear(Item.Picture);
            Item.Picture.ImportStream(PicInStream, FileName, GetMimeType(FileName));
            Item.Modify(true);
        end else begin
            if not PropertyRoom.Get(Property."No.", RoomNo) then
                exit;
            if PropertyRoom."Variant Code" = '' then
                exit;
            if not ItemVariant.Get(Property."Item No.", PropertyRoom."Variant Code") then
                exit;
            TempBlob.CreateInStream(PicInStream);
            Clear(ItemVariant.Picture);
            ItemVariant.Picture.ImportStream(PicInStream, FileName, GetMimeType(FileName));
            ItemVariant.Modify(true);
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

    local procedure ImageExists(PropertyNo: Code[20]; SourceId: Text): Boolean
    var
        PropertyImage: Record "BeDyn Property Image";
    begin
        if SourceId = '' then
            exit(false);
        PropertyImage.SetRange("Property No.", PropertyNo);
        PropertyImage.SetRange("Source Id", CopyStr(SourceId, 1, MaxStrLen(PropertyImage."Source Id")));
        exit(not PropertyImage.IsEmpty());
    end;

    local procedure IsFolderUrl(Url: Text): Boolean
    begin
        exit(Url.Contains('/folders/') or Url.Contains('embeddedfolderview'));
    end;

    local procedure GetFolderId(Url: Text): Text
    begin
        if Url.Contains('/folders/') then
            exit(TakeIdChars(Url.Substring(Url.IndexOf('/folders/') + StrLen('/folders/'))));
        if Url.Contains('id=') then
            exit(TakeIdChars(Url.Substring(Url.IndexOf('id=') + 3)));
        exit('');
    end;

    local procedure ExtractDriveFileId(Url: Text): Text
    begin
        if Url.Contains('/file/d/') then
            exit(TakeIdChars(Url.Substring(Url.IndexOf('/file/d/') + StrLen('/file/d/'))));
        if Url.Contains('id=') then
            exit(TakeIdChars(Url.Substring(Url.IndexOf('id=') + 3)));
        exit('');
    end;

    local procedure NormalizeFileUrl(Url: Text; FileId: Text): Text
    begin
        if FileId = '' then
            exit(Url);
        exit(DownloadUrlTok + FileId);
    end;

    local procedure TakeIdChars(Value: Text) Id: Text
    var
        i: Integer;
        C: Char;
    begin
        for i := 1 to StrLen(Value) do begin
            C := Value[i];
            if ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z')) or
               ((C >= '0') and (C <= '9')) or (C = '-') or (C = '_')
            then
                Id += Format(C)
            else
                exit(Id);
        end;
    end;

    local procedure IsImageFile(FileName: Text): Boolean
    begin
        FileName := FileName.ToLower();
        exit(FileName.EndsWith('.jpg') or FileName.EndsWith('.jpeg') or FileName.EndsWith('.png') or
             FileName.EndsWith('.gif') or FileName.EndsWith('.bmp') or FileName.EndsWith('.webp'));
    end;

    local procedure DownloadImage(Url: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        HeaderValues: List of [Text];
        ResponseInStream: InStream;
        OutStr: OutStream;
    begin
        if not Client.Get(Url, Response) then begin
            LastLineError := StrSubstNo(DownloadFailedErr, Url);
            exit(false);
        end;
        if not Response.IsSuccessStatusCode() then begin
            LastLineError := StrSubstNo(DownloadHttpErr, Response.HttpStatusCode(), Url);
            exit(false);
        end;
        Response.Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then begin
            ContentHeaders.GetValues('Content-Type', HeaderValues);
            if HeaderValues.Count() > 0 then
                if HeaderValues.Get(1).ToLower().Contains('text/html') then begin
                    LastLineError := StrSubstNo(NotSharedErr, Url);
                    exit(false);
                end;
        end;
        Response.Content.ReadAs(ResponseInStream);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, ResponseInStream);
        exit(true);
    end;

    local procedure DownloadText(Url: Text; var Content: Text): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if not Client.Get(Url, Response) then
            exit(false);
        if not Response.IsSuccessStatusCode() then
            exit(false);
        Response.Content.ReadAs(Content);
        exit(true);
    end;

    local procedure IsHeaderLine(Line: Text): Boolean
    var
        Values: List of [Text];
    begin
        Values := Line.Split(GetSeparator(Line));
        if Values.Count() < 3 then
            exit(true);
        exit(not CleanValue(Values.Get(3)).ToLower().StartsWith('http'));
    end;

    local procedure GetSeparator(Line: Text): Text
    begin
        if Line.Contains(';') then
            exit(';');
        exit(',');
    end;

    local procedure CleanValue(Value: Text): Text
    begin
        exit(DelChr(Value, '<>', ' "'));
    end;

    local procedure GetFileNameFromUrl(Url: Text) FileName: Text
    var
        Segments: List of [Text];
    begin
        if Url.Contains('?') then
            Url := Url.Split('?').Get(1);
        Segments := Url.Split('/');
        FileName := Segments.Get(Segments.Count());
        if FileName = '' then
            FileName := 'image';
    end;

    local procedure GetMimeType(FileName: Text): Text
    begin
        FileName := FileName.ToLower();
        case true of
            FileName.EndsWith('.png'):
                exit('image/png');
            FileName.EndsWith('.gif'):
                exit('image/gif');
            FileName.EndsWith('.bmp'):
                exit('image/bmp');
            FileName.EndsWith('.webp'):
                exit('image/webp');
            else
                exit('image/jpeg');
        end;
    end;

    var
        LastLineError: Text;
        FolderViewUrlTok: Label 'https://drive.google.com/embeddedfolderview?id=', Locked = true;
        DownloadUrlTok: Label 'https://drive.google.com/uc?export=download&id=', Locked = true;
        EntryTitleTok: Label 'flip-entry-title">', Locked = true;
        SelectFileTxt: Label 'Seleccione el archivo CSV';
        CsvFilterTxt: Label 'Archivos CSV (*.csv)|*.csv|Todos los archivos (*.*)|*.*', Locked = true;
        ImportingTxt: Label 'Importando imágenes, línea #1######', Comment = '#1 = nº de línea del CSV (campo de diálogo)';
        LineErrorTxt: Label 'Línea %1: %2', Comment = '%1 = Nº línea, %2 = Error';
        TooFewColumnsErr: Label 'La línea no tiene las 3 columnas esperadas (propiedad; subpropiedad; URL).';
        InvalidUrlErr: Label 'La URL "%1" no es válida.', Comment = '%1 = URL';
        PropertyNotFoundErr: Label 'No existe la propiedad %1.', Comment = '%1 = Nº propiedad';
        RoomNotFoundErr: Label 'No existe la subpropiedad %1 en la propiedad %2.', Comment = '%1 = Nº subpropiedad, %2 = Nº propiedad';
        DownloadFailedErr: Label 'No se pudo descargar %1.', Comment = '%1 = URL';
        DownloadHttpErr: Label 'La descarga devolvió el estado HTTP %1 (%2).', Comment = '%1 = Código HTTP, %2 = URL';
        NotSharedErr: Label 'La descarga de %1 devolvió una página web en lugar de una imagen. Compruebe que el archivo o la carpeta de Drive está compartido como "Cualquier persona con el enlace".', Comment = '%1 = URL';
        NotFolderUrlErr: Label 'La URL "%1" no es una carpeta de Google Drive válida (debe contener /folders/).', Comment = '%1 = URL';
        FolderListErr: Label 'No se pudo obtener el contenido de la carpeta de Drive %1. Compruebe que está compartida como "Cualquier persona con el enlace".', Comment = '%1 = Id de carpeta';
        EmptyFolderErr: Label 'La carpeta de Drive %1 no contiene archivos o no está compartida públicamente.', Comment = '%1 = Id de carpeta';
        ImportedMsg: Label 'Se han importado %1 imágenes.', Comment = '%1 = Nº imágenes';
        ImportedWithErrorsMsg: Label 'Se han importado %1 imágenes. %2 líneas con error:\%3', Comment = '%1 = Nº imágenes, %2 = Nº errores, %3 = Detalle';
}
