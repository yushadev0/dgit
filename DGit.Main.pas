unit DGit.Main;

interface

uses
  ToolsAPI,
  System.SysUtils,
  Vcl.Menus,
  DGit.UI,
  DGit.Settings,
  Vcl.Dialogs;

procedure Register;

implementation

type
  TMenuEventSink = class
  private
    procedure SettingsMenuClick(Sender: TObject);
  public
    procedure DGitMenuClick(Sender: TObject);
  end;

var
  DGitTopMenu: TMenuItem;
  MenuItem: TMenuItem;
  MenuEventSink: TMenuEventSink;

{ TMenuEventSink }

procedure TMenuEventSink.DGitMenuClick(Sender: TObject);
begin
  ShowDGitPanel;
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
    Exit; // Proje yoksa işlemi iptal et
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

  RegisterDockableForm;

  if BorlandIDEServices.GetService(INTAServices, NTAServices) then
  begin
    DGitTopMenu := TMenuItem.Create(NTAServices.MainMenu);
    DGitTopMenu.Caption := 'DGit';

    if not Assigned(MenuEventSink) then
      MenuEventSink := TMenuEventSink.Create;

    MenuItem := TMenuItem.Create(DGitTopMenu);
    MenuItem.Caption := 'Open DGit Panel';
    MenuItem.OnClick := MenuEventSink.DGitMenuClick;
    DGitTopMenu.Add(MenuItem);

    SettingsMenuItem := TMenuItem.Create(DGitTopMenu);
    SettingsMenuItem.Caption := 'Settings...';
    SettingsMenuItem.OnClick := MenuEventSink.SettingsMenuClick;
    DGitTopMenu.Add(SettingsMenuItem);

    NTAServices.MainMenu.Items.Add(DGitTopMenu);
  end;

end;

// Paket kapatılırken RAM'de kalanları temizle
initialization
finalization
  if Assigned(MenuItem) then
    MenuItem.Free;
  if Assigned(DGitTopMenu) then
    DGitTopMenu.Free;
  if Assigned(MenuEventSink) then
    MenuEventSink.Free;

  // Çıkışta IDE'den form kaydımızı siliyoruz
  UnregisterDockableForm;

end.
