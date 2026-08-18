# Brings the whole Voiceover Studio up on its own, with no window and no
# clicking. Meant to be launched at login by autostart-voiceover.vbs, but it is
# safe to run by hand at any time.
#
# What it does, in order:
#   1. Makes sure Docker Desktop is running.
#   2. Makes sure the kokoro and voiceover-gate containers are up.
#   3. Refreshes the Studio page inside the container.
#   4. Checks the password gate actually answers 401 before publishing.
#   5. Starts a Cloudflare quick tunnel and writes the new address to
#      CURRENT-LINK.txt (in this folder and on the Desktop).
#   6. Posts the address to Slack, if slack-webhook.txt exists.
#
# Nothing here needs administrator rights.

$ErrorActionPreference = "SilentlyContinue"

$Root      = $PSScriptRoot
$Exe       = Join-Path $Root "tunnel\cloudflared.exe"
$ErrLog    = Join-Path $Root "tunnel\tunnel-error.log"
$OutLog    = Join-Path $Root "tunnel\tunnel-output.log"
$RunLog    = Join-Path $Root "tunnel\autostart.log"
$StudioSrc = Join-Path $Root "web\studio.html"
$LinkFile  = Join-Path $Root "CURRENT-LINK.txt"
$DeskLink  = Join-Path ([Environment]::GetFolderPath("Desktop")) "VOICEOVER LINK - open me.txt"
$HookFile  = Join-Path $Root "slack-webhook.txt"
$PwFile    = Join-Path $Root "VOICEOVER-PASSWORD.txt"

$Container = "kokoro"
$Gate      = "voiceover-gate"
$GateUrl   = "http://127.0.0.1:8890/web/studio.html"

function Note ($m) {
    $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $RunLog -Value "$stamp  $m" -Encoding utf8
}

Note "=== autostart begin ==="

# ------------------------------------------------------------- 1. Docker up
docker info 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Note "Docker not running. Starting Docker Desktop."
    $dd = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dd) { Start-Process -FilePath $dd -WindowStyle Minimized }
    $up = $false
    for ($i = 0; $i -lt 90; $i++) {
        Start-Sleep -Seconds 5
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $up = $true; break }
    }
    if (-not $up) { Note "FAILED: Docker did not start within 7 minutes."; exit 1 }
}
Note "Docker is running."

# --------------------------------------------------------- 2. Containers up
foreach ($c in @($Container, $Gate)) {
    $running = docker ps --filter "name=^$c$" --format "{{.Names}}"
    if ($running -ne $c) {
        Note "Container $c is not running. Starting it."
        docker start $c | Out-Null
    }
}

# The engine loads its model on boot, so wait for it rather than guessing.
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        $r = Invoke-WebRequest -Uri "http://localhost:8880/health" -UseBasicParsing -TimeoutSec 5
        if ($r.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
    Start-Sleep -Seconds 5
}
if (-not $ready) { Note "FAILED: voice engine never became healthy."; exit 1 }
Note "Voice engine is healthy."

# ------------------------------------------------------ 3. Refresh the page
if (Test-Path $StudioSrc) {
    docker cp $StudioSrc "${Container}:/app/web/studio.html" | Out-Null
    Note "Studio page copied into the container."
}

# --------------------------------------------- 4. Prove the gate is locked
# If this ever stops returning 401 the password is not being asked for, and
# publishing the address would put an open server on the internet.
$code = 0
try   { $null = Invoke-WebRequest -Uri $GateUrl -UseBasicParsing -TimeoutSec 15 }
catch { $code = $_.Exception.Response.StatusCode.value__ }
if ($code -ne 401) {
    Note "ABORTED: password gate answered $code instead of 401. Not publishing."
    exit 1
}
Note "Password gate is locked (401)."

# --------------------------------------------------------- 5. Start tunnel
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item $ErrLog, $OutLog -Force -ErrorAction SilentlyContinue

if (-not (Test-Path $Exe)) { Note "FAILED: tunnel\cloudflared.exe is missing."; exit 1 }

Start-Process -FilePath $Exe `
    -ArgumentList "tunnel", "--no-autoupdate", "--url", "http://127.0.0.1:8890" `
    -WindowStyle Hidden -RedirectStandardError $ErrLog -RedirectStandardOutput $OutLog | Out-Null

$url = $null
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 2
    if (Test-Path $ErrLog) {
        $m = [regex]::Match((Get-Content $ErrLog -Raw), 'https://[a-z0-9\-]+\.trycloudflare\.com')
        if ($m.Success) { $url = $m.Value; break }
    }
}
if (-not $url) { Note "FAILED: no tunnel address appeared within 80 seconds."; exit 1 }

$studio = "$url/web/studio.html"
Note "Tunnel is up: $studio"

# Confirm the public address really works before telling anyone about it.
# The tunnel takes a few seconds after the address appears before it starts
# serving, so retry instead of trusting one early attempt.
$pubCode = $null
for ($i = 0; $i -lt 10; $i++) {
    try   { $null = Invoke-WebRequest -Uri $studio -UseBasicParsing -TimeoutSec 20; $pubCode = 200 }
    catch { $pubCode = $_.Exception.Response.StatusCode.value__ }
    if ($pubCode) { break }
    Start-Sleep -Seconds 3
}
if     ($pubCode -eq 401) { Note "Public address is live and asking for the password." }
elseif ($pubCode -eq 200) { Note "ALERT: public address answered 200 with no password. Check the gate." }
else                      { Note "WARNING: public address answered '$pubCode', expected 401." }

# ------------------------------------------------------ 6. Publish the link
$pw = "see VOICEOVER-PASSWORD.txt"
if (Test-Path $PwFile) {
    $line = Get-Content $PwFile | Where-Object { $_ -match "^Password:" } | Select-Object -First 1
    if ($line) { $pw = ($line -replace "^Password:\s*", "").Trim() }
}

$body = @"
VOICEOVER STUDIO - CURRENT LINK
===============================

Address:   $studio
Username:  editors
Password:  $pw

Updated:   $((Get-Date).ToString("dddd d MMMM yyyy, h:mm tt"))

This address changes every time the office PC restarts. This file is
rewritten automatically each time, so it is always the current one.
Do not post the address in any public place.
"@

Set-Content -Path $LinkFile -Value $body -Encoding utf8
Set-Content -Path $DeskLink -Value $body -Encoding utf8
Note "CURRENT-LINK.txt written."

# Optional: tell Slack, so the editors do not have to ask anyone.
if (Test-Path $HookFile) {
    $hook = (Get-Content $HookFile -Raw).Trim()
    if ($hook -like "https://hooks.slack.com/*") {
        $payload = @{ text = "Voiceover Studio is live again.`nLink: $studio`nUsername: editors`nPassword: $pw" } | ConvertTo-Json
        try {
            Invoke-RestMethod -Uri $hook -Method Post -ContentType "application/json" -Body $payload -TimeoutSec 20 | Out-Null
            Note "Posted the new link to Slack."
        } catch { Note "Slack post failed: $($_.Exception.Message)" }
    }
}

Note "=== autostart done ==="
