namespace BeDynamic.PropertyManagement;

using Microsoft.eServices.OnlineMap;

codeunit 82502 "BeDyn Property Online Map Mgt."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Online Map Management", OnBeforeValidAddress, '', false, false)]
    local procedure HandleOnBeforeValidAddress(TableID: Integer; var IsValid: Boolean)
    begin
        if TableID = Database::"BeDyn Property" then
            IsValid := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Online Map Management", OnAfterGetAddress, '', false, false)]
    local procedure HandleOnAfterGetAddress(TableID: Integer; RecPosition: Text; var Parameters: array[12] of Text[100]; var RecordRef: RecordRef)
    var
        Property: Record "BeDyn Property";
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        if TableID <> Database::"BeDyn Property" then
            exit;

        OnlineMapManagement.SetParameters(
            RecordRef, Parameters,
            Property.FieldNo(Address), Property.FieldNo(City), Property.FieldNo(County),
            Property.FieldNo("Post Code"), Property.FieldNo("Country/Region Code"));
    end;
}
