unit ImageUtils;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows,Dialogs,zstd,language,forms;


type
  TDiskExtent = record
    DiskNumber: DWORD;
    StartingOffset: LARGE_INTEGER;
    ExtentLength: LARGE_INTEGER;
  end;

  TVolumeDiskExtents = record
    NumberOfDiskExtents: DWORD;
    Extents: array[0..15] of TDiskExtent;
  end;


  type
  TMBRPartition = packed record
    BootFlag: byte;         // 0x0 Bootflag
    StartHead: byte;        // 0x1 Kopf, an dem die Partition anfängt
    StartSectorCylinder: byte; // 0x2 Anfangssektor und Bits des Anfangszylinders
    StartCylinder: byte;    // 0x3 Zylinderbeginn
    PartitionType: byte;    // 0x4 Partitions-Typ
    EndHead: byte;          // 0x5 Kopf, an dem die Partition endet
    EndSectorCylinder: byte; // 0x6 Letzter Sektor und Bits des Endzylinders
    EndCylinder: byte;      // 0x7 Zylinderende
    FirstLBA: DWORD;        // 0x8 LBA Nummer des ersten Sektors (32-Bit)
    PartitionSize: DWORD;   // 0xC Länge der Partition in Sektoren (32-Bit)
  end;


  TMBR = packed record
    BootCode: array[0..439] of byte;          // 0x000–0x1B7
    DiskSignature: DWORD;                     // 0x1B8–0x1BB
    Reserved: word;                           // 0x1BC–0x1BD (muss 0)
    PartitionEntries: array[1..4] of TMBRPartition; // 0x1BE–0x1FD
    Signature: word;                          // 0x1FE–0x1FF (muss $AA55)
   end;


  type
  TStoragePropertyQuery = record
    PropertyId: DWORD;
    QueryType: DWORD;
    AdditionalParameters: array[0..0] of Byte;
  end;

  PStorageDeviceDescriptor = ^TStorageDeviceDescriptor;
  TStorageDeviceDescriptor = record
    Version: DWORD;
    Size: DWORD;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Byte;
    CommandQueueing: Byte;
    VendorIdOffset: DWORD;
    ProductIdOffset: DWORD;
    ProductRevisionOffset: DWORD;
    SerialNumberOffset: DWORD;
    BusType: DWORD;
    RawPropertiesLength: DWORD;
  end;

const
  StorageDeviceProperty = 0;
  PropertyStandardQuery = 0;

  IOCTL_STORAGE_QUERY_PROPERTY = $002D1400;

  BusTypeScsi  = 1;
  BusTypeAta   = 3;
  BusType1394  = 4;
  BusTypeUsb   = 7;
  BusTypeRAID  = 8;
  BusTypeSata  = 11;
  BusTypeSd    = 12;
  BusTypeMmc   = 13;
  BusTypeNvme  = 17;



type
  TProgressEvent = procedure(Sender: TObject; Position, Total: Int64) of object;
  TLogEvent = procedure(Sender: TObject; const Msg: string) of object;

procedure LogMsg(const Msg: string; OnLog: TLogEvent);
function PhysicalDriveExists(const DriveName: string): Boolean;
function GetPhysicalDriveSize(const DriveName: string): UInt64;
function IsSystemDrive(const DriveName: string): Boolean;
function GetDriveLetters(DriveNo: Integer): string;
function Read_MBR(const Filename: string; out ErrorMsg: string; out MBR: TMbr): Boolean;
function FileExistsWildcard(const FilePattern: string): string;
procedure Write_MBR(const MBR: TMbr; const DriveName: string);
function LockAndDismountVolume(const VolumeName: string; out VolumeHandle: THandle): Boolean;
function LockAndDismountDrivePartitions(DriveNo: Integer): Boolean;
procedure UnlockDrivePartitions;
function GetPhysicalDriveNumber(const Device: string): Integer;
function RestoreBootImage(const ImageFile, Device: string; mbr:tmbr;OnProgress: TProgressEvent; OnLog: TLogEvent): Boolean;
function ReadMBRFromTarget(const Device: string;var MBR:Tmbr): Boolean;
function GetPhysicalDriveInfo(const DriveName: string): string;




var
  cancelrequested: Boolean = False;
   RawImageBytesProcessed:qword;

