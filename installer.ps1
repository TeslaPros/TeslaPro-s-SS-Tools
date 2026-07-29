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

$ScriptRoot = if ($script:EntryPath) { Split-Path -Parent $script:EntryPath } else { (Get-Location).Path }
$AppRoot = Join-Path $ScriptRoot 'teslatool'
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

[xml]$splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tesla SS Tools Loading"
        Width="520" Height="280"
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
    <Border Background="#050A10" BorderBrush="#1E3A4E" BorderThickness="1" Padding="26">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <StackPanel Orientation="Horizontal">
                <Border Width="58" Height="58" CornerRadius="12" Background="#0C1824" BorderBrush="#2F6F88" BorderThickness="1">
                    <Grid>
                        <TextBlock Text="T" FontSize="28" FontWeight="Bold" Foreground="#7BE9FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        <Border Height="2" Background="#39E5FF" VerticalAlignment="Bottom" Margin="10,0,10,9"/>
                    </Grid>
                </Border>
                <StackPanel Margin="14,0,0,0" VerticalAlignment="Center">
                    <TextBlock Text="Tesla SS Tools" FontSize="24" FontWeight="SemiBold" Foreground="White"/>
                    <TextBlock x:Name="SplashStatusText" Text="Starting interface..." FontSize="12" Foreground="#8EA2B6" Margin="0,5,0,0"/>
                </StackPanel>
            </StackPanel>
            <StackPanel Grid.Row="1" Margin="0,28,0,18">
                <Border Height="34" CornerRadius="8" Background="#08121C" BorderBrush="#17364A" BorderThickness="1" Padding="12,0">
                    <TextBlock Text="Loading tools, scripts, downloads and UI modules" Foreground="#D8E8F5" FontSize="12" VerticalAlignment="Center"/>
                </Border>
                <Grid Margin="0,16,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="8"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="8"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Border Height="5" CornerRadius="3" Background="#123446"/>
                    <Border Grid.Column="2" Height="5" CornerRadius="3" Background="#164D63"/>
                    <Border Grid.Column="4" Height="5" CornerRadius="3" Background="#1E7C99"/>
                </Grid>
                <ProgressBar x:Name="SplashProgressBar" Height="8" Minimum="0" Maximum="100" Value="10" Foreground="#22D6FF" Background="#091018" BorderThickness="0" Margin="0,20,0,0"/>
            </StackPanel>
            <TextBlock Grid.Row="2" Text="Tesla SS Course ready" Foreground="#7E92A6" FontSize="12" HorizontalAlignment="Center"/>
        </Grid>
    </Border>
</Window>
"@

try {
    $splashReader = New-Object System.Xml.XmlNodeReader $splashXaml
    $SplashWindow = [Windows.Markup.XamlReader]::Load($splashReader)
    $SplashStatusText = $SplashWindow.FindName('SplashStatusText')
    $SplashProgressBar = $SplashWindow.FindName('SplashProgressBar')
    $SplashWindow.Show()
    $SplashWindow.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}
catch {
    $SplashWindow = $null
}

