object Form2: TForm2
  Left = 341
  Height = 459
  Top = 43
  Width = 910
  BorderStyle = bsSingle
  ClientHeight = 459
  ClientWidth = 910
  Position = poDesktopCenter
  LCLVersion = '9.0'
  OnShow = FormShow
  object HtmlViewer1: THtmlViewer
    AnchorSideLeft.Control = Owner
    AnchorSideTop.Control = Owner
    AnchorSideRight.Control = Owner
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = Owner
    AnchorSideBottom.Side = asrBottom
    Left = 0
    Height = 459
    Top = 0
    Width = 910
    BorderStyle = htFocused
    HistoryMaxCount = 0
    NoSelect = False
    PrintMarginBottom = 2
    PrintMarginLeft = 2
    PrintMarginRight = 2
    PrintMarginTop = 2
    PrintScale = 1
    Anchors = [akTop, akLeft, akRight, akBottom]
    TabOrder = 0
  end
end
