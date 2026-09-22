namespace BeDynamic.PropertyManagement;

using System.Integration;

page 82516 "BeDyn Portal Web Viewer"
{
    PageType = Card;
    Caption = 'Portal';
    Extensible = false;

    layout
    {
        area(Content)
        {
            usercontrol(WebViewer; WebPageViewer)
            {
                ApplicationArea = All;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    AddInReady := true;
                    if UrlToShow <> '' then
                        CurrPage.WebViewer.Navigate(UrlToShow);
                end;
            }
        }
    }

    procedure SetUrl(NewUrl: Text; NewCaption: Text)
    begin
        UrlToShow := NewUrl;
        if NewCaption <> '' then
            CurrPage.Caption(NewCaption);
        if AddInReady then
            CurrPage.WebViewer.Navigate(UrlToShow);
    end;

    var
        UrlToShow: Text;
        AddInReady: Boolean;
}
