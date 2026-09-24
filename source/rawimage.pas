unit rawimage;{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, BaseUnix, Unix, ext4bitmap, zstd, Forms, ImageUtils;

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

function CreateRawImage(const Device, ImageFile: string; OnProgress: TProgressEvent = nil; OnLog: TLogEvent = nil): boolean;
function GetRawImageProgress: int64;
function CreateDiffBitmap(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent = nil; OnLog: TLogEvent = nil): boolean;
function CreateDiffImage(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent = nil; OnLog: TLogEvent = nil): boolean;
function RestoreImage(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent = nil; OnLog: TLogEvent = nil): boolean;

implementation

uses unit1, Language;

function GetRawImageProgress: int64;
begin
  Result := RawImageBytesProcessed;
end;

function CreateRawImage(const Device, ImageFile: string; OnProgress: TProgressEvent; OnLog: TLogEvent): boolean;
var
  DevFD, ImgFD, ErrorCode: integer;
  DeviceSize, Offset, Count, TotalWritten: int64;
  SectorSize: uint32;
  SectorCount, BitmapSize, UsedSectors, BlockFirstSector, SectorNo, RunStart, RunCount, BlockSectors: uint64;
  UsedBytes: uint64;
  Bitmap, DeviceBuffer, OutBuffer: TBytes;
  Info: TExt4Info;
  Header: TBaseHeader;
  Ctx: TZSTD_CCtx;
  InBuf: TZSTD_inBuffer;
  OutBuf: TZSTD_outBuffer;
  Ret: nativeuint;
  ThreadCount: integer;

  procedure ZstdError(const Msg: string);
  begin
    raise Exception.Create(Msg + ': ' + StrPas(ZSTD_getErrorName(Ret)));
  end;

  procedure CompressData(P: Pointer; DataSize: SizeInt);
  begin
    InBuf.src := P;
    InBuf.
      size := DataSize;
    InBuf.pos := 0;
    repeat
      OutBuf.dst := @OutBuffer[0];
      OutBuf.size := Length(OutBuffer);
      OutBuf.pos := 0;
      Ret := ZSTD_compressStream2(Ctx, @OutBuf, @InBuf, ZSTD_e_continue);
      if ZSTD_isError(Ret) <> 0 then ZstdError(_(TXT_ZSTD_COMPRESSION_ERROR));
      if OutBuf.pos > 0 then
      begin
        if not WriteExact(ImgFD, OutBuffer[0], OutBuf.pos, ErrorCode) then raise
          Exception.CreateFmt(_(TXT_BASE_IMAGE_WRITE_ERROR), [ErrorCode]);
        Inc(TotalWritten, OutBuf.pos);
      end;
    until InBuf.pos >= InBuf.size;
  end;

  procedure FinishCompression;
  begin
    InBuf.src := nil;
    InBuf.size := 0;
    InBuf.pos := 0;
    repeat
      OutBuf.dst := @OutBuffer[0];
      OutBuf.size := Length(OutBuffer);
      OutBuf.pos := 0;
      Ret := ZSTD_compressStream2(Ctx, @OutBuf, @InBuf, ZSTD_e_end);
      if ZSTD_isError(Ret) <> 0 then ZstdError(_(TXT_ZSTD_FINALIZATION_ERROR));
      if OutBuf.pos > 0 then
      begin
        if not WriteExact(ImgFD, OutBuffer[0], OutBuf.pos, ErrorCode) then raise Exception.CreateFmt(_(TXT_BASE_IMAGE_WRITE_ERROR), [ErrorCode]);
        Inc(TotalWritten, OutBuf.pos);
      end;
    until Ret = 0;
  end;

begin
  Result := False;
  DevFD := -1;
  ImgFD := -1;
  Ctx := nil;
  RawImageBytesProcessed := 0;
  try
    LogMsg(_(TXT_EXT4_DETECTING), OnLog);
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
    if (Info.BlockSize mod SectorSize) <> 0 then
    begin
      LogMsg(_(TXT_EXT4_BLOCK_SIZE_ERROR), OnLog);
      Exit;
    end;
    if not GetDeviceSize(Device, DeviceSize) then
    begin
      LogMsg(_(TXT_DEVICE_SIZE_ERROR), OnLog);
      Exit;
    end;
    if (DeviceSize mod SectorSize) <> 0 then
    begin
      LogMsg(_(TXT_DEVICE_SECTOR_SIZE_ERROR), OnLog);
      Exit;
    end;
    SectorCount := uint64(DeviceSize) div SectorSize;
    BitmapSize := (SectorCount + 7) div 8;
    if not BuildUsedSectorBitmap(Device, Info, Bitmap) then
    begin
      LogMsg(_(TXT_BITMAP_CREATE_ERROR), OnLog);
      Exit;
    end;
    if uint64(Length(Bitmap)) <> BitmapSize then
    begin
      LogMsg(_(TXT_BITMAP_SIZE_ERROR), OnLog);
      Exit;
    end;
    UsedSectors := CountSetBits(Bitmap);
    UsedBytes := UsedSectors * uint64(SectorSize);
    LogMsg(Format(_(TXT_PARTITION_SIZE), [DeviceSize / 1024 / 1024 / 1024]), OnLog);
    LogMsg(Format(_(TXT_USED_SECTORS), [UsedSectors]), OnLog);
    LogMsg(Format(_(TXT_USED_DATA), [UsedBytes / 1024 / 1024 / 1024]), OnLog);
    DevFD := fpOpen(PChar(Device), O_RDONLY);
    if DevFD < 0 then
    begin
      LogMsg(Format(_(TXT_DEVICE_OPEN_ERROR), [fpGetErrno]), OnLog);
      Exit;
    end;
    ImgFD := fpOpen(PChar(ImageFile), O_WRONLY or O_CREAT or O_TRUNC, &666);
    if ImgFD < 0 then
    begin
      LogMsg(Format(_(TXT_BASE_IMAGE_CREATE_ERROR), [fpGetErrno]), OnLog);
      Exit;
    end;
    FillChar(Header, SizeOf(Header), 0);
    Move(BASE_MAGIC[1], Header.Magic[0], 8);
    Header.Version := 1;
    Header.HeaderSize := SizeOf(TBaseHeader);
    Header.SectorSize := SectorSize;
    Header.SectorCount := SectorCount;
    Header.BitmapSize := BitmapSize;
    Header.UsedSectors := UsedSectors;
    if not WriteExact(ImgFD, Header, SizeOf(Header), ErrorCode) then
    begin
      LogMsg(Format(_(TXT_HEADER_WRITE_ERROR), [ErrorCode]), OnLog);
      Exit;
    end;
    if BitmapSize > 0 then if not WriteExact(ImgFD, Bitmap[0], SizeInt(BitmapSize), ErrorCode) then
      begin
        LogMsg(Format(_(TXT_BITMAP_WRITE_ERROR), [ErrorCode]), OnLog);
        Exit;
      end;
    Ctx := ZSTD_createCCtx();
    if Ctx = nil then
    begin
      LogMsg(_(TXT_ZSTD_CONTEXT_ERROR), OnLog);
      Exit;
    end;
    Ret := ZSTD_CCtx_setParameter(Ctx, ZSTD_c_compressionLevel, form1.spinedit1.Value);
    if ZSTD_isError(Ret) <> 0 then ZstdError(_(TXT_ZSTD_LEVEL_ERROR));
    ThreadCount := GetCPUCount;
    Ret := ZSTD_CCtx_setParameter(Ctx, ZSTD_c_nbWorkers, ThreadCount);
    if ZSTD_isError(Ret) <> 0 then ZstdError(_(TXT_ZSTD_THREADS_ERROR));
    Ret := ZSTD_CCtx_setParameter(Ctx, ZSTD_c_enableLongDistanceMatching, 1);
    if ZSTD_isError(Ret) <> 0 then ZstdError(_(TXT_ZSTD_LONG_ERROR));
    LogMsg(Format(_(TXT_ZSTD_INFO), [form1.SpinEdit1.Value, ThreadCount]), OnLog);
    SetLength(DeviceBuffer, RAW_BLOCK_SIZE);
    SetLength(OutBuffer, RAW_BLOCK_SIZE);
    Offset := 0;
    TotalWritten := SizeOf(TBaseHeader) + int64(BitmapSize);
    while Offset < DeviceSize do
    begin
      if terminate_all then raise Exception.Create(_(TXT_OPERATION_CANCELLED));
      Count := DeviceSize - Offset;
      if Count > Length(DeviceBuffer) then Count := Length(DeviceBuffer);
      if not ReadExact(DevFD, DeviceBuffer[0], Count, ErrorCode) then
      begin
        LogMsg(Format(_(TXT_DEVICE_READ_ERROR), [Offset, ErrorCode]), OnLog);
        Exit;
      end;
      BlockFirstSector := uint64(Offset) div SectorSize;
      BlockSectors := uint64(Count) div SectorSize;
      SectorNo := BlockFirstSector;
      while SectorNo < BlockFirstSector + BlockSectors do
      begin
        while (SectorNo < BlockFirstSector + BlockSectors) and ((Bitmap[SectorNo shr 3] and byte(1 shl (SectorNo and 7))) = 0) do Inc(SectorNo);
        if SectorNo >= BlockFirstSector + BlockSectors then Break;
        RunStart := SectorNo;
        RunCount := 0;
        while (SectorNo < BlockFirstSector + BlockSectors) and ((Bitmap[SectorNo shr 3] and byte(1 shl (SectorNo and 7))) <> 0) do
        begin
          Inc(SectorNo);
          Inc(RunCount);
        end;
        CompressData(@DeviceBuffer[(RunStart - BlockFirstSector) * uint64(SectorSize)], SizeInt(RunCount * uint64(SectorSize)));
      end;
      Inc(Offset, Count);
      RawImageBytesProcessed := Offset;
      if Assigned(OnProgress) then OnProgress(nil, Offset, DeviceSize);
    end;
    FinishCompression;
    if fpFSync(ImgFD) <> 0 then
    begin
      LogMsg(Format(_(TXT_FSYNC_ERROR), [fpGetErrno]), OnLog);
      Exit;
    end;
    LogMsg(Format(_(TXT_BASE_IMAGE_SIZE), [TotalWritten / 1024 / 1024]), OnLog);
    Result := True;
  except
    on E: Exception do
    begin
      LogMsg(_(TXT_BASE_IMAGE_ERROR) + ' ' + E.Message, OnLog);
      Result := False;
    end;
  end;
  if Ctx <> nil then ZSTD_freeCCtx(Ctx);
  if ImgFD >= 0 then fpClose(ImgFD);
  if DevFD >= 0 then fpClose(DevFD);
end;

function CreateDiffBitmap(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent; OnLog: TLogEvent): boolean;
begin
  Result := CreateDiffImage(Device, BaseImage, DiffImage, OnProgress, OnLog);
end;

function CreateDiffImage(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent; OnLog: TLogEvent): boolean;
const
  ZSTD_BUFFER_SIZE = 32 * 1024 * 1024;
  DIFF_BUFFER_SIZE = 32 * 1024 * 1024;
var
  DevFD, BaseFD, DiffFD, ErrorCode: integer;
  DeviceSize, DevicePos, BaseBytesProduced, DiffBytesWritten: int64;
  SectorSize: uint32;
  SectorCount, BitmapSize, UsedSectors, DifferentSectors: uint64;
  BaseHeader: TBaseHeader;
  DiffHeader: TDiffHeader;
  BaseBitmap, CurrentBitmap, DiffBitmap: TBytes;
  DeviceBuffer, BaseSector: TBytes;
  BaseInBuffer, BaseOutBuffer: TBytes;
  DiffBuffer, DiffOutBuffer: TBytes;
  ZIn: TZSTD_inBuffer;
  ZOut: TZSTD_outBuffer;
  Dctx: TZSTD_DCtx;
  Cctx: TZSTD_CCtx;
  ZRet: nativeuint;
  ZOutPos, ZOutSize: SizeInt;
  ZFinished: boolean;
  N: ssize_t;
  Info: TExt4Info;
  Sector, BlockSectors, BlockSize, TargetSector: uint64;
  DiffBufferPos: SizeInt;
  InBuf: TZSTD_inBuffer;
  OutBuf: TZSTD_outBuffer;
  CtxRet: nativeuint;
  ThreadCount: integer;

  function IsSet(const B: TBytes; Bit: uint64): boolean;
  begin
    Result := (B[Bit shr 3] and byte(1 shl (Bit and 7))) <> 0;
  end;

  procedure CtxError(const Msg: string);
  begin
    raise Exception.Create(Msg + ': ' + StrPas(ZSTD_getErrorName(CtxRet)));
  end;

  function ReadBaseSector(P: Pointer): boolean;
  var
    Need, CopyCount: SizeInt;
  begin
    Result := False;
    Need := SectorSize;
    while Need > 0 do
    begin
      if ZOutPos < ZOutSize then
      begin
        CopyCount := ZOutSize - ZOutPos;
        if CopyCount > Need then CopyCount := Need;
        Move(BaseOutBuffer[ZOutPos], pbyte(P)[SectorSize - Need], CopyCount);
        Inc(ZOutPos, CopyCount);
        Dec(Need, CopyCount);
        Continue;
      end;
      if ZFinished then
      begin
        LogMsg(_(TXT_BASE_DATA_TOO_SHORT), OnLog);
        Exit;
      end;
      if ZIn.pos >= ZIn.size then
      begin
        N := fpRead(BaseFD, BaseInBuffer[0], Length(BaseInBuffer));
        if N < 0 then
        begin
          LogMsg(Format(_(TXT_BASE_READ_ERROR), [fpGetErrno]), OnLog);
          Exit;
        end;
        if N = 0 then
        begin
          LogMsg(_(TXT_BASE_EOF), OnLog);
          Exit;
        end;
        ZIn.src := @BaseInBuffer[0];
        ZIn.size := N;
        ZIn.pos := 0;
      end;
      ZOut.dst := @BaseOutBuffer[0];
      ZOut.size := Length(BaseOutBuffer);
      ZOut.pos := 0;
      ZRet := ZSTD_decompressStream(Dctx, ZOut, ZIn);
      if ZSTD_isError(ZRet) <> 0 then
      begin
        LogMsg(_(TXT_ZSTD_COMPRESSION_ERROR) + ': ' + StrPas(ZSTD_getErrorName(ZRet)), OnLog);
        Exit;
      end;
      ZOutPos := 0;
      ZOutSize := ZOut.pos;
      if ZRet = 0 then ZFinished := True;
    end;
    Result := True;
  end;

  procedure CompressDiffData(P: Pointer; DataSize: SizeInt);
  begin
    InBuf.src := P;
    InBuf.size := DataSize;
    InBuf.pos := 0;
    while InBuf.pos < InBuf.size do
    begin
      OutBuf.dst := @DiffOutBuffer[0];
      OutBuf.size := Length(DiffOutBuffer);
      OutBuf.pos := 0;
      CtxRet := ZSTD_compressStream2(Cctx, @OutBuf, @InBuf, ZSTD_e_continue);
      if ZSTD_isError(CtxRet) <> 0 then CtxError(_(TXT_ZSTD_COMPRESSION_ERROR));
      if OutBuf.pos > 0 then
      begin
        if not WriteExact(DiffFD, DiffOutBuffer[0], OutBuf.pos, ErrorCode) then
          raise Exception.CreateFmt(_(TXT_DIFF_IMAGE_WRITE_ERROR), [ErrorCode]);
        Inc(DiffBytesWritten, OutBuf.pos);
      end;
    end;
  end;

  procedure FinishDiffCompression;
  begin
    InBuf.src := nil;
    InBuf.size := 0;
    InBuf.pos := 0;
    repeat
      OutBuf.dst := @DiffOutBuffer[0];
      OutBuf.size := Length(DiffOutBuffer);
      OutBuf.pos := 0;
      CtxRet := ZSTD_compressStream2(Cctx, @OutBuf, @InBuf, ZSTD_e_end);
      if ZSTD_isError(CtxRet) <> 0 then CtxError(_(TXT_ZSTD_FINALIZATION_ERROR));
      if OutBuf.pos > 0 then
      begin
        if not WriteExact(DiffFD, DiffOutBuffer[0], OutBuf.pos, ErrorCode) then raise Exception.CreateFmt(_(TXT_DIFF_IMAGE_WRITE_ERROR), [ErrorCode]);
        Inc(DiffBytesWritten, OutBuf.pos);
      end;
    until CtxRet = 0;
  end;

begin
  Result := False;
  DevFD := -1;
  BaseFD := -1;
  DiffFD := -1;
  Dctx := nil;
  Cctx := nil;
  RawImageBytesProcessed := 0;
  DevicePos := 0;
  BaseBytesProduced := 0;
  DiffBytesWritten := 0;
  DifferentSectors := 0;
  try
    if not GetDeviceSize(Device, DeviceSize) then
    begin
      LogMsg(_(TXT_DEVICE_SIZE_ERROR), OnLog);
      Exit;
    end;
    SectorSize := GetSectorSize(Device);
    if SectorSize = 0 then
    begin
      LogMsg(_(TXT_SECTOR_SIZE_ERROR), OnLog);
      Exit;
    end;
    if (DeviceSize mod SectorSize) <> 0 then
    begin
      LogMsg(_(TXT_DEVICE_SECTOR_SIZE_ERROR), OnLog);
      Exit;
    end;
    if (DIFF_BUFFER_SIZE mod SectorSize) <> 0 then
    begin
      LogMsg(_(TXT_SECTOR_SIZE_ERROR), OnLog);
      Exit;
    end;
    SectorCount := uint64(DeviceSize) div SectorSize;
    BitmapSize := (SectorCount + 7) div 8;
    BaseFD := fpOpen(PChar(BaseImage), O_RDONLY);
    if BaseFD < 0 then
    begin
      LogMsg(Format(_(TXT_BASE_IMAGE_OPEN_ERROR), [fpGetErrno]), OnLog);
      Exit;
    end;
    if not ReadExact(BaseFD, BaseHeader, SizeOf(BaseHeader), ErrorCode) then
    begin
      LogMsg(_(TXT_BASE_IMAGE_HEADER_ERROR), OnLog);
      Exit;
    end;
    if not CompareMem(@BaseHeader.Magic[0], @BASE_MAGIC[1], 8) then
    begin
      LogMsg(_(TXT_INVALID_BASE_IMAGE), OnLog);
      Exit;
    end;
    if BaseHeader.Version <> 1 then
    begin
      LogMsg(_(TXT_UNSUPPORTED_BASE_VERSION), OnLog);
      Exit;
    end;
    if BaseHeader.SectorSize <> SectorSize then
    begin
      LogMsg(_(TXT_SECTOR_SIZE_MISMATCH), OnLog);
      Exit;
    end;
    if BaseHeader.SectorCount <> SectorCount then
    begin
      LogMsg(_(TXT_DEVICE_BASE_SIZE_MISMATCH), OnLog);
      Exit;
    end;
    SetLength(BaseBitmap, SizeInt(BitmapSize));
    if BitmapSize > 0 then
      if not ReadExact(BaseFD, BaseBitmap[0], SizeInt(BitmapSize), ErrorCode) then
      begin
        LogMsg(_(TXT_BASE_BITMAP_READ_ERROR), OnLog);
        Exit;
      end;
    UsedSectors := CountSetBits(BaseBitmap);
    if not ReadExt4Info(Device, Info) then
    begin
      LogMsg(_(TXT_EXT4_READ_ERROR), OnLog);
      Exit;
    end;
    if not BuildUsedSectorBitmap(Device, Info, CurrentBitmap) then
    begin
      LogMsg(_(TXT_CURRENT_BITMAP_ERROR), OnLog);
      Exit;
    end;
    if uint64(Length(CurrentBitmap)) <> BitmapSize then
    begin
      LogMsg(_(TXT_CURRENT_BITMAP_SIZE_ERROR), OnLog);
      Exit;
    end;
    SetLength(DiffBitmap, SizeInt(BitmapSize));
    FillChar(DiffBitmap[0], Length(DiffBitmap), 0);
    DevFD := fpOpen(PChar(Device), O_RDONLY);
    if DevFD < 0 then
    begin
      LogMsg(Format(_(TXT_DEVICE_OPEN_ERROR), [fpGetErrno]), OnLog);
      Exit;
    end;
    DiffFD := fpOpen(PChar(DiffImage), O_WRONLY or O_CREAT or O_TRUNC, &666);
    if DiffFD < 0 then
    begin
      LogMsg(Format(_(TXT_DIFF_IMAGE_CREATE_ERROR), [fpGetErrno]), OnLog);
      Exit;
    end;
    FillChar(DiffHeader, SizeOf(DiffHeader), 0);
    Move(DIFF_MAGIC[1], DiffHeader.Magic[0], 8);
    DiffHeader.Version := 1;
    DiffHeader.HeaderSize := SizeOf(TDiffHeader);
    DiffHeader.SectorSize := SectorSize;
    DiffHeader.SectorCount := SectorCount;
    if not WriteExact(DiffFD, DiffHeader, SizeOf(DiffHeader), ErrorCode) then
    begin
      LogMsg(_(TXT_DIFF_HEADER_WRITE_ERROR), OnLog);
      Exit;
    end;
    if BitmapSize > 0 then if not WriteExact(DiffFD, DiffBitmap[0], SizeInt(BitmapSize), ErrorCode) then
      begin
        LogMsg(_(TXT_DIFF_BITMAP_WRITE_ERROR), OnLog);
        Exit;
      end;
    Dctx := ZSTD_createDCtx();
    if Dctx = nil then
    begin
      LogMsg(_(TXT_BASE_DECODER_ERROR), OnLog);
      Exit;
    end;
    Cctx := ZSTD_createCCtx();
    if Cctx = nil then
    begin
      LogMsg(_(TXT_ZSTD_CONTEXT_ERROR), OnLog);
      Exit;
    end;
    CtxRet := ZSTD_CCtx_setParameter(Cctx, ZSTD_c_compressionLevel, form1.spinedit1.Value);
    if ZSTD_isError(CtxRet) <> 0 then CtxError(_(TXT_ZSTD_LEVEL_ERROR));
    ThreadCount := GetCPUCount;
    CtxRet := ZSTD_CCtx_setParameter(Cctx, ZSTD_c_nbWorkers, ThreadCount);
    if ZSTD_isError(CtxRet) <> 0 then CtxError(_(TXT_ZSTD_THREADS_ERROR));
    CtxRet := ZSTD_CCtx_setParameter(Cctx, ZSTD_c_enableLongDistanceMatching, 1);
    if ZSTD_isError(CtxRet) <> 0 then CtxError(_(TXT_ZSTD_LONG_ERROR));

    LogMsg(Format(_(TXT_ZSTD_INFO), [form1.SpinEdit1.Value, ThreadCount]), OnLog);

    SetLength(DeviceBuffer, DIFF_BUFFER_SIZE);
    SetLength(BaseSector, SectorSize);
    SetLength(BaseInBuffer, ZSTD_BUFFER_SIZE);
    SetLength(BaseOutBuffer, ZSTD_BUFFER_SIZE);
    SetLength(DiffBuffer, DIFF_BUFFER_SIZE);
    SetLength(DiffOutBuffer, ZSTD_BUFFER_SIZE);
    FillChar(ZIn, SizeOf(ZIn), 0);
    FillChar(ZOut, SizeOf(ZOut), 0);
    ZOutPos := 0;
    ZOutSize := 0;
    ZFinished := False;
    DiffBufferPos := 0;
    while DevicePos < DeviceSize do
    begin
      if terminate_all then raise Exception.Create(_(TXT_OPERATION_CANCELLED));
      BlockSize := DeviceSize - DevicePos;
      if BlockSize > DIFF_BUFFER_SIZE then BlockSize := DIFF_BUFFER_SIZE;
      BlockSectors := BlockSize div SectorSize;
      if not ReadExact(DevFD, DeviceBuffer[0], BlockSize, ErrorCode) then
      begin
        LogMsg(Format(_(TXT_DEVICE_READ_ERROR), [DevicePos, ErrorCode]), OnLog);
        Exit;
      end;
      DiffBufferPos := 0;
      for Sector := 0 to BlockSectors - 1 do
      begin
        TargetSector := uint64(DevicePos) div SectorSize + Sector;
        if IsSet(BaseBitmap, TargetSector) then
        begin
          if not ReadBaseSector(@BaseSector[0]) then Exit;
          Inc(BaseBytesProduced,
            SectorSize);
          if not IsSet(CurrentBitmap, TargetSector) then
          begin
            FillChar(DiffBuffer[DiffBufferPos], SectorSize, 0);
            Inc(DiffBufferPos, SectorSize);
            DiffBitmap[TargetSector shr 3] := DiffBitmap[TargetSector shr 3] or byte(1 shl (TargetSector and 7));
            Inc(DifferentSectors);
          end
          else if not CompareMem(@DeviceBuffer[Sector * uint64(SectorSize)], @BaseSector[0], SectorSize) then
          begin
            Move(DeviceBuffer[Sector * uint64(SectorSize)], DiffBuffer[DiffBufferPos], SectorSize);
            Inc(DiffBufferPos, SectorSize);
            DiffBitmap[TargetSector shr 3] := DiffBitmap[TargetSector shr 3] or byte(1 shl (TargetSector and 7));
            Inc(DifferentSectors);
          end;
        end
        else if IsSet(CurrentBitmap, TargetSector) then
        begin
          Move(DeviceBuffer[Sector * uint64(SectorSize)], DiffBuffer[DiffBufferPos], SectorSize);
          Inc(DiffBufferPos, SectorSize);
          DiffBitmap[TargetSector shr 3] := DiffBitmap[TargetSector shr 3] or byte(1 shl (TargetSector and 7));
          Inc(DifferentSectors);
        end;
      end;
      if DiffBufferPos > 0 then CompressDiffData(@DiffBuffer[0], DiffBufferPos);
      Inc(DevicePos, BlockSize);
      RawImageBytesProcessed := DevicePos;
      if Assigned(OnProgress) then OnProgress(nil, DevicePos, DeviceSize);
    end;
    FinishDiffCompression;
    if BaseBytesProduced <> int64(UsedSectors) * SectorSize then
    begin
      LogMsg(_(TXT_BASE_DATA_COUNT_ERROR), OnLog);
      Exit;
    end;
    if fpLSeek(DiffFD, SizeOf(TDiffHeader), SEEK_SET) < 0 then
    begin
      LogMsg(_(TXT_DIFF_BITMAP_UPDATE_ERROR), OnLog);
      Exit;
    end;
    if BitmapSize > 0 then
      if not WriteExact(DiffFD, DiffBitmap[0], SizeInt(BitmapSize), ErrorCode) then
      begin
        LogMsg(_(TXT_DIFF_BITMAP_UPDATE_ERROR), OnLog);
        Exit;
      end;
    if fpFSync(DiffFD) <> 0 then
    begin
      LogMsg(Format(_(TXT_FSYNC_ERROR), [fpGetErrno]), OnLog);
      Exit;
    end;
    LogMsg(_(TXT_DIFF_CREATED), OnLog);
    LogMsg(Format(_(TXT_CHANGED_SECTORS), [DifferentSectors]), OnLog);
    LogMsg(Format(_(TXT_COMPRESSED_DIFF_DATA), [DiffBytesWritten / 1024 / 1024]), OnLog);
    Result := True;
  except
    on E: Exception do
    begin
      LogMsg(_(TXT_DIFF_IMAGE_ERROR) + ' ' + E.Message, OnLog);
      Result := False;
    end;
  end;
  if Cctx <> nil then ZSTD_freeCCtx(Cctx);
  if Dctx <> nil then ZSTD_freeDCtx(Dctx);
  if DiffFD >= 0 then fpClose(DiffFD);
  if BaseFD >= 0 then fpClose(BaseFD);
  if DevFD >= 0 then fpClose(DevFD);
end;

function RestoreImage(const Device, BaseImage, DiffImage: string; OnProgress: TProgressEvent; OnLog: TLogEvent): boolean;
const
  ZSTD_BUFFER_SIZE = 32 * 1024 * 1024;
  RESTORE_BLOCK_SIZE = 32 * 1024 * 1024;
var
  DevFD, BaseFD, DiffFD, ErrorCode: integer;
  DeviceSize, TargetPos, TargetOffset, TargetPartitionSize: int64;
  BaseBytesProduced, DiffBytesRead: int64;
  SectorSize: uint32;
  SectorCount, BitmapSize, DiffSectorCount: uint64;
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
  BaseDctx: TZSTD_DCtx;
  DiffDctx: TZSTD_DCtx;
  BaseZRet: nativeuint;
  DiffZRet: nativeuint;
  BaseZOutPos, BaseZOutSize: SizeInt;
  DiffZOutPos, DiffZOutSize: SizeInt;
  BaseZFinished: boolean;
  DiffZFinished: boolean;
  N: ssize_t;
  Sector, BlockSectors, BlockSize, TargetSector: uint64;
  TargetDrive: string;

  function GetPartitionTarget(const PartitionDevice: string; out Drive: string; out StartOffset: int64; out PartitionSize: int64): boolean;
  var
    DevName, SysPath, StartText, SizeText: string;
    F: TextFile;
    P: integer;
  begin
    Result := False;
    Drive := '';
    StartOffset := 0;
    PartitionSize := 0;

    DevName := ExtractFileName(PartitionDevice);

    if DevName = '' then
      Exit;

    SysPath := '/sys/class/block/' + DevName;

    if not DirectoryExists(SysPath) then
      Exit;

    { Das Device muss eine Partition sein }
    if not FileExists(SysPath + '/partition') then
      Exit;

    { ------------------------------------------------------------- }
    { Partitionsstart lesen                                         }
    { ------------------------------------------------------------- }

    if not FileExists(SysPath + '/start') then
      Exit;

    AssignFile(F, SysPath + '/start');
    Reset(F);
    try
      ReadLn(F, StartText);
    finally
      CloseFile(F);
    end;

    if not TryStrToInt64(Trim(StartText), StartOffset) then
      Exit;

    { sysfs liefert den Start in 512-Byte-Sektoren }
    StartOffset := StartOffset * 512;

    { ------------------------------------------------------------- }
    { Partitionsgröße lesen                                         }
    { ------------------------------------------------------------- }

    if not FileExists(SysPath + '/size') then
      Exit;

    AssignFile(F, SysPath + '/size');
    Reset(F);
    try
      ReadLn(F, SizeText);
    finally
      CloseFile(F);
    end;

    if not TryStrToInt64(Trim(SizeText), PartitionSize) then
      Exit;

    { sysfs liefert die Größe ebenfalls in 512-Byte-Sektoren }
    PartitionSize := PartitionSize * 512;

    { ------------------------------------------------------------- }
    { Übergeordnetes Laufwerk bestimmen                             }
    { ------------------------------------------------------------- }

    P := Length(DevName);

    { normale Geräte:
        sda2 -> sda
        sdd2 -> sdd
        vda3 -> vda
    }
    while (P > 0) and
          (DevName[P] >= '0') and
          (DevName[P] <= '9') do
      Dec(P);

    if P <= 0 then
      Exit;

    { Geräte wie:
        mmcblk0p2 -> mmcblk0
        nvme0n1p2 -> nvme0n1
    }
    if (P > 0) and
       (DevName[P] = 'p') then
      Dec(P);

    if P <= 0 then
      Exit;

    Drive := '/dev/' + Copy(DevName, 1, P);

    if not FileExists(Drive) then
    begin
      Drive := '';
      Exit;
    end;

    Result := True;
  end;

  function IsSet(const B: TBytes; Bit: uint64): boolean;
  begin
    Result := (B[Bit shr 3] and byte(1 shl (Bit and 7))) <> 0;
  end;

  function ReadBaseBytes(P: Pointer; Count: SizeInt): boolean;
  var
    Done, CopyCount: SizeInt;
  begin
    Result := False;
    Done := 0;

    while Done < Count do
    begin
      if BaseZOutPos < BaseZOutSize then
      begin
        CopyCount := BaseZOutSize - BaseZOutPos;

        if CopyCount > Count - Done then
          CopyCount := Count - Done;

        Move(
          BaseOutBuffer[BaseZOutPos],
          PByte(P)[Done],
          CopyCount);

        Inc(BaseZOutPos, CopyCount);
        Inc(Done, CopyCount);
        Continue;
      end;

      if BaseZFinished then
      begin
        LogMsg(
          _(TXT_BASE_DATA_TOO_SHORT),
          OnLog);
        Exit;
      end;

      if BaseZIn.pos >= BaseZIn.size then
      begin
        N := fpRead(
          BaseFD,
          BaseInBuffer[0],
          Length(BaseInBuffer));

        if N < 0 then
        begin
          LogMsg(
            Format(
              _(TXT_BASE_READ_ERROR),
              [fpGetErrno]),
            OnLog);
          Exit;
        end;

        if N = 0 then
        begin
          LogMsg(
            _(TXT_BASE_EOF),
            OnLog);
          Exit;
        end;

        BaseZIn.src := @BaseInBuffer[0];
        BaseZIn.size := N;
        BaseZIn.pos := 0;
      end;

      BaseZOut.dst := @BaseOutBuffer[0];
      BaseZOut.size := Length(BaseOutBuffer);
      BaseZOut.pos := 0;

      BaseZRet := ZSTD_decompressStream(
        BaseDctx,
        BaseZOut,
        BaseZIn);

      if ZSTD_isError(BaseZRet) <> 0 then
      begin
        LogMsg(
          _(TXT_ZSTD_COMPRESSION_ERROR) + ': ' +
          StrPas(ZSTD_getErrorName(BaseZRet)),
          OnLog);
        Exit;
      end;

      BaseZOutPos := 0;
      BaseZOutSize := BaseZOut.pos;

      if BaseZRet = 0 then
        BaseZFinished := True;

      if (BaseZOutSize = 0) and BaseZFinished then
      begin
        LogMsg(
          _(TXT_BASE_ZSTD_STREAM_ERROR),
          OnLog);
        Exit;
      end;
    end;

    Inc(BaseBytesProduced, Count);
    Result := True;
  end;

  function ReadDiffBytes(P: Pointer; Count: SizeInt): boolean;
  var
    Done, CopyCount: SizeInt;
  begin
    Result := False;
    Done := 0;

    while Done < Count do
    begin
      if DiffZOutPos < DiffZOutSize then
      begin
        CopyCount := DiffZOutSize - DiffZOutPos;

        if CopyCount > Count - Done then
          CopyCount := Count - Done;

        Move(
          DiffOutBuffer[DiffZOutPos],
          PByte(P)[Done],
          CopyCount);

        Inc(DiffZOutPos, CopyCount);
        Inc(Done, CopyCount);
        Continue;
      end;

      if DiffZFinished then
      begin
        LogMsg(
          _(TXT_DIFF_DATA_TOO_SHORT),
          OnLog);
        Exit;
      end;

      if DiffZIn.pos >= DiffZIn.size then
      begin
        N := fpRead(
          DiffFD,
          DiffInBuffer[0],
          Length(DiffInBuffer));

        if N < 0 then
        begin
          LogMsg(
            Format(
              _(TXT_DIFF_READ_ERROR),
              [fpGetErrno]),
            OnLog);
          Exit;
        end;

        if N = 0 then
        begin
          LogMsg(
            _(TXT_DIFF_EOF),
            OnLog);
          Exit;
        end;

        DiffZIn.src := @DiffInBuffer[0];
        DiffZIn.size := N;
        DiffZIn.pos := 0;
      end;

      DiffZOut.dst := @DiffOutBuffer[0];
      DiffZOut.size := Length(DiffOutBuffer);
      DiffZOut.pos := 0;

      DiffZRet := ZSTD_decompressStream(
        DiffDctx,
        DiffZOut,
        DiffZIn);

      if ZSTD_isError(DiffZRet) <> 0 then
      begin
        LogMsg(
          _(TXT_DIFF_ZSTD_ERROR) + ': ' +
          StrPas(ZSTD_getErrorName(DiffZRet)),
          OnLog);
        Exit;
      end;

      DiffZOutPos := 0;
      DiffZOutSize := DiffZOut.pos;

      if DiffZRet = 0 then
        DiffZFinished := True;

      if (DiffZOutSize = 0) and DiffZFinished then
      begin
        LogMsg(
          _(TXT_DIFF_ZSTD_STREAM_ERROR),
          OnLog);
        Exit;
      end;
    end;

    Inc(DiffBytesRead, Count);
    Result := True;
  end;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


begin
  Result := False;

  DevFD := -1;
  BaseFD := -1;
  DiffFD := -1;

  BaseDctx := nil;
  DiffDctx := nil;

  RawImageBytesProcessed := 0;

  TargetPos := 0;
  TargetOffset := 0;
  TargetPartitionSize := 0;

  BaseBytesProduced := 0;
  DiffBytesRead := 0;

  try
    { ------------------------------------------------------------- }
    { Größe der Zielpartition ermitteln                            }
    { ------------------------------------------------------------- }

    if not GetDeviceSize(
      Device,
      DeviceSize) then
    begin
      LogMsg(
        _(TXT_DEVICE_SIZE_ERROR),
        OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Zielpartition und übergeordnetes Laufwerk bestimmen           }
    { ------------------------------------------------------------- }

    if not GetPartitionTarget(
      Device,
      TargetDrive,
      TargetOffset,
      TargetPartitionSize) then
    begin
      LogMsg(
        _(TXT_PARTITION_TARGET_ERROR),
        OnLog);
      Exit;
    end;

    LogMsg(
      Format(
        _(TXT_RESTORE_TARGET_PARTITION),
        [Device]),
      OnLog);

    LogMsg(
      Format(
        _(TXT_TARGET_DRIVE),
        [TargetDrive]),
      OnLog);

    LogMsg(
      Format(
        _(TXT_PARTITION_START),
        [TargetOffset]),
      OnLog);

    LogMsg(
      Format(
        _(TXT_PARTITION_SIZE_INFO),
        [TargetPartitionSize]),
      OnLog);

    { ------------------------------------------------------------- }
    { Größe prüfen                                                   }
    { ------------------------------------------------------------- }

    if TargetPartitionSize <> DeviceSize then
    begin
      LogMsg(
        Format(
          _(TXT_TARGET_PARTITION_SIZE_ERROR),
          [TargetPartitionSize, DeviceSize]),
        OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Physisches Ziellaufwerk öffnen                                }
    { ------------------------------------------------------------- }

    DevFD := fpOpen(
      PChar(TargetDrive),
      O_WRONLY);

    if DevFD < 0 then
    begin
      LogMsg(
        Format(
          _(TXT_TARGET_DRIVE_OPEN_ERROR),
          [fpGetErrno]),
        OnLog);
      Exit;
    end;

    { Auf Beginn der Zielpartition positionieren }
    if fpLseek(
      DevFD,
      TargetOffset,
      SEEK_SET) < 0 then
    begin
      LogMsg(
        Format(
          _(TXT_TARGET_POSITION_ERROR),
          [fpGetErrno]),
        OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Basisimage öffnen                                              }
    { ------------------------------------------------------------- }

    BaseFD := fpOpen(
      PChar(BaseImage),
      O_RDONLY);

    if BaseFD < 0 then
    begin
      LogMsg(
        Format(
          _(TXT_BASE_IMAGE_OPEN_ERROR),
          [fpGetErrno]),
        OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Differenzimage öffnen                                          }
    { ------------------------------------------------------------- }

    DiffFD := fpOpen(
      PChar(DiffImage),
      O_RDONLY);

    if DiffFD < 0 then
    begin
      LogMsg(
        Format(
          _(TXT_DIFF_IMAGE_CREATE_ERROR),
          [fpGetErrno]),
        OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Basisimage Header                                               }
    { ------------------------------------------------------------- }

    if not ReadExact(BaseFD,BaseHeader,SizeOf(BaseHeader),ErrorCode) then
    begin
      LogMsg( _(TXT_BASE_IMAGE_HEADER_ERROR),OnLog);
      Exit;
    end;

    if not CompareMem(
      @BaseHeader.Magic[0],
      @BASE_MAGIC[1],
      8) then
    begin
      LogMsg(
        _(TXT_INVALID_BASE_IMAGE),
        OnLog);
      Exit;
    end;

    if BaseHeader.Version <> 1 then
    begin
      LogMsg(
        _(TXT_UNSUPPORTED_BASE_VERSION),
        OnLog);
      Exit;
    end;

    if BaseHeader.HeaderSize <> SizeOf(TBaseHeader) then
    begin
      LogMsg(
        _(TXT_BASE_HEADER_SIZE_ERROR),
        OnLog);
      Exit;
    end;

    SectorSize := BaseHeader.SectorSize;

    if SectorSize = 0 then
    begin
      LogMsg(
        _(TXT_INVALID_SECTOR_SIZE),
        OnLog);
      Exit;
    end;

    SectorCount := BaseHeader.SectorCount;

    if uint64(DeviceSize) <> SectorCount * SectorSize then
    begin
      LogMsg(
        _(TXT_DEVICE_BASE_SIZE_MISMATCH),
        OnLog);
      Exit;
    end;

    BitmapSize := BaseHeader.BitmapSize;

    if BitmapSize <> (SectorCount + 7) div 8 then
    begin
      LogMsg(
        _(TXT_INVALID_BITMAP_SIZE),
        OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Basis-Bitmap lesen                                             }
    { ------------------------------------------------------------- }

    SetLength(
      BaseBitmap,
      SizeInt(BitmapSize));

    if BitmapSize > 0 then
      if not ReadExact(
        BaseFD,
        BaseBitmap[0],
        SizeInt(BitmapSize),
        ErrorCode) then
      begin
        LogMsg(
          _(TXT_BASE_BITMAP_READ_ERROR),
          OnLog);
        Exit;
      end;

    if CountSetBits(BaseBitmap) <> BaseHeader.UsedSectors then
    begin
      LogMsg(
        _(TXT_USED_SECTORS_COUNT_ERROR),
        OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Diff Header                                                     }
    { ------------------------------------------------------------- }

    if not ReadExact(
      DiffFD,
      DiffHeader,
      SizeOf(DiffHeader),
      ErrorCode) then
    begin
      LogMsg(
        _(TXT_DIFF_HEADER_READ_ERROR),
        OnLog);
      Exit;
    end;

    if not CompareMem(
      @DiffHeader.Magic[0],
      @DIFF_MAGIC[1],
      8) then
    begin
      LogMsg(
        _(TXT_INVALID_DIFF_IMAGE),
        OnLog);
      Exit;
    end;

    if DiffHeader.Version <> 1 then
    begin
      LogMsg(
        _(TXT_UNSUPPORTED_DIFF_VERSION),
        OnLog);
      Exit;
    end;

    if DiffHeader.HeaderSize <> SizeOf(TDiffHeader) then
    begin
      LogMsg(
        _(TXT_DIFF_HEADER_SIZE_ERROR),
        OnLog);
      Exit;
    end;

    if DiffHeader.SectorSize <> SectorSize then
    begin
      LogMsg(_(TXT_SECTOR_SIZE_MISMATCH),OnLog);
      Exit;
    end;

    if DiffHeader.SectorCount <> SectorCount then
    begin
      LogMsg(_(TXT_SECTOR_COUNT_ERROR),OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Diff-Bitmap lesen                                              }
    { ------------------------------------------------------------- }

    SetLength(DiffBitmap,SizeInt(BitmapSize));

    if BitmapSize > 0 then
      if not ReadExact(DiffFD,DiffBitmap[0],SizeInt(BitmapSize),ErrorCode) then
      begin
        LogMsg( _(TXT_DIFF_BITMAP_READ_ERROR), OnLog);
        Exit;
      end;

    DiffSectorCount := CountSetBits(DiffBitmap);

    LogMsg(Format(_(TXT_DIFF_INFO),[DiffSectorCount]),OnLog);

    { ------------------------------------------------------------- }
    { ZSTD Decoder                                                    }
    { ------------------------------------------------------------- }

    BaseDctx := ZSTD_createDCtx();

    if BaseDctx = nil then
    begin
      LogMsg(_(TXT_BASE_DECODER_ERROR),OnLog);
      Exit;
    end;

    DiffDctx := ZSTD_createDCtx();

    if DiffDctx = nil then
    begin
      LogMsg(_(TXT_DIFF_DECODER_ERROR),OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Buffer                                                           }
    { ------------------------------------------------------------- }

    SetLength( RestoreBuffer,RESTORE_BLOCK_SIZE);
    SetLength(  BaseInBuffer,ZSTD_BUFFER_SIZE);
     SetLength( BaseOutBuffer,ZSTD_BUFFER_SIZE);
      SetLength(DiffInBuffer,ZSTD_BUFFER_SIZE);
    SetLength(DiffOutBuffer,ZSTD_BUFFER_SIZE);
    FillChar(BaseZIn, SizeOf(BaseZIn),0);
    FillChar(BaseZOut,SizeOf(BaseZOut),0);
    FillChar(DiffZIn, SizeOf(DiffZIn), 0);
     FillChar(DiffZOut, SizeOf(DiffZOut),0);

    BaseZOutPos := 0;
    BaseZOutSize := 0;
    BaseZFinished := False;

    DiffZOutPos := 0;
    DiffZOutSize := 0;
    DiffZFinished := False;

    { ------------------------------------------------------------- }
    { Restore                                                        }
    { ------------------------------------------------------------- }

    while TargetPos < DeviceSize do
    begin
      if terminate_all then
        raise Exception.Create(_(TXT_OPERATION_CANCELLED));

      BlockSize := DeviceSize - TargetPos;

      if BlockSize > RESTORE_BLOCK_SIZE then
        BlockSize := RESTORE_BLOCK_SIZE;

      BlockSectors := BlockSize div SectorSize;

      FillChar(RestoreBuffer[0],SizeInt(BlockSize),0);

      for Sector := 0 to BlockSectors - 1 do
      begin
        TargetSector :=
          uint64(TargetPos) div SectorSize + Sector;

        { Basisdaten }
        if IsSet(BaseBitmap,TargetSector) then
        begin
          if not ReadBaseBytes(@RestoreBuffer[Sector * uint64(SectorSize)],SectorSize) then
            Exit;
        end;

        { Diffdaten überschreiben Basisdaten }
        if IsSet(DiffBitmap,TargetSector) then
        begin
          if not ReadDiffBytes(@RestoreBuffer[Sector * uint64(SectorSize)],SectorSize) then
            Exit;
        end;
      end;

      { ----------------------------------------------------------- }
      { 32-MiB-Block auf das physische Laufwerk schreiben           }
      { Der Dateioffset steht bereits auf TargetOffset + TargetPos. }
      { ----------------------------------------------------------- }

      if not WriteExact(DevFD,RestoreBuffer[0],BlockSize,ErrorCode) then
      begin
        LogMsg(Format(_(TXT_RESTORE_ERROR_MESSAGE),[Format('errno=%d', [ErrorCode])]),OnLog);
        Exit;
      end;

      Inc(TargetPos,BlockSize);

      RawImageBytesProcessed := TargetPos;

      if Assigned(OnProgress) then OnProgress(nil,TargetPos,DeviceSize);
    end;

    { ------------------------------------------------------------- }
    { Datenmengen prüfen                                             }
    { ------------------------------------------------------------- }

    if BaseBytesProduced <>
      int64(BaseHeader.UsedSectors) * SectorSize then
    begin
      LogMsg(_(TXT_BASE_DATA_COUNT_ERROR),OnLog);
      Exit;
    end;

    if DiffBytesRead <> int64(DiffSectorCount) * SectorSize then
    begin
      LogMsg(_(TXT_DIFF_DATA_COUNT_ERROR),OnLog);
      Exit;
    end;

    { ------------------------------------------------------------- }
    { Daten auf das Laufwerk synchronisieren                         }
    { ------------------------------------------------------------- }

    if fpFSync(DevFD) <> 0 then
    begin
      LogMsg(Format(_(TXT_FSYNC_ERROR),[fpGetErrno]),OnLog);
      Exit;
    end;

    LogMsg(_(TXT_RESTORE_SUCCESS),OnLog);

    LogMsg(Format(_(TXT_WRITTEN_DATA),[DeviceSize / 1024 / 1024 / 1024]),OnLog);

    LogMsg(Format(_(TXT_RESTORE_TARGET), [TargetDrive, TargetOffset]),OnLog);

    Result := True;

  except
    on E: Exception do
    begin
      LogMsg(Format( _(TXT_RESTORE_ERROR_MESSAGE), [E.Message]),OnLog);
      Result := False;
    end;
  end;

  { --------------------------------------------------------------- }
  { Aufräumen                                                       }
  { --------------------------------------------------------------- }

  if DiffDctx <> nil then
    ZSTD_freeDCtx(DiffDctx);

  if BaseDctx <> nil then
    ZSTD_freeDCtx(BaseDctx);

  if DiffFD >= 0 then
    fpClose(DiffFD);

  if BaseFD >= 0 then
    fpClose(BaseFD);

  if DevFD >= 0 then
    fpClose(DevFD);
end;


end.
