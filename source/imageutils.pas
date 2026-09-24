unit Imageutils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,unix,baseunix;


type
  TExt4Info = record
    BlockSize: UInt32;
    BlockCount: UInt64;
    BlocksPerGroup: UInt32;
    GroupCount: UInt32;
    FirstDataBlock: UInt32;
    DescSize: UInt16;
    Is64Bit: Boolean;
  end;

type
  TProgressEvent = procedure(Sender: TObject; Position, Total: Int64) of object;
  TLogEvent = procedure(Sender: TObject; const Msg: string) of object;

function GetDeviceSize(const Device: string; out Size: Int64): Boolean;
function GetFileSize64(const FileName: string; out Size: Int64): Boolean;
function ReadExact(FD: Integer; var Buffer; Count: SizeInt; out ErrorCode: Integer): Boolean;
function WriteExact(FD: Integer; var Buffer; Count: SizeInt; out ErrorCode: Integer): Boolean;
function GetCPUCount: Integer;
function CreateUsedBitmap(const Device, BitmapFile: string;OnProgress: TProgressEvent;OnLog: TLogEvent): Boolean;
procedure LogMsg(const Msg: string; OnLog: TLogEvent);

var
  RawImageBytesProcessed: Int64 = 0;
  cancelrequested:boolean=false;

implementation

uses
  ext4bitmap, Language,unit1;


procedure LogMsg(const Msg: string; OnLog: TLogEvent);
begin
  if Assigned(OnLog) and (not cancelrequested) then
    OnLog(nil, Msg);
end;



function GetDeviceSize(const Device: string; out Size: Int64): Boolean;
const
  BLKGETSIZE64 = $80081272;
var
  FD: Integer;
begin
  Result := False;
  Size := 0;

  FD := fpOpen(PChar(Device), O_RDONLY);
  if FD < 0 then Exit;

  try
    if fpIOCtl(FD, BLKGETSIZE64, @Size) = 0 then
      Result := Size > 0;
  finally
    fpClose(FD);
  end;
end;

function GetFileSize64(const FileName: string; out Size: Int64): Boolean;
var
  St: Stat;
begin
  Result := False;
  Size := 0;

  if fpStat(PChar(FileName), St) <> 0 then Exit;

  Size := St.st_size;
  Result := True;
end;


function ReadExact(FD: Integer; var Buffer; Count: SizeInt; out ErrorCode: Integer): Boolean; inline;
var
  P: PByte;
  Done: SizeInt;
  N: ssize_t;
begin
  Result := False;
  ErrorCode := 0;

  if Count <= 0 then
  begin
    Result := True;
    Exit;
  end;

  P := @Buffer;
  Done := 0;

  while Done < Count do
  begin
    if cancelrequested then exit;

       //  raise Exception.Create(_(TXT_CANCELLED));

     // Log(Self, _(TXT_CANCELLED));

   N := fpRead(FD, P^, Count - Done);

    if N < 0 then
    begin
      ErrorCode := fpGetErrno;
      Exit;
    end;

    if N = 0 then
      Exit;

    Inc(P, N);
    Inc(Done, N);
  end;

  Result := True;
end;


function WriteExact(FD: Integer; var Buffer; Count: SizeInt; out ErrorCode: Integer): Boolean; inline;
var
  P: PByte;
  Done: SizeInt;
  N: ssize_t;
begin
  Result := False;
  ErrorCode := 0;

  if Count <= 0 then
  begin
    Result := True;
    Exit;
  end;

  P := @Buffer;
  Done := 0;

  while Done < Count do
  begin
     if cancelrequested then exit;

    N := fpWrite(FD, P^, Count - Done);

    if N < 0 then
    begin
      ErrorCode := fpGetErrno;
      Exit;
    end;

    if N = 0 then
      Exit;

    Inc(P, N);
    Inc(Done, N);
  end;

  Result := True;
end;


function GetCPUCount: Integer;
var
  F: TextFile;
  Line: string;
begin
  Result := 0;
  AssignFile(F, '/proc/cpuinfo');
  try
    Reset(F);
    try
      while not EOF(F) do
      begin
        ReadLn(F, Line);
        if Pos('processor', Line) = 1 then
          Inc(Result);
      end;
    finally
      CloseFile(F);
    end;
  except
    Result := 0;
  end;

  if Result < 1 then
    Result := 1;
end;


function CreateUsedBitmap(const Device, BitmapFile: string;OnProgress: TProgressEvent;OnLog: TLogEvent): Boolean;
var
  Info: TExt4Info;
  SectorBitmap: TBytes;
  BitmapFD: Integer;
  ErrorCode: Integer;
  BitmapSize: Int64;
  TotalSectors: UInt64;
  UsedSectors: UInt64;
  SectorSize: UInt32;
begin
  Result := False;
  RawImageBytesProcessed := 0;

  LogMsg(_(TXT_EXT4_DETECTING), OnLog);

  { Ext4-Superblock einlesen }
  if not ReadExt4Info(Device, Info) then
  begin
    LogMsg(_(TXT_EXT4_READ_ERROR), OnLog);
    Exit;
  end;

  SectorSize := GetSectorSize(Device);

  if SectorSize = 0 then
  begin
    LogMsg(_(TXT_SECTOR_SIZE_ERROR), OnLog);
    Exit;
  end;

  TotalSectors := Info.BlockCount * UInt64(Info.BlockSize div SectorSize);

  BitmapSize := (Int64(TotalSectors) + 7) div 8;

  LogMsg(Format(_(TXT_PARTITION_SIZE), [Info.BlockCount * UInt64(Info.BlockSize) / 1024 / 1024 / 1024]), OnLog);

  LogMsg(Format(_(TXT_SECTOR_COUNT), [TotalSectors]), OnLog);

  LogMsg(Format(_(TXT_BITMAP_SIZE), [BitmapSize / 1024 / 1024]), OnLog);

  { Belegte Sektoren ermitteln }
  if not BuildUsedSectorBitmap(Device, Info, SectorBitmap) then
  begin
    LogMsg(_(TXT_BITMAP_CREATE_ERROR), OnLog);
    Exit;
  end;

  { Bitmap speichern }
  BitmapFD := fpOpen(PChar(BitmapFile), O_WRONLY or O_CREAT or O_TRUNC, &666);

  if BitmapFD < 0 then
  begin
    ErrorCode := fpGetErrno;

    LogMsg(Format(_(TXT_BITMAP_CREATE_FILE_ERROR), [ErrorCode]), OnLog);
    Exit;
  end;

  try

    if not WriteExact(BitmapFD, SectorBitmap[0], Length(SectorBitmap), ErrorCode) then
    begin
      LogMsg(Format(_(TXT_BITMAP_WRITE_ERROR), [ErrorCode]), OnLog);
      Exit;
    end;

    if fpFSync(BitmapFD) <> 0 then
    begin
      ErrorCode := fpGetErrno;

      LogMsg(Format(_(TXT_FSYNC_ERROR), [ErrorCode]), OnLog);
      Exit;
    end;

  finally
    fpClose(BitmapFD);
  end;

  UsedSectors := CountSetBits(SectorBitmap);

  LogMsg(Format(_(TXT_USED_SECTORS), [UsedSectors]), OnLog);

  LogMsg(Format(_(TXT_BITMAP_CREATED), [BitmapFile]), OnLog);

  RawImageBytesProcessed := TotalSectors * SectorSize;

  if Assigned(OnProgress) then
    OnProgress(nil, RawImageBytesProcessed, RawImageBytesProcessed);

  Result := True;
end;


end.
