# Windows Admin Scripts

Handy PowerShell scripts I use for Windows system administration—inventory, maintenance, security checks, and log collection. Each script is written to be readable, parameterized, and safe to run in a homelab or enterprise test environment.

> ⚠️ Always review scripts before running in production. Test in a lab first.

---

## 🚀 Quick Start

```powershell
# PowerShell 5.1+ (Windows) or PowerShell 7+
# Run from a non-elevated prompt unless noted in the script

# Allow local script execution for this session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Example: run inventory
.\scripts\Inventory\Get-SystemInventory.ps1 -OutPath .\outputs
