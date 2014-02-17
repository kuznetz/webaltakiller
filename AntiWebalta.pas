{
  This unit is part of Webalta Killer project (webaltakiller.ru)
  Author: Georgiy Kuznetsov (mail@from-nothing.ru)
  License: LGPL
}
unit AntiWebalta;
interface
uses Classes;

procedure KillWebalta();

var
  LogStrs: TStrings = nil;

implementation

uses SysUtils, StrUtils, Windows, ShlObj, ComOBJ, ActiveX, Registry, SHFolder;

procedure LogMessage(s: string);
begin
  if Assigned(LogStrs) then
    LogStrs.Add(s);
end;

function myDeleteFile(dirname: string):boolean;
begin
  if (FileExists(dirname)) then begin
    DeleteFile(PWideChar(dirname));
    LogMessage('Файл '+dirname+' удален');
  end;
end;

function RemoveFullDir(dirname: string):boolean;
var
  SR: TSearchRec;
  Found: Boolean;
begin
  if not DirectoryExists(dirname) then begin
    Result := true;
    exit;
  end;
  Result := true;
  Found := FindFirst(dirname+'\*', faAnyFile, SR) = 0;
  while Found do begin
    if (SR.Attr and faDirectory) = faDirectory then begin
      if (SR.Name <> '.') and (SR.Name <> '..') then begin
        Result := Result and RemoveFullDir(dirname +'\'+ SR.Name);
      end;
    end else begin
      result := Result and myDeleteFile(dirname +'\'+ SR.Name);
    end;
    Found := (FindNext(SR) = 0);
  end;
  Found := RemoveDirectory(PWideChar(dirname));

  result := Result and Found;
end;

function GetSpecialFolderPath(folder : integer) : string;
const
  SHGFP_TYPE_CURRENT = 0;
var
  path: array [0..MAX_PATH] of char;
begin
  if SUCCEEDED(SHGetFolderPath(0, folder, 0, SHGFP_TYPE_CURRENT, @path[0])) then
    Result := path
  else
    Result := '';
end;

procedure CleanClsId(Reg: TRegistry; Key: string);
var
  KeyPrefix, CurVal: string;
  SLKeys: TStrings;
  RegKeys: TStrings;
  i: integer;
begin
  LogMessage('Поиск зараженных ключей реестра в:'#13#10+Key);

  RegKeys := TStringList.Create();
  RegKeys.Add(Key);

  while (RegKeys.Count > 0) do begin
    reg.OpenKey(RegKeys[0],false);

    if (RegKeys[0] = '') then begin
      KeyPrefix := '';
    end else begin
      KeyPrefix := RegKeys[0]+'\';
    end;

    SLKeys := TStringList.Create;
    reg.GetKeyNames(SLKeys);
    for i := 0 to SLKeys.Count-1 do begin
      RegKeys.Add(KeyPrefix+SLKeys[i]);
    end;
    SLKeys.Destroy;

    if (Reg.GetDataType('Assembly') = rdString) then begin
      CurVal := Reg.GetDataAsString('Assembly');
      if (PosEx('WebAltaSearch,',CurVal) > 0) then begin
        LogMessage(RegKeys[0]);
        Reg.DeleteValue('Assembly');
      end;
    end;

    reg.CloseKey();
    RegKeys.Delete(0);
  end;
end;

procedure FixIE();
var
  Reg: TRegistry;
  SL: TStringList;
  ShitKey: string;
  i:integer;
begin
  LogMessage('Очищаем браузер IE');
  Reg := TRegistry.Create();
  Reg.RootKey := HKEY_CURRENT_USER;

  if (Reg.OpenKey('Software\Microsoft\Internet Explorer\Main',false)) then begin
    Reg.WriteString('Default_Search_URL','http://go.microsoft.com/fwlink/?LinkId=54896');
    Reg.WriteString('Search Page','http://go.microsoft.com/fwlink/?LinkId=54896');
    Reg.WriteString('Search Bar','http://go.microsoft.com/fwlink/?LinkId=54896');
    Reg.CloseKey;
  end;

  if (Reg.OpenKey('Software\Microsoft\Internet Explorer\Search',false)) then begin
    Reg.WriteString('SearchAssistant','http://ya.ru/');
    Reg.CloseKey;
  end;

  SL := TStringList.Create;
  if (Reg.OpenKey('Software\Microsoft\Internet Explorer\SearchScopes',false)) then begin
    Reg.GetKeyNames(SL);
    Reg.CloseKey;
    for i := 0 to SL.Count-1 do begin
      Reg.OpenKey('Software\Microsoft\Internet Explorer\SearchScopes\'+SL[i],false);
      ShitKey := Reg.ReadString('URL');
      Reg.CloseKey;
      if (PosEx('webalta.ru',ShitKey) > 0) then break;
      ShitKey := '';
    end;
    if (ShitKey <> '') then begin
      Reg.DeleteKey('Software\Microsoft\Internet Explorer\SearchScopes\'+SL[i]);
    end;
  end;

  SL.Destroy;

  Reg.Destroy();
end;

function FixFirefoxProfile(profiledir: string):boolean;
var
  SL: TStringList;
  i: integer;
begin
  myDeleteFile(profiledir+'\searchplugins\webalta-search.xml');
  myDeleteFile(profiledir+'\extensions\{4933189D-C7F7-4C6E-834B-A29F087BFD23}.xpi');
  myDeleteFile(profiledir+'\extensions\staged\{4933189D-C7F7-4C6E-834B-A29F087BFD23}.json');
  myDeleteFile(profiledir+'\extensions\staged\{4933189D-C7F7-4C6E-834B-A29F087BFD23}.xpi');

  SL := TStringList.Create;

  if (FileExists(profiledir+'\prefs.js')) then begin
    SL.LoadFromFile(profiledir+'\prefs.js');
    for i := 0 to SL.Count-1 do begin
      if (PosEx('http://home.webalta.ru',SL[i]) > 0) then begin
        SL[i] := ReplaceStr(SL[i],'http://home.webalta.ru','about:home');
        break;
      end;
    end;
    SL.SaveToFile(profiledir+'\prefs.js');
  end;

  SL.Destroy();
  result := true;
end;

function FixFirefox():boolean;
var
  SR: TSearchRec;
  Found: Boolean;
  FoxDir: string;
begin
  LogMessage('Очищаем браузер Firefox');
  FoxDir := GetSpecialFolderPath(CSIDL_APPDATA)+'\Mozilla\Firefox\Profiles';
  Found := FindFirst(FoxDir+'\*', faDirectory, SR) = 0;
  while Found do begin
    if (SR.Name <> '.') and (SR.Name <> '..') then begin
      FixFirefoxProfile(FoxDir+'\'+SR.Name);
    end;
    Found := (FindNext(SR) = 0);
  end;
  result := true;
end;

function FixOpera():boolean;
var
  SL: TStringList;
  i: integer;
  operadir: string;
begin
  LogMessage('Очищаем браузер Opera');
  operadir := GetSpecialFolderPath(CSIDL_APPDATA)+'\Opera\Opera';
  myDeleteFile(operadir+'\widgets\webalta.oex');

  SL := TStringList.Create;

  if (FileExists(operadir+'\operaprefs.ini')) then begin
    LogMessage('Исправляем файл operaprefs.ini');
    SL.LoadFromFile(operadir+'\operaprefs.ini');
    for i := 0 to SL.Count-1 do begin
      if (PosEx('http://home.webalta.ru/?new',SL[i]) > 0) then begin
        SL[i] := ReplaceStr(SL[i],'http://home.webalta.ru/?new','http://yandex.ru');
        break;
      end;
    end;
    SL.SaveToFile(operadir+'\operaprefs.ini');
  end;

  LogMessage('Исправляем файл search.ini');
  if (FileExists(operadir+'\search.ini')) then begin
    SL.LoadFromFile(operadir+'\search.ini');
    for i := 0 to SL.Count-1 do begin
      SL[i] := ReplaceStr(SL[i],'http://webalta.ru/srch?q=%s','http://yandex.ru/yandsearch?text=%s&lr=2');
      SL[i] := ReplaceStr(SL[i],'webalta Search','Yandex');
    end;
    SL.SaveToFile(operadir+'\search.ini');
  end;
  SL.Destroy();

  operadir := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)+'\Opera\Opera';
  myDeleteFile(operadir+'\widgets\webalta.oex');
end;

procedure DelUninstaller();
var
  s: string;
  Reg: TRegistry;
begin
  LogMessage('Удаляем "денисталяцию" Webalta');
  s := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA);
  RemoveFullDir(s+'\Webalta Toolbar');

  Reg := TRegistry.Create();
  Reg.RootKey := HKEY_CURRENT_USER;
  Reg.DeleteKey('Software\Microsoft\Windows\CurrentVersion\Uninstall\Webalta Toolbar');
  Reg.Destroy();
end;

function FixLink(LinkFileName: string): boolean;
var
  MyObject: IUnknown;
  MySLink: IShellLink;
  MyPFile: IPersistFile;
  WidePath: array[0..MAX_PATH] of WideChar;
  Buff: array[0..MAX_PATH] of WideChar;
begin
  result := false;
  if (fileexists(Linkfilename) = false) then
    exit;
  MyObject := CreateComObject(CLSID_ShellLink);
  MyPFile := MyObject as IPersistFile;
  MySLink := MyObject as IShellLink;

  StringToWideChar(LinkFileName, WidePath, SizeOf(WidePath));
  MyPFile.Load(WidePath, 0);
  MySLink.GetArguments(Buff, MAX_PATH);
  if (PosEx('webalta.ru',Buff) > 0) then begin
    Buff := '';
    MySLink.SetArguments(Buff);
    MyPFile.Save(WidePath,false);
    result := true;
  end;
end;

procedure ClearLinks(dirname: string);
var
  SR: TSearchRec;
  Found: Boolean;
begin
  if not DirectoryExists(dirname) then begin
    exit;
  end;
  LogMessage('Сканируем ярлыки в'#13#10+dirname);
  Found := FindFirst(dirname+'\*.lnk', faNormal, SR) = 0;
  while Found do begin
    if FixLink(dirname+'\'+SR.Name) then
      LogMessage('Ярлык '+SR.Name+' исцелен');
    Found := (FindNext(SR) = 0);
  end;
end;

procedure WebaltaRegScanKeys(Reg: TRegistry; Key: string; RegKeys: TStrings; ValueNames: TStrings);
var
  KeyPrefix, CurVal: string;
  SLKeys, SLValsNames: TStrings;
  i: integer;
begin
  reg.OpenKey(Key,false);

  if (Key = '') then begin
    KeyPrefix := ''
  end else begin
    KeyPrefix := Key+'\'
  end;

  SLKeys := TStringList.Create;
  reg.GetKeyNames(SLKeys);
  for i := 0 to SLKeys.Count-1 do begin
    RegKeys.Add(KeyPrefix+SLKeys[i]);
  end;
  SLKeys.Destroy;

  SLValsNames := TStringList.Create;
  reg.GetValueNames(SLValsNames);
  ValueNames.Clear();
  for i := 0 to SLValsNames.Count-1 do begin
    if (Reg.GetDataType(SLValsNames[i]) = rdString) then begin
      CurVal := LowerCase(Reg.GetDataAsString(SLValsNames[i]));
      if (PosEx('webalta',CurVal) > 0) then begin
        ValueNames.Add(SLValsNames[i]);
      end;
    end;
  end;
  SLValsNames.Destroy;

  reg.CloseKey();
end;

procedure KillWebalta;
var
  reg: TRegistry;
begin
  reg := TRegistry.Create();
  reg.RootKey := HKEY_LOCAL_MACHINE;

  CleanClsId(reg,'SOFTWARE\Classes\CLSID');
  CleanClsId(reg,'SOFTWARE\Classes\Record');

  reg.Destroy();

  FixIE();
  FixFirefox();
  FixOpera();
  DelUninstaller();

  ClearLinks(GetSpecialFolderPath(0));
  ClearLinks(GetSpecialFolderPath(CSIDL_APPDATA)+'\Microsoft\Internet Explorer\Quick Launch');
  ClearLinks(GetSpecialFolderPath(CSIDL_APPDATA)+'\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar');

  ClearLinks(GetSpecialFolderPath(CSIDL_COMMON_DESKTOPDIRECTORY));
  ClearLinks(GetSpecialFolderPath(CSIDL_COMMON_APPDATA)+'\Microsoft\Internet Explorer\Quick Launch');
  ClearLinks(GetSpecialFolderPath(CSIDL_COMMON_APPDATA)+'\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar');

end;

end.
