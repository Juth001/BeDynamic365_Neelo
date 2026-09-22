namespace BeDynamic.PropertyWizard;

using BeDynamic.PropertyManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;

codeunit 82400 "BeDyn Property Creation"
{
    // Alta completa de una propiedad con un único código:
    //
    //   [País]-[Empresa]-[Tipo]-[Secuencial]     p.ej. ES-01-02-003
    //
    //   · Producto: código de propiedad, descripción = línea de dirección, con
    //     variantes H0 (propiedad completa) y H1..HN (una por habitación).
    //   · Valor de la dimensión de propiedad, asignado como dimensión por defecto
    //     al producto, al proyecto y a la propiedad.
    //   · Proyecto: mismo código y descripción.
    //   · Propiedad del módulo de gestión: mismo código, enlazada al producto y
    //     al proyecto, con una subpropiedad por variante de habitación.
    //
    // El mismo criterio que usa la importación de Airbnb: la propiedad se factura
    // como producto y su código es el valor de dimensión.

    var
        Setup: Record "BeDyn Property Setup";

    procedure CheckSetup()
    var
        Dimension: Record Dimension;
    begin
        Setup.GetSetup();
        Setup.TestField("Property Type Dimension Code");
        Setup.TestField("Property Dimension Code");
        // Si alguna dimensión configurada no existe, error estándar de BC.
        Dimension.Get(Setup."Property Type Dimension Code");
        Dimension.Get(Setup."Property Dimension Code");
    end;

    // Nº de orden del valor dentro de la dimensión de tipos, a 2 cifras.
    // El primer valor (ordenados por código) es siempre 01.
    procedure GetTypeSegment(TypeValueCode: Code[20]): Code[2]
    var
        DimValue: Record "Dimension Value";
        Pos: Integer;
        NotFoundErr: Label 'El valor %1 no existe en la dimensión %2.', Comment = '%1 = valor de dimensión, %2 = dimensión';
    begin
        CheckSetup();
        DimValue.SetRange("Dimension Code", Setup."Property Type Dimension Code");
        if DimValue.FindSet() then
            repeat
                Pos += 1;
                if DimValue.Code = TypeValueCode then
                    exit(CopyStr(Format(100 + Pos), 2, 2));
            until DimValue.Next() = 0;
        Error(NotFoundErr, TypeValueCode, Setup."Property Type Dimension Code");
    end;

    // Siguiente código libre para el prefijo País-Empresa-Tipo: secuencial máximo
    // entre los productos existentes con ese prefijo + 1, saltando códigos ya
    // usados por un producto, un valor de dimensión o un proyecto.
    procedure BuildPropertyCode(CountryCode: Code[2]; CompanyCode: Code[10]; TypeSegment: Code[2]): Code[20]
    var
        Item: Record Item;
        Prefix: Text;
        CandidateCode: Code[20];
        Seq: Integer;
        MaxSeq: Integer;
        ItemSeq: Integer;
        NoFreeErr: Label 'No queda ningún secuencial libre (001-999) para el prefijo %1.', Comment = '%1 = prefijo del código';
    begin
        CheckSetup();
        Prefix := StrSubstNo('%1-%2-%3-', CountryCode, CompanyCode, TypeSegment);
        MaxSeq := 0;
        Item.SetFilter("No.", Prefix + '*');
        if Item.FindSet() then
            repeat
                if Evaluate(ItemSeq, CopyStr(Item."No.", StrLen(Prefix) + 1)) then
                    if ItemSeq > MaxSeq then
                        MaxSeq := ItemSeq;
            until Item.Next() = 0;

        Seq := MaxSeq + 1;
        CandidateCode := CopyStr(Prefix + FormatSeq(Seq), 1, MaxStrLen(CandidateCode));
        while CodeIsUsed(CandidateCode) do begin
            Seq += 1;
            if Seq > 999 then
                Error(NoFreeErr, Prefix);
            CandidateCode := CopyStr(Prefix + FormatSeq(Seq), 1, MaxStrLen(CandidateCode));
        end;
        exit(CandidateCode);
    end;

    /// <summary>
    /// Indica si el código ya está ocupado por un producto, un valor de dimensión,
    /// un proyecto o una propiedad. El asistente lo usa para validar el código que
    /// el usuario escriba a mano en la confirmación.
    /// </summary>
    procedure IsCodeUsed(PropertyCode: Code[20]): Boolean
    begin
        CheckSetup();
        exit(CodeIsUsed(PropertyCode));
    end;

    procedure CreateProperty(PropertyCode: Code[20]; AddressLine: Text[100]; CountryCode: Code[2]; Rooms: Integer; ItemTemplateCode: Code[20]; PropertyTypeCode: Code[20]; OwnerNo: Code[20])
    var
        NoCodeErr: Label 'Indica el código de propiedad.';
        UsedErr: Label 'El código %1 ya está en uso: indica otro o deja el campo vacío para que el asistente proponga uno.', Comment = '%1 = código de propiedad';
    begin
        CheckSetup();
        // Sin código, el Insert del producto tiraría de la serie numérica y las
        // cuatro entidades dejarían de compartir el mismo código.
        if PropertyCode = '' then
            Error(NoCodeErr);
        if CodeIsUsed(PropertyCode) then
            Error(UsedErr, PropertyCode);

        CreateItemWithVariants(PropertyCode, AddressLine, Rooms, ItemTemplateCode);
        EnsurePropertyDimValue(PropertyCode, AddressLine);
        AssignDimensions(Database::Item, PropertyCode, PropertyTypeCode);
        CreateJob(PropertyCode, AddressLine);
        // Las dimensiones por defecto se asignan antes de crear las tareas: al
        // insertarse, cada tarea copia las del proyecto y las heredan sus líneas.
        AssignDimensions(Database::Job, PropertyCode, PropertyTypeCode);
        CreateJobTasks(PropertyCode);
        CreatePropertyRecord(PropertyCode, AddressLine, CountryCode, Rooms, PropertyTypeCode, OwnerNo);
    end;

    // Dimensiones por defecto del maestro: la propiedad recién creada y el tipo
    // de propiedad elegido en el asistente.
    local procedure AssignDimensions(TableID: Integer; PropertyCode: Code[20]; PropertyTypeCode: Code[20])
    begin
        AddDefaultDimension(TableID, PropertyCode, Setup."Property Dimension Code", PropertyCode);
        if PropertyTypeCode <> '' then
            AddDefaultDimension(TableID, PropertyCode, Setup."Property Type Dimension Code", PropertyTypeCode);
    end;

    local procedure CodeIsUsed(PropertyCode: Code[20]): Boolean
    var
        Item: Record Item;
        DimValue: Record "Dimension Value";
        Job: Record Job;
        Property: Record "BeDyn Property";
    begin
        if Item.Get(PropertyCode) then
            exit(true);
        if DimValue.Get(Setup."Property Dimension Code", PropertyCode) then
            exit(true);
        if Property.Get(PropertyCode) then
            exit(true);
        exit(Job.Get(PropertyCode));
    end;

    // 3 cifras con ceros a la izquierda: 1 -> 001.
    local procedure FormatSeq(Seq: Integer): Code[3]
    begin
        exit(CopyStr(Format(1000 + Seq), 2, 3));
    end;

    local procedure CreateItemWithVariants(PropertyCode: Code[20]; AddressLine: Text[100]; Rooms: Integer; ItemTemplateCode: Code[20])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        i: Integer;
        VariantDescLbl: Label '%1 - H%2', Comment = '%1 = dirección, %2 = nº de habitación', Locked = true;
    begin
        Item.Init();
        Item."No." := PropertyCode;
        Item.Insert(true);
        ApplyItemTemplate(Item, ItemTemplateCode);
        Item.Validate(Description, AddressLine);
        Item.Modify(true);

        // H0 = propiedad completa; H1..HN = una por habitación.
        for i := 0 to Rooms do begin
            ItemVariant.Init();
            ItemVariant."Item No." := Item."No.";
            ItemVariant.Code := CopyStr('H' + Format(i), 1, MaxStrLen(ItemVariant.Code));
            ItemVariant.Description := CopyStr(StrSubstNo(VariantDescLbl, AddressLine, i), 1, MaxStrLen(ItemVariant.Description));
            ItemVariant.Insert(true);
        end;
    end;

    // Aplica la plantilla de producto estándar de BC (tipo, unidad de medida,
    // grupos de registro, dimensiones de la plantilla...). Con plantilla vacía,
    // el producto se crea sin esos datos.
    local procedure ApplyItemTemplate(var Item: Record Item; ItemTemplateCode: Code[20])
    var
        ItemTempl: Record "Item Templ.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        if ItemTemplateCode = '' then
            exit;
        ItemTempl.Get(ItemTemplateCode);
        // El tercer parámetro (UpdateExistingValues) tiene que ir a true: con false,
        // ApplyItemTemplate ignora TODOS los campos de tipo enum/opción de la
        // plantilla —entre ellos Tipo—, y el producto se quedaría como Inventario
        // aunque la plantilla sea de Servicio. Es lo que hace el propio estándar en
        // CreateItemFromTemplate al crear un producto nuevo.
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl, true);
        // ApplyItemTemplate modifica y relee el producto; recargar por si acaso.
        Item.Get(Item."No.");
    end;

    /// <summary>
    /// Asigna a cada producto del conjunto filtrado la dimensión de propiedad por
    /// defecto con valor = código del producto, creando el valor de dimensión si
    /// no existe (con la descripción del producto como nombre).
    /// </summary>
    procedure UpdatePropertyDimension(var Item: Record Item) Count: Integer
    var
        Dimension: Record Dimension;
    begin
        Setup.GetSetup();
        Setup.TestField("Property Dimension Code");
        Dimension.Get(Setup."Property Dimension Code");
        if Item.FindSet() then
            repeat
                EnsurePropertyDimValue(Item."No.", Item.Description);
                AddDefaultDimension(Database::Item, Item."No.", Setup."Property Dimension Code", Item."No.");
                Count += 1;
            until Item.Next() = 0;
    end;

    local procedure EnsurePropertyDimValue(PropertyCode: Code[20]; AddressLine: Text[100])
    var
        DimValue: Record "Dimension Value";
    begin
        if DimValue.Get(Setup."Property Dimension Code", PropertyCode) then
            exit;
        DimValue.Init();
        DimValue.Validate("Dimension Code", Setup."Property Dimension Code");
        DimValue.Validate(Code, PropertyCode);
        DimValue.Validate(Name, CopyStr(AddressLine, 1, MaxStrLen(DimValue.Name)));
        DimValue.Insert(true);
    end;

    local procedure AddDefaultDimension(TableID: Integer; No: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        // La plantilla de producto puede haber creado ya la dimensión por defecto
        // (normalmente sin valor): completar el valor en vez de dejarla como está.
        if DefaultDim.Get(TableID, No, DimensionCode) then begin
            if DefaultDim."Dimension Value Code" = DimensionValueCode then
                exit;
            DefaultDim.Validate("Dimension Value Code", DimensionValueCode);
            DefaultDim.Modify(true);
            exit;
        end;
        DefaultDim.Init();
        DefaultDim.Validate("Table ID", TableID);
        DefaultDim.Validate("No.", No);
        DefaultDim.Validate("Dimension Code", DimensionCode);
        DefaultDim.Validate("Dimension Value Code", DimensionValueCode);
        DefaultDim.Insert(true);
    end;

    local procedure CreateJob(PropertyCode: Code[20]; AddressLine: Text[100])
    var
        Job: Record Job;
    begin
        Job.Init();
        Job."No." := PropertyCode;
        Job.Insert(true);
        Job.Validate(Description, AddressLine);
        if Setup."Job Generic Customer No." <> '' then
            Job.Validate("Sell-to Customer No.", Setup."Job Generic Customer No.");
        Job.Modify(true);
    end;

    // Tareas del proyecto según la plantilla configurable y, para las que lo
    // indiquen, su línea de planificación de tipo presupuesto.
    local procedure CreateJobTasks(PropertyCode: Code[20])
    var
        TaskTempl: Record "BeDyn Property Task Template";
        JobTask: Record "Job Task";
    begin
        TaskTempl.EnsureDefaults();
        if not TaskTempl.FindSet() then
            exit;
        repeat
            JobTask.Init();
            JobTask."Job No." := PropertyCode;
            JobTask."Job Task No." := TaskTempl."Job Task No.";
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Validate(Description, TaskTempl.Description);
            JobTask.Insert(true);
            CreatePlanningLine(JobTask, TaskTempl);
        until TaskTempl.Next() = 0;
    end;

    // Ficha de propiedad del módulo de gestión, con el mismo código y enlazada
    // al producto y al proyecto recién creados. El nº se asigna directamente,
    // sin pasar por la serie numérica de propiedades.
    local procedure CreatePropertyRecord(PropertyCode: Code[20]; AddressLine: Text[100]; CountryCode: Code[2]; Rooms: Integer; PropertyTypeCode: Code[20]; OwnerNo: Code[20])
    var
        Property: Record "BeDyn Property";
    begin
        Property.Init();
        Property."No." := PropertyCode;
        Property.Name := AddressLine;
        Property."Owner No." := OwnerNo;
        Property.Address := AddressLine;
        Property."Country/Region Code" := CountryCode;
        Property."Item No." := PropertyCode;
        Property."Job No." := PropertyCode;
        if Rooms > 0 then
            Property."Rental Type" := Property."Rental Type"::"By Room"
        else
            Property."Rental Type" := Property."Rental Type"::"Entire Property";
        // El Insert crea la subpropiedad master si está configurada en el módulo.
        Property.Insert(true);

        AssignDimensions(Database::"BeDyn Property", PropertyCode, PropertyTypeCode);
        LinkMasterRoomVariant(PropertyCode);
        CreatePropertyRooms(PropertyCode, AddressLine, Rooms);
    end;

    // La subpropiedad master representa la propiedad completa: se enlaza a la
    // variante H0 del producto si ambas existen.
    local procedure LinkMasterRoomVariant(PropertyCode: Code[20])
    var
        PropertyMgtSetup: Record "BeDyn Property Mgt. Setup";
        PropertyRoom: Record "BeDyn Property Room";
        ItemVariant: Record "Item Variant";
    begin
        PropertyMgtSetup.GetInstance();
        if PropertyMgtSetup."Master Room Code" = '' then
            exit;
        if not PropertyRoom.Get(PropertyCode, PropertyMgtSetup."Master Room Code") then
            exit;
        if not ItemVariant.Get(PropertyCode, 'H' + Format(0)) then
            exit;
        PropertyRoom.Validate("Variant Code", ItemVariant.Code);
        PropertyRoom.Modify(true);
    end;

    // Una subpropiedad por habitación (H1..HN), enlazada a su variante.
    local procedure CreatePropertyRooms(PropertyCode: Code[20]; AddressLine: Text[100]; Rooms: Integer)
    var
        PropertyRoom: Record "BeDyn Property Room";
        i: Integer;
        RoomDescLbl: Label '%1 - H%2', Comment = '%1 = dirección, %2 = nº de habitación', Locked = true;
    begin
        for i := 1 to Rooms do begin
            PropertyRoom.Init();
            PropertyRoom."Property No." := PropertyCode;
            PropertyRoom."Room No." := CopyStr('H' + Format(i), 1, MaxStrLen(PropertyRoom."Room No."));
            PropertyRoom.Description := CopyStr(StrSubstNo(RoomDescLbl, AddressLine, i), 1, MaxStrLen(PropertyRoom.Description));
            PropertyRoom.Insert(true);
            PropertyRoom.Validate("Variant Code", CopyStr('H' + Format(i), 1, MaxStrLen(PropertyRoom."Variant Code")));
            PropertyRoom.Modify(true);
        end;
    end;

    local procedure CreatePlanningLine(JobTask: Record "Job Task"; TaskTempl: Record "BeDyn Property Task Template")
    var
        JobPlanningLine: Record "Job Planning Line";
        PlanningQty: Decimal;
    begin
        if (TaskTempl."Planning Type" = TaskTempl."Planning Type"::" ") or (TaskTempl."Planning No." = '') then
            exit;

        JobPlanningLine.Init();
        JobPlanningLine."Job No." := JobTask."Job No.";
        JobPlanningLine."Job Task No." := JobTask."Job Task No.";
        JobPlanningLine."Line No." := 10000;
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);
        JobPlanningLine.Validate("Planning Date", WorkDate());
        case TaskTempl."Planning Type" of
            TaskTempl."Planning Type"::"G/L Account":
                JobPlanningLine.Validate(Type, JobPlanningLine.Type::"G/L Account");
            TaskTempl."Planning Type"::Item:
                JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
            TaskTempl."Planning Type"::Resource:
                JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
        end;
        JobPlanningLine.Validate("No.", TaskTempl."Planning No.");
        PlanningQty := TaskTempl."Planning Quantity";
        if PlanningQty = 0 then
            PlanningQty := 1;
        JobPlanningLine.Validate(Quantity, PlanningQty);
        JobPlanningLine.Modify(true);
    end;
}
