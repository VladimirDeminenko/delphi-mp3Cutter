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
    btnDestDirOpen: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure edtFileNameChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnDestDirOpenClick(Sender: TObject);
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

const
 Genres: array[0..146] of string =
    ('Blues','Classic Rock','Country','Dance','Disco','Funk','Grunge',
    'Hip- Hop','Jazz','Metal','New Age','Oldies','Other','Pop','R&B',
    'Rap','Reggae','Rock','Techno','Industrial','Alternative','Ska',
    'Death Metal','Pranks','Soundtrack','Euro-Techno','Ambient',
    'Trip-Hop','Vocal','Jazz+Funk','Fusion','Trance','Classical',
    'Instrumental','Acid','House','Game','Sound Clip','Gospel','Noise',
    'Alternative Rock','Bass','Punk','Space','Meditative','Instrumental Pop',
    'Instrumental Rock','Ethnic','Gothic','Darkwave','Techno-Industrial','Electronic',
    'Pop-Folk','Eurodance','Dream','Southern Rock','Comedy','Cult','Gangsta',
    'Top 40','Christian Rap','Pop/Funk','Jungle','Native US','Cabaret','New Wave',
    'Psychadelic','Rave','Showtunes','Trailer','Lo-Fi','Tribal','Acid Punk',
    'Acid Jazz','Polka','Retro','Musical','Rock & Roll','Hard Rock','Folk',
    'Folk-Rock','National Folk','Swing','Fast Fusion','Bebob','Latin','Revival',
    'Celtic','Bluegrass','Avantgarde','Gothic Rock','Progressive Rock',
    'Psychedelic Rock','Symphonic Rock','Slow Rock','Big Band','Chorus',
    'Easy Listening','Acoustic','Humour','Speech','Chanson','Opera',
    'Chamber Music','Sonata','Symphony','Booty Bass','Primus','Porn Groove',
    'Satire','Slow Jam','Club','Tango','Samba','Folklore','Ballad',
    'Power Ballad','Rhytmic Soul','Freestyle','Duet','Punk Rock','Drum Solo',
    'Acapella','Euro-House','Dance Hall','Goa','Drum & Bass','Club-House',
    'Hardcore','Terror','Indie','BritPop','Negerpunk','Polsk Punk','Beat',
    'Christian Gangsta','Heavy Metal','Black Metal','Crossover','Contemporary C',
    'Christian Rock','Merengue','Salsa','Thrash Metal','Anime','JPop','SynthPop');

type

(** )
Заголовок   3   «TAG»
Название    30	30-и символьное название
Исполнитель	30	30-и символьное имя исполнителя
Альбом      30	30-и символьное название альбома
Год	        4	  Строковая запись года
Комментарий	28[1] или 30	Комментарий
Нулевой байт[1]	1	Если номер трека присутствует, этот байт равен 0
Track[1]	  1	  Номер трека в альбоме или 0. Учитывается только если предыдущее поле равно 0
Жанр	      1	  Индекс в списке жанров или 255
//*)

  TID3Tag = record
    ID: string[3];
    Titel: string[30];
    Artist: string[30];
    Album: string[30];
    Year: string[4];
    Comment: string[30];
    Genre: Byte;
  end;

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

procedure TfrmMain.btnDestDirOpenClick(Sender: TObject);
const
  SELDIRHELP = 1000;
var
  dir: string;
  selectResult: Boolean;
begin
  dir := edtDestDirName.Text;

  try
    selectResult := SelectDirectory(dir, [sdAllowCreate, sdPerformCreate, sdPrompt], SELDIRHELP);
  except
    dir := 'd:\radio';
    selectResult := SelectDirectory(dir, [sdAllowCreate, sdPerformCreate, sdPrompt], SELDIRHELP);
  end;

  if selectResult then
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
  SIZE_OF_ID3TAG = SizeOf(TId3Tag);
var
  albumName: ShortString;
  blockSize: Integer;
  dest: TFileStream;
  fileExt: string;
  id3Tag: TID3Tag;
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
    albumName := Copy(StringReplace(ExtractFileName(FileName), fileExt, '', []), 1, 30);

    src.Seek(-SIZE_OF_ID3TAG, soFromEnd);
    src.Read(id3Tag, SIZE_OF_ID3TAG);

    newPath := GetDestDirName();

    if not System.SysUtils.DirectoryExists(newPath) then
    begin
      if not ForceDirectories(newPath) then
      begin
        edtDestDirName.Text := 'd:\radio';
        newPath := GetDestDirName();
        ForceDirectories(newPath);
      end;
    end;

    idx := 0;
    repeat
      offset := idx * blockSize;

      Inc(idx);

      newFileName := Format('%s\file%.3d%s', [newPath, idx, fileExt]);
      src.Seek(offset, soFromBeginning);

      dest := TFileStream.Create(newFileName, fmCreate);
      try
        dest.CopyFrom(src, Min(src.Size - offset, blockSize));
        dest.Seek(0, soFromEnd);
        dest.Write(id3Tag, SIZE_OF_ID3TAG);
      finally
        FreeAndNil(dest);
      end;
    until src.Size < offset + blockSize;

  finally
    FreeAndNil(src);
  end;
end;

end.
