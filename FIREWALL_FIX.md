# COMPLETE WINDOWS FIREWALL & NETWORKING SETUP

## Problem: Computers cannot reach each other across network

## Status from testing:
- Computer 1 (172.26.247.68) → Self: ✓ WORKS
- Computer 1 → Computer 2 (172.22.223.237): ✗ TIMEOUT
- Computer 2 → Computer 1: ✗ TIMEOUT (likely)

## Solution: Configure BOTH computers

---

## On Computer 1 - PowerShell as Administrator

```powershell
# Get WSL IP
$wslip = wsl hostname -I
$wslip = $wslip.Trim()
Write-Host "WSL IP: $wslip"

# Clear old rules
netsh interface portproxy reset
Remove-NetFirewallRule -DisplayName "Mini2*" -ErrorAction SilentlyContinue

# Allow INBOUND connections (from other computer)
New-NetFirewallRule -DisplayName "Mini2-Inbound" -Direction Inbound -LocalPort 50050-50055 -Protocol TCP -Action Allow -Profile Any

# Allow OUTBOUND connections (to other computer)
New-NetFirewallRule -DisplayName "Mini2-Outbound" -Direction Outbound -RemotePort 50050-50055 -Protocol TCP -Action Allow -Profile Any

# Port forwarding from Windows to WSL
netsh interface portproxy add v4tov4 listenport=50050 listenaddress=0.0.0.0 connectport=50050 connectaddress=$wslip
netsh interface portproxy add v4tov4 listenport=50051 listenaddress=0.0.0.0 connectport=50051 connectaddress=$wslip
netsh interface portproxy add v4tov4 listenport=50053 listenaddress=0.0.0.0 connectport=50053 connectaddress=$wslip

# Verify
Write-Host "`nFirewall rules created:"
Get-NetFirewallRule -DisplayName "Mini2*" | Select-Object DisplayName, Direction, Action

Write-Host "`nPort forwarding configured:"
netsh interface portproxy show all

Write-Host "`nDone! Computer 1 configured."
```

---

## On Computer 2 - PowerShell as Administrator

```powershell
# Get WSL IP
$wslip = wsl hostname -I
$wslip = $wslip.Trim()
Write-Host "WSL IP: $wslip"

# Clear old rules
netsh interface portproxy reset
Remove-NetFirewallRule -DisplayName "Mini2*" -ErrorAction SilentlyContinue

# Allow INBOUND connections (from other computer)
New-NetFirewallRule -DisplayName "Mini2-Inbound" -Direction Inbound -LocalPort 50050-50055 -Protocol TCP -Action Allow -Profile Any

# Allow OUTBOUND connections (to other computer)
New-NetFirewallRule -DisplayName "Mini2-Outbound" -Direction Outbound -RemotePort 50050-50055 -Protocol TCP -Action Allow -Profile Any

# Port forwarding from Windows to WSL
netsh interface portproxy add v4tov4 listenport=50052 listenaddress=0.0.0.0 connectport=50052 connectaddress=$wslip
netsh interface portproxy add v4tov4 listenport=50054 listenaddress=0.0.0.0 connectport=50054 connectaddress=$wslip
netsh interface portproxy add v4tov4 listenport=50055 listenaddress=0.0.0.0 connectport=50055 connectaddress=$wslip

# Verify
Write-Host "`nFirewall rules created:"
Get-NetFirewallRule -DisplayName "Mini2*" | Select-Object DisplayName, Direction, Action

Write-Host "`nPort forwarding configured:"
netsh interface portproxy show all

Write-Host "`nDone! Computer 2 configured."
```

---

## Test Connectivity (from WSL on each computer)

### From Computer 1 WSL:
```bash
# Test self
telnet 172.26.247.68 50050
# Should connect immediately, Ctrl+C to exit

# Test Computer 2
telnet 172.22.223.237 50052
# Should connect immediately, Ctrl+C to exit
```

### From Computer 2 WSL:
```bash
# Test self
telnet 172.22.223.237 50052
# Should connect immediately, Ctrl+C to exit

# Test Computer 1
telnet 172.26.247.68 50050
# Should connect immediately, Ctrl+C to exit
```

**If telnet still times out:**
- Check Windows Defender Firewall is not in "Block all" mode
- Check network profile is "Private" not "Public"
- Try temporarily: `Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False` (disables ALL firewall - only for testing!)

---

## After Firewall Fixed - Test Mini2

### From Computer 1:
```bash
cd ~/mini-2

# Test client → server on same computer
./build/src/cpp/mini2_client --server 172.26.247.68:50050 --query 'local test'

# Test client → server on other computer (should work after firewall fix)
./build/src/cpp/mini2_client --server 172.22.223.237:50052 --query 'remote test'

# Run full test suite
./scripts/comprehensive_test.sh
```

---

## Troubleshooting

### Check Windows Firewall Status:
```powershell
Get-NetFirewallProfile | Select-Object Name, Enabled
```

### Check if rule exists:
```powershell
Get-NetFirewallRule -DisplayName "Mini2*"
```

### Check port forwarding:
```powershell
netsh interface portproxy show all
```

### Nuclear option (testing only):
```powershell
# DISABLE FIREWALL (only for testing!)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Re-enable after testing:
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
```

---

## Summary

The issue is **Windows Firewall on Computer 2 blocking inbound connections**. The PowerShell commands above:

1. Create firewall rules to ALLOW ports 50050-50055
2. Enable BOTH inbound and outbound traffic
3. Set up port forwarding from Windows IP to WSL IP
4. Apply to ALL network profiles (Domain, Public, Private)

Run the PowerShell commands on **BOTH computers** then test with telnet.
