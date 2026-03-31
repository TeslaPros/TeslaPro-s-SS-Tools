Clear-Host
$Host.UI.RawUI.WindowTitle = "TeslaPro's SS Tools Downloader"

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "2.2"

# =========================
# THEME
# =========================
$script:ColorBorder = "DarkCyan"
$script:ColorAccent = "Cyan"
$script:ColorText   = "Gray"
$script:ColorDim    = "DarkGray"
$script:ColorOk     = "Green"
$script:ColorWarn   = "Yellow"
$script:ColorFail   = "Red"
$script:ColorTitle  = "White"

# =========================
# UI HELPERS
# =========================
function Draw-Background {
    $width = $Host.UI.RawUI.WindowSize.Width
    $height = [Math]::Min($Host.UI.RawUI.WindowSize.Height, 40)

    for ($i = 0; $i -lt $height; $i++) {
        $char = if ($i % 4 -eq 0) { "░" } elseif ($i % 2 -eq 0) { "▒" } else { " " }
        Write-Host ($char * $width) -ForegroundColor Black
    }
}

function Show-Screen {
    param(
        [string]$Subtitle = ""
    )

    Clear-Host
    Draw-Background
    [Console]::SetCursorPosition(0,0)

    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor $script:ColorBorder
    Write-Host "║                     TeslaPro's SS Tools Downloader                  ║" -ForegroundColor $script:ColorAccent
    Write-Host ("║                       Professional Installer v" + $version.PadRight(22) + "║") -ForegroundColor $script:ColorDim
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor $script:ColorBorder

    if ($Subtitle -ne "") {
        Write-Host ""
        Write-Host ("  " + $Subtitle) -ForegroundColor $script:ColorTitle
        Write-Host ""
    }
}

function Write-Panel {
    param([string]$Text)

    Write-Host "┌──────────────────────────────────────────────────────────────────────┐" -ForegroundColor $script:ColorBorder
    Write-Host ("│ " + $Text.PadRight(68) + "│") -ForegroundColor $script:ColorText
    Write-Host "└──────────────────────────────────────────────────────────────────────┘" -ForegroundColor $script:ColorBorder
}

function Write-Step {
    param(
        [int]$Number,
        [int]$Total,
        [string]$Text
    )

    Write-Host ""
    Write-Host ("[" + $Number + "/" + $Total + "] ") -NoNewline -ForegroundColor $script:ColorAccent
    Write-Host $Text -ForegroundColor $script:ColorTitle
}

function Write-Status {
    param(
        [ValidateSet("OK","FAIL","WARN","INFO")]
        [string]$Type,
        [string]$Text
    )

    switch ($Type) {
        "OK" {
            Write-Host "  [✓] " -NoNewline -ForegroundColor $script:ColorOk
            Write-Host $Text -ForegroundColor $script:ColorText
        }
        "FAIL" {
            Write-Host "  [X] " -NoNewline -ForegroundColor $script:ColorFail
            Write-Host $Text -ForegroundColor $script:ColorText
        }
        "WARN" {
            Write-Host "  [!] " -NoNewline -ForegroundColor $script:ColorWarn
            Write-Host $Text -ForegroundColor $script:ColorText
        }
        "INFO" {
            Write-Host "  [•] " -NoNewline -ForegroundColor $script:ColorAccent
            Write-Host $Text -ForegroundColor $script:ColorDim
        }
    }
}

function Show-Spinner {
    param(
        [string]$Text,
        [int]$Seconds = 2
    )

    $frames = @("⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏")
    $end = (Get-Date).AddSeconds($Seconds)
    $i = 0

    Write-Host ""
    while ((Get-Date) -lt $end) {
        $frame = $frames[$i % $frames.Count]
        Write-Host -NoNewline ("`r  " + $frame + " " + $Text + "   ") -ForegroundColor $script:ColorDim
        Start-Sleep -Milliseconds 90
        $i++
    }
    Write-Host ("`r  ✓ " + $Text + " completed.                     ") -ForegroundColor $script:ColorDim
}

function Pause-AndExit {
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

function Pause-Return {
    Write-Host ""
    Read-Host "Press Enter to return to menu"
}

# =========================
# ACTIONS
# =========================
function Remove-TeslaProTools {
    Show-Screen "Remove Installed Tools"
    Write-Panel "This action permanently removes TeslaPro SS Tools from your Downloads folder."
    Write-Host ""

    if (!(Test-Path $dest)) {
        Write-Status FAIL "No existing installation found."
        Pause-Return
        return
    }

    Write-Status WARN "Installed files were detected."
    Write-Status INFO ("Location: " + $dest)
    Write-Host ""

    $confirm = Read-Host "Type DELETE to confirm removal"
    if ($confirm -ne "DELETE") {
        Write-Status FAIL "Removal cancelled."
        Pause-Return
        return
    }

    try {
        Show-Screen "Removing TeslaPro SS Tools"
        Show-Spinner "Removing installed files" 1

        Remove-Item $dest -Recurse -Force -ErrorAction Stop

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
        }

        Write-Host ""
        Write-Status OK "TeslaPro SS Tools were removed successfully."
    }
    catch {
        Write-Host ""
        Write-Status FAIL "Removal failed."
        Write-Status INFO $_.Exception.Message
    }

    Pause-Return
}

