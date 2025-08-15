<#
.SYNOPSIS
  Exports Windows Defender Firewall rules to CSV or JSON for audit/review.

.EXAMPLE
  .\Export-FirewallRules.ps1 -OutPath .\outputs -Format Csv
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$OutPath,

  [ValidateSet('Csv','Json','Both')]
  [string]$Format = 'Csv'
)

begin {
  if (-not (Test-Path $OutPath)) { New-Item -ItemType Directory -Path $OutPath | Out-Null }
  $hostName = $env:COMPUTERNAME
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
}

process {
  $rules = Get-NetFirewallRule | ForEach-Object {
    $props = Get-NetFirewallRule -Name $_.Name -PolicyStore $_.PolicyStore | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue
    $addr  = Get-NetFirewallRule -Name $_.Name -PolicyStore $_.PolicyStore | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue
    [PSCustomObject]@{
      Name        = $_.DisplayName
      Enabled     = $_.Enabled
      Direction   = $_.Direction
      Action      = $_.Action
      Profile     = $_.Profile
      Program     = $_.Program
      Protocol    = $props.Protocol
      LocalPort   = $props.LocalPort
      RemotePort  = $props.RemotePort
      LocalAddr   = $addr.LocalAddress
      RemoteAddr  = $addr.RemoteAddress
      Description = $_.Description
      Group       = $_.DisplayGroup
    }
  }

  if ($Format -in @('Csv','Both')) {
    $rules | Export-Csv -NoTypeInformation -Encoding UTF8 -Path (Join-Path $OutPath "fw_rules_$hostName_$ts.csv")
  }
  if ($Format -in @('Json','Both')) {
    $rules | ConvertTo-Json -Depth 4 | Out-File -Encoding UTF8 -FilePath (Join-Path $OutPath "fw_rules_$hostName_$ts.json")
  }

  Write-Host "[OK] Export complete." -ForegroundColor Green
}
