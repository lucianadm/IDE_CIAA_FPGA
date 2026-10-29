param(
 [Parameter(Mandatory=$true)][string]$ReportFile,
 [Parameter(Mandatory=$true)][string]$BitstreamFile,
 [switch]$WillProgram,
 [switch]$ValidateOnly
)

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if(!(Test-Path -LiteralPath $ReportFile -PathType Leaf)){throw "No existe el informe: $ReportFile"}
if(!(Test-Path -LiteralPath $BitstreamFile -PathType Leaf)){throw "No existe el bitstream: $BitstreamFile"}

$form=New-Object System.Windows.Forms.Form
$form.Text='Resultados de la sintesis'
$form.StartPosition='CenterScreen'
$form.Size=New-Object System.Drawing.Size(820,650)
$form.MinimumSize=New-Object System.Drawing.Size(700,520)
$form.TopMost=$true

$title=New-Object System.Windows.Forms.Label
$title.Text='Sintesis, ruteo y temporizacion finalizados correctamente.'
$title.Font=New-Object System.Drawing.Font('Segoe UI Semibold',11)
$title.AutoSize=$true
$title.Location=New-Object System.Drawing.Point(18,16)
$form.Controls.Add($title)

$saved=New-Object System.Windows.Forms.Label
$saved.Text="Los resultados se guardaron junto al archivo del top level:`r`nInforme: $ReportFile`r`nBitstream: $BitstreamFile"
$saved.AutoEllipsis=$true
$saved.Size=New-Object System.Drawing.Size(770,65)
$saved.Location=New-Object System.Drawing.Point(18,48)
$saved.Anchor='Top, Left, Right'
$form.Controls.Add($saved)

$report=New-Object System.Windows.Forms.TextBox
$report.Multiline=$true
$report.ReadOnly=$true
$report.ScrollBars='Both'
$report.WordWrap=$false
$report.Font=New-Object System.Drawing.Font('Consolas',10)
$report.Text=[IO.File]::ReadAllText($ReportFile)
$report.Location=New-Object System.Drawing.Point(18,122)
$report.Size=New-Object System.Drawing.Size(770,425)
$report.Anchor='Top, Bottom, Left, Right'
$form.Controls.Add($report)

$button=New-Object System.Windows.Forms.Button
$button.Text=if($WillProgram){'Continuar y programar'}else{'Cerrar'}
$button.Size=New-Object System.Drawing.Size(190,38)
$button.Location=New-Object System.Drawing.Point(598,560)
$button.Anchor='Bottom, Right'
$button.Add_Click({$form.Close()})
$form.AcceptButton=$button
$form.Controls.Add($button)

if($ValidateOnly){
 Write-Output 'VALIDATION_OK'
 exit 0
}

[void]$form.ShowDialog()

