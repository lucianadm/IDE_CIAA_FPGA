param([Parameter(ValueFromRemainingArguments=$true)][string[]]$IdeArguments)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$tools=Join-Path $root 'tools'
$downloads=Join-Path $root 'downloads'
New-Item -ItemType Directory -Path $tools,$downloads -Force | Out-Null

if(-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -eq 'ARM64'){
 throw 'Esta version admite Windows x64 sobre procesadores Intel/AMD.'
}

$suiteVersion='2026-10-28'
$suiteArchive="oss-cad-suite-windows-x64-20261028.tgz"
$suiteUrl="https://github.com/YosysHQ/oss-cad-suite-build/releases/download/$suiteVersion/$suiteArchive"
$suiteSha='EB97AF9E5D0B195E570C6A7EE3D29C005BCC60E343D48CB713EF414E4A39E766'
$suiteLocal=Join-Path $tools 'oss-cad-suite'
$suite=$suiteLocal

function Test-Suite([string]$Path){
 try {
  return @('yosys','nextpnr-ice40','icepack','iceprog','iverilog','vvp') | ForEach-Object {
   Test-Path -LiteralPath (Join-Path $Path "bin\$_.exe") -PathType Leaf -ErrorAction Stop
  } | Where-Object {!$_} | Measure-Object | Select-Object -ExpandProperty Count | ForEach-Object {$_ -eq 0}
 } catch {return $false}
}
function Download-Checked([string]$Url,[string]$Destination,[string]$Sha256){
 if(Test-Path -LiteralPath $Destination -PathType Leaf){
  if((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -eq $Sha256){return}
  Move-Item -LiteralPath $Destination -Destination ($Destination+'.hash_incorrecto_'+(Get-Date -Format yyyyMMdd_HHmmssfff))
 }
 Write-Host "Descargando $(Split-Path $Destination -Leaf)..." -ForegroundColor Cyan
 $curl=Get-Command curl.exe -ErrorAction SilentlyContinue
 if($curl){& $curl.Source -L --fail --retry 3 --output $Destination $Url; if($LASTEXITCODE -ne 0){throw 'La descarga fallo.'}}
 else {[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Destination}
 if((Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash -ne $Sha256){throw "SHA-256 incorrecto: $Destination"}
}

if(!(Test-Suite $suiteLocal)){
 $apioSuite=Join-Path $env:USERPROFILE '.apio\packages\oss-cad-suite'
 if(Test-Suite $apioSuite){
  $suite=$apioSuite
  Write-Host "Se reutilizara OSS CAD Suite de Apio: $suite" -ForegroundColor Green
 } else {
  $archive=Join-Path $downloads $suiteArchive
  Download-Checked $suiteUrl $archive $suiteSha
  $stage=Join-Path $tools ('extraer_oss_'+[guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $stage | Out-Null
  Write-Host 'Extrayendo OSS CAD Suite. Puede tardar varios minutos...' -ForegroundColor Cyan
  & tar.exe -xzf $archive -C $stage
  if($LASTEXITCODE -ne 0){throw 'No se pudo extraer OSS CAD Suite.'}
  $found=@(Get-ChildItem -LiteralPath $stage -Directory -Recurse -Filter 'oss-cad-suite' | Where-Object {Test-Suite $_.FullName} | Select-Object -First 1)
  if(!$found.Count){throw 'El archivo descargado no contiene una OSS CAD Suite valida.'}
  if(Test-Path -LiteralPath $suiteLocal){Move-Item -LiteralPath $suiteLocal -Destination ($suiteLocal+'.anterior_'+(Get-Date -Format yyyyMMdd_HHmmssfff))}
  Move-Item -LiteralPath $found[0].FullName -Destination $suiteLocal
  $suite=$suiteLocal
 }
}

$ghdlVersion='6.0.0'
$ghdlDir=Join-Path $tools "ghdl-$ghdlVersion"
$ghdlExe=Join-Path $ghdlDir 'bin\ghdl.exe'
if(!(Test-Path -LiteralPath $ghdlExe -PathType Leaf)){
 $name="ghdl-mcode-$ghdlVersion-mingw64.zip"
 $archive=Join-Path $downloads $name
 Download-Checked "https://github.com/ghdl/ghdl/releases/download/v$ghdlVersion/$name" $archive 'C1562B2A4767E34D33159B536B5E36A8A38EBDB6E7672AA9969A4F4AC2CADFFE'
 $stage=Join-Path $tools ('extraer_ghdl_'+[guid]::NewGuid().ToString('N'))
 Expand-Archive -LiteralPath $archive -DestinationPath $stage
 if(!(Test-Path -LiteralPath (Join-Path $stage 'bin\ghdl.exe'))){throw 'El paquete de GHDL tiene una estructura inesperada.'}
 Move-Item -LiteralPath $stage -Destination $ghdlDir
}

$env:PATH=(Join-Path $suite 'bin')+';'+(Join-Path $suite 'lib')+';'+(Join-Path $ghdlDir 'bin')+';'+$env:PATH
$env:CIAA_TOOLCHAIN=$suite
$env:PYTHONUTF8='1'
$python=$null
foreach($name in @('py.exe','python.exe','python3.exe')){
 $cmd=Get-Command $name -ErrorAction SilentlyContinue
 if($cmd){
  try {& $cmd.Source --version *> $null; if($LASTEXITCODE -eq 0){$python=$cmd.Source;break}} catch {}
 }
}
if(!$python){
 $python=@(Get-ChildItem -LiteralPath $suite -Recurse -File -Filter 'python3.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
 if($python.Count){$python=$python[0]}
}
if(!$python){throw 'No se encontro Python y la suite descargada tampoco lo contiene.'}

Write-Host "Herramientas listas: $suite" -ForegroundColor Green
if(!$IdeArguments.Count){
 $selection=& (Join-Path $PSScriptRoot 'seleccionar_diseno.ps1') -Root $root
 if(!$selection -or !$selection.ProjectFile){throw 'No se pudo preparar el proyecto VHDL seleccionado.'}
 $arguments=@('build',$selection.ProjectFile)
 $arguments+=if($selection.Simulate){'--simulate'}else{'--no-simulate'}
 $arguments+=if($selection.View){'--view'}else{'--no-view'}
 if($selection.Program){$arguments+='--program'}
 & $python (Join-Path $root 'src\ciaa_fpga.py') @arguments
} else {
 & $python (Join-Path $root 'src\ciaa_fpga.py') @IdeArguments
}
exit $LASTEXITCODE
