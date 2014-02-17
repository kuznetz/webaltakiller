program WebaltaKiller;

uses
  Forms,
  MainUnit in 'MainUnit.pas' {MainForm},
  AntiWebalta in 'AntiWebalta.pas',
  frmReport in 'frmReport.pas' {ReportFrm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Webalta Killer';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TReportFrm, ReportFrm);
  Application.Run;
end.
