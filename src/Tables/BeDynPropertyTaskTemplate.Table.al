namespace BeDynamic.PropertyWizard;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

table 82402 "BeDyn Property Task Template"
{
    Caption = 'Plantilla tareas de propiedad';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property Task Templates";
    DrillDownPageId = "BeDyn Property Task Templates";

    fields
    {
        field(1; "Job Task No."; Code[20])
        {
            Caption = 'Nº tarea';
            NotBlank = true;
            ToolTip = 'Número de la tarea que se crea en cada proyecto de propiedad (p.ej. 10, 20...). Las tareas se crean por orden de este número.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Descripción';
            ToolTip = 'Descripción de la tarea (p.ej. Mobiliario).';
        }
        field(10; "Planning Type"; Option)
        {
            Caption = 'Tipo planificación';
            OptionMembers = " ","G/L Account",Item,Resource;
            OptionCaption = ' ,Cuenta contable,Producto,Recurso';
            ToolTip = 'Tipo de la línea de planificación (presupuesto) que se crea para la tarea. Vacío = la tarea se crea sin línea de planificación.';
        }
        field(11; "Planning No."; Code[20])
        {
            Caption = 'Nº planificación';
            TableRelation = if ("Planning Type" = const("G/L Account")) "G/L Account"."No." where("Direct Posting" = const(true), "Account Type" = const(Posting))
            else
            if ("Planning Type" = const(Item)) Item."No."
            else
            if ("Planning Type" = const(Resource)) Resource."No.";
            ToolTip = 'Cuenta contable, producto o recurso de la línea de planificación de la tarea.';
        }
        field(12; "Planning Quantity"; Decimal)
        {
            Caption = 'Cantidad planificada';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Cantidad de la línea de planificación. Con 0 se planifica cantidad 1.';
        }
    }

    keys
    {
        key(PK; "Job Task No.")
        {
            Clustered = true;
        }
    }

    var
        MobiliarioTok: Label 'Mobiliario', Locked = true;
        MaterialObraTok: Label 'Material Obra', Locked = true;
        DecoracionTok: Label 'Decoración', Locked = true;
        MantenimientoTok: Label 'Mantenimiento', Locked = true;
        ElectrodomesticosTok: Label 'Electrodomésticos', Locked = true;
        MenajeTok: Label 'Menaje', Locked = true;
        OtroTok: Label 'Otro', Locked = true;

    // Alta inicial de la plantilla con las tareas estándar de una propiedad.
    // Solo si la tabla está vacía; después se mantiene desde su página.
    procedure EnsureDefaults()
    begin
        if not Rec.IsEmpty() then
            exit;
        InsertTask('10', MobiliarioTok);
        InsertTask('20', MaterialObraTok);
        InsertTask('30', DecoracionTok);
        InsertTask('40', MantenimientoTok);
        InsertTask('50', ElectrodomesticosTok);
        InsertTask('60', MenajeTok);
        InsertTask('70', OtroTok);
    end;

    local procedure InsertTask(TaskNo: Code[20]; TaskDescription: Text[100])
    begin
        Rec.Init();
        Rec."Job Task No." := TaskNo;
        Rec.Description := TaskDescription;
        Rec.Insert(true);
    end;
}
