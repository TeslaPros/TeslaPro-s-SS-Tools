function Test-TeslaAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-TeslaScript {
    param([string]$Path, [switch]$AsAdmin)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $false
    }
    $escapedPath = $Path.Replace('"', '\"')
    $arguments = '-NoProfile -STA -ExecutionPolicy Bypass -File "' + $escapedPath + '"'
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = 'powershell.exe'
    $start.Arguments = $arguments
    $start.UseShellExecute = $true
    if ($AsAdmin) { $start.Verb = 'runas' }
    try {
        [System.Diagnostics.Process]::Start($start) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

$script:EntryPath = if ($PSCommandPath) { $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { $null }
$script:StartupWarnings = New-Object System.Collections.Generic.List[string]

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    if (Restart-TeslaScript -Path $script:EntryPath) { exit }
    Write-Error 'Tesla SS Tools must run in STA mode. Start it with: powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\installer.ps1'
    exit 1
}

if (-not (Test-TeslaAdministrator)) {
    if ($script:EntryPath -and (Restart-TeslaScript -Path $script:EntryPath -AsAdmin)) { exit }
    $script:StartupWarnings.Add('Tesla SS Tools is not running as administrator. Some external tools may require admin permissions.') | Out-Null
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AppName = 'Tesla SS Tools'
$AppVersion = '1.0'
$DiscordInvite = 'https://discord.gg/sFn5TvpAK6'
$DiscordTooltip = 'Join the Tesla SS Course Discord'

$ScriptRoot = if ($script:EntryPath) { Split-Path -Parent $script:EntryPath } else { $null }
$LocalAppDataRoot = if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { [System.IO.Path]::GetTempPath() } else { $env:LOCALAPPDATA }
$AppBaseRoot = if ($ScriptRoot) { $ScriptRoot } else { Join-Path $LocalAppDataRoot 'Tesla SS Tools' }
if ([string]::IsNullOrWhiteSpace($AppBaseRoot)) { $AppBaseRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'Tesla SS Tools' }
$AppRoot = Join-Path $AppBaseRoot 'teslatool'
$ToolsRoot = $AppRoot
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'Tesla SS Tools'

foreach ($dir in @($AppRoot, $ToolsRoot, $TempRoot)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

$Categories = @(
    [ordered]@{
        Key = 'orbdiff'
        Label = 'OrbDiff'
        Header = 'Tools developed by OrbDiff - github.com/orbdiff'
        Description = 'Prefetch, BAM, USN, memory, process, USB, and string forensic tools.'
    },
    [ordered]@{
        Key = 'spokwn'
        Label = 'Spokwn'
        Header = 'Tools developed by Spokwn - github.com/spokwn'
        Description = 'BAM, journal, activities cache, services, process, and path parsers.'
    },
    [ordered]@{
        Key = 'tonynoh'
        Label = 'Tonynoh'
        Header = 'Tools developed by Tonynoh - github.com/meowtonynoh'
        Description = 'Meow resolver, Doomsday finder, client scanner, and import checker.'
    },
    [ordered]@{
        Key = 'praiselily'
        Label = 'PraiseLily'
        Header = 'Tools developed by PraiseLily - github.com/praiselily'
        Description = 'PowerShell hunting, alt detection, hotspot, service, directory, and scheduled-task checks.'
    },
    [ordered]@{
        Key = 'redlotus'
        Label = 'RedLotus'
        Header = 'RedLotus tools by ItzIceHere and RedLotus contributors'
        Description = 'Mod analysis, scheduled-task monitoring, and alternate-account checking tools.'
    },
    [ordered]@{
        Key = 'detectac'
        Label = 'DetectAC'
        Header = 'Tools developed by DetectAC - detect.ac'
        Description = 'Detect.ac Free Tools for Windows forensic review and artifact analysis.'
    },
    [ordered]@{
        Key = 'scripts'
        Label = 'Scripts'
        Header = 'Useful PowerShell scripts for forensic analysis'
        Description = 'Original one-line script actions launched in a visible console window.'
    },
    [ordered]@{
        Key = 'nirsoft'
        Label = 'NirSoft'
        Header = 'NirSoft utilities - nirsoft.net'
        Description = 'Portable Windows event, USB, registry, shellbag, jump list, and prefetch utilities.'
    },
    [ordered]@{
        Key = 'ericzimmerman'
        Label = 'EricZimmerman'
        Header = 'Eric Zimmerman''s forensic tools - ericzimmerman.github.io'
        Description = 'Amcache, event log, jump list, registry, shellbag, SRUM, MFT, and timeline tools.'
    },
    [ordered]@{
        Key = 'others'
        Label = 'Others'
        Header = 'Various forensic tools from the community'
        Description = 'Community tools, decompilers, hex editors, file search, Java scanners, and supporting analyzers.'
    },
    [ordered]@{
        Key = 'dependencies'
        Label = 'Dependencies'
        Header = 'Required runtimes and dependencies'
        Description = '.NET runtimes and Visual C++ Redistributable installers used by external tools.'
    }
)

$DownloadTools = @(
    [ordered]@{
        Name = 'Prefetch View++'
        Description = 'Parses prefetch extracting file info'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.7/pv++.exe')
    },
    [ordered]@{
        Name = 'BAM Reveal'
        Description = 'Parses BAM forensic artefact'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/BAMReveal/releases/latest/download/BAMReveal.exe')
    },
    [ordered]@{
        Name = 'Amcache Parser'
        Description = 'Parses AMCache with YARA + signatures'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/AmcacheParser/releases/latest/download/AmcacheParser.exe')
    },
    [ordered]@{
        Name = 'Journal Parser'
        Description = 'Parses NTFS USNJournal entries'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/JournalParser/releases/latest/download/JournalParser.exe')
    },
    [ordered]@{
        Name = 'Check Deleted USN'
        Description = 'Compares USN timestamp vs boot time'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/CheckDeletedUSN/releases/latest/download/CheckDeletedUSN.exe')
    },
    [ordered]@{
        Name = 'Fileless'
        Description = 'Detect fileless via eventlog + memdump'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/Fileless/releases/latest/download/fileless.exe')
    },
    [ordered]@{
        Name = 'JAR Parser'
        Description = 'Parses JAR prefetch, DcomLaunch strings, etc'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/JARParser/releases/latest/download/JARParser.exe')
    },
    [ordered]@{
        Name = 'PF Trace'
        Description = 'Rundll32/Regsvr32 prefetch analysis'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/PFTrace/releases/latest/download/PFTrace.exe')
    },
    [ordered]@{
        Name = 'InjGen'
        Description = 'Detects JNI/JVMTI memory injections'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/InjGen/releases/latest/download/InjGen.exe')
    },
    [ordered]@{
        Name = 'DPS Analyzer'
        Description = 'Analyzes DPS memory'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/DPS-Analyzer/releases/latest/download/dpsanalyzer.exe')
    },
    [ordered]@{
        Name = 'USB Detector'
        Description = 'Detects USB device history'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/USBDetector/releases/latest/download/USBDetector.exe')
    },
    [ordered]@{
        Name = 'User Assist View'
        Description = 'Parser UserAssist artifact'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/UserAssistView/releases/latest/download/UserAssistView.exe')
    },
    [ordered]@{
        Name = 'Strings Parser'
        Description = 'Strings + YARA + signatures scanner'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/StringsParser/releases/download/v1.2/stringsparser1.2b.exe')
    },
    [ordered]@{
        Name = 'Bam Check Restart'
        Description = 'Detect the date of creation of the BAM'
        Category = 'orbdiff'
        Kind = 'Download'
        Links = @('https://github.com/Orbdiff/BAM-CheckRestart/releases/download/v2.0.2/BAMCheckRestart.exe')
    },
    [ordered]@{
        Name = 'Activities Cache execution'
        Description = 'Gets the execution of files using the activitiescache.db'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/ActivitiesCache-execution/releases/download/v0.6.5/ActivitiesCacheParser.exe')
    },
    [ordered]@{
        Name = 'BAM Parser'
        Description = 'parses the BAM forensic artefact'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/BAM-parser/releases/download/v1.2.9/BAMParser.exe')
    },
    [ordered]@{
        Name = 'Bam Deleted Keys'
        Description = 'Gathers BAM deleted keys by comparing them with the hives keys.'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/BamDeletedKeys/releases/download/v1.0/BamDeletedKeys.exe')
    },
    [ordered]@{
        Name = 'Journal Trace'
        Description = 'Parses NTFS journal entries'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/JournalTrace/releases/download/1.2/JournalTrace.exe')
    },
    [ordered]@{
        Name = 'Pca Svc Executed'
        Description = 'pcasvc-executed is my fork of zack-srcs service-execution'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/pcasvc-executed/releases/download/v0.8.7/PcaSvcExecuted.exe')
    },
    [ordered]@{
        Name = 'Espouken Tool'
        Description = 'A lot of tools'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/Tool/releases/download/v1.1.3/espouken.exe')
    },
    [ordered]@{
        Name = 'Process Parser'
        Description = 'Parses processes using xxstrings'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/process-parser/releases/download/v0.5.5/ProcessParser.exe')
    },
    [ordered]@{
        Name = 'Paths Parser'
        Description = 'Parses info about paths on a .txt'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe')
    },
    [ordered]@{
        Name = 'Kernel Live Dump Tool'
        Description = 'Captures live kernel memory dumps'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/KernelLiveDumpTool/releases/latest')
    },
    [ordered]@{
        Name = 'Prefetch Parser'
        Description = 'Parses Windows prefetch files'
        Category = 'spokwn'
        Kind = 'Download'
        Links = @('https://github.com/spokwn/prefetch-parser/releases/latest')
    },
    [ordered]@{
        Name = 'Meow Resolver'
        Description = 'Detector and Resolver tool to detect some shitty bypasses'
        Category = 'tonynoh'
        Kind = 'Download'
        Links = @('https://github.com/MeowTonynoh/MeowResolver/releases/download/v.1.1/MeowResolver.exe')
    },
    [ordered]@{
        Name = 'Meow Doomsday Fucker'
        Description = 'Best Doomsday Finder '
        Category = 'tonynoh'
        Kind = 'Download'
        Links = @('https://github.com/MeowTonynoh/MeowDoomsdayFucker/releases/download/V.1.5/MeowDoomsdayFucker.exe')
    },
    [ordered]@{
        Name = 'Meow Client Fucker'
        Description = '2nd Best Scanner !'
        Category = 'tonynoh'
        Kind = 'Download'
        Links = @('https://github.com/MeowTonynoh/MeowClientFucker/releases/download/v1.0/MeowClientFucker.exe')
    },
    [ordered]@{
        Name = 'Meow Imports Checker'
        Description = 'The best file checker !'
        Category = 'tonynoh'
        Kind = 'Download'
        Links = @('https://github.com/MeowTonynoh/MeowImportsChecker/releases/download/MeowImportsChecker/MeowImportsChecker.exe')
    },
    [ordered]@{
        Name = 'Meow Novoware Fucker'
        Description = 'Detects Novoware cheat artifacts'
        Category = 'tonynoh'
        Kind = 'Download'
        Links = @('https://github.com/MeowTonynoh/MeowNovowareFucker/releases/latest')
    },
    [ordered]@{
        Name = 'PSHunter'
        Description = 'Hunts suspicious PowerShell activity'
        Category = 'praiselily'
        Kind = 'Download'
        Links = @('https://github.com/praiselily/PSHunter/releases/latest')
    },
    [ordered]@{
        Name = 'AltDetector'
        Description = 'Detects alternate account artifacts'
        Category = 'praiselily'
        Kind = 'Download'
        Links = @('https://github.com/praiselily/AltDetector/releases/latest')
    },
    [ordered]@{
        Name = 'RL ModAnalyzer'
        Description = 'Analyzes mod files for cheat indicators'
        Category = 'redlotus'
        Kind = 'Download'
        Links = @('https://github.com/ItzIceHere/RedLotus-Mod-Analyzer/releases/latest')
    },
    [ordered]@{
        Name = 'RL TaskSentinel'
        Description = 'Monitors scheduled tasks for anomalies'
        Category = 'redlotus'
        Kind = 'Download'
        Links = @('https://github.com/ItzIceHere/RedLotus-Task-Sentinel/releases/latest')
    },
    [ordered]@{
        Name = 'RL AltChecker'
        Description = 'Checks for alternate account indicators'
        Category = 'redlotus'
        Kind = 'Download'
        Links = @('https://github.com/ItzIceHere/RedLotusAltChecker/releases/latest')
    },
    [ordered]@{
        Name = 'Amcache Parser++'
        Description = 'High-performance Amcache parser with YARA + VirusTotal'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/AmcacheParser++.exe')
    },
    [ordered]@{
        Name = 'Autoruns++'
        Description = 'Rebuilt Autoruns alternative with USN monitoring and signature verification'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/Autoruns++.exe')
    },
    [ordered]@{
        Name = 'Bam Parser++'
        Description = 'BAM execution history with YARA engine and tamper detection'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/BamParser++.exe')
    },
    [ordered]@{
        Name = 'Browser Downloads View++'
        Description = 'Multi-browser download history with USN modification highlighting'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/BrowserDownloadsView++.exe')
    },
    [ordered]@{
        Name = 'Browsing History View++'
        Description = 'Multi-browser history with suspicious domain flagging + VT links'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/BrowsingHistoryView++.exe')
    },
    [ordered]@{
        Name = 'Crashed File Viewer++'
        Description = 'Unified view of Windows crash artifacts with USN highlighting'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/CrashedFileViewer++.exe')
    },
    [ordered]@{
        Name = 'Journal Trace++'
        Description = 'USN Journal analysis with bypass detections and filtering'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/JournalTrace++.exe')
    },
    [ordered]@{
        Name = 'Kernel Live Dump++'
        Description = 'Dumps Kernel/User-mode RAM with filterable string results'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/KernelLiveDump++.exe')
    },
    [ordered]@{
        Name = 'MFT Explorer++'
        Description = 'Defined $MFT view with suspicious ADS identification'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/MFTExplorer++.exe')
    },
    [ordered]@{
        Name = 'Paths Parser++'
        Description = 'Paths parser GUI with YARA support and a USN journal viewer'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/PathsParser++.exe')
    },
    [ordered]@{
        Name = 'PowerShell Parser++'
        Description = 'Scrapes PowerShell history artifacts with bypass detection'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/PowerShellParser++.exe')
    },
    [ordered]@{
        Name = 'Saved Files Viewer++'
        Description = 'Shows every file saved to disk with cross-referenced timestamps'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/SavedFilesViewer++.exe')
    },
    [ordered]@{
        Name = 'SRUM Explorer++'
        Description = 'Maps file paths and services from SRUM with YARA + USN tracking'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/SRUMExplorer++.exe')
    },
    [ordered]@{
        Name = 'String Explorer++'
        Description = 'Navigate an exe''s full string data, entropy, and VirusTotal integration'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/StringExplorer++.exe')
    },
    [ordered]@{
        Name = 'USB Deview++'
        Description = 'Aggregated USB device logs cross-referenced against DeviceHunt'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/USBDeview++.exe')
    },
    [ordered]@{
        Name = 'Win Prefetch View++'
        Description = 'WinPrefetchView with bypass detections and YARA rule support'
        Category = 'detectac'
        Kind = 'Download'
        Links = @('https://github.com/detect-ac/Detect.ac-Free-Tools/releases/download/FreeTools/WinPrefetchView++.exe')
    },
    [ordered]@{
        Name = 'Full Event Log View'
        Description = 'View Windows event logs'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/fulleventlogview-x64.zip')
    },
    [ordered]@{
        Name = 'Network Usage View'
        Description = 'Monitor network usage'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/networkusageview-x64.zip')
    },
    [ordered]@{
        Name = 'Browser Downloads View'
        Description = 'View browser download history'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/browserdownloadsview-x64.zip')
    },
    [ordered]@{
        Name = 'Alternate Stream View'
        Description = 'View NTFS alternate data streams'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/alternatestreamview-x64.zip')
    },
    [ordered]@{
        Name = 'USB Deview'
        Description = 'Manage USB devices'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/usbdeview-x64.zip')
    },
    [ordered]@{
        Name = 'Open Save Files View'
        Description = 'View Open/Save dialog history'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/opensavefilesview-x64.zip')
    },
    [ordered]@{
        Name = 'Executed Programs List'
        Description = 'List executed programs'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/executedprogramslist.zip')
    },
    [ordered]@{
        Name = 'Task Scheduler View'
        Description = 'View scheduled tasks'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/taskschedulerview-x64.zip')
    },
    [ordered]@{
        Name = 'Jump Lists View'
        Description = 'View Windows Jump Lists'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/jumplistsview.zip')
    },
    [ordered]@{
        Name = 'Win Prefetch View'
        Description = 'View Windows Prefetch files'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/winprefetchview-x64.zip')
    },
    [ordered]@{
        Name = 'Reg Scanner'
        Description = 'Advanced Registry scanner'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/regscanner-x64.zip')
    },
    [ordered]@{
        Name = 'ShellBags View'
        Description = 'View ShellBags entries'
        Category = 'nirsoft'
        Kind = 'Download'
        Links = @('https://www.nirsoft.net/utils/shellbagsview.zip')
    },
    [ordered]@{
        Name = 'Computer Activity View'
        Description = 'Timeline of computer activity events'
        Category = 'nirsoft'
        Kind = 'Link'
        Links = @('https://www.nirsoft.net/utils/computer_activity_view.html')
    },
    [ordered]@{
        Name = 'Amcache Parser'
        Description = 'Parse Amcache.hve'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/AmcacheParser.zip')
    },
    [ordered]@{
        Name = 'bstrings'
        Description = 'String extractor'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/bstrings.zip')
    },
    [ordered]@{
        Name = 'EvtxECmd'
        Description = 'Event log parser'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/EvtxECmd.zip')
    },
    [ordered]@{
        Name = 'Jump List Explorer'
        Description = 'Jump List explorer'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/JumpListExplorer.zip')
    },
    [ordered]@{
        Name = 'JLECmd'
        Description = 'Parses Jump List files from the command line'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/JLECmd.zip')
    },
    [ordered]@{
        Name = 'MFTECmd'
        Description = 'MFT parser'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/MFTECmd.zip')
    },
    [ordered]@{
        Name = 'PECmd'
        Description = 'Prefetch parser'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/PECmd.zip')
    },
    [ordered]@{
        Name = 'Recent File Cache Parser'
        Description = 'Parses RecentFileCache.bcf artifacts'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/RecentFileCacheParser.zip')
    },
    [ordered]@{
        Name = 'Registry Explorer'
        Description = 'Registry viewer'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/RegistryExplorer.zip')
    },
    [ordered]@{
        Name = 'ShellBags Explorer'
        Description = 'ShellBags viewer'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/ShellBagsExplorer.zip')
    },
    [ordered]@{
        Name = 'SrumECmd'
        Description = 'SRUM parser'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/SrumECmd.zip')
    },
    [ordered]@{
        Name = 'Timeline Explorer'
        Description = 'Timeline explorer'
        Category = 'ericzimmerman'
        Kind = 'Download'
        Links = @('https://download.ericzimmermanstools.com/net9/TimelineExplorer.zip')
    },
    [ordered]@{
        Name = 'Jarabel'
        Description = 'Locate all .jar files (or most of them) on a computer'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/nay-cat/Jarabel/releases/download/light/Jarabel.Light.exe')
    },
    [ordered]@{
        Name = 'Luyten'
        Description = 'Open Source Java Decompiler Gui for Procyon'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/deathmarine/Luyten/releases/download/v0.5.4_Rebuilt_with_Latest_depenencies/luyten-0.5.4.exe')
    },
    [ordered]@{
        Name = 'VM Aware'
        Description = 'Advanced VM detection library and tool'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/NotRequiem/VMAware/releases/download/v2.8.0/vmaware.exe')
    },
    [ordered]@{
        Name = 'NTFS Parser'
        Description = 'Forensics tool for NTFS'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/thewhiteninja/ntfstool/releases/download/v1.7/ntfstool.x64.exe')
    },
    [ordered]@{
        Name = 'Hayabusa'
        Description = 'Threat hunting and fast forensics timeline generator'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/Yamato-Security/hayabusa/releases/download/v3.10.0/hayabusa-3.10.0-all-platforms.zip')
    },
    [ordered]@{
        Name = 'Everything'
        Description = 'Locate files and folders by name instantly.'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://www.voidtools.com/Everything-1.4.1.1032.x64-Setup.exe')
    },
    [ordered]@{
        Name = 'HxD'
        Description = 'HxD Hex Editor'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://mh-nexus.de/downloads/HxDSetup.zip')
    },
    [ordered]@{
        Name = 'DIE Engine'
        Description = 'Detects file type, packer, and compiler information'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/horsicq/DIE-engine/releases')
    },
    [ordered]@{
        Name = 'Velociraptor'
        Description = 'Endpoint DFIR and threat hunting tool'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/Velocidex/velociraptor/releases/latest')
    },
    [ordered]@{
        Name = 'P1AE Javaw'
        Description = 'Best Javaw scanner'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/p1aegg/javaw/releases/download/v1.9/P1AE.Javaw.exe')
    },
    [ordered]@{
        Name = 'Macro Scanner'
        Description = 'Lafferr Macro Scanner'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/Lafferrr/MacroScanner/releases/download/MS/MacroScanner.exe')
    },
    [ordered]@{
        Name = 'String Checker'
        Description = 'Lafferrs Strings Checker'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/Strings/LaffersStringsChecker.exe')
    },
    [ordered]@{
        Name = 'Java Library Analyzer'
        Description = 'Lafferr Java Library Analyzer'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/JavaLibraryAnalyzer/JavaLibraryAnalyzer.exe', 'https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/JavaLibraryAnalyzer/library_baseline.bin', 'https://github.com/Lafferrr/SSTools/raw/refs/heads/main/SSTools/JavaLibraryAnalyzer/natives_baseline.bin')
    },
    [ordered]@{
        Name = 'PJ Cheat Scanner Lite'
        Description = 'String Checker'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/gorbgallin/Pj-sCheatScannerLite/releases/download/1.1/PjCheatScannerLite.exe', 'https://github.com/gorbgallin/Pj-sCheatScannerLite/releases/download/1.1/cheat_strings.txt')
    },
    [ordered]@{
        Name = 'System Informer'
        Description = 'Process viewer n shi'
        Category = 'others'
        Kind = 'Download'
        Links = @('https://github.com/winsiderss/si-builds/releases/download/4.0.26115.206/systeminformer-build-canary-setup.exe')
    },
    [ordered]@{
        Name = 'NET 8.0'
        Description = 'Install .NET 8.0 runtime'
        Category = 'dependencies'
        Kind = 'Download'
        Links = @('https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-8.0.423-windows-x64-installer')
    },
    [ordered]@{
        Name = 'NET 9.0'
        Description = 'Install .NET 9.0 runtime'
        Category = 'dependencies'
        Kind = 'Download'
        Links = @('https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/9.0.11/windowsdesktop-runtime-9.0.11-win-x64.exe')
    },
    [ordered]@{
        Name = 'NET 10.0'
        Description = 'Install .NET 10.0 runtime'
        Category = 'dependencies'
        Kind = 'Download'
        Links = @('https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/10.0.10/windowsdesktop-runtime-10.0.10-win-x64.exe')
    },
    [ordered]@{
        Name = 'VSRedist'
        Description = 'Install Visual C++ Redistributable'
        Category = 'dependencies'
        Kind = 'Download'
        Links = @('https://aka.ms/vc14/vc_redist.x64.exe')
    }
)

$ScriptActions = @(
    [ordered]@{
        Name = 'Running Processes'
        Description = 'Lists all running processes'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Get-Process | Sort-Object CPU -Descending | Format-Table Name,ID,CPU,WorkingSet -AutoSize'
    },
    [ordered]@{
        Name = 'Services Checker'
        Description = 'Runs Nicc/services-checker from GitHub'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/NiccBlahh/ServiceChecker/refs/heads/main/ServiceChecker.ps1'')'
    },
    [ordered]@{
        Name = 'Zeezy Services'
        Description = 'Runs zeezyexe services checker'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/zeezyexe/services-checker/refs/heads/main/zeezyservices.psl'')'
    },
    [ordered]@{
        Name = 'P1ae''s Mod Analyzer'
        Description = 'Runs p1aegg mod analyzer'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/p1aegg/powershell/refs/heads/main/modanalyzer.ps1'')'
    },
    [ordered]@{
        Name = 'JAR Parser'
        Description = 'Parses JAR files'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/JARParser.ps1'')'
    },
    [ordered]@{
        Name = 'Fileless Bypass Detection'
        Description = 'Detects fileless bypass techniques'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/l4rpsucks/Scripts/refs/heads/main/FilelessBypassDetection.ps1'')'
    },
    [ordered]@{
        Name = 'Macro Scanner'
        Description = 'Scans for mouse software macros (zeezy)'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/zeezyexe/macro-scanner/refs/heads/main/catchmacro.ps1'')'
    },
    [ordered]@{
        Name = 'ClassLoader Dump'
        Description = 'Dumps ClassLoader data'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/p1aegg/powershell/refs/heads/main/ClassLoaderDump.ps1'')'
    },
    [ordered]@{
        Name = 'Yarp''s Mod Analyzer'
        Description = 'Runs YarpLetapStan mod analyzer v6.0'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/YarpLetapStan/PowershellScripts/refs/heads/main/YarpsModAnalyzer6.0.ps1'')'
    },
    [ordered]@{
        Name = 'Meow Mod Analyzer'
        Description = 'Runs MeowTonynoh mod analyzer'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/MeowTonynoh/MeowModAnalyzer/main/MeowModAnalyzer.ps1'')'
    },
    [ordered]@{
        Name = 'Prefetch Integrity Analyzer'
        Description = 'Analyzes prefetch integrity (RedLotus)'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/bacanoicua/Screenshare/main/RedLotusPrefetchIntegrityAnalyzer.ps1'')'
    },
    [ordered]@{
        Name = 'Lily Services'
        Description = 'Runs PraiseLilys services checker'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Lafferrr/SSTools/refs/heads/main/LilysServices'')'
    },
    [ordered]@{
        Name = 'Lily Services Enabler'
        Description = 'Runs services enabler'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/Lafferrr/SSTools/refs/heads/main/LilysServicesEnabler'')'
    },
    [ordered]@{
        Name = 'WeHateFakers'
        Description = 'Checks hotspot and tethering logs'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/praiselily/WeHateFakers/refs/heads/main/HotspotLogs.ps1'')'
    },
    [ordered]@{
        Name = 'Common Directories'
        Description = 'Lists files in common suspicious directories'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/CommonDirectories.ps1'')'
    },
    [ordered]@{
        Name = 'Harddisk Converter'
        Description = 'Converts hard disk identifiers for review'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/HarddiskConverter.ps1'')'
    },
    [ordered]@{
        Name = 'PraiseLily Services'
        Description = 'Lists and analyzes running services'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Services.ps1'')'
    },
    [ordered]@{
        Name = 'Signed Scheduled Tasks'
        Description = 'Finds unsigned or suspicious scheduled tasks'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/praiselily/lilith-ps/refs/heads/main/Signed-Scheduled-Tasks.ps1'')'
    },
    [ordered]@{
        Name = 'DQRKIS Fucker'
        Description = 'Runs cheesecatlol DQRKIS artifact checker'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/cheesecatlol/DQRKIS-FUCKER/refs/heads/main/DqrkisFucker.ps1'')'
    },
    [ordered]@{
        Name = 'MacroDetector'
        Description = 'Detects macro and clicker software traces'
        Category = 'scripts'
        Kind = 'Script'
        Command = 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod ''https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/MacroDetector.ps1'')'
    }
)

