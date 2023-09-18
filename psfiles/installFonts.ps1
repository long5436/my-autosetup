
# Run this as a Computer Startup script to allow installing fonts from C:\InstallFont\
# Based on http://www.edugeek.net/forums/windows-7/123187-installation-fonts-without-admin-rights-2.html
# Run this as a Computer Startup Script in Group Policy

# Full details on my website - https://mediarealm.com.au/articles/windows-font-install-no-password-powershell/

$fontPath = Split-Path -Path $PSScriptRoot -Parent



$Timeout = 360
$job = Start-Job -ScriptBlock {
    # Here's where you put the stuff that might hang or take too long.
}

$JobTimer = 0

# Wait for the number of seconds in the $Timeout variable before giving up on the job.
while ($job.State -eq "Running" -and $JobTimer -le $Timeout) {
    $JobTimer = $JobTimer + 1
    sleep -Seconds 1
}

if ($job.State -eq "Completed" -and $job.HasMoreData -eq $true) {
    $job | Receive-Job
}

$SourceDir   = "$fontPath\"
$Source      = "$fontPath\*"
$Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
$TempFolder  = "C:\Windows\Temp\Fonts"

# Create the source directory if it doesn't already exist
New-Item -ItemType Directory -Force -Path $SourceDir

New-Item $TempFolder -Type Directory -Force | Out-Null

Get-ChildItem -Path $Source -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach {
    If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {

        $Font = "$TempFolder\$($_.Name)"
        
        # Copy font to local temporary folder
        Copy-Item $($_.FullName) -Destination $TempFolder
        
        # Install font
        $Destination.CopyHere($Font,0x10)

        # Delete temporary copy of font
        Remove-Item $Font -Force
    }
}