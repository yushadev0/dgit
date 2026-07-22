unit DGit.UI;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  ToolsAPI, DeskUtil, System.IniFiles, Vcl.ActnList, Vcl.ImgList, Vcl.Menus,
  Vcl.ComCtrls, DesignIntf, Vcl.ExtCtrls, System.ImageList;

  function GetActiveProjectDir: string;
  function RunGitCommand(const ACommand, AWorkDir: string): string;

type
  // Delphi'nin kendi oluşturduğu temiz Frame sınıfımız
  TFrame1 = class(TFrame)
    pnlNoRepo: TPanel;
    btnInit: TButton;
    btnClone: TButton;
    Label1: TLabel;
    pnlRepo: TPanel;
    memoCommit: TMemo;
    btnCommit: TButton;
    tvFiles: TTreeView;
    tmrGitCheck: TTimer;
    imgGitStatus: TImageList;
    pmCommit: TPopupMenu;
    miCommitAndPush: TMenuItem;
    chkSelectAll: TCheckBox;
    miPushOnly: TMenuItem;
    pnlUnpushed: TPanel;
    Splitter1: TSplitter;
    lblUnpushedCount: TLabel;
    lbUnpushed: TListBox;
    procedure btnCommitClick(Sender: TObject);
    procedure btnInitClick(Sender: TObject);
    procedure btnCloneClick(Sender: TObject);
    procedure tmrGitCheckTimer(Sender: TObject);
    procedure miCommitAndPushClick(Sender: TObject);
    procedure btnCommitDropDownClick(Sender: TObject);
    procedure chkSelectAllClick(Sender: TObject);
    procedure miPushOnlyClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure CheckRepositoryState;
    procedure RefreshFileList;
    procedure ExecuteCommit(PushAfter: Boolean);
    procedure RefreshUnpushedList;

    var FLastGitStatus: string;
  end;

type
  TDGitDockableForm = class(TInterfacedObject, INTACustomDockableForm)
  public
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    function GetIdentifier: string;
    function CreateForm(Parent: TWinControl): TCustomForm;
    procedure FreeForm;
    procedure SaveWindowState(Desktop: TCustomIniFile; const Section: string;
      IsProject: Boolean);
    procedure LoadWindowState(Desktop: TCustomIniFile; const Section: string);

    procedure FrameCreated(AFrame: TCustomFrame);
    function GetMenuActionList: TCustomActionList;
    function GetMenuImageList: TCustomImageList;
    procedure CustomizePopupMenu(PopupMenu: TPopupMenu);
    function GetToolBarActionList: TCustomActionList;
    function GetToolBarImageList: TCustomImageList;
    procedure CustomizeToolBar(ToolBar: TToolBar);
    function GetEditState: TEditState;
    function EditAction(Action: TEditAction): Boolean;
  end;

procedure RegisterDockableForm;
procedure UnregisterDockableForm;
procedure ShowDGitPanel;

implementation

{$R *.dfm}

const
  c_DGitPanelID = 'DGit.DockPanel';

var
  FDGitDockableForm: TDGitDockableForm;
  FGitFrame: TFrame1;

  { TDGitDockableForm }

function GetActiveProjectDir: string;
var
  ModuleServices: IOTAModuleServices;
  ProjectGroup: IOTAProjectGroup;
  Project: IOTAProject;
begin
  Result := '';
  if BorlandIDEServices.GetService(IOTAModuleServices, ModuleServices) then
  begin
    ProjectGroup := ModuleServices.MainProjectGroup;
    if Assigned(ProjectGroup) then
    begin
      Project := ProjectGroup.ActiveProject;
      if Assigned(Project) then
        Result := ExtractFilePath(Project.FileName);
    end;
  end;
end;

function RunGitCommand(const ACommand, AWorkDir: string): string;
var
  SA: TSecurityAttributes;
  SI: TStartupInfo;
  PI: TProcessInformation;
  StdOutPipeRead, StdOutPipeWrite: THandle;
  WasOK: Boolean;
  Buffer: array [0 .. 4095] of Byte;
  // Buffer'ı büyüttük ve Byte dizisine çevirdik
  BytesRead: Cardinal;
  CmdLine: string;
  MemStream: TMemoryStream;
  StrStream: TStringStream;