$Credits = @(
    [ordered]@{
        Name = 'p1ae'
        Role = 'Original SSTool Windows application branding, source metadata, and C++/WebView2 launcher structure.'
        Source = 'README.md, resource.rc, main.cpp, splash.cpp'
    },
    [ordered]@{
        Name = 'p1aegg'
        Role = 'Original remote UI repository reference, PowerShell scripts, mod analyzer, ClassLoader Dump, and P1AE Javaw links.'
        Source = 'webview_manager.cpp, web/index.html'
    },
    [ordered]@{
        Name = 'TeslaPro / @teamwsf'
        Role = 'Uploaded PowerShell control panel visual reference and Tesla-style launcher credit.'
        Source = 'TeslaControlPannel.ps1 reference'
    },
    [ordered]@{
        Name = 'OrbDiff'
        Role = 'OrbDiff forensic tools.'
        Source = 'github.com/Orbdiff'
    },
    [ordered]@{
        Name = 'Spokwn'
        Role = 'Spokwn forensic tools and AnyDesk/script ecosystem links referenced by the uploaded material.'
        Source = 'github.com/spokwn'
    },
    [ordered]@{
        Name = 'Tonynoh / MeowTonynoh'
        Role = 'Meow resolver, Doomsday, client, imports, and mod analyzer tools.'
        Source = 'github.com/MeowTonynoh'
    },
    [ordered]@{
        Name = 'DetectAC'
        Role = 'Detect.ac Free Tools suite.'
        Source = 'detect.ac, github.com/detect-ac'
    },
    [ordered]@{
        Name = 'NirSoft'
        Role = 'NirSoft Windows forensic and system utilities.'
        Source = 'nirsoft.net'
    },
    [ordered]@{
        Name = 'Eric Zimmerman'
        Role = 'Eric Zimmerman forensic tools.'
        Source = 'ericzimmerman.github.io, download.ericzimmermanstools.com'
    },
    [ordered]@{
        Name = 'NiccBlahh'
        Role = 'ServiceChecker script.'
        Source = 'github.com/NiccBlahh/ServiceChecker'
    },
    [ordered]@{
        Name = 'zeezyexe'
        Role = 'Services checker and macro scanner scripts.'
        Source = 'github.com/zeezyexe'
    },
    [ordered]@{
        Name = 'l4rpsucks'
        Role = 'JARParser and FilelessBypassDetection scripts.'
        Source = 'github.com/l4rpsucks/Scripts'
    },
    [ordered]@{
        Name = 'YarpLetapStan'
        Role = 'Yarp''s Mod Analyzer script.'
        Source = 'github.com/YarpLetapStan/PowershellScripts'
    },
    [ordered]@{
        Name = 'bacanoicua / RedLotus'
        Role = 'RedLotus prefetch integrity analyzer script.'
        Source = 'github.com/bacanoicua/Screenshare'
    },
    [ordered]@{
        Name = 'Lafferrr / PraiseLily'
        Role = 'Macro Scanner, Strings Checker, Java Library Analyzer, Lily Services, and Lily Services Enabler references.'
        Source = 'github.com/Lafferrr/SSTools'
    },
    [ordered]@{
        Name = 'praiselily'
        Role = 'PSHunter, AltDetector, WeHateFakers, lilith-ps scripts, services, directories, harddisk converter, and scheduled tasks references.'
        Source = 'github.com/praiselily'
    },
    [ordered]@{
        Name = 'ItzIceHere / RedLotus'
        Role = 'RedLotus Mod Analyzer, Task Sentinel, and AltChecker tools.'
        Source = 'github.com/ItzIceHere'
    },
    [ordered]@{
        Name = 'cheese cat / cheesecatlol'
        Role = 'Reference implementation used for observing download, cache, extract, and launch behavior; DQRKIS checker reference.'
        Source = 'CheesySSTool.ps1 reference, github.com/cheesecatlol'
    },
    [ordered]@{
        Name = 'nay-cat'
        Role = 'Jarabel.'
        Source = 'github.com/nay-cat/Jarabel'
    },
    [ordered]@{
        Name = 'deathmarine / Procyon'
        Role = 'Luyten Java decompiler GUI and Procyon attribution from the original tool description.'
        Source = 'github.com/deathmarine/Luyten'
    },
    [ordered]@{
        Name = 'NotRequiem'
        Role = 'VM Aware.'
        Source = 'github.com/NotRequiem/VMAware'
    },
    [ordered]@{
        Name = 'thewhiteninja'
        Role = 'NTFS Parser.'
        Source = 'github.com/thewhiteninja/ntfstool'
    },
    [ordered]@{
        Name = 'Yamato-Security'
        Role = 'Hayabusa.'
        Source = 'github.com/Yamato-Security/hayabusa'
    },
    [ordered]@{
        Name = 'horsicq'
        Role = 'DIE Engine.'
        Source = 'github.com/horsicq/DIE-engine'
    },
    [ordered]@{
        Name = 'Velocidex'
        Role = 'Velociraptor.'
        Source = 'github.com/Velocidex/velociraptor'
    },
    [ordered]@{
        Name = 'voidtools'
        Role = 'Everything file search.'
        Source = 'voidtools.com'
    },
    [ordered]@{
        Name = 'MH-Nexus'
        Role = 'HxD Hex Editor.'
        Source = 'mh-nexus.de'
    },
    [ordered]@{
        Name = 'gorbgallin'
        Role = 'PJ Cheat Scanner Lite.'
        Source = 'github.com/gorbgallin'
    },
    [ordered]@{
        Name = 'winsiderss'
        Role = 'System Informer builds.'
        Source = 'github.com/winsiderss/si-builds'
    },
    [ordered]@{
        Name = 'Microsoft'
        Role = '.NET runtimes, Visual C++ Redistributable, WPF/.NET, and WebView2 dependency used by the original source.'
        Source = 'microsoft.com, dotnet.microsoft.com, aka.ms'
    }
)

