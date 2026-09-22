namespace BeDynamic.PropertyManagement;

using System.Security.User;

tableextension 82502 "BeDyn User Setup" extends "User Setup"
{
    fields
    {
        field(82500; "BeDyn Renumber Properties"; Boolean)
        {
            Caption = 'Puede renumerar propiedades';
            DataClassification = CustomerContent;
            ToolTip = 'Permite a este usuario cambiar el código de una propiedad cuando la numeración de los cuatro maestros (producto, valor de dimensión, proyecto y propiedad) está enlazada. Sin esta marca el cambio se rechaza; un usuario sin ficha en esta configuración tampoco puede hacerlo.';
        }
    }
}
