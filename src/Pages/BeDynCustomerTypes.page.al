namespace BeDynamic.PropertyManagement;

page 82801 "BeDyn Customer Types"
{
    PageType = List;
    SourceTable = "BeDyn Customer Type";
    Caption = 'Tipos de cliente';
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Código del tipo de cliente, tal y como llega en los ficheros de importación.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del tipo de cliente.';
                }
            }
        }
    }
}
