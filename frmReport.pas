unit frmReport;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, jpeg;

type
  TReportFrm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    Panel1: TPanel;
    Image1: TImage;
    Panel2: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    ReportResult: integer;
    { Public declarations }

  end;

var
  ReportFrm: TReportFrm;

implementation

{$R *.dfm}

procedure TReportFrm.FormShow(Sender: TObject);
begin
  ReportResult := 0;
end;

procedure TReportFrm.Button1Click(Sender: TObject);
begin
  ReportResult := 1;
  Close();
end;

procedure TReportFrm.Button2Click(Sender: TObject);
begin
  ReportResult := 2;
  Close();
end;

end.
