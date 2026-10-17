param([string]$Payload=(Join-Path (Split-Path -Parent $PSScriptRoot) 'build\payload'))
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$testRoot=Join-Path $env:TEMP ('thermals-fix-test-'+[Guid]::NewGuid().ToString('N'))
$registry='HKCU:\Software\TaskbarThermalsFixTests\'+[Guid]::NewGuid().ToString('N')+'\Mods'
$key=Join-Path $registry 'local@taskbar-thermals-start'
$windhawk=Join-Path $testRoot 'Windhawk'
$state=Join-Path $testRoot 'State'
$app=Join-Path $testRoot 'TaskbarThermals.exe'
$powershell=(Get-Command powershell.exe).Source
New-Item -ItemType Directory -Path (Join-Path $windhawk 'Engine\Mods\64'),(Join-Path $windhawk 'ModsSource'),$state -Force | Out-Null
$checks=0
function Check($ok,$message){if(!$ok){throw $message};$script:checks++}
function Backend($action,$patch=$false,$expect=0){
 $args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $root 'installer\Apply-Fix.ps1'),'-Action',$action,'-PackageRoot',$Payload,'-StateRoot',$state,'-WindhawkData',$windhawk,'-RegistryRoot',$registry,'-NoRestart')
 if($patch){$args+=@('-PatchApplication','-ApplicationPath',$app)}
 $output=& $powershell @args 2>&1
 if($LASTEXITCODE -ne $expect){throw "Backend $action exit=$LASTEXITCODE expected=$expect`n$output"}
}
try {
 Backend Install
 Check (Test-Path -LiteralPath $key) 'Module registration missing.'
 Check ((Get-ItemProperty $key).Disabled -eq 0) 'Module should be enabled.'
 Backend Install
 $saved=Get-Content (Join-Path $state 'state.json') -Raw | ConvertFrom-Json
 Check (!$saved.ModExisted) 'Upgrade lost the original absent-module state.'
 Backend Remove
 Check (!(Test-Path -LiteralPath $key)) 'Uninstall did not remove a new registration.'
 Check (@(Get-ChildItem (Join-Path $windhawk 'Engine\Mods\64') -Filter '*_fix.dll').Count -eq 0) 'Managed DLLs remain after uninstall.'

 New-Item -Path $key -Force | Out-Null
 New-ItemProperty $key -Name Disabled -PropertyType DWord -Value 1 | Out-Null
 New-ItemProperty $key -Name LibraryFileName -PropertyType String -Value 'previous.dll' | Out-Null
 $source=Join-Path $windhawk 'ModsSource\local@taskbar-thermals-start.wh.cpp'
 Set-Content -LiteralPath $source -Value 'previous source' -Encoding UTF8
 $sourceHash=(Get-FileHash $source).Hash
 Backend Install
 Backend Remove
 Check ((Get-ItemProperty $key).Disabled -eq 1) 'Previous disabled state was not restored.'
 Check ((Get-ItemProperty $key).LibraryFileName -eq 'previous.dll') 'Previous DLL reference was not restored.'
 Check ((Get-FileHash $source).Hash -eq $sourceHash) 'Previous source was not restored byte-for-byte.'

 Copy-Item -LiteralPath (Join-Path $Payload 'TaskbarThermals.exe') -Destination $app
 $originalHash=(Get-FileHash $app).Hash
 Backend Install $true
 Check ((Get-Content (Join-Path $state 'state.json') -Raw | ConvertFrom-Json).AppPatched) 'Optional patch was not recorded.'
 Backend Install $true
 Check ((Get-FileHash (Join-Path $state 'original-TaskbarThermals.exe')).Hash -eq $originalHash) 'Application upgrade replaced the original backup.'
 Backend Remove
 Check ((Get-FileHash $app).Hash -eq $originalHash) 'Application backup was not restored.'

 Set-Content -LiteralPath $app -Value 'unknown application version'
 Backend Install $true 1
 Check ((Get-Content $app -Raw).Trim() -eq 'unknown application version') 'Unsupported application was overwritten.'
 Check ((Get-ItemProperty $key).LibraryFileName -eq 'previous.dll') 'Validation failure changed the previous mod.'

 Copy-Item -LiteralPath (Join-Path $Payload 'TaskbarThermals.exe') -Destination $app -Force
 Backend Install $true
 Set-Content -LiteralPath $app -Value 'newer user-installed application'
 Backend Remove
 Check ((Get-Content $app -Raw).Trim() -eq 'newer user-installed application') 'Uninstall overwrote a newer application.'
 Check (Test-Path -LiteralPath (Join-Path $state 'original-TaskbarThermals.exe')) 'Uninstall discarded the retained application backup.'

 Write-Output "PASS: $checks installer lifecycle assertions (isolated files and HKCU registry; Windows PowerShell 5.1)."
} finally {
 if(Test-Path -LiteralPath $registry){Remove-Item -LiteralPath $registry -Recurse -Force}
 $resolved=[IO.Path]::GetFullPath($testRoot)
 $temporary=[IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')+'\'
 if(!$resolved.StartsWith($temporary,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe test cleanup path.'}
 Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
}
