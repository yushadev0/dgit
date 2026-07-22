unit DGit.History;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, DGit.UI,
  Vcl.StdCtrls;

type
  TfrmDGitHistory = class(TForm)
    lvHistory: TListView;
    Label1: TLabel;
    procedure FormShow(Sender: TObject);
    procedure lvHistoryDblClick(Sender: TObject);
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
  ProjDir, GitOutput, Line, BranchName: string;
  Lines, Parts, UnpushedHashes: TStringList;
  i: Integer;
  ListItem: TListItem;
  StatusText: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then Exit;

  // 1. AŞAMA: UNPUSHED (BEKLEYEN) COMMIT HASH'LERİNİ BULMA
  UnpushedHashes := TStringList.Create;
  try
    BranchName := Trim(RunGitCommand('git branch --show-current', ProjDir));
    if BranchName <> '' then
    begin
      // Upstream (sunucu bağlantısı) kontrolü
      GitOutput := Trim(RunGitCommand('git rev-parse --abbrev-ref ' + BranchName + '@{u}', ProjDir));

      if (Pos('fatal:', GitOutput) > 0) or (Pos('error:', GitOutput) > 0) or (GitOutput = '') then
        // Upstream yoksa yereldeki tüm commitler pushlanmayı bekliyor demektir
        GitOutput := RunGitCommand('git log --format="%h"', ProjDir)
      else
        // Upstream varsa sadece aradaki farkların hash'lerini getir
        GitOutput := RunGitCommand('git log @{u}..HEAD --format="%h"', ProjDir);

      UnpushedHashes.Text := GitOutput;
    end;

    // 2. AŞAMA: ANA GEÇMİŞ LİSTESİNİ DOLDURMA
    lvHistory.Items.BeginUpdate;
    try
      lvHistory.Items.Clear;

      // Tarih formatımızı tam istediğin gibi tutuyoruz
      GitOutput := RunGitCommand('git log --pretty=format:"%h|%an|%ad|%s" --date=format:"%Y-%m-%d %H:%M"', ProjDir);

      if Trim(GitOutput) = '' then Exit;

      Lines := TStringList.Create;
      Parts := TStringList.Create;
      try
        Parts.StrictDelimiter := True;
        Parts.Delimiter := '|';
        Lines.Text := GitOutput;

        for i := 0 to Lines.Count - 1 do
        begin
          Line := Trim(Lines[i]);
          if Line = '' then Continue;

          Parts.DelimitedText := Line;

          if Parts.Count >= 4 then
          begin
            ListItem := lvHistory.Items.Add;
            ListItem.Caption := Parts[0];         // Hash
            ListItem.SubItems.Add(Parts[1]);      // Author
            ListItem.SubItems.Add(Parts[2]);      // Date

            // YENİ: Status Kolonu Belirleme
            // Eğer bu satırın Hash değeri, Unpushed listemizin içinde varsa:
            if UnpushedHashes.IndexOf(Parts[0]) <> -1 then
              StatusText := '✖ Unpushed'
            else
              StatusText := '✔ Pushed';

            ListItem.SubItems.Add(StatusText);    // Status

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

  finally
    // İşimiz bitince hafızayı temizle
    UnpushedHashes.Free;
  end;
end;

procedure TfrmDGitHistory.lvHistoryDblClick(Sender: TObject);
var
  CommitHash, GitOutput: string;
  DetailForm: TForm;
  MemoView: TMemo;
begin
  // Eğer hiçbir satır seçilmemişse işlemi iptal et
  if lvHistory.Selected = nil then Exit;

  // TListView'da ilk kolon her zaman 'Caption' özelliğidir, yani bizim Hash değerimiz!
  CommitHash := Trim(lvHistory.Selected.Caption);

  if CommitHash = '' then Exit;

  // DGit.UI'dan miras aldığımız fonksiyonlarla komutu çalıştırıyoruz
  GitOutput := RunGitCommand('git show --stat ' + CommitHash, GetActiveProjectDir);

  // Anında dinamik detay formunu oluştur
  DetailForm := TForm.Create(nil);
  try
    DetailForm.Caption := 'Commit Details: ' + CommitHash;
    DetailForm.Width := 800;
    DetailForm.Height := 450;
    DetailForm.Position := poScreenCenter;
    DetailForm.BorderStyle := bsSizeToolWin; // Şık bir araç penceresi görünümü

    MemoView := TMemo.Create(DetailForm);
    MemoView.Parent := DetailForm;
    MemoView.Align := alClient;
    MemoView.ScrollBars := ssBoth;
    MemoView.ReadOnly := True;
    // Terminal formatını milimetrik korumak için Consolas fontu
    MemoView.Font.Name := 'Consolas';
    MemoView.Font.Size := 10;
    MemoView.Lines.Text := GitOutput;

    // Formu göster
    DetailForm.ShowModal;
  finally
    // İşlem bittiğinde RAM'den temizle
    DetailForm.Free;
  end;
end;

end.