function Show-TeslaDialog {
    param(
        [string]$Title = 'Tesla SS Tools',
        [string]$Message = '',
        [string]$Kind = 'Info',
        [string]$Details = ''
    )

    if ([string]::IsNullOrWhiteSpace($Message)) { $Message = 'No message was provided.' }

    [xml]$dialogXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tesla SS Tools"
        Width="590" Height="430"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        ResizeMode="NoResize"
        AllowsTransparency="False"
        Background="#050A10"
        ShowInTaskbar="False"
        Topmost="True"
        UseLayoutRounding="True"
        SnapsToDevicePixels="True"
        FontFamily="Segoe UI">
    <Border Background="#050A10" BorderBrush="#1E3A4E" BorderThickness="1" Padding="22">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="14"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Border x:Name="DialogIconBorder" Width="46" Height="46" CornerRadius="12" Background="#0C1824" BorderBrush="#2F6F88" BorderThickness="1">
                    <TextBlock x:Name="DialogIconText" Text="i" FontSize="24" FontWeight="Bold" Foreground="#74E8FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <StackPanel Grid.Column="2" VerticalAlignment="Center">
                    <TextBlock x:Name="DialogTitleText" Text="Tesla SS Tools" FontSize="18" FontWeight="SemiBold" Foreground="White" TextWrapping="Wrap"/>
                    <TextBlock x:Name="DialogKindText" Text="System message" FontSize="11" FontWeight="Bold" Foreground="#74E8FF" Margin="0,4,0,0"/>
                </StackPanel>
                <Button x:Name="DialogCloseButton" Grid.Column="3" Content="X" Width="34" Height="32" Background="#101824" Foreground="White" BorderBrush="#203040" BorderThickness="1" FontWeight="Bold" Cursor="Hand"/>
            </Grid>

            <StackPanel Grid.Row="1" Margin="0,22,0,18">
                <Border CornerRadius="12" Background="#0A141E" BorderBrush="#17364A" BorderThickness="1" Padding="16">
                    <TextBlock x:Name="DialogMessageText" Text="Message" Foreground="#D8E8F5" FontSize="13" TextWrapping="Wrap"/>
                </Border>
                <Border x:Name="DialogDetailsBorder" CornerRadius="12" Background="#07111B" BorderBrush="#203040" BorderThickness="1" Padding="12" Margin="0,12,0,0">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="8"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <TextBlock Text="Details" Foreground="#74E8FF" FontSize="11" FontWeight="Bold"/>
                        <TextBox x:Name="DialogDetailsBox" Grid.Row="2" Height="118" Background="Transparent" Foreground="#D8E8F5" BorderThickness="0" FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
                    </Grid>
                </Border>
            </StackPanel>

            <Grid Grid.Row="2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="150"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="110"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="Tesla SS Tools" Foreground="#597086" FontSize="11" VerticalAlignment="Center"/>
                <Button x:Name="DialogCopyButton" Grid.Column="2" Content="Copy Details" Height="40" Background="#101824" Foreground="#D8E8F5" BorderBrush="#203040" BorderThickness="1" Cursor="Hand" FontSize="12"/>
                <Button x:Name="DialogOkButton" Grid.Column="4" Content="OK" Height="40" Background="#00A8D8" Foreground="White" BorderBrush="#39E5FF" BorderThickness="1" Cursor="Hand" FontSize="12" FontWeight="SemiBold"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    try {
        $dialogReader = New-Object System.Xml.XmlNodeReader $dialogXaml
        $dialogWindow = [Windows.Markup.XamlReader]::Load($dialogReader)
        $dialogWindow.Add_MouseLeftButtonDown({ try { $dialogWindow.DragMove() } catch {} })

        $titleText = $dialogWindow.FindName('DialogTitleText')
        $kindText = $dialogWindow.FindName('DialogKindText')
        $messageText = $dialogWindow.FindName('DialogMessageText')
        $detailsBorder = $dialogWindow.FindName('DialogDetailsBorder')
        $detailsBox = $dialogWindow.FindName('DialogDetailsBox')
        $copyButton = $dialogWindow.FindName('DialogCopyButton')
        $iconText = $dialogWindow.FindName('DialogIconText')
        $iconBorder = $dialogWindow.FindName('DialogIconBorder')
        $brushConverter = New-Object System.Windows.Media.BrushConverter

        $titleText.Text = $Title
        $messageText.Text = $Message

        switch ($Kind.ToLowerInvariant()) {
            'error' {
                $kindText.Text = 'ERROR'
                $kindText.Foreground = $brushConverter.ConvertFromString('#FF7B7B')
                $iconText.Text = '!'
                $iconText.Foreground = $brushConverter.ConvertFromString('#FF7B7B')
                $iconBorder.BorderBrush = $brushConverter.ConvertFromString('#7A2B34')
            }
            'warning' {
                $kindText.Text = 'WARNING'
                $kindText.Foreground = $brushConverter.ConvertFromString('#FFD166')
                $iconText.Text = '!'
                $iconText.Foreground = $brushConverter.ConvertFromString('#FFD166')
                $iconBorder.BorderBrush = $brushConverter.ConvertFromString('#6E5520')
            }
            default {
                $kindText.Text = 'MESSAGE'
                $kindText.Foreground = $brushConverter.ConvertFromString('#74E8FF')
                $iconText.Text = 'i'
                $iconText.Foreground = $brushConverter.ConvertFromString('#74E8FF')
            }
        }

        if ([string]::IsNullOrWhiteSpace($Details)) {
            $detailsBorder.Visibility = 'Collapsed'
            $copyButton.Visibility = 'Collapsed'
        }
        else {
            $detailsBox.Text = $Details
            $copyButton.Add_Click({
                try { [System.Windows.Clipboard]::SetText($detailsBox.Text) } catch {}
            })
        }

        $dialogWindow.FindName('DialogOkButton').Add_Click({ $dialogWindow.Close() })
        $dialogWindow.FindName('DialogCloseButton').Add_Click({ $dialogWindow.Close() })
        $dialogWindow.ShowDialog() | Out-Null
    }
    catch {
        [System.Windows.MessageBox]::Show($Message, $Title, 'OK', 'Information') | Out-Null
    }
}

function Show-TeslaTermsDialog {
    [xml]$termsXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tesla SS Tools Terms"
        Width="620" Height="520"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        ResizeMode="NoResize"
        AllowsTransparency="False"
        Background="#050A10"
        ShowInTaskbar="False"
        Topmost="True"
        UseLayoutRounding="True"
        SnapsToDevicePixels="True"
        FontFamily="Segoe UI">
    <Border Background="#050A10" BorderBrush="#1E3A4E" BorderThickness="1" Padding="24">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Width="48" Height="48" CornerRadius="12" Background="#0C1824" BorderBrush="#2F6F88" BorderThickness="1">
                        <TextBlock Text="T" FontSize="24" FontWeight="Bold" Foreground="#7BE9FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <StackPanel Margin="14,0,0,0" VerticalAlignment="Center">
                        <TextBlock Text="Tesla SS Tools" FontSize="22" FontWeight="SemiBold" Foreground="White"/>
                        <TextBlock Text="Please read and accept before continuing" FontSize="12" Foreground="#8EA2B6" Margin="0,4,0,0"/>
                    </StackPanel>
                </StackPanel>
                <Button x:Name="TermsCloseButton" Grid.Column="1" Content="X" Width="36" Height="34" Background="#101824" Foreground="White" BorderBrush="#203040" BorderThickness="1" FontWeight="Bold" Cursor="Hand"/>
            </Grid>

            <StackPanel Grid.Row="1" Margin="0,28,0,18">
                <Border CornerRadius="10" Background="#0A141E" BorderBrush="#17364A" BorderThickness="1" Padding="16">
                    <StackPanel>
                        <TextBlock Text="Before You Continue" FontSize="18" FontWeight="SemiBold" Foreground="White"/>
                        <TextBlock TextWrapping="Wrap" Foreground="#D8E8F5" FontSize="13" Margin="0,12,0,0"
                                   Text="Tesla SS Tools is a launcher for legitimate screenshare, education, and forensic review workflows. Use it only on systems where you have permission."/>
                        <TextBlock TextWrapping="Wrap" Foreground="#D8E8F5" FontSize="13" Margin="0,12,0,0"
                                   Text="External programs and scripts are created by their own developers. Tesla SS Tools keeps their original credits and does not claim ownership of those external tools."/>
                        <TextBlock TextWrapping="Wrap" Foreground="#D8E8F5" FontSize="13" Margin="0,12,0,0"
                                   Text="Downloaded tools are saved in the teslatool folder. Some tools may require administrator permission or their own runtimes to work correctly."/>
                        <TextBlock TextWrapping="Wrap" Foreground="#74E8FF" FontSize="13" FontWeight="SemiBold" Margin="0,16,0,0"
                                   Text="Click Accept if you understand and agree."/>
                    </StackPanel>
                </Border>
            </StackPanel>

            <Grid Grid.Row="2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="TermsCancelButton" Content="Cancel" Height="44" Background="#101824" Foreground="#D8E8F5" BorderBrush="#203040" BorderThickness="1" Cursor="Hand" FontSize="13"/>
                <Button x:Name="TermsAcceptButton" Grid.Column="2" Content="Accept &amp; Continue" Height="44" Background="#00A8D8" Foreground="White" BorderBrush="#39E5FF" BorderThickness="1" Cursor="Hand" FontSize="13" FontWeight="SemiBold"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    try {
        $termsReader = New-Object System.Xml.XmlNodeReader $termsXaml
        $termsWindow = [Windows.Markup.XamlReader]::Load($termsReader)
        $termsAccepted = $false
        $termsWindow.Add_MouseLeftButtonDown({ try { $termsWindow.DragMove() } catch {} })
        $termsWindow.FindName('TermsAcceptButton').Add_Click({
            $script:TeslaTermsAccepted = $true
            $termsWindow.Close()
        })
        $termsWindow.FindName('TermsCancelButton').Add_Click({
            $script:TeslaTermsAccepted = $false
            $termsWindow.Close()
        })
        $termsWindow.FindName('TermsCloseButton').Add_Click({
            $script:TeslaTermsAccepted = $false
            $termsWindow.Close()
        })
        $script:TeslaTermsAccepted = $false
        $termsWindow.ShowDialog() | Out-Null
        $termsAccepted = [bool]$script:TeslaTermsAccepted
        Remove-Variable -Name TeslaTermsAccepted -Scope Script -ErrorAction SilentlyContinue
        return $termsAccepted
    }
    catch {
        Show-TeslaDialog -Title 'Tesla SS Tools - Startup Error' -Message 'Tesla SS Tools could not display the terms window.' -Kind 'Error' -Details $_.Exception.Message
        return $false
    }
}

