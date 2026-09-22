namespace BeDynamic.PropertyManagement;

using Microsoft.Inventory.Item;

codeunit 82503 "BeDyn Property Picture Sync"
{
    procedure SyncAll()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Property: Record "BeDyn Property";
        PropertyRoom: Record "BeDyn Property Room";
    begin
        Property.SetFilter("Item No.", '<>%1', '');
        if Property.FindSet() then
            repeat
                if Item.Get(Property."Item No.") then begin
                    UpdatePropertyPicture(Property, Item);
                    PropertyRoom.SetRange("Property No.", Property."No.");
                    PropertyRoom.SetFilter("Variant Code", '<>%1', '');
                    if PropertyRoom.FindSet() then
                        repeat
                            if ItemVariant.Get(Property."Item No.", PropertyRoom."Variant Code") then
                                UpdateRoomPicture(PropertyRoom, ItemVariant);
                        until PropertyRoom.Next() = 0;
                end;
            until Property.Next() = 0;
    end;

    local procedure UpdatePropertyPicture(var Property: Record "BeDyn Property"; Item: Record Item)
    begin
        if Property.Picture.MediaId = Item.Picture.MediaId then
            exit;
        Property.Picture := Item.Picture;
        Property.Modify();
    end;

    local procedure UpdateRoomPicture(var PropertyRoom: Record "BeDyn Property Room"; ItemVariant: Record "Item Variant")
    begin
        if PropertyRoom.Picture.MediaId = ItemVariant.Picture.MediaId then
            exit;
        PropertyRoom.Picture := ItemVariant.Picture;
        PropertyRoom.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, OnAfterModifyEvent, '', false, false)]
    local procedure SyncPropertiesOnItemModify(var Rec: Record Item)
    var
        Property: Record "BeDyn Property";
    begin
        if Rec.IsTemporary() then
            exit;
        Property.SetRange("Item No.", Rec."No.");
        if Property.FindSet() then
            repeat
                UpdatePropertyPicture(Property, Rec);
            until Property.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", OnAfterModifyEvent, '', false, false)]
    local procedure SyncRoomsOnItemVariantModify(var Rec: Record "Item Variant")
    var
        Property: Record "BeDyn Property";
        PropertyRoom: Record "BeDyn Property Room";
    begin
        if Rec.IsTemporary() then
            exit;
        Property.SetRange("Item No.", Rec."Item No.");
        if Property.FindSet() then
            repeat
                PropertyRoom.SetRange("Property No.", Property."No.");
                PropertyRoom.SetRange("Variant Code", Rec.Code);
                if PropertyRoom.FindSet() then
                    repeat
                        UpdateRoomPicture(PropertyRoom, Rec);
                    until PropertyRoom.Next() = 0;
            until Property.Next() = 0;
    end;
}
