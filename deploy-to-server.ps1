# Copies the deploy folder up to a Linux server and runs the installer there.
#
# You need the server's IP address and to be able to log into it. Nothing on
# this computer is changed, and nothing here needs administrator rights.

$ErrorActionPreference = "Stop"

$Local  = Join-Path $PSScriptRoot "deploy"
$Remote = "/opt/voiceover"

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
Say "  Put Voiceover Studio on a server"
Say "  --------------------------------"
Say ""

if (-not (Test-Path $Local)) { Fail "The deploy folder is missing from this app folder." }
if (-not (Test-Path (Join-Path $Local "web\studio.html"))) { Fail "deploy\web\studio.html is missing." }

$ssh = "$env:SystemRoot\System32\OpenSSH\ssh.exe"
$scp = "$env:SystemRoot\System32\OpenSSH\scp.exe"
if (-not (Test-Path $ssh)) { $ssh = (Get-Command ssh -ErrorAction SilentlyContinue).Source }
if (-not (Test-Path $scp)) { $scp = (Get-Command scp -ErrorAction SilentlyContinue).Source }
if (-not $ssh -or -not $scp) { Fail "Windows OpenSSH is missing. Turn it on under Settings, Apps, Optional features, OpenSSH Client." }

Write-Host "  The server's IP address (the provider shows it after you create the server)."
$ip = (Read-Host "  IP").Trim()
if (-not $ip) { Fail "No IP given, nothing was done." }

Write-Host ""
Write-Host "  The login name for the server."
Write-Host "  Oracle Cloud Ubuntu servers use  ubuntu  . Most others use  root  ."
$user = (Read-Host "  User [ubuntu]").Trim()
if (-not $user) { $user = "ubuntu" }
$target = "$user@$ip"

# Oracle hands you a private key file at the moment you create the server.
# Windows refuses to use a key that other accounts can read, so take a copy
# and lock it down.
Write-Host ""
Write-Host "  The private key file the provider gave you (drag the file in here)."
Write-Host "  Leave blank if you set a password instead."
$keyIn = (Read-Host "  Key file").Trim().Trim('"')

$sshArgs = @("-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=20")
if ($keyIn) {
    if (-not (Test-Path $keyIn)) { Fail "No file at: $keyIn" }
    $keyDir = Join-Path $env:USERPROFILE ".ssh"
    if (-not (Test-Path $keyDir)) { New-Item -ItemType Directory -Force $keyDir | Out-Null }
    $key = Join-Path $keyDir "voiceover-server.key"
    Copy-Item $keyIn $key -Force
    & icacls $key /inheritance:r | Out-Null
    & icacls $key /grant:r "$($env:USERNAME):(R)" | Out-Null
    $sshArgs += @("-i", $key)
    Say "  Key copied to $key and locked down."
}

Write-Host ""
Say "  Checking you can reach the server..."
& $ssh @sshArgs $target "echo ok" | Out-Null
if ($LASTEXITCODE -ne 0) {
    Fail "Could not log into $target. Check the IP, the user name, and the key file. On Oracle the user is usually 'ubuntu', not 'root'."
}
Say "  Connected."

Say "  Copying the files up..."
& $ssh @sshArgs $target "sudo mkdir -p $Remote && sudo chown -R `$(whoami) $Remote"
if ($LASTEXITCODE -ne 0) { Fail "Could not create $Remote on the server." }

& $scp @sshArgs -r "$Local\*" "${target}:$Remote/"
if ($LASTEXITCODE -ne 0) { Fail "Copying the files failed." }
Say "  Files copied to $Remote"

Write-Host ""
Say "  Running the installer on the server."
Warn "  It will ask you two questions: the web address, and a password."
Warn "  The first run downloads about 5 GB, so give it several minutes."
Write-Host ""

& $ssh @sshArgs -t $target "cd $Remote && sudo bash install.sh"
$code = $LASTEXITCODE

Write-Host ""
if ($code -eq 0) {
    Say "  Finished. The address and password are printed above."
    Say "  They are also saved on the server in $Remote/LOGIN.txt"
    Write-Host ""
    Write-Host "  From now on the server runs it. This computer can be switched off." -ForegroundColor Green
} else {
    Warn "  The installer stopped with an error. Read the messages above."
    Warn "  You can try again with this same file, nothing is lost."
}
Write-Host ""
Read-Host "  Press Enter to close"