begin
  Result := '';
  if AWorkDir = '' then
    Exit;

  with SA do
  begin
    nLength := SizeOf(SA);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;

  CreatePipe(StdOutPipeRead, StdOutPipeWrite, @SA, 0);
  try
    SetHandleInformation(StdOutPipeRead, HANDLE_FLAG_INHERIT, 0);
    FillChar(SI, SizeOf(SI), 0);
    SI.cb := SizeOf(SI);
    SI.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    SI.wShowWindow := SW_HIDE;
    SI.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    SI.hStdOutput := StdOutPipeWrite;
    SI.hStdError := StdOutPipeWrite;

    CmdLine := 'cmd.exe /c ' + ACommand;
    UniqueString(CmdLine);

    WasOK := CreateProcess(nil, PChar(CmdLine), nil, nil, True, 0, nil,
      PChar(AWorkDir), SI, PI);
    CloseHandle(StdOutPipeWrite);

    if WasOK then
    begin
      MemStream := TMemoryStream.Create;
      try
        repeat
          // Tüm çıktıları stream içine topluyoruz
          WasOK := ReadFile(StdOutPipeRead, Buffer, SizeOf(Buffer),
            BytesRead, nil);
          if BytesRead > 0 then
            MemStream.WriteBuffer(Buffer, BytesRead);
        until not WasOK or (BytesRead = 0);

        WaitForSingleObject(PI.hProcess, INFINITE);

        // --- SİHRİN GERÇEKLEŞTİĞİ YER: UTF8 ÇEVİRİSİ ---
        MemStream.Position := 0;
        StrStream := TStringStream.Create('', TEncoding.UTF8);
        // Veriyi UTF-8 olarak oku
        try
          StrStream.CopyFrom(MemStream, MemStream.Size);
          Result := StrStream.DataString;
          // Delphi'nin tertemiz Unicode karakterlerine dönüştür
        finally
          StrStream.Free;
        end;
        // -----------------------------------------------

      finally
        MemStream.Free;
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
      end;
    end;
  finally
    CloseHandle(StdOutPipeRead);
  end;
end;

function GetOrCreateNode(Tree: TTreeView; ParentNode: TTreeNode;
  const NodeText: string; IsFolder: Boolean): TTreeNode;
var
  Node: TTreeNode;
begin
  Result := nil;
  // Eğer ParentNode varsa onun çocuklarında, yoksa en üst seviyede (root) ara
  if Assigned(ParentNode) then
    Node := ParentNode.getFirstChild
  else
    Node := Tree.Items.GetFirstNode;

  while Assigned(Node) do
  begin
    if SameText(Node.Text, NodeText) then
    begin
      Result := Node;
      Exit;
    end;
    Node := Node.getNextSibling;
  end;

  // Bulunamadıysa yeni oluştur
  Result := Tree.Items.AddChild(ParentNode, NodeText);

  // Eğer bu bir klasörse Git ikonunu kaldırıyoruz (-1)
  if IsFolder then
  begin
    Result.ImageIndex := -1;
    Result.SelectedIndex := -1;
    // Klasörlerin varsayılan olarak açık gelmesini istersen:
    Result.Expand(False);
  end;
end;

function GetNodePath(Node: TTreeNode): string;
begin
  Result := Node.Text;
  while Node.Parent <> nil do
  begin
    Node := Node.Parent;
    Result := Node.Text + '/' + Result; // Git'in sevdiği forward slash'leri (/) kullanıyoruz
  end;
end;

function IsNodeOrParentChecked(Node: TTreeNode): Boolean;
begin
  Result := False;
  while Node <> nil do
  begin
    // Eğer kendisi veya herhangi bir ebeveyni (üst klasörü) işaretliyse True dön
    if Node.Checked then
    begin
      Result := True;
      Break;
    end;
    Node := Node.Parent;
  end;
end;

function TDGitDockableForm.GetFrameClass: TCustomFrameClass;
begin
  Result := TFrame1; // Kendi frame sınıfımızı döndürüyoruz
