# verificar.ps1
# Mide cuanto escribe atieclxx.exe (servicio "AMD External Events Utility") durante unos segundos.
# Solo lee contadores de Windows: no cambia nada.
# Uso (PowerShell como administrador):
#   powershell -ExecutionPolicy Bypass -File .\verificar.ps1
#   powershell -ExecutionPolicy Bypass -File .\verificar.ps1 -Segundos 60

param([int]$Segundos = 30)

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host 'Ejecuta PowerShell como administrador: sin permisos no se pueden leer los contadores del servicio.' -ForegroundColor Yellow
    return
}

function Get-EscriturasAtieclxx {
    $p = @(Get-CimInstance Win32_Process -Filter "Name='atieclxx.exe'")
    if ($p.Count -eq 0) { return $null }
    return [double](($p | Measure-Object WriteTransferCount -Sum).Sum)
}

$a = Get-EscriturasAtieclxx
if ($null -eq $a) {
    Write-Host 'atieclxx.exe no esta en ejecucion: no hay escrituras que medir.' -ForegroundColor Green
    return
}

Write-Host ("Midiendo durante {0} segundos..." -f $Segundos)
Start-Sleep -Seconds $Segundos
$b = Get-EscriturasAtieclxx

if ($null -eq $b -or $b -lt $a) {
    Write-Host 'El proceso se reinicio durante la medicion. Vuelve a ejecutar el script.' -ForegroundColor Yellow
    return
}

$kbs = ($b - $a) / $Segundos / 1KB
Write-Host ("atieclxx.exe escribe {0:N0} KB/s (~{1:N1} GB por dia con el PC encendido 24 h)" -f $kbs, ($kbs * 86400 / 1MB))

if ($kbs -ge 150) {
    Write-Host 'AFECTADO: escritura continua. Ver aplicar.ps1.' -ForegroundColor Red
} else {
    Write-Host 'OK: sin escritura continua.' -ForegroundColor Green
}
