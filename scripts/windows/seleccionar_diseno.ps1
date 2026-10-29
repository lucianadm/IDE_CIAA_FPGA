param(
 [Parameter(Mandatory=$true)][string]$Root,
 [Parameter(Mandatory=$true)][string]$Python
)

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Find-Top([string[]]$Files,[string]$Preferred,[string]$Language){
 $names=New-Object System.Collections.Generic.List[string]
 $pattern=if($Language -eq 'vhdl'){'(?im)^\s*entity\s+([a-z][a-z0-9_]*)\s+is\b'}else{'(?im)^\s*module\s+([a-z_][a-z0-9_$]*)\b'}
 foreach($file in $Files){
  foreach($match in [regex]::Matches([IO.File]::ReadAllText($file),$pattern)){
   [void]$names.Add($match.Groups[1].Value)
  }
 }
 $same=@($names | Where-Object {$_ -ieq $Preferred} | Select-Object -First 1)
 if($same.Count){return $same[0]}
 if($names.Count){return $names[$names.Count-1]}
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

function Select-Language {
 $form=New-Object System.Windows.Forms.Form
 $form.Text='Lenguaje del diseno'
 $form.StartPosition='CenterScreen'
 $form.FormBorderStyle=[System.Windows.Forms.FormBorderStyle]::FixedDialog
 $form.ClientSize=New-Object System.Drawing.Size(430,155)
 $form.MaximizeBox=$false
 $form.MinimizeBox=$false
 $form.ShowInTaskbar=$false
 $form.TopMost=$true

 $label=New-Object System.Windows.Forms.Label
 $label.Text='Seleccione el lenguaje de los archivos que va a cargar:'
 $label.AutoSize=$true
 $label.Location=New-Object System.Drawing.Point(22,25)
 $form.Controls.Add($label)

 $vhdl=New-Object System.Windows.Forms.Button
 $vhdl.Text='VHDL'
 $vhdl.Size=New-Object System.Drawing.Size(115,36)
 $vhdl.Location=New-Object System.Drawing.Point(22,82)
 $vhdl.Add_Click({$form.Tag='vhdl';$form.DialogResult=[System.Windows.Forms.DialogResult]::OK;$form.Close()})
 $form.Controls.Add($vhdl)

 $verilog=New-Object System.Windows.Forms.Button
 $verilog.Text='Verilog'
 $verilog.Size=New-Object System.Drawing.Size(115,36)
 $verilog.Location=New-Object System.Drawing.Point(157,82)
 $verilog.Add_Click({$form.Tag='verilog';$form.DialogResult=[System.Windows.Forms.DialogResult]::OK;$form.Close()})
 $form.Controls.Add($verilog)

 $cancel=New-Object System.Windows.Forms.Button
 $cancel.Text='Cancelar'
 $cancel.Size=New-Object System.Drawing.Size(115,36)
 $cancel.Location=New-Object System.Drawing.Point(292,82)
 $cancel.Add_Click({$form.DialogResult=[System.Windows.Forms.DialogResult]::Cancel;$form.Close()})
 $form.Controls.Add($cancel)

 $form.AcceptButton=$vhdl
 $form.CancelButton=$cancel
 $result=$form.ShowDialog()
 if($result -ne [System.Windows.Forms.DialogResult]::OK -or !$form.Tag){throw 'Operacion cancelada.'}
 return [string]$form.Tag
}

function Test-Programmer {
 $iceprog=Get-Command iceprog -ErrorAction SilentlyContinue
 if(!$iceprog){throw 'No se encontro iceprog aunque el entorno de herramientas fue preparado.'}
 $selectors=@(
  @('-d','i:0x0403:0x6010','-I','A','-t'),
  @('-I','A','-t'),
  @('-d','i:0x0403:0x6010:0','-I','A','-t')
 )
 foreach($arguments in $selectors){
  $startInfo=New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName=$iceprog.Source
  $startInfo.Arguments=$arguments -join ' '
  $startInfo.UseShellExecute=$false
  $startInfo.CreateNoWindow=$true
  $startInfo.RedirectStandardOutput=$true
  $startInfo.RedirectStandardError=$true
  $process=New-Object System.Diagnostics.Process
  $process.StartInfo=$startInfo
  if(!$process.Start()){continue}
  $stdout=$process.StandardOutput.ReadToEndAsync()
  $stderr=$process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  [void]$stdout.Result
  [void]$stderr.Result
  if($process.ExitCode -eq 0){return $true}
 }
 return $false
}

function Show-UsbDialog {
 $form=New-Object System.Windows.Forms.Form
 $form.Text='Preparar conexion USB de la FPGA'
 $form.StartPosition='CenterScreen'
 $form.FormBorderStyle=[System.Windows.Forms.FormBorderStyle]::FixedDialog
 $form.ClientSize=New-Object System.Drawing.Size(600,245)
 $form.MaximizeBox=$false
 $form.MinimizeBox=$false
 $form.ShowInTaskbar=$false
 $form.TopMost=$true

 $label=New-Object System.Windows.Forms.Label
 $label.Text="No se puede acceder al programador FT2232H.`r`n`r`nCon la placa conectada, abra Zadig y seleccione solamente:`r`nDual RS232-HS (Interface 0) - USB ID 0403:6010 - interfaz 00`r`nCambie esa interfaz a WinUSB. No modifique Interface 1.`r`nLuego desconecte y vuelva a conectar la placa."
 $label.AutoSize=$false
 $label.Size=New-Object System.Drawing.Size(555,145)
 $label.Location=New-Object System.Drawing.Point(22,20)
 $form.Controls.Add($label)

 $zadig=New-Object System.Windows.Forms.Button
 $zadig.Text='Abrir Zadig'
 $zadig.Size=New-Object System.Drawing.Size(150,38)
 $zadig.Location=New-Object System.Drawing.Point(42,184)
 $zadig.Add_Click({$form.Tag='zadig';$form.DialogResult=[System.Windows.Forms.DialogResult]::OK;$form.Close()})
 $form.Controls.Add($zadig)

 $retry=New-Object System.Windows.Forms.Button
 $retry.Text='Reintentar'
 $retry.Size=New-Object System.Drawing.Size(150,38)
 $retry.Location=New-Object System.Drawing.Point(225,184)
 $retry.Add_Click({$form.Tag='retry';$form.DialogResult=[System.Windows.Forms.DialogResult]::OK;$form.Close()})
 $form.Controls.Add($retry)

 $cancel=New-Object System.Windows.Forms.Button
 $cancel.Text='Cancelar'
 $cancel.Size=New-Object System.Drawing.Size(150,38)
 $cancel.Location=New-Object System.Drawing.Point(408,184)
 $cancel.Add_Click({$form.Tag='cancel';$form.DialogResult=[System.Windows.Forms.DialogResult]::Cancel;$form.Close()})
 $form.Controls.Add($cancel)
 $form.CancelButton=$cancel

 [void]$form.ShowDialog()
 return [string]$form.Tag
}

function Open-FtdiDriverTool {
 $apio=Get-Command apio -ErrorAction SilentlyContinue
 if($apio){
  Write-Host "`nSe abrira el preparador FTDI de Apio. Siga las indicaciones de Zadig." -ForegroundColor Yellow
  & $apio.Source drivers install ftdi
  if($LASTEXITCODE -ne 0){throw "El preparador FTDI de Apio fallo (codigo $LASTEXITCODE)."}
  return
 }

 $apioHome=Join-Path $env:USERPROFILE '.apio'
 $zadig=@(Get-ChildItem -LiteralPath $apioHome -Recurse -File -Filter 'zadig*.exe' -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1)
 if(!$zadig.Count){
  throw 'No se encontro Zadig. Instale Apio o ejecute nuevamente el instalador de preparacion de la EDU-CIAA-FPGA.'
 }
 try {
  Start-Process -FilePath $zadig[0].FullName -Verb RunAs -Wait
 } catch {
  throw 'No se pudo abrir Zadig con permisos de administrador.'
 }
}

function Confirm-ProgrammerReady {
 while(!(Test-Programmer)){
  $answer=Show-UsbDialog
  if($answer -eq 'cancel' -or !$answer){throw 'Programacion cancelada porque el controlador USB no esta preparado.'}
  if($answer -eq 'zadig'){
   Open-FtdiDriverTool
   [void][System.Windows.Forms.MessageBox]::Show(
    "Desconecte y vuelva a conectar la EDU-CIAA-FPGA.`r`n`r`nPulse Aceptar solamente cuando la placa este nuevamente conectada.",
    'Reconectar la placa',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
   )
  }
 }
 [void][System.Windows.Forms.MessageBox]::Show(
  'La memoria Flash fue identificada correctamente. Puede continuar con la sintesis.',
  'Programador USB listo',
  [System.Windows.Forms.MessageBoxButtons]::OK,
  [System.Windows.Forms.MessageBoxIcon]::Information
 )
}

[void][System.Windows.Forms.MessageBox]::Show(
 "Este asistente permite compilar un diseno VHDL o Verilog para la EDU-CIAA-FPGA.`n`nPrimero seleccione el lenguaje y despues TODOS los archivos fuente del diseno.",
 'IDE CIAA FPGA',
 [System.Windows.Forms.MessageBoxButtons]::OK,
 [System.Windows.Forms.MessageBoxIcon]::Information
)

$language=Select-Language
$languageName=if($language -eq 'vhdl'){'VHDL'}else{'Verilog/SystemVerilog'}
$filter=if($language -eq 'vhdl'){'Fuentes VHDL (*.vhd;*.vhdl)|*.vhd;*.vhdl'}else{'Fuentes Verilog (*.v;*.sv)|*.v;*.sv'}

$dialog=New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory=$Root
$dialog.Filter=$filter
$dialog.Multiselect=$true
$dialog.Title="Seleccione TODOS los archivos $languageName sintetizables del diseno"
if($dialog.ShowDialog() -ne 'OK'){throw "Seleccion de archivos $languageName cancelada."}
$designFiles=@($dialog.FileNames)
if(!$designFiles.Count){throw "No se seleccionaron archivos $languageName."}

$top=Find-Top $designFiles ([IO.Path]::GetFileNameWithoutExtension($designFiles[0])) $language
$value=Read-Host "Top level del diseno para sintetizar (ENTER = $top)"
if($value){$top=$value.Trim()}
if($top -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$'){throw 'Nombre de top level invalido.'}

$doSimulation=Ask-YesNo 'Quiere ejecutar la simulacion funcional RTL antes de sintetizar?' "Simulacion funcional $languageName"
$testFiles=@()
$simulationTop=$null
$stopTime='10ms'
$waveFile=$null
$projectDir=Join-Path $Root ('build\proyecto_interactivo_'+(Get-Date -Format 'yyyyMMdd_HHmmssfff'))
New-Item -ItemType Directory -Path $projectDir -Force | Out-Null

if($doSimulation){
 $dialog.FileName=''
 $dialog.Multiselect=$true
 $dialog.InitialDirectory=Split-Path $designFiles[0]
 $dialog.Title="Seleccione el testbench $languageName y todos sus archivos auxiliares"
 if($dialog.ShowDialog() -ne 'OK'){throw 'Seleccion del testbench cancelada. La simulacion necesita un testbench.'}
 $testFiles=@($dialog.FileNames)
 if(!$testFiles.Count){throw 'No se selecciono ningun archivo de testbench.'}
 $tbTop=Find-Top $testFiles ([IO.Path]::GetFileNameWithoutExtension($testFiles[0])) $language
 $value=Read-Host "Top level del testbench (ENTER = $tbTop)"
 if($value){$tbTop=$value.Trim()}
 if($tbTop -notmatch '^[A-Za-z_][A-Za-z0-9_$]*$'){throw 'Nombre de top level del testbench invalido.'}

 if($language -eq 'vhdl'){
  $simulationTop=$tbTop
  $value=Read-Host "Duracion maxima de simulacion (ENTER = $stopTime; ejemplos: 500ns, 20us, 10ms)"
  if($value){$stopTime=$value.Trim()}
  if($stopTime -notmatch '^\d+(\.\d+)?(fs|ps|ns|us|ms|sec|min|hr)$'){
   throw 'Tiempo de simulacion invalido. Use, por ejemplo, 500ns, 20us o 10ms.'
  }
 } else {
  $simulationTop='ciaa_testbench_automatico'
  $waveFile='simulacion.vcd'
  $wrapper=Join-Path $projectDir 'ciaa_testbench_automatico.sv'
  $wrapperText="module ciaa_testbench_automatico;`r`n  $tbTop testbench();`r`n  initial begin`r`n    `$dumpfile(`"simulacion.vcd`");`r`n    `$dumpvars(0, testbench);`r`n  end`r`nendmodule`r`n"
  [IO.File]::WriteAllText($wrapper,$wrapperText,[Text.UTF8Encoding]::new($false))
  $testFiles+=@($wrapper)
 }

 $simulationProject=Join-Path $projectDir 'project_simulation.json'
 $simulationConfig=[ordered]@{
  name=($top+'_simulacion_funcional')
  language=$language
  top=$top
  sources=@($designFiles)
  include_dirs=@($designFiles | ForEach-Object {Split-Path $_} | Select-Object -Unique)
  simulation=[ordered]@{
   enabled=$true
   sources=@($testFiles)
   top=$simulationTop
   stop_time=$stopTime
   wave_file=$waveFile
   open_viewer=$true
  }
 }
 $simulationConfig | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $simulationProject -Encoding UTF8
 Write-Host "`nSe ejecutara ahora la simulacion funcional RTL. Todavia no se necesita el archivo PCF." -ForegroundColor Cyan
 & $Python (Join-Path $Root 'src\ciaa_fpga.py') simulate $simulationProject --view 2>&1 | ForEach-Object {Write-Host $_}
 $simulationExit=$LASTEXITCODE
 if($simulationExit -ne 0){throw "La simulacion funcional fallo (codigo $simulationExit). No se solicitara el PCF."}
 Write-Host 'Simulacion funcional finalizada. A continuacion comienza la preparacion de la sintesis.' -ForegroundColor Green
}

$doProgram=Ask-YesNo 'Quiere programar la FPGA despues de sintetizar?' 'Programar FPGA'
if($doProgram){Confirm-ProgrammerReady}

$dialog.Multiselect=$false
$dialog.FileName=''
$dialog.InitialDirectory=Split-Path $designFiles[0]
$dialog.Filter='Asignacion de pines (*.pcf)|*.pcf'
$dialog.Title='Seleccione el archivo de asignacion de pines PCF'
if($dialog.ShowDialog() -ne 'OK'){throw 'Seleccion del archivo PCF cancelada.'}
$pcf=$dialog.FileName

$projectFile=Join-Path $projectDir 'project.json'
$includeDirs=@($designFiles | ForEach-Object {Split-Path $_} | Select-Object -Unique)
$project=[ordered]@{
 name=$top
 language=$language
 top=$top
 sources=@($designFiles)
 include_dirs=$includeDirs
 pcf=$pcf
 device=[ordered]@{nextpnr_device='hx8k';package='tq144:4k';frequency_mhz=12}
 programmer=[ordered]@{vid='0403';pid='6010';index=0;interface='A'}
 simulation=[ordered]@{
  enabled=$doSimulation
  sources=@($testFiles)
  top=$simulationTop
  stop_time=$stopTime
  wave_file=$waveFile
  open_viewer=$doSimulation
 }
}
$project | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $projectFile -Encoding UTF8

[pscustomobject]@{
 ProjectFile=$projectFile
 Program=$doProgram
}