function Show-TeslaDiscordAd {
    [xml]$discordAdXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Join Tesla SS Course"
        Width="560" Height="390"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        ResizeMode="NoResize"
        AllowsTransparency="False"
        Background="#050A10"
        ShowInTaskbar="False"
        Topmost="True"
        UseLayoutRounding="True"
        SnapsToDevicePixels="True"
        FontFamily="Segoe UI">
    <Border Background="#050A10" BorderBrush="#1E3A4E" BorderThickness="1" Padding="22">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="Tesla SS Course Discord" FontSize="18" FontWeight="SemiBold" Foreground="White" VerticalAlignment="Center"/>
                <Button x:Name="AdCloseButton" Grid.Column="1" Content="X" Width="34" Height="32" Background="#101824" Foreground="White" BorderBrush="#203040" BorderThickness="1" FontWeight="Bold" Cursor="Hand"/>
            </Grid>

            <Border Grid.Row="1" Margin="0,22,0,18" CornerRadius="14" Background="#0A141E" BorderBrush="#17364A" BorderThickness="1" Padding="22">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="110"/>
                        <ColumnDefinition Width="18"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button x:Name="AdDiscordIconButton" Width="94" Height="94" Background="#5865F2" BorderBrush="#7B86FF" BorderThickness="1" Cursor="Hand" ToolTip="Join the Tesla SS Course Discord">
                        <Viewbox Width="58" Height="44">
                            <Canvas Width="24" Height="18">
                                <Path Fill="White" Data="M3,4 C8,1 16,1 21,4 L20,14 C16,18 8,18 4,14 Z"/>
                                <Ellipse Canvas.Left="7" Canvas.Top="8" Width="3" Height="3" Fill="#5865F2"/>
                                <Ellipse Canvas.Left="14" Canvas.Top="8" Width="3" Height="3" Fill="#5865F2"/>
                                <Path Stroke="#5865F2" StrokeThickness="1.4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Data="M9,13 C11,14 13,14 15,13"/>
                            </Canvas>
                        </Viewbox>
                    </Button>
                    <StackPanel Grid.Column="2" VerticalAlignment="Center">
                        <TextBlock Text="Join the Discord and learn how to SS properly." FontSize="22" FontWeight="Bold" Foreground="White" TextWrapping="Wrap"/>
                        <TextBlock Text="Get methods, tool guides, screenshare help, and updates from the Tesla SS Course community." FontSize="13" Foreground="#D8E8F5" Margin="0,12,0,0" TextWrapping="Wrap"/>
                        <TextBlock Text="Start learning faster. Ask better questions. Use the tools with purpose." FontSize="13" Foreground="#74E8FF" Margin="0,12,0,0" TextWrapping="Wrap" FontWeight="SemiBold"/>
                    </StackPanel>
                </Grid>
            </Border>

            <Grid Grid.Row="2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="14"/>
                    <ColumnDefinition Width="190"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="AdSkipButton" Content="Continue" Height="44" Background="#101824" Foreground="#D8E8F5" BorderBrush="#203040" BorderThickness="1" Cursor="Hand" FontSize="13"/>
                <Button x:Name="AdJoinButton" Grid.Column="2" Content="Join Discord" Height="44" Background="#5865F2" Foreground="White" BorderBrush="#7B86FF" BorderThickness="1" Cursor="Hand" FontSize="13" FontWeight="SemiBold" ToolTip="Join the Tesla SS Course Discord"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    try {
        $adReader = New-Object System.Xml.XmlNodeReader $discordAdXaml
        $adWindow = [Windows.Markup.XamlReader]::Load($adReader)
        $adWindow.Add_MouseLeftButtonDown({ try { $adWindow.DragMove() } catch {} })
        $openDiscord = {
            try {
                Start-Process $DiscordInvite
                $adWindow.Close()
            }
            catch {
                Show-TeslaDialog -Title 'Tesla SS Tools - Discord Error' -Message 'Could not open Discord invite.' -Kind 'Error' -Details $_.Exception.Message
            }
        }
        $adWindow.FindName('AdJoinButton').Add_Click($openDiscord)
        $adWindow.FindName('AdDiscordIconButton').Add_Click($openDiscord)
        $adWindow.FindName('AdSkipButton').Add_Click({ $adWindow.Close() })
        $adWindow.FindName('AdCloseButton').Add_Click({ $adWindow.Close() })
        $adWindow.ShowDialog() | Out-Null
    }
    catch {
        Show-TeslaDialog -Title 'Tesla SS Tools - Discord Screen Error' -Message 'Tesla SS Tools could not display the Discord screen.' -Kind 'Error' -Details $_.Exception.Message
    }
}

if (-not (Show-TeslaTermsDialog)) {
    exit
}

[xml]$splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tesla SS Tools Loading"
        Width="660" Height="420"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        ResizeMode="NoResize"
        AllowsTransparency="False"
        Background="#03070D"
        ShowInTaskbar="False"
        Topmost="True"
        UseLayoutRounding="True"
        SnapsToDevicePixels="True"
        FontFamily="Segoe UI">
    <Border Background="#03070D" BorderBrush="#1E3A4E" BorderThickness="1" Padding="28">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="18"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Border x:Name="SplashLogo" Width="92" Height="92" CornerRadius="22" Background="#07121D" BorderBrush="#39E5FF" BorderThickness="1">
                    <Border.RenderTransform>
                        <ScaleTransform x:Name="SplashLogoScale" ScaleX="1" ScaleY="1"/>
                    </Border.RenderTransform>
                    <Grid>
                        <Border Width="54" Height="54" CornerRadius="14" Background="#0E2130" BorderBrush="#2F6F88" BorderThickness="1" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        <TextBlock Text="T" FontSize="42" FontWeight="Bold" Foreground="#7BE9FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        <Border Height="2" Background="#39E5FF" VerticalAlignment="Bottom" Margin="18,0,18,18"/>
                    </Grid>
                </Border>
                <StackPanel Grid.Column="2" VerticalAlignment="Center">
                    <TextBlock Text="TESLA SS TOOLS" FontSize="28" FontWeight="Bold" Foreground="White"/>
                    <TextBlock x:Name="SplashBootText" Text="NEON BOOT SEQUENCE" FontSize="11" FontWeight="Bold" Foreground="#74E8FF" Margin="0,4,0,0"/>
                    <TextBlock x:Name="SplashStatusText" Text="Initializing Tesla SS Tools..." FontSize="13" Foreground="#9DB1C4" Margin="0,12,0,0"/>
                </StackPanel>
            </Grid>

            <StackPanel Grid.Row="1" Margin="0,30,0,22">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border x:Name="SplashChipOne" Height="42" CornerRadius="10" Background="#08121C" BorderBrush="#17364A" BorderThickness="1" Padding="12,0">
                        <TextBlock Text="Core modules" Foreground="#D8E8F5" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                    </Border>
                    <Border x:Name="SplashChipTwo" Grid.Column="2" Height="42" CornerRadius="10" Background="#08121C" BorderBrush="#17364A" BorderThickness="1" Padding="12,0">
                        <TextBlock Text="GitHub resolver" Foreground="#D8E8F5" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                    </Border>
                    <Border x:Name="SplashChipThree" Grid.Column="4" Height="42" CornerRadius="10" Background="#08121C" BorderBrush="#17364A" BorderThickness="1" Padding="12,0">
                        <TextBlock Text="SS scripts" Foreground="#D8E8F5" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                    </Border>
                </Grid>

                <Border Height="54" CornerRadius="12" Background="#06101A" BorderBrush="#102D40" BorderThickness="1" Margin="0,22,0,0" Padding="14,0">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock x:Name="SplashModuleText" Text="Loading categories and tool metadata" Foreground="#D8E8F5" FontSize="13" VerticalAlignment="Center"/>
                        <TextBlock x:Name="SplashProgressText" Grid.Column="1" Text="10%" Foreground="#74E8FF" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                    </Grid>
                </Border>

                <Grid Height="12" Margin="0,22,0,0">
                    <Border CornerRadius="6" Background="#07111B" BorderBrush="#102D40" BorderThickness="1"/>
                    <Border x:Name="SplashProgressFill" Width="48" CornerRadius="6" Background="#22D6FF" HorizontalAlignment="Left"/>
                    <Border x:Name="SplashProgressSweep" Width="34" CornerRadius="6" Background="#C8F8FF" Opacity="0.56" HorizontalAlignment="Left"/>
                </Grid>
            </StackPanel>
            <TextBlock Grid.Row="2" Text="Learn the method. Read the artifacts. Confirm the proof." Foreground="#7E92A6" FontSize="12" HorizontalAlignment="Center"/>
        </Grid>
    </Border>
</Window>
"@

try {
    $splashReader = New-Object System.Xml.XmlNodeReader $splashXaml
    $SplashWindow = [Windows.Markup.XamlReader]::Load($splashReader)
    $SplashStatusText = $SplashWindow.FindName('SplashStatusText')
    $SplashBootText = $SplashWindow.FindName('SplashBootText')
    $SplashModuleText = $SplashWindow.FindName('SplashModuleText')
    $SplashProgressText = $SplashWindow.FindName('SplashProgressText')
    $SplashProgressFill = $SplashWindow.FindName('SplashProgressFill')
    $SplashProgressSweep = $SplashWindow.FindName('SplashProgressSweep')
    $SplashChipOne = $SplashWindow.FindName('SplashChipOne')
    $SplashChipTwo = $SplashWindow.FindName('SplashChipTwo')
    $SplashChipThree = $SplashWindow.FindName('SplashChipThree')
    $SplashLogoScale = $SplashWindow.FindName('SplashLogoScale')
    $SplashWindow.Show()
    if ($SplashLogoScale) {
        $pulse = New-Object System.Windows.Media.Animation.DoubleAnimation
        $pulse.From = 0.92
        $pulse.To = 1.0
        $pulse.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(420))
        $SplashLogoScale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $pulse)
        $SplashLogoScale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $pulse)
    }
    $SplashWindow.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}
catch {
    $SplashWindow = $null
}

