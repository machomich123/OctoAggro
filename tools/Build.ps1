$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$vswhere='C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
if(-not (Test-Path -LiteralPath $vswhere)){$vswhere='C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe'}
$vs=& $vswhere -latest -products '*' -property installationPath
if(-not $vs){throw 'Visual Studio C++ tools are required to rebuild the bridge.'}
& (Join-Path $vs 'Common7\Tools\Launch-VsDevShell.ps1') -Arch x86 -HostArch amd64 -SkipAutomaticLocation
Push-Location (Join-Path $repo 'native')
try{
  & cl.exe /nologo /EHsc /O2 /MT /std:c++17 /LD OctoAggroNative.cpp vendor\minhook\src\hook.c vendor\minhook\src\buffer.c vendor\minhook\src\trampoline.c vendor\minhook\src\hde\hde32.c /link /OUT:OctoAggroNative.dll bcrypt.lib
  if($LASTEXITCODE -ne 0){throw 'Native build failed.'}
}finally{Pop-Location}
