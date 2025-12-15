# Azure Excel Compatibility Lab - Excel Installation Script
# Run this script on the Windows VM to install Excel
# Usage: .\install-excel.ps1 [-Version 2019]

param(
    [ValidateSet("2016", "2019", "2021")]
    [string]$Version = "2019"
)

$ErrorActionPreference = "Stop"

# Setup directory
$SetupDir = "C:\ExcelSetup"

Write-Host "=== Azure Excel Compatibility Lab ===" -ForegroundColor Green
Write-Host "Installing Excel $Version" -ForegroundColor Yellow
Write-Host ""

# Excel configuration based on version
$ExcelConfigs = @{
    "2016" = @{
        Channel = "PerpetualVL2016"
        ProductId = "ProPlusVolume"
        PidKey = "XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99"
        Edition = "32"
    }
    "2019" = @{
        Channel = "PerpetualVL2019"
        ProductId = "ProPlus2019Volume"
        PidKey = "NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP"
        Edition = "64"
    }
    "2021" = @{
        Channel = "PerpetualVL2021"
        ProductId = "ProPlus2021Volume"
        PidKey = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
        Edition = "64"
    }
}

$Config = $ExcelConfigs[$Version]

# Create setup directory if it doesn't exist
if (-not (Test-Path $SetupDir)) {
    Write-Host "Creating setup directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $SetupDir | Out-Null
}

# Download ODT if not present
$OdtPath = Join-Path $SetupDir "odt.exe"
$SetupExe = Join-Path $SetupDir "setup.exe"

if (-not (Test-Path $SetupExe)) {
    Write-Host "Downloading Office Deployment Tool..." -ForegroundColor Yellow
    $OdtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17830-20162.exe"

    try {
        Invoke-WebRequest -Uri $OdtUrl -OutFile $OdtPath -UseBasicParsing
        Write-Host "Download complete." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to download ODT: $_" -ForegroundColor Red
        exit 1
    }

    # Extract ODT
    Write-Host "Extracting Office Deployment Tool..." -ForegroundColor Yellow
    Start-Process -FilePath $OdtPath -ArgumentList "/quiet /extract:$SetupDir" -Wait
    Write-Host "Extraction complete." -ForegroundColor Green
}

# Create configuration XML
Write-Host "Creating Excel $Version configuration..." -ForegroundColor Yellow
$ConfigXml = @"
<Configuration>
  <Add OfficeClientEdition="$($Config.Edition)" Channel="$($Config.Channel)">
    <Product ID="$($Config.ProductId)" PIDKEY="$($Config.PidKey)">
      <Language ID="en-us" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="PowerPoint" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
      <ExcludeApp ID="Word" />
    </Product>
  </Add>
  <Updates Enabled="FALSE" />
  <Display Level="Full" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="SharedComputerLicensing" Value="0" />
</Configuration>
"@

$ConfigPath = Join-Path $SetupDir "config.xml"
$ConfigXml | Out-File -FilePath $ConfigPath -Encoding UTF8

Write-Host "Configuration saved to: $ConfigPath" -ForegroundColor Green

# Install Excel
Write-Host ""
Write-Host "Installing Excel $Version..." -ForegroundColor Yellow
Write-Host "This may take 5-15 minutes depending on internet speed." -ForegroundColor Yellow
Write-Host ""

try {
    $process = Start-Process -FilePath $SetupExe -ArgumentList "/configure `"$ConfigPath`"" -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "=== Excel $Version Installation Complete ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "Excel is now installed and ready for testing." -ForegroundColor Green
        Write-Host "Note: Excel is running in evaluation mode (no activation required)." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To start Excel, run: excel.exe" -ForegroundColor Cyan
    }
    else {
        Write-Host "Installation exited with code: $($process.ExitCode)" -ForegroundColor Red
    }
}
catch {
    Write-Host "Installation failed: $_" -ForegroundColor Red
    exit 1
}
