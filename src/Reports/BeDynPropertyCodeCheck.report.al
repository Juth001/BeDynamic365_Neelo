namespace BeDynamic.PropertyManagement;

using BeDynamic.PropertyWizard;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;

report 82502 "BeDyn Property Code Check"
{
    // Compara los cuatro maestros que comparten código en cada propiedad
    // —producto, valor de dimensión, proyecto y propiedad— y señala los que
    // faltan o han dejado de coincidir. Al final lista los valores de la
    // dimensión de propiedad que ya no tienen ficha de propiedad.

    Caption = 'Comparación maestros de propiedad';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;

    dataset
    {
        dataitem(Property; "BeDyn Property")
        {
            RequestFilterFields = "No.", "Owner No.";

            column(SummaryText; SummaryText)
            {
            }
            column(PropertyDimensionCode; PropertyDimension)
            {
            }
            column(PropertyNo; "No.")
            {
            }
            column(PropertyName; Name)
            {
            }
            column(ItemText; ItemText)
            {
            }
            column(DimValueText; DimValueText)
            {
            }
            column(JobText; JobText)
            {
            }
            column(LinkText; LinkText)
            {
            }
            column(StatusText; StatusText)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if EvaluateProperty(Property) then begin
                    StatusText := AlignedLbl;
                    if ShowOnlyDifferences then
                        CurrReport.Skip();
                end else
                    StatusText := BrokenLbl;
            end;
        }
        dataitem(OrphanDimValue; "Dimension Value")
        {
            DataItemTableView = sorting("Dimension Code", Code);

            column(OrphanCode; Code)
            {
            }
            column(OrphanName; Name)
            {
            }

            trigger OnPreDataItem()
            begin
                if PropertyDimension = '' then
                    CurrReport.Break();
                SetRange("Dimension Code", PropertyDimension);
            end;

            trigger OnAfterGetRecord()
            var
                PropertyRec: Record "BeDyn Property";
            begin
                if PropertyRec.Get(Code) then
                    CurrReport.Skip();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Opciones';

                    field(ShowOnlyDifferencesCtrl; ShowOnlyDifferences)
                    {
                        Caption = 'Solo diferencias';
                        ApplicationArea = All;
                        ToolTip = 'Deja fuera del listado las propiedades cuyos cuatro maestros coinciden. Con esta opción, un informe sin propiedades significa que está todo correcto.';
                    }
                }
            }
        }
    }

    var
        PropertyDimension: Code[20];
        ShowOnlyDifferences: Boolean;
        ItemText: Text;
        DimValueText: Text;
        JobText: Text;
        LinkText: Text;
        StatusText: Text;
        SummaryText: Text;
        FoundLbl: Label 'Existe';
        MissingLbl: Label 'NO EXISTE';
        NoDimensionLbl: Label 'Dimensión sin configurar';
        AlignedLbl: Label 'Correcto';
        BrokenLbl: Label 'Revisar';
        LinkOkLbl: Label 'Enlaces correctos';
        LinkMismatchLbl: Label '%1 = %2', Comment = '%1 = título del campo de enlace, %2 = valor que no coincide';
        AllAlignedLbl: Label 'Los cuatro maestros coinciden en las %1 propiedades revisadas.', Comment = '%1 = nº de propiedades';
        SomeBrokenLbl: Label '%1 propiedades revisadas: %2 con diferencias entre los cuatro maestros.', Comment = '%1 = nº de propiedades, %2 = nº con diferencias';
        NoDimensionSetupLbl: Label 'La dimensión de propiedad no está configurada en el asistente de creación de propiedades: no se ha podido comparar el valor de dimensión.';

    trigger OnPreReport()
    var
        CountProperty: Record "BeDyn Property";
        Total: Integer;
        Broken: Integer;
    begin
        PropertyDimension := PropertyDimensionCode();

        // Primera pasada solo para el resumen, con los mismos filtros que ha
        // elegido el usuario: así la cabecera puede decir de entrada si cuadra o no.
        CountProperty.CopyFilters(Property);
        if CountProperty.FindSet() then
            repeat
                Total += 1;
                if not EvaluateProperty(CountProperty) then
                    Broken += 1;
            until CountProperty.Next() = 0;

        if Broken = 0 then
            SummaryText := StrSubstNo(AllAlignedLbl, Total)
        else
            SummaryText := StrSubstNo(SomeBrokenLbl, Total, Broken);
        if PropertyDimension = '' then
            SummaryText := SummaryText + ' ' + NoDimensionSetupLbl;
    end;

    // Comprueba una propiedad contra los otros tres maestros y deja preparados los
    // textos de cada columna. Devuelve si los cuatro coinciden.
    local procedure EvaluateProperty(PropertyRec: Record "BeDyn Property") Aligned: Boolean
    var
        Item: Record Item;
        Job: Record Job;
        DimValue: Record "Dimension Value";
    begin
        Aligned := true;

        if Item.Get(PropertyRec."No.") then
            ItemText := FoundLbl
        else begin
            ItemText := MissingLbl;
            Aligned := false;
        end;

        // Sin dimensión configurada no hay nada contra lo que comparar: se avisa en
        // el resumen, pero no cuenta como diferencia de la propiedad.
        if PropertyDimension = '' then
            DimValueText := NoDimensionLbl
        else
            if DimValue.Get(PropertyDimension, PropertyRec."No.") then
                DimValueText := FoundLbl
            else begin
                DimValueText := MissingLbl;
                Aligned := false;
            end;

        if Job.Get(PropertyRec."No.") then
            JobText := FoundLbl
        else begin
            JobText := MissingLbl;
            Aligned := false;
        end;

        LinkText := '';
        if PropertyRec."Item No." <> PropertyRec."No." then begin
            LinkText := StrSubstNo(LinkMismatchLbl, PropertyRec.FieldCaption("Item No."), PropertyRec."Item No.");
            Aligned := false;
        end;
        if PropertyRec."Job No." <> PropertyRec."No." then begin
            if LinkText <> '' then
                LinkText := LinkText + '; ';
            LinkText := LinkText + StrSubstNo(LinkMismatchLbl, PropertyRec.FieldCaption("Job No."), PropertyRec."Job No.");
            Aligned := false;
        end;
        if LinkText = '' then
            LinkText := LinkOkLbl;
    end;

    local procedure PropertyDimensionCode(): Code[20]
    var
        WizardSetup: Record "BeDyn Property Setup";
    begin
        if not WizardSetup.Get() then
            exit('');
        exit(WizardSetup."Property Dimension Code");
    end;
}