end;

function TDGitDockableForm.CreateForm(Parent: TWinControl): TCustomForm;
begin
  Result := nil;
end;

procedure TDGitDockableForm.FrameCreated(AFrame: TCustomFrame);
begin
  FGitFrame := AFrame as TFrame1;
  FGitFrame.CheckRepositoryState;
end;

procedure TDGitDockableForm.FreeForm;
begin
  FGitFrame := nil;
end;

function TDGitDockableForm.GetCaption: string;
begin
  Result := 'DGit Version Control';
end;

function TDGitDockableForm.GetIdentifier: string;
begin
  Result := c_DGitPanelID;
end;

procedure TDGitDockableForm.LoadWindowState(Desktop: TCustomIniFile;
  const Section: string);
begin
end;

procedure TDGitDockableForm.SaveWindowState(Desktop: TCustomIniFile;
  const Section: string; IsProject: Boolean);
begin
end;

function TDGitDockableForm.GetMenuActionList: TCustomActionList;
begin
  Result := nil;
end;

function TDGitDockableForm.GetMenuImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TDGitDockableForm.CustomizePopupMenu(PopupMenu: TPopupMenu);
begin
end;

function TDGitDockableForm.GetToolBarActionList: TCustomActionList;
begin
  Result := nil;
end;

function TDGitDockableForm.GetToolBarImageList: TCustomImageList;
begin
  Result := nil;
end;

procedure TDGitDockableForm.CustomizeToolBar(ToolBar: TToolBar);
begin
end;

function TDGitDockableForm.GetEditState: TEditState;
begin
  Result := [];
end;

function TDGitDockableForm.EditAction(Action: TEditAction): Boolean;
begin
  Result := False;
end;

// --- IDE Entegrasyon ---

procedure RegisterDockableForm;
begin
  if not Assigned(FDGitDockableForm) then
  begin
    FDGitDockableForm := TDGitDockableForm.Create;
    (BorlandIDEServices as INTAServices).RegisterDockableForm
      (FDGitDockableForm);
  end;
end;

procedure UnregisterDockableForm;
begin
  if Assigned(FDGitDockableForm) then
  begin
    (BorlandIDEServices as INTAServices).UnregisterDockableForm
      (FDGitDockableForm);
    FDGitDockableForm := nil;
  end;
end;

procedure ShowDGitPanel;
var
  LForm: TCustomForm;
begin
  if Assigned(FDGitDockableForm) then
  begin
    LForm := (BorlandIDEServices as INTAServices)
      .CreateDockableForm(FDGitDockableForm);
    if Assigned(LForm) then
    begin
      LForm.Show;
    end;
  end;
end;

procedure TFrame1.btnCloneClick(Sender: TObject);
begin
  ShowMessage('cloning stuff. will be build.');
end;

procedure TFrame1.btnCommitClick(Sender: TObject);
begin
  ExecuteCommit(False);
end;

procedure TFrame1.btnCommitDropDownClick(Sender: TObject);
var
  P: TPoint;
begin
  P := Point(btnCommit.Width, btnCommit.Height);
  P := btnCommit.ClientToScreen(P);
  pmCommit.Alignment := paRight;
  pmCommit.Popup(P.X, P.Y);
end;

procedure TFrame1.btnInitClick(Sender: TObject);
var
  ProjDir: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir <> '' then
  begin
    // Repoyu oluştur
    RunGitCommand('git init', ProjDir);

    // Durumu tekrar kontrol et (Bu sayede arayüz otomatik olarak pnlRepo'ya geçecek!)
    CheckRepositoryState;
  end;

end;

procedure TFrame1.CheckRepositoryState;
var
  ProjDir, GitOutput: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
    Exit;

  GitOutput := RunGitCommand('git status', ProjDir);

  // Eğer repo YOKSA
  if Pos('fatal: not a git repository', GitOutput) > 0 then
  begin
    // Sadece şu an pnlRepo görünürse (yani durum yeni değiştiyse) panelleri değiştir
    if pnlRepo.Visible then
    begin
      pnlNoRepo.Visible := True;
      pnlRepo.Visible := False;
      pnlNoRepo.BringToFront;
    end;
  end
  else
  // Eğer repo VARSA
  begin
    if pnlNoRepo.Visible then
    begin
      pnlNoRepo.Visible := False;
      pnlRepo.Visible := True;
      pnlRepo.BringToFront;

      RefreshFileList;
      RefreshUnpushedList;
    end;
  end;
