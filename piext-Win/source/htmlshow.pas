unit Htmlshow;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, HtmlView, HtmlGlobals, HTMLUn2;

type

  { TForm2 }

  TForm2 = class(TForm)
    HtmlViewer1: THtmlViewer;
       procedure FormShow(Sender: TObject);
       procedure HtmlViewer1BitmapRequest(Sender: TObject;const SRC: ThtString; var Bitmap: TBitmap; var AColor: TColor);

  private

  public

  end;

var
  Form2: TForm2;

implementation

uses language;

{$R *.frm}

{ TForm2 }

procedure TForm2.FormShow(Sender: TObject);
var
  fname:string;
begin
  try
   fname:=extractfilepath(application.ExeName);
   if currentlanguage = 1 then  fname:= fname+ 'PiExtRestorer_en.html' else
                      fname:= fname+ 'PiExtRestorer_de.html';
   if fileexists(fname) then   HtmlViewer1.LoadFromFile(fname);
  finally
  end;
end;

procedure TForm2.HtmlViewer1BitmapRequest(Sender: TObject;  const SRC: ThtString; var Bitmap: TBitmap; var AColor: TColor);
begin

end;



end.
