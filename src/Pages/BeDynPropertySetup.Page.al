namespace BeDynamic.PropertyWizard;

page 82400 "BeDyn Property Setup"
{
    Caption = 'Configuración asistente propiedades';
    PageType = Card;
    SourceTable = "BeDyn Property Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Property Type Dimension Code"; Rec."Property Type Dimension Code")
                {
                    ApplicationArea = All;
                }
                field("Property Dimension Code"; Rec."Property Dimension Code")
                {
                    ApplicationArea = All;
                }
                field("Item Template Code"; Rec."Item Template Code")
                {
                    ApplicationArea = All;
                }
                field("Job Generic Customer No."; Rec."Job Generic Customer No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenWizard)
            {
                Caption = 'Crear propiedad...';
                ApplicationArea = All;
                Image = NewItem;
                RunObject = page "BeDyn Property Wizard";
                ToolTip = 'Abre el asistente de creación de propiedades.';
            }
        }
        area(Navigation)
        {
            action(MgtCompanies)
            {
                Caption = 'Empresas gestoras';
                ApplicationArea = All;
                Image = Company;
                RunObject = page "BeDyn Property Mgt. Companies";
                ToolTip = 'Abre la lista de empresas gestoras (segundo segmento del código de propiedad).';
            }
            action(TaskTemplates)
            {
                Caption = 'Plantilla de tareas';
                ApplicationArea = All;
                Image = List;
                RunObject = page "BeDyn Property Task Templates";
                ToolTip = 'Abre la plantilla de tareas que se crean en cada proyecto de propiedad, con su línea de planificación opcional.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';
                actionref(OpenWizard_Promoted; OpenWizard) { }
                actionref(MgtCompanies_Promoted; MgtCompanies) { }
                actionref(TaskTemplates_Promoted; TaskTemplates) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
