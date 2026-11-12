# revertir.ps1
# Quita el bloqueo aplicado por aplicar.ps1 y deja los permisos como estaban.
# Ejecutalo ANTES de instalar un driver nuevo de AMD (por ejemplo Adrenalin 26.11.1).
# Uso (PowerShell como administrador):
#   powershell -ExecutionPolicy Bypass -File .\revertir.ps1

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host 'Ejecuta PowerShell como administrador.' -ForegroundColor Yellow
    return
}

$f = Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe'
if (-not (Test-Path -LiteralPath $f)) {
    Write-Host "No existe $f : no hay nada que revertir." -ForegroundColor Green
    return
}

& icacls $f /remove:d '*S-1-5-18'
Write-Host ''
Write-Host 'Permisos actuales:'
& icacls $f
Write-Host ''
Write-Host 'Bloqueo quitado. Tras instalar el driver nuevo, ejecuta verificar.ps1 para comprobar si AMD lo arreglo.' -ForegroundColor Green
