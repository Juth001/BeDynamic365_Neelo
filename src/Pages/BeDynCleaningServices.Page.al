namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using Microsoft.Foundation.UOM;

page 82702 "BeDyn Cleaning Services"
{
    PageType = List;
    SourceTable = "BeDyn Cleaning Service";
    Caption = 'Catálogo de servicios por proveedor';
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Services)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                }
                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Expense G/L Account No."; Rec."Expense G/L Account No.")
                {
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                }
                field("Default Price"; Rec."Default Price")
                {
                }
                field(Blocked; Rec.Blocked)
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PropertyPrices)
            {
                ApplicationArea = All;
                Caption = 'Precios por propiedad';
                Image = Price;
                ToolTip = 'Precios negociados por propiedad para este servicio, que sustituyen al precio pactado general.';

                trigger OnAction()
                var
                    ServicePrice: Record "BeDyn Cleaning Service Price";
                begin
                    ServicePrice.SetRange("Vendor No.", Rec."Vendor No.");
                    ServicePrice.SetRange("Service Code", Rec.Code);
                    Page.Run(Page::"BeDyn Cleaning Service Prices", ServicePrice);
                end;
            }
            action(CreateStandardServices)
            {
                ApplicationArea = All;
                Caption = 'Crear servicios estándar';
                Image = Insert;
                ToolTip = 'Crea para el proveedor habitual de la configuración los tres servicios del fichero estándar (LIMPIEZA, LAVANDERIA y AMENITIE). Revisa cuentas, tareas y precios después.';

                trigger OnAction()
                begin
                    InsertStandardServices();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(PropertyPrices_Promoted; PropertyPrices)
                {
                }
            }
        }
    }

    local procedure InsertStandardServices()
    var
        PropertySetup: Record "BeDyn Property Mgt. Setup";
        CleaningLbl: Label 'Limpieza';
        LaundryLbl: Label 'Lavandería';
        AmenitiesLbl: Label 'Amenities';
        HourLbl: Label 'h';
        KgLbl: Label 'kg';
        KitLbl: Label 'kits';
        NoVendorErr: Label 'Configura el proveedor habitual en la configuración de gestión de propiedades antes de crear los servicios estándar.';
        DoneMsg: Label 'Servicios estándar creados para el proveedor %1. Completa cuenta de gasto, tarea y precio de cada uno.', Comment = '%1 = proveedor';
    begin
        PropertySetup.GetInstance();
        if PropertySetup."Cleaning Vendor No." = '' then
            Error(NoVendorErr);
        InsertService(PropertySetup."Cleaning Vendor No.", 'LIMPIEZA', CleaningLbl, HourLbl);
        InsertService(PropertySetup."Cleaning Vendor No.", 'LAVANDERIA', LaundryLbl, KgLbl);
        InsertService(PropertySetup."Cleaning Vendor No.", 'AMENITIE', AmenitiesLbl, KitLbl);
        Message(DoneMsg, PropertySetup."Cleaning Vendor No.");
        CurrPage.Update(false);
    end;

    local procedure InsertService(VendorNo: Code[20]; ServiceCode: Code[20]; ServiceDescription: Text[100]; UnitOfMeasureCode: Code[10])
    var
        CleaningService: Record "BeDyn Cleaning Service";
    begin
        EnsurePropertyService(ServiceCode, ServiceDescription);
        EnsureUnitOfMeasure(UnitOfMeasureCode);
        if CleaningService.Get(VendorNo, ServiceCode) then
            exit;
        CleaningService.Init();
        CleaningService."Vendor No." := VendorNo;
        CleaningService.Code := ServiceCode;
        CleaningService.Description := ServiceDescription;
        CleaningService."Unit of Measure Code" := UnitOfMeasureCode;
        CleaningService.Insert(true);
    end;

    local procedure EnsurePropertyService(ServiceCode: Code[20]; ServiceDescription: Text[100])
    var
        PropertyService: Record "BeDyn Property Service";
    begin
        if PropertyService.Get(ServiceCode) then
            exit;
        PropertyService.Init();
        PropertyService.Code := ServiceCode;
        PropertyService.Description := ServiceDescription;
        PropertyService.Insert(true);
    end;

    local procedure EnsureUnitOfMeasure(UnitOfMeasureCode: Code[10])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            exit;
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := UnitOfMeasureCode;
        UnitOfMeasure.Insert(true);
    end;
}
