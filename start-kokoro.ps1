# Starts the Kokoro voiceover server and opens the web page.
# Safe to run any time. If it is already running, it just opens the page.

$ErrorActionPreference = "SilentlyContinue"
$Container = "kokoro"
$Image     = "ghcr.io/remsky/kokoro-fastapi-cpu:v0.2.2"
$Url       = "http://localhost:8880/web/studio.html"
$StudioSrc = Join-Path $PSScriptRoot "web\studio.html"

function Say($msg) { Write-Host $msg -ForegroundColor Cyan }

Clear-Host
Say ""
Say "  Calilio Voiceover Server"
Say "  ------------------------"
Say ""

# 1. Make sure Docker Desktop is running
docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Say "  Starting Docker Desktop... (this can take up to 2 minutes)"
    $dd = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dd) { Start-Process -FilePath $dd }

    $up = $false
    for ($i = 0; $i -lt 60; $i++) {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $up = $true; break }
        Start-Sleep -Seconds 5
    }
    if (-not $up) {
        Write-Host ""
        Write-Host "  Docker did not start. Restart the computer and try again." -ForegroundColor Red
        Write-Host ""
        Read-Host "  Press Enter to close"
        exit 1
    }
}
Say "  Docker is running."

# 2. Make sure the container exists and is started
$exists = docker ps -a --filter "name=$Container" --format "{{.Names}}"
if ($exists -ne $Container) {
    Say "  Container missing. Creating it..."
    docker run -d --name $Container --restart always -p 8880:8880 $Image | Out-Null
} else {
    $running = docker ps --filter "name=$Container" --format "{{.Names}}"
    if ($running -ne $Container) {
        Say "  Starting the voiceover server..."
        docker start $Container | Out-Null
    } else {
        Say "  Voiceover server already running."
    }
}

# 3. Wait until it answers
Say "  Waiting for it to be ready..."
$ready = $false
for ($i = 0; $i -lt 36; $i++) {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8880/health" -UseBasicParsing -TimeoutSec 5
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
    Start-Sleep -Seconds 5
}

if (-not $ready) {
    Write-Host ""
    Write-Host "  It did not become ready. Open TROUBLESHOOTING.md, in this folder:" -ForegroundColor Red
    Write-Host "  Desktop\Internal Apps\kokoro-voiceover-server\" -ForegroundColor Red
    Write-Host ""
    Read-Host "  Press Enter to close"
    exit 1
}

# 4. Put the Voiceover Studio page inside the container.
# Done on every start so it comes back automatically if the container is ever recreated.
if (Test-Path $StudioSrc) {
    $studioDest = $Container + ":/app/web/studio.html"
    docker cp $StudioSrc $studioDest | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Say "  Voiceover Studio page installed."
    } else {
        Write-Host "  Could not install the Studio page. The classic player still works at http://localhost:8880/web/" -ForegroundColor Yellow
        $Url = "http://localhost:8880/web/"
    }
} else {
    Write-Host "  web\studio.html is missing from this folder. Opening the classic player instead." -ForegroundColor Yellow
    $Url = "http://localhost:8880/web/"
}

# 5. Open the page
Say "  Ready. Opening the voiceover page..."
Start-Process $Url
Start-Sleep -Seconds 2
