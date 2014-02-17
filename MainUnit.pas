unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, StrUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Registry, SHFolder, acPNG, ExtCtrls, sButton, sMemo, sPanel,
  OverbyteIcsWndControl, OverbyteIcsHttpProt, frmReport;

type
  TMainForm = class(TForm)
    Image1: TImage;
    Memo2: TMemo;
    sButton1: TsButton;
    sButton2: TsButton;
    sButton3: TsButton;
    PanLogs: TsPanel;
    PanAbout: TsPanel;
    Memo1: TsMemo;
    sMemo1: TsMemo;
    HttpCli1: THttpCli;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure sButton2Click(Sender: TObject);
    procedure sButton3Click(Sender: TObject);
    procedure sButton1Click(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

Uses AntiWebalta, ShellApi;
{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  PanLogs.Visible := false;
  PanAbout.Visible := false;
  ClientHeight := Image1.Height+Memo2.Height+Panel1.Height+Panel2.Height;
  PanLogs.Top := 240;
  PanAbout.Top := 240;
end;

procedure TMainForm.Image1Click(Sender: TObject);
begin
  ShellExecute(0,'open','http://webaltakiller.ru',nil,nil,SW_SHOWNORMAL);
end;

procedure TMainForm.Panel2Click(Sender: TObject);
begin
  ShellExecute(0,'open','http://vklife.ru',nil,nil,SW_SHOWNORMAL);
end;

procedure TMainForm.sButton1Click(Sender: TObject);
begin
  AntiWebalta.LogStrs := Memo1.Lines;
  KillWebalta();

  Reportfrm.ShowModal();
  if (Reportfrm.ReportResult > 0) then begin
    HttpCli1.URL := 'http://webaltakiller.ru/start.php?result='+IntToStr(Reportfrm.ReportResult);
    //HttpCli1.URL := 'http://localhost/webaltakiller/start.php?result='+IntToStr(Reportfrm.ReportResult);
    HttpCli1.GetASync();
  end;
end;

procedure TMainForm.sButton2Click(Sender: TObject);
begin
  PanLogs.Visible := false;
  ClientHeight := Image1.Height+Memo2.Height+Panel1.Height+Panel2.Height+PanAbout.Height;
  PanAbout.Visible := true;
end;

procedure TMainForm.sButton3Click(Sender: TObject);
begin
  PanAbout.Visible := false;
  PanLogs.Height := 300;
  ClientHeight := Image1.Height+Memo2.Height+Panel1.Height+Panel2.Height+PanLogs.Height;
  PanLogs.Visible := true;
end;

end.
