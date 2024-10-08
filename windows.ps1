# Run this command first and then run the ps1 file in powershell
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Variables
$pathRoot = $PSScriptRoot 
$evkeyLinkDownload = "https://github.com/lamquangminh/EVKey/releases/download/Release/EVKey.zip"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$evkeyPathFile = "$DesktopPath\evkey.zip"
$evkeyPathFolder = "$HOME\PortableApps\evkey"
$evkeyConfigFile = $pathRoot + "\config\evkey\setting.ini"
$evKeyexeFile = $evkeyPathFolder + "\EVKey64.exe"
$powershellFnmEnv = "fnm env --use-on-cd | Out-String | Invoke-Expression"
$bashAndZshFnmEnv = 'eval "$(fnm env --use-on-cd)"'
$pathConfigWindowTerminal = "$HOME\scoop\apps\windows-terminal\current\settings"
$pathFileConfigWindowTerminal = $pathRoot + "\config\windowsTerminal\settings.json"
$pathGitbashConfig = $pathRoot + "\config\gitbash"


# Functions
function Write-Start {
    param (
        $msg
    )
    Write-Host $msg -ForegroundColor Green; Write-Host
}
function Write-Done {
    Write-Host "DONE" -ForegroundColor Green; Write-Host
}

Function setEnvFnm {
    param (
        $shell
    )
    
    switch ($shell) {
        "ps1" { SetEnvToShell -name 'Powershell' -shellPath $PROFILE -envCode $powershellFnmEnv }
        "bash" { 
            # SetEnvToShell -name 'Bash' -shellPath "$HOME\.bashrc" -envCode $bashAndZshFnmEnv 
            # dos2unix.exe -r -v -f -D utf8 "$HOME\.bashrc" 
            Copy-Item "$pathGitbashConfig/.bashrc" -Destination $HOME -Force
        }
        "zsh" {
            # SetEnvToShell -name 'Zsh' -shellPath "$HOME\.zshrc" -envCode $bashAndZshFnmEnv
            # dos2unix.exe -r -v -f -D utf8 "$HOME\.bashrc"  
            Copy-Item "$pathGitbashConfig/.zshrc" -Destination $HOME -Force
        }
        Default {}
    }
}

Function SetEnvToShell {
    param (
        $name, $shellPath, $envCode
    )

    If (test-path $shellPath) {
        $fileContent = Get-Content -Path $shellPath
        $result = $fileContent -like $envCode

        If ($null -ne $result) {
            Write-Host "$name FnmEnv existed" 
        }
        Else {
            "`n$envCode" >> $shellPath
            Write-Host "$name FnmEnv created" 
        }
    }
    Else {
        Write-Host "$name FnmEnv created" 
        New-Item -Path $shellPath -Type File -Force
        "`n$envCode" >> $shellPath
    }
}

Function InstallFontFromFile {
    $fontPath = "$PSScriptRoot\assets\fonts\"
    $Source = "$fontPath*"
    $Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
    $TempFolder = "C:\Windows\Temp\Fonts"

    # Create the source directory if it doesn't already exist
    New-Item -ItemType Directory -Force -Path $fontPath

    New-Item $TempFolder -Type Directory -Force | Out-Null

    Get-ChildItem -Path $Source -Include '*.ttf', '*.ttc', '*.otf' -Recurse | ForEach-Object {
        If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {

            $Font = "$TempFolder\$($_.Name)"
        
            # Copy font to local temporary folder
            Copy-Item $($_.FullName) -Destination $TempFolder -Force
        
            # Install font
            $Destination.CopyHere($Font, 0x10) 

            # Delete temporary copy of font
            Remove-Item $Font -Force
        }
    }
}


Exit-PSHostProcess

# # Start
Start-Process -Wait powershell -verb runas -ArgumentList "Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0"
 
                                       
#
Write-Start -msg "Installing Chocolatey"
Start-Process -Wait powershell -verb runas -ArgumentList "
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
Write-Done

Write-Start -msg "Installing Scoop"
if (Get-Command scoop -errorAction SilentlyContinue) {
    Write-Warning "Scoop already installed"
}
else {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
}
Write-Done

Write-Start -msg "Initializing Scoop..."
scoop install git
scoop bucket add extras
scoop bucket add nerd-fonts
scoop bucket add java
scoop bucket add main
scoop bucket add versions
scoop update
Write-Done


# This will speed up package download
Write-Start -msg "Installing aria2"
$ProgressPreference = 'SilentlyContinue'
#scoop install aria2
Write-Done

Write-Start -msg "Installing Scoop's packages"
scoop install extras/googlechrome extras/brave extras/firefox <# Browser #>
scoop install main/dos2unix main/scrcpy main/adb gsudo <# Tool #>
If (Test-Path !$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe) {
    scoop install extras/windows-terminal
}
scoop install vscode versions/vscode-insiders extras/vscodium main/fnm extras/sublime-text postman extras/heidisql extras/sourcetree <# Coding #>
scoop install python <# Runtime lib #> 
Start-Process -Wait powershell -verb runas -ArgumentList "scoop install vcredist-aio"
scoop install extras/telegram extras/neatdownloadmanager extras/anydesk extras/bifrost <# Apps #>  
Write-Done

Write-Start -msg "Installing Chocolatey's packages"
Start-Process -Wait powershell -verb runas -ArgumentList "choco install warp -y"
Write-Done

