# Quick Windows PowerShell Commands (Run as Administrator)

# Computer 1 - Run these in PowerShell as Admin
$wslip1 = wsl -d Ubuntu hostname -I
$wslip1 = $wslip1.Trim()
Write-Host "WSL IP: $wslip1"

# Clear old rules
netsh interface portproxy reset

# Add firewall rule
New-NetFirewallRule -DisplayName "Mini2-WSL-Servers" -Direction Inbound -LocalPort 50050-50055 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Port forwarding
netsh interface portproxy add v4tov4 listenport=50050 listenaddress=0.0.0.0 connectport=50050 connectaddress=$wslip1
netsh interface portproxy add v4tov4 listenport=50051 listenaddress=0.0.0.0 connectport=50051 connectaddress=$wslip1
netsh interface portproxy add v4tov4 listenport=50052 listenaddress=0.0.0.0 connectport=50052 connectaddress=$wslip1
netsh interface portproxy add v4tov4 listenport=50053 listenaddress=0.0.0.0 connectport=50053 connectaddress=$wslip1
netsh interface portproxy add v4tov4 listenport=50054 listenaddress=0.0.0.0 connectport=50054 connectaddress=$wslip1
netsh interface portproxy add v4tov4 listenport=50055 listenaddress=0.0.0.0 connectport=50055 connectaddress=$wslip1

# Verify
Write-Host "`nPort forwarding configured:"
netsh interface portproxy show all

Write-Host "`nTest from another computer:"
Write-Host "telnet YOUR_WINDOWS_IP 50050"
