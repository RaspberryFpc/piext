unit updater;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Process, exebash, fileutil;

type

  { TForm5 }

  TForm5 = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  end;

var
  Form5: TForm5;

procedure CheckForUpdates(memo: Tmemo);

implementation

{$R *.frm}

uses
  fpjson, jsonparser, unit1;

const
  PROG=  'piext';
  REPO = 'RaspberryFpc/'+PROG;
  NEWDEB =      '/var/lib/'+PROG+'/'+PROG+'_new.deb';
  LASTGOODDEB = '/var/lib/'+PROG+'/'+PROG+'_last_good.deb';




var
  RemoteVersion: string;

{ TForm5 }

procedure TForm5.Button1Click(Sender: TObject);
begin
  ModalResult := 1;
end;

procedure TForm5.Button2Click(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure TForm5.Button3Click(Sender: TObject);
begin
  ModalResult := 3;
end;

function GetRemoteVersion: string;
var
  S: string;
  J: TJSONData;
  Tag: string;
begin
  Result := '';

  if not RunCommand('curl -L -s --fail https://api.github.com/repos/' + REPO + '/releases/latest',S) then
                  Exit;

  try
    J := GetJSON(S);
    try
      Tag := Trim(J.FindPath('tag_name').AsString);

      if (Length(Tag) < 5) or (Length(Tag) > 15) then
        Exit;

      if (Tag[1] <> 'v') and (Tag[1] <> 'V') then
        Exit;

      Result := Tag;
    finally
      J.Free;
    end;
  except
    Result := '';
  end;
end;

procedure CommitUpdate;
begin
  DeleteFile(LASTGOODDEB);

  if RenameFile(NEWDEB, LASTGOODDEB) then
    Exit;

  if CopyFile(NEWDEB, LASTGOODDEB) then
    DeleteFile(NEWDEB);
end;

procedure RestartApplication;
var
  P: TProcess;
begin
  P := TProcess.Create(nil);
  try
    P.Executable := '/usr/lib/pibackup/pibackup';
    P.Options := [];
    P.Execute;
  finally
    P.Free;
  end;

  Application.MainForm.Close;
end;

procedure InstallUpdate(memo: Tmemo);
var
  S: string;
  DownloadURL: string;
begin
  ForceDirectories('/var/lib/pibackup');

  DownloadURL :=
    'https://raw.githubusercontent.com/' +
    REPO + '/' + RemoteVersion + '/bin/pibackup.deb';

  S := PrexeBash('wget -O ' + NEWDEB + ' "' + DownloadURL + '"',memo);

  if not FileExists(NEWDEB) then
  begin
    MessageDlg( 'Error','Download failed.',mtError,[mbOK],0);
    Exit;
  end;

  S := PrexeBash('bash -c "sudo env DEBIAN_FRONTEND=noninteractive apt install -y ' + NEWDEB + '"',form1.memo1);

  if LastExitCode = 0 then
  begin
    DeleteFile(NEWDEB);
    DeleteFile(LASTGOODDEB);

    if MessageDlg('updater','Update installed successfully.' + LineEnding +'      Restart pibackup?',
      mtInformation,[mbYes, mbNo],0) = mrYes then
    begin
      RestartApplication;
    end;
  end
  else
  begin
    MessageDlg('updater','Update failed' + LineEnding + 'System remains unchanged.',mtError,[mbOK],0);
  end;
end;

procedure SnoozeInstall;
var
  F: TextFile;
  SnoozeFile: string;
begin
  SnoozeFile := '/var/lib/pibackup/update_snooze.dat';

  try
    ForceDirectories('/var/lib/pibackup');

    AssignFile(F, SnoozeFile);
    Rewrite(F);
    try
      Writeln(F, DateTimeToStr(Now + 3));
    finally
      CloseFile(F);
    end;
  except
    on E: Exception do
      Exit;
  end;

  Form5.Close;
end;

function IsSnoozed: Boolean;
var
  F: TextFile;
  SnoozeFile: string;
  S: string;
  DT: TDateTime;
begin
  Result := False;
  SnoozeFile := '/var/lib/pibackup/update_snooze.dat';

  if not FileExists(SnoozeFile) then
    Exit;

  AssignFile(F, SnoozeFile);
  Reset(F);
  try
    ReadLn(F, S);
  finally
    CloseFile(F);
  end;

  if not TryStrToDateTime(S, DT) then
  begin
    DeleteFile(SnoozeFile);
    Exit;
  end;

  if Now < DT then
    Result := True
  else
  begin
    DeleteFile(SnoozeFile);
    Result := False;
  end;
end;

function VersionToInt64(Ver: string): Int64;
var
  Major, Minor, Patch: Int64;
  P1, P2: Integer;
begin
  if (Copy(Ver, 1, 1) = 'v') or (Copy(Ver, 1, 1) = 'V') then
    Delete(Ver, 1, 1);

  P1 := Pos('.', Ver);
  P2 := Pos('.', Ver, P1 + 1);

  if (P1 = 0) or (P2 = 0) then
  begin
    Result := -1;
    Exit;
  end;

  try
    Major := StrToInt64(Copy(Ver, 1, P1 - 1));
    Minor := StrToInt64(Copy(Ver, P1 + 1, P2 - P1 - 1));
    Patch := StrToInt64(Copy(Ver, P2 + 1, MaxInt));

    Result := Major * 100000000 +
              Minor * 10000 +
              Patch;
  except
    Result := -1;
  end;
end;

procedure CheckForUpdates(memo: Tmemo);
begin
  if IsSnoozed then
    Exit;

  RemoteVersion := GetRemoteVersion;

  if RemoteVersion = '' then
    Exit;

  if VersionToInt64(RemoteVersion) <= VersionToInt64(Version) then
    Exit;

  Form5.Label1.Caption := 'There is a update available';
  Form5.Label2.Caption := 'Do you want install the update?';
  Form5.Label3.Caption := 'Installed: ' + VERSION;
  Form5.Label4.Caption := 'Available: ' + RemoteVersion;

  Form5.ShowModal;

  case Form5.ModalResult of
    1: InstallUpdate(memo);
    2: Exit;
    3: SnoozeInstall;
  end;
end;

end.
