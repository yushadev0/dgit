unit DGit.History;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, DGit.UI;

type
  TfrmDGitHistory = class(TForm)
    lvHistory: TListView;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmDGitHistory: TfrmDGitHistory;

implementation

{$R *.dfm}

procedure TfrmDGitHistory.FormShow(Sender: TObject);
var
  ProjDir, GitOutput, Line: string;
  Lines, Parts: TStringList;
  i: Integer;
  ListItem: TListItem;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit; // Proje dizini yoksa işlemi durdur[cite: 2]

  lvHistory.Items.BeginUpdate;
  try
    lvHistory.Items.Clear;

    // Git log komutu: %h=Hash, %an=Yazar, %ar=Tarih, %s=Mesaj
    GitOutput := RunGitCommand
      ('git log --pretty=format:"%h|%an|%ad|%s" --date=format:"%H:%M %d-%m-%Y"',
      ProjDir);

    if Trim(GitOutput) = '' then
      Exit;

    Lines := TStringList.Create;
    Parts := TStringList.Create;
    try
      Parts.StrictDelimiter := True; // Boşluklardan bölmesini engeller
      Parts.Delimiter := '|';
      Lines.Text := GitOutput;

      for i := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[i]);
        if Line = '' then
          Continue;

        Parts.DelimitedText := Line;

        if Parts.Count >= 4 then
        begin
          ListItem := lvHistory.Items.Add;
          ListItem.Caption := Parts[0]; // Hash
          ListItem.SubItems.Add(Parts[1]); // Author
          ListItem.SubItems.Add(Parts[2]); // Date
          ListItem.SubItems.Add(Parts[3]); // Message
        end;
      end;
    finally
      Lines.Free;
      Parts.Free;
    end;
  finally
    lvHistory.Items.EndUpdate;
  end;
end;

end.
