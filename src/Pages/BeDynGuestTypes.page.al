namespace BeDynamic.PropertyManagement;

page 82802 "BeDyn Guest Types"
{
    PageType = List;
    SourceTable = "BeDyn Guest Type";
    Caption = 'Tipos de huésped';
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
                    ToolTip = 'Código del tipo de huésped, tal y como llega en los ficheros de importación.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del tipo de huésped.';
                }
            }
        }
    }
}
