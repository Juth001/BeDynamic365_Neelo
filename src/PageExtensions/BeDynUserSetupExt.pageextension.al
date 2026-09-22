namespace BeDynamic.PropertyManagement;

using System.Security.User;

pageextension 82500 "BeDyn User Setup Ext" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("BeDyn Renumber Properties"; Rec."BeDyn Renumber Properties")
            {
                ApplicationArea = All;
            }
        }
    }
}
