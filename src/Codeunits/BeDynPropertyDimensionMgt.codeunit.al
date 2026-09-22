namespace BeDynamic.PropertyManagement;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using System.Reflection;

codeunit 82506 "BeDyn Property Dimension Mgt."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::DimensionManagement, OnAfterSetupObjectNoList, '', false, false)]
    local procedure OnAfterSetupObjectNoList(var TempAllObjWithCaption: Record AllObjWithCaption temporary)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.InsertObject(TempAllObjWithCaption, Database::"BeDyn Property");
        DimMgt.InsertObject(TempAllObjWithCaption, Database::"BeDyn Property Service");
    end;

    // Fusiona en el conjunto las dimensiones predeterminadas del servicio de la
    // tabla de servicios. Las del servicio prevalecen sobre las que ya hubiera
    // con el mismo código de dimensión.
    procedure AddServiceDefaultDims(DimSetID: Integer; ServiceCode: Code[20]): Integer
    begin
        if ServiceCode = '' then
            exit(DimSetID);
        exit(AddTableDefaultDims(DimSetID, Database::"BeDyn Property Service", ServiceCode));
    end;

    // Fusiona en el conjunto las dimensiones predeterminadas de la propiedad
    // según el parámetro "Trabajar con" de la configuración: las de la ficha de
    // propiedad o las del producto asociado a la propiedad (o con su mismo
    // código si la propiedad no existe o no tiene producto).
    procedure AddPropertyDefaultDims(DimSetID: Integer; PropertyNo: Code[20]): Integer
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        Property: Record "BeDyn Property";
        ItemNo: Code[20];
    begin
        if PropertyNo = '' then
            exit(DimSetID);
        PropertySetup.GetInstance();
        if PropertySetup."Property Dim. Source" = PropertySetup."Property Dim. Source"::Items then begin
            ItemNo := PropertyNo;
            if Property.Get(PropertyNo) and (Property."Item No." <> '') then
                ItemNo := Property."Item No.";
            exit(AddTableDefaultDims(DimSetID, Database::Item, ItemNo));
        end;
        exit(AddTableDefaultDims(DimSetID, Database::"BeDyn Property", PropertyNo));
    end;

    local procedure AddTableDefaultDims(DimSetID: Integer; TableID: Integer; No: Code[20]): Integer
    var
        DefaultDim: Record "Default Dimension";
    begin
        DefaultDim.SetRange("Table ID", TableID);
        DefaultDim.SetRange("No.", No);
        DefaultDim.SetFilter("Dimension Value Code", '<>%1', '');
        if DefaultDim.FindSet() then
            repeat
                DimSetID := AddDimensionToSet(DimSetID, DefaultDim."Dimension Code", DefaultDim."Dimension Value Code");
            until DefaultDim.Next() = 0;
        exit(DimSetID);
    end;

    local procedure AddDimensionToSet(DimSetID: Integer; DimCode: Code[20]; DimValueCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        DimValue.Get(DimCode, DimValueCode);
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        TempDimSetEntry.SetRange("Dimension Code", DimCode);
        if TempDimSetEntry.FindFirst() then
            TempDimSetEntry.Delete();
        TempDimSetEntry.Reset();
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Set ID" := 0;
        TempDimSetEntry."Dimension Code" := DimCode;
        TempDimSetEntry."Dimension Value Code" := DimValueCode;
        TempDimSetEntry."Dimension Value ID" := DimValue."Dimension Value ID";
        TempDimSetEntry.Insert();
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;
}
