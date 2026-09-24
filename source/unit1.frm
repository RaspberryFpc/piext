object Form1: TForm1
  Left = 199
  Height = 367
  Top = 101
  Width = 489
  AlphaBlend = True
  Anchors = [akTop]
  Caption = 'PiExt'
  ClientHeight = 367
  ClientWidth = 489
  Color = 16777168
  Font.Height = -12
  Position = poDesktopCenter
  LCLVersion = '9.0'
  OnClose = FormClose
  OnCreate = FormCreate
  object ProgressBar1: TProgressBar
    AnchorSideLeft.Control = Label1
    AnchorSideRight.Control = Memo1
    AnchorSideRight.Side = asrBottom
    Left = 16
    Height = 20
    Top = 154
    Width = 457
    Anchors = [akTop, akLeft, akRight]
    TabOrder = 0
  end
  object Memo1: TMemo
    Left = 16
    Height = 176
    Top = 176
    Width = 457
    Lines.Strings = (
      ''
    )
    TabOrder = 1
  end
  object EditImage: TEdit
    AnchorSideLeft.Control = Label2
    AnchorSideLeft.Side = asrBottom
    AnchorSideRight.Control = Memo1
    AnchorSideRight.Side = asrBottom
    Left = 120
    Height = 25
    Top = 65
    Width = 333
    Anchors = [akTop, akRight]
    BorderSpacing.Left = 5
    BorderSpacing.Right = 20
    TabOrder = 2
    OnChange = EditImageChange
  end
  object SpinEdit1: TSpinEdit
    AnchorSideTop.Control = ButtonStart
    AnchorSideTop.Side = asrCenter
    Left = 272
    Height = 26
    Top = 96
    Width = 40
    Anchors = []
    MaxValue = 19
    TabOrder = 3
    Value = 4
    OnChange = SpinEdit1Change
  end
  object ComboBox1: TComboBox
    AnchorSideLeft.Control = EditImage
    AnchorSideRight.Control = Memo1
    AnchorSideRight.Side = asrBottom
    Left = 120
    Height = 25
    Top = 40
    Width = 353
    Anchors = [akTop, akRight]
    ItemHeight = 17
    TabOrder = 4
    OnChange = ComboBox1Change
    OnDropDown = ComboBox1DropDown
  end
  object RadioCreate: TRadioButton
    Left = 80
    Height = 23
    Top = 8
    Width = 62
    Caption = 'Create'
    Checked = True
    TabOrder = 6
    TabStop = True
    OnChange = RadioCreateChange
  end
  object RadioRestore: TRadioButton
    Left = 200
    Height = 23
    Top = 8
    Width = 69
    Caption = 'Restore'
    TabOrder = 5
    OnChange = RadioRestoreChange
  end
  object ButtonStart: TButton
    AnchorSideLeft.Control = Memo1
    Left = 16
    Height = 25
    Top = 125
    Width = 152
    Anchors = [akTop]
    TabOrder = 7
    OnClick = ButtonStartClick
  end
  object Button1: TButton
    AnchorSideLeft.Control = EditImage
    AnchorSideLeft.Side = asrBottom
    AnchorSideTop.Control = EditImage
    AnchorSideRight.Control = Memo1
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = EditImage
    AnchorSideBottom.Side = asrBottom
    Left = 452
    Height = 25
    Top = 65
    Width = 21
    Anchors = [akTop, akRight, akBottom]
    Caption = '▼'
    Font.Color = clMedGray
    Font.Height = -9
    ParentFont = False
    TabOrder = 8
    OnClick = Button1Click
  end
  object Label1: TLabel
    AnchorSideLeft.Control = Memo1
    AnchorSideTop.Control = ComboBox1
    AnchorSideTop.Side = asrCenter
    Left = 16
    Height = 17
    Top = 44
    Width = 37
    Caption = 'Device'
  end
  object Label2: TLabel
    AnchorSideLeft.Control = Memo1
    AnchorSideTop.Control = EditImage
    AnchorSideTop.Side = asrCenter
    Left = 16
    Height = 17
    Top = 69
    Width = 75
    Caption = 'Target Folder'
  end
  object Label3: TLabel
    AnchorSideTop.Control = ButtonStart
    AnchorSideTop.Side = asrCenter
    Left = 152
    Height = 17
    Top = 103
    Width = 106
    Anchors = []
    Caption = 'Compression Level'
  end
  object Button2: TButton
    Left = 440
    Height = 25
    Top = 8
    Width = 32
    Caption = 'Button2'
    TabOrder = 9
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 376
    Height = 25
    Top = 8
    Width = 58
    Caption = 'help'
    TabOrder = 10
    OnClick = Button3Click
  end
  object ButtonCancel: TButton
    AnchorSideLeft.Control = Memo1
    AnchorSideTop.Control = ButtonStart
    AnchorSideBottom.Control = ButtonStart
    AnchorSideBottom.Side = asrBottom
    Left = 168
    Height = 25
    Top = 125
    Width = 152
    Anchors = [akTop, akBottom]
    TabOrder = 11
    OnClick = ButtonCancelClick
  end
  object Button4: TButton
    AnchorSideTop.Control = ButtonStart
    AnchorSideRight.Control = Memo1
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = ButtonStart
    AnchorSideBottom.Side = asrBottom
    Left = 320
    Height = 25
    Top = 125
    Width = 153
    Anchors = [akTop, akLeft, akRight, akBottom]
    Caption = 'Button4'
    TabOrder = 12
  end
  object SelectDirectoryDialog1: TSelectDirectoryDialog
    Left = 120
    Top = 224
  end
  object OpenDialog1: TOpenDialog
    Left = 72
    Top = 216
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 296
    Top = 189
  end
end