function Update-Splash {
    param([string]$Text, [double]$Progress)
    if (-not $SplashWindow) { return }
    if ($SplashStatusText) { $SplashStatusText.Text = $Text }
    if ($SplashModuleText) { $SplashModuleText.Text = $Text }
    if ($SplashProgressText) { $SplashProgressText.Text = ('{0}%' -f [int]$Progress) }
    $fillWidth = [Math]::Max(48, [Math]::Min(600, 600 * ($Progress / 100)))
    if ($SplashProgressFill) { $SplashProgressFill.Width = $fillWidth }
    if ($SplashProgressSweep) { $SplashProgressSweep.Margin = New-Object System.Windows.Thickness ([Math]::Max(0, $fillWidth - 34)),0,0,0 }
    $splashBrushConverter = New-Object System.Windows.Media.BrushConverter
    $activeSplashBrush = $splashBrushConverter.ConvertFromString('#22D6FF')
    if ($SplashChipOne -and $Progress -ge 35) { $SplashChipOne.BorderBrush = $activeSplashBrush }
    if ($SplashChipTwo -and $Progress -ge 60) { $SplashChipTwo.BorderBrush = $activeSplashBrush }
    if ($SplashChipThree -and $Progress -ge 80) { $SplashChipThree.BorderBrush = $activeSplashBrush }
    $SplashWindow.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

Update-Splash -Text 'Initializing interface core...' -Progress 18
Start-Sleep -Milliseconds 90

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tesla SS Tools"
        Width="1420"
        Height="900"
        MinWidth="1160"
        MinHeight="740"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResizeWithGrip"
        WindowStyle="None"
        AllowsTransparency="False"
        Background="#05070B"
        UseLayoutRounding="True"
        SnapsToDevicePixels="True"
        FontFamily="Segoe UI">
    <Window.Resources>
        <LinearGradientBrush x:Key="WindowBackground" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#05070B" Offset="0"/>
            <GradientStop Color="#09111B" Offset="0.48"/>
            <GradientStop Color="#071B27" Offset="1"/>
        </LinearGradientBrush>
        <LinearGradientBrush x:Key="SidebarBackground" StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#0B1118" Offset="0"/>
            <GradientStop Color="#0D1520" Offset="1"/>
        </LinearGradientBrush>
        <LinearGradientBrush x:Key="PrimaryButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#39E5FF" Offset="0"/>
            <GradientStop Color="#00A8D8" Offset="1"/>
        </LinearGradientBrush>
        <LinearGradientBrush x:Key="NeutralButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#182332" Offset="0"/>
            <GradientStop Color="#141C27" Offset="1"/>
        </LinearGradientBrush>
        <LinearGradientBrush x:Key="CardBackground" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#101824" Offset="0"/>
            <GradientStop Color="#0B1017" Offset="1"/>
        </LinearGradientBrush>
        <SolidColorBrush x:Key="BorderBrushSoft" Color="#1C2A3C"/>
        <SolidColorBrush x:Key="TextMuted" Color="#8EA2B6"/>
        <SolidColorBrush x:Key="AccentText" Color="#74E8FF"/>

        <Style x:Key="SmallWindowButtonStyle" TargetType="Button">
            <Setter Property="Width" Value="36"/>
            <Setter Property="Height" Value="36"/>
            <Setter Property="Margin" Value="8,0,0,0"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Background" Value="#14FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" Background="{TemplateBinding Background}" CornerRadius="10">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.9"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.72"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ActionButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="46"/>
            <Setter Property="Margin" Value="0,0,0,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Background" Value="{StaticResource NeutralButtonBrush}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Root" Background="{TemplateBinding Background}" CornerRadius="15" BorderBrush="#203040" BorderThickness="1">
                            <Grid Margin="15,0,14,0">
                                <ContentPresenter VerticalAlignment="Center" RecognizesAccessKey="True"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Root" Property="BorderBrush" Value="#35D9FF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Root" Property="Opacity" Value="0.82"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Root" Property="Opacity" Value="0.42"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ToolCardButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Background" Value="{StaticResource CardBackground}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Root" Background="{TemplateBinding Background}" CornerRadius="12" BorderBrush="#203040" BorderThickness="1" Padding="0">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Root" Property="BorderBrush" Value="#35D9FF"/>
                                <Setter TargetName="Root" Property="Opacity" Value="0.96"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Root" Property="Opacity" Value="0.82"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Root" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="CardBorderStyle" TargetType="Border">
            <Setter Property="CornerRadius" Value="22"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Background" Value="{StaticResource CardBackground}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Border Background="{StaticResource WindowBackground}" BorderBrush="#1D2938" BorderThickness="1">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="64"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Border x:Name="HeaderBar" Grid.Row="0" Background="#0A0F17" BorderBrush="#162232" BorderThickness="0,0,0,1">
                    <Grid Margin="18,0,18,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Border Width="40" Height="40" CornerRadius="13" Background="#101A27" BorderBrush="#23435D" BorderThickness="1">
                                <TextBlock Text="T" FontSize="20" FontWeight="Bold" Foreground="#7BE9FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
                                <TextBlock Text="Tesla SS Tools" FontSize="18" FontWeight="SemiBold" Foreground="White"/>
                                <TextBlock Text="Standalone forensic launcher" FontSize="11" Foreground="#7E92A6" Margin="0,2,0,0"/>
                            </StackPanel>
                        </StackPanel>
                        <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                            <Button x:Name="DiscordButton" Style="{StaticResource SmallWindowButtonStyle}" Background="#23315C" ToolTip="Join the Tesla SS Course Discord">
                                <Viewbox Width="18" Height="18">
                                    <Canvas Width="24" Height="18">
                                        <Path Fill="White" Data="M3,4 C8,1 16,1 21,4 L20,14 C16,18 8,18 4,14 Z"/>
                                        <Ellipse Canvas.Left="7" Canvas.Top="8" Width="3" Height="3" Fill="#23315C"/>
                                        <Ellipse Canvas.Left="14" Canvas.Top="8" Width="3" Height="3" Fill="#23315C"/>
                                        <Path Stroke="#23315C" StrokeThickness="1.4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Data="M9,13 C11,14 13,14 15,13"/>
                                    </Canvas>
                                </Viewbox>
                            </Button>
                            <Button x:Name="MinButton" Content="-" Style="{StaticResource SmallWindowButtonStyle}"/>
                            <Button x:Name="CloseButton" Content="X" Style="{StaticResource SmallWindowButtonStyle}" Background="#1F2330"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <Grid Grid.Row="1" Margin="20">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="320"/>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" Background="{StaticResource SidebarBackground}" CornerRadius="22" BorderBrush="#192537" BorderThickness="1" Padding="20">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="18"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="20"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            <StackPanel>
                                <TextBlock Text="Tesla SS Tools" FontSize="24" FontWeight="SemiBold" Foreground="White"/>
                                <TextBlock Text="Categories" TextWrapping="Wrap" Margin="0,8,0,0" Foreground="#8EA2B6" FontSize="13"/>
                            </StackPanel>
                            <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                <StackPanel x:Name="CategoryButtonPanel"/>
                            </ScrollViewer>
                            <Border Grid.Row="4" Background="#0B1017" CornerRadius="18" Padding="14" BorderBrush="#1B2837" BorderThickness="1">
                                <StackPanel>
                                    <Button x:Name="OpenToolsFolderButton" Content="Open Folder" Style="{StaticResource ActionButtonStyle}" Background="{StaticResource PrimaryButtonBrush}" Margin="0,0,0,10"/>
                                    <Button x:Name="SettingsButton" Content="Settings" Style="{StaticResource ActionButtonStyle}" Margin="0,0,0,10"/>
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBlock x:Name="VersionText" Text="Version 1.0" Foreground="#74E8FF" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                                        <Border Grid.Column="1" Width="78" Height="26" CornerRadius="13" Background="#122232" BorderBrush="#234760" BorderThickness="1" VerticalAlignment="Center">
                                            <TextBlock x:Name="StateChip" Text="READY" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#74E8FF" FontSize="11" FontWeight="Bold"/>
                                        </Border>
                                    </Grid>
                                </StackPanel>
                            </Border>
                        </Grid>
                    </Border>

                    <Grid Grid.Column="2">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="0"/>
                            <RowDefinition Height="0"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="0"/>
                            <RowDefinition Height="0"/>
                        </Grid.RowDefinitions>
                        <Border Grid.Row="0" Style="{StaticResource CardBorderStyle}" Visibility="Collapsed">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="1"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <TextBlock x:Name="StatusText" Text="Ready" FontSize="28" FontWeight="SemiBold" Foreground="White"/>
                                    <TextBlock x:Name="SubStatusText" Text="Everything is ready. Pick a category on the left." Margin="0,8,0,0" FontSize="14" Foreground="#9DB1C4" TextWrapping="Wrap"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" VerticalAlignment="Center" Visibility="Collapsed">
                                    <TextBlock x:Name="BigChipText" Text="READY" HorizontalAlignment="Center" Foreground="#74E8FF" FontSize="22" FontWeight="Bold" Margin="0,8,0,0"/>
                                    <TextBlock x:Name="FooterText" Text="Idle" HorizontalAlignment="Center" Foreground="#8FA4B8" FontSize="12" Margin="0,6,0,0"/>
                                </StackPanel>
                            </Grid>
                        </Border>

                        <Border Grid.Row="2" Style="{StaticResource CardBorderStyle}">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="14"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <Grid>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="10"/>
                                        <RowDefinition Height="Auto"/>
                                    </Grid.RowDefinitions>
                                    <StackPanel Grid.Row="0">
                                        <TextBlock x:Name="SelectedCategoryText" Text="OrbDiff" FontSize="24" FontWeight="SemiBold" Foreground="White"/>
                                        <TextBlock x:Name="SelectedCategoryDescription" Text="Tools developed by OrbDiff" Foreground="#91A7BB" FontSize="12.5" Margin="0,6,0,0" TextWrapping="Wrap"/>
                                        <Border Margin="0,10,0,0" CornerRadius="8" Background="#0A141E" BorderBrush="#17364A" BorderThickness="1" Padding="10,7" HorizontalAlignment="Stretch">
                                            <TextBlock x:Name="CategoryHeaderText" Text="Tools developed by OrbDiff - github.com/orbdiff" FontSize="12.5" Foreground="#74E8FF" TextWrapping="Wrap"/>
                                        </Border>
                                        <TextBlock x:Name="InlineStatusText" Text="Ready" Foreground="#8EA2B6" FontSize="12" Margin="0,8,0,0" TextWrapping="Wrap"/>
                                    </StackPanel>
                                    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                                        <Button x:Name="CancelDownloadButton" Content="Cancel" Style="{StaticResource ActionButtonStyle}" Width="104" Margin="0,0,10,0" IsEnabled="False"/>
                                        <Button x:Name="DownloadAllButton" Content="Download All" Style="{StaticResource ActionButtonStyle}" Background="{StaticResource PrimaryButtonBrush}" Width="138" Margin="0"/>
                                    </StackPanel>
                                </Grid>
                                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                    <WrapPanel x:Name="ToolWrapPanel" HorizontalAlignment="Center" Margin="0,12,0,0"/>
                                </ScrollViewer>
                            </Grid>
                        </Border>

                        <Border Grid.Row="4" Style="{StaticResource CardBorderStyle}" Visibility="Collapsed">
                            <Grid>
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="12"/>
                                    <RowDefinition Height="12"/>
                                    <RowDefinition Height="12"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="140"/>
                                        <ColumnDefinition Width="140"/>
                                        <ColumnDefinition Width="140"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel>
                                        <TextBlock Text="Activity Console" FontSize="20" FontWeight="SemiBold" Foreground="White"/>
                                        <TextBlock Text="Tool output and current status" Foreground="#91A7BB" FontSize="12" Margin="0,5,0,0"/>
                                    </StackPanel>
                                    <StackPanel Grid.Column="1">
                                        <TextBlock Text="Step" FontSize="11" Foreground="#7C93A8" HorizontalAlignment="Center"/>
                                        <TextBlock x:Name="StepText" Text="Waiting" FontSize="14" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                                    </StackPanel>
                                    <StackPanel Grid.Column="2">
                                        <TextBlock Text="Progress" FontSize="11" Foreground="#7C93A8" HorizontalAlignment="Center"/>
                                        <TextBlock x:Name="ProgressLabel" Text="0%" FontSize="14" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                                    </StackPanel>
                                    <StackPanel Grid.Column="3">
                                        <TextBlock Text="Items" FontSize="11" Foreground="#7C93A8" HorizontalAlignment="Center"/>
                                        <TextBlock x:Name="ToolCountText" Text="0" FontSize="14" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                                    </StackPanel>
                                </Grid>
                                <Border Grid.Row="2" CornerRadius="8" Background="#091018" BorderBrush="#1A2B3C" BorderThickness="1">
                                    <ProgressBar x:Name="MainProgressBar" Height="12" Minimum="0" Maximum="100" Value="0" Background="Transparent" Foreground="#22D6FF" BorderThickness="0"/>
                                </Border>
                                <Border Grid.Row="4" CornerRadius="16" Background="#091018" BorderBrush="#1A2B3C" BorderThickness="1" Padding="12">
                                    <TextBox x:Name="ActivityBox" Background="Transparent" Foreground="#D8E8F5" BorderThickness="0" FontFamily="Consolas" FontSize="12" IsReadOnly="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" TextWrapping="Wrap" AcceptsReturn="True"/>
                                </Border>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$HeaderBar = $window.FindName('HeaderBar')
$CloseButton = $window.FindName('CloseButton')
$MinButton = $window.FindName('MinButton')
$DiscordButton = $window.FindName('DiscordButton')
$CategoryButtonPanel = $window.FindName('CategoryButtonPanel')
$ToolWrapPanel = $window.FindName('ToolWrapPanel')
$StatusText = $window.FindName('StatusText')
$SubStatusText = $window.FindName('SubStatusText')
$CategoryHeaderText = $window.FindName('CategoryHeaderText')
$StateChip = $window.FindName('StateChip')
$BigChipText = $window.FindName('BigChipText')
$FooterText = $window.FindName('FooterText')
$SelectedCategoryText = $window.FindName('SelectedCategoryText')
$SelectedCategoryDescription = $window.FindName('SelectedCategoryDescription')
$InlineStatusText = $window.FindName('InlineStatusText')
$DownloadAllButton = $window.FindName('DownloadAllButton')
$CancelDownloadButton = $window.FindName('CancelDownloadButton')
$OpenToolsFolderButton = $window.FindName('OpenToolsFolderButton')
$SettingsButton = $window.FindName('SettingsButton')
$StepText = $window.FindName('StepText')
$ProgressLabel = $window.FindName('ProgressLabel')
$ToolCountText = $window.FindName('ToolCountText')
$MainProgressBar = $window.FindName('MainProgressBar')
$ActivityBox = $window.FindName('ActivityBox')
$VersionText = $window.FindName('VersionText')

$VersionText.Text = "Version $AppVersion"

$script:CurrentCategory = 'orbdiff'
$script:CategoryButtons = @{}
$script:CardIndicators = @{}
$script:CardProgressBars = @{}
$script:DownloadQueue = New-Object System.Collections.Queue
$script:CurrentWorker = $null
$script:ActiveDownloadJob = $null
$script:BatchActive = $false
$script:ShowActivityLog = $false
$script:BrushConverter = New-Object System.Windows.Media.BrushConverter
$script:Settings = [ordered]@{
    AutoLaunchDownloads = $true
    RunScriptsAsAdmin = $true
    ShowDiscordAd = $true
    OpenFolderWhenNoLaunchable = $true
    DetailedErrorPopups = $true
}

function Get-Brush {
    param([string]$Color)
    return $script:BrushConverter.ConvertFromString($Color)
}

function Refresh-Ui {
    if ($window) {
        $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }
}

function Set-ProgressAnimated {
    param([double]$Value, [int]$DurationMs = 180)
    if ($Value -lt 0) { $Value = 0 }
    if ($Value -gt 100) { $Value = 100 }
    $MainProgressBar.IsIndeterminate = $false
    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animation.To = $Value
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($DurationMs))
    $MainProgressBar.BeginAnimation([System.Windows.Controls.ProgressBar]::ValueProperty, $animation)
}

function Set-UiState {
    param(
        [string]$Title,
        [string]$SubTitle,
        [string]$Chip,
        [string]$Step,
        [double]$Progress = 0
    )
    $StatusText.Text = $Title
    $SubStatusText.Text = $SubTitle
    if ($InlineStatusText) {
        $InlineStatusText.Foreground = Get-Brush '#8EA2B6'
        $InlineStatusText.Text = $SubTitle
    }
    $StateChip.Text = $Chip.ToUpperInvariant()
    $BigChipText.Text = $Chip.ToUpperInvariant()
    $FooterText.Text = $Title
    $StepText.Text = $Step
    $ProgressLabel.Text = ('{0}%' -f [int]$Progress)
    Set-ProgressAnimated -Value $Progress
    Refresh-Ui
}

function Write-Activity {
    param([string]$Text)
    if (-not $script:ShowActivityLog -or -not $ActivityBox) { return }
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $ActivityBox.AppendText("[$timestamp] $Text`r`n")
    $ActivityBox.ScrollToEnd()
    Refresh-Ui
}

function Show-Message {
    param([string]$Message, [string]$Title = $AppName, [string]$Icon = 'Information')
    $kind = if ($Icon -match 'Error') { 'Error' } elseif ($Icon -match 'Warning|Exclamation') { 'Warning' } else { 'Info' }
    Show-TeslaDialog -Title $Title -Message $Message -Kind $kind
}

function Show-ErrorDetails {
    param(
        [string]$Title,
        [string]$Action,
        [string]$ToolName,
        [string]$Message,
        [string]$Url,
        [string]$Path,
        [string]$Extra
    )

    if ([string]::IsNullOrWhiteSpace($Message)) { $Message = 'Unknown error.' }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Action: $Action") | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($ToolName)) { $lines.Add("Tool: $ToolName") | Out-Null }
    $lines.Add("Error: $Message") | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($Url)) { $lines.Add("URL: $Url") | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace($Path)) { $lines.Add("Path: $Path") | Out-Null }
    if (-not [string]::IsNullOrWhiteSpace($Extra)) { $lines.Add("Details: $Extra") | Out-Null }

    $detail = ($lines -join "`r`n")
    Set-UiState -Title 'Error' -SubTitle $Message -Chip 'Error' -Step $Action -Progress 0
    if ($InlineStatusText) {
        $InlineStatusText.Foreground = Get-Brush '#FF7B7B'
        $InlineStatusText.Text = "Error: $Message"
    }
    $detailsToShow = $detail
    if ($script:Settings -and -not [bool]$script:Settings.DetailedErrorPopups) {
        $detailsToShow = ''
    }
    Show-TeslaDialog -Title $Title -Message $Message -Kind 'Error' -Details $detailsToShow
}

