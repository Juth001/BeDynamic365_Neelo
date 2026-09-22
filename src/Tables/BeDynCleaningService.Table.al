namespace BeDynamic.CleaningImport;

using BeDynamic.PropertyManagement;
using BeDynamic.PropertyWizard;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.UOM;
using Microsoft.Purchases.Vendor;

table 82701 "BeDyn Cleaning Service"
{
    Caption = 'Servicio de proveedor';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Cleaning Services";
    DrillDownPageId = "BeDyn Cleaning Services";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Proveedor';
            TableRelation = Vendor."No.";
            NotBlank = true;
            ToolTip = 'Proveedor que presta el servicio. Cada proveedor tiene su propio catálogo de servicios con sus precios.';
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Código';
            TableRelation = "BeDyn Property Service".Code;
            NotBlank = true;
            ToolTip = 'Código del servicio, de la tabla de servicios, tal y como viene en la columna servicio del fichero, sin acentos (p. ej. LIMPIEZA, LAVANDERIA, AMENITIE).';

            trigger OnValidate()
            var
                PropertyService: Record "BeDyn Property Service";
            begin
                if PropertyService.Get("Code") then
                    Description := PropertyService.Description
                else
                    Description := '';
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Descripción';
            Editable = false;
            ToolTip = 'Descripción del servicio, tomada de la tabla de servicios. Forma parte de las descripciones de las líneas del diario de reclasificación.';
        }
        field(4; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unidad';
            TableRelation = "Unit of Measure";
            ToolTip = 'Unidad de medida de la cantidad del servicio (h, kg, kits...), para mensajes y descripciones.';
        }
        field(10; "Expense G/L Account No."; Code[20])
        {
            Caption = 'Cuenta de gasto';
            TableRelation = "G/L Account" where("Account Type" = const(Posting), Blocked = const(false), "Direct Posting" = const(true));
            ToolTip = 'Cuenta de gasto real donde la reclasificación carga este servicio.';
        }
        field(11; "Job Task No."; Code[20])
        {
            Caption = 'Tarea estándar';
            TableRelation = "BeDyn Property Task Template"."Job Task No.";
            ToolTip = 'Tarea estándar del proyecto de propiedad a la que se imputa el servicio. Debe existir en la plantilla de tareas de propiedad; en los proyectos donde falte se crea automáticamente.';
        }
        field(30; "Default Price"; Decimal)
        {
            Caption = 'Precio pactado';
            DecimalPlaces = 2 : 5;
            MinValue = 0;
            ToolTip = 'Precio unitario acordado con el proveedor para este servicio. Se usa para validar los importes del fichero (cantidad × precio), salvo que la propiedad tenga un precio propio. Con 0 no se valida.';
        }
        field(31; Blocked; Boolean)
        {
            Caption = 'Bloqueado';
            ToolTip = 'Un servicio bloqueado no se importa del fichero del proveedor.';
        }
    }

    keys
    {
        key(PK; "Vendor No.", "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        ServicePrice: Record "BeDyn Cleaning Service Price";
    begin
        ServicePrice.SetRange("Vendor No.", "Vendor No.");
        ServicePrice.SetRange("Service Code", "Code");
        ServicePrice.DeleteAll();
    end;
}
