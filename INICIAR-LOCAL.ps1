# Gold Host 13.52 - servidor local para probar desde la PS4
# Uso: clic derecho > Ejecutar con PowerShell
#      o: powershell -ExecutionPolicy Bypass -File .\INICIAR-LOCAL.ps1 [puerto]

param([int]$Port = 8080)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$mime = @{
    ".html"      = "text/html; charset=utf-8"
    ".htm"       = "text/html; charset=utf-8"
    ".js"        = "application/javascript; charset=utf-8"
    ".css"       = "text/css; charset=utf-8"
    ".json"      = "application/json; charset=utf-8"
    ".appcache"  = "text/cache-manifest; charset=utf-8"
    ".webmanifest" = "application/manifest+json; charset=utf-8"
    ".png"       = "image/png"
    ".jpg"       = "image/jpeg"
    ".svg"       = "image/svg+xml"
    ".ico"       = "image/x-icon"
    ".bin"       = "application/octet-stream"
}

$ip = $null
try {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
        Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
        Select-Object -First 1).IPAddress
} catch { }
if (-not $ip) { $ip = "127.0.0.1" }

$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
$listener.Start()

Write-Host ""
Write-Host "  HOST PS4 13.52 - servidor local" -ForegroundColor Yellow
Write-Host "  Carpeta: $root"
Write-Host ""
Write-Host "  En el navegador de la PS4 abre:" -ForegroundColor Cyan
Write-Host "      http://${ip}:$Port/" -ForegroundColor Green
Write-Host ""
Write-Host "  (misma red Wi-Fi/LAN; permite el puerto $Port en el Firewall si no carga)"
Write-Host "  Ctrl+C para parar."
Write-Host ""

function Send-Response($stream, [string]$status, [string]$ctype, [byte[]]$body) {
    $head = "HTTP/1.1 $status`r`n" +
            "Content-Type: $ctype`r`n" +
            "Content-Length: $($body.Length)`r`n" +
            "Cache-Control: no-cache, no-store, must-revalidate`r`n" +
            "Pragma: no-cache`r`n" +
            "Connection: close`r`n`r`n"
    $hb = [System.Text.Encoding]::ASCII.GetBytes($head)
    $stream.Write($hb, 0, $hb.Length)
    if ($body.Length -gt 0) { $stream.Write($body, 0, $body.Length) }
    $stream.Flush()
}

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $client.ReceiveTimeout = 8000
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)

            $requestLine = $reader.ReadLine()
            if ([string]::IsNullOrWhiteSpace($requestLine)) { continue }
            # Consumir cabeceras hasta la línea en blanco.
            while ($true) {
                $line = $reader.ReadLine()
                if ($null -eq $line -or $line -eq "") { break }
            }

            $parts = $requestLine.Split(" ")
            $method = $parts[0]
            $rawPath = if ($parts.Length -ge 2) { $parts[1] } else { "/" }
            $path = ($rawPath -split "\?")[0]
            $path = [System.Uri]::UnescapeDataString($path)
            if ($path -eq "/" -or $path -eq "") { $path = "/index.html" }

            $rel = $path.TrimStart("/").Replace("/", [System.IO.Path]::DirectorySeparatorChar)
            $file = [System.IO.Path]::GetFullPath((Join-Path $root $rel))
            $rootFull = [System.IO.Path]::GetFullPath($root)

            if (-not $file.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                $b = [System.Text.Encoding]::UTF8.GetBytes("403")
                Send-Response $stream "403 Forbidden" "text/plain; charset=utf-8" $b
            }
            elseif (Test-Path -LiteralPath $file -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
                $ctype = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
                $bytes = [System.IO.File]::ReadAllBytes($file)
                if ($method -eq "HEAD") { $bytes = [byte[]]@() }
                Send-Response $stream "200 OK" $ctype $bytes
                Write-Host ("  {0} {1}" -f $method, $path) -ForegroundColor DarkGray
            }
            else {
                $b = [System.Text.Encoding]::UTF8.GetBytes("404 - no existe: $path")
                Send-Response $stream "404 Not Found" "text/plain; charset=utf-8" $b
                Write-Host ("  {0} {1} -> 404" -f $method, $path) -ForegroundColor DarkYellow
            }
        }
        catch {
            # Conexión cortada por el navegador: no es un error grave.
        }
        finally {
            try { $client.Close() } catch { }
        }
    }
}
finally {
    $listener.Stop()
}
