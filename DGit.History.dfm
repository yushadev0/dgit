object frmDGitHistory: TfrmDGitHistory
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Commit History'
  ClientHeight = 441
  ClientWidth = 754
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
    Left = 0
    Top = 421
    Width = 754
    Height = 20
    Align = alBottom
    Alignment = taCenter
    Caption = 'Double click to an item to see details.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    ExplicitTop = 418
    ExplicitWidth = 249
  end
  object lvHistory: TListView
    Left = 0
    Top = 0
    Width = 754
    Height = 421
    Align = alClient
    Columns = <
      item
        Caption = 'Hash'
        Width = 80
      end
      item
        Caption = 'Author'
        Width = 120
      end
      item
        Caption = 'Date'
        Width = 105
      end
      item
        Caption = 'Status'
        Width = 90
      end
      item
        Caption = 'Message'
        Width = 400
      end>
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
    OnDblClick = lvHistoryDblClick
    ExplicitHeight = 441
  end
end
