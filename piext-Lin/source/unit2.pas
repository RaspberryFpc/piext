unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, HtmlView, HtmlGlobals;

type

  { TForm2 }

  TForm2 = class(TForm)
    HtmlViewer1: THtmlViewer;
       procedure FormShow(Sender: TObject);

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
begin
  try
   if currentlanguage = 1 then
                     HtmlViewer1.LoadFromFile(changefileext(application.ExeName,'_en.html'))
                     else
                       HtmlViewer1.LoadFromFile(changefileext(application.ExeName,'_de.html'));
  finally
  end;
end;



end.