function Show-TeslaSettings {
    [xml]$settingsXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tesla SS Tools Settings"
        Width="610" Height="520"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        ResizeMode="NoResize"
        AllowsTransparency="False"
        Background="#050A10"
        ShowInTaskbar="False"
        Topmost="True"
        UseLayoutRounding="True"
        SnapsToDevicePixels="True"
        FontFamily="Segoe UI">
    <Border Background="#050A10" BorderBrush="#1E3A4E" BorderThickness="1" Padding="22">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel>
                    <TextBlock Text="Settings" FontSize="22" FontWeight="SemiBold" Foreground="White"/>
                    <TextBlock Text="Session options for Tesla SS Tools" FontSize="12" Foreground="#8EA2B6" Margin="0,4,0,0"/>
                </StackPanel>
                <Button x:Name="SettingsCloseButton" Grid.Column="1" Content="X" Width="34" Height="32" Background="#101824" Foreground="White" BorderBrush="#203040" BorderThickness="1" FontWeight="Bold" Cursor="Hand"/>
            </Grid>

            <StackPanel Grid.Row="1" Margin="0,24,0,18">
                <Border CornerRadius="12" Background="#0A141E" BorderBrush="#17364A" BorderThickness="1" Padding="16">
                    <StackPanel>
                        <CheckBox x:Name="AutoLaunchCheck" Content="Auto-launch tools after download" Foreground="#D8E8F5" FontSize="13" Margin="0,0,0,14"/>
                        <CheckBox x:Name="AdminScriptsCheck" Content="Run scripts as administrator" Foreground="#D8E8F5" FontSize="13" Margin="0,0,0,14"/>
                        <CheckBox x:Name="DiscordAdCheck" Content="Show Discord promo after startup" Foreground="#D8E8F5" FontSize="13" Margin="0,0,0,14"/>
                        <CheckBox x:Name="OpenFolderNoLaunchCheck" Content="Open tool folder if no launchable file is found" Foreground="#D8E8F5" FontSize="13" Margin="0,0,0,14"/>
                        <CheckBox x:Name="DetailedErrorsCheck" Content="Show detailed custom error popups" Foreground="#D8E8F5" FontSize="13"/>
                    </StackPanel>
                </Border>

                <Border CornerRadius="12" Background="#07111B" BorderBrush="#203040" BorderThickness="1" Padding="14" Margin="0,14,0,0">
                    <TextBlock Text="These settings apply to this run of the tool. No separate config file is required, so installer.ps1 stays fully standalone." Foreground="#8EA2B6" FontSize="12" TextWrapping="Wrap"/>
                </Border>
            </StackPanel>

            <Grid Grid.Row="2">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="120"/>
                    <ColumnDefinition Width="12"/>
                    <ColumnDefinition Width="130"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="DefaultsButton" Content="Defaults" Height="42" Background="#101824" Foreground="#D8E8F5" BorderBrush="#203040" BorderThickness="1" Cursor="Hand" FontSize="12"/>
                <Button x:Name="CancelSettingsButton" Grid.Column="2" Content="Cancel" Height="42" Background="#101824" Foreground="#D8E8F5" BorderBrush="#203040" BorderThickness="1" Cursor="Hand" FontSize="12"/>
                <Button x:Name="SaveSettingsButton" Grid.Column="4" Content="Save" Height="42" Background="#00A8D8" Foreground="White" BorderBrush="#39E5FF" BorderThickness="1" Cursor="Hand" FontSize="12" FontWeight="SemiBold"/>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    try {
        $settingsReader = New-Object System.Xml.XmlNodeReader $settingsXaml
        $settingsWindow = [Windows.Markup.XamlReader]::Load($settingsReader)
        $settingsWindow.Add_MouseLeftButtonDown({ try { $settingsWindow.DragMove() } catch {} })

        $autoLaunchCheck = $settingsWindow.FindName('AutoLaunchCheck')
        $adminScriptsCheck = $settingsWindow.FindName('AdminScriptsCheck')
        $discordAdCheck = $settingsWindow.FindName('DiscordAdCheck')
        $openFolderNoLaunchCheck = $settingsWindow.FindName('OpenFolderNoLaunchCheck')
        $detailedErrorsCheck = $settingsWindow.FindName('DetailedErrorsCheck')

        $autoLaunchCheck.IsChecked = [bool]$script:Settings.AutoLaunchDownloads
        $adminScriptsCheck.IsChecked = [bool]$script:Settings.RunScriptsAsAdmin
        $discordAdCheck.IsChecked = [bool]$script:Settings.ShowDiscordAd
        $openFolderNoLaunchCheck.IsChecked = [bool]$script:Settings.OpenFolderWhenNoLaunchable
        $detailedErrorsCheck.IsChecked = [bool]$script:Settings.DetailedErrorPopups

        $settingsWindow.FindName('DefaultsButton').Add_Click({
            $autoLaunchCheck.IsChecked = $true
            $adminScriptsCheck.IsChecked = $true
            $discordAdCheck.IsChecked = $true
            $openFolderNoLaunchCheck.IsChecked = $true
            $detailedErrorsCheck.IsChecked = $true
        })

        $settingsWindow.FindName('SaveSettingsButton').Add_Click({
            $script:Settings.AutoLaunchDownloads = [bool]$autoLaunchCheck.IsChecked
            $script:Settings.RunScriptsAsAdmin = [bool]$adminScriptsCheck.IsChecked
            $script:Settings.ShowDiscordAd = [bool]$discordAdCheck.IsChecked
            $script:Settings.OpenFolderWhenNoLaunchable = [bool]$openFolderNoLaunchCheck.IsChecked
            $script:Settings.DetailedErrorPopups = [bool]$detailedErrorsCheck.IsChecked
            $settingsWindow.Close()
            Set-UiState -Title 'Settings saved' -SubTitle 'Session settings were updated.' -Chip 'Ready' -Step 'Settings' -Progress 0
        })

        $settingsWindow.FindName('CancelSettingsButton').Add_Click({ $settingsWindow.Close() })
        $settingsWindow.FindName('SettingsCloseButton').Add_Click({ $settingsWindow.Close() })
        $settingsWindow.ShowDialog() | Out-Null
    }
    catch {
        Show-TeslaDialog -Title 'Tesla SS Tools - Settings Error' -Message 'Could not open settings.' -Kind 'Error' -Details $_.Exception.Message
    }
}

function Get-SafeFileName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return 'download' }
    $invalid = [Regex]::Escape((-join [System.IO.Path]::GetInvalidFileNameChars()))
    $safe = [Regex]::Replace($Name, "[$invalid]", '_')
    $safe = $safe.Trim()
    if ([string]::IsNullOrWhiteSpace($safe)) { return 'download' }
    return $safe
}

function Get-UrlFileName {
    param([string]$Url)
    try {
        $uri = [Uri]$Url
        $name = [System.IO.Path]::GetFileName($uri.LocalPath)
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            return (Get-SafeFileName ([Uri]::UnescapeDataString($name)))
        }
    }
    catch {}
    return 'download'
}

function Get-NormalExtension {
    param([string]$FileName)
    $ext = [System.IO.Path]::GetExtension($FileName)
    if ([string]::IsNullOrWhiteSpace($ext)) { return $null }
    $lower = $ext.ToLowerInvariant()
    $known = @('.exe', '.zip', '.msi', '.ps1', '.cmd', '.bat', '.txt', '.bin', '.dll', '.json')
    if ($known -contains $lower) { return $ext }
    return $null
}

function Get-PrimaryFileName {
    param($Tool)
    $firstUrlName = Get-UrlFileName (@($Tool.Links)[0])
    $ext = Get-NormalExtension $firstUrlName
    if ([string]::IsNullOrWhiteSpace($ext)) { $ext = '.exe' }
    return (Get-SafeFileName $Tool.Name) + $ext
}