const
  IOCTL_DISK_GET_LENGTH_INFO = $0007405C;
  IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS = $00560000;
  FSCTL_LOCK_VOLUME     = DWORD($00090018);
  FSCTL_UNLOCK_VOLUME   = DWORD($0009001C);
  FSCTL_DISMOUNT_VOLUME = DWORD($00090020);

implementation


var
  LockedVolumeHandles: array of THandle;

  function GetLogicalDriveLetters: TStringList;
  var
    Buffer: array[0..1023] of Char;
    P: PChar;
  begin
    Result := TStringList.Create;
    if GetLogicalDriveStrings(SizeOf(Buffer), Buffer) = 0 then
      Exit;

    P := Buffer;
    while P^ <> #0 do
    begin
      Result.Add(Copy(P, 1, 2));
      Inc(P, StrLen(P) + 1);
    end;
  end;


function ReadMBRFromTarget(const Device: string; var MBR:Tmbr): Boolean;
var
  H: THandle;
  BytesRead: DWORD;
begin
  Result := False;

  h := Windows.CreateFile(PChar(Device), GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE, nil,OPEN_EXISTING, 0, 0);

  if H = INVALID_HANDLE_VALUE then Exit;

  try
    if not SetFilePointerEx(H, 0, nil, FILE_BEGIN) then  Exit;

    BytesRead := 0;
    if not Windows.ReadFile(H, MBR, 512, BytesRead, nil) then  Exit;

    if BytesRead <> 512 then  Exit;

    Result := mbr.Signature=$aa55;
  finally
    Windows.CloseHandle(H);
  end;
end;



  function GetPhysicalDriveNumber(const Device: string): Integer;
var
  S: string;
begin
  Result := -1;
  S := Trim(Device);

  if Pos('\\.\PhysicalDrive', S) <> 1 then
    Exit;

  Delete(S, 1, Length('\\.\PhysicalDrive'));

  if (S = '') or (Pos(' ', S) > 0) then
    Exit;

  if not TryStrToInt(S, Result) then
    Result := -1;
end;



  function LockAndDismountDrivePartitions(DriveNo: Integer): Boolean;
  var
    Buffer: array[0..1023] of Char;
    BufferLength: DWORD;
    P: PChar;
    VolumePath, DriveLetter: string;
    H: THandle;
    Extents: TVolumeDiskExtents;
    BytesReturned: DWORD;
    Found, Locked: Boolean;
    ErrorCode: DWORD;
  begin
    Result := False;
    UnlockDrivePartitions;

    FillChar(Buffer, SizeOf(Buffer), 0);
    BufferLength := GetLogicalDriveStrings(SizeOf(Buffer), PChar(@Buffer[0]));

    if (BufferLength = 0) or (BufferLength >= SizeOf(Buffer)) then
    begin
      LogMsg(Format(_(TXT_VOLUME_LETTERS_ERROR), [SysErrorMessage(GetLastError)]), nil);
      Exit;
    end;

    P := PChar(@Buffer[0]);

    while P^ <> #0 do
    begin
      DriveLetter := Copy(P, 1, 2);
      VolumePath := '\\.\' + DriveLetter;

      H := Windows.CreateFile(PChar(VolumePath),
        GENERIC_READ or GENERIC_WRITE,
        FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil, OPEN_EXISTING, 0, 0);

      if H <> INVALID_HANDLE_VALUE then
      begin
        FillChar(Extents, SizeOf(Extents), 0);
        BytesReturned := 0;

        Found := DeviceIoControl(H,
          IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS,
          nil, 0, @Extents, SizeOf(Extents),
          BytesReturned, nil);

        if Found and (Extents.NumberOfDiskExtents > 0) and
          (Extents.Extents[0].DiskNumber = DWORD(DriveNo)) then
        begin
          BytesReturned := 0;
          Locked := DeviceIoControl(H, FSCTL_LOCK_VOLUME,
            nil, 0, nil, 0, BytesReturned, nil);

          if not Locked then
          begin
            ErrorCode := GetLastError;
            LogMsg(Format(_(TXT_VOLUME_LOCK_ERROR), [DriveLetter, SysErrorMessage(ErrorCode)]), nil);
            Windows.CloseHandle(H);
            UnlockDrivePartitions;
            Exit;
          end;

          SetLength(LockedVolumeHandles, Length(LockedVolumeHandles) + 1);
          LockedVolumeHandles[High(LockedVolumeHandles)] := H;

          BytesReturned := 0;
          if not DeviceIoControl(H, FSCTL_DISMOUNT_VOLUME,
            nil, 0, nil, 0, BytesReturned, nil) then
          begin
            ErrorCode := GetLastError;
            LogMsg(Format(_(TXT_VOLUME_DISMOUNT_ERROR), [DriveLetter, SysErrorMessage(ErrorCode)]), nil);
            UnlockDrivePartitions;
            Exit;
          end;
        end
        else
          Windows.CloseHandle(H);
      end;

      Inc(P, StrLen(P) + 1);
    end;

    Result := True;
  end;




