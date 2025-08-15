<#
.SYNOPSIS
  Checks for and installs Windows Updates (supports download-only mode).

.NOTES
  Requires Administrator for installation.

.EXAMPLE
  .\Invoke-WindowsUpdate.ps1 -DownloadOnly
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [switch]$DownloadOnly,
  [switch]$AcceptEula
)

function Get-WindowsUpdateSession {
  $session  = New-Object -ComObject Microsoft.Update.Session
  $searcher = $session.CreateUpdateSearcher()
  $result   = $searcher.Search("IsInstalled=0 and Type='Software'")
  return @{ Session = $session; Result = $result }
}

try {
  if (-not $AcceptEula) {
    Write-Warning "Some updates may require EULA acceptance. Use -AcceptEula to auto-accept."
  }

  $ctx = Get-WindowsUpdateSession
  $updates = New-Object -ComObject Microsoft.Update.UpdateColl

  foreach ($upd in $ctx.Result.Updates) {
    if ($PSCmdlet.ShouldProcess($upd.Title, "Queue update")) {
      if ($AcceptEula -and -not $upd.EulaAccepted) { $upd.AcceptEula() | Out-Null }
      $updates.Add($upd) | Out-Null
    }
  }

  if ($updates.Count -eq 0) { Write-Host "No applicable updates found." -ForegroundColor Yellow; return }

  if ($DownloadOnly) {
    $downloader = $ctx.Session.CreateUpdateDownloader()
    $downloader.Updates = $updates
    $downloader.Download() | Out-Null
    Write-Host "[OK] Updates downloaded. Install later via Settings or rerun without -DownloadOnly." -ForegroundColor Green
  } else {
    $installer = $ctx.Session.CreateUpdateInstaller()
    $installer.Updates = $updates
    $result = $installer.Install()
    Write-Host "[OK] Installation result: $($result.ResultCode)" -ForegroundColor Green
    Write-Host "Reboot required: $($result.RebootRequired)" -ForegroundColor Yellow
  }
}
catch {
  Write-Error $_.Exception.Message
}
