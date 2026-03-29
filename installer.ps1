Clear-Host
$host.UI.RawUI.WindowTitle = "TeslaPro ScreenShare Tools"

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "2.1"

function Line {
    Write-Host "===============================================" -ForegroundColor Cyan
}

function TitleBox {
    Line
    Write-Host " TeslaPro ScreenShare Tools" -ForegroundColor Green
    Write-Host " Version $version" -ForegroundColor DarkGray
    Line
    Write-Host ""
}

function Step {
    param(
        [int]$Number,
        [int]$Total,
        [string]$Text
    )
    Write-Host ("[{0}/{1}] {2}" -f $Number, $Total, $Text) -ForegroundColor Yellow
}

function Ok {
    param([string]$Text)
    Write-Host ("[✓] {0}" -f $Text) -ForegroundColor Green
}

function Fail {
    param([string]$Text)
    Write-Host ("[X] {0}" -f $Text) -ForegroundColor Red
}

function Info {
    param([string]$Text)
    Write-Host $Text -ForegroundColor DarkGray
}

function Show-Spinner {
    param(
        [string]$Text,
        [int]$Seconds = 2
    )
    $frames = @('|','/','-','\')
    $end = (Get-Date).AddSeconds($Seconds)
    $i = 0
    while ((Get-Date) -lt $end) {
        $frame = $frames[$i % $frames.Count]
        Write-Host -NoNewline ("`r{0} {1}" -f $Text, $frame) -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 125
        $i++
    }
    Write-Host ("`r{0} done.   " -f $Text) -ForegroundColor DarkGray
}

function Exit-OnError {
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

function Remove-TeslaProTools {
    Write-Host ""
    Line
    Write-Host " Remove TeslaPro Tools" -ForegroundColor Red
    Line
    Write-Host ""

    if (!(Test-Path $dest)) {
        Fail "No existing installation found"
        return
    }

    try {
        $confirm = Read-Host "Type DELETE to permanently remove all installed TeslaPro tools"
        if ($confirm -ne "DELETE") {
            Fail "Removal cancelled"
            return
        }

        Remove-Item $dest -Recurse -Force

        if (Test-Path $zip) {
            Remove-Item $zip -Force
        }

        Ok "All TeslaPro tools have been removed from this system"
    }
    catch {
        Fail "Removal failed"
        Write-Host $_.Exception.Message -ForegroundColor DarkGray
    }
}

TitleBox

Write-Host "Type INSTALL to install/update the tools." -ForegroundColor Cyan
Write-Host "Type DELETE to remove all installed tools." -ForegroundColor Cyan
Write-Host "Type anything else to exit." -ForegroundColor Cyan
Write-Host ""

$action = Read-Host "Enter your choice"

switch ($action.ToUpper()) {
    "DELETE" {
        Remove-TeslaProTools
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit
    }
    "INSTALL" {
        # continue below
    }
    default {
        Info "No action selected. Exiting."
        exit
    }
}

Step 1 4 "System check"
Show-Spinner "Running system check" 2

try {
    if ($env:OS -ne "Windows_NT") {
        throw "This script only works on Windows."
    }
    Ok "Windows detected"
    Info "Windows only."

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell version is too old. Version 5 or higher is required."
    }
    Ok ("PowerShell version OK ({0})" -f $PSVersionTable.PSVersion.ToString())

    if (!(Test-Path $downloads)) {
        throw "Downloads folder does not exist."
    }
    Ok "Downloads folder exists"

    $testFile = Join-Path $downloads "teslapro_write_test.tmp"
    "test" | Out-File $testFile -Force
    Remove-Item $testFile -Force
    Ok "Write permissions OK"

    $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
    $drive = Get-PSDrive -Name $driveName
    if ($drive.Free -lt 100MB) {
        throw "Not enough free disk space. At least 100 MB is required."
    }
    Ok ("Free disk space OK ({0:N2} GB free)" -f ($drive.Free / 1GB))

    Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null
    Ok "Internet connection OK"
    Ok "GitHub reachable"

    Info "Administrator rights are not required."
}
catch {
    Fail "System check failed"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-OnError
}

Write-Host ""

if (Test-Path $dest) {
    Write-Host "[!] Existing installation found" -ForegroundColor Magenta
    $choice = Read-Host "Do you want to overwrite it? (y/n)"
    if ($choice -ne "y") {
        Fail "Installation cancelled"
        Exit-OnError
    }
    Ok "Existing installation will be overwritten"
    Write-Host ""
}

Step 2 4 "Downloading"
Show-Spinner "Preparing download" 1

try {
    if (Test-Path $zip) {
        Remove-Item $zip -Force
    }

    $ProgressPreference = "Continue"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip

    if (!(Test-Path $zip)) {
        throw "ZIP file not found after download."
    }

    $zipSize = (Get-Item $zip).Length
    if ($zipSize -lt 1000) {
        throw "ZIP is empty or corrupted."
    }

    Ok "Download completed"
    Write-Host ("Downloaded: {0:N2} MB" -f ($zipSize / 1MB)) -ForegroundColor DarkGray
}
catch {
    Fail "Download failed"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-OnError
}

Write-Host ""

Step 3 4 "Extracting"
Show-Spinner "Preparing extraction" 1

try {
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
    }

    New-Item -ItemType Directory -Path $dest | Out-Null
    Expand-Archive -Path $zip -DestinationPath $dest -Force

    $items = Get-ChildItem -Path $dest -Recurse -Force
    $count = ($items | Measure-Object).Count
    if ($count -eq 0) {
        throw "The extracted folder is empty."
    }

    Ok "Extraction completed"
    Write-Host ("Extracted files: {0}" -f $count) -ForegroundColor DarkGray

    if (Test-Path $zip) {
        Remove-Item $zip -Force
        Ok "Temporary ZIP removed"
    }
}
catch {
    Fail "Extraction failed"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-OnError
}

Write-Host ""

$tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe | Sort-Object Name
$toolCount = ($tools | Measure-Object).Count

if ($toolCount -gt 0) {
    Ok ("Tools found: {0}" -f $toolCount)
    foreach ($tool in $tools) {
        Write-Host (" - " + $tool.Name) -ForegroundColor White
    }
} else {
    Fail "No .exe tools found"
}

Write-Host ""

Step 4 4 "Finished"
Line
Write-Host " Installation completed" -ForegroundColor Green
Line
Write-Host "Files are located in:" -ForegroundColor Cyan
Write-Host $dest -ForegroundColor White
Write-Host ""

try {
    Start-Process $dest
    Ok "Folder opened automatically"
}
catch {
    Fail "Could not open the folder automatically"
}

Write-Host ""
Info "The tools are ready."
Write-Host ""
Read-Host "Press Enter to exit"