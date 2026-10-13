param([Parameter(Mandatory=$true)][string]$GamePath,[Parameter(Mandatory=$true)][string]$BackupPath)
$ErrorActionPreference='Stop'
$game=(Resolve-Path -LiteralPath $GamePath).Path
$backup=(Resolve-Path -LiteralPath $BackupPath).Path
$evidence=Get-Content -Raw -LiteralPath (Join-Path $backup 'verification.json') | ConvertFrom-Json
$target=[IO.Path]::GetFullPath((Join-Path $game 'Interface\AddOns\OctoAggro'))
if($target -ne $evidence.Target){throw 'Backup belongs to another installation.'}
if(-not $target.StartsWith($game.TrimEnd('\')+'\Interface\AddOns\',[StringComparison]::OrdinalIgnoreCase)){throw 'Target is outside the addon directory.'}
$exe=Join-Path $game 'WoW.exe'
if(Get-CimInstance Win32_Process -Filter "name='WoW.exe'" | Where-Object {$_.ExecutablePath -eq $exe}){throw 'Close WoW before restoring.'}
$loader=Join-Path $game 'dlls.txt'
if((Get-FileHash -LiteralPath $loader).Hash -ne $evidence.LoaderHash){throw 'dlls.txt changed after installation; automatic restore refuses to overwrite it.'}
$files=Get-ChildItem -LiteralPath $target -Recurse -File -Force
if($files.Count -ne $evidence.FilesVerified){throw 'Addon folder has additional files; automatic restore refuses to remove it.'}
foreach($property in $evidence.FileHashes.PSObject.Properties){
  $file=[IO.Path]::GetFullPath((Join-Path $target $property.Name))
  if(-not $file.StartsWith($target+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Invalid backup file path.'}
  if((Get-FileHash -LiteralPath $file).Hash -ne $property.Value){throw "Addon file changed: $($property.Name)"}
}
# The absolute target was checked above and contains exactly the verified files.
Copy-Item -LiteralPath (Join-Path $backup 'dlls.txt') -Destination $loader -Force
Remove-Item -LiteralPath $target -Recurse -Force
$old=Join-Path $backup 'OctoAggro'
if(Test-Path -LiteralPath $old){Copy-Item -LiteralPath $old -Destination $target -Recurse}
if((Get-FileHash -LiteralPath $loader).Hash -ne (Get-FileHash -LiteralPath (Join-Path $backup 'dlls.txt')).Hash){throw 'Loader restore verification failed.'}
'OctoAggro world installation restored; loader hash verified.'