function Get-ToolFolder {
    param($Tool, [switch]$Create)
    $folder = Join-Path $ToolsRoot (Get-SafeFileName $Tool.Name)
    if ($Create -and -not (Test-Path -LiteralPath $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
    return $folder
}

function Get-SecondaryFileName {
    param([string]$Url, [int]$Index)
    $name = Get-UrlFileName $Url
    if ($name -eq 'download') { $name = 'download_' + $Index + '.bin' }
    return $name
}

function Get-DownloadTargets {
    param($Tool)
    $destDir = Get-ToolFolder -Tool $Tool -Create
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    }
    $links = @($Tool.Links)
    $targets = @()
    for ($i = 0; $i -lt $links.Count; $i++) {
        if ($i -eq 0) { $fileName = Get-PrimaryFileName $Tool }
        else { $fileName = Get-SecondaryFileName -Url $links[$i] -Index ($i + 1) }
        $targets += [pscustomobject]@{
            Url = [string]$links[$i]
            Path = (Join-Path $destDir $fileName)
            Directory = $destDir
            FileName = $fileName
            Index = ($i + 1)
            Total = $links.Count
        }
    }
    return $targets
}

function Get-ItemKey {
    param($Item)
    return ($Item.Category + '::' + $Item.Name)
}

function Format-Bytes {
    param([Int64]$Bytes)
    if ($Bytes -lt 1024) { return "$Bytes B" }
    if ($Bytes -lt 1048576) { return ('{0:N1} KB' -f ($Bytes / 1024)) }
    return ('{0:N1} MB' -f ($Bytes / 1048576))
}

function Get-CategoryItemCount {
    param([string]$Key)
    if ($Key -eq 'scripts') { return $ScriptActions.Count }
    if ($Key -eq 'credits') { return $Credits.Count }
    return @($DownloadTools | Where-Object { $_.Category -eq $Key }).Count
}

function Get-SelectedItems {
    if ($script:CurrentCategory -eq 'scripts') {
        return @($ScriptActions | Sort-Object Name)
    }
    if ($script:CurrentCategory -eq 'credits') {
        return @($Credits)
    }
    $items = @($DownloadTools | Where-Object { $_.Category -eq $script:CurrentCategory })
    if ($script:CurrentCategory -ne 'dependencies') { $items = @($items | Sort-Object Name) }
    return $items
}

function Update-CategoryButtons {
    foreach ($category in $Categories) {
        $key = $category.Key
        if (-not $script:CategoryButtons.ContainsKey($key)) { continue }
        $button = $script:CategoryButtons[$key]
        $count = Get-CategoryItemCount -Key $key
        $button.Content = "$($category.Label) ($count)"
        if ($key -eq $script:CurrentCategory) {
            $button.Background = $window.Resources['PrimaryButtonBrush']
        }
        else {
            $button.Background = $window.Resources['NeutralButtonBrush']
        }
    }
}

function New-TextBlock {
    param(
        [string]$Text,
        [double]$Size = 12,
        [string]$Color = '#D8E8F5',
        [string]$Weight = 'Normal'
    )
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.FontSize = $Size
    $tb.Foreground = Get-Brush $Color
    $tb.FontWeight = $Weight
    $tb.TextWrapping = 'Wrap'
    return $tb
}

function New-ToolCard {
    param($Item)
    $button = New-Object System.Windows.Controls.Button
    $button.Style = $window.Resources['ToolCardButtonStyle']
    $button.Width = 210
    $button.Height = 58
    $button.Margin = New-Object System.Windows.Thickness 7,7,7,7
    $button.ToolTip = $Item.Description

    $grid = New-Object System.Windows.Controls.Grid
    $rowMain = New-Object System.Windows.Controls.RowDefinition
    $rowMain.Height = New-Object System.Windows.GridLength 1,([System.Windows.GridUnitType]::Star)
    $rowProgress = New-Object System.Windows.Controls.RowDefinition
    $rowProgress.Height = New-Object System.Windows.GridLength 4
    $grid.RowDefinitions.Add($rowMain) | Out-Null
    $grid.RowDefinitions.Add($rowProgress) | Out-Null

    $name = New-TextBlock -Text $Item.Name -Size 13.5 -Color '#FFFFFF' -Weight 'SemiBold'
    $name.TextTrimming = 'CharacterEllipsis'
    $name.HorizontalAlignment = 'Center'
    $name.VerticalAlignment = 'Center'
    $name.TextAlignment = 'Center'
    $name.Margin = New-Object System.Windows.Thickness 10,0,10,0
    [System.Windows.Controls.Grid]::SetRow($name, 0)
    $grid.Children.Add($name) | Out-Null

    $progress = New-Object System.Windows.Controls.ProgressBar
    $progress.Minimum = 0
    $progress.Maximum = 100
    $progress.Value = 0
    $progress.Height = 3
    $progress.Margin = New-Object System.Windows.Thickness 8,0,8,0
    $progress.Foreground = Get-Brush '#22D6FF'
    $progress.Background = Get-Brush '#091018'
    $progress.BorderThickness = New-Object System.Windows.Thickness 0
    [System.Windows.Controls.Grid]::SetRow($progress, 1)
    $grid.Children.Add($progress) | Out-Null
    $button.Content = $grid

    $key = Get-ItemKey $Item
    $script:CardProgressBars[$key] = $progress

    if ($Item.Kind -eq 'Script' -or $Item.Kind -eq 'Link') {
        $progress.Visibility = 'Hidden'
    }
    else {
        $primaryPath = Join-Path (Get-ToolFolder -Tool $Item) (Get-PrimaryFileName $Item)
        if (Test-Path -LiteralPath $primaryPath) {
            $progress.Value = 100
        }
    }

    $itemForClick = $Item
    $button.Add_Click({ Invoke-ItemAction -Item $itemForClick }.GetNewClosure())
    return $button
}

function New-CreditCard {
    param($Credit)
    $border = New-Object System.Windows.Controls.Border
    $border.Width = 350
    $border.MinHeight = 132
    $border.Margin = New-Object System.Windows.Thickness 0,0,12,12
    $border.Padding = New-Object System.Windows.Thickness 16
    $border.Background = $window.Resources['CardBackground']
    $border.BorderBrush = Get-Brush '#203040'
    $border.BorderThickness = New-Object System.Windows.Thickness 1
    $border.CornerRadius = New-Object System.Windows.CornerRadius 18

    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.Children.Add((New-TextBlock -Text $Credit.Name -Size 15 -Color '#FFFFFF' -Weight 'SemiBold')) | Out-Null
    $role = New-TextBlock -Text $Credit.Role -Size 12 -Color '#D8E8F5'
    $role.Margin = New-Object System.Windows.Thickness 0,8,0,0
    $stack.Children.Add($role) | Out-Null
    $source = New-TextBlock -Text $Credit.Source -Size 11 -Color '#74E8FF'
    $source.Margin = New-Object System.Windows.Thickness 0,8,0,0
    $stack.Children.Add($source) | Out-Null
    $border.Child = $stack
    return $border
}

function Render-CurrentCategory {
    $ToolWrapPanel.Children.Clear()
    $script:CardIndicators.Clear()
    $script:CardProgressBars.Clear()

    $category = $Categories | Where-Object { $_.Key -eq $script:CurrentCategory } | Select-Object -First 1
    if (-not $category) { return }

    $SelectedCategoryText.Text = $category.Label
    $SelectedCategoryDescription.Text = $category.Description
    $CategoryHeaderText.Text = $category.Header
    $ToolCountText.Text = (Get-CategoryItemCount -Key $category.Key).ToString()

    if ($category.Key -eq 'scripts' -or $category.Key -eq 'credits') {
        $DownloadAllButton.Visibility = 'Collapsed'
        $CancelDownloadButton.Visibility = 'Collapsed'
    }
    else {
        $DownloadAllButton.Visibility = 'Visible'
        $CancelDownloadButton.Visibility = 'Visible'
    }

    $items = @(Get-SelectedItems)
    if ($items.Count -eq 0) {
        $empty = New-TextBlock -Text 'No items in this category.' -Size 14 -Color '#8EA2B6'
        $ToolWrapPanel.Children.Add($empty) | Out-Null
    }
    elseif ($category.Key -eq 'credits') {
        foreach ($credit in $items) {
            $ToolWrapPanel.Children.Add((New-CreditCard -Credit $credit)) | Out-Null
        }
    }
    else {
        foreach ($item in $items) {
            $ToolWrapPanel.Children.Add((New-ToolCard -Item $item)) | Out-Null
        }
    }

    Update-CategoryButtons
    Refresh-Ui
}

function Switch-Category {
    param([string]$Key)
    $script:CurrentCategory = $Key
    Render-CurrentCategory
    Set-UiState -Title 'Ready' -SubTitle "Showing $($SelectedCategoryText.Text)." -Chip 'Ready' -Step 'Waiting' -Progress 0
}

function Add-CategoryButton {
    param($Category)
    $button = New-Object System.Windows.Controls.Button
    $button.Style = $window.Resources['ActionButtonStyle']
    $button.ToolTip = $Category.Header
    $button.Content = $Category.Label
    $key = $Category.Key
    $button.Add_Click({ Switch-Category -Key $key }.GetNewClosure())
    $CategoryButtonPanel.Children.Add($button) | Out-Null
    $script:CategoryButtons[$Category.Key] = $button
}

function Set-CardDownloading {
    param($Job, [bool]$Indeterminate)
    $key = $Job.Category + '::' + $Job.Name
    if ($script:CardIndicators.ContainsKey($key)) {
        $script:CardIndicators[$key].Background = Get-Brush '#DDAAFF'
    }
    if ($script:CardProgressBars.ContainsKey($key)) {
        $bar = $script:CardProgressBars[$key]
        $bar.IsIndeterminate = $Indeterminate
        if (-not $Indeterminate) { $bar.Value = 0 }
    }
}

function Set-CardProgress {
    param($Job, [double]$Percent, [bool]$HasPercent)
    $key = $Job.Category + '::' + $Job.Name
    if ($script:CardProgressBars.ContainsKey($key)) {
        $bar = $script:CardProgressBars[$key]
        if ($HasPercent) {
            $bar.IsIndeterminate = $false
            $bar.Value = [Math]::Max(0, [Math]::Min(100, $Percent))
        }
        else {
            $bar.IsIndeterminate = $true
        }
    }
}

function Set-CardComplete {
    param($Job, [bool]$Success)
    $key = $Job.Category + '::' + $Job.Name
    if ($script:CardIndicators.ContainsKey($key)) {
        $script:CardIndicators[$key].Background = if ($Success) { Get-Brush '#22C55E' } else { Get-Brush '#EF4444' }
    }
    if ($script:CardProgressBars.ContainsKey($key)) {
        $bar = $script:CardProgressBars[$key]
        $bar.IsIndeterminate = $false
        $bar.Value = if ($Success) { 100 } else { 0 }
    }
}

function New-DownloadJob {
    param($Tool, [bool]$Batch)
    $targets = @(Get-DownloadTargets -Tool $Tool)
    $toolDir = Get-ToolFolder -Tool $Tool -Create
    $primaryPath = $null
    $isZip = $false
    if ($targets.Count -gt 0) {
        $primaryPath = [string]$targets[0].Path
        $isZip = ([System.IO.Path]::GetExtension($primaryPath).ToLowerInvariant() -eq '.zip')
    }
    return [pscustomobject]@{
        Name = [string]$Tool.Name
        Description = [string]$Tool.Description
        Category = [string]$Tool.Category
        Batch = [bool]$Batch
        Directory = $toolDir
        Targets = $targets
        PrimaryPath = $primaryPath
        IsZip = $isZip
    }
}

function Start-NextDownload {
    if ($script:CurrentWorker -ne $null) { return }
    if ($script:DownloadQueue.Count -eq 0) {
        $script:BatchActive = $false
        $CancelDownloadButton.IsEnabled = $false
        return
    }

    $job = $script:DownloadQueue.Dequeue()
    $script:ActiveDownloadJob = $job
    $CancelDownloadButton.IsEnabled = $true
    Set-CardDownloading -Job $job -Indeterminate $true
    Set-UiState -Title 'Downloading tool' -SubTitle "Downloading $($job.Name)." -Chip 'Downloading' -Step $job.Name -Progress 0
    Write-Activity "[INFO] Download started: $($job.Name)"

    $MainProgressBar.IsIndeterminate = $true
    $ProgressLabel.Text = '...'
    Set-CardProgress -Job $job -Percent 0 -HasPercent $false
    if ($InlineStatusText) { $InlineStatusText.Text = "Downloading $($job.Name): resolving source" }

    try {
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $runspace.ApartmentState = 'STA'
        $runspace.ThreadOptions = 'ReuseThread'
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable('downloadJob', $job)

        $powerShell = [powershell]::Create()
        $powerShell.Runspace = $runspace
        $null = $powerShell.AddScript({
            $jobArg = $downloadJob
            $result = [pscustomobject]@{
                Job = $jobArg
                Success = $false
                Cancelled = $false
                Error = $null
                ErrorType = $null
                ErrorUrl = $null
                ErrorPath = $null
                PrimaryPath = $jobArg.PrimaryPath
                IsZip = $jobArg.IsZip
                Directory = $jobArg.Directory
                LaunchPath = $null
                DownloadedPaths = @()
            }

            function Resolve-TeslaDownloadTarget {
                param($Target)

                $url = [string]$Target.Url
                $resolved = [pscustomobject]@{
                    Url = $url
                    FileName = [string]$Target.FileName
                    Path = [string]$Target.Path
                }

                $apiUrl = $null
                $apiRequired = $true
                if ($url -match 'github\.com/([^/]+)/([^/]+)/releases/latest/?$') {
                    $apiUrl = "https://api.github.com/repos/$($Matches[1])/$($Matches[2])/releases/latest"
                }
                elseif ($url -match 'github\.com/([^/]+)/([^/]+)/releases/?$') {
                    $apiUrl = "https://api.github.com/repos/$($Matches[1])/$($Matches[2])/releases/latest"
                }
                elseif ($url -match 'github\.com/([^/]+)/([^/]+)/releases/tag/(.+)$') {
                    $tag = [Uri]::EscapeDataString(([Uri]::UnescapeDataString($Matches[3])).TrimEnd('/'))
                    $apiUrl = "https://api.github.com/repos/$($Matches[1])/$($Matches[2])/releases/tags/$tag"
                }
                elseif ($url -match 'github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)$') {
                    $tag = [Uri]::EscapeDataString(([Uri]::UnescapeDataString($Matches[3])).TrimEnd('/'))
                    $apiUrl = "https://api.github.com/repos/$($Matches[1])/$($Matches[2])/releases/tags/$tag"
                    $apiRequired = $false
                }

                if ($apiUrl) {
                    try {
                        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'Tesla SS Tools' } -ErrorAction Stop
                        $asset = $release.assets |
                            Where-Object { $_.name -match '\.(exe|zip|msi|cmd|bat)$' } |
                            Sort-Object @{ Expression = {
                                $ext = [System.IO.Path]::GetExtension($_.name).ToLowerInvariant()
                                switch ($ext) {
                                    '.exe' { 0 }
                                    '.msi' { 1 }
                                    '.zip' { 2 }
                                    '.cmd' { 3 }
                                    '.bat' { 4 }
                                    default { 9 }
                                }
                            }}, name |
                            Select-Object -First 1
                        if (-not $asset) {
                            if ($apiRequired) { throw "No downloadable GitHub release asset was found at $apiUrl." }
                        }
                        else {
                            $resolved.Url = [string]$asset.browser_download_url
                            $resolved.FileName = [string]$asset.name
                            $resolved.Path = Join-Path ([string]$Target.Directory) ([string]$asset.name)
                        }
                    }
                    catch {
                        if ($apiRequired) { throw }
                    }
                }

                return $resolved
            }

            function Save-TeslaUrlToFile {
                param([string]$Uri, [string]$OutFile)

                $outDir = Split-Path -Parent $OutFile
                if (-not (Test-Path -LiteralPath $outDir)) {
                    New-Item -Path $outDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }

                $tempFile = "$OutFile.download"
                if (Test-Path -LiteralPath $tempFile) {
                    Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
                }

                $client = New-Object System.Net.WebClient
                $client.Headers.Add('User-Agent', 'Tesla SS Tools')
                try {
                    $client.DownloadFile($Uri, $tempFile)
                    if (Test-Path -LiteralPath $OutFile) {
                        Remove-Item -LiteralPath $OutFile -Force -ErrorAction Stop
                    }
                    Move-Item -LiteralPath $tempFile -Destination $OutFile -Force -ErrorAction Stop
                }
                finally {
                    $client.Dispose()
                    if (Test-Path -LiteralPath $tempFile) {
                        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }

            function Find-TeslaLaunchable {
                param([string]$Directory, [string]$PreferredPath)

                if ($PreferredPath -and (Test-Path -LiteralPath $PreferredPath)) {
                    $preferredExt = [System.IO.Path]::GetExtension($PreferredPath).ToLowerInvariant()
                    if (@('.exe', '.msi', '.cmd', '.bat') -contains $preferredExt) {
                        return $PreferredPath
                    }
                }

                $launchable = Get-ChildItem -Path $Directory -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { @('.exe', '.msi', '.cmd', '.bat') -contains $_.Extension.ToLowerInvariant() } |
                    Sort-Object @{ Expression = {
                        switch ($_.Extension.ToLowerInvariant()) {
                            '.exe' { 0 }
                            '.msi' { 1 }
                            '.cmd' { 2 }
                            '.bat' { 3 }
                            default { 9 }
                        }
                    }}, FullName |
                    Select-Object -First 1

                if ($launchable) { return $launchable.FullName }
                return $null
            }

            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                if (-not (Test-Path -LiteralPath $jobArg.Directory)) {
                    New-Item -Path $jobArg.Directory -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }

                foreach ($target in $jobArg.Targets) {
                    $result.ErrorUrl = $target.Url
                    $result.ErrorPath = $target.Path

                    $resolvedTarget = Resolve-TeslaDownloadTarget -Target $target
                    $target.Url = $resolvedTarget.Url
                    $target.FileName = $resolvedTarget.FileName
                    $target.Path = $resolvedTarget.Path
                    $result.ErrorUrl = $resolvedTarget.Url
                    $result.ErrorPath = $resolvedTarget.Path

                    if ($target.Index -eq 1) {
                        $result.PrimaryPath = $resolvedTarget.Path
                        $result.IsZip = ([System.IO.Path]::GetExtension($resolvedTarget.Path).ToLowerInvariant() -eq '.zip')
                    }

                    if (-not (Test-Path -LiteralPath $resolvedTarget.Path)) {
                        Save-TeslaUrlToFile -Uri $resolvedTarget.Url -OutFile $resolvedTarget.Path
                    }

                    $result.DownloadedPaths += [string]$resolvedTarget.Path
                }

                if ($result.PrimaryPath -and ([System.IO.Path]::GetExtension($result.PrimaryPath).ToLowerInvariant() -eq '.zip')) {
                    Expand-Archive -Path $result.PrimaryPath -DestinationPath $jobArg.Directory -Force -ErrorAction Stop
                }

                $result.LaunchPath = Find-TeslaLaunchable -Directory $jobArg.Directory -PreferredPath $result.PrimaryPath
                $result.Success = $true
                $result
            }
            catch {
                $result.Error = $_.Exception.Message
                if ($_.Exception) { $result.ErrorType = $_.Exception.GetType().FullName }
                $result
            }
        })

        $handle = $powerShell.BeginInvoke()
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(250)

        $script:CurrentWorker = [pscustomobject]@{
            PowerShell = $powerShell
            Runspace = $runspace
            Handle = $handle
            Timer = $timer
            Job = $job
            CancelRequested = $false
        }

        $timer.Add_Tick({
            if (-not $script:CurrentWorker) { return }
            if (-not $script:CurrentWorker.Handle.IsCompleted) { return }

            $workerState = $script:CurrentWorker
            $workerState.Timer.Stop()
            $result = $null
            $wasCancelled = [bool]$workerState.CancelRequested

            try {
                if ($wasCancelled) {
                    $result = [pscustomobject]@{ Job = $workerState.Job; Success = $false; Cancelled = $true; Error = $null; ErrorType = $null; ErrorUrl = $null; ErrorPath = $workerState.Job.Directory; PrimaryPath = $workerState.Job.PrimaryPath; IsZip = $workerState.Job.IsZip; Directory = $workerState.Job.Directory; LaunchPath = $null; DownloadedPaths = @() }
                }
                else {
                    $output = $workerState.PowerShell.EndInvoke($workerState.Handle)
                    if ($output -and $output.Count -gt 0) {
                        $result = $output[$output.Count - 1]
                    }
                    if (-not $result) {
                        $result = [pscustomobject]@{ Job = $workerState.Job; Success = $false; Cancelled = $false; Error = 'The download worker finished but did not return a result object.'; ErrorType = 'MissingResult'; ErrorUrl = $null; ErrorPath = $workerState.Job.Directory; PrimaryPath = $workerState.Job.PrimaryPath; IsZip = $workerState.Job.IsZip; Directory = $workerState.Job.Directory; LaunchPath = $null; DownloadedPaths = @() }
                    }
                }
            }
            catch {
                if ($wasCancelled) {
                    $result = [pscustomobject]@{ Job = $workerState.Job; Success = $false; Cancelled = $true; Error = $null; ErrorType = $null; ErrorUrl = $null; ErrorPath = $workerState.Job.Directory; PrimaryPath = $workerState.Job.PrimaryPath; IsZip = $workerState.Job.IsZip; Directory = $workerState.Job.Directory; LaunchPath = $null; DownloadedPaths = @() }
                }
                else {
                    $result = [pscustomobject]@{ Job = $workerState.Job; Success = $false; Cancelled = $false; Error = $_.Exception.Message; ErrorType = $_.Exception.GetType().FullName; ErrorUrl = $null; ErrorPath = $workerState.Job.Directory; PrimaryPath = $workerState.Job.PrimaryPath; IsZip = $workerState.Job.IsZip; Directory = $workerState.Job.Directory; LaunchPath = $null; DownloadedPaths = @() }
                }
            }
            finally {
                try { $workerState.PowerShell.Dispose() } catch {}
                try { $workerState.Runspace.Close() } catch {}
                try { $workerState.Runspace.Dispose() } catch {}
            }

            $jobDone = $result.Job
            if (-not $jobDone) {
                $script:CurrentWorker = $null
                $script:ActiveDownloadJob = $null
                $CancelDownloadButton.IsEnabled = $false
                $MainProgressBar.IsIndeterminate = $false
                Set-UiState -Title 'Download stopped' -SubTitle 'The download ended without a job result.' -Chip 'Error' -Step 'Stopped' -Progress 0
                Write-Activity '[INFO] Download ended without a job result.'
                Show-ErrorDetails -Title 'Tesla SS Tools - Download Error' -Action 'Download' -ToolName '' -Message 'The download ended without a job result.' -Url '' -Path '' -Extra 'No job object was returned by the download runspace.'
                Start-NextDownload
                return
            }

            $script:CurrentWorker = $null
            $script:ActiveDownloadJob = $null
            $MainProgressBar.IsIndeterminate = $false
            $CancelDownloadButton.IsEnabled = $false

            if ($result.Cancelled) {
                Set-CardComplete -Job $jobDone -Success $false
                Set-UiState -Title 'Download cancelled' -SubTitle "$($jobDone.Name) was cancelled." -Chip 'Cancelled' -Step 'Cancelled' -Progress 0
                Write-Activity "[INFO] Download cancelled: $($jobDone.Name)"
            }
            elseif ($result.Success) {
                Set-CardComplete -Job $jobDone -Success $true
                Set-UiState -Title 'Download complete' -SubTitle "$($jobDone.Name) saved successfully." -Chip 'Ready' -Step 'Completed' -Progress 100
                Write-Activity "[OK] Saved: $($result.PrimaryPath)"
                if (-not $jobDone.Batch -and $result.LaunchPath -and [bool]$script:Settings.AutoLaunchDownloads) {
                    Start-DownloadedTool -Path $result.LaunchPath -Name $jobDone.Name -Directory $result.Directory
                }
                elseif (-not $jobDone.Batch -and $result.LaunchPath) {
                    Set-UiState -Title 'Downloaded' -SubTitle "$($jobDone.Name) was saved. Auto-launch is disabled in settings." -Chip 'Ready' -Step 'Downloaded' -Progress 100
                    Write-Activity "[INFO] Auto-launch disabled for $($jobDone.Name)."
                }
                elseif (-not $jobDone.Batch -and $result.Directory) {
                    Set-UiState -Title 'Downloaded' -SubTitle "$($jobDone.Name) was saved, but no launchable file was found." -Chip 'Ready' -Step 'Open folder' -Progress 100
                    if ([bool]$script:Settings.OpenFolderWhenNoLaunchable) {
                        Start-Process 'explorer.exe' -ArgumentList $result.Directory
                        Write-Activity "[INFO] No launchable file found for $($jobDone.Name). Opened folder."
                    }
                    else {
                        Write-Activity "[INFO] No launchable file found for $($jobDone.Name). Folder open disabled."
                    }
                }
            }
            else {
                $message = if ($result.Error) { $result.Error } else { 'Unknown download error.' }
                Set-CardComplete -Job $jobDone -Success $false
                Set-UiState -Title 'Download failed' -SubTitle $message -Chip 'Error' -Step 'Failed' -Progress 0
                Write-Activity "[ERROR] $($jobDone.Name): $message"
                Show-ErrorDetails -Title 'Tesla SS Tools - Download Error' -Action 'Download' -ToolName $jobDone.Name -Message $message -Url $result.ErrorUrl -Path $result.ErrorPath -Extra $result.ErrorType
            }

            Start-NextDownload
        })

        $timer.Start()
    }
    catch {
        $script:CurrentWorker = $null
        $script:ActiveDownloadJob = $null
        $MainProgressBar.IsIndeterminate = $false
        $CancelDownloadButton.IsEnabled = $false
        Set-CardComplete -Job $job -Success $false
        Set-UiState -Title 'Download failed' -SubTitle $_.Exception.Message -Chip 'Error' -Step 'Failed' -Progress 0
        Write-Activity "[ERROR] Could not start download runspace for $($job.Name): $($_.Exception.Message)"
        Show-ErrorDetails -Title 'Tesla SS Tools - Download Error' -Action 'Start download worker' -ToolName $job.Name -Message $_.Exception.Message -Url '' -Path $job.Directory -Extra $_.Exception.GetType().FullName
        Start-NextDownload
    }
}

function Queue-Download {
    param($Tool, [bool]$Batch)
    try {
        $job = New-DownloadJob -Tool $Tool -Batch $Batch
        $script:DownloadQueue.Enqueue($job)
        if ($Batch) { $script:BatchActive = $true }
        if ($script:CurrentWorker -ne $null) {
            Write-Activity "[INFO] Queued: $($Tool.Name)"
        }
        Start-NextDownload
    }
    catch {
        Set-UiState -Title 'Queue failed' -SubTitle $_.Exception.Message -Chip 'Error' -Step 'Failed' -Progress 0
        Write-Activity "[ERROR] Could not queue $($Tool.Name): $($_.Exception.Message)"
        Show-ErrorDetails -Title 'Tesla SS Tools - Queue Error' -Action 'Queue download' -ToolName $Tool.Name -Message $_.Exception.Message -Url '' -Path $ToolsRoot -Extra $_.Exception.GetType().FullName
    }
}

function Start-DownloadedTool {
    param([string]$Path, [string]$Name, [string]$Directory)
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            throw "File not found: $Path"
        }
        if ([string]::IsNullOrWhiteSpace($Directory)) {
            $Directory = Split-Path -Parent $Path
        }
        $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        if ($extension -eq '.cmd' -or $extension -eq '.bat') {
            $psi.FileName = 'cmd.exe'
            $psi.Arguments = '/k "' + $Path + '"'
        }
        else {
            $psi.FileName = $Path
        }
        $psi.WorkingDirectory = $Directory
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Set-UiState -Title 'Tool launched' -SubTitle "$Name launched successfully." -Chip 'Ready' -Step 'Launched' -Progress 100
        Write-Activity "[OK] Launched: $Name"
    }
    catch {
        Set-UiState -Title 'Launch failed' -SubTitle $_.Exception.Message -Chip 'Error' -Step 'Failed' -Progress 0
        Write-Activity "[ERROR] Launch failed for ${Name}: $($_.Exception.Message)"
        Show-ErrorDetails -Title 'Tesla SS Tools - Launch Error' -Action 'Launch downloaded tool' -ToolName $Name -Message $_.Exception.Message -Url '' -Path $Path -Extra $_.Exception.GetType().FullName
    }
}

