unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Spin, ActnList, rawimage,imageutils, process,
  inifiles, Language, unit2,updater;

type

  { TForm1 }

  TForm1 = class(TForm)

    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    ButtonStart: TButton;
    ButtonCancel: TButton;
    ComboBox1: TComboBox;
    EditImage: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LabelDevice: TLabel;
    LabelImage: TLabel;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    ProgressBar1: TProgressBar;
    RadioCreate: TRadioButton;
    RadioRestore: TRadioButton;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    SpinEdit1: TSpinEdit;
    Timer1: TTimer;

    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure EditImageChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure RadioRestoreChange(Sender: TObject);
    procedure RestoreImg;
    procedure CreateImg;
    procedure ButtonStartClick(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioCreateChange(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure saveini;
    procedure readini;
    procedure Timer1Timer(Sender: TObject);

  public


  private
    FLastSpeedBytes: Int64;
    procedure Progress(Sender: TObject; BPosition, Total: Int64);
    procedure Log(Sender: TObject; const Msg: string);
  end;

var
  Form1: TForm1;

  const
  version = 'v1.0.1';


implementation

{$R *.frm}

const
  f_caption = 'PiExt';
  prefixbaseimage = 'base_image_';
  prefixdiffimage = 'diff-image_';

var
  LastProgressTime: QWord;
  LastProgressPosition: Int64;
  SmoothedETASeconds: Int64;
  restoredevice, restorefilename, createdevice, createfolder: string;

procedure TForm1.Progress(Sender: TObject; BPosition, Total: Int64);
var
  Tick: QWord;
  DeltaTick: QWord;
  DeltaBytes: Int64;
  Speed: Double;
  Remaining: Int64;
  ETASeconds: Double;
  Hours: Int64;
  Minutes: Int64;
  Seconds: Int64;
  SpeedText: string;
  ETAText: string;
begin
  Tick := GetTickCount64;

  if LastProgressTime = 0 then
  begin
    LastProgressTime := Tick;
    LastProgressPosition := BPosition;
    SmoothedETASeconds := 0;
  end
  else
  begin
    DeltaTick := Tick - LastProgressTime;

    if DeltaTick >= 5000 then
    begin
      DeltaBytes := BPosition - LastProgressPosition;

      if DeltaTick > 0 then
      begin
        Speed := DeltaBytes * 1000.0 / DeltaTick;

        if Speed >= 1024 * 1024 then
          SpeedText := FormatFloat('0.0 MiB/s', Speed / (1024 * 1024))
        else if Speed >= 1024 then
          SpeedText := FormatFloat('0.0 KiB/s', Speed / 1024)
        else
          SpeedText := FormatFloat('0 B/s', Speed);

        if (Total > BPosition) and (Speed > 0) then
        begin
          Remaining := Total - BPosition;
          ETASeconds := Remaining / Speed;

          SmoothedETASeconds := Round((SmoothedETASeconds * 3 + ETASeconds) / 4);

          Hours := SmoothedETASeconds div 3600;
          Minutes := (SmoothedETASeconds mod 3600) div 60;
          Seconds := SmoothedETASeconds mod 60;

          if Hours > 0 then
            ETAText := Format(_(TXT_ETA_HOURS), [Hours, Minutes, Seconds])
          else
            ETAText := Format(_(TXT_ETA_MINUTES), [Minutes, Seconds]);

          //LabelSpeed.Caption
          button4.Caption := SpeedText + '  ' + ETAText;
        end
        else
          //LabelSpeed.Caption := SpeedText;
          button4.Caption := SpeedText;
      end;

      LastProgressTime := Tick;
      LastProgressPosition := BPosition;
    end;
  end;

  if Total > 0 then
    ProgressBar1.Position := Round(BPosition * 100.0 / Total)
  else
    ProgressBar1.Position := 0;

  Application.ProcessMessages;
end;

procedure TForm1.Log(Sender: TObject; const Msg: string);
begin
  Memo1.Lines.Add(Msg);
  Memo1.SelStart := Length(Memo1.Text);
  Application.ProcessMessages;
end;


function extractdevice(s: string): string;
var
  p: Integer;
begin
  s := '/dev/' + s;
  p := Pos(' ', s);

  if p > 0 then
    Result := Copy(s, 1, p - 1)
  else
    Result := s;
end;

function createBasedestname: string;
var
  device, dir: string;
begin
  Result := '';

  device := Trim(extractdevice(Form1.ComboBox1.Text));
  device := Copy(device, 6, MaxInt);

  if device = '' then
  begin
    Form1.Log(Form1, _(TXT_PARTITION_NOT_SELECTED));
    Exit;
  end;

  dir := IncludeTrailingPathDelimiter(Form1.EditImage.Text);

  Result := IncludeTrailingPathDelimiter(dir) + prefixbaseimage + device + '_' + FormatDateTime('yyyy-mm-dd', Date) + '.zst';
end;

procedure GetImageSourcePartitions(ComboBox: TComboBox);
var
  S, Line: string;
  Lines: TStringList;
  P: TStringList;
  I: Integer;
  Target, MountPoint: string;
  Size: Int64;
begin
  ComboBox.Clear;

  RunCommand('lsblk -rnbo NAME,TYPE,FSTYPE,SIZE,MOUNTPOINT', S);

  Lines := TStringList.Create;
  P := TStringList.Create;

  try
    Lines.Text := S;

    for I := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[I]);

      if Line = '' then
        Continue;

      P.Clear;
      P.Delimiter := ' ';
      P.StrictDelimiter := False;
      P.DelimitedText := Line;

      if P.Count < 4 then
        Continue;

      if P[1] <> 'part' then
        Continue;

      if not ((P[2] = 'ext2') or (P[2] = 'ext3') or (P[2] = 'ext4')) then
        Continue;

      Target := P[0];
      Size := StrToInt64Def(P[3], 0);

      if Size <= 0 then
        Continue;

      if P.Count >= 5 then
        MountPoint := P[4]
      else
        MountPoint := '-';

      if MountPoint = '' then
        MountPoint := '-';

      ComboBox.Items.Add(Target + '  ' + FormatFloat('0.0', Size / 1024 / 1024 / 1024) + ' GiB  ' + MountPoint);
    end;

  finally
    P.Free;
    Lines.Free;
  end;
end;

function FileExistsWildcard(const Filename: string): string;
var
  SR: TSearchRec;
begin
  Result := '';

  if FindFirst(Filename + '*', faAnyFile, SR) = 0 then
    Result := ExtractFilePath(Filename) + SR.Name;

  FindClose(SR);
end;

function GetmaxDiffFile(const Dir: string): Integer;
var
  SR: TSearchRec;
  n, p: Integer;
  s: string;
begin
  Result := 0;

  if FindFirst(IncludeTrailingPathDelimiter(Dir) + prefixdiffimage + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') and ((SR.Attr and faDirectory) = 0) then
      begin
        s := SR.Name;
        Delete(s, 1, Length(prefixdiffimage));

        p := Pos('.', s);

        if p > 0 then
          Delete(s, p, MaxInt);

        p := Pos('_', s);

        if p > 0 then
          s := Copy(s, p + 1, MaxInt)
        else
          s := '';

        if not TryStrToInt(s, n) then
          n := 0;

        if n > Result then
          Result := n;
      end;

    until FindNext(SR) <> 0;

    FindClose(SR);
  end;
end;

procedure creatediff(dir, existingbasefile: string);
var
  n: Integer;
  dateiname: string;
begin
  n := GetmaxDiffFile(Dir);

  Dateiname := IncludeTrailingPathDelimiter(dir) + prefixdiffimage + FormatDateTime('yyyy-mm-dd', Date) + '_' + IntToStr(n + 1) + '.zst';

  Form1.Memo1.Clear;

  Form1.Log(Form1, Format(_(TXT_CREATING_DIFF_IMAGE), [dateiname]));

  Form1.ProgressBar1.Position := 0;

  if CreateDiffBitmap(Trim(extractdevice(Form1.ComboBox1.Text)), existingbasefile, Dateiname, @Form1.Progress, @Form1.Log) then
    Form1.Log(Form1, _(TXT_DIFF_IMAGE_CREATED))
  else
    Form1.Log(Form1, _(TXT_DIFF_IMAGE_ERROR));
end;

procedure TForm1.CreateImg;
var
  destname, existingbasefilename, f_ext, device, dir: string;
begin
  Memo1.Clear;
  ProgressBar1.Position := 0;

  FLastSpeedBytes := 0;
  //LabelSpeed
  button4.Caption := '0.0 MB/s';

  try
    dir := Trim(EditImage.Text);

    existingbasefilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + prefixbaseimage);
    f_ext := ExtractFileExt(existingbasefilename);

    if f_ext = '.zst' then
    begin
      creatediff(dir, existingbasefilename);
      Exit;
    end;

    device := Trim(extractdevice(ComboBox1.Text));

    if device = '' then
    begin
      Log(Self, _(TXT_PARTITION_NOT_SELECTED));
      Exit;
    end;

    destname := createBasedestname;

    if destname = '' then
      Exit;

    if not DirectoryExists(dir) then
      ForceDirectories(dir);

    if CreateRawImage(device, Destname, @Progress, @Log) then
      Log(Self, _(TXT_BASE_IMAGE_CREATED))
    else
      Log(Self, _(TXT_BASE_IMAGE_ERROR));

  finally

    //LabelSpeed
    button4.Caption := '0.0 MB/s';
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if RadioCreate.Checked then
  begin
    SelectDirectoryDialog1.FileName := createfolder;

    if SelectDirectoryDialog1.Execute then
      EditImage.Text := SelectDirectoryDialog1.FileName;
  end;

  if RadioRestore.Checked then
  begin
    OpenDialog1.Filter := _(TXT_ZSTD_FILES) + ' (*.zst)|*.zst';
    OpenDialog1.InitialDir := createfolder;

    if OpenDialog1.Execute then
      EditImage.Text := OpenDialog1.FileName;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if CurrentLanguage = LANG_ENGLISH then
  begin
    CurrentLanguage := LANG_GERMAN;
    Button2.Caption := 'EN';
    ButtonCancel.Caption := 'abbrechen';
    Button3.Caption := 'Hilfe';
    Buttonstart.Caption:= _(TXT_CREATE_IMAGE);
  end
  else
  begin
    CurrentLanguage := LANG_ENGLISH;
    Button2.Caption := 'DE';
    ButtonCancel.Caption := 'cancel';
    Button3.Caption := 'help';
    Buttonstart.Caption:= _(TXT_CREATE_IMAGE);
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Form2.Show;
end;

procedure TForm1.ButtonCancelClick(Sender: TObject);
begin
  cancelrequested := True;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveIni;
end;

procedure TForm1.ButtonStartClick(Sender: TObject);
begin
  cancelrequested := False;
  ButtonStart.Enabled := False;
  LastProgressTime := 0;

  try
    if RadioCreate.Checked then
      CreateImg;

    if RadioRestore.Checked then
      RestoreImg;

  except
    on E: Exception do
     if not cancelrequested then Log(Self, E.Message);
  end;
  if cancelrequested then
  begin
    Log(Self,_(TXT_CANCELLED));
    progressbar1.Position:=0;
  end;
  // LabelSpeed.
  button4.Caption := '';

  ButtonStart.Enabled := True;
  cancelrequested:=false;
end;



procedure TForm1.RestoreImg;
var
  TargetDevice: string;
  MountPoint, S: string;
  BaseFilename, DiffFilename, Dir: string;
  SourceFile: string;
begin
  MountPoint := '';

  TargetDevice := Trim(extractdevice(ComboBox1.Text));

  if not DirectoryExists('/sys/class/block/' + ExtractFileName(TargetDevice)) then
  begin
    Log(Self, TargetDevice + ' ' + _(TXT_DOES_NOT_EXIST_RESTORE_SUSPENDED));
    Exit;
  end;

  RunCommand('findmnt -n -o TARGET ' + TargetDevice, MountPoint);
  MountPoint := Trim(MountPoint);

  if MountPoint = '/' then
  begin
    Log(Self, TargetDevice + ' ' + _(TXT_ROOT_RESTORE_SUSPENDED));
    Exit;
  end;

  if MountPoint > '' then
  begin
    RunCommand('umount ' + MountPoint, S);
    RunCommand('umount ' + TargetDevice, S);
  end;

  SourceFile := ExtractFileName(Trim(EditImage.Text));

  if MessageDlg(TargetDevice + ' ' + _(TXT_WILL_BE_RESTORED) + LineEnding + SourceFile + LineEnding + _(TXT_ALL_DATA_WILL_BE_LOST), mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Dir := ExtractFilePath(Trim(EditImage.Text));

  BaseFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + prefixbaseimage);
  DiffFilename := Trim(EditImage.Text);

  if BaseFilename = DiffFilename then
    DiffFilename := '';

  TargetDevice := Trim(extractdevice(ComboBox1.Text));

  if RestoreImage(TargetDevice, BaseFilename, DiffFilename, @Progress, @Log) then
    Log(Self, _(TXT_IMAGE_RESTORED))
  else
    Log(Self, _(TXT_RESTORE_ERROR));
end;

procedure TForm1.ComboBox1DropDown(Sender: TObject);
begin
  GetImageSourcePartitions(ComboBox1);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.Caption := f_caption + ' ' + version;

  //LabelSpeed
  button4.Caption := '';

  RadioRestore.Checked := False;
  RadioCreate.Checked := True;

  ReadIni;

  if CurrentLanguage = LANG_ENGLISH then
  begin
    Button3.Caption := 'help';
    Button2.Caption := 'DE';
    ButtonCancel.Caption := 'cancel';
  end
  else
  begin
    ButtonCancel.Caption := 'abbrechen';
    Button3.Caption := 'Hilfe';
    Button2.Caption := 'EN';
  end;

  ButtonStart.Caption := _(TXT_CREATE_IMAGE);
  Button1.Caption := '▼';

  Label1.Caption := _(TXT_SOURCE_PARTITION);
  Label2.Caption := _(TXT_IMAGE_FOLDER);
  Label3.Caption := _(TXT_COMPRESSION_LEVEL);

  ComboBox1.Text := createdevice;
  EditImage.Text := createfolder;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  if RadioCreate.Checked then
    createdevice := ComboBox1.Text;

  if RadioRestore.Checked then
    restoredevice := ComboBox1.Text;
end;

procedure TForm1.EditImageChange(Sender: TObject);
begin
  if RadioCreate.Checked then
    createfolder := EditImage.Text;

  if RadioRestore.Checked then
    restorefilename := EditImage.Text;
end;

procedure TForm1.RadioCreateChange(Sender: TObject);
begin
  if RadioCreate.Checked then
  begin
    ButtonStart.Caption := _(TXT_CREATE_IMAGE);
    Label1.Caption := _(TXT_SOURCE_PARTITION);
    Label2.Caption := _(TXT_IMAGE_FOLDER);

    SaveIni;

    EditImage.Text := createfolder;
    ComboBox1.Text := createdevice;
  end;
end;

procedure TForm1.SpinEdit1Change(Sender: TObject);
begin

end;

procedure TForm1.RadioRestoreChange(Sender: TObject);
begin
  if RadioRestore.Checked then
  begin
    ButtonStart.Caption := _(TXT_RESTORE_IMAGE);
    Label1.Caption := _(TXT_TARGET_PARTITION);
    Label2.Caption := _(TXT_IMAGE_FILE);

    SaveIni;

    EditImage.Text := restorefilename;
    ComboBox1.Text := restoredevice;
  end;
end;

procedure TForm1.readini;
var
  ini: TIniFile;
  filename: string;
begin
  filename := ChangeFileExt(Application.ExeName, '.cfg');
  ini := TIniFile.Create(filename);

  try
    SpinEdit1.Value := ini.ReadInteger('common', 'compressionlevel', 3);
    CurrentLanguage := ini.ReadInteger('common', 'language', 0);
    createdevice := ini.ReadString('create', 'device', '');
    createfolder := ini.ReadString('create', 'folder', '');
    restoredevice := ini.ReadString('restore', 'device', '');
    restorefilename := ini.ReadString('restore', 'filename', '');
  finally
    ini.Free;
  end;
end;


procedure TForm1.Timer1Timer(Sender: TObject);
begin
   timer1.Enabled := False;
   CheckForUpdates(memo1);

end;


procedure TForm1.saveini;
var
  ini: TIniFile;
  filename: string;
begin
  filename := ChangeFileExt(Application.ExeName, '.cfg');
  ini := TIniFile.Create(filename);

  try
    ini.WriteInteger('common', 'compressionlevel', SpinEdit1.Value);
    ini.WriteInteger('common', 'language', CurrentLanguage);
    ini.WriteString('create', 'device', createdevice);
    ini.WriteString('create', 'folder', createfolder);
    ini.WriteString('restore', 'device', restoredevice);
    ini.WriteString('restore', 'filename', restorefilename);
  finally
    ini.Free;
  end;
end;

end.


