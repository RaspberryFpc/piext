unit rawimage;{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, zstd, Forms, ImageUtils,windows;

const
  RAW_BLOCK_SIZE = 32 * 1024 * 1024;
  RAW_BLOCK_SIZE_DIFF = 1 * 1024 * 1024;
  BASE_MAGIC = 'PIBASE01';
  DIFF_MAGIC = 'PIDIFF01';

type
  TBaseHeader = packed record
    Magic: array[0..7] of ansichar;
    Version: uint32;
    HeaderSize: uint32;
    SectorSize: uint32;
    SectorCount: uint64;
    BitmapSize: uint64;
    UsedSectors: uint64;
  end;

  TDiffHeader = packed record
    Magic: array[0..7] of ansichar;
    Version: uint32;
    HeaderSize: uint32;
    SectorSize: uint32;
    SectorCount: uint64;
  end;

function GetRawImageProgress: int64;
function RestoreSystemimage(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent; OnLog: TLogEvent): boolean;
function RestoreMBR(const ImageFile, Device: string; OnLog: TLogEvent): Boolean;

procedure ResetRestoreSpeed;
procedure UpdateRestoreSpeed(BytesWritten, TotalBytes: Int64);

const
RestoreSpeedSamplescount=20;

var
  RestoreSpeedStartTick: QWord = 0;
  RestoreSpeedLastTick: QWord = 0;
  RestoreSpeedLastBytes: Int64 = 0;
  RestoreSpeedSamples: array[0.. RestoreSpeedSamplescount] of Double;
  RestoreSpeedSampleIndex: Integer = 0;
  RestoreSpeedInitialized: Boolean = False;

implementation

uses unit1, Language;

function GetRawImageProgress: int64;
begin
  Result := RawImageBytesProcessed;
end;


procedure ResetRestoreSpeed;
begin
  RestoreSpeedStartTick := GetTickCount64;
  RestoreSpeedLastTick := RestoreSpeedStartTick;
  RestoreSpeedLastBytes := 0;
  RestoreSpeedSampleIndex := 0;
  RestoreSpeedInitialized := False;

  FillChar(RestoreSpeedSamples, SizeOf(RestoreSpeedSamples), 0);
end;

procedure UpdateRestoreSpeed(BytesWritten, TotalBytes: Int64);
var
  NowTick: QWord;
  DeltaTime: Double;
  CurrentSpeed, AverageSpeed, MedianSpeed, TotalSpeed: Double;
  RemainingBytes: Int64;
  Samples: array[0..RestoreSpeedSamplescount] of Double;
  I, J: Integer;
  Temp: Double;
  ETASeconds: Double;
  ETACount: Integer;
  Hours, Minutes, Seconds, Days: Int64;
  ETAString: string;
begin
  NowTick := GetTickCount64;

  // Nur alle fünf Sekunden aktualisieren
  if NowTick - RestoreSpeedLastTick < 5000 then
    Exit;

  DeltaTime := (NowTick - RestoreSpeedLastTick) / 1000.0;

  if DeltaTime <= 0 then
    Exit;

  // Aktuelle Geschwindigkeit in Bytes pro Sekunde
  CurrentSpeed := (BytesWritten - RestoreSpeedLastBytes) / DeltaTime;

  // Ringpuffer beim ersten Messwert vollständig füllen
  if not RestoreSpeedInitialized then
  begin
    for I := 0 to RestoreSpeedSamplescount do
      RestoreSpeedSamples[I] := CurrentSpeed;

    RestoreSpeedSampleIndex := 0;
    RestoreSpeedInitialized := True;
  end
  else
  begin
    // Ältesten Messwert ersetzen
    RestoreSpeedSamples[RestoreSpeedSampleIndex] := CurrentSpeed;
    RestoreSpeedSampleIndex :=
      (RestoreSpeedSampleIndex + 1) mod (RestoreSpeedSamplescount + 1);
  end;

  // Mittelwert berechnen und Werte für Median kopieren
  AverageSpeed := 0;

  for I := 0 to RestoreSpeedSamplescount do
  begin
    AverageSpeed := AverageSpeed + RestoreSpeedSamples[I];
    Samples[I] := RestoreSpeedSamples[I];
  end;

  AverageSpeed := AverageSpeed / (RestoreSpeedSamplescount + 1);

  // Median durch Sortieren berechnen
  for I := 0 to RestoreSpeedSamplescount - 1 do
    for J := I + 1 to RestoreSpeedSamplescount do
      if Samples[I] > Samples[J] then
      begin
        Temp := Samples[I];
        Samples[I] := Samples[J];
        Samples[J] := Temp;
      end;

  MedianSpeed := Samples[RestoreSpeedSamplescount div 2];

  // Durchschnittsgeschwindigkeit seit Start
  if NowTick > RestoreSpeedStartTick then
    TotalSpeed := BytesWritten /
      ((NowTick - RestoreSpeedStartTick) / 1000.0)
  else
    TotalSpeed := 0;

  // Verbleibende Datenmenge
  RemainingBytes := TotalBytes - BytesWritten;

  if RemainingBytes < 0 then
    RemainingBytes := 0;

  // Drei gleich gewichtete ETA-Schätzungen
  ETASeconds := 0;
  ETACount := 0;

  if MedianSpeed > 0 then
  begin
    ETASeconds := ETASeconds + RemainingBytes / MedianSpeed;
    Inc(ETACount);
  end;

  if AverageSpeed > 0 then
  begin
    ETASeconds := ETASeconds + RemainingBytes / AverageSpeed;
    Inc(ETACount);
  end;

  if TotalSpeed > 0 then
  begin
    ETASeconds := ETASeconds + RemainingBytes / TotalSpeed;
    Inc(ETACount);
  end;

  if ETACount > 0 then
    ETASeconds := ETASeconds / ETACount;

  // ETA formatieren
  if ETACount = 0 then
    ETAString := '--:--:--'
  else
  begin
    Seconds := Round(ETASeconds);
    Days := Seconds div 86400;
    Hours := (Seconds mod 86400) div 3600;
    Minutes := (Seconds mod 3600) div 60;
    Seconds := Seconds mod 60;

   if Days > 0 then
    ETAString := Format(_(TXT_ETA_DAYS),
      [Days, Hours, Minutes, Seconds])
  else
    ETAString := Format(_(TXT_ETA_TIME),
      [Hours, Minutes, Seconds]);
  end;
  // Aktuelle Geschwindigkeit und geschätzte Restzeit anzeigen
   Form1.Bt_speed.Caption := Format(
     _(TXT_RESTORE_SPEED),
     [CurrentSpeed / 1048576, ETAString]);

  // Messintervall aktualisieren
  RestoreSpeedLastTick := NowTick;
  RestoreSpeedLastBytes := BytesWritten;
end;


function RestoreSystemImage(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent; OnLog: TLogEvent): boolean;
const
  ZSTD_BUFFER_SIZE = 32 * 1024 * 1024;
  RESTORE_BLOCK_SIZE = 32 * 1024 * 1024;
var
  DevFD, BaseFD, DiffFD: THandle;
  ErrorCode: Integer;
  DeviceSize, TargetPos, TargetOffset: Int64;
  BaseBytesProduced, DiffBytesRead: Int64;
  SectorSize: UInt32;
  SectorCount, BitmapSize, DiffSectorCount: UInt64;
  BaseHeader: TBaseHeader;
  DiffHeader: TDiffHeader;
  BaseBitmap, DiffBitmap: TBytes;
  RestoreBuffer: TBytes;
  BaseInBuffer, BaseOutBuffer: TBytes;
  DiffInBuffer, DiffOutBuffer: TBytes;
  BaseZIn: TZSTD_inBuffer;
  BaseZOut: TZSTD_outBuffer;
  DiffZIn: TZSTD_inBuffer;
  DiffZOut: TZSTD_outBuffer;
  BaseDctx, DiffDctx: TZSTD_DCtx;
  BaseZRet, DiffZRet: NativeUInt;
  BaseZOutPos, BaseZOutSize: SizeInt;
  DiffZOutPos, DiffZOutSize: SizeInt;
  BaseZFinished, DiffZFinished: Boolean;
  BytesRead: DWORD;
  Position: LARGE_INTEGER;
  PartType: Byte;
  Sector, BlockSectors, BlockSize, TargetSector: UInt64;


    function CountSetBits(const Buffer: TBytes): Int64;
  var
    I: SizeInt;
    B: Byte;
  begin
    Result := 0;
    for I := 0 to High(Buffer) do
    begin
      B := Buffer[I];
      while B <> 0 do
      begin
        Inc(Result, B and 1);
        B := B shr 1;
      end;
    end;
  end;


  function ReadExactWin(H: THandle; Buffer: Pointer; Count: NativeUInt; out Err: Integer): Boolean;
  var
    DoneCount: NativeUInt;
    Bytes: DWORD;
    Request: DWORD;
  begin
    Result := False;
    Err := 0;
    DoneCount := 0;

    while DoneCount < Count do
    begin
      if Count - DoneCount > High(DWORD) then
        Request := High(DWORD)
      else
        Request := DWORD(Count - DoneCount);

      if not ReadFile(H, PByte(Buffer)[DoneCount], Request, Bytes, nil) then
      begin
        Err := GetLastError;
        Exit;
      end;

      if Bytes = 0 then
      begin
        Err := ERROR_HANDLE_EOF;
        Exit;
      end;

      Inc(DoneCount, Bytes);
    end;

    Result := True;
  end;

  function WriteExactWin(H: THandle; Buffer: Pointer; Count: NativeUInt; out Err: Integer): Boolean;
  var
    DoneCount: NativeUInt;
    Bytes: DWORD;
    Request: DWORD;
  begin
    Result := False;
    Err := 0;
    DoneCount := 0;

    while DoneCount < Count do
    begin
      if Count - DoneCount > High(DWORD) then
        Request := High(DWORD)
      else
        Request := DWORD(Count - DoneCount);


      if cancelrequested then exit;

      if not WriteFile(H, PByte(Buffer)[DoneCount], Request, Bytes, nil) then
      begin
        Err := GetLastError;
        Exit;
      end;

      application.ProcessMessages;


      if Bytes = 0 then
      begin
        Err := ERROR_WRITE_FAULT;
        Exit;
      end;

      Inc(DoneCount, Bytes);
    end;
    Result := True;
  end;

  function IsSet(const B: TBytes; Bit: UInt64): Boolean;
  begin
    Result := (B[Bit shr 3] and Byte(1 shl (Bit and 7))) <> 0;
  end;
   function ReadBaseBytes(P: Pointer; Count: SizeInt): Boolean;
  var
    CopyCount, DoneCount: SizeInt;
  begin
    Result := False;
    DoneCount := 0;

    while DoneCount < Count do
    begin
      if BaseZOutPos < BaseZOutSize then
      begin
        CopyCount := BaseZOutSize - BaseZOutPos;

        if CopyCount > Count - DoneCount then
          CopyCount := Count - DoneCount;

        Move(BaseOutBuffer[BaseZOutPos], PByte(P)[DoneCount], CopyCount);
        Inc(BaseZOutPos, CopyCount);
        Inc(DoneCount, CopyCount);
        Continue;
      end;



      if BaseZFinished then
      begin
        LogMsg(_(TXT_BASE_DATA_TOO_SHORT), OnLog);
        Exit;
      end;

      if BaseZIn.pos >= BaseZIn.size then
      begin
        if not ReadFile(BaseFD, BaseInBuffer[0], Length(BaseInBuffer), BytesRead, nil) then
        begin
          LogMsg(Format(_(TXT_BASE_READ_ERROR), [GetLastError]), OnLog);
          Exit;
        end;

        if BytesRead = 0 then
        begin
          LogMsg(_(TXT_BASE_EOF), OnLog);
          Exit;
        end;

        BaseZIn.src := @BaseInBuffer[0];
        BaseZIn.size := BytesRead;
        BaseZIn.pos := 0;
      end;

      BaseZOut.dst := @BaseOutBuffer[0];
      BaseZOut.size := Length(BaseOutBuffer);
      BaseZOut.pos := 0;

      BaseZRet := ZSTD_decompressStream(BaseDctx, BaseZOut, BaseZIn);

      if ZSTD_isError(BaseZRet) <> 0 then
      begin
        LogMsg(_(TXT_ZSTD_COMPRESSION_ERROR) + ': ' + StrPas(ZSTD_getErrorName(BaseZRet)), OnLog);
        Exit;
      end;

      BaseZOutPos := 0;
      BaseZOutSize := BaseZOut.pos;

      if BaseZRet = 0 then
        BaseZFinished := True;

      if (BaseZOutSize = 0) and BaseZFinished then
      begin
        LogMsg(_(TXT_BASE_ZSTD_STREAM_ERROR), OnLog);
        Exit;
      end;
    end;

    Inc(BaseBytesProduced, Count);
    Result := True;
  end;


   function ReadDiffBytes(P: Pointer; Count: SizeInt): Boolean;
   var
     CopyCount, DoneCount: SizeInt;
   begin
     Result := False;
     DoneCount := 0;

     while DoneCount < Count do
     begin
       if DiffZOutPos < DiffZOutSize then
       begin
         CopyCount := DiffZOutSize - DiffZOutPos;

         if CopyCount > Count - DoneCount then
           CopyCount := Count - DoneCount;

         Move(DiffOutBuffer[DiffZOutPos], PByte(P)[DoneCount], CopyCount);
         Inc(DiffZOutPos, CopyCount);
         Inc(DoneCount, CopyCount);
         Continue;
       end;

       if DiffZFinished then
       begin
         LogMsg(_(TXT_DIFF_DATA_TOO_SHORT), OnLog);
         Exit;
       end;

       if DiffZIn.pos >= DiffZIn.size then
       begin
         if not ReadFile(DiffFD, DiffInBuffer[0], DWORD(Length(DiffInBuffer)), BytesRead, nil) then
         begin
           LogMsg(Format(_(TXT_DIFF_READ_ERROR), [GetLastError]), OnLog);
           Exit;
         end;

         if BytesRead = 0 then
         begin
           LogMsg(_(TXT_DIFF_EOF), OnLog);
           Exit;
         end;

         DiffZIn.src := @DiffInBuffer[0];
         DiffZIn.size := BytesRead;
         DiffZIn.pos := 0;
       end;

       DiffZOut.dst := @DiffOutBuffer[0];
       DiffZOut.size := Length(DiffOutBuffer);
       DiffZOut.pos := 0;

       DiffZRet := ZSTD_decompressStream(DiffDctx, DiffZOut, DiffZIn);

       if ZSTD_isError(DiffZRet) <> 0 then
       begin
         LogMsg(_(TXT_DIFF_ZSTD_ERROR) + ': ' + StrPas(ZSTD_getErrorName(DiffZRet)), OnLog);
         Exit;
       end;

       DiffZOutPos := 0;
       DiffZOutSize := DiffZOut.pos;

       if DiffZRet = 0 then
         DiffZFinished := True;

       if (DiffZOutSize = 0) and DiffZFinished then
       begin
         LogMsg(_(TXT_DIFF_ZSTD_STREAM_ERROR), OnLog);
         Exit;
       end;
     end;

     Inc(DiffBytesRead, Count);
     Result := True;
   end;


begin
  Result := False;
  DevFD := INVALID_HANDLE_VALUE;
  BaseFD := INVALID_HANDLE_VALUE;
  DiffFD := INVALID_HANDLE_VALUE;
  BaseDctx := nil;
  DiffDctx := nil;
  RawImageBytesProcessed := 0;
  TargetPos := 0;
  TargetOffset := 0;
  DeviceSize := 0;
  BaseBytesProduced := 0;
  DiffBytesRead := 0;
  DiffSectorCount := 0;

  ResetRestoreSpeed;

  try
    try
      DevFD := CreateFile(PChar(Device), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

      if DevFD = INVALID_HANDLE_VALUE then
        raise Exception.Create(Format(_(TXT_TARGET_DRIVE_OPEN_ERROR), [GetLastError]));

      Position.QuadPart := 0;
      if not SetFilePointerEx(DevFD, Position, nil, FILE_BEGIN) then
        RaiseLastOSError;

      { Die Systempartition ist immer der zweite MBR-Eintrag. }
      PartType := new_MBR.PartitionEntries[2].PartitionType;

      TargetOffset := new_mbr.PartitionEntries[2].FirstLBA * 512;
      DeviceSize := new_mbr.PartitionEntries[2].PartitionSize * 512;

      LogMsg(Format(_(TXT_RESTORE_TARGET_PARTITION), [Device]), OnLog);
      LogMsg(Format(_(TXT_TARGET_DRIVE), [Device]), OnLog);
      LogMsg(Format(_(TXT_PARTITION_START), [TargetOffset]), OnLog);
      LogMsg(Format(_(TXT_PARTITION_SIZE_INFO), [DeviceSize]), OnLog);

      Position.QuadPart := TargetOffset;
      if not SetFilePointerEx(DevFD, Position, nil, FILE_BEGIN) then
        raise Exception.Create(Format(_(TXT_TARGET_POSITION_ERROR), [GetLastError]));

      BaseFD := CreateFile(PChar(BaseImage), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

      if BaseFD = INVALID_HANDLE_VALUE then
        raise Exception.Create(Format(_(TXT_BASE_IMAGE_OPEN_ERROR), [GetLastError]));

      if DiffImage <> '' then
      begin
        DiffFD := CreateFile(PChar(DiffImage), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

        if DiffFD = INVALID_HANDLE_VALUE then
          raise Exception.Create(Format(_(TXT_DIFF_IMAGE_CREATE_ERROR), [GetLastError]));
      end;

      if not ReadExactWin(BaseFD, @BaseHeader, SizeOf(BaseHeader), ErrorCode) then
        raise Exception.Create(_(TXT_BASE_IMAGE_HEADER_ERROR));

      if not CompareMem(@BaseHeader.Magic[0], @BASE_MAGIC[1], 8) then
        raise Exception.Create(_(TXT_INVALID_BASE_IMAGE));

      if BaseHeader.Version <> 1 then
        raise Exception.Create(_(TXT_UNSUPPORTED_BASE_VERSION));

      if BaseHeader.HeaderSize <> SizeOf(TBaseHeader) then
        raise Exception.Create(_(TXT_BASE_HEADER_SIZE_ERROR));

      SectorSize := BaseHeader.SectorSize;

      if SectorSize = 0 then
        raise Exception.Create(_(TXT_INVALID_SECTOR_SIZE));

      SectorCount := BaseHeader.SectorCount;

      if UInt64(DeviceSize) <> SectorCount * SectorSize then
        raise Exception.Create(_(TXT_DEVICE_BASE_SIZE_MISMATCH));

      BitmapSize := BaseHeader.BitmapSize;

      if BitmapSize <> (SectorCount + 7) div 8 then
        raise Exception.Create(_(TXT_INVALID_BITMAP_SIZE));

      SetLength(BaseBitmap, SizeInt(BitmapSize));

      if (BitmapSize > 0) and not ReadExactWin(BaseFD, @BaseBitmap[0], SizeInt(BitmapSize), ErrorCode) then
        raise Exception.Create(_(TXT_BASE_BITMAP_READ_ERROR));

      if CountSetBits(BaseBitmap) <> BaseHeader.UsedSectors then
        raise Exception.Create(_(TXT_USED_SECTORS_COUNT_ERROR));

      if DiffImage <> '' then
      begin
        if not ReadExactWin(DiffFD, @DiffHeader, SizeOf(DiffHeader), ErrorCode) then
          raise Exception.Create(_(TXT_DIFF_HEADER_READ_ERROR));

        if not CompareMem(@DiffHeader.Magic[0], @DIFF_MAGIC[1], 8) then
          raise Exception.Create(_(TXT_INVALID_DIFF_IMAGE));

        if DiffHeader.Version <> 1 then
          raise Exception.Create(_(TXT_UNSUPPORTED_DIFF_VERSION));

        if DiffHeader.HeaderSize <> SizeOf(TDiffHeader) then
          raise Exception.Create(_(TXT_DIFF_HEADER_SIZE_ERROR));

        if DiffHeader.SectorSize <> SectorSize then
          raise Exception.Create(_(TXT_SECTOR_SIZE_MISMATCH));

        if DiffHeader.SectorCount <> SectorCount then
          raise Exception.Create(_(TXT_SECTOR_COUNT_ERROR));

        SetLength(DiffBitmap, SizeInt(BitmapSize));

        if (BitmapSize > 0) and not ReadExactWin(DiffFD, @DiffBitmap[0], SizeInt(BitmapSize), ErrorCode) then
          raise Exception.Create(_(TXT_DIFF_BITMAP_READ_ERROR));

        DiffSectorCount := CountSetBits(DiffBitmap);
        LogMsg(Format(_(TXT_DIFF_INFO), [DiffSectorCount]), OnLog);
      end
      else
      begin
        SetLength(DiffBitmap, SizeInt(BitmapSize));

        if BitmapSize > 0 then
          FillChar(DiffBitmap[0], SizeInt(BitmapSize), 0);

        DiffSectorCount := 0;
        LogMsg(_(TXT_BASE_ONLY_RESTORE), OnLog);
      end;

      BaseDctx := ZSTD_createDCtx();

      if BaseDctx = nil then
        raise Exception.Create(_(TXT_BASE_DECODER_ERROR));

      if DiffImage <> '' then
      begin
        DiffDctx := ZSTD_createDCtx();

        if DiffDctx = nil then
          raise Exception.Create(_(TXT_DIFF_DECODER_ERROR));
      end;

      SetLength(RestoreBuffer, RESTORE_BLOCK_SIZE);
      SetLength(BaseInBuffer, ZSTD_BUFFER_SIZE);
      SetLength(BaseOutBuffer, ZSTD_BUFFER_SIZE);

      if DiffImage <> '' then
      begin
        SetLength(DiffInBuffer, ZSTD_BUFFER_SIZE);
        SetLength(DiffOutBuffer, ZSTD_BUFFER_SIZE);
      end;

      FillChar(BaseZIn, SizeOf(BaseZIn), 0);
      FillChar(BaseZOut, SizeOf(BaseZOut), 0);

      if DiffImage <> '' then
      begin
        FillChar(DiffZIn, SizeOf(DiffZIn), 0);
        FillChar(DiffZOut, SizeOf(DiffZOut), 0);
      end;

      BaseZOutPos := 0;
      BaseZOutSize := 0;
      BaseZFinished := False;

      DiffZOutPos := 0;
      DiffZOutSize := 0;
      DiffZFinished := False;

      while TargetPos < DeviceSize do
      begin
        if terminate_all then
          raise Exception.Create(_(TXT_OPERATION_CANCELLED));

        BlockSize := DeviceSize - TargetPos;

        if BlockSize > RESTORE_BLOCK_SIZE then
          BlockSize := RESTORE_BLOCK_SIZE;

        BlockSectors := BlockSize div SectorSize;
        FillChar(RestoreBuffer[0], SizeInt(BlockSize), 0);

        for Sector := 0 to BlockSectors - 1 do
        begin
          TargetSector := UInt64(TargetPos) div SectorSize + Sector;

          if IsSet(BaseBitmap, TargetSector) then
            if not ReadBaseBytes(@RestoreBuffer[Sector * UInt64(SectorSize)], SectorSize) then
              raise Exception.Create(_(TXT_BASE_DATA_TOO_SHORT));

          if (DiffImage <> '') and IsSet(DiffBitmap, TargetSector) then
            if not ReadDiffBytes(@RestoreBuffer[Sector * UInt64(SectorSize)], SectorSize) then
              raise Exception.Create(_(TXT_DIFF_DATA_TOO_SHORT));
        end;

        if not WriteExactWin(DevFD, @RestoreBuffer[0], BlockSize, ErrorCode) then
          if not cancelrequested then
          raise Exception.Create(Format(_(TXT_RESTORE_ERROR_MESSAGE), [Format('Windows error=%d', [ErrorCode])]))
          else
           raise Exception.Create(_( TXT_OPERATION_CANCELLED));

        Inc(TargetPos, BlockSize);
        RawImageBytesProcessed := TargetPos;

        UpdateRestoreSpeed(TargetPos, DeviceSize);

        if Assigned(OnProgress) then
          OnProgress(nil, TargetPos, DeviceSize);
      end;

      if BaseBytesProduced <> Int64(BaseHeader.UsedSectors) * SectorSize then
        raise Exception.Create(_(TXT_BASE_DATA_COUNT_ERROR));

      if DiffImage <> '' then
        if DiffBytesRead <> Int64(DiffSectorCount) * SectorSize then
          raise Exception.Create(_(TXT_DIFF_DATA_COUNT_ERROR));

      if not FlushFileBuffers(DevFD) then
        raise Exception.Create(Format(_(TXT_FSYNC_ERROR), [GetLastError]));

      if DiffImage = '' then
        LogMsg(_(TXT_BASE_RESTORE_SUCCESS), OnLog)
      else
        LogMsg(_(TXT_RESTORE_SUCCESS), OnLog);

      LogMsg(Format(_(TXT_WRITTEN_DATA), [DeviceSize / 1024 / 1024 / 1024]), OnLog);
      LogMsg(Format(_(TXT_RESTORE_TARGET), [Device, TargetOffset]), OnLog);

      Result := True;
    except
      on E: Exception do
      begin
        LogMsg(Format(_(TXT_RESTORE_ERROR_MESSAGE), [E.Message]), OnLog);
        Result := False;
      end;
    end;
  finally
    if DiffDctx <> nil then
      ZSTD_freeDCtx(DiffDctx);

    if BaseDctx <> nil then
      ZSTD_freeDCtx(BaseDctx);

    if DiffFD <> INVALID_HANDLE_VALUE then
      CloseHandle(DiffFD);

    if BaseFD <> INVALID_HANDLE_VALUE then
      CloseHandle(BaseFD);

    if DevFD <> INVALID_HANDLE_VALUE then
      CloseHandle(DevFD);
  end;
end;






function RestoreMBR(const ImageFile, Device: string; OnLog: TLogEvent): Boolean;
var
  InFile, OutFile: THandle;
  Buffer: array[0..511] of Byte;
  BytesRead, BytesWritten, Done: DWORD;
  Position: LARGE_INTEGER;
begin
  Result := False;
  InFile := INVALID_HANDLE_VALUE;
  OutFile := INVALID_HANDLE_VALUE;

  try
    InFile := CreateFile(PChar(ImageFile), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if InFile = INVALID_HANDLE_VALUE then
      raise Exception.Create(Format(_(TXT_MBR_IMAGE_OPEN_ERROR), [ImageFile]));

    Done := 0;
    while Done < SizeOf(Buffer) do
    begin
      if not ReadFile(InFile, Buffer,512, BytesRead, nil) then
        RaiseLastOSError;
      if BytesRead = 0 then
        raise Exception.Create(_(TXT_MBR_IMAGE_TOO_SHORT));
      Inc(Done, BytesRead);
    end;

    OutFile := CreateFile(PChar(Device), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    if OutFile = INVALID_HANDLE_VALUE then
      raise Exception.Create(Format(_(TXT_MBR_DEVICE_OPEN_ERROR), [Device]));
     Position.QuadPart := 0;
    if not SetFilePointerEx(OutFile,0, nil, FILE_BEGIN) then
      RaiseLastOSError;

      begin
      if not WriteFile(OutFile, Buffer, 512, BytesWritten, nil) then
        RaiseLastOSError;
      if BytesWritten < 512 then
        raise Exception.Create(_(TXT_MBR_WRITE_ERROR));
      Inc(Done, BytesWritten);
    end;

    if not FlushFileBuffers(OutFile) then
      RaiseLastOSError;

    Result := True;
    LogMsg(_(TXT_MBR_RESTORE_SUCCESS), OnLog);
  except
    on E: Exception do
      LogMsg(Format(_(TXT_MBR_RESTORE_ERROR), [E.Message]), OnLog);
  end;

  if OutFile <> INVALID_HANDLE_VALUE then
    CloseHandle(OutFile);
  if InFile <> INVALID_HANDLE_VALUE then
    CloseHandle(InFile);
end;




end.
