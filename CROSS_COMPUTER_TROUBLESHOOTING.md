# CROSS-COMPUTER CONNECTION TROUBLESHOOTING

## Current Status
- ✅ Servers running on both computers
- ✅ Servers listening on 0.0.0.0 (all interfaces)
- ❌ Cross-computer communication BLOCKED

## Problem
Windows Firewall is blocking connections between the two computers.

## SOLUTION - Run on BOTH Computers

### Step 1: Fix Windows Firewall (BOTH COMPUTERS)

**Open PowerShell as Administrator** and run:

```powershell
cd C:\Users\<YOUR_USERNAME>\mini-2\scripts
.\WINDOWS_FIREWALL_FIX.ps1
```

If you get execution policy error, run this first:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Step 2: Quick Test (Alternative Method)

**If script doesn't work, manually add rules (as Administrator):**

**On Computer 1 (192.168.137.189):**
```powershell
# Allow inbound from Computer 2
New-NetFirewallRule -DisplayName "Mini2-Allow-Remote" -Direction Inbound -Protocol TCP -RemoteAddress 192.168.137.1 -LocalPort 50050-50055 -Action Allow

# Allow outbound to Computer 2
New-NetFirewallRule -DisplayName "Mini2-Allow-Remote-Out" -Direction Outbound -Protocol TCP -RemoteAddress 192.168.137.1 -RemotePort 50050-50055 -Action Allow
```

**On Computer 2 (192.168.137.1):**
```powershell
# Allow inbound from Computer 1
New-NetFirewallRule -DisplayName "Mini2-Allow-Remote" -Direction Inbound -Protocol TCP -RemoteAddress 192.168.137.189 -LocalPort 50050-50055 -Action Allow

# Allow outbound to Computer 1
New-NetFirewallRule -DisplayName "Mini2-Allow-Remote-Out" -Direction Outbound -Protocol TCP -RemoteAddress 192.168.137.189 -RemotePort 50050-50055 -Action Allow
```

### Step 3: TEMPORARY - Disable Firewall for Testing

**ONLY IF ABOVE DOESN'T WORK** (you can re-enable later):

```powershell
Set-NetFirewallProfile -Profile Private -Enabled False
```

To re-enable later:
```powershell
Set-NetFirewallProfile -Profile Private -Enabled True
```

### Step 4: Verify in WSL

After firewall changes, test in WSL:

**Computer 1:**
```bash
nc -zv 192.168.137.1 50052
nc -zv 192.168.137.1 50054
nc -zv 192.168.137.1 50055
```

**Computer 2:**
```bash
nc -zv 192.168.137.189 50050
nc -zv 192.168.137.189 50051
nc -zv 192.168.137.189 50053
```

All should show "succeeded" or "open".

### Step 5: Run Diagnostic Again

```bash
./scripts/diagnose_and_fix.sh
```

Should now show:
- ✅ Remote connectivity: WORKS

## Why This Happens

1. Windows Firewall blocks **inbound** connections by default
2. Even with port forwarding, Windows Firewall can block **cross-computer** traffic
3. Private network profile treats Ethernet connections as potentially unsafe

## What the Fix Does

1. Creates firewall rules allowing **inbound** TCP on ports 50050-50055
2. Creates firewall rules allowing **outbound** TCP to ports 50050-50055
3. Adds WSL-specific rules for vEthernet interface
4. Tests connectivity between computers

## After Fix Works

Once connectivity is established, test the distributed system:

```bash
# On Computer 1
./build/mini2_client --server 192.168.137.189:50050 --mode ping

# Test request forwarding
./build/mini2_client --server 192.168.137.189:50050 --mode request --query "test cross-computer"
```

## Rollback

To remove all firewall rules if needed:
```powershell
Remove-NetFirewallRule -DisplayName "Mini2*"
```
