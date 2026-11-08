unit Zstd;

{$mode objfpc}{$H+}

interface

uses
  StdCtrls, Forms, Language;

procedure DecompressFileZstdWithProgress(const InFile, OutFile: string; Listbox: TListBox);

const
  ZSTD_LIB = 'libzstd.dll';

type
  TZSTD_DCtx = Pointer;

  TZSTD_inBuffer = record
    src: Pointer;
    size: SizeUInt;
    pos: SizeUInt;
  end;
  PZSTD_inBuffer = ^TZSTD_inBuffer;

  TZSTD_outBuffer = record
    dst: Pointer;
    size: SizeUInt;
    pos: SizeUInt;
  end;
  PZSTD_outBuffer = ^TZSTD_outBuffer;

function ZSTD_createDCtx: TZSTD_DCtx; cdecl; external ZSTD_LIB;
function ZSTD_freeDCtx(dctx: TZSTD_DCtx): SizeUInt; cdecl; external ZSTD_LIB;
function ZSTD_decompressStream(dctx: TZSTD_DCtx; var output: TZSTD_outBuffer; var input: TZSTD_inBuffer): SizeUInt; cdecl; external ZSTD_LIB;
function ZSTD_isError(code: SizeUInt): LongInt; cdecl; external ZSTD_LIB;
function ZSTD_getErrorName(code: SizeUInt): PChar; cdecl; external ZSTD_LIB;

var
  terminate_all: Boolean = False;

implementation

uses
  Classes, SysUtils, DateUtils, Unit1;

const
  BuSize = 1024 * 1024;

var
  InBuf, OutBuf: array of Byte;

procedure DecompressFileZstdWithProgress(const InFile, OutFile: string; Listbox: TListBox);
var
  fIn, fOut: TFileStream;
  dctx: TZSTD_DCtx;
  input: TZSTD_inBuffer;
  output: TZSTD_outBuffer;
  readBytes: LongInt;
  totalRead, totalWritten, fileSize: Int64;
  ret: SizeUInt;
  startTime, lastUpdateTime: TDateTime;
  elapsedSecs, speedMBs, etaSecs: Double;
  s: string;
  finished: Boolean;
begin
  dctx := nil;
  fIn := nil;
  fOut := nil;

  SetLength(InBuf, BuSize);
  SetLength(OutBuf, BuSize);

  Form1.ProgressBar1.Max := 1000;
  Form1.ProgressBar1.Position := 0;

  try
    fIn := TFileStream.Create(InFile, fmOpenRead or fmShareDenyWrite);
    fOut := TFileStream.Create(OutFile, fmCreate);

    fileSize := fIn.Size;
    totalRead := 0;
    totalWritten := 0;
    startTime := Now;
    lastUpdateTime := startTime;
    ret := 0;

    dctx := ZSTD_createDCtx;
    if dctx = nil then
      raise Exception.Create(_(TXT_ZSTD_CONTEXT_CREATE_ERROR));

    finished := False;

    while not finished do
    begin
      Application.ProcessMessages;

      if terminate_all then
        raise Exception.Create(_(TXT_OPERATION_CANCELLED));

      readBytes := fIn.Read(InBuf[0], BuSize);

      if readBytes = 0 then
      begin
        finished := True;
        Break;
      end;

      Inc(totalRead, readBytes);

      input.src := @InBuf[0];
      input.size := readBytes;
      input.pos := 0;

      repeat
        Application.ProcessMessages;

        if terminate_all then
          raise Exception.Create(_(TXT_OPERATION_CANCELLED));

        output.dst := @OutBuf[0];
        output.size := BuSize;
        output.pos := 0;

        ret := ZSTD_decompressStream(dctx, output, input);

        if ZSTD_isError(ret) <> 0 then
          raise Exception.Create(
            Format(_(TXT_ZSTD_DECOMPRESSION_ERROR), [StrPas(ZSTD_getErrorName(ret))]));

        if output.pos > 0 then
        begin
          fOut.WriteBuffer(OutBuf[0], output.pos);
          Inc(totalWritten, output.pos);
        end;

        if (fileSize > 0) then
          Form1.ProgressBar1.Position :=
            (totalRead * 1000) div fileSize;

      until (input.pos >= input.size) and (output.pos < output.size);

      if (Now - lastUpdateTime) * SecsPerDay >= 0.5 then
      begin
        elapsedSecs := (Now - startTime) * SecsPerDay;

        if elapsedSecs > 0 then
          speedMBs := (totalRead / (1024 * 1024)) / elapsedSecs
        else
          speedMBs := 0;

        if speedMBs > 0 then
          etaSecs := ((fileSize - totalRead) / (1024 * 1024)) / speedMBs
        else
          etaSecs := 0;

        s := Format(_(TXT_ZSTD_PROGRESS),
          [speedMBs, FormatDateTime('nn:ss', etaSecs / SecsPerDay)]);

        lastUpdateTime := Now;
      end;
    end;

    if (totalRead > 0) and (ret <> 0) then
      raise Exception.Create(_(TXT_ZSTD_INCOMPLETE_FILE));

    Form1.ProgressBar1.Position := Form1.ProgressBar1.Max;

  finally
    if dctx <> nil then
      ZSTD_freeDCtx(dctx);

    fIn.Free;
    fOut.Free;
  end;
end;

end.

