Clear-Host
$Host.UI.RawUI.WindowTitle = "TeslaPro's SS Tools Downloader"

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "2.1"

# =========================
# UI / DESIGN HELPERS
# =========================
function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║                                                                      ║" -ForegroundColor DarkCyan
    Write-Host "║   ████████╗███████╗███████╗██╗      █████╗ ██████╗ ██████╗  ██████╗  ║" -ForegroundColor Cyan
    Write-Host "║   ╚══██╔══╝██╔════╝██╔════╝██║     ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗ ║" -ForegroundColor Cyan
    Write-Host "║      ██║   █████╗  ███████╗██║     ███████║██████╔╝██████╔╝██║   ██║ ║" -ForegroundColor Cyan
    Write-Host "║      ██║   ██╔══╝  ╚════██║██║     ██╔══██║██╔═══╝ ██╔══██╗██║   ██║ ║" -ForegroundColor Cyan
    Write-Host "║      ██║   ███████╗███████║███████╗██║  ██║██║     ██║  ██║╚██████╔╝ ║" -ForegroundColor Cyan
    Write-Host "║      ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝  ║" -ForegroundColor Cyan
    Write-Host "║                                                                      ║" -ForegroundColor DarkCyan
    Write-Host "║                 ScreenShare Tools Installer                          ║" -ForegroundColor White
    Write-Host "║                 Professional Setup Utility v$version                       ║" -ForegroundColor DarkGray
    Write-Host "║                                                                      ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "┌──────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host ("│  " + $Text.PadRight(66) + "│") -ForegroundColor White
    Write-Host "└──────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
}

function Write-Step {
    param(
        [int]$Number,
        [int]$Total,
        [string]$Text
    )
    Write-Host ""
    Write-Host ("[" + $Number + "/" + $Total + "] ") -NoNewline -ForegroundColor Yellow
    Write-Host $Text -ForegroundColor White
}

function Write-Status {
    param(
        [ValidateSet("OK","FAIL","INFO","WARN")]
        [string]$Type,
        [string]$Text
    )

    switch ($Type) {
        "OK" {
            Write-Host "[ OK ] " -NoNewline -ForegroundColor Black -BackgroundColor Green
            Write-Host " $Text" -ForegroundColor Green
        }
        "FAIL" {
            Write-Host "[FAIL] " -NoNewline -ForegroundColor White -BackgroundColor Red
            Write-Host " $Text" -ForegroundColor Red
        }
        "INFO" {
            Write-Host "[INFO] " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
            Write-Host " $Text" -ForegroundColor Gray
        }
        "WARN" {
            Write-Host "[WARN] " -NoNewline -ForegroundColor Black -BackgroundColor Yellow
            Write-Host " $Text" -ForegroundColor Yellow
        }
    }
}

function Write-Menu {
    Write-Section "Select an Action"
    Write-Host "  [1] Install / Update TeslaPro SS Tools" -ForegroundColor Cyan
    Write-Host "  [2] Remove Installed Tools" -ForegroundColor Red
    Write-Host "  [3] Exit" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Spinner {
    param(
        [string]$Text,
        [int]$Seconds = 2
    )

    $frames = @("⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏")
    $end = (Get-Date).AddSeconds($Seconds)
    $i = 0

    while ((Get-Date) -lt $end) {
        $frame = $frames[$i % $frames.Count]
        Write-Host -NoNewline ("`r{0} {1}" -f $frame, $Text) -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 100
        $i++
    }

    Write-Host ("`r✓ {0}" -f $Text.PadRight(60)) -ForegroundColor DarkGray
}

function Pause-AndExit {
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

function Remove-TeslaProTools {
    Write-Banner
    Write-Section "Remove TeslaPro SS Tools"

    if (!(Test-Path $dest)) {
        Write-Status FAIL "No existing installation was found."
        return
    }

    Write-Status WARN "This will permanently remove the installed tools."
    Write-Host ""
    $confirm = Read-Host "Type DELETE to confirm removal"

    if ($confirm -ne "DELETE") {
        Write-Status FAIL "Removal cancelled by user."
        return
    }

    try {
        Remove-Item $dest -Recurse -Force -ErrorAction Stop

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
        }

        Write-Status OK "TeslaPro SS Tools have been removed successfully."
    }
    catch {
        Write-Status FAIL "Removal failed."
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
    }
}

# =========================
# MAIN
# =========================
Write-Banner
Write-Menu

$choice = Read-Host "Enter your choice"

switch ($choice) {
    "1" { }
    "2" {
        Remove-TeslaProTools
        Pause-AndExit
    }
    default {
        Write-Status INFO "No action selected. Exiting."
        exit
    }
}

# Step 1 - System Check
Write-Step 1 4 "Running system diagnostics"
Show-Spinner "Checking environment"

try {
    if ($env:OS -ne "Windows_NT") {
        throw "This installer only supports Windows."
    }
    Write-Status OK "Windows environment detected."

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or newer is required."
    }
    Write-Status OK ("PowerShell version verified: " + $PSVersionTable.PSVersion.ToString())

    if (!(Test-Path $downloads)) {
        throw "The Downloads folder could not be found."
    }
    Write-Status OK "Downloads folder is available."

    $testFile = Join-Path $downloads "teslapro_write_test.tmp"
    "test" | Out-File $testFile -Force
    Remove-Item $testFile -Force
    Write-Status OK "Write permissions confirmed."

    $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
    $drive = Get-PSDrive -Name $driveName
    if ($drive.Free -lt 100MB) {
        throw "Not enough free disk space. At least 100 MB is required."
    }
    Write-Status OK ("Free disk space available: {0:N2} GB" -f ($drive.Free / 1GB))

    Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null
    Write-Status OK "Internet connection is active."
    Write-Status OK "GitHub is reachable."

    Write-Status INFO "Administrator privileges are not required."
}
catch {
    Write-Status FAIL "System diagnostics failed."
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Pause-AndExit
}

