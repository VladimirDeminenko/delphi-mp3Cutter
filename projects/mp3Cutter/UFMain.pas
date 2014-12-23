unit UFMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls;

type
  TfrmMain = class(TForm)
    dlgOpenDialog: TOpenDialog;
    pnlControl: TPanel;
    btnClose: TButton;
    pnlMain: TPanel;
    lblFileNameFrom: TLabel;
    edtFileName: TEdit;
    btnStart: TButton;
    btnOpen: TButton;
    edtDestDirName: TEdit;
    edtSizeMB: TEdit;
    lblDirNameTo: TLabel;
    lblSizeMB: TLabel;
    Button1: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure edtFileNameChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    function GetDestDirName: string;
    function GetFileName: string;
  protected
    procedure CheckState; virtual;
    procedure Start; virtual;
    property DestDirName: string read GetDestDirName;
    property FileName: string read GetFileName;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  Math, Vcl.FileCtrl;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if dlgOpenDialog.Execute then
  begin
    edtFileName.Text := dlgOpenDialog.FileName;
  end;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  Start;

  ShowMessage('Done.');
end;

procedure TfrmMain.Button1Click(Sender: TObject);
const
  SELDIRHELP = 1000;
var
  dir: string;
begin
  dir := 'G:\Radio';

  if SelectDirectory(dir, [sdAllowCreate, sdPerformCreate, sdPrompt], SELDIRHELP) then
  begin
    edtDestDirName.Text := dir;
  end;
end;

procedure TfrmMain.CheckState;
begin
  btnStart.Enabled := FileName <> EmptyStr;
end;

procedure TfrmMain.edtFileNameChange(Sender: TObject);
begin
  CheckState;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  CheckState;
end;

function TfrmMain.GetDestDirName: string;
var
  destDirName: string;
  fileExt: string;
begin
  fileExt := ExtractFileExt(FileName);
  destDirName := StringReplace(ExtractFileName(FileName), fileExt, '', []);

  Result := Format('%s\%s', [Trim(edtDestDirName.Text), destDirName]);
end;

function TfrmMain.GetFileName: string;
begin
  Result := Trim(edtFileName.Text);
end;

procedure TfrmMain.Start;
const
  BLOCK_SIZE = 1024 * 1024;
var
  blockSize: Integer;
  dest: TFileStream;
  fileExt: string;
  idx: Integer;
  newFileName: string;
  newPath: string;
  offset: Integer;
  src: TFileStream;
begin
  try
    blockSize := Round(StrToFloat(edtSizeMB.Text) * BLOCK_SIZE);
  except
    blockSize := BLOCK_SIZE;
  end;

  src := TFileStream.Create(FileName, fmOpenRead);
  try
    fileExt := ExtractFileExt(FileName);
    newPath := GetDestDirName();

    if not System.SysUtils.DirectoryExists(newPath) then
    begin
      CreateDir(newPath);
    end;

    idx := 0;
    repeat
      newFileName := Format('%s\file%.3d%s', [newPath, idx + 1, fileExt]);
      offset := idx * blockSize;
      src.Seek(offset, soFromBeginning);

      dest := TFileStream.Create(newFileName, fmCreate);
      try
        dest.CopyFrom(src, Min(src.Size - offset, blockSize));
      finally
        FreeAndNil(dest);
      end;

      Inc(idx);
    until src.Size < offset + blockSize;
  finally
    FreeAndNil(src);
  end;
end;

end.
