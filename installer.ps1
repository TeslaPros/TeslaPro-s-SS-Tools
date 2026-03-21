Clear-Host
$host.UI.RawUI.WindowTitle = "TeslaPro ScreenShare Tools"

$userDir = [Environment]::GetFolderPath("UserProfile")
$url  = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip  = Join-Path $userDir "Downloads\SS.TeslaPro.zip"
$dest = Join-Path $userDir "Downloads\TeslaPro-Tools"

function Line {
    Write-Host "=====================================" -ForegroundColor Cyan
}

function Step($text) {
    Write-Host "[*] $text" -ForegroundColor Yellow
}

function Ok($text) {
    Write-Host "[✓] $text" -ForegroundColor Green
}

function Fail($text) {
    Write-Host "[X] $text" -ForegroundColor Red
}

Line
Write-Host " TeslaPro ScreenShare Tools" -ForegroundColor Green
Line
Write-Host ""

# ========================
# DOWNLOAD
# ========================
Step "Downloaden..."

try {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip

    if (!(Test-Path $zip)) {
        throw "ZIP bestand niet gevonden."
    }

    if ((Get-Item $zip).Length -lt 1000) {
        throw "ZIP is beschadigd of leeg."
    }

    Ok "Download voltooid"
}
catch {
    Fail "Download mislukt"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Read-Host "Druk op Enter om af te sluiten"
    exit
}

Write-Host ""

# ========================
# UITPAKKEN
# ========================
Step "Uitpakken..."

try {
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
    }

    New-Item -ItemType Directory -Path $dest | Out-Null
    Expand-Archive -Path $zip -DestinationPath $dest -Force

    $count = (Get-ChildItem -Path $dest -Recurse | Measure-Object).Count

    if ($count -eq 0) {
        throw "Map is leeg na uitpakken."
    }

    Ok "Uitpakken voltooid"
}
catch {
    Fail "Uitpakken mislukt"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Read-Host "Druk op Enter om af te sluiten"
    exit
}

Write-Host ""

# ========================
# KLAAR
# ========================
Line
Write-Host " Klaar!" -ForegroundColor Green
Write-Host "Bestanden staan in:" -ForegroundColor Cyan
Write-Host $dest -ForegroundColor White
Line

Write-Host ""
Read-Host "Druk op Enter om af te sluiten"		