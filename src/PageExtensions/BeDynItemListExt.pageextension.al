namespace BeDynamic.PropertyWizard;

using Microsoft.Inventory.Item;

pageextension 82400 "BeDyn Item List Ext" extends "Item List"
{
    actions
    {
        addlast(Processing)
        {
            action(BeDynUpdatePropertyDimension)
            {
                ApplicationArea = All;
                Caption = 'Actualizar Dimensión propiedad';
                Image = Dimensions;
                ToolTip = 'Asigna a los productos seleccionados la dimensión de propiedad por defecto con el valor igual al código del producto. Si el valor de dimensión no existe, se crea con la descripción del producto como nombre.';

                trigger OnAction()
                var
                    Item: Record Item;
                    Creation: Codeunit "BeDyn Property Creation";
                    UpdatedCount: Integer;
                    ConfirmQst: Label '¿Actualizar la dimensión de propiedad de %1 productos?', Comment = '%1 = nº de productos seleccionados';
                    DoneMsg: Label 'Dimensión de propiedad actualizada en %1 productos.', Comment = '%1 = nº de productos actualizados';
                begin
                    CurrPage.SetSelectionFilter(Item);
                    if not Confirm(ConfirmQst, false, Item.Count()) then
                        exit;
                    UpdatedCount := Creation.UpdatePropertyDimension(Item);
                    Message(DoneMsg, UpdatedCount);
                end;
            }
        }
    }
}
