unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,StdCtrls, ComCtrls, ExtCtrls, Spin, ActnList, rawimage,
  imageutils, process, inifiles, Language, unit2, updater,BaseUnix,rkutils;

type
  { TForm1 }
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    ButtonStart: TButton;
    ButtonCancel: TButton;
    cb_system: TCheckBox;
    cb_boot: TCheckBox;
    cb_mbr: TCheckBox;
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
    procedure cb_bootChange(Sender: TObject);
    procedure cb_mbrChange(Sender: TObject);
    procedure cb_systemChange(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure EditImageChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure RadioRestoreChange(Sender: TObject);
    function RestoreImg: boolean;
    function RestoreMBRImage: boolean;
    function CreateImg(const device: string): boolean;
    procedure ButtonStartClick(Sender: TObject);
    procedure ComboBox1DropDown(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioCreateChange(Sender: TObject);
    procedure saveini;
    procedure readini;
    procedure Timer1Timer(Sender: TObject);
  public
    procedure StartCLI;
  private
    FLastSpeedBytes: int64;
    FCliMode: boolean;
    FCliHide: boolean;
    FCliStart: boolean;
    FCliCreate: boolean;
    FCliRestore: boolean;
    FCliCreateDestination: boolean;
    FCliDestinationSpecified: boolean;
    procedure Progress(Sender: TObject; BPosition, Total: int64);
    procedure Log(Sender: TObject; const Msg: string);
    procedure ProcessCommandLine;
    procedure GetImageSourcePartitions(ComboBox: TComboBox);
  end;

var
  Form1: TForm1;

const
  version = 'v2.0.5';  // verzeichnisrechte
  f_caption = 'PiExt';
  prefixbaseimage = 'base_image_';
  prefixdiffimage = 'diff-image_';

implementation

{$R *.frm}

var
  LastProgressTime: QWord;
  LastProgressPosition: int64;
  SmoothedETASeconds: int64;
  restoredevice, restorefilename, createdevice, createfolder: string;

procedure TForm1.StartCLI;
begin
  if FCliStart then
    ButtonStartClick(ButtonStart);
end;

procedure TForm1.Progress(Sender: TObject; BPosition, Total: int64);
var
  Tick, DeltaTick: QWord;
  DeltaBytes, Remaining, Hours, Minutes, Seconds: int64;
  Speed, ETASeconds: double;
  SpeedText, ETAText: string;
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
          Button4.Caption := SpeedText + '  ' + ETAText;
        end
        else
          Button4.Caption := SpeedText;
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
  p: integer;
begin
  s := Trim(s);
  if s = '' then
  begin
    Result := '';
    Exit;
  end;
  p := Pos(' ', s);
  if p > 0 then
    s := Copy(s, 1, p - 1);
  if Pos('/dev/', s) <> 1 then
    s := '/dev/' + s;
  Result := s;
end;

function GetDeviceType(const Device: string): string;
var
  S: string;
begin
  Result := '';
  if Device = '' then
    Exit;
  RunCommand('lsblk -dnbo TYPE ' + Device, S);
  Result := Trim(S);
end;

function IsWholeDisk(const Device: string): boolean;
begin
  Result := SameText(GetDeviceType(Device), 'disk');
end;

function GetParentDisk(const Device: string): string;
var
  Name: string;
begin
  Name := ExtractFileName(extractdevice(Device));
  if Name = '' then
    Exit('');

  if (Pos('nvme', Name) = 1) or (Pos('mmcblk', Name) = 1) then
  begin
    while (Length(Name) > 0) and CharInSet(Name[Length(Name)], ['0'..'9']) do
      Delete(Name, Length(Name), 1);
    if (Length(Name) > 0) and (Name[Length(Name)] = 'p') then
      Delete(Name, Length(Name), 1);
  end
  else
  begin
    while (Length(Name) > 0) and CharInSet(Name[Length(Name)], ['0'..'9']) do
      Delete(Name, Length(Name), 1);
  end;

  if Name = '' then
    Result := ''
  else
    Result := '/dev/' + Name;
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
    Form1.Log(Form1, _(TXT_DRIVE_NOT_SELECTED));
    Exit;
  end;
  dir := IncludeTrailingPathDelimiter(Form1.EditImage.Text);
  Result := IncludeTrailingPathDelimiter(dir) + prefixbaseimage + device + '_' + FormatDateTime('yyyy-mm-dd', Date) + '.zst';
end;

procedure TForm1.GetImageSourcePartitions(ComboBox: TComboBox);
var
  S, Line, DeviceName, DeviceType, FSType, SizeStr: string;
  RootSource, RootDisk, ParentDisk: string;
  SL, Fields: TStringList;
  I: integer;
  Size: int64;
begin
  ComboBox.Items.Clear;

  RootSource := '';
  RootDisk := '';

  if RadioRestore.Checked then
  begin
    RunCommand('findmnt -no SOURCE /', RootSource);
    RootSource := Trim(RootSource);

    if RootSource <> '' then
    begin
      RunCommand('lsblk -no PKNAME ' + RootSource, RootDisk);
      RootDisk := Trim(RootDisk);

      if RootDisk = '' then
        RootDisk := ExtractFileName(RootSource);
    end;
  end;

  RunCommand('lsblk -rnbo NAME,TYPE,SIZE,FSTYPE', S);

  SL := TStringList.Create;
  try
    SL.Text := S;

    for I := 0 to SL.Count - 1 do
    begin
      Line := Trim(SL[I]);

      if Line = '' then
        Continue;

      Fields := TStringList.Create;
      try
        ExtractStrings([' ', #9], [], PChar(Line), Fields);

        if Fields.Count < 3 then
          Continue;

        DeviceName := Fields[0];
        DeviceType := Fields[1];
        SizeStr := Fields[2];

        FSType := '';

        if Fields.Count >= 4 then
          FSType := LowerCase(Fields[3]);

        if (Pos('loop', LowerCase(DeviceName)) = 1) or (Pos('zram', LowerCase(DeviceName)) = 1) then
          Continue;

        { Aktives Systemlaufwerk beim Restore komplett ausschließen }
        if RadioRestore.Checked and (RootDisk <> '') then
        begin
          ParentDisk := '';

          if DeviceType = 'disk' then
            ParentDisk := DeviceName
          else if DeviceType = 'part' then
            RunCommand('lsblk -no PKNAME /dev/' + DeviceName, ParentDisk);

          ParentDisk := Trim(ParentDisk);

          if (DeviceName = RootDisk) or (ParentDisk = RootDisk) then
            Continue;
        end;
        if (DeviceType <> 'disk') then continue;

        Size := StrToInt64Def(SizeStr, 0);

        if Size <= 0 then
          Continue;

        if DeviceType = 'disk' then
          ComboBox.Items.Add('/dev/' + DeviceName + '  ' + FormatFloat('0.0', Size / 1024 / 1024 / 1024) + ' GiB  disk')
        else
        begin
          if FSType = '' then
            FSType := 'unknown';

          ComboBox.Items.Add('/dev/' + DeviceName + '  ' + FormatFloat('0.0', Size / 1024 / 1024 / 1024) + ' GiB  ' + FSType);
        end;

      finally
        Fields.Free;
      end;
    end;

  finally
    SL.Free;
  end;
end;

function FileExistsWildcard(const Filename: string): string;
var
  SR: TSearchRec;
begin
  Result := '';
  if FindFirst(Filename + '*', faAnyFile, SR) = 0 then
  begin
    Result := ExtractFilePath(Filename) + SR.Name;
    FindClose(SR);
  end;
end;

function GetmaxDiffFile(const Dir: string): integer;
var
  SR: TSearchRec;
  n, p: integer;
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

function creatediff(dir, existingbasefile, systemdevice: string): boolean;
var
  n: integer;
  Dateiname,s: string;
begin
  Result := False;
  n := GetmaxDiffFile(Dir);
  Dateiname := IncludeTrailingPathDelimiter(dir) + prefixdiffimage + FormatDateTime('yyyy-mm-dd', Date) + '_' + IntToStr(n + 1) + '.zst';
  Form1.Memo1.Clear;
  Form1.Log(Form1, Format(_(TXT_CREATING_DIFF_IMAGE), [Dateiname]));
  Form1.ProgressBar1.Position := 0;
  Form1.Log(Form1, 'Differential source: ' + systemdevice);
  if CreateDiffBitmap(systemdevice, existingbasefile, Dateiname, @Form1.Progress, @Form1.Log) then
  begin
    Form1.Log(Form1, _(TXT_SYNCING));
    RunCommand('sync',s);
    Form1.Log(Form1, _(TXT_DIFF_IMAGE_CREATED));
    Result := True;
  end
  else
    Form1.Log(Form1, _(TXT_DIFF_IMAGE_ERROR));
end;

function TForm1.CreateImg(const device: string): boolean;
var
  destname, existingbasefilename, bootimagename, mbrimagename: string;
  f_ext, disk, bootdevice, systemdevice, dir, Timestamp,s: string;
begin
  Result := False;
  Memo1.Clear;
  ProgressBar1.Position := 0;
  FLastSpeedBytes := 0;
  Button4.Caption := '0.0 MB/s';

  try
    dir := Trim(EditImage.Text);

    if dir = '' then
    begin
      Log(Self, _(TXT_NO_DESTINATION_FOLDER));
      Exit;
    end;

    if FCliMode and FCliDestinationSpecified and not FCliCreateDestination and not DirectoryExists(dir) then
    begin
      Log(Self, Format(_(TXT_DESTINATION_NOT_EXIST), [dir]));
      Exit;
    end;

    if not DirectoryExists(dir) then
    begin
      if not ForceDirectories(dir) then
      begin
        Log(Self, Format(_(TXT_DESTINATION_CREATE_ERROR), [dir]));
        Exit;
      end;
    end;

    // verzeichnisrechte setzen damit images vom user ohne sudo gelöscht werden können

    fpChmod(PChar(Dir), &0777);


    disk := Trim(ExtractDevice(device));

    if disk = '' then
    begin
      Log(Self, _(TXT_NO_DEVICE_SPECIFIED));
      Exit;
    end;

    if not IsWholeDisk(disk) then
    begin
      Log(Self, Format(_(TXT_NOT_COMPLETE_DISK), [disk]));
      Exit;
    end;

    Log(Self, Format(_(TXT_SOURCE_DRIVE), [disk]));

    { Second partition = system partition }
    if Pos('mmcblk', ExtractFileName(disk)) = 1 then
      systemdevice := disk + 'p2'
    else if Pos('nvme', ExtractFileName(disk)) = 1 then
      systemdevice := disk + 'p2'
    else
      systemdevice := disk + '2';

    if not DirectoryExists('/sys/class/block/' + ExtractFileName(systemdevice)) then
    begin
      Log(Self, Format(_(TXT_SYSTEM_PARTITION_NOT_FOUND), [systemdevice]));
      Exit;
    end;

    Log(Self, Format(_(TXT_SYSTEM_PARTITION), [systemdevice]));

    existingbasefilename := FileExistsWildcard(IncludeTrailingPathDelimiter(dir) + prefixbaseimage);
    f_ext := ExtractFileExt(existingbasefilename);

    { Existing base image -> create differential image }
    if f_ext = '.zst' then
    begin
      Log(Self, _(TXT_BASE_IMAGE_EXISTS));
      Log(Self, _(TXT_CREATING_DIFFERENTIAL));

      Result := creatediff(dir, existingbasefilename, systemdevice);

      /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


      Exit;
    end;

    Timestamp := FormatDateTime('yyyy-mm-dd', Now);

    { MBR }
    mbrimagename := IncludeTrailingPathDelimiter(dir) + 'mbr_image_' + Timestamp + '.img';

    Log(Self, _(TXT_MBR_CREATING));

    if not CreateMBRImage(disk, mbrimagename, @Progress, @Log) then
    begin
      Log(Self, _(TXT_MBR_CREATE_ERROR));
      Exit;
    end;

    Log(Self, Format(_(TXT_MBR_CREATED), [mbrimagename]));

    { First partition = boot partition }
    if Pos('mmcblk', ExtractFileName(disk)) = 1 then
      bootdevice := disk + 'p1'
    else if Pos('nvme', ExtractFileName(disk)) = 1 then
      bootdevice := disk + 'p1'
    else
      bootdevice := disk + '1';

    if not DirectoryExists('/sys/class/block/' + ExtractFileName(bootdevice)) then
    begin
      Log(Self, Format(_(TXT_BOOT_PARTITION_NOT_FOUND), [bootdevice]));
      Exit;
    end;

    Log(Self, Format(_(TXT_BOOT_PARTITION), [bootdevice]));

    bootimagename := IncludeTrailingPathDelimiter(dir) + 'boot_image_' + Timestamp + '.zst';

    Log(Self, _(TXT_CREATING_FULL_BOOT_IMAGE));

    if not CreateFullCompressedImage(bootdevice, bootimagename, @Progress, @Log) then
    begin
      Log(Self, _(TXT_BOOT_IMAGE_CREATE_ERROR));
      Exit;
    end;

    Log(Self, Format(_(TXT_BOOT_IMAGE_CREATED), [bootimagename]));

    destname := CreateBaseDestName;

    if destname = '' then
      Exit;

    Log(Self, _(TXT_SYSTEM_IMAGE));

    if not CreateRawImage(systemdevice, destname, @Progress, @Log) then
    begin
      Log(Self, _(TXT_BASE_IMAGE_ERROR));
      Exit;
    end;

    Log(Self, _(TXT_BASE_IMAGE_CREATED));

    Result := True;
  finally
    Button4.Caption := '0.0 MB/s';
  end;

//  if Result then
//    Log(Self, _(TXT_ALL_IMAGES_SUCCESS));
//  end;

  if Result then
  begin
    Log(Self, _(TXT_SYNCING));
    RunCommand('sync',s);
    Log(Self, _(TXT_ALL_IMAGES_SUCCESS));
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

procedure updatelang;
begin
  with form1 do
  begin
    if radiocreate.Checked then
    begin
      Label1.Caption := _(TXT_SOURCEDRIVE);
      Label2.Caption := _(TXT_IMAGEFOLDER);
      ButtonStart.Caption := _(TXT_CREATE_IMAGE);
    end
    else
    begin
      Label1.Caption := _(TXT_TARGETDRIVE);
      Label2.Caption := _(TXT_IMAGE_FILE);
      ButtonStart.Caption := _(TXT_RESTORE_IMAGE);
    end;

    Label3.Caption := _(TXT_COMPRESSION_LEVEL);
    ButtonCancel.Caption := _(TXT_abort);
    button2.Caption := _(TXT_lang);
    button3.Caption := _(TXT_help);
    radiocreate.Caption := _(TXT_lang_create);
    radiorestore.Caption := _(TXT_lang_restore);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if CurrentLanguage = LANG_ENGLISH then
    CurrentLanguage := LANG_GERMAN
  else
    CurrentLanguage := LANG_ENGLISH;
  updatelang;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Form2.Show;
end;

procedure TForm1.ButtonCancelClick(Sender: TObject);
begin
  cancelrequested := True;
end;

procedure TForm1.cb_bootChange(Sender: TObject);
begin
  if cb_boot.Checked then
  begin
    combobox1.Text := '';
    GetImageSourcePartitions(ComboBox1);
  end;
end;

procedure TForm1.cb_mbrChange(Sender: TObject);
begin
  combobox1.Text := '';
  GetImageSourcePartitions(combobox1);
  if cb_mbr.Checked then
  begin
    GetImageSourcePartitions(ComboBox1);
  end;
end;

procedure TForm1.cb_systemChange(Sender: TObject);
begin
  if cb_system.Checked then
  begin
    combobox1.Text := '';
    GetImageSourcePartitions(ComboBox1);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveIni;
end;



procedure TForm1.ButtonStartClick(Sender: TObject);
var
Success, AnySelected, InvalidPartition: boolean;
S, TargetDevice, MBRFilename, Dir, ErrorMsg, InvalidPartitions: string;
MBR: TMbr;
DiskSectors, EndLBA: DWord;
I: integer;
begin
cancelrequested := False;
ButtonStart.Enabled := False;
LastProgressTime := 0;
Success := False;

try
if RadioCreate.Checked then
Success := CreateImg(ComboBox1.Text);

if RadioRestore.Checked then
begin
  AnySelected := cb_mbr.Checked or cb_boot.Checked or cb_system.Checked;

  if not AnySelected then
  begin
    Log(Self, _(TXT_PLEASE_SELECT_RESTORE_OPTION));
    Exit;
  end;

  TargetDevice := ExtractDevice(ComboBox1.Text);

  if TargetDevice = '' then
  begin
    Log(Self, _(TXT_DRIVE_NOT_SELECTED));
    Exit;
  end;

  S := _(TXT_SECURITY_QUERY) + LineEnding + LineEnding + _(TXT_WARNING) + LineEnding + LineEnding + _(TXT_TARGET_DRIVE_INFO) + LineEnding + '  ' + TargetDevice +
    LineEnding + LineEnding + _(TXT_DATA_WRITTEN_TO_DRIVE) + LineEnding + LineEnding;

  if cb_mbr.Checked then
    S := S + '  • ' + _(TXT_MBR) + LineEnding;

  if cb_boot.Checked then
    S := S + '  • ' + _(TXT_BOOT_PARTITION_NAME) + LineEnding;

  if cb_system.Checked then
    S := S + '  • ' + _(TXT_SYSTEM_PARTITION_NAME) + LineEnding;



    { Check whether invalid partitions will be removed from the MBR }
  InvalidPartitions := '';

  if cb_mbr.Checked and IsWholeDisk(TargetDevice) then
  begin
    Dir := ExtractFilePath(Trim(EditImage.Text));
    MBRFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'mbr_image_*.img');

    if (MBRFilename <> '') and FileExists(MBRFilename) then
    begin
      if Read_MBR(MBRFilename, ErrorMsg, MBR) then
      begin
        if RunCommand('blockdev --getsz ' + TargetDevice, S) and
           TryStrToDWord(Trim(S), DiskSectors) then
        begin
          for I := 1 to 4 do
          begin
            if MBR.PartitionEntries[I].PartitionSize > 0 then
            begin
              EndLBA := MBR.PartitionEntries[I].FirstLBA +
                MBR.PartitionEntries[I].PartitionSize;

              if EndLBA > DiskSectors then
                           InvalidPartitions := InvalidPartitions + 'Partition '+ IntToStr(I)+LineEnding;
            end;
          end;
        end;
      end;
    end;
  end;

  if InvalidPartitions <> '' then
  begin
    S := S + LineEnding + LineEnding + 'WARNING:' + LineEnding +
      _(txt_invalid_part_detected)+ LineEnding +
      InvalidPartitions +
      _(txt_invalid_remove)+
      LineEnding;
  end;


  S := S + LineEnding + _(TXT_EXISTING_DATA_OVERWRITTEN) + LineEnding + _(TXT_CONFIRM_CONTINUE);

  if MessageDlg(_(TXT_SECURITY_QUERY), S, mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Success := RestoreImg;
end;


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

Button4.Caption := '';
ButtonStart.Enabled := True;

if FCliMode then
begin
if Success then
ExitCode := 0
else
ExitCode := 1;
Application.Terminate;
end;

cancelrequested := False;
end;






function TForm1.RestoreImg: boolean;
var
  TargetDevice, Disk, BootDevice, SystemDevice, MountPoint, S: string;
  BaseFilename, DiffFilename, Dir, SourceFile: string;
  MBRFilename, BootFilename: string;
  I:integer;
begin
  Result := False;
  MountPoint := '';

  TargetDevice := Trim(extractdevice(ComboBox1.Text));

  if TargetDevice = '' then
  begin
    Log(Self, _(TXT_DRIVE_NOT_SELECTED));
    Exit;
  end;

  if not IsWholeDisk(TargetDevice) then
  begin
    Log(Self, _(TXT_COMPLETE_DISK_RESTORE));
    Exit;
  end;

  Disk := TargetDevice;

  if not DirectoryExists('/sys/class/block/' + ExtractFileName(Disk)) then
  begin
    Log(Self, Disk + ' ' + _(TXT_DOES_NOT_EXIST_RESTORE_SUSPENDED));
    Exit;
  end;

  { Determine first and second partition }
  if Pos('mmcblk', ExtractFileName(Disk)) = 1 then
  begin
    BootDevice := Disk + 'p1';
    SystemDevice := Disk + 'p2';
  end
  else if Pos('nvme', ExtractFileName(Disk)) = 1 then
  begin
    BootDevice := Disk + 'p1';
    SystemDevice := Disk + 'p2';
  end
  else
  begin
    BootDevice := Disk + '1';
    SystemDevice := Disk + '2';
  end;

  { Selected image must exist }
  DiffFilename := Trim(EditImage.Text);

  if DiffFilename = '' then
  begin
    Log(Self, _(TXT_IMAGE_FILE_NOT_SELECTED));
    Exit;
  end;

  if not FileExists(DiffFilename) then
  begin
    Log(Self, Format(_(TXT_IMAGE_FILE_NOT_EXIST), [DiffFilename]));
    Exit;
  end;

  Dir := ExtractFilePath(DiffFilename);

  if Dir = '' then
    Dir := IncludeTrailingPathDelimiter(GetCurrentDir);

  { Find base image }
  BaseFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + prefixbaseimage);

  { ------------------------------------------------------------ }
  { Check all required image files BEFORE starting restore }
  { ------------------------------------------------------------ }

  if CB_MBR.Checked then
  begin
    MBRFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'mbr_image_*.img');

    if MBRFilename = '' then
    begin
      Log(Self, Format(_(TXT_NO_MBR_IMAGE), [Dir]));
      Exit;
    end;

    if not FileExists(MBRFilename) then
    begin
      Log(Self, Format(_(TXT_MBR_IMAGE_NOT_EXIST), [MBRFilename]));
      Exit;
    end;
  end;

  if CB_Boot.Checked then
  begin
    BootFilename := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'boot_image_*.zst');

    if BootFilename = '' then
    begin
      Log(Self, Format(_(TXT_NO_BOOT_IMAGE), [Dir]));
      Exit;
    end;

    if not FileExists(BootFilename) then
    begin
      Log(Self, Format(_(TXT_BOOT_IMAGE_NOT_EXIST), [BootFilename]));
      Exit;
    end;
  end;

  if CB_System.Checked then
  begin
    if BaseFilename = '' then
    begin
      Log(Self, Format(_(TXT_NO_BASE_IMAGE), [Dir]));
      Exit;
    end;

    if not FileExists(BaseFilename) then
    begin
      Log(Self, Format(_(TXT_BASE_IMAGE_NOT_EXIST), [BaseFilename]));
      Exit;
    end;
  end;

  { If selected image is the base image, no differential image is needed }
  if BaseFilename = DiffFilename then
    DiffFilename := '';

  SourceFile := ExtractFileName(Trim(EditImage.Text));

  { ------------------------------------------------------------ }
  { Unmount system partition }
  { ------------------------------------------------------------ }

  if CB_System.Checked then
  begin
    RunCommand('findmnt -n -o TARGET ' + SystemDevice, MountPoint);
    MountPoint := Trim(MountPoint);

    if MountPoint = '/' then
    begin
      Log(Self, SystemDevice + ' ' + _(TXT_ROOT_RESTORE_SUSPENDED));
      Exit;
    end;

    if MountPoint <> '' then
    begin
      Log(Self, Format(_(TXT_UNMOUNTING), [SystemDevice, MountPoint]));
      RunCommand('umount ' + MountPoint, S);
      RunCommand('umount ' + SystemDevice, S);
    end;
  end;

  { ------------------------------------------------------------ }
  { 1. MBR }
  { ------------------------------------------------------------ }

  if CB_MBR.Checked then
  begin
    Log(Self, _(TXT_RESTORING_MBR));

    if not RestoreMBRImage then
    begin
      Log(Self, _(TXT_MBR_RESTORE_ERROR));
      Exit;
    end;

    Log(Self, _(TXT_MBR_RESTORED));

    { Give the kernel a chance to reread the partition table }
    RunCommand('partprobe ' + Disk, S);
    RunCommand('udevadm settle', S);

    { Wait up to 5 seconds for the selected partitions }
for I := 1 to 50 do
begin
  if (not CB_Boot.Checked or
      DirectoryExists('/sys/class/block/' + ExtractFileName(BootDevice))) and
     (not CB_System.Checked or
      DirectoryExists('/sys/class/block/' + ExtractFileName(SystemDevice))) then
    Break;

  Sleep(100);
  Application.ProcessMessages;
end;





    { Check selected partitions after MBR restore }
    if CB_Boot.Checked then
      if not DirectoryExists('/sys/class/block/' + ExtractFileName(BootDevice)) then
      begin
        Log(Self, Format(_(TXT_BOOT_PARTITION_NOT_FOUND), [BootDevice]));
        Exit;
      end;

    if CB_System.Checked then
      if not DirectoryExists('/sys/class/block/' + ExtractFileName(SystemDevice)) then
      begin
        Log(Self, Format(_(TXT_SYSTEM_PARTITION_NOT_FOUND), [SystemDevice]));
        Exit;
      end;
  end
  else
  begin
    { No MBR restore: partitions must already exist }
    if CB_Boot.Checked then
      if not DirectoryExists('/sys/class/block/' + ExtractFileName(BootDevice)) then
      begin
        Log(Self, Format(_(TXT_BOOT_PARTITION_NOT_FOUND), [BootDevice]));
        Exit;
      end;

    if CB_System.Checked then
      if not DirectoryExists('/sys/class/block/' + ExtractFileName(SystemDevice)) then
      begin
        Log(Self, Format(_(TXT_SYSTEM_PARTITION_NOT_FOUND), [SystemDevice]));
        Exit;
      end;
  end;

  { ------------------------------------------------------------ }
  { 2. Boot partition }
  { ------------------------------------------------------------ }

  if CB_Boot.Checked then
  begin
    Log(Self, Format(_(TXT_RESTORING_BOOT), [BootDevice]));

    if not RestoreFullCompressedImage(BootFilename, BootDevice, @Progress, @Log) then
    begin
      Log(Self, _(TXT_BOOT_RESTORE_ERROR));
      Exit;
    end;

    Log(Self, _(TXT_BOOT_RESTORED));
  end;

  { ------------------------------------------------------------ }
  { 3. System partition }
  { ------------------------------------------------------------ }

  if CB_System.Checked then
  begin
    Log(Self, Format(_(TXT_RESTORING_SYSTEM), [SystemDevice]));

    if not RestoreImage(SystemDevice, BaseFilename, DiffFilename, @Progress, @Log) then
    begin
      Log(Self, _(TXT_RESTORE_ERROR));
      Exit;
    end;

    Log(Self, _(TXT_SYSTEM_RESTORE_SUCCESS));
  end;

  Result := True;
  Log(Self, _(TXT_ALL_SELECTED_RESTORED));
end;



function TForm1.RestoreMBRImage: boolean;
var
  TargetDevice, MBRImage, Dir, ErrorMsg, S: string;
  MBR: TMbr;
  DiskSectors: DWord;
  I: integer;
  EndLBA:DWord;
  modified: boolean;
begin
  Result := False;

  TargetDevice := Trim(extractdevice(ComboBox1.Text));

  if TargetDevice = '' then
  begin
    Log(Self, _(TXT_DRIVE_NOT_SELECTED));
    Exit;
  end;

  if not IsWholeDisk(TargetDevice) then
  begin
    Log(Self, _(TXT_DEVICE_NOT_COMPLETE_DISK));
    Exit;
  end;

  Dir := ExtractFilePath(Trim(EditImage.Text));

  MBRImage := FileExistsWildcard(IncludeTrailingPathDelimiter(Dir) + 'mbr_image_');

  if MBRImage = '' then
  begin
    Log(Self, _(TXT_MBR_NOT_FOUND));
    Exit;
  end;

  { MBR-Image in den Speicher lesen }
  if not Read_MBR(MBRImage, ErrorMsg, MBR) then
  begin
    Log(Self, ErrorMsg);
    Exit;
  end;

  { Größe des Ziellaufwerks in Sektoren ermitteln }
  if not RunCommand('blockdev --getsz ' + TargetDevice, S) then
  begin
    Log(Self, 'Could not determine target drive size.');
    Exit;
  end;

  if not TryStrToDWord(Trim(S), DiskSectors) then
  begin
    Log(Self, 'Could not determine target drive size.');
    Exit;
  end;

  modified := False;

  { Partitionseinträge prüfen }
  for I := 1 to 4 do
  begin

    EndLBA := MBR.PartitionEntries[I].FirstLBA+MBR.PartitionEntries[I].PartitionSize;
    if EndLBA > DiskSectors then
    begin
      Log(Self, Format('Removing invalid partition %d from MBR.', [I]));
      FillChar(MBR.PartitionEntries[I], SizeOf(MBR.PartitionEntries[i]), 0);
      modified := True;
    end;
  end;

  { Korrigierten MBR aus dem Speicher direkt schreiben }
  try
    Write_MBR(MBR, TargetDevice);
  except
    on E: Exception do
    begin
      Log(Self, E.Message);
      Exit;
    end;
  end;

  RunCommand('sync', S);

  { Kernel soll die korrigierte Partitionstabelle einlesen }
  RunCommand('partprobe ' + TargetDevice, S);

  if modified then
    Log(Self, 'Invalid partitions were removed from MBR.');

  Log(Self, _(TXT_MBR_RESTORE_SUCCESS));
  Result := True;
end;





procedure TForm1.ComboBox1DropDown(Sender: TObject);
begin
  GetImageSourcePartitions(ComboBox1);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  cb_mbr.Visible := False;
  cb_system.Visible := False;
  cb_boot.Visible := False;

  Form1.Caption := f_caption + ' ' + version;
  Button4.Caption := '';
  RadioRestore.Checked := False;
  RadioCreate.Checked := True;

  FCliMode := ParamCount > 0;

  if FCliMode then
  begin
    Application.ShowMainForm := False;
    Hide;
    ProcessCommandLine;
  end
  else
  begin
    ReadIni;
  end;
 // Button2Click(Self);
  Button1.Caption := '▼';
  if not FCliMode then
  begin
    ComboBox1.Text := createdevice;
    EditImage.Text := createfolder;
  end;
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
    updatelang;
    SaveIni;
    EditImage.Text := createfolder;
    ComboBox1.Text := createdevice;
    cb_mbr.Visible := False;
    cb_boot.Visible := False;
    cb_system.Visible := False;
  end;
end;



procedure TForm1.RadioRestoreChange(Sender: TObject);
begin
  if RadioRestore.Checked then
  begin
//    ButtonStart.Caption := _(TXT_RESTORE_IMAGE);

 updatelang;
    SaveIni;
    EditImage.Text := restorefilename;
    ComboBox1.Text := restoredevice;
    cb_mbr.Visible := True;
    cb_boot.Visible := True;
    cb_system.Visible := True;
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
    updatelang;
  finally
    ini.Free;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if not FCliMode then
    CheckForUpdates(Memo1);
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

procedure TForm1.ProcessCommandLine;
begin
  FCliCreate := False;
  FCliRestore := False;
  FCliStart := False;
  FCliHide := True;
  FCliCreateDestination := True;
  FCliDestinationSpecified := True;

  if FPGetUID <> 0 then
  begin
    WriteLn('Error: PiExt must be started with sudo.');
    WriteLn('Usage: sudo piext <drive> <destination-folder>');
    Exit;
  end;

  if ParamCount <> 2 then
  begin
    WriteLn('Usage: sudo piext <drive> <destination-folder>');
    WriteLn('Example: sudo piext /dev/sda /backup/piext');
    Exit;
  end;

  createdevice := ParamStr(1);
  createfolder := ParamStr(2);

  ComboBox1.Text := createdevice;
  EditImage.Text := createfolder;
  RadioCreate.Checked := True;

  FCliCreate := True;
  FCliStart := True;

  Application.ShowMainForm := False;
  Hide;
end;

end.

