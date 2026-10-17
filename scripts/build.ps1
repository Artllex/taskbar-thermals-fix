[CmdletBinding()]
param(
 [string]$Dotnet='dotnet',
 [string]$WindhawkPath=(Join-Path $env:ProgramFiles 'Windhawk'),
 [string]$InnoCompiler,
 [switch]$SkipInstaller
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
$build=Join-Path $root 'build'
$payload=Join-Path $build 'payload'
$dist=Join-Path $root 'dist'
New-Item -ItemType Directory -Path $payload,$dist -Force | Out-Null
$project=Join-Path $root 'vendor\TaskbarThermals\TaskbarThermals.csproj'
& $Dotnet restore $project --locked-mode -r win-x64 -p:PublishSingleFile=true -p:SelfContained=false -p:IncludeNativeLibrariesForSelfExtract=true
if($LASTEXITCODE){throw 'Application dependency restore failed.'}
& $Dotnet publish $project --no-restore -c Release -r win-x64 --self-contained false -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:IncludeSourceRevisionInInformationalVersion=false -o (Join-Path $build 'application')
if($LASTEXITCODE){throw 'Application build failed.'}
Copy-Item -LiteralPath (Join-Path $build 'application\TaskbarThermals.exe') -Destination $payload -Force
$mod=Join-Path $root 'src\taskbar-thermals-start.wh.cpp'
$version='1.0.0'
$engine=Join-Path $WindhawkPath 'Engine\1.7.3\64\windhawk.lib'
if(!(Test-Path -LiteralPath $engine)){throw 'This build uses the Windhawk 1.7.3 SDK. Install the pinned offline distribution first.'}
& (Join-Path $WindhawkPath 'Compiler\bin\clang++.exe') -std=c++23 -O2 -shared -DUNICODE -D_UNICODE -DWINVER=0x0A00 -D_WIN32_WINNT=0x0A00 -DWH_MOD -include windhawk_api.h -target x86_64-w64-mingw32 '-Wl,--export-all-symbols' $mod $engine -o (Join-Path $payload 'compatibility.dll')
if($LASTEXITCODE){throw 'Windhawk module build failed.'}
Copy-Item -LiteralPath $mod -Destination $payload -Force
Copy-Item -LiteralPath (Join-Path $root 'vendor\TaskbarThermals\LICENSE') -Destination (Join-Path $payload 'TaskbarThermals-LICENSE.txt') -Force
$licenses=Join-Path $payload 'licenses'
New-Item -ItemType Directory -Path $licenses -Force | Out-Null
$assets=Get-Content (Join-Path $root 'vendor\TaskbarThermals\obj\project.assets.json') -Raw | ConvertFrom-Json
$packageRoot=if($env:NUGET_PACKAGES){$env:NUGET_PACKAGES}else{Join-Path $env:USERPROFILE '.nuget\packages'}
$notices=@('# Bundled .NET application dependencies','','The application is derived from Quenchh/taskbar-thermals, MIT, commit 23207757799d2df6d22f2a42825cea81404ccbde.','','The following packages are unmodified. Exact package versions and hashes are locked in vendor/TaskbarThermals/packages.lock.json. Source links identify the upstream repositories/commits where available. MPL-covered libraries remain under MPL-2.0.','','| Package | License | Source | Copyright / authors |','| --- | --- | --- | --- |')
$expressions=@('MIT','MPL-2.0')
foreach($entry in $assets.libraries.PSObject.Properties){
 if($entry.Value.type -ne 'package' -or $entry.Name -like 'runtime.*' -or $entry.Name -like 'Microsoft.NET.ILLink.Tasks/*'){continue}
 $folder=Join-Path $packageRoot $entry.Value.path
 $spec=Get-ChildItem -LiteralPath $folder -Filter '*.nuspec' | Select-Object -First 1
 [xml]$xml=Get-Content -LiteralPath $spec.FullName
 $meta=$xml.package.metadata
 foreach($noticeFile in (Get-ChildItem -LiteralPath $folder -File | Where-Object {$_.Name -match '^(LICENSE|COPYING|NOTICE|THIRD-PARTY)'})){
  Copy-Item -LiteralPath $noticeFile.FullName -Destination (Join-Path $licenses ($entry.Name.Replace('/','-')+'-'+$noticeFile.Name)) -Force
 }
 $license=if($meta.license){$meta.license.InnerText}else{'MIT (upstream Mono)'}
 $source=[string]$meta.projectUrl
 if($meta.repository.url){$source=[string]$meta.repository.url;if($meta.repository.commit){$source=$source.TrimEnd('/').Replace('.git','')+'/tree/'+$meta.repository.commit}}
 if($meta.license.type -eq 'file'){
  $licenseFile=Join-Path $folder $license
  if(!(Test-Path -LiteralPath $licenseFile)){throw "Missing package license: $($entry.Name)"}
  Copy-Item -LiteralPath $licenseFile -Destination (Join-Path $licenses ($entry.Name.Replace('/','-')+'-LICENSE.txt')) -Force
 } elseif($meta.license){$expressions+=@($license -split ' OR | AND ' | ForEach-Object {$_.Trim('() ')})}
 $credit=if($meta.copyright){$meta.copyright}else{$meta.authors}
 $notices+=('| '+$entry.Name+' | '+$license+' | '+$source+' | '+$credit+' |')
}
Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/mono/mono/main/LICENSE' -OutFile (Join-Path $licenses 'Mono.Posix.NETStandard-1.0.0-LICENSE.txt')
# Canonical license texts, rather than links alone, accompany the binaries.
foreach($expression in ($expressions | Sort-Object -Unique)){
 if($expression -notmatch '^[A-Za-z0-9.+-]+$'){throw "Unsupported license expression: $expression"}
 Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/spdx/license-list-data/main/text/$expression.txt" -OutFile (Join-Path $licenses ($expression+'.txt'))
}
$notices | Set-Content -LiteralPath (Join-Path $payload 'DEPENDENCY-NOTICES.md') -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $root 'THIRD-PARTY-NOTICES.md') -Destination $payload -Force
$files=@(Get-ChildItem -LiteralPath $payload -File | Where-Object {$_.Name -ne 'manifest.json'} | ForEach-Object {@{Name=$_.Name;SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}})
@{Version=$version;ModVersion=$version;Files=$files} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $payload 'manifest.json') -Encoding UTF8
if(!$SkipInstaller){
 if(!$InnoCompiler){
  foreach($path in @((Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),(Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'))){if(Test-Path -LiteralPath $path){$InnoCompiler=$path;break}}
 }
 if(!$InnoCompiler){throw 'Inno Setup 6 compiler not found. Use -InnoCompiler to select ISCC.exe.'}
 & $InnoCompiler (Join-Path $root 'installer\setup.iss')
 if($LASTEXITCODE){throw 'Installer compilation failed.'}
}
Write-Output "Built package in $payload"
} finally {Pop-Location}
