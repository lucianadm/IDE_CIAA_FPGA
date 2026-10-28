param([Parameter(Mandatory=$true)][string]$Root)

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms

function Find-Entity([string[]]$Files,[string]$Preferred){
 $entities=New-Object System.Collections.Generic.List[string]
 foreach($file in $Files){
  foreach($match in [regex]::Matches([IO.File]::ReadAllText($file),'(?im)^\s*entity\s+([a-z][a-z0-9_]*)\s+is\b')){
   [void]$entities.Add($match.Groups[1].Value)
  }
 }
 $same=@($entities | Where-Object {$_ -ieq $Preferred} | Select-Object -First 1)
 if($same.Count){return $same[0]}
 if($entities.Count){return $entities[$entities.Count-1]}
 return $Preferred
}

function Ask-YesNo([string]$Question,[string]$Title){
 $answer=[System.Windows.Forms.MessageBox]::Show(
  $Question,$Title,
  [System.Windows.Forms.MessageBoxButtons]::YesNo,
  [System.Windows.Forms.MessageBoxIcon]::Question
 )
 return $answer -eq [System.Windows.Forms.DialogResult]::Yes
}

$dialog=New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory=$Root
$dialog.Filter='Fuentes VHDL (*.vhd;*.vhdl)|*.vhd;*.vhdl'
$dialog.Multiselect=$true
$dialog.Title='Seleccione TODOS los archivos VHDL sintetizables del diseno'
if($dialog.ShowDialog() -ne 'OK'){throw 'Seleccion de archivos VHDL cancelada.'}
$designFiles=@($dialog.FileNames)
if(!$designFiles.Count){throw 'No se seleccionaron archivos VHDL.'}

$doSimulation=Ask-YesNo '¿Quiere simular el diseno antes de sintetizar?' 'Simulacion VHDL'
$testFiles=@()
$tbTop=$null
$stopTime='10ms'
$openViewer=$false

if($doSimulation){
 $dialog.FileName=''
 $dialog.Multiselect=$true
 $dialog.InitialDirectory=Split-Path $designFiles[0]
 $dialog.Title='Seleccione el testbench VHDL y todos sus archivos auxiliares'
 if($dialog.ShowDialog() -ne 'OK'){throw 'Seleccion del testbench cancelada. La simulacion necesita un testbench.'}
 $testFiles=@($dialog.FileNames)
 if(!$testFiles.Count){throw 'No se selecciono ningun archivo de testbench.'}
 $tbTop=Find-Entity $testFiles ([IO.Path]::GetFileNameWithoutExtension($testFiles[0]))
 $value=Read-Host "Entidad principal del testbench (ENTER = $tbTop)"
 if($value){$tbTop=$value.Trim()}
 $value=Read-Host "Duracion maxima de simulacion (ENTER = $stopTime; ejemplos: 500ns, 20us, 10ms)"
 if($value){$stopTime=$value.Trim()}
 if($stopTime -notmatch '^\d+(\.\d+)?(fs|ps|ns|us|ms|sec|min|hr)$'){
  throw 'Tiempo de simulacion invalido. Use, por ejemplo, 500ns, 20us o 10ms.'
 }
 $openViewer=Ask-YesNo '¿Quiere abrir el diagrama temporal al terminar la simulacion?' 'Diagrama temporal'
}

$top=Find-Entity $designFiles ([IO.Path]::GetFileNameWithoutExtension($designFiles[0]))
$value=Read-Host "Entidad principal para sintetizar (ENTER = $top)"
if($value){$top=$value.Trim()}
if($top -notmatch '^[A-Za-z][A-Za-z0-9_]*$'){throw 'Nombre de entidad superior invalido.'}
if($tbTop -and $tbTop -notmatch '^[A-Za-z][A-Za-z0-9_]*$'){throw 'Nombre de entidad del testbench invalido.'}

$dialog.Multiselect=$false
$dialog.FileName=''
$dialog.InitialDirectory=Split-Path $designFiles[0]
$dialog.Filter='Asignacion de pines (*.pcf)|*.pcf'
$dialog.Title='Seleccione el archivo de asignacion de pines PCF'
if($dialog.ShowDialog() -ne 'OK'){throw 'Seleccion del archivo PCF cancelada.'}
$pcf=$dialog.FileName

$doProgram=Ask-YesNo '¿Quiere programar la FPGA despues de sintetizar?' 'Programar FPGA'
$stamp=Get-Date -Format 'yyyyMMdd_HHmmssfff'
$projectDir=Join-Path $Root "build\proyecto_interactivo_$stamp"
New-Item -ItemType Directory -Path $projectDir -Force | Out-Null
$projectFile=Join-Path $projectDir 'project.json'

$project=[ordered]@{
 name=$top
 language='vhdl'
 top=$top
 sources=@($designFiles)
 pcf=$pcf
 device=[ordered]@{nextpnr_device='hx8k';package='tq144:4k';frequency_mhz=12}
 programmer=[ordered]@{vid='0403';pid='6010';index=0;interface='A'}
 simulation=[ordered]@{
  enabled=$doSimulation
  sources=@($testFiles)
  top=$tbTop
  stop_time=$stopTime
  open_viewer=$openViewer
 }
}
$project | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $projectFile -Encoding UTF8

[pscustomobject]@{
 ProjectFile=$projectFile
 Simulate=$doSimulation
 View=$openViewer
 Program=$doProgram
}