# Existing install check
if (Test-Path $dest) {
    Write-Host ""
    Write-Status WARN "Existing installation detected."
    $overwrite = Read-Host "Do you want to overwrite the current installation? (y/n)"
    if ($overwrite -ne "y") {
        Write-Status FAIL "Installation cancelled by user."
        Pause-AndExit
    }
    Write-Status OK "Existing installation will be replaced."
}

# Step 2 - Download
Write-Step 2 4 "Downloading package"
Show-Spinner "Preparing secure download"

try {
    if (Test-Path $zip) {
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
    }

    $ProgressPreference = "Continue"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip

    if (!(Test-Path $zip)) {
        throw "The ZIP file was not created after download."
    }

    $zipSize = (Get-Item $zip).Length
    if ($zipSize -lt 1000) {
        throw "The downloaded ZIP appears to be invalid or corrupted."
    }

    Write-Status OK "Download completed successfully."
    Write-Status INFO ("Downloaded size: {0:N2} MB" -f ($zipSize / 1MB))
}
catch {
    Write-Status FAIL "Download failed."
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Pause-AndExit
}

# Step 3 - Extract
Write-Step 3 4 "Extracting files"
Show-Spinner "Unpacking archive"

try {
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
    }

    New-Item -ItemType Directory -Path $dest | Out-Null
    Expand-Archive -Path $zip -DestinationPath $dest -Force

    $items = Get-ChildItem -Path $dest -Recurse -Force
    $count = ($items | Measure-Object).Count
    if ($count -eq 0) {
        throw "Extraction failed because the destination folder is empty."
    }

    Write-Status OK "Extraction completed successfully."
    Write-Status INFO ("Extracted items: {0}" -f $count)

    if (Test-Path $zip) {
        Remove-Item $zip -Force
        Write-Status OK "Temporary ZIP file removed."
    }
}
catch {
    Write-Status FAIL "Extraction failed."
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Pause-AndExit
}

# Tool scan
Write-Host ""
$tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe | Sort-Object Name
$toolCount = ($tools | Measure-Object).Count

if ($toolCount -gt 0) {
    Write-Status OK ("Executable tools detected: {0}" -f $toolCount)
    Write-Host ""
    foreach ($tool in $tools) {
        Write-Host ("   • " + $tool.Name) -ForegroundColor White
    }
}
else {
    Write-Status WARN "No .exe files were found in the extracted package."
}

# Step 4 - Finish
Write-Step 4 4 "Installation complete"
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                         INSTALLATION COMPLETE                       ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Status OK "TeslaPro SS Tools are ready to use."
Write-Status INFO ("Installed location: " + $dest)

try {
    Start-Process $dest
    Write-Status OK "Installation folder opened automatically."
}
catch {
    Write-Status WARN "The installation folder could not be opened automatically."
}

Write-Host ""
Read-Host "Press Enter to exit"