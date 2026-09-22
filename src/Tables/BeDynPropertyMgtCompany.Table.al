namespace BeDynamic.PropertyWizard;

using System.Environment;

table 82401 "BeDyn Property Mgt. Company"
{
    Caption = 'Empresa gestora de propiedades';
    DataClassification = CustomerContent;
    LookupPageId = "BeDyn Property Mgt. Companies";
    DrillDownPageId = "BeDyn Property Mgt. Companies";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Código';
            NotBlank = true;
            ToolTip = 'Código de la empresa gestora. Forma el segundo segmento del código de propiedad (p.ej. 01).';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Nombre';
            ToolTip = 'Nombre de la empresa gestora.';
        }
        field(3; "Company Name"; Text[30])
        {
            Caption = 'Empresa';
            TableRelation = Company.Name;
            ToolTip = 'Empresa de Business Central donde vive la contabilidad de esta gestora. Al importar reservas o gastos de Pleo, las líneas de una propiedad cuyo segundo segmento sea este código se llevan a esta empresa.';
        }
        field(4; "Main Company"; Boolean)
        {
            Caption = 'Empresa principal';
            ToolTip = 'Empresa titular del monedero Pleo: recibe las líneas de Pleo sin propiedad (recargas, cashbacks y gastos sin proyecto), se importen donde se importen. Solo puede haber una.';

            trigger OnValidate()
            var
                OtherCompany: Record "BeDyn Property Mgt. Company";
                OnlyOneMainErr: Label 'Solo puede haber una empresa principal: ya lo es %1 (%2).', Comment = '%1 = código, %2 = nombre';
            begin
                if not "Main Company" then
                    exit;
                OtherCompany.SetRange("Main Company", true);
                OtherCompany.SetFilter(Code, '<>%1', Code);
                if OtherCompany.FindFirst() then
                    Error(OnlyOneMainErr, OtherCompany.Code, OtherCompany.Name);
            end;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    var
        TepozTok: Label 'Tepoz', Locked = true;
        ErasmusTok: Label 'Erasmus', Locked = true;

    // Alta inicial: 01 Tepoz y 02 Erasmus. Solo si la tabla está vacía;
    // después se mantiene desde su página.
    procedure EnsureDefaults()
    begin
        if not Rec.IsEmpty() then
            exit;
        InsertCompany('01', TepozTok);
        InsertCompany('02', ErasmusTok);
    end;

    // El código de propiedad es PAIS-EMPRESA-TIPO-SECUENCIAL: el segundo segmento
    // es el código de esta tabla. Deja el registro posicionado en esa gestora.
    procedure GetFromPropertyCode(PropertyCode: Code[20]): Boolean
    var
        Segments: List of [Text];
        PropertyCodeText: Text;
    begin
        PropertyCodeText := PropertyCode;
        Segments := PropertyCodeText.Split('-');
        if Segments.Count() < 2 then
            exit(false);
        exit(Rec.Get(CopyStr(Segments.Get(2), 1, MaxStrLen(Rec.Code))));
    end;

    // Empresa principal: titular del monedero Pleo; recibe las líneas sin
    // propiedad. Solo puede haber una (se valida al marcarla). Deja el registro
    // posicionado en ella.
    procedure GetMainCompany(): Boolean
    begin
        Rec.Reset();
        Rec.SetRange("Main Company", true);
        exit(Rec.FindFirst());
    end;

    local procedure InsertCompany(NewCode: Code[10]; NewName: Text[100])
    begin
        Rec.Init();
        Rec.Code := NewCode;
        Rec.Name := NewName;
        Rec.Insert(true);
    end;
}
