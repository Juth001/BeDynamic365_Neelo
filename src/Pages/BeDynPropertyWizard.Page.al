namespace BeDynamic.PropertyWizard;

using BeDynamic.PropertyManagement;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;

page 82402 "BeDyn Property Wizard"
{
    Caption = 'Asistente creación de propiedades';
    PageType = NavigatePage;
    UsageCategory = Tasks;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(StepAddress)
            {
                Caption = 'Paso 1: Dirección de la propiedad';
                Visible = AddressVisible;
                group(AddressInstruction)
                {
                    ShowCaption = false;
                    InstructionalText = 'La línea de dirección (calle y número, sin código postal ni población) será la descripción del producto, del valor de dimensión, del proyecto y de la propiedad.';
                }
                field(AddressLineCtrl; AddressLine)
                {
                    Caption = 'Dirección (calle y número)';
                    ApplicationArea = All;
                    ToolTip = 'Línea de dirección de la propiedad, sin código postal ni otros detalles.';
                }
                field(CountryCodeCtrl; CountryCode)
                {
                    Caption = 'País (2 letras)';
                    ApplicationArea = All;
                    ToolTip = 'Código de país de 2 letras (ES, PT, FR...). Es el primer segmento del código de propiedad.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CountryRegion: Record "Country/Region";
                    begin
                        if Page.RunModal(0, CountryRegion) <> Action::LookupOK then
                            exit(false);
                        Text := CountryRegion.Code;
                        exit(true);
                    end;
                }
                field(OwnerNoCtrl; OwnerNo)
                {
                    Caption = 'Propietario';
                    ApplicationArea = All;
                    ToolTip = 'Propietario de la propiedad. Se asigna a la ficha de propiedad que crea el asistente.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PropertyOwner: Record "BeDyn Property Owner";
                    begin
                        if Page.RunModal(0, PropertyOwner) <> Action::LookupOK then
                            exit(false);
                        // Asignar aquí también el nombre: al elegir por lookup la
                        // plataforma no dispara el OnValidate del control.
                        OwnerNo := PropertyOwner."No.";
                        OwnerName := PropertyOwner.Name;
                        Text := PropertyOwner."No.";
                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        PropertyOwner: Record "BeDyn Property Owner";
                    begin
                        OwnerName := '';
                        if OwnerNo = '' then
                            exit;
                        PropertyOwner.Get(OwnerNo);
                        OwnerName := PropertyOwner.Name;
                    end;
                }
                field(OwnerNameCtrl; OwnerName)
                {
                    Caption = 'Nombre propietario';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Nombre del propietario seleccionado.';
                }
            }
            group(StepCompany)
            {
                Caption = 'Paso 2: Empresa gestora';
                Visible = CompanyVisible;
                field(CompanyCodeCtrl; CompanyCode)
                {
                    Caption = 'Empresa gestora';
                    ApplicationArea = All;
                    ToolTip = 'Empresa que gestiona la propiedad (p.ej. 01 Tepoz, 02 Erasmus). Es el segundo segmento del código de propiedad.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        MgtCompany: Record "BeDyn Property Mgt. Company";
                    begin
                        MgtCompany.EnsureDefaults();
                        if Page.RunModal(0, MgtCompany) <> Action::LookupOK then
                            exit(false);
                        // Asignar aquí también el nombre: al elegir por lookup la
                        // plataforma no dispara el OnValidate del control.
                        CompanyCode := MgtCompany.Code;
                        CompanyName := MgtCompany.Name;
                        Text := MgtCompany.Code;
                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        MgtCompany: Record "BeDyn Property Mgt. Company";
                    begin
                        CompanyName := '';
                        if CompanyCode = '' then
                            exit;
                        MgtCompany.Get(CompanyCode);
                        CompanyName := MgtCompany.Name;
                    end;
                }
                field(CompanyNameCtrl; CompanyName)
                {
                    Caption = 'Nombre';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Nombre de la empresa gestora seleccionada.';
                }
            }
            group(StepType)
            {
                Caption = 'Paso 3: Tipo de propiedad';
                Visible = TypeVisible;
                field(PropertyTypeCtrl; PropertyTypeCode)
                {
                    Caption = 'Tipo de propiedad';
                    ApplicationArea = All;
                    ToolTip = 'Valor de la dimensión de tipos de propiedad. Su nº de orden dentro de la dimensión (el primero siempre es 01) es el tercer segmento del código.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                    begin
                        DimValue.SetRange("Dimension Code", Setup."Property Type Dimension Code");
                        if Page.RunModal(0, DimValue) <> Action::LookupOK then
                            exit(false);
                        // Asignar aquí también los campos calculados: al elegir por lookup
                        // la plataforma no dispara el OnValidate del control.
                        PropertyTypeCode := DimValue.Code;
                        TypeName := DimValueDisplayName(DimValue);
                        TypeSegment := Creation.GetTypeSegment(PropertyTypeCode);
                        Text := DimValue.Code;
                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        DimValue: Record "Dimension Value";
                    begin
                        TypeName := '';
                        TypeSegment := '';
                        if PropertyTypeCode = '' then
                            exit;
                        DimValue.Get(Setup."Property Type Dimension Code", PropertyTypeCode);
                        TypeName := DimValueDisplayName(DimValue);
                        TypeSegment := Creation.GetTypeSegment(PropertyTypeCode);
                    end;
                }
                field(TypeNameCtrl; TypeName)
                {
                    Caption = 'Nombre';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Nombre del tipo de propiedad seleccionado.';
                }
                field(TypeSegmentCtrl; TypeSegment)
                {
                    Caption = 'Segmento del código';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Nº de orden del tipo dentro de la dimensión, a 2 cifras: el primer valor siempre es 01.';
                }
            }
            group(StepRooms)
            {
                Caption = 'Paso 4: Habitaciones';
                Visible = RoomsVisible;
                group(RoomsInstruction)
                {
                    ShowCaption = false;
                    InstructionalText = 'Se creará la variante H0 para la propiedad completa y una variante por habitación (H1, H2...). Con 0 habitaciones (estudio) solo se crea H0. En la ficha de propiedad se crea además una subpropiedad por habitación, enlazada a su variante.';
                }
                field(RoomsCtrl; Rooms)
                {
                    Caption = 'Nº de habitaciones';
                    ApplicationArea = All;
                    MinValue = 0;
                    ToolTip = 'Número de habitaciones de la propiedad. Determina cuántas variantes se crean además de H0.';
                }
            }
            group(StepTemplate)
            {
                Caption = 'Paso 5: Plantilla de producto';
                Visible = TemplateVisible;
                group(TemplateInstruction)
                {
                    ShowCaption = false;
                    InstructionalText = 'Selecciona la plantilla con la que se creará el producto de la propiedad. Se propone la de la configuración; si se deja vacía, el producto se crea sin datos de registro y habrá que completarlos a mano.';
                }
                field(TemplateCodeCtrl; TemplateCode)
                {
                    Caption = 'Plantilla de producto';
                    ApplicationArea = All;
                    ToolTip = 'Plantilla de producto que se aplica al crear el producto: aporta tipo, unidad de medida y grupos de registro.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemTempl: Record "Item Templ.";
                    begin
                        if Page.RunModal(0, ItemTempl) <> Action::LookupOK then
                            exit(false);
                        // Asignar aquí también la descripción: al elegir por lookup la
                        // plataforma no dispara el OnValidate del control.
                        TemplateCode := ItemTempl.Code;
                        TemplateDesc := ItemTempl.Description;
                        Text := ItemTempl.Code;
                        exit(true);
                    end;

                    trigger OnValidate()
                    var
                        ItemTempl: Record "Item Templ.";
                    begin
                        TemplateDesc := '';
                        if TemplateCode = '' then
                            exit;
                        ItemTempl.Get(TemplateCode);
                        TemplateDesc := ItemTempl.Description;
                    end;
                }
                field(TemplateDescCtrl; TemplateDesc)
                {
                    Caption = 'Descripción';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Descripción de la plantilla seleccionada.';
                }
            }
            group(StepConfirm)
            {
                Caption = 'Paso 6: Confirmación';
                Visible = ConfirmVisible;
                group(ConfirmInstruction)
                {
                    ShowCaption = false;
                    InstructionalText = 'Revisa los datos. El código propuesto se puede cambiar por el que quieras: déjalo vacío para que el asistente vuelva a proponer el automático. Al pulsar Crear se crearán el producto con sus variantes, el valor de dimensión, el proyecto y la ficha de propiedad con sus subpropiedades, todos con el mismo código.';
                }
                field(FinalCodeCtrl; PropertyCode)
                {
                    Caption = 'Código de propiedad';
                    ApplicationArea = All;
                    Style = Strong;
                    ToolTip = 'Código con el que se crearán el producto, el valor de dimensión, el proyecto y la ficha de propiedad. El asistente propone el siguiente libre según los datos introducidos, pero puedes escribir el que quieras. Si lo dejas vacío, se vuelve a proponer el automático.';

                    trigger OnValidate()
                    var
                        UsedErr: Label 'El código %1 ya está en uso por un producto, un valor de dimensión, un proyecto o una propiedad. Indica otro o deja el campo vacío para que el asistente proponga uno.', Comment = '%1 = código de propiedad';
                    begin
                        PropertyCode := CopyStr(DelChr(PropertyCode, '<>'), 1, MaxStrLen(PropertyCode));
                        // Vaciar el campo devuelve el código propuesto automáticamente.
                        if PropertyCode = '' then begin
                            ProposeCode();
                            exit;
                        end;
                        if Creation.IsCodeUsed(PropertyCode) then
                            Error(UsedErr, PropertyCode);
                        // A partir de aquí el código es cosa del usuario: no se
                        // recalcula aunque se vuelva a pasar por la confirmación.
                        CodeIsManual := true;
                    end;
                }
                field(SummaryAddressCtrl; AddressLine)
                {
                    Caption = 'Dirección';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Descripción que llevarán las tres entidades.';
                }
                field(SummaryOwnerCtrl; OwnerName)
                {
                    Caption = 'Propietario';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Propietario de la ficha de propiedad.';
                }
                field(SummaryCompanyCtrl; CompanyName)
                {
                    Caption = 'Empresa gestora';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Empresa gestora de la propiedad.';
                }
                field(SummaryTypeCtrl; TypeName)
                {
                    Caption = 'Tipo de propiedad';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Tipo de propiedad elegido.';
                }
                field(SummaryVariantsCtrl; VariantsText)
                {
                    Caption = 'Variantes';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Variantes del producto que se van a crear.';
                }
                field(SummaryTemplateCtrl; TemplateText)
                {
                    Caption = 'Plantilla de producto';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Plantilla que se aplicará al producto.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                Caption = 'Atrás';
                ApplicationArea = All;
                Enabled = BackEnabled;
                InFooterBar = true;
                Image = PreviousRecord;
                ToolTip = 'Vuelve al paso anterior.';

                trigger OnAction()
                begin
                    TakeStep(-1);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Siguiente';
                ApplicationArea = All;
                Enabled = NextEnabled;
                InFooterBar = true;
                Image = NextRecord;
                ToolTip = 'Pasa al paso siguiente.';

                trigger OnAction()
                begin
                    TakeStep(1);
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Crear';
                ApplicationArea = All;
                Enabled = FinishEnabled;
                InFooterBar = true;
                Image = Approve;
                ToolTip = 'Crea el producto con sus variantes, el valor de dimensión, el proyecto y la ficha de propiedad con sus subpropiedades.';

                trigger OnAction()
                begin
                    FinishWizard();
                end;
            }
        }
    }

    var
        Setup: Record "BeDyn Property Setup";
        Creation: Codeunit "BeDyn Property Creation";
        Step: Integer;
        AddressVisible: Boolean;
        CompanyVisible: Boolean;
        TypeVisible: Boolean;
        RoomsVisible: Boolean;
        TemplateVisible: Boolean;
        ConfirmVisible: Boolean;
        BackEnabled: Boolean;
        NextEnabled: Boolean;
        FinishEnabled: Boolean;
        AddressLine: Text[100];
        CountryCode: Code[2];
        CompanyCode: Code[10];
        CompanyName: Text[100];
        PropertyTypeCode: Code[20];
        TypeName: Text[50];
        TypeSegment: Code[2];
        Rooms: Integer;
        TemplateCode: Code[20];
        TemplateDesc: Text[100];
        TemplateText: Text;
        PropertyCode: Code[20];
        CodeIsManual: Boolean;
        VariantsText: Text;
        OwnerNo: Code[20];
        OwnerName: Text[100];

    trigger OnOpenPage()
    var
        MgtCompany: Record "BeDyn Property Mgt. Company";
        ItemTempl: Record "Item Templ.";
    begin
        Setup.GetSetup();
        Creation.CheckSetup();
        MgtCompany.EnsureDefaults();
        // Proponer la plantilla de producto de la configuración; el paso 5 permite cambiarla.
        TemplateCode := Setup."Item Template Code";
        if (TemplateCode <> '') and ItemTempl.Get(TemplateCode) then
            TemplateDesc := ItemTempl.Description
        else
            TemplateCode := '';
        SetStep(1);
    end;

    local procedure TakeStep(Direction: Integer)
    begin
        if Direction > 0 then
            case Step of
                1:
                    CheckStepAddress();
                2:
                    CheckStepCompany();
                3:
                    CheckStepType();
                5:
                    PrepareConfirm();
            end;
        SetStep(Step + Direction);
    end;

    local procedure SetStep(NewStep: Integer)
    begin
        Step := NewStep;
        AddressVisible := Step = 1;
        CompanyVisible := Step = 2;
        TypeVisible := Step = 3;
        RoomsVisible := Step = 4;
        TemplateVisible := Step = 5;
        ConfirmVisible := Step = 6;
        BackEnabled := Step > 1;
        NextEnabled := Step < 6;
        FinishEnabled := Step = 6;
    end;

    local procedure CheckStepAddress()
    var
        PropertyOwner: Record "BeDyn Property Owner";
        i: Integer;
        NoAddressErr: Label 'Indica la dirección (calle y número).';
        BadCountryErr: Label 'El país debe ser un código de 2 letras (p.ej. ES).';
        NoOwnerErr: Label 'Selecciona el propietario de la propiedad.';
    begin
        AddressLine := CopyStr(DelChr(AddressLine, '<>'), 1, MaxStrLen(AddressLine));
        if AddressLine = '' then
            Error(NoAddressErr);
        if StrLen(CountryCode) <> 2 then
            Error(BadCountryErr);
        for i := 1 to 2 do
            if not (CountryCode[i] in ['A' .. 'Z']) then
                Error(BadCountryErr);
        if OwnerNo = '' then
            Error(NoOwnerErr);
        PropertyOwner.Get(OwnerNo);
        OwnerName := PropertyOwner.Name;
    end;

    local procedure CheckStepCompany()
    var
        MgtCompany: Record "BeDyn Property Mgt. Company";
        NoCompanyErr: Label 'Selecciona la empresa gestora.';
    begin
        if CompanyCode = '' then
            Error(NoCompanyErr);
        MgtCompany.Get(CompanyCode);
        CompanyName := MgtCompany.Name;
    end;

    local procedure CheckStepType()
    var
        DimValue: Record "Dimension Value";
        NoTypeErr: Label 'Selecciona el tipo de propiedad.';
    begin
        if PropertyTypeCode = '' then
            Error(NoTypeErr);
        // Recalcular nombre y segmento aquí garantiza que llegan a la confirmación
        // aunque el código no haya pasado por el OnValidate ni por el lookup.
        DimValue.Get(Setup."Property Type Dimension Code", PropertyTypeCode);
        TypeName := DimValueDisplayName(DimValue);
        TypeSegment := Creation.GetTypeSegment(PropertyTypeCode);
    end;

    // Nombre a mostrar de un valor de dimensión: su nombre o, si está vacío, el código.
    local procedure DimValueDisplayName(DimValue: Record "Dimension Value"): Text[50]
    begin
        if DimValue.Name <> '' then
            exit(DimValue.Name);
        exit(CopyStr(DimValue.Code, 1, 50));
    end;

    local procedure PrepareConfirm()
    var
        ItemTempl: Record "Item Templ.";
        OneVariantLbl: Label 'H0 (1 variante: propiedad completa)';
        VariantsLbl: Label 'H0 - H%1 (%2 variantes)', Comment = '%1 = última habitación, %2 = total de variantes';
        NoTemplateLbl: Label '(sin plantilla: completar los datos de registro a mano)';
        TemplateLbl: Label '%1 %2', Comment = '%1 = código plantilla, %2 = descripción', Locked = true;
    begin
        if TemplateCode <> '' then begin
            ItemTempl.Get(TemplateCode);
            TemplateDesc := ItemTempl.Description;
            TemplateText := DelChr(StrSubstNo(TemplateLbl, TemplateCode, TemplateDesc), '>');
        end else
            TemplateText := NoTemplateLbl;

        // El código escrito a mano manda: solo se recalcula la propuesta mientras
        // el usuario no lo haya tocado.
        if not CodeIsManual then
            ProposeCode();

        if Rooms = 0 then
            VariantsText := OneVariantLbl
        else
            VariantsText := StrSubstNo(VariantsLbl, Rooms, Rooms + 1);
    end;

    // Siguiente código libre según país, empresa gestora y tipo elegidos.
    local procedure ProposeCode()
    begin
        CodeIsManual := false;
        PropertyCode := Creation.BuildPropertyCode(CountryCode, CompanyCode, TypeSegment);
    end;

    local procedure FinishWizard()
    var
        Property: Record "BeDyn Property";
        DoneMsg: Label 'Propiedad %1 creada: producto con %2 variantes, valor de dimensión, proyecto y ficha de propiedad.', Comment = '%1 = código de propiedad, %2 = nº de variantes';
    begin
        Creation.CreateProperty(PropertyCode, AddressLine, CountryCode, Rooms, TemplateCode, PropertyTypeCode, OwnerNo);
        Message(DoneMsg, PropertyCode, Rooms + 1);
        CurrPage.Close();
        if Property.Get(PropertyCode) then
            Page.Run(Page::"BeDyn Property Card", Property);
    end;
}
