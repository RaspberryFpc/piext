unit exethread;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, StdCtrls;

type
  TPrexeThreaded = class(TThread)
  private
    FCmd: string;
    FParams: array of string;
    FMemo: TMemo;
    FPass: integer;
    FResult: string;
    FTempString: string;
    Fdelcount: integer;
    FCurrentLine: string;
    FCurrentMemoLine: integer;
    FCursorPos: integer;
    FFinished: boolean;
    FExitCode: integer;
    FDebugFile: TFileStream;
    FDebugOffset: int64;

    procedure MemoAddtoline;
    procedure MemoAddLine;
    procedure memoclearline;
    procedure memobackspace;

    procedure memoaddtext;
    procedure memodeltext;
    procedure memotext;

    procedure DebugWrite(const Data: pchar; DataSize: integer);
  protected
    procedure Execute; override;
  public
    constructor Create(const Cmd: string; const Params: array of string; Memo: TMemo; Pass: integer = 0);
    property ResultText: string read FResult;
    property ExitCode: integer read FExitCode;
    property Finished: boolean read FFinished;
  end;

var
  LastExitCode: integer = -1;

function PrexeThreaded(const Cmd: string; const Params: array of string; Memo: TMemo; Pass: integer = 0): string;
function PrexeThreadedBash(const Command: string; Memo: TMemo; Pass: integer = 0): string;

implementation

var
  sl: TStringList;

procedure Mtext(fmemo: TMemo);
begin
  if not Assigned(FMemo) then Exit;

  FMemo.Text := sl.Text;
  FMemo.SelStart := Length(FMemo.Text);
  FMemo.SelLength := 0;
  FMemo.Repaint;
end;

procedure TPrexeThreaded.Memotext;
begin
  if not Assigned(FMemo) then Exit;
  Mtext(FMemo);
end;

procedure MAddLine(fmemo: TMemo);
begin
  if not Assigned(FMemo) then Exit;

  FMemo.Lines.Add('');
  FMemo.SelStart := Length(FMemo.Text);
  FMemo.SelLength := 0;
  FMemo.Repaint;
end;

procedure TPrexeThreaded.MemoAddLine;
begin
  if not Assigned(FMemo) then Exit;
  MAddLine(FMemo);
end;

procedure Maddtoline(s: string; fmemo: TMemo);
var
  FCurrentMemoLine: integer;
begin
  if not Assigned(FMemo) then Exit;

  FCurrentMemoLine := FMemo.Lines.Count - 1;

  if FCurrentMemoLine >= 0 then
    FMemo.Lines[FCurrentMemoLine] := FMemo.Lines[FCurrentMemoLine] + s;

  FMemo.SelLength := 0;
  FMemo.SelStart := Length(FMemo.Text);
  FMemo.Repaint;
end;

procedure TPrexeThreaded.Memoaddtoline;
begin
  if not Assigned(FMemo) then Exit;
  Maddtoline(FTempString, FMemo);
end;

procedure mclearline(fmemo: TMemo);
begin
  if not Assigned(FMemo) then Exit;

  if FMemo.Lines.Count > 0 then
    FMemo.Lines.Delete(FMemo.Lines.Count - 1);
end;

procedure TPrexeThreaded.memoclearline;
begin
  mclearline(FMemo);
end;

procedure mbackspace(fmemo: TMemo);
var
  s: string;
begin
  if not Assigned(FMemo) then Exit;
  if FMemo.Lines.Count = 0 then Exit;

  s := FMemo.Lines[FMemo.Lines.Count - 1];

  if Length(s) > 0 then
    Delete(s, Length(s), 1);

  FMemo.Lines[FMemo.Lines.Count - 1] := s;
end;

procedure TPrexeThreaded.memobackspace;
begin
  mbackspace(FMemo);
end;

procedure maddtext(tempstr: string; fmemo: TMemo);
begin
  if not Assigned(FMemo) then Exit;
  FMemo.Text := FMemo.Text + tempstr;
end;

procedure TPrexeThreaded.memoaddtext;
begin
  maddtext(FTempString, FMemo);
end;

procedure mdeltextfmemo(delcount: integer; fmemo: TMemo);
var
  s: string;
begin
  if not Assigned(FMemo) then Exit;

  s := FMemo.Text;

  if delcount > Length(s) then
    delcount := Length(s);

  if delcount > 0 then
    Delete(s, Length(s) + 1 - delcount, delcount);

  FMemo.Text := s;
end;

procedure TPrexeThreaded.memodeltext;
begin
  mdeltextfmemo(Fdelcount, FMemo);
end;

procedure TPrexeThreaded.DebugWrite(const Data: pchar; DataSize: integer);
var
  I: integer;
  Line: string;
  HexPart: string;
  AsciiPart: string;
  B: byte;
  C: char;
begin
  if not Assigned(FDebugFile) then Exit;
  if DataSize <= 0 then Exit;

  I := 0;

  while I < DataSize do
  begin
    Line := Format('%.8x  ', [FDebugOffset]);
    HexPart := '';
    AsciiPart := '';

    while (I < DataSize) and (Length(HexPart) < 48) do
    begin
      B := byte(Data[I]);

      HexPart := HexPart + IntToHex(B, 2) + ' ';

      if (B >= 32) and (B <= 126) then
        C := char(B)
      else
        C := '.';

      AsciiPart := AsciiPart + C;

      Inc(I);
      Inc(FDebugOffset);
    end;

    while Length(HexPart) < 48 do
      HexPart := HexPart + ' ';

    Line := Line + HexPart + ' |' + AsciiPart + '|' + LineEnding;

    FDebugFile.WriteBuffer(Line[1], Length(Line));
  end;

  FDebugFile.Flush;
end;

