unit DGit.Main;

interface

uses
  ToolsAPI,
  System.SysUtils,
  Vcl.Menus,
  DGit.UI,
  DGit.Settings,
  DGit.History, // YENİ EKLENDİ
  Vcl.Dialogs;

procedure Register;

implementation

type
  TMenuEventSink = class
  private
    procedure SettingsMenuClick(Sender: TObject);
    procedure HistoryMenuClick(Sender: TObject); // YENİ EKLENDİ
  public
    procedure DGitMenuClick(Sender: TObject);
  end;

var
  DGitTopMenu: TMenuItem;
  MenuItem: TMenuItem;
  HistoryMenuItem: TMenuItem; // YENİ EKLENDİ
  MenuEventSink: TMenuEventSink;

{ TMenuEventSink }

procedure TMenuEventSink.DGitMenuClick(Sender: TObject);
begin
  ShowDGitPanel; // DGit panelini göster[cite: 1]
end;

// YENİ EKLENEN HISTORY TIKLAMA OLAYI
procedure TMenuEventSink.HistoryMenuClick(Sender: TObject);
var
  HistoryForm: TfrmDGitHistory;
  ProjDir, GitOutput: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
  begin
    ShowMessage('Please open a Delphi Project.');
    Exit;
  end;

  GitOutput := RunGitCommand('git status', ProjDir);
  if Pos('fatal: not a git repository', GitOutput) > 0 then
  begin
    ShowMessage('This project is not yet a git repository.' + sLineBreak +
                'Please first create a git repository from the DGit panel.');
    Exit;
  end;

  HistoryForm := TfrmDGitHistory.Create(nil);
  try
    HistoryForm.ShowModal;
  finally
    HistoryForm.Free;
  end;
end;

procedure TMenuEventSink.SettingsMenuClick(Sender: TObject);
var
  SettingsForm: TfrmDGitSettings;
  ProjDir, GitOutput: string;
begin
  ProjDir := GetActiveProjectDir;
  if ProjDir = '' then
  begin
    ShowMessage('Please open a Delphi Project.');
    Exit; // Proje yoksa işlemi iptal et[cite: 1]
  end;

  GitOutput := RunGitCommand('git status', ProjDir);
  if Pos('fatal: not a git repository', GitOutput) > 0 then
  begin
    ShowMessage('This project is not yet a git repository.' + sLineBreak +
                'To access the settings, please first create a git repository from the DGit panel.');
    Exit;
  end;

  SettingsForm := TfrmDGitSettings.Create(nil);
  try
    SettingsForm.ShowModal;
  finally
    SettingsForm.Free;
  end;
end;

procedure Register;
var
  MessageServices: IOTAMessageServices;
  NTAServices: INTAServices;
  SettingsMenuItem: TMenuItem;
begin
  if BorlandIDEServices.GetService(IOTAMessageServices, MessageServices) then
  begin
    MessageServices.AddTitleMessage('DGit installed successfully!');
  end;

  RegisterDockableForm; // Form kaydını yap[cite: 1]

  if BorlandIDEServices.GetService(INTAServices, NTAServices) then
  begin
    DGitTopMenu := TMenuItem.Create(NTAServices.MainMenu);
    DGitTopMenu.Caption := 'DGit';

    if not Assigned(MenuEventSink) then
      MenuEventSink := TMenuEventSink.Create;

    // 1. Open Panel Menüsü
    MenuItem := TMenuItem.Create(DGitTopMenu);
    MenuItem.Caption := 'Open DGit Panel';
    MenuItem.OnClick := MenuEventSink.DGitMenuClick;
    DGitTopMenu.Add(MenuItem);

    // 2. YENİ EKLENEN: History Log Menüsü
    HistoryMenuItem := TMenuItem.Create(DGitTopMenu);
    HistoryMenuItem.Caption := 'History Log';
    HistoryMenuItem.OnClick := MenuEventSink.HistoryMenuClick;
    DGitTopMenu.Add(HistoryMenuItem);

    // 3. Settings Menüsü
    SettingsMenuItem := TMenuItem.Create(DGitTopMenu);
    SettingsMenuItem.Caption := 'Settings...';
    SettingsMenuItem.OnClick := MenuEventSink.SettingsMenuClick;
    DGitTopMenu.Add(SettingsMenuItem);

    NTAServices.MainMenu.Items.Add(DGitTopMenu);
  end;

end;

initialization
finalization
  if Assigned(MenuItem) then
    MenuItem.Free;
  if Assigned(HistoryMenuItem) then
    HistoryMenuItem.Free; // Bellekten temizle
  if Assigned(DGitTopMenu) then
    DGitTopMenu.Free;
  if Assigned(MenuEventSink) then
    MenuEventSink.Free;

  UnregisterDockableForm; // IDE'den form kaydını sil[cite: 1]

end.
