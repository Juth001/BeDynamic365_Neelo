namespace BeDynamic.PortalImport;

using BeDynamic.PropertyManagement;

tableextension 82600 "BeDyn Portal Ext" extends "BeDyn Portal"
{
    fields
    {
        field(82600; "Import Channel"; Enum "BeDyn Portal Channel")
        {
            Caption = 'Canal de importación';
            DataClassification = CustomerContent;
            ToolTip = 'Canal de la herramienta de importación de portales que corresponde a este portal (Airbnb o Booking). En blanco, el portal no participa en la importación de CSV. Solo un portal debe tener cada canal.';

            trigger OnValidate()
            var
                Portal: Record "BeDyn Portal";
                DuplicateChannelErr: Label 'El portal %1 ya tiene asignado el canal de importación %2.', Comment = '%1 = código portal, %2 = canal';
            begin
                if "Import Channel" = "Import Channel"::" " then
                    exit;
                Portal.SetFilter(Code, '<>%1', Code);
                Portal.SetRange("Import Channel", "Import Channel");
                if Portal.FindFirst() then
                    Error(DuplicateChannelErr, Portal.Code, "Import Channel");
            end;
        }
    }
}