function Start-ScriptAction {
    param($ScriptItem)
    $ps1Path = $null
    try {
        if (-not (Test-Path -LiteralPath $TempRoot)) { New-Item -Path $TempRoot -ItemType Directory -Force | Out-Null }
        $fileName = 'Tesla_SS_Tools_script_' + [DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss_fff') + '.ps1'
        $ps1Path = Join-Path $TempRoot $fileName
        $header = "`$Host.UI.RawUI.WindowTitle = 'Tesla SS Tools - $($ScriptItem.Name)'`r`n"
        $body = $header + $ScriptItem.Command + "`r`n"
        $utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false
        [System.IO.File]::WriteAllText($ps1Path, $body, $utf8NoBom)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'cmd.exe'
        $psi.Arguments = '/k title Tesla SS Tools Script & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + $ps1Path + '"'
        $psi.UseShellExecute = $true
        if ([bool]$script:Settings.RunScriptsAsAdmin) { $psi.Verb = 'runas' }
        $proc = [System.Diagnostics.Process]::Start($psi)
        if ($proc) {
            $proc.EnableRaisingEvents = $true
            Register-ObjectEvent -InputObject $proc -EventName Exited -Action {
                Remove-Item -LiteralPath $Event.MessageData -Force -ErrorAction SilentlyContinue
            } -MessageData $ps1Path | Out-Null
        }
        Set-UiState -Title 'Script launched' -SubTitle "$($ScriptItem.Name) opened in a visible console window." -Chip 'Running' -Step $ScriptItem.Name -Progress 100
        Write-Activity "[OK] Script launched: $($ScriptItem.Name)"
    }
    catch {
        Set-UiState -Title 'Script failed' -SubTitle $_.Exception.Message -Chip 'Error' -Step 'Failed' -Progress 0
        Write-Activity "[ERROR] Script failed for $($ScriptItem.Name): $($_.Exception.Message)"
        Show-ErrorDetails -Title 'Tesla SS Tools - Script Error' -Action 'Run script as admin' -ToolName $ScriptItem.Name -Message $_.Exception.Message -Url '' -Path $ps1Path -Extra $_.Exception.GetType().FullName
    }
}

function Invoke-ItemAction {
    param($Item)
    if ($Item.Kind -eq 'Script') {
        Start-ScriptAction -ScriptItem $Item
        return
    }
    if ($Item.Kind -eq 'Link') {
        $url = @($Item.Links)[0]
        try {
            Start-Process $url
            Set-UiState -Title 'Opened link' -SubTitle "$($Item.Name) opened in your browser." -Chip 'Ready' -Step 'Browser' -Progress 0
        }
        catch {
            Show-ErrorDetails -Title 'Tesla SS Tools - Link Error' -Action 'Open link' -ToolName $Item.Name -Message $_.Exception.Message -Url $url -Path '' -Extra $_.Exception.GetType().FullName
        }
        return
    }
    Queue-Download -Tool $Item -Batch:$false
}

function Download-AllCurrentCategory {
    if ($script:CurrentCategory -eq 'scripts' -or $script:CurrentCategory -eq 'credits') { return }
    $items = @(Get-SelectedItems | Where-Object { $_.Kind -eq 'Download' })
    if ($items.Count -eq 0) { return }
    Write-Activity "[INFO] Batch download queued for $($SelectedCategoryText.Text): $($items.Count) item(s)"
    foreach ($item in $items) {
        Queue-Download -Tool $item -Batch:$true
    }
}

function Cancel-CurrentDownload {
    if ($script:CurrentWorker -ne $null) {
        $script:CurrentWorker.CancelRequested = $true
        try { $script:CurrentWorker.PowerShell.Stop() } catch {}
        $CancelDownloadButton.IsEnabled = $false
        Write-Activity '[INFO] Cancel requested for current download.'
    }
}

function Open-ToolsFolder {
    try {
        if (-not (Test-Path -LiteralPath $ToolsRoot)) { New-Item -Path $ToolsRoot -ItemType Directory -Force | Out-Null }
        Start-Process 'explorer.exe' -ArgumentList $ToolsRoot
        Write-Activity "[OK] Opened tools folder: $ToolsRoot"
    }
    catch {
        Write-Activity "[ERROR] Could not open tools folder: $($_.Exception.Message)"
        Show-ErrorDetails -Title 'Tesla SS Tools - Folder Error' -Action 'Open tools folder' -ToolName '' -Message $_.Exception.Message -Url '' -Path $ToolsRoot -Extra $_.Exception.GetType().FullName
    }
}

function Open-DiscordInvite {
    try {
        Start-Process $DiscordInvite
        Write-Activity '[OK] Opened Tesla SS Course Discord invite.'
    }
    catch {
        Write-Activity "[ERROR] Could not open Discord invite: $($_.Exception.Message)"
        Show-ErrorDetails -Title 'Tesla SS Tools - Discord Error' -Action 'Open Discord invite' -ToolName 'Discord' -Message $_.Exception.Message -Url $DiscordInvite -Path '' -Extra $_.Exception.GetType().FullName
    }
}

foreach ($category in $Categories) {
    Add-CategoryButton -Category $category
}

$HeaderBar.Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
$CloseButton.Add_Click({ $window.Close() })
$MinButton.Add_Click({ $window.WindowState = 'Minimized' })
$DiscordButton.ToolTip = $DiscordTooltip
$DiscordButton.Add_Click({ Open-DiscordInvite })
$DownloadAllButton.Add_Click({ Download-AllCurrentCategory })
$CancelDownloadButton.Add_Click({ Cancel-CurrentDownload })
$OpenToolsFolderButton.Add_Click({ Open-ToolsFolder })
$SettingsButton.Add_Click({ Show-TeslaSettings })

$window.Add_PreviewKeyDown({
    param($sender, $e)
    if ($e.Key -eq 'Escape') {
        if ($script:CurrentWorker -ne $null) { Cancel-CurrentDownload }
        $e.Handled = $true
    }
})

try {
    $window.Opacity = 0
    $window.Add_ContentRendered({
        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeIn.From = 0
        $fadeIn.To = 1
        $fadeIn.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(220))
        $window.BeginAnimation([System.Windows.Window]::OpacityProperty, $fadeIn)
    })
}
catch {}

Render-CurrentCategory
Set-UiState -Title 'Ready' -SubTitle 'Everything is ready. Pick a category on the left.' -Chip 'Ready' -Step 'Waiting' -Progress 0
Write-Activity '[OK] Tesla SS Tools started'
Write-Activity "[INFO] Tools folder: $ToolsRoot"
Write-Activity "[INFO] Temp folder: $TempRoot"
Write-Activity ("[INFO] Loaded {0} downloadable tools and dependencies" -f $DownloadTools.Count)
Write-Activity ("[INFO] Loaded {0} script actions" -f $ScriptActions.Count)
Write-Activity ("[INFO] Loaded {0} credits" -f $Credits.Count)
foreach ($warning in $script:StartupWarnings) { Write-Activity "[INFO] $warning" }

if ($SplashWindow) {
    foreach ($step in @(
        @{ Text = 'Loading OrbDiff, Spokwn and community tools...'; Progress = 42 },
        @{ Text = 'Priming GitHub resolver and download cache...'; Progress = 64 },
        @{ Text = 'Preparing admin script console flow...'; Progress = 82 },
        @{ Text = 'Tesla SS Course systems online.'; Progress = 100 }
    )) {
        Update-Splash -Text $step.Text -Progress $step.Progress
        Start-Sleep -Milliseconds 150
    }
    $SplashWindow.Close()
}

if ([bool]$script:Settings.ShowDiscordAd) {
    Show-TeslaDiscordAd
}
$window.ShowDialog() | Out-Null
