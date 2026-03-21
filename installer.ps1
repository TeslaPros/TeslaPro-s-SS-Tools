Clear-Host
$host.UI.RawUI.WindowTitle = "TeslaPro ScreenShare Tools"

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$log       = Join-Path $downloads "TeslaPro_install_log.txt"
$version   = "2.0"

function Log($text){
    Add-Content -Path $log -Value ("[{0}] {1}" -f (Get-Date), $text)
}

function Line { Write-Host "=====================================" -ForegroundColor Cyan }
function Step($t){ Write-Host "[*] $t" -ForegroundColor Yellow; Log $t }
function Ok($t){ Write-Host "[✓] $t" -ForegroundColor Green; Log $t }
function Fail($t){ Write-Host "[X] $t" -ForegroundColor Red; Log $t }

function ExitError {
    Write-Host ""
    Read-Host "Druk op Enter om af te sluiten"
    exit
}

function ProgressBar($label,$start,$end){
    for($i=$start;$i -le $end;$i+=5){
        $bars=[int]($i/5)
        $bar=("█"* $bars).PadRight(20,"-")
        Write-Host -NoNewline ("`r{0} [{1}] {2}%" -f $label,$bar,$i) -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 40
    }
    Write-Host ""
}

Line
Write-Host " TeslaPro ScreenShare Tools" -ForegroundColor Green
Write-Host " Versie $version" -ForegroundColor DarkGray
Line
Write-Host ""

# ================= SYSTEM CHECK =================
Step "Systeemchecks..."

try{
    if($env:OS -ne "Windows_NT"){ throw "Alleen Windows ondersteund" }

    if($PSVersionTable.PSVersion.Major -lt 5){
        throw "PowerShell versie te oud (min v5 vereist)"
    }

    if(!(Test-Path $downloads)){
        throw "Downloads map niet gevonden"
    }

    $test = Join-Path $downloads "test.tmp"
    "ok" | Out-File $test -Force
    Remove-Item $test -Force

    $drive = Get-PSDrive -Name (Split-Path $downloads -Qualifier).Replace(":","")
    if($drive.Free -lt 100MB){
        throw "Minimaal 100MB vrije ruimte nodig"
    }

    Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null

    Ok "Systeem OK"
}
catch{
    Fail $_.Exception.Message
    ExitError
}

Write-Host ""

# ================= EXISTING INSTALL =================
if(Test-Path $dest){
    Step "Bestaande installatie gevonden"
    $choice = Read-Host "Overschrijven? (j/n)"
    if($choice -ne "j"){
        Fail "Installatie geannuleerd"
        ExitError
    }
}

# ================= DOWNLOAD =================
Step "Downloaden..."
try{
    if(Test-Path $zip){ Remove-Item $zip -Force }

    ProgressBar "Download starten" 0 30

    $ProgressPreference="SilentlyContinue"
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
    $ProgressPreference="Continue"

    ProgressBar "Download afronden" 35 100

    if(!(Test-Path $zip)){ throw "Download mislukt" }

    $size=(Get-Item $zip).Length
    if($size -lt 1000){ throw "ZIP corrupt" }

    Ok ("Download OK ({0:N2} MB)" -f ($size/1MB))
}
catch{
    Fail $_.Exception.Message
    ExitError
}

Write-Host ""

# ================= EXTRACT =================
Step "Uitpakken..."
try{
    ProgressBar "Voorbereiden" 0 30

    if(Test-Path $dest){ Remove-Item $dest -Recurse -Force }
    New-Item -ItemType Directory -Path $dest | Out-Null

    ProgressBar "Uitpakken" 30 70

    Expand-Archive -Path $zip -DestinationPath $dest -Force

    ProgressBar "Afronden" 70 100

    $count=(Get-ChildItem $dest -Recurse | Measure-Object).Count
    if($count -eq 0){ throw "Map leeg" }

    Ok "Uitpakken OK"
    Write-Host "Bestanden: $count" -ForegroundColor DarkGray
}
catch{
    Fail $_.Exception.Message
    ExitError
}

Write-Host ""

# ================= TOOL LIST =================
Step "Tools gevonden:"
$tools = Get-ChildItem $dest -Recurse -Filter *.exe

if($tools.Count -gt 0){
    foreach($t in $tools){
        Write-Host (" - " + $t.Name) -ForegroundColor White
    }
    Ok "Tools geladen"
}else{
    Fail "Geen tools gevonden"
}

Write-Host ""

# ================= OPEN FOLDER =================
Step "Map openen..."
try{
    Start-Process $dest
    Ok "Map geopend"
}catch{
    Fail "Kon map niet openen"
}

# ================= FINISH =================
Write-Host ""
Line
Write-Host " Klaar!" -ForegroundColor Green
Write-Host $dest -ForegroundColor Cyan
Line

Write-Host ""
Write-Host "Logbestand opgeslagen in Downloads" -ForegroundColor DarkGray

# ================= EXIT ANIMATION =================
$frames=@("|","/","-","\")
for($t=10;$t -ge 1;$t--){
    foreach($f in $frames){
        Write-Host -NoNewline ("`rSluit over $t sec... $f") -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 120
    }
}
Write-Host "`rSluiten..." -ForegroundColor DarkGray
Start-Sleep -Milliseconds 400
exit		