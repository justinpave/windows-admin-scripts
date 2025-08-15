<#
.SYNOPSIS
  Collects basic system inventory (device, OS, CPU, RAM, disks, NICs) to CSV/JSON.

.EXAMPLE
  .\Get-SystemInventory.ps1 -OutPath .\outputs
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateNotNullOrEmpty()]
  [string]$OutPath,

  [ValidateSet('Csv','Json','Both')]
  [string]$Format = 'Both'
)

begin {
  if (-not (Test-Path $OutPath)) { New-Item -ItemType Directory -Path $OutPath | Out-Null }
  $hostName = $env:COMPUTERNAME
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
}

process {
  $os   = Get-CimInstance Win32_OperatingSystem
  $cs   = Get-CimInstance Win32_ComputerSystem
  $cpu  = Get-CimInstance Win32_Processor
  $bios = Get-CimInstance Win32_BIOS
  $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

  $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    [PSCustomObject]@{
      DeviceID   = $_.DeviceID
      FileSystem = $_.FileSystem
      SizeGB     = [math]::Round($_.Size/1GB,2)
      FreeGB     = [math]::Round($_.FreeSpace/1GB,2)
    }
  }

  $nics = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | ForEach-Object {
    [PSCustomObject]@{
      Description = $_.Description
      IPv4        = ($_.IPAddress | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }) -join ','
      IPv6        = ($_.IPAddress | Where-Object { $_ -match ':' }) -join ','
      MAC         = $_.MACAddress
      DNS         = ($_.DNSServerSearchOrder) -join ','
    }
  }

  $obj = [PSCustomObject]@{
    Timestamp       = (Get-Date).ToString("s")
    Hostname        = $hostName
    Manufacturer    = $cs.Manufacturer
    Model           = $cs.Model
    BIOSVersion     = $bios.SMBIOSBIOSVersion
    SerialNumber    = $bios.SerialNumber
    OSCaption       = $os.Caption
    OSVersion       = $os.Version
    BuildNumber     = $os.BuildNumber
    InstallDate     = $os.InstallDate
    UptimeDays      = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays,2)
    CPUName         = $cpu.Name
    Cores           = $cpu.NumberOfCores
    LogicalProcs    = $cpu.NumberOfLogicalProcessors
    RAM_GB          = $ramGB
    Disks           = $disks
    NICs            = $nics
  }

  if ($Format -in @('Csv','Both')) {
    $flat = $obj | Select-Object Timestamp,Hostname,Manufacturer,Model,BIOSVersion,SerialNumber,
      OSCaption,OSVersion,BuildNumber,InstallDate,UptimeDays,CPUName,Cores,LogicalProcs,RAM_GB
    $flat | Export-Csv -Path (Join-Path $OutPath "inventory_$hostName_$ts.csv") -NoTypeInformation -Encoding UTF8
  }
  if ($Format -in @('Json','Both')) {
    $obj | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path $OutPath "inventory_$hostName_$ts.json") -Encoding UTF8
  }

  Write-Host "[OK] Inventory captured for $hostName" -ForegroundColor Green
}