end;

procedure TFrame1.chkSelectAllClick(Sender: TObject);
var
  i: Integer;
begin
  // Ekranın titremesini engeller ve döngüyü hızlandırır
  tvFiles.Items.BeginUpdate;
  try
    for i := 0 to tvFiles.Items.Count - 1 do
    begin
      // TreeView'daki her bir elemanın durumunu, bizim Select All kutucuğunun durumuna eşitleriz
      tvFiles.Items[i].Checked := chkSelectAll.Checked;
    end;
  finally
    // İşlem bitince ekranı tek seferde yeniden çizer
    tvFiles.Items.EndUpdate;
  end;
end;

function TreeSortProc(lParam1, lParam2, lParamSort: NativeInt)
  : Integer; stdcall;
var
  Node1, Node2: TTreeNode;
  IsFolder1, IsFolder2: Boolean;
begin
  Node1 := TTreeNode(lParam1);
  Node2 := TTreeNode(lParam2);

  // İkon indeksinin -1 olması onun klasör olduğunu gösterir (GetOrCreateNode'da böyle ayarlamıştık)
  IsFolder1 := Node1.ImageIndex = -1;
  IsFolder2 := Node2.ImageIndex = -1;

  if IsFolder1 and not IsFolder2 then
    Result := -1 // 1. düğüm klasör, 2. düğüm dosyaysa -> Klasör ÜSTE
  else if not IsFolder1 and IsFolder2 then
    Result := 1 // 1. düğüm dosya, 2. düğüm klasörse -> Klasör ÜSTE
  else
    // Eğer ikisi de klasörse veya ikisi de dosyaysa -> Sadece isme göre alfabetik sırala
    Result := AnsiCompareText(Node1.Text, Node2.Text);
end;

procedure TFrame1.RefreshFileList;
var
  GitOutput, Line, FileStatus, FullPath, Part: string;
  Lines: TStringList;
  PathParts: TArray<string>;
  i, p, IconIdx: Integer;
  CurrentParent, FileNode: TTreeNode;
  IsFile, IsHidden: Boolean;
