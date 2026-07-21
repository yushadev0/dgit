unit dgit_main;

interface

uses
  ToolsAPI,
  System.SysUtils;

procedure Register;

implementation

procedure Register;
var
  MessageServices: IOTAMessageServices;
begin
  // IDE'nin mesaj servisini (Messages sekmesini) alıyoruz
  if BorlandIDEServices.GetService(IOTAMessageServices, MessageServices) then
  begin
    MessageServices.AddTitleMessage
      ('DGit başarıyla IDE''ye entegre edildi! Hoş geldin.');
  end;
end;

end.
