Write-Host "[*] Iniciando Auditoria y exportando a ficheros..." -ForegroundColor Cyan


$resDir = "C:\Users\Public\Logs_Auditoria"
if (!(Test-Path $resDir)) { New-Item -ItemType Directory -Path $resDir | Out-Null }

# 1. ENUMERACIÓN DE USUARIOS -> usuarios.txt
Write-Host "[!] Exportando usuarios del dominio..." -ForegroundColor Yellow
try {
    $searcher = [adsisearcher]'(&(objectCategory=person)(objectClass=user))'
    $searcher.PageSize = 1000
    $searcher.FindAll() | ForEach-Object { $_.Properties.adspath } | Out-File -FilePath "$resDir\usuarios.txt"
    Write-Host "[+] usuarios.txt generado."
} catch { }

# 2. BARRIDO DE RED -> redes.txt
Write-Host "[!] Escaneando red (Puerto 445)..." -ForegroundColor Yellow
$prefix = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch "127.0.0.1" })[0].IPAddress.SubString(0,10)
1..50 | ForEach-Object {
    $t = "$prefix.$_"
    if (Test-Connection -ComputerName $t -Count 1 -Quiet) {
        $s = New-Object Net.Sockets.TcpClient
        $c = $s.BeginConnect($t, 445, $null, $null)
        if ($c.AsyncWaitHandle.WaitOne(100, $false)) {
            "Host con SMB activo: $t" | Out-File -FilePath "$resDir\redes.txt" -Append
        }
        $s.Close()
    }
}
Write-Host "[+] redes.txt generado."

# 3. RECURSOS COMPARTIDOS -> recursos.txt
Write-Host "[!] Listando recursos compartidos..." -ForegroundColor Yellow
net view /all /domain | Out-File -FilePath "$resDir\recursos.txt"
Write-Host "[+] recursos.txt generado."

# 4. GRUPOS Y SPNs -> privilegios.txt
Write-Host "[!] Consultando grupos y SPNs..." -ForegroundColor Yellow
"--- GRUPOS ---" | Out-File -FilePath "$resDir\privilegios.txt"
net group "Domain Admins" /domain >> "$resDir\privilegios.txt"
"--- SPNs ---" >> "$resDir\privilegios.txt"
setspn -Q */* >> "$resDir\privilegios.txt"
Write-Host "[+] privilegios.txt generado."

Write-Host "`n[*] Finalizado. Resultados en $resDir" -ForegroundColor Cyan
