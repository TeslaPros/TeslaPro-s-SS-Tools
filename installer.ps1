Clear-Host
$host.UI.RawUI.WindowTitle = "TeslaPro ScreenShare Tools"

$userDir = [Environment]::GetFolderPath("UserProfile")
$url     = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip     = Join-Path $userDir "Downloads\SS.TeslaPro.zip"
$dest    = Join-Path $userDir "Downloads\TeslaPro-Tools"
$version = "1.1"

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

function Exit-Nicely {
    Write-Host ""
    Read-Host "Druk op Enter om af te sluiten"
    exit
}

Line
Write-Host " TeslaPro ScreenShare Tools" -ForegroundColor Green
Write-Host " Versie $version" -ForegroundColor DarkGray
Line
Write-Host ""

Step "Internetverbinding controleren..."
try {
    Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null
    Ok "GitHub is bereikbaar"
}
catch {
    Fail "GitHub is niet bereikbaar"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-Nicely
}

Write-Host ""

Step "Downloaden..."
try {
    if (Test-Path $zip) {
        Remove-Item $zip -Force
    }

    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
    $ProgressPreference = "Continue"

    if (!(Test-Path $zip)) {
        throw "ZIP bestand niet gevonden na download."
    }

    $zipSize = (Get-Item $zip).Length
    if ($zipSize -lt 1000) {
        throw "ZIP is beschadigd of leeg."
    }

    Ok "Download voltooid"
    Write-Host ("Bestandsgrootte: {0:N2} MB" -f ($zipSize / 1MB)) -ForegroundColor DarkGray
}
catch {
    $ProgressPreference = "Continue"
    Fail "Download mislukt"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-Nicely
}

Write-Host ""

Step "Uitpakken..."
try {
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
    }

    New-Item -ItemType Directory -Path $dest | Out-Null
    Expand-Archive -Path $zip -DestinationPath $dest -Force

    $count = (Get-ChildItem -Path $dest -Recurse -Force | Measure-Object).Count
    if ($count -eq 0) {
        throw "Map is leeg na uitpakken."
    }

    Ok "Uitpakken voltooid"
    Write-Host "Aantal bestanden: $count" -ForegroundColor DarkGray
}
catch {
    Fail "Uitpakken mislukt"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-Nicely
}

Write-Host ""

Line
Write-Host " Klaar!" -ForegroundColor Green
Write-Host "Bestanden staan in:" -ForegroundColor Cyan
Write-Host $dest -ForegroundColor White
Line

Write-Host ""
Step "Map openen..."
try {
    Start-Process $dest
    Ok "Map geopend"
}
catch {
    Fail "Kon map niet automatisch openen"
}

Write-Host ""
Write-Host "Installatie voltooid." -ForegroundColor Green
Write-Host "De tools staan klaar in de map hierboven." -ForegroundColor DarkGray

Write-Host ""
Write-Host "Dit venster sluit automatisch over 10 seconden..." -ForegroundColor DarkGray

for ($i = 10; $i -ge 1; $i--) {
    Write-Host ("Sluiten over {0}..." -f $i) -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
}

exit		