constructor TPrexeThreaded.Create(const Cmd: string; const Params: array of string; Memo: TMemo; Pass: integer);
var
  I: integer;
begin
  inherited Create(True);

  FreeOnTerminate := False;

  FCmd := Cmd;

  SetLength(FParams, Length(Params));

  for I := 0 to High(Params) do
    FParams[I] := Params[I];

  FMemo := Memo;
  FPass := Pass;

  FResult := '';
  FTempString := '';
  FCurrentLine := '';
  FCurrentMemoLine := -1;
  FCursorPos := 0;

  FFinished := False;
  FExitCode := -1;

  FDebugFile := nil;
  FDebugOffset := 0;
end;

procedure TPrexeThreaded.Execute;
var
  Pr: TProcess;
  Buffer: array[0..2048] of byte;
  BytesRead: integer;
  I: integer;
  StartCount: integer;
  ch: char;

  procedure ProcessOutput(const Data: pchar; DataSize: integer; memo: TMemo);
  var
    x: integer;
    s: string;
  begin
    DebugWrite(Data, DataSize);

    for x := 0 to DataSize - 1 do
    begin
      ch := Data[x];

      { CR = Cursor an den Anfang der aktuellen Zeile }
      if ch = #13 then
      begin
        FCursorPos := 0;
        Continue;
      end;

      { LF = neue Zeile }
      if ch = #10 then
      begin
        if FCurrentMemoLine < 0 then
        begin
          sl.Add('');
          FCurrentMemoLine := sl.Count - 1;
        end;

        sl.Add('');
        FCurrentMemoLine := sl.Count - 1;
        FCursorPos := 0;
        Continue;
      end;

      { Backspace = Cursor eine Position zurück }
      if ch = #8 then
      begin
        if FCursorPos > 0 then
          Dec(FCursorPos);

        Continue;
      end;

      { Andere Steuerzeichen ignorieren }
      if Ord(ch) < 32 then
        Continue;

      { Sicherstellen, dass eine aktuelle Zeile existiert }
      if FCurrentMemoLine < 0 then
      begin
        sl.Add('');
        FCurrentMemoLine := sl.Count - 1;
        FCursorPos := 0;
      end;

      s := sl[FCurrentMemoLine];

      { Cursorposition liegt hinter dem bisherigen Text }
      while Length(s) < FCursorPos do
        s := s + ' ';

      { Zeichen an Cursorposition schreiben }
      if FCursorPos < Length(s) then
      begin
        s[FCursorPos + 1] := ch;
      end
      else
      begin
        s := s + ch;
      end;

      sl[FCurrentMemoLine] := s;

      Inc(FCursorPos);
    end;

    Synchronize(@Memotext);
  end;

begin
  Pr := TProcess.Create(nil);

  try
    FDebugFile := TFileStream.Create('/tmp/piext_output.hex', fmCreate);
    FDebugOffset := 0;

    Pr.Executable := FCmd;

    for I := 0 to High(FParams) do
      Pr.Parameters.Add(FParams[I]);

    Pr.Options := [poUsePipes, poStderrToOutPut, poDefaultErrorMode];

    Pr.PipeBufferSize := 2048;

    { Cursor befindet sich zunächst am Ende des letzten vorhandenen Textes }
    if sl.Count > 0 then
    begin
      FCurrentMemoLine := sl.Count - 1;
      FCursorPos := Length(sl[FCurrentMemoLine]);
    end
    else
    begin
      sl.Add('');
      FCurrentMemoLine := 0;
      FCursorPos := 0;
    end;

    Pr.Execute;

    while Pr.Running do
    begin
      if Terminated then
      begin
        Pr.Terminate(0);
        Break;
      end;

      if Pr.Output.NumBytesAvailable > 0 then
      begin
        BytesRead := Pr.Output.Read(Buffer, SizeOf(Buffer));

        if BytesRead > 0 then
          ProcessOutput(PChar(@Buffer[0]), BytesRead, FMemo);
      end
      else
        Sleep(10);
    end;

    { Restliche Daten lesen }
    while Pr.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Pr.Output.Read(Buffer, SizeOf(Buffer));

      if BytesRead > 0 then
        ProcessOutput(PChar(@Buffer[0]), BytesRead, FMemo)
      else
        Break;
    end;

    Pr.WaitOnExit;

    FExitCode := Pr.ExitStatus;

    { Ergebnis aus dem Memo aufbauen }
    if Assigned(FMemo) then
    begin
      FResult := '';

      for I := StartCount - 1 to FMemo.Lines.Count - 1 do
      begin
        if FResult <> '' then
          FResult := FResult + LineEnding;

        FResult := FResult + FMemo.Lines[I];
      end;
    end;

    FFinished := True;

  finally
    if Assigned(FDebugFile) then
    begin
      FDebugFile.Free;
      FDebugFile := nil;
    end;

    Pr.Free;
  end;
end;

function PrexeThreaded(const Cmd: string; const Params: array of string; Memo: TMemo; Pass: integer): string;
var
  T: TPrexeThreaded;
begin
  sl := TStringList.Create;

  if Assigned(Memo) then
    sl.Text := Memo.Text;

  T := TPrexeThreaded.Create(Cmd, Params, Memo, Pass);

  try
    T.Start;
    T.WaitFor;

    Result := T.ResultText;
    LastExitCode := T.ExitCode;
  finally
    T.Free;
    sl.Free;
    sl := nil;
  end;
end;

function PrexeThreadedBash(const Command: string; Memo: TMemo; Pass: integer): string;
var
  Params: array[0..1] of string;
begin
  Params[0] := '-c';
  Params[1] := Command;

  Result := PrexeThreaded('bash', Params, Memo, Pass);
end;

end.
