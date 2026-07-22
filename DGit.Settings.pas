unit DGit.Settings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls,
  DGit.UI, Winapi.ShellAPI, System.UITypes;

type
  TfrmDGitSettings = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    edtUserName: TLabeledEdit;
    edtUserEmail: TLabeledEdit;
    rbGlobal: TRadioButton;
    rbLocal: TRadioButton;
    edtRemoteUrl: TLabeledEdit;
    edtRemoteName: TLabeledEdit;
    btnSave: TButton;
    btnCancel: TButton;
    GroupBox3: TGroupBox;
    btnCreateReadme: TButton;
    btnCreateGitIgnore: TButton;
    btnShowInExplorer: TButton;
    Label1: TLabel;
    GroupBox4: TGroupBox;
    lbBranches: TListBox;
    btnCheckoutBranch: TButton;
    btnDeleteBranch: TButton;
    btnCreateBranch: TButton;
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCreateGitIgnoreClick(Sender: TObject);
    procedure btnCreateReadmeClick(Sender: TObject);
    procedure btnShowInExplorerClick(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure btnCreateBranchClick(Sender: TObject);
    procedure btnCheckoutBranchClick(Sender: TObject);
    procedure btnDeleteBranchClick(Sender: TObject);
  private
    { Private declarations }
    procedure RefreshBranchList;
  public
    { Public declarations }
  end;

var
  frmDGitSettings: TfrmDGitSettings;

implementation

{$R *.dfm}

procedure TfrmDGitSettings.btnCheckoutBranchClick(Sender: TObject);
var
  ProjDir, SelectedBranch: string;
begin
  if lbBranches.ItemIndex = -1 then
  begin
    ShowMessage('Please select a branch to checkout.');
    Exit;
  end;

  SelectedBranch := lbBranches.Items[lbBranches.ItemIndex];

  if SelectedBranch.StartsWith('*') then
  begin
    ShowMessage('You are already in this branch!');
    Exit;
  end;

  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  RunGitCommand('git checkout ' + SelectedBranch, ProjDir);
  RefreshBranchList;
  ShowMessage('Successfully switched to the ''' + SelectedBranch +
    ''' branch.');
end;

procedure TfrmDGitSettings.btnCreateBranchClick(Sender: TObject);
var
  ProjDir, BranchName, GitOutput: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then Exit;


  BranchName := InputBox('New Branch', 'Enter the new branch name (no spaces):', '');

  if Trim(BranchName) <> '' then
  begin
    GitOutput := RunGitCommand('git branch ' + Trim(BranchName), ProjDir);

    if (Pos('fatal:', GitOutput) > 0) or (Pos('error:', GitOutput) > 0) then
    begin
      ShowMessage('Failed to create branch!' + sLineBreak + sLineBreak +
                  'Git Error: ' + Trim(GitOutput) + sLineBreak + sLineBreak +
                  '(Note: You cannot create a branch if there are no commits in the repository yet. Please make an initial commit first.)');
    end
    else
    begin
      RefreshBranchList;
      ShowMessage('Branch ''' + BranchName + ''' was successfully created.');
    end;
  end;
end;

procedure TfrmDGitSettings.btnCreateGitIgnoreClick(Sender: TObject);
var
  ProjDir, FileName: string;
  Lines: TStringList;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  FileName := IncludeTrailingPathDelimiter(ProjDir) + '.gitignore';

  if FileExists(FileName) then
  begin
    ShowMessage('This project already has a .gitignore file!');
    Exit;
  end;

  Lines := TStringList.Create;
  try
    Lines.Add('# Delphi Files and Folders');
    Lines.Add('*.dcu');
    Lines.Add('*.identcache');
    Lines.Add('*.local');
    Lines.Add('*.stat');
    Lines.Add('*.res');
    Lines.Add('__history/');
    Lines.Add('__recovery/');
    Lines.Add('Win32/');
    Lines.Add('Win64/');

    Lines.SaveToFile(FileName, TEncoding.UTF8);
    ShowMessage('The .gitignore file has been successfully created.');
  finally
    Lines.Free;
  end;
end;

procedure TfrmDGitSettings.btnCreateReadmeClick(Sender: TObject);
var
  ProjDir, FileName, ProjectName: string;
  Lines: TStringList;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  FileName := IncludeTrailingPathDelimiter(ProjDir) + 'README.md';

  if FileExists(FileName) then
  begin
    ShowMessage('The README.md file already exists!');
    Exit;
  end;

  ProjectName := ExtractFileName(ExcludeTrailingPathDelimiter(ProjDir));

  Lines := TStringList.Create;
  try
    Lines.Add('# ' + ProjectName);
    Lines.Add('');
    Lines.Add('Write a short description about this project...');
    Lines.Add('This README file was created by DGit.');
    Lines.Add('You can edit this file as you wish.');

    Lines.SaveToFile(FileName, TEncoding.UTF8);
    ShowMessage('README.md created successfully.');
  finally
    Lines.Free;
  end;

end;

procedure TfrmDGitSettings.btnDeleteBranchClick(Sender: TObject);
var
  ProjDir, SelectedBranch: string;
begin
  if lbBranches.ItemIndex = -1 then
  begin
    ShowMessage('Please select a branch to delete.');
    Exit;
  end;

  SelectedBranch := lbBranches.Items[lbBranches.ItemIndex];

  if SelectedBranch.StartsWith('*') then
  begin
    ShowMessage
      ('You cannot delete the currently checked out branch. Please switch to another branch first.');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete the ''' + SelectedBranch +
    ''' branch?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ProjDir := GetActiveProjectDir;
    if ProjDir = '' then
      Exit;

    RunGitCommand('git branch -D ' + SelectedBranch, ProjDir);
    RefreshBranchList;
  end;
end;

procedure TfrmDGitSettings.btnSaveClick(Sender: TObject);
var
  ProjDir, Scope, RemoteName, RemoteUrl, CheckRemote: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  // 1. Kapsam (Scope) Belirleme: Global mi Local mi?
  if rbGlobal.Checked then
    Scope := '--global'
  else
    Scope := '--local';

  // 2. İsim ve E-posta Ayarlarını Kaydetmeasdasd
  if Trim(edtUserName.Text) <> '' then
    RunGitCommand('git config ' + Scope + ' user.name "' +
      Trim(edtUserName.Text) + '"', ProjDir);

  if Trim(edtUserEmail.Text) <> '' then
    RunGitCommand('git config ' + Scope + ' user.email "' +
      Trim(edtUserEmail.Text) + '"', ProjDir);

  // 3. Uzak Sunucu (Remote) Ayarlarını Kaydetme
  RemoteName := Trim(edtRemoteName.Text);
  RemoteUrl := Trim(edtRemoteUrl.Text);

  if RemoteName <> '' then
  begin
    // Eğer URL kısmı tamamen silinmişse, o remote bağlantısını koparalım
    if RemoteUrl = '' then
    begin
      RunGitCommand('git remote remove ' + RemoteName, ProjDir);
    end
    else
    begin
      // Önce bu isimde bir remote var mı diye kontrol edelim
      CheckRemote := Trim(RunGitCommand('git config --get remote.' + RemoteName
        + '.url', ProjDir));

      if CheckRemote = '' then
        // Yoksa yeni ekle
        RunGitCommand('git remote add ' + RemoteName + ' ' + RemoteUrl, ProjDir)
      else if CheckRemote <> RemoteUrl then
        // Varsa ama URL'si değişmişse güncelle
        RunGitCommand('git remote set-url ' + RemoteName + ' ' +
          RemoteUrl, ProjDir);
    end;
  end;

  ModalResult := mrOk;
end;

procedure TfrmDGitSettings.btnShowInExplorerClick(Sender: TObject);
var
  ProjDir: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  ShellExecute(0, 'open', PChar(ProjDir), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmDGitSettings.FormShow(Sender: TObject);
var
  ProjDir, RemoteUrl: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  edtUserName.Text := Trim(RunGitCommand('git config user.name', ProjDir));
  edtUserEmail.Text := Trim(RunGitCommand('git config user.email', ProjDir));

  RemoteUrl := Trim(RunGitCommand('git config --get remote.' +
    edtRemoteName.Text + '.url', ProjDir));
  edtRemoteUrl.Text := RemoteUrl;

  RefreshBranchList
end;

procedure TfrmDGitSettings.Label1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar('https://github.com/yushadev0/'), nil, nil, 1);
end;

procedure TfrmDGitSettings.RefreshBranchList;
var
  ProjDir, GitOutput, Line: string;
  Lines: TStringList;
  i: Integer;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  lbBranches.Items.Clear;
  GitOutput := RunGitCommand('git branch', ProjDir);

  if Trim(GitOutput) = '' then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := GitOutput;
    for i := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[i]);
      if Line <> '' then
        lbBranches.Items.Add(Line);
    end;
  finally
    Lines.Free;
  end;
end;

end.
