param([Parameter(Mandatory=$true)][string]$BackupPath)
$ErrorActionPreference='Stop'
$backup=(Resolve-Path -LiteralPath $BackupPath).Path
$manifest=Get-Content -LiteralPath (Join-Path $backup 'dll-install.json') -Raw | ConvertFrom-Json
$game=(Resolve-Path -LiteralPath $manifest.GamePath).Path
if((Get-Process -Name WoW -ErrorAction SilentlyContinue) -or (Get-CimInstance Win32_Process -Filter "name='WoW.exe'")){throw 'Lukk WoW forst.'}
$loader=Join-Path $game 'dlls.txt'
if((Get-FileHash -LiteralPath $loader).Hash -ne $manifest.LoaderHash){throw 'dlls.txt er endret siden installasjonen. Ingen filer endret.'}
$oldLoader=Join-Path $backup 'dlls.txt'
if((Get-FileHash -LiteralPath $oldLoader).Hash -ne $manifest.BackupLoaderHash){throw 'Sikkerhetskopien er endret. Ingen filer endret.'}
$allowed=@((Join-Path $game 'ClassicAPI.dll'),(Join-Path $game 'UnitXP_SP3.dll'),(Join-Path $game 'Interface\AddOns\OctoAggro\native\OctoAggroNative.dll'))
foreach($file in $manifest.CreatedFiles){
  if($allowed -notcontains [IO.Path]::GetFullPath($file.Path)){throw 'Uventet filsti i sikkerhetskopien.'}
  if((Get-FileHash -LiteralPath $file.Path).Hash -ne $file.Hash){throw ('Filen er endret: '+$file.Path)}
}
Copy-Item -LiteralPath $oldLoader -Destination $loader -Force
foreach($file in $manifest.CreatedFiles){Remove-Item -LiteralPath $file.Path -Force}
if((Get-FileHash -LiteralPath $loader).Hash -ne $manifest.BackupLoaderHash){throw 'Kontroll av gjenoppretting feilet.'}
'DLL-installasjonen er angret. Tidligere DLL-filer og OctoAggro-filer er beholdt.'