Write-Start -msg "Installing Fonts"
scoop install nerd-fonts/FiraCode-NF nerd-fonts/Hack-NF firacode nerd-fonts/Cascadia-Code
InstallFontFromFile
Write-Done

Write-Start -msg "Set Env shell"
setEnvFnm -shell "ps1"
# Start-Process -Wait powershell -verb runas -ArgumentList 'setEnvFnm -shell "bash"'
setEnvFnm -shell "bash"
# Start-Process -Wait powershell -verb runas -ArgumentList 'setEnvFnm -shell "zsh"'
setEnvFnm -shell "zsh"
Write-Done

Write-Start -msg "Set Git Credential Manager Core"
Start-Process -Wait powershell -verb runas -ArgumentList "git config --global credential.helper manager"
Write-Done

Write-Start -msg "Set Git default branch name"
Start-Process -Wait powershell -verb runas -ArgumentList "git config --global init.defaultBranch main"
Write-Done


Write-Start -msg "Installing NodeJS in fnm"
Start-Process -Wait powershell -verb runas -ArgumentList "fnm install 20"
Start-Process -Wait powershell -verb runas -ArgumentList "fnm use 20"
Write-Done

Write-Start -msg "Installing Modules global Nodejs"
Start-Process -Wait powershell -verb runas -ArgumentList "npm install --verbose;npm install -g yarn pnpm"
Write-Done

Write-Start -msg "Setup fnm env"
fnm env --use-on-cd | Out-String | Invoke-Expression
Write-Done

Write-Start -msg "Add Windows Terminal as a context menu option"
reg import "$HOME\scoop\apps\windows-terminal\current\install-context.reg"
Write-Done

Write-Start -msg "Add Sublime Text as a context menu option"
reg import "$HOME\scoop\apps\sublime-text\current\install-context.reg"
Write-Done

Write-Start -msg "Add VSCodium as a context menu option, For file associations"
reg import "$HOME\scoop\apps\vscodium\current\install-context.reg"
reg import "$HOME\scoop\apps\vscodium\current\install-associations.reg"
Write-Done

Write-Start -msg "Add VSCode Insiders as a context menu option, For file associations"
reg import "$HOME\scoop\apps\vscode-insiders\current\install-context.reg"
reg import "$HOME\scoop\apps\vscode-insiders\current\install-associations.reg"
Write-Done

Write-Start -msg "Add VSCode as a context menu option, For file associations"
reg import "$HOME\scoop\apps\vscode\current\install-context.reg"
reg import "$HOME\scoop\apps\vscode\current\install-associations.reg"
Write-Done

Write-Start -msg "Add 7zip as a context menu option"
reg import "$HOME\scoop\apps\7zip\current\install-context.reg"
Write-Done

Write-Start -msg "Enable UTC Time"
Start-Process -Wait powershell -verb runas -ArgumentList "reg import '$PSScriptRoot\assets\regs\WinUTCOn.reg'"
Write-Done

Write-Start -msg "Installing Evkey"
If (Test-Path -Path $evKeyexeFile -PathType Leaf) {
    Write-Warning "Evkey installed"
    Start-Process $evKeyexeFile
}
Else {
    # if (Test-Path -Path $evkeyPathFolder) {
    #     Remove-Item -Path $evkeyPathFolder -Recurse -Include *.*
    # } 
    Write-Host "Downloading evkey"
    Invoke-WebRequest $evkeyLinkDownload -OutFile $evkeyPathFile
    Write-Host "Extracting evkey"
    Expand-Archive -Path $evkeyPathFile -DestinationPath $evkeyPathFolder -Force

    Write-Host "Setup config evkey"
    If (Test-Path -Path $evkeyPathFolder) {
        Copy-Item $evkeyConfigFile -Destination $evkeyPathFolder -Force
        Start-Process $evKeyexeFile
    }

    Write-Host "Delete evkey.zip"
    If (Test-Path -Path $evkeyPathFile -PathType Leaf) {
        Remove-Item -Path $evkeyPathFile 
    } 
}
Write-Done

Write-Start -msg "Setup config Windows terminal"
If (Test-Path $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe) {
    If (test-path "$pathConfigWindowTerminal\settings.json") {
    }
    Else {
        Copy-Item $pathFileConfigWindowTerminal -Destination $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState -Force
    }
}
Else {
    Write-Start -msg "Installing windows-terminal"
    scoop install extras/windows-terminal
    Write-Done

    If (test-path "$pathConfigWindowTerminal") {
        Copy-Item $pathFileConfigWindowTerminal -Destination $pathConfigWindowTerminal -Force
    }
    Else {
    }
}
Write-Done

Write-Start -msg "Enable show hidden files"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
Write-Done

Write-Start -msg "Enable show extension files"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Write-Done


Write-Start -msg "Enable Virtualization"
Start-Process -Wait powershell -Verb runas -ArgumentList @"
    echo y | Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    echo y | Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
    echo y | Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
    echo y | Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
"@
Write-Done

# Write-Start -msg "Installing WSL..."
# wsl --set-default-version 2
# if (-not (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State) {
#     wsl --install
#     wsl --update
#     wsl --install --no-launch --web-download -d Ubuntu
#     Write-Host "WSL installed"
# }
# else {
#     Write-Host "WSL already installed"
# }
# Write-Done



## End
Start-Process -Wait powershell -verb runas -ArgumentList "Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 2"