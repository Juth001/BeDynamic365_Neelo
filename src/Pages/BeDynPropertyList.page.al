namespace BeDynamic.PropertyManagement;

page 82503 "BeDyn Property List"
{
    PageType = List;
    SourceTable = "BeDyn Property";
    Caption = 'Propiedades';
    CardPageId = "BeDyn Property Card";
    Editable = false;
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de la propiedad.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la propiedad.';
                }
                field("Owner No."; Rec."Owner No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Propietario de la propiedad.';
                }
                field("Owner Name"; Rec."Owner Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre del propietario.';
                }
                field("Rental Type"; Rec."Rental Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si se alquila la propiedad completa o por subpropiedades.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado de la propiedad (p. ej. ACTIVO, PUBLICADO, BAJA).';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Población de la propiedad.';
                }
                field("No. of Rooms"; Rec."No. of Rooms")
                {
                    ApplicationArea = All;
                    ToolTip = 'Número de subpropiedades registradas.';
                }
                field("External Id"; Rec."External Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Identificador de la propiedad en un sistema externo.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SyncPictures)
            {
                ApplicationArea = All;
                Caption = 'Actualizar imágenes desde productos';
                Image = Refresh;
                ToolTip = 'Actualiza la imagen de las propiedades desde la de su producto y la de las subpropiedades desde la de sus variantes.';

                trigger OnAction()
                var
                    PropertyPictureSync: Codeunit "BeDyn Property Picture Sync";
                begin
                    PropertyPictureSync.SyncAll();
                    Message(PicturesSyncedMsg);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(SyncPictures_Promoted; SyncPictures)
                {
                }
            }
        }
    }

    var
        PicturesSyncedMsg: Label 'Las imágenes se han actualizado desde los productos y sus variantes.';
}
