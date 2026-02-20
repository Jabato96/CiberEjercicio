$ErrorActionPreference = "SilentlyContinue"
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    INFORME DE ENUMERACIÓN DE TAREAS Y PRIVILEGIOS" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)"
Write-Host "Host: $env:COMPUTERNAME | Usuario: $env:USERDOMAIN\$env:USERNAME"
Write-Host "----------------------------------------------------------"

$targetScript = "C:\Program Files\Servicio Tecnico\Updateschk.ps1"

Write-Host "[*] Escaneando tareas del sistema..." -ForegroundColor White

# Buscamos directamente en el listado detallado de schtasks
$taskData = schtasks /query /v /fo LIST

Write-Host "[+] Análisis de configuraciones inseguras en curso...`n"

# 1. ANALIZAR EL OBJETIVO ESPECÍFICO (FORZADO)
if (Test-Path $targetScript) {
    Write-Host "[!] VERIFICANDO RUTA CRÍTICA: $targetScript" -ForegroundColor White
    $acl = Get-Acl $targetScript
    $riskyAccess = $acl.Access | Where-Object { 
        ($_.IdentityReference -match "Users|Everyone|Authenticated Users|Usuarios") -and 
        ($_.FileSystemRights -match "Write|Modify|FullControl")
    }

    if ($riskyAccess) {
        Write-Host "    [HALLAZGO CRÍTICO]: Permisos de ESCRITURA detectados." -ForegroundColor Red -BackgroundColor Black
        Write-Host "    El usuario actual puede modificar el script de servicio." -ForegroundColor Yellow
        $riskyAccess | Select-Object IdentityReference, FileSystemRights | Format-Table | Out-String | Write-Host
        
        # Intentar localizar qué tarea lo corre para completar la evidencia
        $relatedTask = $taskData | Select-String -Pattern "Updateschk.ps1" -Context 5,1
        if ($relatedTask) {
            Write-Host "    Contexto de la Tarea encontrada:" -ForegroundColor Cyan
            $relatedTask | Write-Host
        }
    }
} else {
    Write-Host "[-] No se detectó el directorio de Servicio Tecnico o el script." -ForegroundColor Gray
}

Write-Host "`n[*] Análisis de seguridad completado." -ForegroundColor Cyan
