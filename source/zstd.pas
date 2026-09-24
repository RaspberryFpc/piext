  unit Zstd;

{$mode objfpc}{$H+}

interface

uses
  baseunix, StdCtrls, Forms,Language;

procedure CompressFileZstdWithProgress(const InFile, OutFile: string; Level, ThreadCount: integer; UseLongMode: boolean; listbox: Tlistbox);

const
  ZSTD_LIB = 'libzstd.so';

const
  ZSTD_c_compressionLevel           = 100;
  ZSTD_c_windowLog                  = 101;
  ZSTD_c_nbWorkers                  = 400;
  ZSTD_c_enableLongDistanceMatching = 160;

  ZSTD_e_continue = 0;
  ZSTD_e_end      = 2;

type
  TZSTD_DStream = Pointer;
  TZSTD_CCtx = Pointer;
  TZSTD_DCtx = Pointer;

  TZSTD_inBuffer = record
    src: Pointer;
    size: nativeuint;
    pos: nativeuint;
  end;
  PZSTD_inBuffer = ^TZSTD_inBuffer;

  TZSTD_outBuffer = record
    dst: Pointer;
    size: nativeuint;
    pos: nativeuint;
  end;
  PZSTD_outBuffer = ^TZSTD_outBuffer;

function ZSTD_createCCtx(): TZSTD_CCtx; cdecl; external ZSTD_LIB;
function ZSTD_freeCCtx(cctx: TZSTD_CCtx): nativeuint; cdecl; external ZSTD_LIB;
function ZSTD_CCtx_setParameter(cctx: TZSTD_CCtx; param: cint; Value: cint): nativeuint; cdecl; external ZSTD_LIB;
function ZSTD_compressStream2(cctx: TZSTD_CCtx; output: PZSTD_outBuffer; input: PZSTD_inBuffer; endOp: integer): nativeuint; cdecl; external ZSTD_LIB;
function ZSTD_initDStream(dstream: TZSTD_DStream): size_t; cdecl; external ZSTD_LIB;
function ZSTD_versionNumber: cardinal; cdecl; external ZSTD_LIB;

function ZSTD_createDCtx(): TZSTD_DCtx; cdecl; external ZSTD_LIB;
function ZSTD_freeDCtx(dctx: TZSTD_DCtx): nativeuint; cdecl; external ZSTD_LIB;
function ZSTD_decompressStream(dctx: TZSTD_DCtx; var output: TZSTD_outBuffer; var input: TZSTD_inBuffer): nativeuint; cdecl; external ZSTD_LIB;

function ZSTD_isError(code: nativeuint): cint; cdecl; external ZSTD_LIB;
function ZSTD_getErrorName(code: nativeuint): pchar; cdecl; external ZSTD_LIB;

var
  terminate_all:boolean=false;

implementation

uses
  Classes, SysUtils, DateUtils, unit1;

function GetCPUCount: integer;
var
  f: TextFile;
  line: string;
begin
  Result := 0;
  AssignFile(f, '/proc/cpuinfo');
  Reset(f);
  try
    while not EOF(f) do
    begin
      ReadLn(f, line);
      if Pos('processor', line) = 1 then
        Inc(Result);
    end;
  finally
    CloseFile(f);
  end;
  if Result = 0 then
    Result := 1;
end;

const
  BuSize = 32 * 1024 * 1024;

var
  InBuf, OutBuf: array[0..BuSize - 1] of byte;

procedure CompressFileZstdWithProgress(const InFile, OutFile: string; Level, ThreadCount: integer; UseLongMode: boolean; Listbox: TListBox);
var
  input, output: record
    src: Pointer;
    size, pos: SizeUInt;
    end;

  fIn, fOut: TFileStream;
  cctx: Pointer;
  readBytes: integer;
  totalWritten, fileSize, totalRead: int64;
  ret: SizeUInt;
  startTime, lastUpdateTime: TDateTime;
  elapsedSecs, etaSecs, speedMBs: double;
  compressionRatio: double;
  s: string;

  procedure Compressblock(endMode: cardinal);
  begin
    repeat
      application.ProcessMessages;
      if terminate_all then
        raise Exception.Create(_(TXT_OPERATION_CANCELLED));

      output.src := @OutBuf;
      output.size := BuSize;
      output.pos := 0;

      ret := ZSTD_compressStream2(cctx, @output, @input, endMode);
      if ZSTD_isError(ret) <> 0 then
        raise Exception.Create(Format(_(TXT_ZSTD_COMPRESSION_ERROR) + ' %s', [StrPas(ZSTD_getErrorName(ret))]));

      if output.pos > 0 then
      begin
        fOut.Write(OutBuf, output.pos);
        Inc(totalWritten, output.pos);
      end;
    until ((endMode = ZSTD_e_continue) and (input.pos >= input.size)) or ((endMode = ZSTD_e_end) and (ret = 0));
  end;

