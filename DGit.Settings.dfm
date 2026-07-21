object frmDGitSettings: TfrmDGitSettings
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'DGit Project Settings'
  ClientHeight = 477
  ClientWidth = 752
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnShow = FormShow
  TextHeight = 15
  object Label1: TLabel
    Left = 233
    Top = 453
    Width = 298
    Height = 15
    Cursor = crHandPoint
    Hint = 'Open Github'
    Caption = 'Programmed by Yu'#351'a G'#246'verdik (github.com/yushadev0)'
    ParentShowHint = False
    ShowHint = True
    OnClick = Label1Click
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 353
    Height = 217
    Caption = 'User Identity'
    TabOrder = 0
    object edtUserName: TLabeledEdit
      AlignWithMargins = True
      Left = 22
      Top = 47
      Width = 309
      Height = 36
      Margins.Left = 20
      Margins.Top = 30
      Margins.Right = 20
      Align = alTop
      EditLabel.Width = 56
      EditLabel.Height = 28
      EditLabel.Caption = 'Name:'
      EditLabel.Font.Charset = DEFAULT_CHARSET
      EditLabel.Font.Color = clWindowText
      EditLabel.Font.Height = -20
      EditLabel.Font.Name = 'Segoe UI'
      EditLabel.Font.Style = []
      EditLabel.ParentFont = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = ''
    end
    object edtUserEmail: TLabeledEdit
      AlignWithMargins = True
      Left = 22
      Top = 116
      Width = 309
      Height = 36
      Margins.Left = 20
      Margins.Top = 30
      Margins.Right = 20
      Align = alTop
      EditLabel.Width = 51
      EditLabel.Height = 28
      EditLabel.Caption = 'Email:'
      EditLabel.Font.Charset = DEFAULT_CHARSET
      EditLabel.Font.Color = clWindowText
      EditLabel.Font.Height = -20
      EditLabel.Font.Name = 'Segoe UI'
      EditLabel.Font.Style = []
      EditLabel.ParentFont = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = ''
    end
    object rbGlobal: TRadioButton
      Left = 69
      Top = 168
      Width = 142
      Height = 33
      Caption = 'Global'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      TabStop = True
    end
    object rbLocal: TRadioButton
      Left = 217
      Top = 168
      Width = 142
      Height = 33
      Caption = 'Local'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
  end
  object GroupBox2: TGroupBox
    Left = 381
    Top = 8
    Width = 361
    Height = 217
    Caption = 'Remote Repository (for this project)'
    TabOrder = 1
    object edtRemoteUrl: TLabeledEdit
      AlignWithMargins = True
      Left = 22
      Top = 131
      Width = 317
      Height = 36
      Margins.Left = 20
      Margins.Top = 30
      Margins.Right = 20
      Align = alTop
      EditLabel.Width = 111
      EditLabel.Height = 28
      EditLabel.Caption = 'Remote URL:'
      EditLabel.Font.Charset = DEFAULT_CHARSET
      EditLabel.Font.Color = clWindowText
      EditLabel.Font.Height = -20
      EditLabel.Font.Name = 'Segoe UI'
      EditLabel.Font.Style = []
      EditLabel.ParentFont = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = ''
    end
    object edtRemoteName: TLabeledEdit
      AlignWithMargins = True
      Left = 22
      Top = 62
      Width = 317
      Height = 36
      Margins.Left = 20
      Margins.Top = 45
      Margins.Right = 20
      Align = alTop
      EditLabel.Width = 128
      EditLabel.Height = 28
      EditLabel.Caption = 'Remote Name:'
      EditLabel.Font.Charset = DEFAULT_CHARSET
      EditLabel.Font.Color = clWindowText
      EditLabel.Font.Height = -20
      EditLabel.Font.Name = 'Segoe UI'
      EditLabel.Font.Style = []
      EditLabel.ParentFont = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = 'origin'
    end
  end
  object btnSave: TButton
    Left = 262
    Top = 399
    Width = 105
    Height = 41
    Caption = 'Save'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -20
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = btnSaveClick
  end
  object btnCancel: TButton
    Left = 386
    Top = 399
    Width = 105
    Height = 41
    Caption = 'Cancel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -20
    Font.Name = 'Segoe UI'
    Font.Style = []
    ModalResult = 2
    ParentFont = False
    TabOrder = 3
  end
  object GroupBox3: TGroupBox
    Left = 8
    Top = 231
    Width = 353
    Height = 154
    Caption = 'Supporting Files'
    TabOrder = 4
    object btnCreateReadme: TButton
      Left = 19
      Top = 24
      Width = 312
      Height = 33
      Caption = 'Create README.md file'
      TabOrder = 0
      OnClick = btnCreateReadmeClick
    end
    object btnCreateGitIgnore: TButton
      Left = 19
      Top = 70
      Width = 312
      Height = 33
      Caption = 'Create .gitignore file'
      TabOrder = 1
      OnClick = btnCreateGitIgnoreClick
    end
    object btnShowInExplorer: TButton
      Left = 19
      Top = 116
      Width = 312
      Height = 31
      Caption = 'Open project directory'
      TabOrder = 2
      WordWrap = True
      OnClick = btnShowInExplorerClick
    end
  end
  object GroupBox4: TGroupBox
    Left = 381
    Top = 231
    Width = 361
    Height = 154
    Caption = 'Branch Settings'
    TabOrder = 5
    object lbBranches: TListBox
      Left = 11
      Top = 24
      Width = 223
      Height = 123
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemHeight = 28
      Items.Strings = (
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test'
        'test')
      ParentFont = False
      TabOrder = 0
    end
    object btnCheckoutBranch: TButton
      Left = 240
      Top = 68
      Width = 107
      Height = 35
      Caption = 'Checkout Branch'
      TabOrder = 1
      OnClick = btnCheckoutBranchClick
    end
    object btnDeleteBranch: TButton
      Left = 240
      Top = 112
      Width = 107
      Height = 35
      Caption = 'Delete Branch'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = btnDeleteBranchClick
    end
    object btnCreateBranch: TButton
      Left = 240
      Top = 24
      Width = 107
      Height = 35
      Caption = 'Create Branch'
      TabOrder = 3
      OnClick = btnCreateBranchClick
    end
  end
end
