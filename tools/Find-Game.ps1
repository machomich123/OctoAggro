function Find-OctoAggroGamePath {
  param([string]$ConfigDirectory=(Join-Path $env:APPDATA 'octo-launcher'))
  function Get-ValidCandidates($Paths){
    $found=@()
    foreach($candidate in $Paths){
      if(-not $candidate){continue}
      try{
        $path=[IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables([string]$candidate))
        if((Test-Path -LiteralPath (Join-Path $path 'WoW.exe') -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $path 'Interface\AddOns\OctoAggro\OctoAggro.toc') -PathType Leaf)){
          $found+=(Resolve-Path -LiteralPath $path).Path.TrimEnd('\')
        }
      }catch{continue}
    }
    @($found | Sort-Object -Unique)
  }
  # Read only the launcher's game location; never its account/login files.
  $configured=@()
  foreach($name in @('install.json','settings.json')){
    $file=Join-Path $ConfigDirectory $name
    if(Test-Path -LiteralPath $file -PathType Leaf){
      try{$json=Get-Content -LiteralPath $file -Raw | ConvertFrom-Json;$configured+=$json.clientDir}catch{}
    }
  }
  $found=@(Get-ValidCandidates $configured)
  if($found.Count -gt 1){throw 'Launcheren peker til flere OctoAggro-installasjoner. Ingen filer endret.'}
  if($found.Count -eq 1){return $found[0]}
  # Fallback for installations without saved launcher settings.
  $common=@()
  foreach($drive in Get-PSDrive -PSProvider FileSystem){
    if($drive.Root -notmatch '^[A-Za-z]:\\$'){continue}
    foreach($relative in @('Games\Octowow','Octowow','World of Warcraft','Games\World of Warcraft')){$common+=Join-Path $drive.Root $relative}
  }
  foreach($base in @($env:ProgramFiles,${env:ProgramFiles(x86)},$env:USERPROFILE)){
    if($base){foreach($relative in @('Octowow','Games\Octowow')){$common+=Join-Path $base $relative}}
  }
  $found=@(Get-ValidCandidates $common)
  if($found.Count -gt 1){throw 'Fant flere spillmapper med OctoAggro. Apne OctoLauncher og sett riktig spillmappe, sa kjor installeren igjen. Ingen filer endret.'}
  if($found.Count -eq 1){return $found[0]}
  throw 'Fant ikke OctoAggro-spillmappen automatisk. Apne OctoLauncher og kontroller at spillet og OctoAggro er installert, sa kjor denne filen igjen.'
}