procedure UnlockDrivePartitions;
var
  I: Integer;
  BytesReturned: DWORD;
begin
  for I := High(LockedVolumeHandles) downto 0 do
  begin
    if LockedVolumeHandles[I] <> INVALID_HANDLE_VALUE then
    begin
      BytesReturned := 0;
      DeviceIoControl(LockedVolumeHandles[I], FSCTL_UNLOCK_VOLUME,
        nil, 0, nil, 0, BytesReturned, nil);
      Windows.CloseHandle(LockedVolumeHandles[I]);
    end;
  end;

  SetLength(LockedVolumeHandles, 0);
end;




function LockAndDismountVolume(const VolumeName: string;
  out VolumeHandle: THandle): Boolean;
var
  BytesReturned: DWORD;
begin
  Result := False;
  VolumeHandle := INVALID_HANDLE_VALUE;

  VolumeHandle := CreateFile(
    PChar(VolumeName),
    GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil,
    OPEN_EXISTING,
    0,
    0
  );

  if VolumeHandle = INVALID_HANDLE_VALUE then
    Exit;

  if not DeviceIoControl(VolumeHandle, FSCTL_LOCK_VOLUME,
    nil, 0, nil, 0, BytesReturned, nil) then
  begin
    CloseHandle(VolumeHandle);
    VolumeHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  if not DeviceIoControl(VolumeHandle, FSCTL_DISMOUNT_VOLUME,
    nil, 0, nil, 0, BytesReturned, nil) then
  begin
    DeviceIoControl(VolumeHandle, FSCTL_UNLOCK_VOLUME,
      nil, 0, nil, 0, BytesReturned, nil);
    CloseHandle(VolumeHandle);
    VolumeHandle := INVALID_HANDLE_VALUE;
    Exit;
  end;

  Result := True;
end;




function RestoreBootImage(const ImageFile, Device: string;mbr:tmbr; OnProgress: TProgressEvent; OnLog: TLogEvent): Boolean;
const
  INPUT_BUFFER_SIZE = 1 * 1024 * 1024;
  OUTPUT_BUFFER_SIZE = 32 * 1024 * 1024;
  IOCTL_DISK_GET_DRIVE_GEOMETRY = $00070000;
type
  TDiskGeometryInfo = packed record
    Cylinders: Int64;
    MediaType: DWORD;
    TracksPerCylinder: DWORD;
    SectorsPerTrack: DWORD;
    BytesPerSector: DWORD;
  end;
var
  InFile, OutFile, GeometryHandle: THandle;
  InputBuffer, OutputBuffer, PendingBuffer: TBytes;
  Input: TZSTD_inBuffer;
  Output: TZSTD_outBuffer;
  TotalWritten: Int64;
  BytesRead, BytesWritten, Remaining: DWORD;
  WritePtr: PByte;
  Ret: NativeUInt;
  DCtx: TZSTD_DCtx;
  Finished: Boolean;
  NewPosition: LARGE_INTEGER;
  Geometry: TDiskGeometryInfo;
  BytesReturned: DWORD;
  SectorSize: Integer;
  PendingSize, CombinedSize, AlignedSize: Integer;
  WriteOffset: Int64;

  partitionoffset,partitionsize:int64;

