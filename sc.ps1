<#
.SYNOPSIS
    Removes old ScreenConnect clients and installs a new version from a local MSI.
.DESCRIPTION
    Detects and uninstalls any existing ScreenConnect Client installations,
    then installs the MSI provided via the -MsiPath parameter.
    Works on Windows 7 and above (PowerShell 3.0+).
.PARAMETER MsiPath
    Full path to the ScreenConnect MSI file. Defaults to .\ScreenConnect.ClientSetup.msi
.EXAMPLE
    .\Install-ScreenConnect.ps1 -MsiPath "C:\Installers\ScreenConnect.msi"
.NOTES
    Requires administrative privileges.
    Logs are written to: $env:TEMP\ScreenConnect-Install.log
#>

param(
    [string]$MsiPath = (Join-Path $PSScriptRoot "NEW__SEXXXXXXX.msi")
)

#region Initialisation
$ErrorActionPreference = "Stop"
$LogFile = Join-Path $env:TEMP "ScreenConnect-Install.log"
function Write-Log { param([string]$Message) "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" | Out-File -FilePath $LogFile -Append; Write-Host $Message }
Write-Log "=== ScreenConnect Installation Started ==="

# Check for administrative rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "ERROR: This script must be run as Administrator."
    exit 1
}

# Check if MSI exists
if (-not (Test-Path $MsiPath)) {
    Write-Log "ERROR: MSI file not found at '$MsiPath'."
    exit 2
}
Write-Log "Using MSI: $MsiPath"
#endregion

#region Uninstall existing ScreenConnect clients
Write-Log "Searching for installed ScreenConnect clients..."

$UninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$Products = @()
try {
    $Products += Get-WmiObject -Class Win32_Product -Filter "Name LIKE 'ScreenConnect Client%'" -ErrorAction SilentlyContinue
} catch { Write-Log "WMI query for products failed: $_" }

$RegApps = Get-ChildItem $UninstallPaths -ErrorAction SilentlyContinue | Where-Object { $_.GetValue("DisplayName") -like "ScreenConnect Client*" }
$Products += $RegApps

if ($Products.Count -eq 0) {
    Write-Log "No ScreenConnect clients found."
} else {
    Write-Log "Found $($Products.Count) installation(s)."
    foreach ($app in $Products) {
        $displayName = $app.DisplayName -or $app.GetValue("DisplayName")
        $uninstallString = $app.UninstallString -or $app.GetValue("UninstallString")
        $productCode = $null

        if ($uninstallString -match "\{[A-F0-9\-]+\}") {
            $productCode = $matches[0]
        } elseif ($app.IdentifyingNumber) {
            $productCode = $app.IdentifyingNumber
        }

        if ($productCode) {
            Write-Log "Uninstalling '$displayName' (GUID: $productCode)..."
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode /qn /norestart" -Wait -PassThru -ErrorAction SilentlyContinue
            if ($process.ExitCode -eq 0) {
                Write-Log "Uninstall succeeded."
            } else {
                Write-Log "Uninstall exited with code $($process.ExitCode)."
            }
        } else {
            Write-Log "Could not determine product code for '$displayName'. Skipping."
        }
    }
}
#endregion

#region Install from local MSI
Write-Log "Installing ScreenConnect from $MsiPath ..."

$installProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$MsiPath`" /qn /norestart /L*v `"$env:TEMP\ScreenConnect-MSI.log`"" -Wait -PassThru
$exitCode = $installProcess.ExitCode

Write-Log "MSI installation exited with code $exitCode"

if ($exitCode -eq 0) {
    Write-Log "Installation successful."
} elseif ($exitCode -eq 3010) {
    Write-Log "Installation completed but requires a reboot (exit code 3010)."
} else {
    Write-Log "Installation failed with exit code $exitCode. Check MSI log: $env:TEMP\ScreenConnect-MSI.log"
    exit 4
}
#endregion

Write-Log "=== Script finished ==="
exit 0
