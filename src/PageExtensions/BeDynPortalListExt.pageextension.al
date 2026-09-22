namespace BeDynamic.PortalImport;

using BeDynamic.PropertyManagement;

pageextension 82600 "BeDyn Portal List Ext" extends "BeDyn Portal List"
{
    layout
    {
        addlast(General)
        {
            field("Import Channel"; Rec."Import Channel")
            {
                ApplicationArea = All;
            }
        }
    }
}
