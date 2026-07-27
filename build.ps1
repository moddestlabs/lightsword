<#
.SYNOPSIS
    Script to build and serve the LightSword web app on Windows using PowerShell.

.DESCRIPTION
    Stops existing web server processes, builds the Flutter web application,
    generates the offline service worker, and starts a fresh Python HTTP web server
    on a random port (or specified port).

.PARAMETER Clean
    Cleans previous build before building.

.PARAMETER Port
    Port number to listen on. If omitted or 0, a random free port will be automatically selected.

.EXAMPLE
    .\build.ps1
    .\build.ps1 -Clean
    .\build.ps1 -Port 8080
    .\build.ps1 -Clean -Port 8080
#>

[CmdletBinding()]
param (
    [switch]$Clean,
    [int]$Port = 0
)

$ErrorActionPreference = "Stop"

# Stop existing Python HTTP servers
Write-Host "[*] Checking for existing servers..."
try {
    $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        ($_.Name -like "python*" -or $_.Name -eq "py.exe") -and $_.CommandLine -like "*http.server*"
    }
    if ($procs) {
        Write-Host "    Stopping existing Python HTTP servers..."
        foreach ($proc in $procs) {
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 1
    } else {
        Write-Host "    No existing servers found."
    }
} catch {
    Write-Host "    Note: Unable to query process list or no matching server found."
}

# Determine Port: if <= 0, assign a random available port
if ($Port -le 0) {
    $ip = [System.Net.IPAddress]::Loopback
    $listener = New-Object System.Net.Sockets.TcpListener -ArgumentList @($ip, 0)
    $listener.Start()
    $Port = $listener.LocalEndpoint.Port
    $listener.Stop()
    Write-Host "[*] Selected random available port: $Port"
} else {
    Write-Host "[*] Using specified port: $Port"
}

$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Get-Location
}

$bibleAppDir = Join-Path $scriptDir "bible_app"
if (-not (Test-Path $bibleAppDir)) {
    Write-Error "Could not find bible_app directory at: $bibleAppDir"
    exit 1
}

Set-Location $bibleAppDir

Write-Host "[*] Building LightSword web app..."

# Clean if requested
if ($Clean) {
    Write-Host "[*] Cleaning previous build..."
    flutter clean
}

# Build the web version
Write-Host "[*] Building for web..."
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed during 'flutter build web'"
    exit 1
}

# Generate offline service worker
Write-Host "[*] Generating offline service worker..."
$buildWebDir = Join-Path $bibleAppDir "build\web"
$swScriptPs1 = Join-Path $scriptDir "scripts\generate_pwa_service_worker.ps1"
$swScriptSh = Join-Path $scriptDir "scripts\generate_pwa_service_worker.sh"

if (Test-Path $swScriptPs1) {
    & $swScriptPs1 -BuildDir $buildWebDir
} elseif (Get-Command bash -ErrorAction SilentlyContinue) {
    bash $swScriptSh "build/web"
} else {
    Write-Warning "Service worker generator script not found!"
}

# Check if build was successful
if (-not (Test-Path $buildWebDir)) {
    Write-Error "Build failed - build/web directory not found"
    exit 1
}

# Change to build output directory
Set-Location $buildWebDir

Write-Host "[+] Build complete!"
Write-Host ""
Write-Host "    Starting fresh web server on http://localhost:$Port"
Write-Host "    Open the URL above in your browser to see the latest changes"
Write-Host "    Press Ctrl+C to stop the server"
Write-Host ""

# Detect available Python launcher/executable
$pythonCmd = "python"
if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    if (Get-Command "py" -ErrorAction SilentlyContinue) {
        $pythonCmd = "py"
    } elseif (Get-Command "python3" -ErrorAction SilentlyContinue) {
        $pythonCmd = "python3"
    }
}

& $pythonCmd -m http.server $Port
