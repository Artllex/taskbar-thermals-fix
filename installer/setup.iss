#define AppVersion "1.0.0"
[Setup]
AppId={{A43F5E34-0B5A-43DA-9EB3-B10F80A22881}
AppName=Taskbar Thermals Fix
AppVersion={#AppVersion}
AppPublisher=Artllex
AppPublisherURL=https://github.com/Artllex/taskbar-thermals-fix
AppSupportURL=https://github.com/Artllex/taskbar-thermals-fix/issues
DefaultDirName={autopf}\Taskbar Thermals Fix
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.22000
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=TaskbarThermalsFix-{#AppVersion}-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=Taskbar Thermals Fix
CloseApplications=no
RestartApplications=no
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"

[Types]
Name: "standard"; Description: "{cm:StandardInstall}"
Name: "full"; Description: "{cm:FullInstall}"
Name: "custom"; Description: "{cm:CustomInstall}"; Flags: iscustom

[Components]
Name: "compatibility"; Description: "{cm:CompatibilityComponent}"; Types: standard full custom; Flags: fixed
Name: "application"; Description: "{cm:ApplicationComponent}"; Types: full

[Files]
Source: "..\build\payload\*"; DestDir: "{app}\payload"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Apply-Fix.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.pl.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\THIRD-PARTY-NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion

[CustomMessages]
english.StandardInstall=Start menu compatibility only
polish.StandardInstall=Tylko zgodność z menu Start
english.FullInstall=Start menu compatibility and optional screenshot fix
polish.FullInstall=Zgodność z menu Start i opcjonalna poprawka zrzutów
english.CustomInstall=Custom installation
polish.CustomInstall=Instalacja niestandardowa
english.CompatibilityComponent=Windhawk module: keep the panel visible with Start open
polish.CompatibilityComponent=Moduł Windhawk: widoczny panel przy otwartym menu Start
english.ApplicationComponent=Optional: patch Taskbar Thermals 1.1.0 for screen capture compatibility
polish.ApplicationComponent=Opcjonalnie: poprawka zrzutów dla Taskbar Thermals 1.1.0
english.PathTitle=Taskbar Thermals executable
polish.PathTitle=Plik wykonywalny Taskbar Thermals
english.PathSubtitle=Select the existing application to back up and patch.
polish.PathSubtitle=Wybierz obecny program do wykonania kopii i aktualizacji.
english.PathDescription=Only the official .NET-dependent Taskbar Thermals 1.1.0 executable and the documented local build are supported. Settings, logs and startup configuration are preserved.
polish.PathDescription=Obsługiwany jest oficjalny plik Taskbar Thermals 1.1.0 wymagający .NET oraz udokumentowana lokalna kompilacja. Ustawienia, logi i konfiguracja autostartu zostaną zachowane.
english.PathInvalid=Choose an existing file named TaskbarThermals.exe.
polish.PathInvalid=Wybierz istniejący plik o nazwie TaskbarThermals.exe.
english.NeedWindhawk=Install the standard (non-portable) x64 version of Windhawk first. Tested with Windhawk 1.7.3.
polish.NeedWindhawk=Najpierw zainstaluj standardową (nieprzenośną) wersję x64 Windhawk. Testowano z Windhawk 1.7.3.
english.BackendFailed=The operation failed. See the Windows setup log and %1 for details. Existing configuration is backed up before changes.
polish.BackendFailed=Operacja nie powiodła się. Szczegóły znajdują się w logu instalatora oraz w %1. Przed zmianami wykonywana jest kopia konfiguracji.

[Code]
var AppPathPage: TInputFileWizardPage;

function InitializeSetup(): Boolean;
begin
  Result := RegKeyExists(HKLM64, 'SOFTWARE\Windhawk\Engine') and
    DirExists(ExpandConstant('{commonappdata}\Windhawk\Engine\Mods\64'));
  if not Result then MsgBox(CustomMessage('NeedWindhawk'), mbError, MB_OK);
end;

procedure InitializeWizard();
var Candidate: String;
begin
  AppPathPage := CreateInputFilePage(wpSelectComponents, CustomMessage('PathTitle'),
    CustomMessage('PathSubtitle'), CustomMessage('PathDescription'));
  AppPathPage.Add('TaskbarThermals.exe', 'Executable|TaskbarThermals.exe', '.exe');
  Candidate := ExpandConstant('{userstartup}\TaskbarThermals.exe');
  if not FileExists(Candidate) then
    Candidate := ExpandConstant('{localappdata}\Programs\TaskbarThermals\TaskbarThermals.exe');
  if FileExists(Candidate) then AppPathPage.Values[0] := Candidate;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = AppPathPage.ID) and not WizardIsComponentSelected('application');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = AppPathPage.ID then begin
    Result := FileExists(AppPathPage.Values[0]) and
      (CompareText(ExtractFileName(AppPathPage.Values[0]), 'TaskbarThermals.exe') = 0);
    if not Result then MsgBox(CustomMessage('PathInvalid'), mbError, MB_OK);
  end;
end;

function RunBackend(Action: String; Installing: Boolean): Boolean;
var Args: String; Code: Integer;
begin
  Args := '-NoProfile -ExecutionPolicy Bypass -File ' +
    AddQuotes(ExpandConstant('{app}\Apply-Fix.ps1')) + ' -Action ' + Action +
    ' -PackageRoot ' + AddQuotes(ExpandConstant('{app}\payload'));
  if Installing and WizardIsComponentSelected('application') then
    Args := Args + ' -PatchApplication -ApplicationPath ' + AddQuotes(AppPathPage.Values[0]);
  Result := Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    Args, '', SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 0);
  if not Result then MsgBox(FmtMessage(CustomMessage('BackendFailed'), [ExpandConstant('{commonappdata}\TaskbarThermalsFix\last-error.txt')]), mbError, MB_OK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    if not RunBackend('Install', True) then RaiseException('Taskbar Thermals Fix installation failed.');
end;

function InitializeUninstall(): Boolean;
begin
  Result := RunBackend('Remove', False);
end;

