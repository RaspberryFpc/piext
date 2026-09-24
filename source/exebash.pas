unit exebash;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Process, BaseUnix, Unix, LazUTF8, FileUtil, DateUtils,
  StdCtrls, Forms, Dialogs, ExtCtrls, ComCtrls;

function PrexeBash(Command: ansistring; Memo: TMemo): ansistring;

var
  LastExitCode: Integer;

implementation

procedure MemoAddScroll(Memo: TMemo; const S: string);
begin
  Memo.Lines.Add(S);
  Memo.SelStart := Length(Memo.Text);
end;

function PrexeBash(Command: ansistring; Memo: TMemo): ansistring;
const
  BufferSize = 2048;
var
  Pr: TProcess;
  Buf: array[0..BufferSize - 1] of Char;
  BytesRead, CPos, I, StartCount, XPos: Integer;
  SU, SM: ansistring;
begin
  LastExitCode := -1;
  Result := '';
  XPos := 0;

  if Assigned(Memo) then
  begin
    MemoAddScroll(Memo, '');
    StartCount := Memo.Lines.Count - 1;
  end
  else
    StartCount := 0;

  Pr := TProcess.Create(nil);
  try
    Pr.Executable := 'bash';
    Pr.Options := [poUsePipes, poStderrToOutPut, poDefaultErrorMode];
    Pr.PipeBufferSize := BufferSize;
    Pr.Parameters.Add('-c');
    Pr.Parameters.Add(Command);
    Pr.Execute;

    while Pr.Running do
    begin
      Application.ProcessMessages;
      Sleep(20);

      while Pr.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := Pr.Output.Read(Buf, BufferSize);
        CPos := 0;

        repeat
          SU := '';

          while (CPos < BytesRead) and (Buf[CPos] > #31) do
          begin
            SU := SU + Buf[CPos];
            Inc(CPos);
          end;

          if SU <> '' then
          begin
            if Assigned(Memo) then
            begin
              SM := Memo.Lines[Memo.Lines.Count - 1];
              Insert(SU, SM, XPos + 1);
              Inc(XPos, Length(SU));
              Delete(SM, XPos + 1, Length(SU));
              Memo.Lines[Memo.Lines.Count - 1] := SM;
              Memo.SelStart := Length(Memo.Text);
            end;
          end;

          if CPos < BytesRead then
          begin
            case Buf[CPos] of
              #10:
                begin
                  Inc(CPos);
                  XPos := 0;
                  if Assigned(Memo) then
                    MemoAddScroll(Memo, '');
                end;
              #13:
                begin
                  Inc(CPos);
                  XPos := 0;
                end;
              #8:
                begin
                  Inc(CPos);
                  Dec(XPos);
                  if XPos < 0 then
                    XPos := 0;
                end;
            end;
          end
          else
            Inc(CPos);
        until CPos >= BytesRead;
      end;
    end;

    while Pr.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Pr.Output.Read(Buf, BufferSize);
      CPos := 0;

      repeat
        SU := '';

        while (CPos < BytesRead) and (Buf[CPos] > #31) do
        begin
          SU := SU + Buf[CPos];
          Inc(CPos);
        end;

        if SU <> '' then
        begin
          if Assigned(Memo) then
          begin
            SM := Memo.Lines[Memo.Lines.Count - 1];
            Insert(SU, SM, XPos + 1);
            Inc(XPos, Length(SU));
            Delete(SM, XPos + 1, Length(SU));
            Memo.Lines[Memo.Lines.Count - 1] := SM;
            Memo.SelStart := Length(Memo.Text);
          end;
        end;

        if CPos < BytesRead then
        begin
          case Buf[CPos] of
            #10:
              begin
                Inc(CPos);
                XPos := 0;
                if Assigned(Memo) then
                  MemoAddScroll(Memo, '');
              end;
            #13:
              begin
                Inc(CPos);
                XPos := 0;
              end;
            #8:
              begin
                Inc(CPos);
                Dec(XPos);
                if XPos < 0 then
                  XPos := 0;
              end;
          end;
        end
        else
          Inc(CPos);
      until CPos >= BytesRead;
    end;

    Pr.WaitOnExit;
    LastExitCode := Pr.ExitStatus;

    if Assigned(Memo) then
      for I := StartCount to Memo.Lines.Count - 1 do
        Result := Result + Memo.Lines[I] + sLineBreak;
  finally
    Pr.Free;
  end;
end;

end.
