Clear-Host
$host.UI.RawUI.WindowTitle = "TeslaPro ScreenShare Tools"

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "2.1"
$closeDelaySeconds = 10

function Line {
    Write-Host "===============================================" -ForegroundColor Cyan
}

function TitleBox {
    Line
    Write-Host " TeslaPro ScreenShare Tools" -ForegroundColor Green
    Write-Host " Versie $version" -ForegroundColor DarkGray
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
    Write-Host ("`r{0} klaar.   " -f $Text) -ForegroundColor DarkGray
}

function Exit-OnError {
    Write-Host ""
    Read-Host "Druk op Enter om af te sluiten"
    exit
}

function Show-CloseCountdown {
    Write-Host ""
    $frames = @('|','/','-','\')
    for ($remaining = $closeDelaySeconds; $remaining -ge 1; $remaining--) {
        for ($j = 0; $j -lt 8; $j++) {
            $frame = $frames[$j % $frames.Count]
            Write-Host -NoNewline ("`rVenster sluit automatisch over {0} seconden... {1}" -f $remaining, $frame) -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 125
        }
    }
    Write-Host "`rVenster wordt gesloten...                             " -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 400
    exit
}

TitleBox

Step 1 4 "Systeemcheck"
Show-Spinner "Systeemcheck uitvoeren" 2

try {
    if ($env:OS -ne "Windows_NT") {
        throw "Dit script werkt alleen op Windows."
    }
    Ok "Windows gedetecteerd"
    Info "Alleen voor Windows."

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell versie te oud. Minimaal versie 5 vereist."
    }
    Ok ("PowerShell versie OK ({0})" -f $PSVersionTable.PSVersion.ToString())

    if (!(Test-Path $downloads)) {
        throw "Downloads-map bestaat niet."
    }
    Ok "Downloads-map bestaat"

    $testFile = Join-Path $downloads "teslapro_write_test.tmp"
    "test" | Out-File $testFile -Force
    Remove-Item $testFile -Force
    Ok "Schrijfrechten OK"

    $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
    $drive = Get-PSDrive -Name $driveName
    if ($drive.Free -lt 100MB) {
        throw "Onvoldoende vrije schijfruimte. Minimaal 100 MB nodig."
    }
    Ok ("Vrije schijfruimte OK ({0:N2} GB vrij)" -f ($drive.Free / 1GB))

    Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null
    Ok "Internetverbinding OK"
    Ok "GitHub bereikbaar"

    Info "Administrator niet vereist."
}
catch {
    Fail "Systeemcheck mislukt"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-OnError
}

Write-Host ""

if (Test-Path $dest) {
    Write-Host "[!] Bestaande installatie gevonden" -ForegroundColor Magenta
    $choice = Read-Host "Wil je overschrijven? (j/n)"
    if ($choice -ne "j") {
        Fail "Installatie geannuleerd"
        Exit-OnError
    }
    Ok "Bestaande installatie wordt overschreven"
    Write-Host ""
}

Step 2 4 "Downloaden"
Show-Spinner "Download voorbereiden" 1

try {
    if (Test-Path $zip) {
        Remove-Item $zip -Force
    }

    $ProgressPreference = "Continue"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip

    if (!(Test-Path $zip)) {
        throw "ZIP bestand niet gevonden na download."
    }

    $zipSize = (Get-Item $zip).Length
    if ($zipSize -lt 1000) {
        throw "ZIP is leeg of beschadigd."
    }

    Ok "Download voltooid"
    Write-Host ("Gedownload: {0:N2} MB" -f ($zipSize / 1MB)) -ForegroundColor DarkGray
}
catch {
    Fail "Download mislukt"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-OnError
}

Write-Host ""

Step 3 4 "Uitpakken"
Show-Spinner "Uitpakken voorbereiden" 1

try {
    if (Test-Path $dest) {
        Remove-Item $dest -Recurse -Force
    }

    New-Item -ItemType Directory -Path $dest | Out-Null
    Expand-Archive -Path $zip -DestinationPath $dest -Force

    $items = Get-ChildItem -Path $dest -Recurse -Force
    $count = ($items | Measure-Object).Count
    if ($count -eq 0) {
        throw "De uitgepakte map is leeg."
    }

    Ok "Uitpakken voltooid"
    Write-Host ("Uitgepakte bestanden: {0}" -f $count) -ForegroundColor DarkGray

    if (Test-Path $zip) {
        Remove-Item $zip -Force
        Ok "Tijdelijke ZIP verwijderd"
    }
}
catch {
    Fail "Uitpakken mislukt"
    Write-Host $_.Exception.Message -ForegroundColor DarkGray
    Exit-OnError
}

Write-Host ""

$tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe | Sort-Object Name
$toolCount = ($tools | Measure-Object).Count

if ($toolCount -gt 0) {
    Ok ("Tools gevonden: {0}" -f $toolCount)
    foreach ($tool in $tools) {
        Write-Host (" - " + $tool.Name) -ForegroundColor White
    }
} else {
    Fail "Geen .exe tools gevonden"
}

Write-Host ""

Step 4 4 "Klaar"
Line
Write-Host " Installatie voltooid" -ForegroundColor Green
Line
Write-Host "Bestanden staan in:" -ForegroundColor Cyan
Write-Host $dest -ForegroundColor White
Write-Host ""

try {
    Start-Process $dest
    Ok "Map automatisch geopend"
}
catch {
    Fail "Kon de map niet automatisch openen"
}

Write-Host ""
Info "De tools staan klaar."
Info ("Dit venster sluit automatisch over {0} seconden." -f $closeDelaySeconds)

Show-CloseCountdown