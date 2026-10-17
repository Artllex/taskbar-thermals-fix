# Windows PowerShell 5.1 compatible. The graphical installer supplies elevation.
[CmdletBinding()]
param(
 [ValidateSet('Install','Remove')][string]$Action='Install',
 [string]$PackageRoot=$PSScriptRoot,
 [string]$StateRoot=(Join-Path $env:ProgramData 'TaskbarThermalsFix'),
 [string]$WindhawkData=(Join-Path $env:ProgramData 'Windhawk'),
 [string]$RegistryRoot='HKLM:\SOFTWARE\Windhawk\Engine\Mods',
 [string]$ApplicationPath,
 [switch]$PatchApplication,
 [switch]$NoRestart
)
$ErrorActionPreference='Stop'
$modId='local@taskbar-thermals-start'
$key=Join-Path $RegistryRoot $modId
$stateFile=Join-Path $StateRoot 'state.json'
if(!$ApplicationPath -and !$NoRestart){
 $task=Get-ScheduledTask -TaskName TaskbarThermals -ErrorAction SilentlyContinue
 if($task){$ApplicationPath=@($task.Actions)[0].Execute}
}
function Read-Reg($path) {
 $items=@()
 if(Test-Path -LiteralPath $path){
  $item=Get-Item -LiteralPath $path
  foreach($name in $item.GetValueNames()){$items+=@{Name=$name;Kind=$item.GetValueKind($name).ToString();Value=$item.GetValue($name)}}
 }
 return ,$items
}
function Write-Reg($path,$items) {
 New-Item -Path $path -Force | Out-Null
 foreach($v in $items){New-ItemProperty -LiteralPath $path -Name $v.Name -PropertyType $v.Kind -Value $v.Value -Force | Out-Null}
}
function Save-State($state) {
 $temporary=Join-Path $StateRoot 'state.tmp'
 $state | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $temporary -Encoding UTF8
 Move-Item -LiteralPath $temporary -Destination $stateFile -Force
}
function Restart-Thermals {
 if($NoRestart){return}
 $task=Get-ScheduledTask -TaskName TaskbarThermals -ErrorAction SilentlyContinue
 if($task -and $task.State -ne 'Disabled'){Start-ScheduledTask -TaskName TaskbarThermals}
 elseif($ApplicationPath -and (Test-Path -LiteralPath $ApplicationPath)){Start-Process -FilePath $ApplicationPath -WindowStyle Hidden}
}
function Stop-Thermals {
 if($NoRestart){return}
 Stop-ScheduledTask -TaskName TaskbarThermals -ErrorAction SilentlyContinue
 $running=@(Get-Process TaskbarThermals -ErrorAction SilentlyContinue)
 foreach($process in $running){if(!$process.CloseMainWindow()){} }
 foreach($process in $running){if(!$process.WaitForExit(3000)){Stop-Process -Id $process.Id -Force -ErrorAction Stop}}
}
function Copy-App($from,$to) {
 # Renaming a mapped executable avoids overwriting an image still held by a scanner.
 $retired=$to+'.thermals-fix-old'
 if(Test-Path -LiteralPath $retired){Remove-Item -LiteralPath $retired -Force}
 if(Test-Path -LiteralPath $to){Move-Item -LiteralPath $to -Destination $retired}
 try {Copy-Item -LiteralPath $from -Destination $to -Force}
 catch {if(Test-Path -LiteralPath $retired){Move-Item -LiteralPath $retired -Destination $to -Force};throw}
 Remove-Item -LiteralPath $retired -Force -ErrorAction SilentlyContinue
}
function Restore($state) {
 if($state.ApplicationPath){$script:ApplicationPath=$state.ApplicationPath}
 if(Test-Path -LiteralPath $key){Set-ItemProperty -LiteralPath $key -Name Disabled -Value 1}
 if(!$NoRestart){Start-Sleep -Milliseconds 900}
 Stop-Thermals
 foreach($file in @($state.CreatedDlls)){
  $candidate=Join-Path (Join-Path $WindhawkData 'Engine\Mods\64') ([IO.Path]::GetFileName($file))
  if([IO.Path]::GetFileName($file) -notlike 'local@taskbar-thermals-start_*_fix.dll'){throw 'Invalid managed DLL name in state.'}
  Remove-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue
 }
 $source=Join-Path $WindhawkData ('ModsSource\'+$modId+'.wh.cpp')
 if($state.SourceExisted){Copy-Item -LiteralPath (Join-Path $StateRoot 'original-mod.wh.cpp') -Destination $source -Force}
 else {Remove-Item -LiteralPath $source -Force -ErrorAction SilentlyContinue}
 if($state.ModExisted){
  # This module has no user settings subkeys. Restore its original root values exactly.
  if(Test-Path -LiteralPath $key){Remove-Item -LiteralPath $key -Recurse -Force}
  Write-Reg $key $state.ModValues
 } elseif(Test-Path -LiteralPath $key){Remove-Item -LiteralPath $key -Recurse -Force}
 $retained=$false
 if($state.AppPatched){
  $script:ApplicationPath=$state.ApplicationPath
  $current=if(Test-Path -LiteralPath $ApplicationPath){(Get-FileHash -LiteralPath $ApplicationPath -Algorithm SHA256).Hash}else{''}
  if(!$current -or $current -eq $state.InstalledAppHash){Copy-App (Join-Path $StateRoot 'original-TaskbarThermals.exe') $ApplicationPath}
  else {$retained=$true;Write-Warning 'Taskbar Thermals changed after installation. It was not overwritten. Original backup retained in the state directory.'}
 }
 Restart-Thermals
 return $retained
}
try {
 if($Action -eq 'Remove'){
  if(!(Test-Path -LiteralPath $stateFile)){return}
  $state=Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
  $retained=Restore $state
  if(!$retained){Remove-Item -LiteralPath $stateFile -Force;foreach($name in @('original-mod.wh.cpp','original-TaskbarThermals.exe')){Remove-Item -LiteralPath (Join-Path $StateRoot $name) -Force -ErrorAction SilentlyContinue}}
  return
 }
 if(!(Test-Path -LiteralPath (Join-Path $WindhawkData 'Engine\Mods\64'))){throw 'Windhawk is not installed in the selected data directory.'}
 $manifest=Get-Content -LiteralPath (Join-Path $PackageRoot 'manifest.json') -Raw | ConvertFrom-Json
 foreach($entry in $manifest.Files){
  if([IO.Path]::GetFileName($entry.Name) -ne $entry.Name){throw 'Invalid payload name.'}
  if((Get-FileHash -LiteralPath (Join-Path $PackageRoot $entry.Name) -Algorithm SHA256).Hash -ne $entry.SHA256){throw ('Payload integrity check failed: '+$entry.Name)}
 }
 $existingState=Test-Path -LiteralPath $stateFile
 if($existingState){$state=Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json}
 else {
  New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null
  $source=Join-Path $WindhawkData ('ModsSource\'+$modId+'.wh.cpp')
  $state=[pscustomobject]@{Schema=1;ModExisted=(Test-Path -LiteralPath $key);ModValues=(Read-Reg $key);SourceExisted=(Test-Path -LiteralPath $source);CreatedDlls=@();AppPatched=$false;ApplicationPath=$ApplicationPath;InstalledAppHash=''}
  if($state.SourceExisted){Copy-Item -LiteralPath $source -Destination (Join-Path $StateRoot 'original-mod.wh.cpp')}
 }
 if($PatchApplication){
  if(!$ApplicationPath -or !(Test-Path -LiteralPath $ApplicationPath) -or [IO.Path]::GetFileName($ApplicationPath) -ne 'TaskbarThermals.exe'){throw 'Choose an existing TaskbarThermals.exe for the optional application patch.'}
  $appHash=(Get-FileHash -LiteralPath $ApplicationPath -Algorithm SHA256).Hash
  $payloadHash=($manifest.Files | Where-Object {$_.Name -eq 'TaskbarThermals.exe'}).SHA256
  $supported=@('FC0E36618ACC8C35EC12E6265C9DA3C63473E42169ED3FD805D2B647DD36966A','48ADD15552C2F337799EDED772EF1AC4E5FA51F59890519382F06DDAAED48FF3',$payloadHash)
  if($state.AppPatched){$supported+=@($state.InstalledAppHash)}
  if($appHash -notin $supported){throw 'Optional screenshot patch supports the official framework-dependent Taskbar Thermals 1.1.0 executable only. Uncheck that component for other versions.'}
  if($state.AppPatched -and $state.ApplicationPath -ne $ApplicationPath){throw 'An application patch is already installed at another path. Uninstall it before changing the path.'}
  if(!$state.AppPatched){Copy-Item -LiteralPath $ApplicationPath -Destination (Join-Path $StateRoot 'original-TaskbarThermals.exe') -Force}
 }
 # Record rollback information before changing anything in Windhawk.
 Save-State $state
 $previousValues=Read-Reg $key
 $previousSource=Join-Path $StateRoot 'upgrade-source.wh.cpp'
 $source=Join-Path $WindhawkData ('ModsSource\'+$modId+'.wh.cpp')
 if(Test-Path -LiteralPath $source){Copy-Item -LiteralPath $source -Destination $previousSource -Force}
 $dllName='local@taskbar-thermals-start_'+$manifest.ModVersion+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'_fix.dll'
 $state.CreatedDlls=@($state.CreatedDlls)+@($dllName)
 Save-State $state
 try {
  if(Test-Path -LiteralPath $key){Set-ItemProperty -LiteralPath $key -Name Disabled -Value 1}
  if(!$NoRestart){Start-Sleep -Milliseconds 900}
  Copy-Item -LiteralPath (Join-Path $PackageRoot 'compatibility.dll') -Destination (Join-Path (Join-Path $WindhawkData 'Engine\Mods\64') $dllName)
  Copy-Item -LiteralPath (Join-Path $PackageRoot 'taskbar-thermals-start.wh.cpp') -Destination $source -Force
  Write-Reg $key @(@{Name='Disabled';Kind='DWord';Value=1},@{Name='LibraryFileName';Kind='String';Value=$dllName},@{Name='Version';Kind='String';Value=$manifest.ModVersion},@{Name='Include';Kind='String';Value='explorer.exe'},@{Name='Exclude';Kind='String';Value=''},@{Name='Architecture';Kind='String';Value='x86-64'},@{Name='LoggingEnabled';Kind='DWord';Value=0})
  if($PatchApplication){
   Stop-Thermals
   Copy-App (Join-Path $PackageRoot 'TaskbarThermals.exe') $ApplicationPath
   $state.AppPatched=$true;$state.ApplicationPath=$ApplicationPath;$state.InstalledAppHash=$payloadHash
  }
  Save-State $state
  Set-ItemProperty -LiteralPath $key -Name Disabled -Value 0
  # A fresh window starts in the desktop band; the hook follows subsequent Start transitions.
  if(!$PatchApplication){Stop-Thermals}
  Restart-Thermals
 } catch {
  if($existingState){
   if(Test-Path -LiteralPath $key){Remove-Item -LiteralPath $key -Recurse -Force}
   Write-Reg $key $previousValues
   if(Test-Path -LiteralPath $previousSource){Copy-Item -LiteralPath $previousSource -Destination $source -Force}
   Restart-Thermals
  } else {[void](Restore $state);Remove-Item -LiteralPath $stateFile -Force -ErrorAction SilentlyContinue}
  throw
 } finally {Remove-Item -LiteralPath $previousSource -Force -ErrorAction SilentlyContinue}
 Write-Output 'Taskbar Thermals Fix installed.'
} catch {
 New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null
 $_ | Out-String | Set-Content -LiteralPath (Join-Path $StateRoot 'last-error.txt') -Encoding UTF8
 Write-Error $_
 exit 1
}
