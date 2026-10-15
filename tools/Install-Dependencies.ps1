param([string]$GamePath)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
if(-not $GamePath){
  . (Join-Path $PSScriptRoot 'Find-Game.ps1')
  $GamePath=Find-OctoAggroGamePath
  Write-Host ('Fant spillmappen automatisk: '+$GamePath)
}
$game=(Resolve-Path -LiteralPath $GamePath).Path
$exe=Join-Path $game 'WoW.exe'
if((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne '5014CA1CFEDF860F10E93FE7D955C56C28EB11A2BB503030DBB9B1C777F00470'){throw 'Feil WoW-klient. Ingen spillfiler endret.'}
if((Get-Process -Name WoW -ErrorAction SilentlyContinue) -or (Get-CimInstance Win32_Process -Filter "name='WoW.exe'")){throw 'Lukk WoW helt og prov igjen.'}
$addon=Join-Path $game 'Interface\AddOns\OctoAggro'
if(-not (Test-Path -LiteralPath (Join-Path $addon 'OctoAggro.toc') -PathType Leaf)){throw 'OctoAggro mangler. Installer tillegget gjennom launcheren forst.'}
$loader=Join-Path $game 'dlls.txt'
if(-not (Test-Path -LiteralPath (Join-Path $game 'VanillaFixes.exe') -PathType Leaf) -or -not (Test-Path -LiteralPath $loader -PathType Leaf)){throw 'VanillaFixes.exe og dlls.txt mangler. Installer VanillaFixes gjennom launcheren forst.'}
$dependencies=@(
  @{Name='ClassicAPI.dll';URL='https://github.com/brues-code/ClassicAPI/releases/download/v1.15.16/ClassicAPI.dll';Hash='E34886FB9725B9059375A5C37BFF81CE220633C4E2C39719EF3223A6B8FC703D'},
  @{Name='UnitXP_SP3.dll';URL='https://github.com/brues-code/UnitXP_SP3/releases/download/v90/UnitXP_SP3.dll';Hash='1D1A622FC4FD74864BDD5AA29D8C4ED2DD5CBB0340F978CBF4DACA815235D10A'}
)
$temp=Join-Path ([IO.Path]::GetTempPath()) ('OctoAggro-DLLs-'+[guid]::NewGuid().ToString('N'))
$changes=@();$created=@();$backup=$null;$loaderWritten=$false
try{
  New-Item -ItemType Directory -Path $temp | Out-Null
  [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  foreach($dep in $dependencies){
    $dst=Join-Path $game $dep.Name
    if(Test-Path -LiteralPath $dst -PathType Leaf){Write-Host ('Beholder eksisterende '+$dep.Name);continue}
    $src=Join-Path $temp $dep.Name
    Write-Host ('Laster ned '+$dep.Name+' fra offisiell GitHub-utgave...')
    Invoke-WebRequest -UseBasicParsing -Uri $dep.URL -OutFile $src
    if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -ne $dep.Hash){throw ('Nedlastingskontroll feilet: '+$dep.Name)}
    $changes+=@{Source=$src;Target=$dst;Hash=$dep.Hash}
  }
  $native=Join-Path $addon 'native\OctoAggroNative.dll'
  if(-not (Test-Path -LiteralPath $native -PathType Leaf)){
    $src=Join-Path $repo 'native\OctoAggroNative.dll'
    if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -ne '878A87CC292CDAF0532EAF3B195294A104B4B759A9082053D404D0C62EF234E8'){throw 'Kontroll av OctoAggroNative.dll feilet.'}
    $toc=Get-Content -LiteralPath (Join-Path $addon 'OctoAggro.toc') -Raw
    if($toc -notmatch '(?m)^## Version:\s*0\.8\.1(?:-test)?\s*$'){throw 'Denne DLL-pakken krever OctoAggro 0.8.1. Oppdater tillegget gjennom launcheren.'}
    $changes+=@{Source=$src;Target=$native;Hash='878A87CC292CDAF0532EAF3B195294A104B4B759A9082053D404D0C62EF234E8'}
  }
  # Normalize only our three entries; preserve all other loader entries and comments.
  $entries=@('ClassicAPI.dll','UnitXP_SP3.dll','Interface/AddOns/OctoAggro/native/OctoAggroNative.dll')
  $before=[IO.File]::ReadAllText($loader)
  $lines=@($before -split '\r?\n' | Where-Object {
    $normalized=$_.Trim().Replace('\','/')
    $entries -notcontains $normalized
  })
  $content=($entries+($lines | Where-Object {$_ -ne ''})) -join "`r`n"
  $content+="`r`n"
  if($changes.Count -eq 0 -and $before -ceq $content){Write-Host 'DLL-filene og lastingen er allerede satt opp.';return}
  $backup=Join-Path $game ('AddonBackups\OctoAggro-DLLs-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
  New-Item -ItemType Directory -Path $backup -Force | Out-Null
  Copy-Item -LiteralPath $loader -Destination (Join-Path $backup 'dlls.txt')
  if((Get-FileHash -LiteralPath $loader).Hash -ne (Get-FileHash -LiteralPath (Join-Path $backup 'dlls.txt')).Hash){throw 'Sikkerhetskopien kunne ikke bekreftes.'}
  $created=@()
  foreach($change in $changes){
    if(Test-Path -LiteralPath $change.Target){throw ('En annen prosess opprettet filen: '+$change.Target)}
    New-Item -ItemType Directory -Path (Split-Path -Parent $change.Target) -Force | Out-Null
    $created+=@{Path=$change.Target;Hash=$change.Hash}
    Copy-Item -LiteralPath $change.Source -Destination $change.Target
    if((Get-FileHash -LiteralPath $change.Target).Hash -ne $change.Hash){throw 'Kopieringskontroll feilet.'}
  }
  $loaderWritten=$true
  [IO.File]::WriteAllText($loader,$content,[Text.UTF8Encoding]::new($false))
  if([IO.File]::ReadAllText($loader) -cne $content){throw 'Kontroll av dlls.txt feilet.'}
  $manifest=[pscustomobject]@{GamePath=$game;BackupLoaderHash=(Get-FileHash -LiteralPath (Join-Path $backup 'dlls.txt')).Hash;LoaderHash=(Get-FileHash -LiteralPath $loader).Hash;CreatedFiles=@($created);LiveWorldTested=$false}
  $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backup 'dll-install.json') -Encoding utf8
  Write-Host ('Ferdig. Sikkerhetskopi: '+$backup)
  Write-Host 'Start spillet med VanillaFixes.exe (eller launcheren hvis den bruker VanillaFixes). Skriv /oa status i spillet.'
  $manifest
}catch{
  if($loaderWritten -and $backup){Copy-Item -LiteralPath (Join-Path $backup 'dlls.txt') -Destination $loader -Force}
  foreach($file in $created){if(Test-Path -LiteralPath $file.Path -PathType Leaf){Remove-Item -LiteralPath $file.Path -Force}}
  throw
}finally{
  # This unique temporary directory is owned by this invocation.
  if(Test-Path -LiteralPath $temp){
    $resolved=[IO.Path]::GetFullPath($temp)
    if(-not $resolved.StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase) -or (Split-Path -Leaf $resolved) -notmatch '^OctoAggro-DLLs-[a-f0-9]{32}$'){throw 'Uventet midlertidig mappe.'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}
