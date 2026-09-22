namespace BeDynamic.PropertyManagement;

using BeDynamic.PropertyWizard;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using System.Security.User;
using System.Utilities;

codeunit 82507 "BeDyn Property Code Sync"
{
    // Numeración enlazada de los cuatro maestros de una propiedad —producto,
    // valor de dimensión, proyecto y propiedad—, que comparten código desde que
    // los crea el asistente.
    //
    // Al renombrar cualquiera de los cuatro se propaga el cambio a los otros
    // tres, previa confirmación y comprobando que el usuario puede renumerar. La
    // propagación usa el Rename de cada tabla, así que es el propio estándar el
    // que arrastra movimientos, documentos y dimensiones. Si alguno de los
    // renombrados no pasa sus validaciones, el error deshace toda la operación y
    // los cuatro maestros se quedan como estaban.
    //
    // La cascada es recursiva por diseño: renombrar el proyecto vuelve a entrar
    // aquí y renombra el valor de dimensión, y así hasta que ningún maestro
    // conserva el código antiguo. Cada uno se renombra una sola vez porque solo
    // se toca el que todavía responde al código antiguo, y por eso la recursión
    // termina sola sin necesidad de banderas de reentrada.

    SingleInstance = true;

    var
        // Par de códigos ya confirmado, para no repetir la pregunta ni la
        // comprobación de permisos en cada renombrado de la cascada. Se limpia al
        // cerrarse la cascada, de forma que un cambio posterior con el mismo par
        // vuelve a pedir permiso y confirmación.
        ConfirmedFromCode: Code[20];
        ConfirmedToCode: Code[20];
        // Nivel de anidamiento de la cascada: solo el nivel exterior da por
        // terminada la operación y limpia el par confirmado.
        CascadeDepth: Integer;

    // ---------------------------------------------------------------- Producto

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnBeforeRenameEvent', '', false, false)]
    local procedure ItemOnBeforeRename(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        CheckRenameAllowed(xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterRenameEvent', '', false, false)]
    local procedure ItemOnAfterRename(var Rec: Record Item; var xRec: Record Item; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        SyncFromRename(xRec."No.", Rec."No.");
    end;

    // ------------------------------------------------------ Valor de dimensión

    [EventSubscriber(ObjectType::Table, Database::"Dimension Value", 'OnBeforeRenameEvent', '', false, false)]
    local procedure DimValueOnBeforeRename(var Rec: Record "Dimension Value"; var xRec: Record "Dimension Value"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if not IsPropertyDimension(xRec."Dimension Code") then
            exit;
        CheckRenameAllowed(xRec.Code, Rec.Code);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Dimension Value", 'OnAfterRenameEvent', '', false, false)]
    local procedure DimValueOnAfterRename(var Rec: Record "Dimension Value"; var xRec: Record "Dimension Value"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if not IsPropertyDimension(Rec."Dimension Code") then
            exit;
        if not AlreadyConfirmed(xRec.Code, Rec.Code) then
            exit;
        UpdateDefaultDimensions(Rec."Dimension Code", xRec.Code, Rec.Code);
        SyncFromRename(xRec.Code, Rec.Code);
    end;

    // ---------------------------------------------------------------- Proyecto

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnBeforeRenameEvent', '', false, false)]
    local procedure JobOnBeforeRename(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        CheckRenameAllowed(xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::Job, 'OnAfterRenameEvent', '', false, false)]
    local procedure JobOnAfterRename(var Rec: Record Job; var xRec: Record Job; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        SyncFromRename(xRec."No.", Rec."No.");
    end;

    // -------------------------------------------------------------- Propiedad

    [EventSubscriber(ObjectType::Table, Database::"BeDyn Property", 'OnBeforeRenameEvent', '', false, false)]
    local procedure PropertyOnBeforeRename(var Rec: Record "BeDyn Property"; var xRec: Record "BeDyn Property"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        CheckRenameAllowed(xRec."No.", Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"BeDyn Property", 'OnAfterRenameEvent', '', false, false)]
    local procedure PropertyOnAfterRename(var Rec: Record "BeDyn Property"; var xRec: Record "BeDyn Property"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        SyncFromRename(xRec."No.", Rec."No.");
    end;

    // ------------------------------------------------------ Permiso y aviso

    // Se ejecuta antes de cada renombrado: decide si el código está enlazado y,
    // si lo está, exige permiso y confirmación antes de dejar seguir.
    local procedure CheckRenameAllowed(FromCode: Code[20]; ToCode: Code[20])
    begin
        if FromCode = ToCode then
            exit;
        // Renombrado encadenado de una cascada ya confirmada.
        if AlreadyConfirmed(FromCode, ToCode) then
            exit;
        if not LinkingEnabled() then
            exit;
        // Un producto, un proyecto o un valor de dimensión que no pertenezca a
        // ninguna propiedad se renombra como siempre, sin preguntar nada.
        if not IsLinkedCode(FromCode) then
            exit;

        CheckUserCanRenumber();
        CheckTargetCodeFree(ToCode);
        ConfirmRename(FromCode, ToCode);

        ConfirmedFromCode := FromCode;
        ConfirmedToCode := ToCode;
        // Arranca una cascada nueva: si la anterior murió a medias por un error,
        // su contador se descarta aquí.
        CascadeDepth := 0;
    end;

    local procedure AlreadyConfirmed(FromCode: Code[20]; ToCode: Code[20]): Boolean
    begin
        exit((FromCode = ConfirmedFromCode) and (ToCode = ConfirmedToCode) and (ConfirmedFromCode <> ''));
    end;

    local procedure CheckUserCanRenumber()
    var
        UserSetup: Record "User Setup";
        NotAllowedErr: Label 'Tus permisos no te permiten cambiar el código de una propiedad. Para poder hacerlo hay que marcar "%1" en la ficha del usuario %2 de la configuración de usuarios.', Comment = '%1 = título del campo, %2 = id de usuario';
    begin
        if UserSetup.Get(UserId()) then
            if UserSetup."BeDyn Renumber Properties" then
                exit;
        Error(NotAllowedErr, UserSetup.FieldCaption("BeDyn Renumber Properties"), UserId());
    end;

    // El código nuevo tiene que estar libre en los cuatro maestros: si no, el
    // renombrado fallaría a mitad de la cascada con un error del sistema.
    local procedure CheckTargetCodeFree(ToCode: Code[20])
    var
        Item: Record Item;
        Job: Record Job;
        DimValue: Record "Dimension Value";
        Property: Record "BeDyn Property";
        DimensionCode: Code[20];
        TakenErr: Label 'No se puede usar el código %1: ya lo tiene otro registro de %2. Los cuatro maestros de una propiedad comparten código, así que el nuevo tiene que estar libre en todos.', Comment = '%1 = código nuevo, %2 = maestro que ya lo usa';
    begin
        if Item.Get(ToCode) then
            Error(TakenErr, ToCode, Item.TableCaption());
        DimensionCode := PropertyDimensionCode();
        if (DimensionCode <> '') and DimValue.Get(DimensionCode, ToCode) then
            Error(TakenErr, ToCode, DimValue.TableCaption());
        if Job.Get(ToCode) then
            Error(TakenErr, ToCode, Job.TableCaption());
        if Property.Get(ToCode) then
            Error(TakenErr, ToCode, Property.TableCaption());
    end;

    local procedure ConfirmRename(FromCode: Code[20]; ToCode: Code[20])
    var
        ConfirmManagement: Codeunit "Confirm Management";
        RenameQst: Label 'Se va a cambiar el código %1 por %2 en: %3.\\El cambio arrastra los movimientos y documentos asociados.\\¿Continuar?', Comment = '%1 = código actual, %2 = código nuevo, %3 = maestros afectados';
    begin
        // Sin interfaz (servicio web, tarea programada) no hay a quién preguntar:
        // se sigue adelante para no dejar los maestros descuadrados.
        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(RenameQst, FromCode, ToCode, AffectedMastersText(FromCode)), true) then
            exit;
        // Error sin texto: cancela y deshace sin mostrar un cuadro de error.
        Error('');
    end;

    local procedure AffectedMastersText(PropertyCode: Code[20]): Text
    var
        Item: Record Item;
        Job: Record Job;
        DimValue: Record "Dimension Value";
        Property: Record "BeDyn Property";
        Masters: List of [Text];
        DimensionCode: Code[20];
        ItemLbl: Label 'el producto';
        JobLbl: Label 'el proyecto';
        PropertyLbl: Label 'la propiedad';
        DimValueLbl: Label 'el valor de la dimensión %1', Comment = '%1 = código de dimensión';
    begin
        if Item.Get(PropertyCode) then
            Masters.Add(ItemLbl);
        DimensionCode := PropertyDimensionCode();
        if (DimensionCode <> '') and DimValue.Get(DimensionCode, PropertyCode) then
            Masters.Add(StrSubstNo(DimValueLbl, DimensionCode));
        if Job.Get(PropertyCode) then
            Masters.Add(JobLbl);
        if Property.Get(PropertyCode) then
            Masters.Add(PropertyLbl);
        exit(JoinMasters(Masters));
    end;

    local procedure JoinMasters(Masters: List of [Text]) Result: Text
    var
        i: Integer;
        SeparatorTok: Label ', ', Locked = true;
        LastSeparatorTok: Label ' y ', Locked = true;
    begin
        for i := 1 to Masters.Count do begin
            if i > 1 then
                if i = Masters.Count then
                    Result += LastSeparatorTok
                else
                    Result += SeparatorTok;
            Result += Masters.Get(i);
        end;
    end;

    // ------------------------------------------------------------ Propagación

    // Se ejecuta después de cada renombrado. Solo propaga el par que se confirmó
    // en CheckRenameAllowed: cualquier otro renombrado pasa de largo.
    local procedure SyncFromRename(FromCode: Code[20]; ToCode: Code[20])
    begin
        if FromCode = ToCode then
            exit;
        if not LinkingEnabled() then
            exit;
        if not AlreadyConfirmed(FromCode, ToCode) then
            exit;

        CascadeDepth += 1;
        SyncOtherMasters(FromCode, ToCode);
        CascadeDepth -= 1;
        // Cerrado el nivel exterior, la operación termina: se olvida el par para
        // que un cambio posterior de los mismos códigos vuelva a preguntar.
        if CascadeDepth <= 0 then begin
            ConfirmedFromCode := '';
            ConfirmedToCode := '';
        end;
    end;

    local procedure SyncOtherMasters(FromCode: Code[20]; ToCode: Code[20])
    var
        Item: Record Item;
        Job: Record Job;
        DimValue: Record "Dimension Value";
        Property: Record "BeDyn Property";
        DimensionCode: Code[20];
    begin
        // Cada Rename vuelve a entrar en este codeunit y continúa la cascada, así
        // que solo se toca el maestro que todavía responde al código antiguo.
        if Item.Get(FromCode) then
            Item.Rename(ToCode);
        DimensionCode := PropertyDimensionCode();
        if (DimensionCode <> '') and DimValue.Get(DimensionCode, FromCode) then
            DimValue.Rename(DimensionCode, ToCode);
        if Job.Get(FromCode) then
            Job.Rename(ToCode);
        if Property.Get(FromCode) then
            Property.Rename(ToCode);

        RelinkProperty(FromCode, ToCode);
    end;

    // El producto y el proyecto de la ficha de propiedad los arrastra la relación
    // de tabla al renombrar; si algún enlace se hubiera quedado en el código
    // antiguo se corrige aquí. Asignación directa a propósito: el OnValidate de
    // "Nº producto" rechaza el cambio cuando hay subpropiedades con variante.
    local procedure RelinkProperty(FromCode: Code[20]; ToCode: Code[20])
    var
        Property: Record "BeDyn Property";
    begin
        if not Property.Get(ToCode) then
            exit;
        if (Property."Item No." <> FromCode) and (Property."Job No." <> FromCode) then
            exit;
        if Property."Item No." = FromCode then
            Property."Item No." := ToCode;
        if Property."Job No." = FromCode then
            Property."Job No." := ToCode;
        Property.Modify();
    end;

    // Las dimensiones por defecto del producto, el proyecto y la propiedad
    // apuntan al valor por su código: si el renombrado del valor no las ha
    // arrastrado, se corrigen aquí para no dejarlas colgando.
    local procedure UpdateDefaultDimensions(DimensionCode: Code[20]; FromCode: Code[20]; ToCode: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        DefaultDim.SetRange("Dimension Code", DimensionCode);
        DefaultDim.SetRange("Dimension Value Code", FromCode);
        if not DefaultDim.IsEmpty() then
            DefaultDim.ModifyAll("Dimension Value Code", ToCode);
    end;

    // ------------------------------------------------------------- Auxiliares

    local procedure LinkingEnabled(): Boolean
    var
        MgtSetup: Record "BeDyn Property Mgt. Setup";
    begin
        if not MgtSetup.Get() then
            exit(false);
        exit(MgtSetup."Link Property Codes");
    end;

    // La propiedad es el maestro que ancla el grupo: sin ficha de propiedad con
    // ese código, no hay nada que enlazar.
    local procedure IsLinkedCode(PropertyCode: Code[20]): Boolean
    var
        Property: Record "BeDyn Property";
    begin
        if PropertyCode = '' then
            exit(false);
        exit(Property.Get(PropertyCode));
    end;

    local procedure IsPropertyDimension(DimensionCode: Code[20]): Boolean
    var
        PropertyDimension: Code[20];
    begin
        PropertyDimension := PropertyDimensionCode();
        exit((PropertyDimension <> '') and (PropertyDimension = DimensionCode));
    end;

    // Se lee sin GetSetup() a propósito: un renombrado no debe crear registros de
    // configuración por el camino.
    local procedure PropertyDimensionCode(): Code[20]
    var
        WizardSetup: Record "BeDyn Property Setup";
    begin
        if not WizardSetup.Get() then
            exit('');
        exit(WizardSetup."Property Dimension Code");
    end;
}
