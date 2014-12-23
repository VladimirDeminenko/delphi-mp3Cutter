program mp3Cutter;

uses
  System.StartUpCopy,
  FMX.Forms,
  UFMain in 'UFMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
