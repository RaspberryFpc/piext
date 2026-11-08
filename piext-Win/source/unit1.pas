unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  ExtCtrls, Windows, IniFiles, rawimage, ImageUtils, Language,Htmlshow,messages;

const
  version = 'v1.0.0';
  f_caption = 'PiExt Restorer';
  prefixbaseimage = 'base_image_';
  prefixdiffimage = 'diff-image_';

type
  TTargetPartition = record
    PhysicalDrive: string;
    PartitionNumber: integer;
    PartitionType: byte;
    StartLBA: uint64;
    SectorCount: uint64;
  end;



  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Bt_language: TButton;
    Bt_speed: TButton;
    Button3: TButton;
    ButtonRestore: TButton;
    ButtonCancel: TButton;
    ButtonStart: TButton;
    cb_mbr: TCheckBox;
    cb_boot: TCheckBox;
    cb_system: TCheckBox;
    ComboBox1: TComboBox;
    EditImage: TEdit;
    Label1: TLabel;
    LabelTarget: TLabel;
    LabelImage: TLabel;
    LabelDevice: TLabel;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    ProgressBar1: TProgressBar;
    procedure Button1Click(Sender: TObject);
    procedure Bt_languageClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonStartClick(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    function RestoreImage: boolean;

  private
    FPartitions: array of TTargetPartition;
    FLastSpeedBytes: int64;

    procedure Progress(Sender: TObject; BPosition, Total: int64);
    procedure Log(Sender: TObject; const Msg: string);
    procedure LoadTargetPartitions;
    function ReadMBR(const PhysicalDrive: string; out MBR: TMBR): boolean;
    function GetPartitionKey(const P: TTargetPartition): string;
    function FindPartitionIndex(const Key: string): integer;
    function GetSelectedPartition(out P: TTargetPartition): boolean;
    function GetImageType(const Filename: string): integer;
    function FindBaseImage(const DiffFilename: string): string;
    procedure SaveIni;
    procedure ReadIni;
    procedure ApplyLanguage;
    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    procedure WMRefreshPartitions(var Msg: TMessage); message WM_APP + 100;
  public
    end;

var
  Form1: TForm1;
   new_mbr:tmbr;

implementation

{$R *.Frm}

const
  DBT_DEVICEARRIVAL = $8000;
  DBT_DEVICEREMOVECOMPLETE = $8004;
  DBT_DEVNODES_CHANGED = $0007;

var
  LastProgressTime: qword;

procedure TForm1.WMDeviceChange(var Msg: TMessage);
begin
  inherited;
  case Msg.WParam of
    DBT_DEVICEARRIVAL,
    DBT_DEVICEREMOVECOMPLETE,
    DBT_DEVNODES_CHANGED:
      PostMessage(Handle, WM_APP + 100, 0, 0);
  end;
end;

procedure TForm1.WMRefreshPartitions(var Msg: TMessage);
begin
  combobox1.Text:='';
  LoadTargetPartitions;
end;


function FormatBytes(Value: uint64): string;
begin
  if Value >= uint64(1024) * 1024 * 1024 then
    Result := FormatFloat('0.00', Value / (1024.0 * 1024.0 * 1024.0)) + ' GiB'
  else
  if Value >= uint64(1024) * 1024 then
    Result := FormatFloat('0.00', Value / (1024.0 * 1024.0)) + ' MiB'
  else
    Result := FormatFloat('0.00', Value / 1024.0) + ' KiB';
end;


function tform1.ReadMBR(const PhysicalDrive: string; out MBR: TMBR): boolean;
var
  H: THandle;
  ReadCount: DWORD;
begin
  Result := False;
  FillChar(MBR, SizeOf(MBR), 0);
  H := CreateFile(PChar(PhysicalDrive), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then Exit;
  try

    if not ReadFile(H, MBR, 512, ReadCount, nil) then Exit;
    if ReadCount <> 512 then Exit;
    if MBR.Signature <> $AA55 then Exit;
    Result := True;
  finally
    CloseHandle(H);
  end;
end;


function TForm1.GetPartitionKey(const P: TTargetPartition): string;
begin
  Result := P.PhysicalDrive + ':' + IntToStr(P.PartitionNumber);
end;

function TForm1.FindPartitionIndex(const Key: string): integer;
var
  I: integer;
begin
  Result := -1;

  if Key = '' then
    Exit;

  for I := 0 to High(FPartitions) do
    if SameText(GetPartitionKey(FPartitions[I]), Key) then
      Exit(I);
end;



procedure TForm1.LoadTargetPartitions;
var
  DriveNo: integer;
  DriveName: string;
  DriveInfo:string;
  H: THandle;
  P: TTargetPartition;
  OldKey: string;
  OldIndex: integer;
begin
  OldKey := '';

  if (ComboBox1.ItemIndex >= 0) and (ComboBox1.ItemIndex < Length(FPartitions)) then
    OldKey := GetPartitionKey(FPartitions[ComboBox1.ItemIndex]);

  ComboBox1.Items.BeginUpdate;
  try
    ComboBox1.Items.Clear;
    SetLength(FPartitions, 0);

    for DriveNo := 0 to 31 do
    begin
      DriveName := '\\.\PhysicalDrive' + IntToStr(DriveNo);

      if IsSystemDrive(DriveName) then
        Continue;


      H := CreateFile(PChar(DriveName), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

      if H = INVALID_HANDLE_VALUE then
        Continue;

      CloseHandle(H);

      P.PhysicalDrive := DriveName;
      P.PartitionNumber := 0;
      P.PartitionType := 0;
      P.StartLBA := 0;
      P.SectorCount := 0;

      SetLength(FPartitions, Length(FPartitions) + 1);
      FPartitions[High(FPartitions)] := P;

      DriveInfo:=GetPhysicalDriveInfo(DriveName);

      ComboBox1.Items.Add(DriveName + '  (' + FormatBytes(GetPhysicalDriveSize(DriveName)) + ') '+ driveinfo);


    end;
  finally
    ComboBox1.Items.EndUpdate;
  end;

  OldIndex := FindPartitionIndex(OldKey);

  if OldIndex >= 0 then
    ComboBox1.ItemIndex := OldIndex
  else if ComboBox1.Items.Count > 0 then
    ComboBox1.ItemIndex := 0;
end;



function TForm1.GetSelectedPartition(out P: TTargetPartition): boolean;
begin
  Result := False;

  if (ComboBox1.ItemIndex < 0) or (ComboBox1.ItemIndex > High(FPartitions)) then
    Exit;

  P := FPartitions[ComboBox1.ItemIndex];
  Result := True;
end;

function TForm1.GetImageType(const Filename: string): integer;
var
  F: TFileStream;
  Magic: array[0..7] of ansichar;
begin
  Result := 0;
  if not FileExists(Filename) then
    Exit;
  F := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
  try
    if F.Read(Magic, SizeOf(Magic)) <> SizeOf(Magic) then
      Exit;
    if CompareByte(Magic, 'PIBASE01', 8) = 0 then
      Result := 1
    else
    if CompareByte(Magic, 'PIDIFF01', 8) = 0 then
      Result := 2;
  finally
    F.Free;
  end;
end;

function TForm1.FindBaseImage(const DiffFilename: string): string;
var
  SR: TSearchRec;
  Dir: string;
  Candidate: string;
begin
  Result := '';

  Dir := ExtractFilePath(DiffFilename);

  if FindFirst(IncludeTrailingPathDelimiter(Dir) + 'base_image_*.zst', faAnyFile and not faDirectory, SR) <> 0 then
    Exit;

  try
    repeat
      Candidate :=
        IncludeTrailingPathDelimiter(Dir) + SR.Name;

      if GetImageType(Candidate) = 1 then
      begin
        Result := Candidate;
        Exit;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR.FindHandle);
  end;
end;


procedure TForm1.Progress(Sender: TObject; BPosition, Total: int64);
var
  Percent: integer;
begin
  if Total <= 0 then
    Exit;

  Percent := Trunc((BPosition * 100.0) / Total);

  if Percent < 0 then
    Percent := 0
  else
  if Percent > 100 then
    Percent := 100;

  ProgressBar1.Position := Percent;
  FLastSpeedBytes := BPosition;
end;

procedure TForm1.Log(Sender: TObject; const Msg: string);
begin
  Memo1.Lines.Add(Msg);
  Memo1.SelStart := Length(Memo1.Text);
end;

procedure TForm1.ButtonCancelClick(Sender: TObject);
begin
  cancelrequested := True;
end;





procedure TForm1.ComboBox1DropDown(Sender: TObject);
begin
  LoadTargetPartitions;
end;


procedure TForm1.Button1Click(Sender: TObject);
begin
  OpenDialog1.Filter := _(TXT_OPEN_IMAGE_FILTER);

  OpenDialog1.DefaultExt := 'zst';

  if FileExists(EditImage.Text) then
    OpenDialog1.InitialDir := ExtractFilePath(EditImage.Text);

  if not OpenDialog1.Execute then
    Exit;

  if GetImageType(OpenDialog1.FileName) = 0 then
  begin
    ShowMessage(_(TXT_IMAGE_INVALID));
    Exit;
  end;
  EditImage.Text := OpenDialog1.FileName;
end;



procedure TForm1.ApplyLanguage;
begin
  Caption := f_caption + ' ' + version;
  LabelImage.Caption := _(TXT_LABEL_IMAGE);
  LabelTarget.Caption := _(TXT_LABEL_DEVICE);
  ButtonStart.Caption := _(TXT_BUTTON_START);
  ButtonCancel.Caption := _(TXT_BUTTON_CANCEL);
  if currentlanguage=0 then Bt_language.Caption:='EN' else  Bt_language.Caption:='DE';
  label1.Caption:=_( TXT_Restore_of);
end;


procedure TForm1.Bt_languageClick(Sender: TObject);
begin
   if   CurrentLanguage=0 then  CurrentLanguage:=1 else  CurrentLanguage:=0;
   ApplyLanguage;
    SaveIni;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 form2.show;
end;


procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveIni;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  x:integer;
begin
  ReadIni;
  ApplyLanguage;
  LoadTargetPartitions;
  for x:=0 to combobox1.Items.count-1 do
       if combobox1.Items[x] = combobox1.text then exit;
  combobox1.Text:='';

end;

procedure TForm1.ReadIni;
begin
  EditImage.Text := '';

  with TIniFile.Create(ChangeFileExt(Application.ExeName, '.cfg')) do
  try
    EditImage.Text :=ReadString('restore', 'filename', '');
    currentlanguage:=ReadInteger('language', 'current', LANG_GERMAN);
    ApplyLanguage;
  finally
    Free;
  end;
end;



procedure TForm1.SaveIni;
var
  Ini: TIniFile;
  P: TTargetPartition;
begin
  Ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.cfg'));

  try
    if GetSelectedPartition(P) then
      Ini.WriteString(
        'restore',
        'device',
        GetPartitionKey(P));

    Ini.WriteString(
      'restore',
      'filename',
      EditImage.Text);
    Ini.WriteInteger('language', 'current', CurrentLanguage);
  finally
    Ini.Free;
  end;
end;



//////////////////////////////////////////////////////////////////////////////////////////////////
procedure TForm1.ButtonStartClick(Sender: TObject);
var
  Success, AnySelected: boolean;
  S, TargetDevice, MBRFilename, Dir, ErrorMsg, InvalidPartitions: string;
  DiskSectors, EndLBA: QWord;
  I, p: integer;
  f_mbr:tmbr;
begin
  cancelrequested := False;
  ButtonStart.Enabled := False;
  Buttoncancel.Enabled :=true;
  LastProgressTime := 0;
  Success := False;
try
  try
    AnySelected := cb_mbr.Checked or cb_boot.Checked or cb_system.Checked;

    if not AnySelected then
    begin
      Log(Self, _(TXT_PLEASE_SELECT_RESTORE_OPTION));
      Exit;
    end;

    TargetDevice := Trim(ComboBox1.Text);
    p := Pos('  (', TargetDevice);
    if p > 0 then
      TargetDevice := Copy(TargetDevice, 1, p - 1);

    if TargetDevice = '' then
    begin
      Log(Self, _(TXT_DRIVE_NOT_SELECTED));
      Exit;
    end;

    S := _(TXT_SECURITY_QUERY) + LineEnding + LineEnding + _(TXT_WARNING) + LineEnding + LineEnding + _(TXT_TARGET_DRIVE_INFO)
          + LineEnding + '  ' + TargetDevice + LineEnding + LineEnding + _(TXT_DATA_WRITTEN_TO_DRIVE) + LineEnding + LineEnding;

    if cb_mbr.Checked then
      S := S + '  • ' + _(TXT_MBR) + LineEnding;

    if cb_boot.Checked then
      S := S + '  • ' + _(TXT_BOOT_PARTITION_NAME) + LineEnding;

    if cb_system.Checked then
      S := S + '  • ' + _(TXT_SYSTEM_PARTITION_NAME) + LineEnding;

    { Check whether invalid partitions will be removed from the MBR }
    InvalidPartitions := '';

    ReadMBRFromTarget(targetdevice,new_mbr);

   if cb_mbr.Checked then
    begin
      Dir := ExtractFilePath(Trim(EditImage.Text));
      MBRFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'mbr_image_*.img');
      if (MBRFilename <> '') and FileExists(MBRFilename) then
      begin
        if not Read_MBR(MBRFilename, ErrorMsg, new_mbr) then
        begin
          Log(Self, ErrorMsg);
          Exit;
        end;

        DiskSectors := GetPhysicalDriveSize(TargetDevice) div 512;

        if DiskSectors = 0 then
        begin
          Log(Self, Format(_(TXT_INVALID_DISK_SIZE), [TargetDevice]));
          Exit;
        end;

        for I := 1 to 4 do
        begin
          if new_MBR.PartitionEntries[I].PartitionSize > 0 then
          begin
            EndLBA := new_MBR.PartitionEntries[I].FirstLBA + new_MBR.PartitionEntries[I].PartitionSize;

            if EndLBA > DiskSectors then
              InvalidPartitions := InvalidPartitions + _(TXT_PARTITION) + ' ' + IntToStr(I) + LineEnding;
          end;
        end;
      end;
    end;

    if InvalidPartitions <> '' then
      S := S + LineEnding + LineEnding + _(TXT_WARNING) + LineEnding + _(txt_invalid_part_detected) + LineEnding + InvalidPartitions + _(txt_invalid_remove) + LineEnding;

    S := S + LineEnding + _(TXT_EXISTING_DATA_OVERWRITTEN) + LineEnding + _(TXT_CONFIRM_CONTINUE);

    if MessageDlg(_(TXT_SECURITY_QUERY), S, mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;



// ungültige partitionen im gespeicherten mbr löschen
for I := 1 to 4 do
      if new_MBR.PartitionEntries[I].PartitionSize > 0 then
        begin
          EndLBA := new_MBR.PartitionEntries[I].FirstLBA + new_MBR.PartitionEntries[I].PartitionSize;
         if EndLBA > DiskSectors then  fillchar(new_MBR.PartitionEntries[I],16,0);
       end;

// jetzt den gesammten mbr auf laufwerk löschen

    fillchar(f_mbr,512,0);
    Write_MBR(f_MBR,targetdevice);

    Success :=RestoreImage;

    Write_MBR(new_MBR,targetdevice);

  except
    on E: Exception do
    begin
      if not cancelrequested then
        Log(Self, E.Message);
      Success := False;
    end;
  end;

  if cancelrequested then
  begin
    Log(Self, _(TXT_CANCELLED));
    ProgressBar1.Position := 0;
  end;

  finally

  Bt_speed.Caption := '';
  ButtonStart.Enabled := True;
  Buttoncancel.Enabled :=false;
  cancelrequested := False;
end;
end;


function TForm1.RestoreImage: boolean;
var
  TargetDevice, Disk: string;
  BaseFilename, DiffFilename, Dir: string;
  MBRFilename, BootFilename: string;
  p: integer;
    drivesize:int64;
begin
  Result := False;

  TargetDevice := Trim(ComboBox1.Text);
  p := Pos('  (', TargetDevice);
  if p > 0 then
    TargetDevice := Copy(TargetDevice, 1, p - 1);

  if TargetDevice = '' then
  begin
    Log(Self, _(TXT_DRIVE_NOT_SELECTED));
    Exit;
  end;

  Disk := TargetDevice;

  //dir aus path extrahieren

    dir := extractfilepath(Trim(EditImage.Text));
    DiffFilename := Trim(EditImage.Text);
    Dir := ExtractFilePath(DiffFilename);

  if not fileexists(difffilename) then difffilename:='';
    if pos('diff-image_',extractfilename(diffFilename))<>1 then
                                                        diffFilename:='';

    MBRFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'mbr_image_*.img');
    BootFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'boot_image_*.zst');
    basefilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'base_image_*.zst');


    if not fileexists( MBRFilename) then mbrfilename:='';
    if not fileexists(BootFilename) then BootFilename:='';
    if not fileexists( basefilename) then  basefilename:='';


    p := GetPhysicalDriveNumber(TargetDevice);