function Update-Splash {
    param([string]$Text, [double]$Progress)
    if (-not $SplashWindow) { return }
    if ($SplashStatusText) { $SplashStatusText.Text = $Text }
    if ($SplashProgressBar) { $SplashProgressBar.Value = $Progress }
    $SplashWindow.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

Update-Splash -Text 'Loading categories...' -Progress 25
Start-Sleep -Milliseconds 120

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
    [System.Windows.MessageBox]::Show($window, $Message, $Title, 'OK', $Icon) | Out-Null
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
    [System.Windows.MessageBox]::Show($window, $detail, $Title, 'OK', 'Error') | Out-Null
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

function Get-SecondaryFileName {
    param([string]$Url, [int]$Index)
    $name = Get-UrlFileName $Url
    if ($name -eq 'download') { $name = 'download_' + $Index + '.bin' }
    return $name
}

function Get-DownloadTargets {
    param($Tool)
    $destDir = $ToolsRoot
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

    if ($Item.Kind -eq 'Script') {
        $progress.Visibility = 'Hidden'
    }
    else {
        $primaryPath = Join-Path $ToolsRoot (Get-PrimaryFileName $Item)
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
    return [pscustomobject]@{
        Name = [string]$Tool.Name
        Description = [string]$Tool.Description
        Category = [string]$Tool.Category
        Batch = [bool]$Batch
        Targets = $targets
        PrimaryPath = if ($targets.Count -gt 0) { [string]$targets[0].Path } else { $null }
        IsZip = if ($targets.Count -gt 0) { ([System.IO.Path]::GetExtension($targets[0].Path).ToLowerInvariant() -eq '.zip') } else { $false }
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

    $worker = New-Object System.ComponentModel.BackgroundWorker
    $worker.WorkerReportsProgress = $true
    $worker.WorkerSupportsCancellation = $true

    $worker.Add_DoWork({
        param($sender, $e)
        $jobArg = $e.Argument
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
        }
        try {
            foreach ($target in $jobArg.Targets) {
                $result.ErrorUrl = $target.Url
                $result.ErrorPath = $target.Path
                if ($sender.CancellationPending) {
                    $result.Cancelled = $true
                    $e.Cancel = $true
                    $e.Result = $result
                    return
                }

                $tmpPath = $target.Path + '.tmp'
                if (Test-Path -LiteralPath $tmpPath) { Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue }
                $sender.ReportProgress(0, [pscustomobject]@{
                    Job = $jobArg
                    Target = $target
                    HasPercent = $false
                    Percent = 0
                    Bytes = 0L
                    Message = ('[{0}/{1}] Connecting' -f $target.Index, $target.Total)
                })

                $request = [System.Net.HttpWebRequest]::Create($target.Url)
                $request.AllowAutoRedirect = $true
                $request.UserAgent = 'Tesla SS Tools/1.0'
                $request.Timeout = 45000
                $request.ReadWriteTimeout = 45000
                $response = $request.GetResponse()
                try {
                    $total = [Int64]$response.ContentLength
                    $inputStream = $response.GetResponseStream()
                    $outputStream = [System.IO.File]::Open($tmpPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                    try {
                        $buffer = New-Object byte[] 65536
                        $downloaded = [Int64]0
                        while ($true) {
                            if ($sender.CancellationPending) {
                                $result.Cancelled = $true
                                $e.Cancel = $true
                                break
                            }
                            $read = $inputStream.Read($buffer, 0, $buffer.Length)
                            if ($read -le 0) { break }
                            $outputStream.Write($buffer, 0, $read)
                            $downloaded += $read
                            $hasPercent = ($total -gt 0)
                            $percent = if ($hasPercent) { [int](($downloaded / $total) * 100) } else { 0 }
                            $sender.ReportProgress($percent, [pscustomobject]@{
                                Job = $jobArg
                                Target = $target
                                HasPercent = $hasPercent
                                Percent = $percent
                                Bytes = $downloaded
                                Message = if ($hasPercent) { ('[{0}/{1}] {2}%' -f $target.Index, $target.Total, $percent) } else { ('[{0}/{1}] Downloaded bytes' -f $target.Index, $target.Total) }
                            })
                        }
                    }
                    finally {
                        if ($outputStream) { $outputStream.Close() }
                        if ($inputStream) { $inputStream.Close() }
                    }
                }
                finally {
                    if ($response) { $response.Close() }
                }

                if ($result.Cancelled) {
                    if (Test-Path -LiteralPath $tmpPath) { Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue }
                    $e.Cancel = $true
                    $e.Result = $result
                    return
                }

                if (Test-Path -LiteralPath $target.Path) { Remove-Item -LiteralPath $target.Path -Force -ErrorAction SilentlyContinue }
                Move-Item -LiteralPath $tmpPath -Destination $target.Path -Force
            }
            $result.Success = $true
            $e.Result = $result
        }
        catch {
            $result.Error = $_.Exception.Message
            if ($_.Exception) { $result.ErrorType = $_.Exception.GetType().FullName }
            $e.Result = $result
        }
    })

    $worker.Add_ProgressChanged({
        param($sender, $e)
        $state = $e.UserState
        if (-not $state) { return }
        $jobState = $state.Job
        if ($state.HasPercent) {
            $MainProgressBar.IsIndeterminate = $false
            Set-ProgressAnimated -Value $state.Percent
            $ProgressLabel.Text = ('{0}%' -f [int]$state.Percent)
            Set-CardProgress -Job $jobState -Percent $state.Percent -HasPercent $true
        }
        else {
            $MainProgressBar.IsIndeterminate = $true
            $ProgressLabel.Text = '...'
            Set-CardProgress -Job $jobState -Percent 0 -HasPercent $false
        }
        $StepText.Text = $state.Message
        $FooterText.Text = $state.Message
        if ($state.Bytes -gt 0) {
            $SubStatusText.Text = "Downloading $($jobState.Name): $(Format-Bytes $state.Bytes)"
            if ($InlineStatusText) { $InlineStatusText.Text = $SubStatusText.Text }
        }
        else {
            if ($InlineStatusText) { $InlineStatusText.Text = "Downloading $($jobState.Name): $($state.Message)" }
        }
        Refresh-Ui
    })

    $worker.Add_RunWorkerCompleted({
        param($sender, $e)
        if ($e.Cancelled) {
            $result = [pscustomobject]@{ Job = $script:ActiveDownloadJob; Success = $false; Cancelled = $true; Error = $null; PrimaryPath = $null; IsZip = $false }
        }
        else {
            $result = $e.Result
            if (-not $result) {
                $result = [pscustomobject]@{ Job = $script:ActiveDownloadJob; Success = $false; Cancelled = $false; Error = 'Unknown download result.'; PrimaryPath = $null; IsZip = $false }
            }
        }
        $jobDone = $result.Job
        if (-not $jobDone) {
            $script:CurrentWorker = $null
            $script:ActiveDownloadJob = $null
            $CancelDownloadButton.IsEnabled = $false
            Set-UiState -Title 'Download stopped' -SubTitle 'The download ended without a job result.' -Chip 'Error' -Step 'Stopped' -Progress 0
            Write-Activity '[INFO] Download ended without a job result.'
            Show-ErrorDetails -Title 'Tesla SS Tools - Download Error' -Action 'Download' -ToolName '' -Message 'The download ended without a job result.' -Url '' -Path '' -Extra 'No job object was returned by the background worker.'
            Start-NextDownload
            return
        }
        $script:CurrentWorker = $null
        $script:ActiveDownloadJob = $null
        $MainProgressBar.IsIndeterminate = $false
        $CancelDownloadButton.IsEnabled = $false

        if ($e.Cancelled -or $result.Cancelled) {
            Set-CardComplete -Job $jobDone -Success $false
            Set-UiState -Title 'Download cancelled' -SubTitle "$($jobDone.Name) was cancelled." -Chip 'Cancelled' -Step 'Cancelled' -Progress 0
            Write-Activity "[INFO] Download cancelled: $($jobDone.Name)"
        }
        elseif ($result.Success) {
            Set-CardComplete -Job $jobDone -Success $true
            Set-UiState -Title 'Download complete' -SubTitle "$($jobDone.Name) saved successfully." -Chip 'Ready' -Step 'Completed' -Progress 100
            Write-Activity "[OK] Saved: $($result.PrimaryPath)"
            if (-not $jobDone.Batch -and -not $result.IsZip -and $result.PrimaryPath) {
                Start-DownloadedTool -Path $result.PrimaryPath -Name $jobDone.Name
            }
            elseif ($result.IsZip) {
                Write-Activity "[INFO] $($jobDone.Name) is a ZIP download. It was saved and not auto-launched, matching the original workflow."
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

    $script:CurrentWorker = $worker
    $worker.RunWorkerAsync($job)
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
    param([string]$Path, [string]$Name)
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            throw "File not found: $Path"
        }
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Path
        $psi.WorkingDirectory = Split-Path -Parent $Path
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
        $psi.Verb = 'runas'
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
    Queue-Download -Tool $Item -Batch:$false
}

function Download-AllCurrentCategory {
    if ($script:CurrentCategory -eq 'scripts' -or $script:CurrentCategory -eq 'credits') { return }
    $items = @(Get-SelectedItems)
    if ($items.Count -eq 0) { return }
    Write-Activity "[INFO] Batch download queued for $($SelectedCategoryText.Text): $($items.Count) item(s)"
    foreach ($item in $items) {
        Queue-Download -Tool $item -Batch:$true
    }
}

function Cancel-CurrentDownload {
    if ($script:CurrentWorker -ne $null) {
        $script:CurrentWorker.CancelAsync()
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
        @{ Text = 'Building tool layout...'; Progress = 55 },
        @{ Text = 'Applying performance mode...'; Progress = 78 },
        @{ Text = 'Ready to launch.'; Progress = 100 }
    )) {
        Update-Splash -Text $step.Text -Progress $step.Progress
        Start-Sleep -Milliseconds 180
    }
    $SplashWindow.Close()
}

$window.ShowDialog() | Out-Null