function Run-Installer {
    Show-Screen "System Check"
    Write-Step 1 4 "Running system diagnostics"
    Show-Spinner "Checking environment" 1

    try {
        if ($env:OS -ne "Windows_NT") {
            throw "This installer only supports Windows."
        }
        Write-Status OK "Windows environment detected."

        if ($PSVersionTable.PSVersion.Major -lt 5) {
            throw "PowerShell 5.0 or higher is required."
        }
        Write-Status OK ("PowerShell version: " + $PSVersionTable.PSVersion.ToString())

        if (!(Test-Path $downloads)) {
            throw "Downloads folder was not found."
        }
        Write-Status OK "Downloads folder is available."

        $testFile = Join-Path $downloads "teslapro_write_test.tmp"
        "test" | Out-File $testFile -Force
        Remove-Item $testFile -Force
        Write-Status OK "Write permission confirmed."

        $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
        $drive = Get-PSDrive -Name $driveName
        if ($drive.Free -lt 100MB) {
            throw "Not enough free disk space. At least 100 MB is required."
        }
        Write-Status OK ("Free space: {0:N2} GB" -f ($drive.Free / 1GB))

        Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null
        Write-Status OK "Internet connection is working."
        Write-Status INFO "Administrator rights are not required."
    }
    catch {
        Write-Host ""
        Write-Status FAIL "System check failed."
        Write-Status INFO $_.Exception.Message
        Pause-AndExit
    }

    if (Test-Path $dest) {
        Write-Host ""
        Write-Status WARN "Existing installation found."
        $overwrite = Read-Host "Overwrite current installation? (y/n)"
        if ($overwrite -ne "y") {
            Write-Status FAIL "Installation cancelled."
            Pause-AndExit
        }
    }

    Show-Screen "Download Package"
    Write-Step 2 4 "Downloading latest release"
    Show-Spinner "Preparing download" 1

    try {
        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
        }

        $ProgressPreference = "Continue"
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip

        if (!(Test-Path $zip)) {
            throw "ZIP file was not created."
        }

        $zipSize = (Get-Item $zip).Length
        if ($zipSize -lt 1000) {
            throw "Downloaded ZIP appears invalid or corrupted."
        }

        Write-Host ""
        Write-Status OK "Download completed successfully."
        Write-Status INFO ("Downloaded size: {0:N2} MB" -f ($zipSize / 1MB))
    }
    catch {
        Write-Host ""
        Write-Status FAIL "Download failed."
        Write-Status INFO $_.Exception.Message
        Pause-AndExit
    }

    Show-Screen "Extract Files"
    Write-Step 3 4 "Installing package"
    Show-Spinner "Extracting archive" 1

    try {
        if (Test-Path $dest) {
            Remove-Item $dest -Recurse -Force
        }

        New-Item -ItemType Directory -Path $dest | Out-Null
        Expand-Archive -Path $zip -DestinationPath $dest -Force

        $items = Get-ChildItem -Path $dest -Recurse -Force
        $count = ($items | Measure-Object).Count
        if ($count -eq 0) {
            throw "Extraction failed because the folder is empty."
        }

        Write-Host ""
        Write-Status OK "Extraction completed successfully."
        Write-Status INFO ("Extracted items: " + $count)

        if (Test-Path $zip) {
            Remove-Item $zip -Force
            Write-Status OK "Temporary ZIP removed."
        }
    }
    catch {
        Write-Host ""
        Write-Status FAIL "Extraction failed."
        Write-Status INFO $_.Exception.Message
        Pause-AndExit
    }

    Show-Screen "Installation Complete"
    Write-Step 4 4 "Finished"

    $tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe | Sort-Object Name
    $toolCount = ($tools | Measure-Object).Count

    Write-Host ""
    Write-Panel "TeslaPro SS Tools have been installed successfully."
    Write-Host ""

    Write-Status OK ("Installed location: " + $dest)

    if ($toolCount -gt 0) {
        Write-Status OK ("Executable files found: " + $toolCount)
        Write-Host ""
        foreach ($tool in $tools) {
            Write-Host ("   • " + $tool.Name) -ForegroundColor $script:ColorText
        }
    }
    else {
        Write-Status WARN "No .exe files were found in the extracted package."
    }

    try {
        Start-Process $dest
        Write-Host ""
        Write-Status OK "Installation folder opened automatically."
    }
    catch {
        Write-Host ""
        Write-Status WARN "Could not open the installation folder automatically."
    }

    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

# =========================
# MAIN MENU LOOP
# =========================
while ($true) {
    Show-Screen "Main Menu"
    Write-Panel "Choose an option below"
    Write-Host ""
    Write-Host "  [1] Install / Update TeslaPro SS Tools" -ForegroundColor $script:ColorAccent
    Write-Host "  [2] Remove Installed Tools" -ForegroundColor $script:ColorWarn
    Write-Host "  [3] Exit" -ForegroundColor $script:ColorDim
    Write-Host ""

    $choice = Read-Host "Enter your choice"

    switch ($choice) {
        "1" { Run-Installer }
        "2" { Remove-TeslaProTools }
        "3" { exit }
        default {
            Write-Host ""
            Write-Status FAIL "Invalid selection."
            Start-Sleep -Seconds 1
        }
    }
}