param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$AppVersion,

  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$OutputBaseFilename
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$issPath = Join-Path $repositoryRoot 'certificate-studio.iss'
$iss = @"
[Setup]
AppId={{A6C1C3D8-7D1B-4AC6-9CB7-4D1F7F0A1E01}}
AppName=Certificate Studio
AppVersion=$AppVersion
DefaultDirName={autopf}\Certificate Studio
DefaultGroupName=Certificate Studio
OutputDir=.
OutputBaseFilename=$OutputBaseFilename
Compression=lzma
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayName=Certificate Studio
; Per-user data is stored outside {app} in %APPDATA%\com.example\certificate_studio.
; Preserve the database, encryption key, generated artifacts, and project assets on uninstall.
; Never add an [UninstallDelete] rule for the user's Application Support directory.

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Certificate Studio"; Filename: "{app}\certificate_studio.exe"
Name: "{autodesktop}\Certificate Studio"; Filename: "{app}\certificate_studio.exe"

[Run]
Filename: "{app}\certificate_studio.exe"; Description: "Launch Certificate Studio"; Flags: nowait postinstall skipifsilent
"@

Set-Content -Path $issPath -Value $iss -Encoding ASCII
$compiler = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
& $compiler $issPath
if ($LASTEXITCODE -ne 0) {
  throw "Inno Setup compiler failed with exit code $LASTEXITCODE."
}