begin
  form1.ProgressBar1.Max := 1000;
  form1.ProgressBar1.Position := 0;

  ThreadCount := GetCPUCount;

  fIn := TFileStream.Create(InFile, fmOpenRead);
  fOut := TFileStream.Create(OutFile, fmCreate);
  try
    fileSize := fIn.Size;
    totalWritten := 0;
    totalRead := 0;
    startTime := Now;
    lastUpdateTime := 0;

    cctx := ZSTD_createCCtx();
    if cctx = nil then
      raise Exception.Create(_(TXT_ZSTD_CONTEXT_ERROR));

    ret := ZSTD_CCtx_setParameter(cctx, ZSTD_c_compressionLevel, Level);
    if ZSTD_isError(ret) <> 0 then
      raise Exception.Create(Format(_(TXT_ZSTD_LEVEL_ERROR) + ' %s', [StrPas(ZSTD_getErrorName(ret))]));

    ret := ZSTD_CCtx_setParameter(cctx, ZSTD_c_nbWorkers, ThreadCount);
    if ZSTD_isError(ret) <> 0 then
      raise Exception.Create(Format(_(TXT_ZSTD_THREADS_ERROR) + ' %s', [StrPas(ZSTD_getErrorName(ret))]));

    if UseLongMode then
    begin
      ret := ZSTD_CCtx_setParameter(cctx, ZSTD_c_enableLongDistanceMatching, 1);
      if ZSTD_isError(ret) <> 0 then
        raise Exception.Create(Format(_(TXT_ZSTD_LONG_ERROR) + ' %s', [StrPas(ZSTD_getErrorName(ret))]));
    end;

    while True do
    begin
      if terminate_all then
        raise Exception.Create(_(TXT_OPERATION_CANCELLED));

      readBytes := fIn.Read(InBuf, BuSize);
      if readBytes = 0 then
        Break;

      input.src := @InBuf;
      input.size := readBytes;
      input.pos := 0;

      Inc(totalRead, readBytes);
      Compressblock(ZSTD_e_continue);

      form1.ProgressBar1.Position := totalRead * 1000 div fileSize;

      elapsedSecs := (Now - startTime) * SecsPerDay;
      if (Now - lastUpdateTime) * SecsPerDay > 0.5 then
      begin
        if elapsedSecs > 0 then
          speedMBs := (totalRead / (1024 * 1024)) / elapsedSecs
        else
          speedMBs := 0;

        if speedMBs > 0 then
          etaSecs := ((fileSize - totalRead) / (1024 * 1024)) / speedMBs
        else
          etaSecs := 0;

        if totalWritten > 0 then
          compressionRatio := totalRead / totalWritten
        else
          compressionRatio := 0;

        s := Format(_(TXT_ZSTD_SPEED_ETA_RATIO), [speedMBs, FormatDateTime('nn:ss', etaSecs / SecsPerDay), compressionRatio]);

        lastUpdateTime := Now;
      end;
    end;

    input.src := nil;
    input.size := 0;
    input.pos := 0;
    Compressblock(ZSTD_e_end);

    s := Format(_(TXT_ZSTD_SPEED_ETA_RATIO), [speedMBs, FormatDateTime('nn:ss', 0), compressionRatio]);

    form1.ProgressBar1.Position := form1.ProgressBar1.Max;

  finally
    ZSTD_freeCCtx(cctx);
    fIn.Free;
    fOut.Free;
  end;
end;

end.
