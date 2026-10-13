param([Parameter(Mandatory=$true)][string]$GamePath)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$game=(Resolve-Path -LiteralPath $GamePath).Path
$exe=Join-Path $game 'WoW.exe'
$expected='5014CA1CFEDF860F10E93FE7D955C56C28EB11A2BB503030DBB9B1C777F00470'
if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne $expected) {throw 'This rendering test supports only the exact inspected OctoWoW client. No files changed.'}
$running=Get-CimInstance Win32_Process -Filter "name='WoW.exe'" | Where-Object { $_.ExecutablePath -eq $exe }
if($running) {throw 'Close this WoW client before installing the rendering bridge.'}
$loader=Join-Path $game 'dlls.txt'
if(-not (Test-Path -LiteralPath $loader)) {throw 'VanillaFixes dlls.txt is required.'}
$entry='Interface/AddOns/OctoAggro/native/OctoAggroNative.dll'
$previous=Get-Content -LiteralPath $loader
$target=Join-Path $game 'Interface\AddOns\OctoAggro'
$files=@('OctoAggro.toc','World.lua','Settings.lua','README.md','LICENSE','native\OctoAggroNative.dll')
foreach($file in $files){if(-not (Test-Path -LiteralPath (Join-Path $repo $file) -PathType Leaf)){throw "Missing: $file"}}
$backup=Join-Path $game ('AddonBackups\OctoAggro-world-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item -LiteralPath $loader -Destination (Join-Path $backup 'dlls.txt')
if(Test-Path -LiteralPath $target){Copy-Item -LiteralPath $target -Destination (Join-Path $backup 'OctoAggro') -Recurse}
foreach($file in $files){
  $src=Join-Path $repo $file;$dst=Join-Path $target $file
  New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force | Out-Null
  if([IO.Path]::GetFullPath($src) -ne [IO.Path]::GetFullPath($dst)){Copy-Item -LiteralPath $src -Destination $dst -Force}
  if((Get-FileHash -LiteralPath $src).Hash -ne (Get-FileHash -LiteralPath $dst).Hash){throw "File verification failed: $file"}
}
if($previous -notcontains $entry){
  $content=[IO.File]::ReadAllText($loader).TrimEnd("`r","`n")+"`r`n"+$entry+"`r`n"
  [IO.File]::WriteAllText($loader,$content,[Text.UTF8Encoding]::new($false))
}
$after=Get-Content -LiteralPath $loader
if(@($after | Where-Object {$_ -eq $entry}).Count -ne 1){throw 'Rendering bridge loader entry was not unique.'}
foreach($line in $previous){if($line -and $after -notcontains $line){throw 'An existing loader entry changed.'}}
$hashes=@{};foreach($file in $files){$hashes[$file]=(Get-FileHash -LiteralPath (Join-Path $target $file)).Hash}
$evidence=[pscustomobject]@{Target=$target;FilesVerified=$files.Count;Backup=$backup;LoaderEntry=$entry;LoaderHash=(Get-FileHash -LiteralPath $loader).Hash;FileHashes=$hashes;LiveWorldTested=$false}
$evidence | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backup 'verification.json') -Encoding utf8
$evidence
