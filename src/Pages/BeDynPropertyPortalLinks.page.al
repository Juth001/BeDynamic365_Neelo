namespace BeDynamic.PropertyManagement;

page 82515 "BeDyn Property Portal Links"
{
    PageType = List;
    SourceTable = "BeDyn Property Portal Link";
    Caption = 'Portales';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Portal Code"; Rec."Portal Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Portal donde está publicada la propiedad.';
                }
                field("Portal Description"; Rec."Portal Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción del portal.';
                }
                field(URL; Rec.URL)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enlace al anuncio de la propiedad en el portal.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenInBC)
            {
                ApplicationArea = All;
                Caption = 'Abrir en Business Central';
                Image = Web;
                Scope = Repeater;
                ToolTip = 'Abre el anuncio en una ventana dentro de Business Central. Algunos portales bloquean esta vista; en ese caso use Abrir en navegador.';

                trigger OnAction()
                var
                    PortalWebViewer: Page "BeDyn Portal Web Viewer";
                begin
                    Rec.TestField(URL);
                    Rec.CalcFields("Portal Description");
                    PortalWebViewer.SetUrl(Rec.URL, Rec."Portal Description");
                    PortalWebViewer.Run();
                end;
            }
            action(OpenInBrowser)
            {
                ApplicationArea = All;
                Caption = 'Abrir en navegador';
                Image = LaunchWeb;
                Scope = Repeater;
                ToolTip = 'Abre el anuncio de la propiedad en una pestaña nueva del navegador.';

                trigger OnAction()
                begin
                    Rec.TestField(URL);
                    Hyperlink(Rec.URL);
                end;
            }
        }
    }
}
