object Form1: TForm1
  AnchorSideTop.Side = asrCenter
  Left = 201
  Height = 367
  Top = 99
  Width = 582
  AlphaBlend = True
  Anchors = []
  Caption = 'PiExt'
  ClientHeight = 367
  ClientWidth = 582
  Color = 16777168
  Font.Height = -12
  Position = poDesktopCenter
  LCLVersion = '8.8'
  OnClose = FormClose
  OnCreate = FormCreate
  object ProgressBar1: TProgressBar
    AnchorSideLeft.Control = LabelTarget
    AnchorSideRight.Control = Memo1
    AnchorSideRight.Side = asrBottom
    Left = 15
    Height = 20
    Top = 148
    Width = 552
    Anchors = [akTop, akLeft, akRight]
    TabOrder = 0
  end
  object Memo1: TMemo
    AnchorSideLeft.Control = Owner
    AnchorSideRight.Control = Owner
    AnchorSideRight.Side = asrBottom
    Left = 15
    Height = 173
    Top = 170
    Width = 552
    Anchors = [akTop, akLeft, akRight]
    BorderSpacing.Left = 15
    BorderSpacing.Right = 15
    Lines.Strings = (
      ''
    )
    ScrollBars = ssAutoVertical
    TabOrder = 1
  end
  object ComboBox1: TComboBox
    AnchorSideRight.Control = Memo1
    AnchorSideRight.Side = asrBottom
    Left = 103
    Height = 23
    Top = 64
    Width = 464
    Anchors = [akTop, akLeft, akRight]
    ItemHeight = 15
    TabOrder = 2
    OnDropDown = ComboBox1DropDown
  end
  object ButtonStart: TButton
    Left = 30
    Height = 24
    Top = 120
    Width = 128
    Caption = 'Start'
    TabOrder = 3
    OnClick = ButtonStartClick
  end
  object LabelTarget: TLabel
    AnchorSideLeft.Control = Memo1
    AnchorSideTop.Control = ComboBox1
    AnchorSideTop.Side = asrCenter
    Left = 15
    Height = 15
    Top = 68
    Width = 70
    Caption = 'Target device'
  end
  object Bt_language: TButton
    Left = 440
    Height = 25
    Top = 8
    Width = 32
    Caption = 'DE'
    TabOrder = 4
    OnClick = Bt_languageClick
  end
  object Button3: TButton
    Left = 376
    Height = 25
    Top = 8
    Width = 58
    Caption = 'help'
    TabOrder = 5
    OnClick = Button3Click
  end
  object ButtonCancel: TButton
    AnchorSideTop.Control = ButtonStart
    AnchorSideBottom.Control = ButtonStart
    AnchorSideBottom.Side = asrBottom
    Left = 192
    Height = 24
    Top = 120
    Width = 128
    Anchors = [akTop, akLeft, akBottom]
    Enabled = False
    TabOrder = 6
    OnClick = ButtonCancelClick
  end
  object cb_mbr: TCheckBox
    Left = 192
    Height = 19
    Top = 96
    Width = 43
    Caption = 'MBR'
    Checked = True
    State = cbChecked
    TabOrder = 7
  end
  object cb_boot: TCheckBox
    Left = 272
    Height = 19
    Top = 96
    Width = 50
    Caption = 'BOOT'
    Checked = True
    State = cbChecked
    TabOrder = 8
  end
  object cb_system: TCheckBox
    Left = 352
    Height = 19
    Top = 96
    Width = 61
    Caption = 'SYSTEM'
    Checked = True
    State = cbChecked
    TabOrder = 9
  end
  object EditImage: TEdit
    AnchorSideLeft.Control = ComboBox1
    AnchorSideRight.Control = Button1
    Left = 103
    Height = 23
    Top = 40
    Width = 443
    Anchors = [akLeft, akRight]
    TabOrder = 10
  end
  object LabelImage: TLabel
    Left = 16
    Height = 15
    Top = 45
    Width = 55
    Caption = 'Source file'
  end
  object Button1: TButton
    AnchorSideTop.Control = EditImage
    AnchorSideTop.Side = asrCenter
    AnchorSideRight.Control = Owner
    AnchorSideRight.Side = asrBottom
    AnchorSideBottom.Control = EditImage
    AnchorSideBottom.Side = asrBottom
    Left = 546
    Height = 25
    Top = 39
    Width = 21
    Anchors = [akTop, akRight]
    BorderSpacing.Right = 15
    Caption = '∨'
    TabOrder = 11
    OnClick = Button1Click
  end
  object Label1: TLabel
    Left = 16
    Height = 25
    Top = 96
    Width = 178
    Alignment = taCenter
    AutoSize = False
    Caption = 'Wiederherstellung von:'
    Font.Height = -15
    ParentFont = False
  end
  object Bt_speed: TButton
    Left = 355
    Height = 25
    Top = 120
    Width = 203
    DoubleBuffered = True
    ParentDoubleBuffered = False
    TabOrder = 12
  end
  object OpenDialog1: TOpenDialog
    Left = 72
    Top = 209
  end
end
