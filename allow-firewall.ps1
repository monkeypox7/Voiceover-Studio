# Opens port 8880 so other computers on the SAME office wifi can reach
# the voiceover server. Limited to the local network only - not the internet.

$RuleName = "Calilio Voiceover Server (port 8880)"

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($id)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  This must run as administrator." -ForegroundColor Red
    Read-Host "  Press Enter to close"
    exit 1
}

$existing = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host ""
    Write-Host "  The rule already exists. Nothing to do." -ForegroundColor Green
} else {
    New-NetFirewallRule `
        -DisplayName $RuleName `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort 8880 `
        -Profile Private,Public `
        -RemoteAddress LocalSubnet `
        -Description "Lets other computers on the office wifi open the Kokoro voiceover page." | Out-Null

    Write-Host ""
    Write-Host "  Done. Editors on the office wifi can now reach the server." -ForegroundColor Green
}

Write-Host ""
Write-Host "  They should bookmark this address:" -ForegroundColor Cyan
$ip = (Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress
Write-Host "     http://$ip`:8880/web" -ForegroundColor Yellow
Write-Host ""
Read-Host "  Press Enter to close"