if p < 0 then
begin
  Log(Self, Format(_(TXT_INVALID_PHYSICAL_DRIVE), [TargetDevice]));
  Exit;
end;

Log(Self, _(TXT_LOCK_PARTITIONS));

try
if not LockAndDismountDrivePartitions(p) then
begin
  Log(Self, _(TXT_LOCK_PARTITIONS_FAILED));
  Exit;
end;

Log(Self, _(TXT_PARTITIONS_LOCKED));


 if CB_Boot.Checked then
           if BootFilename = '' then
    begin
      Log(Self, Format(_(TXT_NO_BOOT_IMAGE), [Dir]));
      Exit;
    end;


    if CB_System.Checked then
       if BaseFilename = '' then
      begin
        Log(Self, Format(_(TXT_NO_BASE_IMAGE), [Dir]));
        Exit;
      end;



  ////////////////////////////////////////////////////////////////////////

  if CB_Boot.Checked then
  begin
   Log(Self, Format(_(TXT_RESTORING_BOOT), [targetdevice]));

   if not RestoreBootImage(BootFilename,targetdevice,new_mbr, @Progress, @Log) then
      begin
      Log(Self, _(TXT_BOOT_RESTORE_ERROR));
      Exit;
     end;
   Log(Self, _(TXT_BOOT_RESTORED));


   if CB_System.Checked then
  begin
    Log(Self, Format(_(TXT_RESTORING_SYSTEM), [TargetDevice]));

   if not RestoreSystemImage(targetDevice, BaseFilename, DiffFilename, @Progress, @Log) then
    begin
      Log(Self, _(TXT_RESTORE_ERROR));
      Exit;
    end;

    Log(Self, _(TXT_SYSTEM_RESTORE_SUCCESS));

  end;

  // üngültige ppartiotionen entfernen
  // wenn grösser als device

  drivesize:=GetPhysicalDriveSize(targetdevice) div 512;

  if (new_mbr.PartitionEntries[3].FirstLBA + new_mbr.PartitionEntries[3].PartitionSize) >  drivesize then fillchar (new_mbr.PartitionEntries[3],16,0);
  if (new_mbr.PartitionEntries[4].FirstLBA + new_mbr.PartitionEntries[4].PartitionSize) >  drivesize then fillchar (new_mbr.PartitionEntries[4],16,0);
  write_mbr(new_mbr,targetdevice);

  Result := True;
  Log(Self, _(TXT_ALL_SELECTED_RESTORED));

  end;
  finally
    UnlockDrivePartitions;
  end;

end;








end.