begin
  tvFiles.Items.BeginUpdate;
  try
    tvFiles.Items.Clear;

    GitOutput := RunGitCommand('git -c core.quotePath=false status -s -uall',
      GetActiveProjectDir);
    if Trim(GitOutput) = '' then
      Exit;

    Lines := TStringList.Create;
    try
      Lines.Text := GitOutput;

      for i := 0 to Lines.Count - 1 do
      begin
        Line := Lines[i];
        if Length(Line) > 3 then
        begin
          FileStatus := Copy(Line, 1, 2);
          FullPath := Trim(Copy(Line, 4, Length(Line)));

          if (Length(FullPath) >= 2) and (FullPath.StartsWith('"')) and
            (FullPath.EndsWith('"')) then
            FullPath := Copy(FullPath, 2, Length(FullPath) - 2);

          FullPath := StringReplace(Trim(Copy(Line, 4, Length(Line))), '/', '\',
            [rfReplaceAll]);

          PathParts := FullPath.Split(['\']);

          // --- GİZLİ KLASÖR/DOSYA KONTROLÜ ---
          IsHidden := False;
          for p := 0 to High(PathParts) do
          begin
            // Adı '.' ile (örn: .git, .local) veya '__' ile (örn: __history) başlayanları atla
            if PathParts[p].StartsWith('.') or PathParts[p].StartsWith('__')
            then
            begin
              IsHidden := True;
              Break;
            end;
          end;

          // Eğer gizli bir yol barındırıyorsa bu satırı hiç parse etmeden sonrakine geç
          if IsHidden then
            Continue;
          // -----------------------------------

          IconIdx := -1;
          if Pos('??', FileStatus) > 0 then
            IconIdx := 0
          else if Pos('M', FileStatus) > 0 then
            IconIdx := 1
          else if Pos('A', FileStatus) > 0 then
            IconIdx := 2
          else if Pos('D', FileStatus) > 0 then
            IconIdx := 3;

          CurrentParent := nil;

          for p := 0 to High(PathParts) do
          begin
            Part := PathParts[p];
            IsFile := (p = High(PathParts));

            CurrentParent := GetOrCreateNode(tvFiles, CurrentParent, Part,
              not IsFile);

            if IsFile and (IconIdx <> -1) then
            begin
              CurrentParent.ImageIndex := IconIdx;
              CurrentParent.SelectedIndex := IconIdx;
            end;
          end;
        end;
      end;
    finally
      Lines.Free;
    end;

    tvFiles.CustomSort(@TreeSortProc, 0, True);
  finally
    tvFiles.Items.EndUpdate;
  end;
  RefreshUnpushedList;
end;

procedure TFrame1.tmrGitCheckTimer(Sender: TObject);
var
  ProjDir, CurrentStatus: string;
begin
  // Mevcut repo kontrolünü yapmaya devam et
  CheckRepositoryState;

  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then Exit;

  // Git'in kısa ve net durum özetini al
  CurrentStatus := Trim(RunGitCommand('git status --porcelain', ProjDir));

  // Eğer son durum hafızaasdasddakinden farklıysa (gerçekten bir dosya değişmişse)
  if CurrentStatus <> FLastGitStatus then
  begin
    FLastGitStatus := CurrentStatus; // Yeni durumu hafızaya al
    RefreshFileList;                 // Ve sadece şimdi listeyi yenile!
  end;
end;

procedure TFrame1.ExecuteCommit(PushAfter: Boolean);
var
  ProjDir, CommitMsg, FileName, GitOutput, BranchName: string;
  i, FilesAdded: Integer;
  Node: TTreeNode;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then Exit;

  // --- YENİ EKLENEN: İLK COMMIT İÇİN DAL KONTROLÜ ---
  // Eğer 'git branch' komutu tamamen boş dönüyorsa, bu projede henüz hiç commit yok demektir.
  if Trim(RunGitCommand('git branch', ProjDir)) = '' then
  begin
    BranchName := InputBox('Initial Branch', 'This is the first commit! Enter a name for the initial branch (e.g., main, master):', 'main');

    if Trim(BranchName) = '' then
    begin
      ShowMessage('Commit cancelled. You must provide a branch name for the initial commit.');
      Exit;
    end;

    // Git'in varsayılan olarak bellekte tuttuğu o ilk dalın adını, kullanıcının girdiği isimle (-M) değiştiriyoruz
    RunGitCommand('git branch -M ' + Trim(BranchName), ProjDir);
  end;
  // --------------------------------------------------

  // 1. Commit mesajı boş mu diye kontrol et
  CommitMsg := Trim(memoCommit.Text);
  if CommitMsg = '' then
  begin
    ShowMessage('Please enter a commit message!');
    Exit;
  end;

  // 2. Ağaçtaki işaretli dosyaları VE KLASÖRLERİ topla
  FilesAdded := 0;
  for i := 0 to tvFiles.Items.Count - 1 do
  begin
    Node := tvFiles.Items[i];

    // Sadece dosyaları işleme alıyoruz (klasörlerin kendisini git add yapmıyoruz)
    if (Node.ImageIndex <> -1) then
    begin
      // YENİ: Eğer dosyanın kendisi VEYA bağlı olduğu klasörlerden herhangi biri işaretliyse:
      if IsNodeOrParentChecked(Node) then
      begin
        FileName := GetNodePath(Node);
        RunGitCommand('git add "' + FileName + '"', ProjDir);
        Inc(FilesAdded);
      end;
    end;
  end;

  // 3. Güvenlik: Hiç dosya seçilmemişse işlemi durdur
  if FilesAdded = 0 then
  begin
    ShowMessage('Please select at least one file or folder to commit!');
    Exit;
  end;

  // 4. Asıl Şov: Commit işlemini ateşle!
  RunGitCommand('git commit -m "' + CommitMsg + '"', ProjDir);

  // 5. Eğer "Commit & Push" seçilmişse, Push işlemini yap
  if PushAfter then
  begin
    BranchName := Trim(RunGitCommand('git branch --show-current', ProjDir));
    if BranchName <> '' then
    begin
      GitOutput := RunGitCommand('git push -u origin ' + BranchName, ProjDir);

      if (Pos('fatal:', GitOutput) > 0) or (Pos('error:', GitOutput) > 0) then
        ShowMessage('Commit successful, but Push failed!' + sLineBreak + sLineBreak + 'Git Error: ' + GitOutput)
      else
        ShowMessage('Successfully committed and pushed to ''' + BranchName + '''!');
    end;
  end
  else
  begin
    ShowMessage('Commit successful!');
  end;

  // 6. İşlem bittikten sonra ortalığı temizle
  memoCommit.Clear;
  RefreshFileList;
end;

procedure TFrame1.miCommitAndPushClick(Sender: TObject);
begin
ExecuteCommit(True);
end;

procedure TFrame1.miPushOnlyClick(Sender: TObject);
var
  ProjDir, BranchName, GitOutput: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then Exit;

  // 1. Önce aktif dalı (branch) bulalım
  BranchName := Trim(RunGitCommand('git branch --show-current', ProjDir));

  if BranchName = '' then
  begin
    ShowMessage('No active branch found! Please create or checkout a branch first.');
    Exit;
  end;

  // 2. Push işlemi (İlk push olma ihtimaline karşı -u parametresiyle garantiye alıyoruz)
  GitOutput := RunGitCommand('git push -u origin ' + BranchName, ProjDir);

  // 3. Sonuç Kontrolü
  if (Pos('fatal:', GitOutput) > 0) or (Pos('error:', GitOutput) > 0) then
  begin
    ShowMessage('Push failed!' + sLineBreak + sLineBreak + 'Git Error: ' + GitOutput);
  end
  else
  begin
    ShowMessage('Successfully pushed to ''' + BranchName + '''!');
  end;
end;

procedure TFrame1.RefreshUnpushedList;
var
  ProjDir, GitOutput, BranchName, Line: string;
  Lines: TStringList;
  i: Integer;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then Exit;

  lbUnpushed.Items.BeginUpdate;
  try
    lbUnpushed.Items.Clear;
    lblUnpushedCount.Caption := 'Unpushed Commits (0)';

    // 1. Önce aktif dalı (branch) alalım
    BranchName := Trim(RunGitCommand('git branch --show-current', ProjDir));
    if BranchName = '' then Exit; // Repoda henüz hiç commit yoksa çık

    // 2. Upstream (sunucu bağlantısı) var mı kontrol et
    GitOutput := Trim(RunGitCommand('git rev-parse --abbrev-ref ' + BranchName + '@{u}', ProjDir));

    if (Pos('fatal:', GitOutput) > 0) or (Pos('error:', GitOutput) > 0) or (GitOutput = '') then
    begin
      // Upstream yok (Yani henüz hiç push atılmamış). Tüm yerel commitleri getir.
      GitOutput := RunGitCommand('git log --pretty=format:"%h - %s"', ProjDir);
    end
    else
    begin
      // Upstream var. Sadece sunucu ile aradaki farkı (unpushed olanları) getir.
      GitOutput := RunGitCommand('git log @{u}..HEAD --pretty=format:"%h - %s"', ProjDir);
    end;

    // Eğer bekleyen commit yoksa işlem tamamdır
    if Trim(GitOutput) = '' then Exit;

    // 3. Gelen veriyi listeye doldur ve sayacı güncelle
    Lines := TStringList.Create;
    try
      Lines.Text := GitOutput;
      for i := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[i]);
        if Line <> '' then
          lbUnpushed.Items.Add(Line);
      end;
      // Başlığı dinamik olarak güncelle
      lblUnpushedCount.Caption := 'Unpushed Commits (' + IntToStr(Lines.Count) + ')';
    finally
      Lines.Free;
    end;
  finally
    lbUnpushed.Items.EndUpdate;
  end;
end;

end.
