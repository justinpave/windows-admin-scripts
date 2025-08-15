<#
.SYNOPSIS
  Collects key Windows event logs (System, Application, Security) for the last N hours.

.EXAMPLE
  .\Collect-Logs.ps1 -OutPath .\outputs -Hours 24
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$OutPath,

  [int]$Hours = 24
)

begin {
  if (-not (Test-Path $OutPath)) { New-Item -ItemType Directory -Path $OutPath | Out-Null }
  $hostName = $env:COMPUTERNAME
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $since = (Get-Date).AddHours(-1 * $Hours)
  Write-Host "Collecting logs since $since ..." -ForegroundColor Cyan
}

process {
  $logs = @("System","Application","Security")
  foreach ($log in $logs) {
    try {
      $evts = Get-WinEvent -LogName $log -ErrorAction Stop | Where-Object { $_.TimeCreated -ge $since }
      $csvPath = Join-Path $OutPath "$log`_$hostName`_$ts.csv"
      $evts | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message |
        Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath
      Write-Host "[OK] $log exported to $csvPath" -ForegroundColor Green
    } catch {
      Write-Warning "Failed to export $log: $($_.Exception.Message)"
    }
  }
}
