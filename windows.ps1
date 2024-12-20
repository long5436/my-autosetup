# Set execution policy
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Variables
$appDataLocalPath = $env:LOCALAPPDATA
$pathRoot = $PSScriptRoot 
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$evkeyLinkDownload = "https://github.com/lamquangminh/EVKey/releases/download/Release/EVKey.zip"
$evkeyPathFile = "$DesktopPath\evkey.zip"
$evkeyPathFolder = "$HOME\PortableApps\evkey"
$evkeyConfigFile = Join-Path $pathRoot "config\evkey\setting.ini"
$evKeyexeFile = Join-Path $evkeyPathFolder "EVKey64.exe"
$pathConfigWindowTerminal = "$HOME\scoop\apps\windows-terminal\current\settings"
$pathFileConfigWindowTerminal = Join-Path $pathRoot "config\windowsTerminal\settings.json"
$profiles = Join-Path $pathRoot "config\profiles"

function Write-Message {
    param (
        [string]$msg,
        [string]$color = "Yellow"
    )
    Write-Host $msg -ForegroundColor $color;
}

function RunCommands {
    param (
        [string[]]$commands
    )
    foreach ($command in $commands) {
        Invoke-Expression $command
    }
}

function RunCommandsWithAdmin {
    param (
        [string[]]$commands
    )
    foreach ($command in $commands) {
        Start-Process -Wait powershell -Verb runas -ArgumentList $command
    }
}

function InstallScoop {
    if (Get-Command scoop -errorAction SilentlyContinue) {
        Write-Message "Scoop already installed"
    }
    else {
        Write-Message "Installing Scoop"
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        Invoke-RestMethod get.scoop.sh | Invoke-Expression
    }
}

function InstallFonts {
    $fontPath = Join-Path $PSScriptRoot "assets\fonts"
    $fontFolderPath = "$appDataLocalPath\Microsoft\Windows\Fonts"
   
    Write-Message("Install fonts from file")
    Get-ChildItem -Path "$fontPath*" -Include '*.ttf', '*.ttc', '*.otf' -Recurse | ForEach-Object {
        If (-Not (Test-Path -Path "$fontFolderPath\$($_.Name)" -PathType Leaf)) {
            Write-Host "Installing $($_.Name)"
            Copy-Item $_ $fontFolderPath 
        }
    }
}

function InstallProfiles {
    param ()

    Write-Message("Install profiles")

    $profilesFile = @(
        "Microsoft.PowerShell_profile.ps1",
        ".bashrc"
        ".zshrc"
    )

    $profilesPath = @(
        "$HOME\Documents\WindowsPowerShell",
        "$HOME",
        "$HOME"
    )

    $index = 0
    $profilesPath | ForEach-Object {
        $profileConfigFile = $profilesFile[$index]
        $a = "$_\$profileConfigFile"

        If (-Not (Test-Path -Path $a -PathType Leaf)) {
            Write-Host "Installing $profileConfigFile"
            Copy-Item "$profiles\$profileConfigFile" $_
        }

        $index++
    }
}

function InstallEvKey {
    param ()

    Write-Message "Downloading and installing Evkey"

    if (-Not (Test-Path $evKeyexeFile)) {
        Write-Host "Downloading"
        Invoke-WebRequest $evkeyLinkDownload -OutFile $evkeyPathFile
        Write-Host "Extracting"
        Expand-Archive -Path $evkeyPathFile -DestinationPath $evkeyPathFolder -Force
        Write-Host "Copying config file"
        Copy-Item $evkeyConfigFile -Destination $evkeyPathFolder -Force
        Write-Host "Starting evkey"
        Start-Process $evKeyexeFile
        Remove-Item -Path $evkeyPathFile 
        Write-Host "Delete evkey.zip"
    }
}

function InstallWindowsTermial {
    param ()

    Write-Message "Install and setup config Windows terminal"

    If (Test-Path $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe) {
        If (test-path "$pathConfigWindowTerminal\settings.json") {
        }
        Else {
            Write-Host "Copying config windows-terminal"
            Copy-Item $pathFileConfigWindowTerminal -Destination $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState -Force
        }
    }
    Else {
        Write-Host "Installing windows-terminal"
        scoop install extras/windows-terminal

        If (test-path "$pathConfigWindowTerminal") {
            Write-Host "Copying config windows-terminal"
            Copy-Item $pathFileConfigWindowTerminal -Destination $pathConfigWindowTerminal -Force
        }
        Else {
        }
    }
}

# run

# This will speed up package download
# Write-Start -msg "Installing aria2"
# $ProgressPreference = 'SilentlyContinue'
#scoop install aria2

Write-Message "Disabling ConsentPromptBehaviorAdmin"
RunCommandsWithAdmin @(
    "Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0"
)

InstallScoop

Write-Message "Install chocolatey"
RunCommandsWithAdmin @(
    "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
)

Write-Message "Installing git, adding buckets"
RunCommands @(
    "scoop install git",
    "scoop bucket add extras",
    "scoop bucket add nerd-fonts",
    "scoop bucket add java",
    "scoop bucket add main",
    "scoop bucket add versions",
    "scoop update"
)

RunCommands @(
    "scoop install innounp-unicode", # Inno Setup Unpacker 
    "scoop install googlechrome brave firefox", # Browser 
    "scoop install dos2unix scrcpy adb gsudo jadx", # Tool 
    "scoop install windows-terminal",
    "scoop install vscode vscodium fnm sublime-text postman heidisql sourcetree android-studio android-clt mongodb mongodb-compass", # Coding
    "scoop install python openjdk17", # Runtime lib 
    "scoop install telegram neatdownloadmanager anydesk bifrost dolphin", # Apps
    "scoop install Hack-NF firacode Cascadia-Code" # Fonts
)

RunCommandsWithAdmin @(
    "scoop install vcredist-aio", # Windows libs 
    "choco install warp -y" # 1111
)

InstallProfiles
InstallFonts
InstallWindowsTermial
InstallEvKey

RunCommands @(
    "git config --global credential.helper manager",
    "git config --global init.defaultBranch main"
)

# Install NodeJS and global modules
Write-Message "Installing NodeJS in fnm"
RunCommandsWithAdmin @(
    "fnm install 20",
    "fnm use 20",
    "npm install -g yarn pnpm"
)


Write-Message "Installing context menu options"
RunCommands @(
    "reg import '$HOME\scoop\apps\sublime-text\current\install-context.reg'",
    "reg import '$HOME\scoop\apps\vscodium\current\install-context.reg'",
    "reg import '$HOME\scoop\apps\vscode-insiders\current\install-context.reg'",
    "reg import '$HOME\scoop\apps\vscode\current\install-context.reg'",
    "reg import '$HOME\scoop\apps\7zip\current\install-context.reg'"
)
If (Test-Path $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe) {
    RunCommands @("reg import '$("$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe")\install-context.reg'")
}
else {
    RunCommands @("reg import '$HOME\scoop\apps\windows-terminal\current\install-context.reg'")
}

Write-Message "Enable UTC Time"
RunCommandsWithAdmin @(
    "reg import '$PSScriptRoot\assets\regs\WinUTCOn.reg'"
)

Write-Message "Config windows"
RunCommands @(
    'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1', # Enable show hidden files
    'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0', # Enable show extension files
    "wsl --set-default-version 2" # set default version wsl
)
RunCommandsWithAdmin @(
    "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart",
    "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart",
    "Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart",
    "Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart"
)

Write-Message "Restoring ConsentPromptBehaviorAdmin"
RunCommandsWithAdmin @(
    "Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 5"
)