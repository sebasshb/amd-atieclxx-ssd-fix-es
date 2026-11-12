# AMD atieclxx SSD fix (manual, en español)

Arreglo **manual y transparente** para el bug de los drivers AMD Radeon en el que el servicio **"AMD External Events Utility"** (`atieclxx.exe`) escribe en el disco sin parar, a unos **54–56 GB por día**, **sin desactivar el servicio**. Así siguen funcionando **VRR/FreeSync** y los atajos de Adrenalin.

> ⚠️ Arreglo **no oficial**, sin relación con AMD. Úsalo bajo tu propia responsabilidad (ver [LICENSE](LICENSE)).
> AMD confirmó el bug y lo corregirá en **Adrenalin 26.11.1**. Este arreglo es temporal hasta entonces.

## El problema

Con los drivers afectados, `atieclxx.exe` **se copia a sí mismo cada segundo** a:

```
C:\Windows\System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe
```

Cada copia pesa unos 660 KB, así que el PC escribe **unos 660 KB/s de forma continua**. Según AMD, el problema viene de una interacción entre ese servicio y el filtro PCIe de Microsoft, relacionada con Resizable BAR / Smart Access Memory.

## ¿Estoy afectado?

En **PowerShell como administrador**:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verificar.ps1
```

Con **600 KB/s o más**, estás afectado. Con unos pocos KB/s, no.

También puedes verlo en `resmon` → pestaña **Disco** → ordenar por **Escritura (B/s)**: `atieclxx.exe` aparece escribiendo todo el tiempo.

## El arreglo

La solución consiste en **negarle al usuario SYSTEM el permiso de sobrescribir o borrar esa única copia**. La autocopia falla al instante y deja de escribir, pero el servicio sigue corriendo.

- No modifica el driver ni el archivo original.
- No crea tareas programadas ni deja procesos corriendo.
- No descarga nada ni se conecta a internet.
- Se revierte con un solo comando.

### Con los scripts

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\aplicar.ps1     # aplica el bloqueo y mide
powershell -ExecutionPolicy Bypass -File .\scripts\verificar.ps1   # vuelve a medir cuando quieras
powershell -ExecutionPolicy Bypass -File .\scripts\revertir.ps1    # quita el bloqueo
```

Si Windows bloquea los scripts descargados, desbloquéalos primero:

```powershell
Get-ChildItem .\scripts\*.ps1 | Unblock-File
```

### A mano, sin scripts

```powershell
$f = "$env:SystemRoot\System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe"
icacls $f                                            # ver permisos actuales
icacls $f /deny "*S-1-5-18:(WD,AD,WEA,WA,DE)"        # aplicar el bloqueo
icacls $f /remove:d "*S-1-5-18"                      # quitar el bloqueo
```

Los permisos que se niegan son `WD` (escribir datos), `AD` (añadir datos), `WEA` (escribir atributos extendidos), `WA` (escribir atributos) y `DE` (borrar). Solo se le niegan a `S-1-5-18` (SYSTEM) y solo sobre esa copia.

## Cuando salga el driver oficial

1. Ejecuta **`revertir.ps1`** **antes** de instalar el driver nuevo, por ejemplo Adrenalin 26.11.1.
2. Instala el driver.
3. Ejecuta **`verificar.ps1`**. Si marca casi 0 KB/s, AMD lo arregló y no hay que hacer nada más.

## Alternativas y por qué no las uso

| Alternativa | Inconveniente |
|---|---|
| Desactivar el servicio "AMD External Events Utility" | Puede romper VRR/FreeSync, los atajos y la detección de monitores |
| Desactivar Resizable BAR / SAM en la BIOS | Pierdes rendimiento en juegos |
| Herramientas de terceros con tareas programadas como SYSTEM | Agregan un proceso con privilegios máximos que no hace falta |

## Resultado probado

En un PC con Ryzen 7 5800X3D, RX 9060 XT y Windows 11, la escritura de `atieclxx.exe` bajó de **662 KB/s** (unos 54,5 GB al día) a **0 KB/s**, con VRR funcionando.

## Créditos y fuentes

- La investigación técnica (la autocopia cada segundo y el bloqueo por ACL) viene de [necanditool/Radeon-atieclxx-SSD-Fix](https://github.com/necanditool/Radeon-atieclxx-SSD-Fix), licencia MIT. Este repo es una versión mínima y manual, en español.
- [Hardware Busters: AMD confirma el bug, arreglo en Adrenalin 26.11.1](https://hwbusters.com/news/amd-confirms-radeon-driver-bug-that-keeps-ssds-writing-at-idle-fix-due-in-adrenalin-26-11-1/)
- [TechPowerUp: AMD Confirms Excessive SSD Writes in Radeon Drivers](https://www.techpowerup.com/354605/amd-confirms-excessive-ssd-writes-in-radeon-drivers-fix-coming-with-adrenalin-26-11-1)
- [WindowsForum: How to check atieclxx.exe](https://windowsforum.com/news/amd-radeon-ssd-write-bug-how-to-check-atieclxx-exe-on-windows-10-and-11.450605/)

AMD, Radeon, FreeSync y Smart Access Memory son marcas de Advanced Micro Devices, Inc. Este proyecto no está afiliado a AMD.

---

## English summary

A minimal, manual workaround for the AMD Radeon driver bug where `atieclxx.exe` (AMD External Events Utility) copies itself every second to `C:\Windows\System32\config\systemprofile\AppData\Local\AMD\atieclxx.exe` (~660 KB/s, ~55 GB/day). The fix adds a deny entry for SYSTEM on that single file (`icacls <file> /deny "*S-1-5-18:(WD,AD,WEA,WA,DE)"`). The self-copy fails, the writes stop, and the service keeps running, so VRR/FreeSync and hotkeys keep working. No scheduled tasks, no downloads, no driver changes. Revert with `icacls <file> /remove:d "*S-1-5-18"` before installing Adrenalin 26.11.1, which AMD says fixes the bug. Based on research by necanditool (MIT). Not affiliated with AMD.
