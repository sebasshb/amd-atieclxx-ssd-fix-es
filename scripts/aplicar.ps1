# aplicar.ps1
# Bloquea la autocopia de atieclxx.exe negando al usuario SYSTEM el permiso de escribir o borrar
# UNA sola copia del archivo. El servicio sigue funcionando (VRR/FreeSync, hotkeys).
# No crea tareas programadas ni deja nada ejecutandose.
# Uso (PowerShell como administrador):
#   powershell -ExecutionPolicy Bypass -File .\aplicar.ps1

$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host 'Ejecuta PowerShell como administrador.' -ForegroundColor Yellow
    return
}

$f = Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe'
if (-not (Test-Path -LiteralPath $f)) {
    Write-Host "No existe $f" -ForegroundColor Yellow
    Write-Host 'Tu driver no hace la autocopia en esta ruta. No se cambio nada.'
    return
}

Write-Host 'Permisos actuales:'
& icacls $f
Write-Host ''

Write-Host 'Aplicando bloqueo (solo SYSTEM, solo este archivo)...'
& icacls $f /deny '*S-1-5-18:(WD,AD,WEA,WA,DE)'
Write-Host ''

$sid = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-18')
$bloqueado = $false
foreach ($r in (Get-Acl -LiteralPath $f).Access) {
    if ($r.AccessControlType -eq 'Deny' -and -not $r.IsInherited) {
        try { if ($r.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]) -eq $sid) { $bloqueado = $true } } catch {}
    }
}
if (-not $bloqueado) {
    Write-Host 'No se pudo aplicar el bloqueo.' -ForegroundColor Red
    return
}
Write-Host 'Bloqueo aplicado.' -ForegroundColor Green
Write-Host ''

$verificar = Join-Path $PSScriptRoot 'verificar.ps1'
if (Test-Path -LiteralPath $verificar) {
    Write-Host 'Comprobando que dejo de escribir:'
    & $verificar -Segundos 15
}
Write-Host ''
Write-Host 'IMPORTANTE: antes de instalar un driver nuevo de AMD, ejecuta revertir.ps1.' -ForegroundColor Yellow
