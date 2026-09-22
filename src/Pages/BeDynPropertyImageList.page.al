namespace BeDynamic.PropertyManagement;

page 82536 "BeDyn Property Image List"
{
    PageType = List;
    SourceTable = "BeDyn Property Image";
    Caption = 'Imágenes de propiedad';
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Property No."; Rec."Property No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propiedad de la imagen.';
                }
                field("Room No."; Rec."Room No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Subpropiedad de la imagen. En blanco si es una imagen general de la propiedad.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Orden de la imagen dentro de la galería.';
                    Visible = false;
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del archivo de la imagen.';
                }
                field("Source Id"; Rec."Source Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identificador del archivo en el origen (p. ej. id de Google Drive). Evita importarlo dos veces.';
                }
            }
        }
        area(FactBoxes)
        {
            part(Gallery; "BeDyn Property Image Gallery")
            {
                ApplicationArea = All;
                Caption = 'Imagen';
                SubPageLink = "Property No." = field("Property No."), "Room No." = field("Room No."), "Line No." = field("Line No.");
            }
        }
    }
}
