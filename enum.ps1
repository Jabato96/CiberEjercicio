Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   INFORME DE AUDITORÍA DE PRIVILEGIOS - CONFIDENCIAL" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)"
Write-Host "Host: $env:COMPUTERNAME"
Write-Host "Usuario: $env:USERDOMAIN\$env:USERNAME"
Write-Host "----------------------------------------------------------"

# 1. ANALIZAR EL ARCHIVO VULNERABLE
$targetScript = "C:\Mantenimiento\check_update.ps1"

Write-Host "[+] Verificando Integridad de Archivos de Mantenimiento..." -ForegroundColor White

if (Test-Path $targetScript) {
    $acl = Get-Acl $targetScript
    # Buscamos permisos críticos
    $riskyAccess = $acl.Access | Where-Object { 
        ($_.IdentityReference -match "Users|Everyone|Authenticated Users") -and 
        ($_.FileSystemRights -match "Write|Modify|FullControl")
    }

    if ($riskyAccess) {
        Write-Host "[VULNERABILIDAD DETECTADA: PERMISOS DÉBILES EN SCRIPT]" -ForegroundColor Red -BackgroundColor Black
        Write-Host "Ruta: $targetScript" -ForegroundColor Yellow
        Write-Host "Evidencia de ACL (Permisos):" -ForegroundColor White
        $riskyAccess | Select-Object IdentityReference, FileSystemRights, AccessControlType | Format-Table | Out-String | Write-Host
        
        Write-Host "[!] Riesgo: Un atacante puede modificar este script para ejecutar código como SYSTEM." -ForegroundColor Red
    }
} else {
    Write-Host "[-] El archivo $targetScript no fue encontrado en la ruta prevista." -ForegroundColor Gray
}

# 2. LOCALIZAR LA TAREA (MÉTODO POR REGISTRO - MÁS FIABLE)
Write-Host "`n[+] Analizando Configuración de Tareas Programadas (vía Registro)..." -ForegroundColor White

$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks"
try {
    $taskFound = $false
    Get-ChildItem $registryPath | ForEach-Object {
        $path = $_.Name
        $values = Get-ItemProperty "Registry::$path"
        if ($values.Path -match "Mantenimiento") {
            $taskFound = $true
            Write-Host "[!] TAREA IDENTIFICADA: $($values.Path)" -ForegroundColor Red
            Write-Host "    ID de Tarea: $($_.PSChildName)" -ForegroundColor Yellow
        }
    }
    if (-not $taskFound) { Write-Host "[-] No se encontró la definición de la tarea en el registro." -ForegroundColor Gray }
} catch {
    Write-Host "[-] Acceso limitado al registro de tareas." -ForegroundColor Gray
}

Write-Host "`n----------------------------------------------------------"
Write-Host "FIN DEL REPORTE" -ForegroundColor Cyan