begin
  Result := False;
  InFile := INVALID_HANDLE_VALUE;
  OutFile := INVALID_HANDLE_VALUE;
  GeometryHandle := INVALID_HANDLE_VALUE;
  DCtx := nil;
  TotalWritten := 0;
  PendingSize := 0;
  RawImageBytesProcessed := 0;
  partitionoffset:=mbr.PartitionEntries[1].FirstLBA*512;
  partitionsize:=mbr.PartitionEntries[1].PartitionSize*512;

  try
    try
      if (PartitionOffset < 0) or (PartitionSize <= 0) then
      begin
        LogMsg(_(TXT_INVALID_PARTITION_OFFSET_SIZE), OnLog);
        Exit;
      end;

      InFile := Windows.CreateFile(PChar(ImageFile), GENERIC_READ,
        FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

      if InFile = INVALID_HANDLE_VALUE then
      begin
        LogMsg(Format(_(TXT_IMAGE_FILE_OPEN_ERROR), [ImageFile, SysErrorMessage(GetLastError)]), OnLog);
        Exit;
      end;

      GeometryHandle := Windows.CreateFile(PChar(Device), GENERIC_READ,
        FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

      if GeometryHandle = INVALID_HANDLE_VALUE then
      begin
        LogMsg(Format(_(TXT_DRIVE_GEOMETRY_ERROR), [SysErrorMessage(GetLastError)]), OnLog);
        Exit;
      end;

      FillChar(Geometry, SizeOf(Geometry), 0);
      BytesReturned := 0;

      if not DeviceIoControl(GeometryHandle,
        IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0,
        @Geometry, SizeOf(Geometry), BytesReturned, nil) then
      begin
        LogMsg(Format(_(TXT_SECTOR_SIZE_QUERY_ERROR), [SysErrorMessage(GetLastError)]), OnLog);
        Exit;
      end;

      SectorSize := Geometry.BytesPerSector;

      if (SectorSize <= 0) or
         ((SectorSize and (SectorSize - 1)) <> 0) then
      begin
        LogMsg(_(TXT_INVALID_LOGICAL_SECTOR_SIZE), OnLog);
        Exit;
      end;

      Windows.CloseHandle(GeometryHandle);
      GeometryHandle := INVALID_HANDLE_VALUE;

      OutFile := Windows.CreateFile(PChar(Device), GENERIC_WRITE,
        FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

      if OutFile = INVALID_HANDLE_VALUE then
      begin
        LogMsg(Format(_(TXT_TARGET_DRIVE_OPEN_ERROR2), [Device, SysErrorMessage(GetLastError)]), OnLog);
        Exit;
      end;

      NewPosition.QuadPart := PartitionOffset;

      if not SetFilePointerEx(OutFile, NewPosition, nil, FILE_BEGIN) then
      begin
        LogMsg(Format(_(TXT_PARTITION_OFFSET_SET_ERROR), [SysErrorMessage(GetLastError)]), OnLog);
        Exit;
      end;

      if (PartitionOffset mod SectorSize) <> 0 then
      begin
        LogMsg(_(TXT_PARTITION_OFFSET_ALIGNMENT), OnLog);
        Exit;
      end;

      DCtx := ZSTD_createDCtx();

      if DCtx = nil then
      begin
        LogMsg(_(TXT_BASE_DECODER_ERROR), OnLog);
        Exit;
      end;

      SetLength(InputBuffer, INPUT_BUFFER_SIZE);
      SetLength(OutputBuffer, OUTPUT_BUFFER_SIZE);
      SetLength(PendingBuffer, OUTPUT_BUFFER_SIZE + SectorSize);

      FillChar(Input, SizeOf(Input), 0);
      FillChar(Output, SizeOf(Output), 0);

      Input.src := @InputBuffer[0];
      Input.size := 0;
      Input.pos := 0;

      Finished := False;

      while not Finished do
      begin
        if terminate_all then
          raise Exception.Create(_(TXT_OPERATION_CANCELLED));

        if Input.pos >= Input.size then
        begin
          if not Windows.ReadFile(InFile, InputBuffer[0],
            DWORD(Length(InputBuffer)), BytesRead, nil) then
          begin
            LogMsg(Format(_(TXT_IMAGE_READ_ERROR), [SysErrorMessage(GetLastError)]), OnLog);
            Exit;
          end;

          if BytesRead = 0 then
          begin
            LogMsg(_(TXT_BASE_EOF), OnLog);
            Exit;
          end;

          Input.src := @InputBuffer[0];
          Input.size := BytesRead;
          Input.pos := 0;
        end;

        Output.dst := @OutputBuffer[0];
        Output.size := Length(OutputBuffer);
        Output.pos := 0;

        Ret := ZSTD_decompressStream(DCtx, Output, Input);

        if ZSTD_isError(Ret) <> 0 then
        begin
          LogMsg(_(TXT_ZSTD_COMPRESSION_ERROR) + ': ' +
            StrPas(ZSTD_getErrorName(Ret)), OnLog);
          Exit;
        end;

        if Output.pos > 0 then
        begin
          CombinedSize := PendingSize + Integer(Output.pos);

          if TotalWritten + Int64(CombinedSize) > PartitionSize then
          begin
            LogMsg(_(TXT_IMAGE_TOO_LARGE), OnLog);
            Exit;
          end;

          Move(OutputBuffer[0], PendingBuffer[PendingSize], Output.pos);

          AlignedSize := (CombinedSize div SectorSize) * SectorSize;

          if AlignedSize > 0 then
          begin
            WritePtr := @PendingBuffer[0];
            Remaining := DWORD(AlignedSize);
            WriteOffset := TotalWritten;

            while Remaining > 0 do
            begin
              application.ProcessMessages;

              if cancelrequested then
                   begin
                    LogMsg( _(TXT_OPERATION_CANCELLED), OnLog);
                    exit;
                   end;

              if not Windows.WriteFile(OutFile, WritePtr^,
                Remaining, BytesWritten, nil) then
              begin
                LogMsg(Format(_(TXT_WRITE_ERROR_DETAIL),[GetLastError, SysErrorMessage(GetLastError), Device, PartitionOffset +
                                      WriteOffset, Remaining]), OnLog);
                Exit;
              end;

              if BytesWritten = 0 then
              begin
                LogMsg(_(TXT_NO_DATA_WRITTEN), OnLog);
                Exit;
              end;

              if (BytesWritten mod DWORD(SectorSize)) <> 0 then
              begin
                LogMsg(_(TXT_INCOMPLETE_SECTOR_WRITE), OnLog);
                Exit;
              end;

              Inc(WritePtr, BytesWritten);
              Inc(WriteOffset, BytesWritten);
              Dec(Remaining, BytesWritten);
            end;

            Inc(TotalWritten, Int64(AlignedSize));
            RawImageBytesProcessed := TotalWritten;

            if Assigned(OnProgress) then
              OnProgress(nil, TotalWritten, PartitionSize);

            PendingSize := CombinedSize - AlignedSize;

            if PendingSize > 0 then
              Move(PendingBuffer[AlignedSize], PendingBuffer[0], PendingSize);
          end
          else
            PendingSize := CombinedSize;
        end;

        if Ret = 0 then
          Finished := True;
      end;

      if PendingSize <> 0 then
      begin
        LogMsg(_(TXT_INCOMPLETE_FINAL_SECTOR), OnLog);
        Exit;
      end;

      if TotalWritten <> PartitionSize then
      begin
        LogMsg(Format(
          _(TXT_IMAGE_PARTITION_SIZE_MISMATCH),
          [TotalWritten, PartitionSize]), OnLog);
        Exit;
      end;

      if not Windows.FlushFileBuffers(OutFile) then
      begin
        LogMsg(Format(_(TXT_FLUSH_FAILED), [SysErrorMessage(GetLastError)]), OnLog);
        Exit;
      end;

      LogMsg(Format(_(TXT_BOOT_PARTITION_WRITTEN), [ImageFile]), OnLog);
      Result := True;

    except
      on E: Exception do
      begin
        LogMsg(Format(_(TXT_BOOT_RESTORE_ERROR_DETAIL), [E.Message]), OnLog);
        Result := False;
      end;
    end;
  finally
    if DCtx <> nil then
      ZSTD_freeDCtx(DCtx);

    if OutFile <> INVALID_HANDLE_VALUE then
      Windows.CloseHandle(OutFile);

    if GeometryHandle <> INVALID_HANDLE_VALUE then
      Windows.CloseHandle(GeometryHandle);

    if InFile <> INVALID_HANDLE_VALUE then
      Windows.CloseHandle(InFile);
  end;
end;




function FileExistsWildcard(const FilePattern: string): string;
var
  SR: TSearchRec;
  R: Integer;
begin
  Result := '';

  R := FindFirst(FilePattern, faAnyFile, SR);
  if R = 0 then
  begin
    try
      repeat
        if ((SR.Attr and faDirectory) = 0) and
           (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          Result := IncludeTrailingPathDelimiter(
            ExtractFilePath(FilePattern)) + SR.Name;
          Break;
        end;

        R := FindNext(SR);
      until R <> 0;
    finally
      SysUtils.FindClose(SR);
    end;
  end;
end;


function Read_MBR(const Filename: string; out ErrorMsg: string; out MBR: TMbr): Boolean;
var
  FS: TFileStream;
  n:integer;
begin
  Result := False;
  ErrorMsg := '';
  try
    FS := TFileStream.Create(Filename, fmOpenRead or fmShareDenyNone);
    try
      if  FS.Size < SizeOf(tMBR) then
      begin
        ErrorMsg := Format(_(TXT_MBR_IMAGE_TOO_SMALL_DE), [Filename]);
        Exit;
      end;
      FS.ReadBuffer(MBR, SizeOf(MBR));
      Result := True;
    finally
      FS.Free;
    end;
  except
    on E: Exception do
      ErrorMsg := E.Message;
  end;
end;


procedure Write_MBR(const MBR: TMbr; const DriveName: string);
var
  H: THandle;
  BytesWritten: DWORD;
begin
  H := Windows.CreateFile(PChar(DriveName), GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
    OPEN_EXISTING, 0, 0);

  if H = INVALID_HANDLE_VALUE then
    raise Exception.Create(Format(_(TXT_CANNOT_OPEN_TARGET_DRIVE), [DriveName, SysErrorMessage(GetLastError)]));

  try
    if not WriteFile(H, MBR, SizeOf(MBR), BytesWritten, nil) then
      raise Exception.Create(Format(_(TXT_ERROR_WRITING_MBR), [SysErrorMessage(GetLastError)]));

    if BytesWritten <> SizeOf(MBR) then
      raise Exception.Create(_(TXT_MBR_INCOMPLETE_WRITE));
  finally
    CloseHandle(H);
  end;
end;


procedure LogMsg(const Msg: string; OnLog: TLogEvent);
begin
  if Assigned(OnLog) and not cancelrequested then
    OnLog(nil, Msg);
end;


function GetDriveLetters(DriveNo: Integer): string;
var
  I: Integer;
  RootPath, VolumePath: string;
  H: THandle;
  Extents: TVolumeDiskExtents;
  BytesReturned: DWORD;
  Found: Boolean;
begin
  Result := '';
  for I := Ord('A') to Ord('Z') do
  begin
    RootPath := Chr(I) + ':\';
    if GetDriveType(PChar(RootPath)) = DRIVE_NO_ROOT_DIR then
      Continue;

    VolumePath := '\\.\' + Chr(I) + ':';
    H := Windows.CreateFile(PChar(VolumePath), 0,
      FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
      OPEN_EXISTING, 0, 0);

    if H = INVALID_HANDLE_VALUE then
      Continue;

    try
      FillChar(Extents, SizeOf(Extents), 0);
      Found := DeviceIoControl(H,
        IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS,
        nil, 0, @Extents, SizeOf(Extents),
        BytesReturned, nil);

      if Found and (Extents.NumberOfDiskExtents > 0) then
        if Extents.Extents[0].DiskNumber = DWORD(DriveNo) then
        begin
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + Chr(I) + ':';
        end;
    finally
      CloseHandle(H);
    end;
  end;

  if Result = '' then
    Result := _(TXT_NO_DRIVE_LETTERS);
end;


function PhysicalDriveExists(const DriveName: string): Boolean;
var
H: THandle;
begin
H := CreateFile(
PChar(DriveName),
0,
FILE_SHARE_READ or FILE_SHARE_WRITE,
nil,
OPEN_EXISTING,
0,
0
);
Result := H <> INVALID_HANDLE_VALUE;
if Result then
CloseHandle(H);
end;

function IsSystemDrive(const DriveName: string): Boolean;
var
  H: THandle;
  Extents: TVolumeDiskExtents;
  BytesReturned: DWORD;
  DriveNo: Integer;
  I: Integer;
begin
  Result := False;

  DriveNo := StrToIntDef(
    Copy(DriveName, Length('\\.\PhysicalDrive') + 1, 10), -1);

  if DriveNo < 0 then Exit;

  H := Windows.CreateFile('\\.\C:', 0,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
    OPEN_EXISTING, 0, 0);

  if H = INVALID_HANDLE_VALUE then Exit;

  try
    if DeviceIoControl(H, IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS,
      nil, 0, @Extents, SizeOf(Extents), BytesReturned, nil) then
      for I := 0 to Integer(Extents.NumberOfDiskExtents) - 1 do
        if Extents.Extents[I].DiskNumber = DWORD(DriveNo) then
        begin
          Result := True;
          Exit;
        end;
  finally
    CloseHandle(H);
  end;
end;



function GetPhysicalDriveSize(const DriveName: string): UInt64;
var
  H: THandle;
  LengthInfo: GET_LENGTH_INFORMATION;
  BytesReturned: DWORD;
begin
  Result := 0;

  H := Windows.CreateFile(PChar(DriveName),   GENERIC_READ,  //     0,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
    OPEN_EXISTING, 0, 0);

  if H = INVALID_HANDLE_VALUE then
  begin
    ShowMessage(Format(_(TXT_DRIVE_SIZE_CREATEFILE_ERROR), [DriveName, SysErrorMessage(GetLastError)]));
    Exit;
  end;

  try
    if not DeviceIoControl(H, IOCTL_DISK_GET_LENGTH_INFO, nil, 0,
      @LengthInfo, SizeOf(LengthInfo), BytesReturned, nil) then
    begin
      ShowMessage(Format(_(TXT_DRIVE_SIZE_IOCTL_ERROR), [DriveName, SysErrorMessage(GetLastError)]));
      Exit;
    end;

    Result := UInt64(LengthInfo.Length.QuadPart);
  finally
    CloseHandle(H);
  end;
end;



function GetPhysicalDriveInfo(const DriveName: string): string;
var
  H: THandle;
  Query: TStoragePropertyQuery;
  Buffer: array[0..1023] of Byte;
  BytesReturned: DWORD;
  Desc: PStorageDeviceDescriptor;
  Vendor, Product, Bus: string;

  function ReadString(Offset: DWORD): string;
  begin
    Result := '';

    if (Offset = 0) or (Offset >= BytesReturned) then
      Exit;

    Result := Trim(PChar(@Buffer[Offset]));
  end;

begin
  Result := '';

  H := CreateFile(
    PChar(DriveName),
    0,
    FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil,
    OPEN_EXISTING,
    0,
    0
  );

  if H = INVALID_HANDLE_VALUE then
    Exit;

  try
    FillChar(Query, SizeOf(Query), 0);

    Query.PropertyId := StorageDeviceProperty;
    Query.QueryType := PropertyStandardQuery;

    FillChar(Buffer, SizeOf(Buffer), 0);
    BytesReturned := 0;

    if not DeviceIoControl(
      H,
      IOCTL_STORAGE_QUERY_PROPERTY,
      @Query,
      SizeOf(Query),
      @Buffer[0],
      SizeOf(Buffer),
      BytesReturned,
      nil
    ) then
      Exit;

    if BytesReturned < SizeOf(TStorageDeviceDescriptor) then
      Exit;

    Desc := PStorageDeviceDescriptor(@Buffer[0]);

    Vendor := ReadString(Desc^.VendorIdOffset);
    Product := ReadString(Desc^.ProductIdOffset);

    case Desc^.BusType of
      BusTypeUsb:  Bus := 'USB';
      BusTypeSata: Bus := 'SATA';
      BusTypeNvme: Bus := 'NVMe';
      BusTypeAta:  Bus := 'ATA';
      BusTypeScsi: Bus := 'SCSI';
      BusTypeSd:   Bus := 'SD';
      BusTypeMmc:  Bus := 'MMC';
      BusType1394: Bus := 'FireWire';
      BusTypeRAID: Bus := 'RAID';
    else
      Bus := 'Unknown';
    end;

    Result := Trim(Vendor + ' ' + Product);

    if Bus <> '' then
      Result := Result + ' [' + Bus + ']';

  finally
    CloseHandle(H);
  end;
end;


end.
