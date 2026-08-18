# Publishes the voiceover server on a temporary internet address, behind a
# password. Safe to run any time. Nothing here needs administrator rights.
#
# The address is temporary: it changes every time this is started. The password
# does not change.

$ErrorActionPreference = "SilentlyContinue"

$Container = "kokoro"
$Image     = "ghcr.io/remsky/kokoro-fastapi-cpu:v0.2.2"
$Gate      = "voiceover-gate"
$GateImage = "caddy:2.10-alpine"
$Net       = "voiceover-net"
$GatePort  = 8890
$User      = "editors"

$Exe       = Join-Path $PSScriptRoot "tunnel\cloudflared.exe"
$Log       = Join-Path $PSScriptRoot "tunnel\tunnel-error.log"
$LogOut    = Join-Path $PSScriptRoot "tunnel\tunnel-output.log"
$PwFile    = Join-Path $PSScriptRoot "VOICEOVER-PASSWORD.txt"
$StudioSrc = Join-Path $PSScriptRoot "web\studio.html"
$Caddyfile = Join-Path $PSScriptRoot "gate\Caddyfile"

function Say  ($m) { Write-Host $m -ForegroundColor Cyan }
function Warn ($m) { Write-Host $m -ForegroundColor Yellow }
function Fail ($m) {
    Write-Host ""
    Write-Host "  $m" -ForegroundColor Red
    Write-Host ""
    Read-Host "  Press Enter to close"
    exit 1
}

Clear-Host
Say ""
Say "  Voiceover link for editors"
Say "  --------------------------"
Say ""

# ---------------------------------------------------------------- 1. Docker
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
    if (-not $up) { Fail "Docker did not start. Restart the computer and try again." }
}
Say "  Docker is running."

# ------------------------------------------------------- 2. Voiceover server
$exists = docker ps -a --filter "name=$Container" --format "{{.Names}}"
if ($exists -ne $Container) {
    Say "  Voiceover server missing. Creating it..."
    docker run -d --name $Container --restart always -p 8880:8880 $Image | Out-Null
} else {
    $running = docker ps --filter "name=$Container" --format "{{.Names}}"
    if ($running -ne $Container) {
        Say "  Starting the voiceover server..."
        docker start $Container | Out-Null
    }
}

Say "  Waiting for the voiceover server to be ready..."
$ready = $false
for ($i = 0; $i -lt 36; $i++) {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8880/health" -UseBasicParsing -TimeoutSec 5
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
    Start-Sleep -Seconds 5
}
if (-not $ready) { Fail "The voiceover server did not become ready. Open TROUBLESHOOTING.md in this folder." }
Say "  Voiceover server is ready."

# ------------------------------------------------------------ 3. Studio page
if (Test-Path $StudioSrc) {
    docker cp $StudioSrc ($Container + ":/app/web/studio.html") | Out-Null
}

# ------------------------------------------------------- 4. Password gate
if (-not (Test-Path $Caddyfile)) { Fail "gate\Caddyfile is missing from this folder. Without it there is no password, so nothing was published." }

docker network create $Net 2>$null | Out-Null
docker network connect $Net $Container 2>$null | Out-Null

$gateRunning = docker ps --filter "name=$Gate" --format "{{.Names}}"
if ($gateRunning -ne $Gate) {
    Say "  Starting the password gate..."
    docker rm -f $Gate 2>$null | Out-Null
    docker run -d --name $Gate --restart always --network $Net -p ("127.0.0.1:" + $GatePort + ":80") -v ($Caddyfile + ":/etc/caddy/Caddyfile:ro") $GateImage | Out-Null
    Start-Sleep -Seconds 3
}

$gateRunning = docker ps --filter "name=$Gate" --format "{{.Names}}"
if ($gateRunning -ne $Gate) { Fail "The password gate did not start, so nothing was published. Run: docker logs $Gate" }
Say "  Password gate is running."

# --------------------------------------- 5. PROVE the password is really on
# This is the safety catch. If the gate ever answers without a password we must
# not put it on the internet, because the voiceover server has no login of its own.
$protected = $false
try {
    Invoke-WebRequest -Uri ("http://127.0.0.1:" + $GatePort + "/web/studio.html") -UseBasicParsing -TimeoutSec 10 | Out-Null
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 401) { $protected = $true }
}
if (-not $protected) {
    Fail "SAFETY STOP. The password gate answered without asking for a password, so nothing was published. Check gate\Caddyfile still has its basic_auth block, then run: docker restart $Gate"
}
Say "  Password check passed. The gate refuses anyone without the password."

# ------------------------------------------------------------- 6. The tunnel
if (-not (Test-Path $Exe)) { Fail "tunnel\cloudflared.exe is missing from this folder. Nothing was published." }

Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
if (Test-Path $Log)    { Remove-Item $Log -Force }
if (Test-Path $LogOut) { Remove-Item $LogOut -Force }

Say "  Opening the internet link..."
$proc = Start-Process -FilePath $Exe `
    -ArgumentList "tunnel", "--no-autoupdate", "--url", ("http://127.0.0.1:" + $GatePort) `
    -RedirectStandardError $Log -RedirectStandardOutput $LogOut `
    -NoNewWindow -PassThru

$url = $null
for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $Log) {
        $text = Get-Content $Log -Raw
        $m = [regex]::Match($text, "https://[a-z0-9-]+\.trycloudflare\.com")
        if ($m.Success) { $url = $m.Value; break }
    }
}

if (-not $url) {
    if ($proc -and -not $proc.HasExited) { $proc.Kill() }
    Fail "Could not get an internet link. Check this computer has internet, then try again. Details are in tunnel\tunnel-error.log"
}

$pw = ""
if (Test-Path $PwFile) {
    $line = (Get-Content $PwFile | Where-Object { $_ -match "^Password:" } | Select-Object -First 1)
    if ($line) { $pw = $line -replace "^Password:\s*", "" }
}

try { Set-Clipboard -Value $url } catch { }

Clear-Host
Write-Host ""
Write-Host "  ===============================================================" -ForegroundColor Green
Write-Host "   THE VOICEOVER TOOL IS NOW ON THE INTERNET" -ForegroundColor Green
Write-Host "  ===============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "   Send the editors this address:" -ForegroundColor White
Write-Host ""
Write-Host "     $url" -ForegroundColor Yellow
Write-Host ""
Write-Host "   (already copied to your clipboard, just paste it)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "   They will be asked for a login. Give them:" -ForegroundColor White
Write-Host ""
Write-Host "     Username:  $User" -ForegroundColor Yellow
if ($pw) { Write-Host "     Password:  $pw" -ForegroundColor Yellow }
else     { Write-Host "     Password:  see VOICEOVER-PASSWORD.txt in this folder" -ForegroundColor Yellow }
Write-Host ""
Write-Host "  ---------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "   KEEP THIS WINDOW OPEN." -ForegroundColor Red
Write-Host "   Closing it switches the internet link off." -ForegroundColor Red
Write-Host ""
Write-Host "   The address above is temporary. Next time you run this you get" -ForegroundColor DarkGray
Write-Host "   a different one, and you must send the new one out. The" -ForegroundColor DarkGray
Write-Host "   username and password stay the same." -ForegroundColor DarkGray
Write-Host ""
Write-Host "   To stop sharing: close this window, or press Ctrl and C." -ForegroundColor DarkGray
Write-Host ""

$proc.WaitForExit()

Write-Host ""
Warn "  The internet link is now off. Editors can no longer reach it."
Write-Host ""
Read-Host "  Press Enter to close"
