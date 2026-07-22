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
  OnShow = FormShow
  TextHeight = 15
  object lvHistory: TListView
    Left = 0
    Top = 0
    Width = 754
    Height = 441
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
        Caption = 'Message'
        Width = 400
      end>
    TabOrder = 0
    ViewStyle = vsReport
    ExplicitLeft = 8
  end
end
