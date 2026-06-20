<# =====================================================================
   TeslaProTools.ps1
   One-file PowerShell 5.1 / WPF launcher and command reference
   Version: 1.0.0
   ===================================================================== #>

#region Metadata and requirements
[CmdletBinding()]
param(
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
    throw "TeslaPro Tools requires Windows because it uses WPF."
}

if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw "TeslaPro Tools requires Windows PowerShell 5.1 or newer."
}

if ([Threading.Thread]::CurrentThread.ApartmentState -ne [Threading.ApartmentState]::STA) {
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        throw "TeslaPro Tools must run in STA mode. Start PowerShell with -Sta and run this script again."
    }

    $exe = if ($PSVersionTable.PSEdition -eq "Core") { "pwsh.exe" } else { "powershell.exe" }
    $arguments = @("-NoProfile", "-Sta", "-File", "`"$PSCommandPath`"")
    if ($SelfTest) { $arguments += "-SelfTest" }
    Start-Process -FilePath $exe -ArgumentList $arguments | Out-Null
    exit
}
#endregion

#region Assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.ComponentModel;

namespace TeslaProTools {
    public class DownloadItem : INotifyPropertyChanged {
        public event PropertyChangedEventHandler PropertyChanged;

        private void Changed(string name) {
            var handler = PropertyChanged;
            if (handler != null) handler(this, new PropertyChangedEventArgs(name));
        }

        private string _id;
        public string Id { get { return _id; } set { if (_id != value) { _id = value; Changed("Id"); } } }

        private string _toolId;
        public string ToolId { get { return _toolId; } set { if (_toolId != value) { _toolId = value; Changed("ToolId"); } } }

        private string _toolName;
        public string ToolName { get { return _toolName; } set { if (_toolName != value) { _toolName = value; Changed("ToolName"); } } }

        private string _fileName;
        public string FileName { get { return _fileName; } set { if (_fileName != value) { _fileName = value; Changed("FileName"); } } }

        private string _sourceUrl;
        public string SourceUrl { get { return _sourceUrl; } set { if (_sourceUrl != value) { _sourceUrl = value; Changed("SourceUrl"); } } }

        private string _status;
        public string Status { get { return _status; } set { if (_status != value) { _status = value; Changed("Status"); } } }

        private int _progress;
        public int Progress { get { return _progress; } set { if (_progress != value) { _progress = value; Changed("Progress"); } } }

        private string _bytesText;
        public string BytesText { get { return _bytesText; } set { if (_bytesText != value) { _bytesText = value; Changed("BytesText"); } } }

        private string _speedText;
        public string SpeedText { get { return _speedText; } set { if (_speedText != value) { _speedText = value; Changed("SpeedText"); } } }

        private string _errorText;
        public string ErrorText { get { return _errorText; } set { if (_errorText != value) { _errorText = value; Changed("ErrorText"); } } }

        private string _filePath;
        public string FilePath { get { return _filePath; } set { if (_filePath != value) { _filePath = value; Changed("FilePath"); } } }

        private string _hashStatus;
        public string HashStatus { get { return _hashStatus; } set { if (_hashStatus != value) { _hashStatus = value; Changed("HashStatus"); } } }

        private bool _canCancel;
        public bool CanCancel { get { return _canCancel; } set { if (_canCancel != value) { _canCancel = value; Changed("CanCancel"); } } }

        private bool _canRetry;
        public bool CanRetry { get { return _canRetry; } set { if (_canRetry != value) { _canRetry = value; Changed("CanRetry"); } } }

        private bool _canOpen;
        public bool CanOpen { get { return _canOpen; } set { if (_canOpen != value) { _canOpen = value; Changed("CanOpen"); } } }

        private object _tool;
        public object Tool { get { return _tool; } set { if (_tool != value) { _tool = value; Changed("Tool"); } } }
    }
}
'@
#endregion

#region Application configuration
$script:AppName = "TeslaPro Tools"
$script:AppVersion = "1.0.0"
$script:DefaultDownloadRoot = Join-Path $env:LOCALAPPDATA "TeslaProTools\Downloads"
$script:UserAgent = "TeslaProTools/$script:AppVersion (official-source launcher)"

if (-not (Test-Path -LiteralPath $script:DefaultDownloadRoot)) {
    [IO.Directory]::CreateDirectory($script:DefaultDownloadRoot) | Out-Null
}
#endregion

#region Application state
$script:Settings = [PSCustomObject]@{
    AnimationsEnabled      = $true
    ConfirmToolLaunch      = $true
    ConfirmCommandRun      = $true
    SafeMode               = $false
    DownloadNotifications  = $true
    Theme                  = "Dark"
    DownloadRoot           = $script:DefaultDownloadRoot
}

$script:Window = $null
$script:CurrentPage = $null
$script:ToolsCollection = New-Object 'System.Collections.ObjectModel.ObservableCollection[object]'
$script:CommandsCollection = New-Object 'System.Collections.ObjectModel.ObservableCollection[object]'
$script:DownloadsCollection = New-Object 'System.Collections.ObjectModel.ObservableCollection[TeslaProTools.DownloadItem]'
$script:ToolsView = $null
$script:CommandsView = $null
$script:DownloadWorkers = @{}
$script:DownloadContexts = @{}
$script:Timers = @()
#endregion

#region Tool definitions
function New-ToolItem {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Author,
        [Parameter(Mandatory)][string]$Description,
        [string]$Version = "Unknown",
        [string]$Category = "General",
        [string]$OfficialWebsite = "",
        [string]$GitHubRepository = "",
        [string]$GitHubReleasePage = "",
        [ValidateSet("OfficialWebsite","GitHubRepository","GitHubReleasePage","DirectDownload","GitHubReleaseAsset","LaunchDownloadedFile")]
        [string]$ActionType = "OfficialWebsite",
        [string]$DirectDownloadUrl = "",
        [string]$GitHubAssetPattern = "",
        [string]$DownloadFileName = "",
        [string]$LaunchFileName = "",
        [ValidateSet("None","Open","Executable","Installer","Script","Archive")]
        [string]$LaunchType = "None",
        [string]$LaunchArguments = "",
        [bool]$RequiresAdministrator = $false,
        [string[]]$AllowedDomains = @(),
        [string[]]$AllowedExtensions = @(),
        [string]$Sha256 = "",
        [string]$Credits = "All credits belong to the original creator.",
        [string]$Warning = "",
        [string]$Icon = "",
        [string]$Status = "Official source"
    )

    $domainSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($domain in $AllowedDomains) {
        if (-not [string]::IsNullOrWhiteSpace($domain)) { [void]$domainSet.Add($domain.Trim().ToLowerInvariant()) }
    }

    foreach ($url in @($OfficialWebsite, $GitHubRepository, $GitHubReleasePage, $DirectDownloadUrl)) {
        if ([string]::IsNullOrWhiteSpace($url)) { continue }
        try {
            $uri = [Uri]$url
            if (-not [string]::IsNullOrWhiteSpace($uri.Host)) { [void]$domainSet.Add($uri.Host.ToLowerInvariant()) }
        } catch { }
    }

    if (-not [string]::IsNullOrWhiteSpace($GitHubRepository) -or -not [string]::IsNullOrWhiteSpace($GitHubReleasePage)) {
        foreach ($githubDomain in @("github.com","api.github.com","objects.githubusercontent.com","release-assets.githubusercontent.com")) {
            [void]$domainSet.Add($githubDomain)
        }
    }

    [PSCustomObject]@{
        Id                    = $Id
        Name                  = $Name
        Author                = $Author
        Description           = $Description
        Version               = $Version
        Category              = $Category
        OfficialWebsite       = $OfficialWebsite
        GitHubRepository      = $GitHubRepository
        GitHubReleasePage     = $GitHubReleasePage
        ActionType            = $ActionType
        DirectDownloadUrl     = $DirectDownloadUrl
        GitHubAssetPattern    = $GitHubAssetPattern
        DownloadFileName      = $DownloadFileName
        LaunchFileName        = $LaunchFileName
        LaunchType            = $LaunchType
        LaunchArguments       = $LaunchArguments
        RequiresAdministrator = $RequiresAdministrator
        AllowedDomains        = @($domainSet)
        AllowedExtensions     = $AllowedExtensions
        Sha256                = $Sha256
        Credits               = $Credits
        Warning               = $Warning
        Icon                  = $Icon
        Status                = $Status
        FileType              = if ($AllowedExtensions.Count -gt 0) { ($AllowedExtensions -join ", ") } else { "Web" }
        DownloadStatus        = "Not downloaded"
        InstallStatus         = "Not installed"
        HashStatus            = if ([string]::IsNullOrWhiteSpace($Sha256)) { "No SHA-256 configured" } else { "SHA-256 configured" }
        LocalPath             = ""
    }
}

$script:Tools = @(
    New-ToolItem -Id "7zip" -Name "7-Zip" -Author "Igor Pavlov" -Description "File archiver with strong compression and a small footprint." -Version "Official site" -Category "Utilities" -OfficialWebsite "https://www.7-zip.org/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi",".zip") -Credits "7-Zip is created by Igor Pavlov."
    New-ToolItem -Id "powertoys" -Name "Microsoft PowerToys" -Author "Microsoft" -Description "Advanced utilities for Windows power users." -Version "Latest release" -Category "Windows" -OfficialWebsite "https://learn.microsoft.com/windows/powertoys/" -GitHubRepository "https://github.com/microsoft/PowerToys" -GitHubReleasePage "https://github.com/microsoft/PowerToys/releases" -ActionType "GitHubReleaseAsset" -GitHubAssetPattern "^PowerToysSetup-.*-x64\.exe$" -AllowedExtensions @(".exe") -RequiresAdministrator $true -Credits "PowerToys is maintained by Microsoft."
    New-ToolItem -Id "process-explorer" -Name "Process Explorer" -Author "Microsoft Sysinternals" -Description "Advanced process inspection tool from Sysinternals." -Version "Official download" -Category "Sysinternals" -OfficialWebsite "https://learn.microsoft.com/sysinternals/downloads/process-explorer" -DirectDownloadUrl "https://download.sysinternals.com/files/ProcessExplorer.zip" -ActionType "DirectDownload" -DownloadFileName "ProcessExplorer.zip" -LaunchType "Archive" -AllowedDomains @("learn.microsoft.com","download.sysinternals.com") -AllowedExtensions @(".zip") -Credits "Process Explorer is part of Microsoft Sysinternals."
    New-ToolItem -Id "autoruns" -Name "Autoruns" -Author "Microsoft Sysinternals" -Description "Shows auto-starting locations and configured startup entries." -Version "Official download" -Category "Sysinternals" -OfficialWebsite "https://learn.microsoft.com/sysinternals/downloads/autoruns" -DirectDownloadUrl "https://download.sysinternals.com/files/Autoruns.zip" -ActionType "DirectDownload" -DownloadFileName "Autoruns.zip" -LaunchType "Archive" -AllowedDomains @("learn.microsoft.com","download.sysinternals.com") -AllowedExtensions @(".zip") -Credits "Autoruns is part of Microsoft Sysinternals."
    New-ToolItem -Id "winscp" -Name "WinSCP" -Author "WinSCP Team" -Description "SFTP, FTP, WebDAV and SCP client for Windows." -Version "Official site" -Category "Network" -OfficialWebsite "https://winscp.net/eng/index.php" -GitHubRepository "https://github.com/winscp/winscp" -GitHubReleasePage "https://github.com/winscp/winscp/releases" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi") -Credits "WinSCP is maintained by the WinSCP project."
    New-ToolItem -Id "putty" -Name "PuTTY" -Author "Simon Tatham" -Description "SSH and Telnet client for Windows." -Version "Official site" -Category "Network" -OfficialWebsite "https://www.chiark.greenend.org.uk/~sgtatham/putty/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi") -Credits "PuTTY is created by Simon Tatham and contributors."
    New-ToolItem -Id "vscode" -Name "Visual Studio Code" -Author "Microsoft" -Description "Code editor with extensions, terminal and debugging." -Version "Official site" -Category "Development" -OfficialWebsite "https://code.visualstudio.com/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".zip") -Credits "Visual Studio Code is maintained by Microsoft."
    New-ToolItem -Id "git" -Name "Git for Windows" -Author "Git for Windows Project" -Description "Git command line tools and Bash environment for Windows." -Version "Official site" -Category "Development" -OfficialWebsite "https://gitforwindows.org/" -GitHubRepository "https://github.com/git-for-windows/git" -GitHubReleasePage "https://github.com/git-for-windows/git/releases" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe") -Credits "Git for Windows is maintained by the Git for Windows project."
    New-ToolItem -Id "github-desktop" -Name "GitHub Desktop" -Author "GitHub" -Description "Desktop Git client for GitHub repositories." -Version "Official site" -Category "Development" -OfficialWebsite "https://desktop.github.com/" -GitHubRepository "https://github.com/desktop/desktop" -GitHubReleasePage "https://github.com/desktop/desktop/releases" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe") -Credits "GitHub Desktop is maintained by GitHub."
    New-ToolItem -Id "nodejs" -Name "Node.js" -Author "OpenJS Foundation" -Description "JavaScript runtime for servers, tools and scripts." -Version "Official site" -Category "Development" -OfficialWebsite "https://nodejs.org/" -ActionType "OfficialWebsite" -AllowedExtensions @(".msi",".zip") -Credits "Node.js is maintained by the OpenJS Foundation and contributors."
    New-ToolItem -Id "python" -Name "Python" -Author "Python Software Foundation" -Description "General purpose programming language and runtime." -Version "Official site" -Category "Development" -OfficialWebsite "https://www.python.org/downloads/windows/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi",".zip") -Credits "Python is maintained by the Python Software Foundation."
    New-ToolItem -Id "temurin" -Name "Eclipse Temurin JDK" -Author "Eclipse Adoptium" -Description "OpenJDK builds for Java development and servers." -Version "Official site" -Category "Java" -OfficialWebsite "https://adoptium.net/temurin/releases/" -ActionType "OfficialWebsite" -AllowedExtensions @(".msi",".zip") -Credits "Temurin is maintained by Eclipse Adoptium."
    New-ToolItem -Id "dotnet-sdk" -Name ".NET SDK" -Author "Microsoft" -Description "SDK for building .NET applications." -Version "Official site" -Category "Development" -OfficialWebsite "https://dotnet.microsoft.com/download" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".zip") -Credits ".NET is maintained by Microsoft and the .NET Foundation."
    New-ToolItem -Id "wireshark" -Name "Wireshark" -Author "Wireshark Foundation" -Description "Network protocol analyzer." -Version "Official site" -Category "Network" -OfficialWebsite "https://www.wireshark.org/download.html" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe") -Credits "Wireshark is maintained by the Wireshark Foundation."
    New-ToolItem -Id "nmap" -Name "Nmap" -Author "Nmap Project" -Description "Network discovery and security auditing utility." -Version "Official site" -Category "Network" -OfficialWebsite "https://nmap.org/download.html" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".zip") -Credits "Nmap is maintained by the Nmap project."
    New-ToolItem -Id "notepad-plus-plus" -Name "Notepad++" -Author "Notepad++ Team" -Description "Lightweight source code and text editor." -Version "Latest release" -Category "Utilities" -OfficialWebsite "https://notepad-plus-plus.org/" -GitHubRepository "https://github.com/notepad-plus-plus/notepad-plus-plus" -GitHubReleasePage "https://github.com/notepad-plus-plus/notepad-plus-plus/releases" -ActionType "GitHubReleasePage" -AllowedExtensions @(".exe",".zip") -Credits "Notepad++ is maintained by the Notepad++ project."
    New-ToolItem -Id "everything" -Name "Everything" -Author "voidtools" -Description "Fast filename search for Windows." -Version "Official site" -Category "Utilities" -OfficialWebsite "https://www.voidtools.com/downloads/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi",".zip") -Credits "Everything is created by voidtools."
    New-ToolItem -Id "crystaldiskinfo" -Name "CrystalDiskInfo" -Author "Crystal Dew World" -Description "Disk health and SMART monitoring utility." -Version "Official site" -Category "Diagnostics" -OfficialWebsite "https://crystalmark.info/en/software/crystaldiskinfo/" -GitHubRepository "https://github.com/hiyohiyo/CrystalDiskInfo" -GitHubReleasePage "https://github.com/hiyohiyo/CrystalDiskInfo/releases" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".zip") -Credits "CrystalDiskInfo is maintained by Crystal Dew World."
    New-ToolItem -Id "hwinfo" -Name "HWiNFO" -Author "REALiX" -Description "Hardware information and sensor monitoring." -Version "Official site" -Category "Diagnostics" -OfficialWebsite "https://www.hwinfo.com/download/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".zip") -Credits "HWiNFO is maintained by REALiX."
    New-ToolItem -Id "rufus" -Name "Rufus" -Author "Pete Batard" -Description "Create bootable USB drives." -Version "Latest release" -Category "Utilities" -OfficialWebsite "https://rufus.ie/" -GitHubRepository "https://github.com/pbatard/rufus" -GitHubReleasePage "https://github.com/pbatard/rufus/releases" -ActionType "GitHubReleaseAsset" -GitHubAssetPattern "^rufus-[0-9].*\.exe$" -LaunchType "Executable" -AllowedExtensions @(".exe") -Credits "Rufus is created by Pete Batard." -Warning "Boot media tools can write to removable drives. Review the official documentation before use."
    New-ToolItem -Id "obs-studio" -Name "OBS Studio" -Author "OBS Project" -Description "Recording and live streaming software." -Version "Latest release" -Category "Media" -OfficialWebsite "https://obsproject.com/" -GitHubRepository "https://github.com/obsproject/obs-studio" -GitHubReleasePage "https://github.com/obsproject/obs-studio/releases" -ActionType "GitHubReleasePage" -AllowedExtensions @(".exe",".zip") -Credits "OBS Studio is maintained by the OBS Project."
    New-ToolItem -Id "vlc" -Name "VLC Media Player" -Author "VideoLAN" -Description "Media player supporting many formats." -Version "Official site" -Category "Media" -OfficialWebsite "https://www.videolan.org/vlc/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi",".zip") -Credits "VLC is maintained by VideoLAN."
    New-ToolItem -Id "prism-launcher" -Name "Prism Launcher" -Author "Prism Launcher Team" -Description "Open source Minecraft launcher with instance management." -Version "Latest release" -Category "Minecraft" -OfficialWebsite "https://prismlauncher.org/" -GitHubRepository "https://github.com/PrismLauncher/PrismLauncher" -GitHubReleasePage "https://github.com/PrismLauncher/PrismLauncher/releases" -ActionType "GitHubReleasePage" -AllowedExtensions @(".exe",".zip") -Credits "Prism Launcher is maintained by the Prism Launcher project."
    New-ToolItem -Id "papermc" -Name "PaperMC" -Author "PaperMC Team" -Description "High performance Minecraft server software." -Version "Official site" -Category "Minecraft" -OfficialWebsite "https://papermc.io/downloads" -ActionType "OfficialWebsite" -AllowedExtensions @(".jar") -Credits "PaperMC is maintained by the PaperMC project."
    New-ToolItem -Id "geysermc" -Name "GeyserMC" -Author "GeyserMC Team" -Description "Proxy that allows Bedrock clients to join Java Minecraft servers." -Version "Latest release" -Category "Minecraft" -OfficialWebsite "https://geysermc.org/" -GitHubRepository "https://github.com/GeyserMC/Geyser" -GitHubReleasePage "https://github.com/GeyserMC/Geyser/releases" -ActionType "GitHubReleasePage" -AllowedExtensions @(".jar") -Credits "Geyser is maintained by the GeyserMC project."
    New-ToolItem -Id "ffmpeg" -Name "FFmpeg" -Author "FFmpeg Project" -Description "Audio/video conversion and processing toolkit." -Version "Official site" -Category "Media" -OfficialWebsite "https://ffmpeg.org/download.html" -ActionType "OfficialWebsite" -AllowedExtensions @(".zip",".7z",".exe") -Credits "FFmpeg is maintained by the FFmpeg project."
    New-ToolItem -Id "yt-dlp" -Name "yt-dlp" -Author "yt-dlp Project" -Description "Command line media downloader." -Version "Latest release" -Category "Media" -OfficialWebsite "https://github.com/yt-dlp/yt-dlp" -GitHubRepository "https://github.com/yt-dlp/yt-dlp" -GitHubReleasePage "https://github.com/yt-dlp/yt-dlp/releases" -ActionType "GitHubReleasePage" -AllowedExtensions @(".exe",".zip") -Credits "yt-dlp is maintained by the yt-dlp project."
    New-ToolItem -Id "windirstat" -Name "WinDirStat" -Author "WinDirStat Team" -Description "Disk usage visualizer and cleanup helper." -Version "Official site" -Category "Utilities" -OfficialWebsite "https://windirstat.net/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi") -Credits "WinDirStat is maintained by the WinDirStat project."
    New-ToolItem -Id "docker-desktop" -Name "Docker Desktop" -Author "Docker" -Description "Container development environment for Windows." -Version "Official site" -Category "Development" -OfficialWebsite "https://www.docker.com/products/docker-desktop/" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe") -RequiresAdministrator $true -Credits "Docker Desktop is maintained by Docker."
    New-ToolItem -Id "virtualbox" -Name "VirtualBox" -Author "Oracle" -Description "Desktop virtualization platform." -Version "Official site" -Category "Virtualization" -OfficialWebsite "https://www.virtualbox.org/wiki/Downloads" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe") -RequiresAdministrator $true -Credits "VirtualBox is maintained by Oracle."
    New-ToolItem -Id "tailscale" -Name "Tailscale" -Author "Tailscale" -Description "WireGuard-based private mesh networking client." -Version "Official site" -Category "Network" -OfficialWebsite "https://tailscale.com/download/windows" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".msi") -Credits "Tailscale is maintained by Tailscale Inc."
    New-ToolItem -Id "filezilla" -Name "FileZilla Client" -Author "FileZilla Project" -Description "FTP, FTPS and SFTP client." -Version "Official site" -Category "Network" -OfficialWebsite "https://filezilla-project.org/download.php?type=client" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe") -Credits "FileZilla is maintained by the FileZilla project."
    New-ToolItem -Id "keepass" -Name "KeePass" -Author "Dominik Reichl" -Description "Local password manager." -Version "Official site" -Category "Security" -OfficialWebsite "https://keepass.info/download.html" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe",".zip") -Credits "KeePass is maintained by Dominik Reichl and contributors."
    New-ToolItem -Id "bitwarden-desktop" -Name "Bitwarden Desktop" -Author "Bitwarden" -Description "Desktop password manager client." -Version "Latest release" -Category "Security" -OfficialWebsite "https://bitwarden.com/download/" -GitHubRepository "https://github.com/bitwarden/clients" -GitHubReleasePage "https://github.com/bitwarden/clients/releases" -ActionType "OfficialWebsite" -AllowedExtensions @(".exe") -Credits "Bitwarden Desktop is maintained by Bitwarden."
)
#endregion

#region Command definitions
function New-CommandItem {
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Category,
        [ValidateSet("CMD","PowerShell")][string]$Shell = "CMD",
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Description,
        [string]$Explanation = "",
        [string]$Example = "",
        [string]$Warning = "",
        [bool]$RequiresAdministrator = $false,
        [bool]$AllowExecution = $false
    )

    [PSCustomObject]@{
        Id                    = $Id
        Name                  = $Name
        Category              = $Category
        Shell                 = $Shell
        Command               = $Command
        Description           = $Description
        Explanation           = if ([string]::IsNullOrWhiteSpace($Explanation)) { $Description } else { $Explanation }
        Example               = if ([string]::IsNullOrWhiteSpace($Example)) { $Command } else { $Example }
        Warning               = $Warning
        RequiresAdministrator = $RequiresAdministrator
        AllowExecution        = $AllowExecution
    }
}

$script:Commands = @(
    New-CommandItem -Id "ipconfig-all" -Name "Full network configuration" -Category "Network" -Shell "CMD" -Command "ipconfig /all" -Description "Shows detailed network adapter configuration." -Explanation "Useful for checking IP addresses, DNS servers, DHCP status and adapter names." -AllowExecution $true
    New-CommandItem -Id "flush-dns" -Name "Flush DNS cache" -Category "Network" -Shell "CMD" -Command "ipconfig /flushdns" -Description "Clears the Windows DNS resolver cache." -Explanation "Use this after DNS changes or when cached DNS entries appear stale." -RequiresAdministrator $false -AllowExecution $true
    New-CommandItem -Id "show-listening-ports" -Name "Show listening ports" -Category "Ports" -Shell "CMD" -Command 'netstat -ano | findstr LISTENING' -Description "Lists local listening TCP ports with process IDs." -Explanation "Combine the PID with Task Manager or tasklist to identify the owning process." -AllowExecution $true
    New-CommandItem -Id "tasklist-pid" -Name "Find process by PID" -Category "Processes" -Shell "CMD" -Command "tasklist /fi `"PID eq 1234`"" -Description "Shows the process matching a specific PID." -Explanation "Replace 1234 with the PID from netstat or Task Manager." -AllowExecution $false
    New-CommandItem -Id "java-version" -Name "Check Java version" -Category "Java" -Shell "CMD" -Command "java -version" -Description "Prints the installed Java runtime version." -Explanation "Useful before starting Minecraft servers or Java tooling." -AllowExecution $true
    New-CommandItem -Id "where-java" -Name "Locate Java executable" -Category "Java" -Shell "CMD" -Command "where java" -Description "Shows Java executable paths found on PATH." -Explanation "If multiple paths are returned, Windows will normally use the first one." -AllowExecution $true
    New-CommandItem -Id "minecraft-server-start" -Name "Start Minecraft server jar" -Category "Minecraft Server" -Shell "CMD" -Command "java -Xms2G -Xmx4G -jar server.jar nogui" -Description "Starts a Minecraft Java server jar without the GUI." -Explanation "Run this inside the folder that contains server.jar. Adjust memory values to match the machine." -Warning "Make sure you accept the Minecraft EULA and understand the memory values before running." -AllowExecution $false
    New-CommandItem -Id "minecraft-eula" -Name "Show Minecraft EULA file" -Category "Minecraft Server" -Shell "CMD" -Command "type eula.txt" -Description "Displays the local eula.txt file in a server folder." -Explanation "This only reads the file. It does not accept the EULA automatically." -AllowExecution $true
    New-CommandItem -Id "systeminfo" -Name "System information" -Category "System information" -Shell "CMD" -Command "systeminfo" -Description "Shows OS, hardware and hotfix information." -Explanation "Useful for support cases and compatibility checks." -AllowExecution $true
    New-CommandItem -Id "whoami-groups" -Name "Current user groups" -Category "General" -Shell "CMD" -Command "whoami /groups" -Description "Lists security groups for the current user." -Explanation "Useful for checking administrator group membership and effective tokens." -AllowExecution $true
    New-CommandItem -Id "powershell-version" -Name "PowerShell version table" -Category "PowerShell" -Shell "PowerShell" -Command '$PSVersionTable' -Description "Displays the current PowerShell engine version." -Explanation "Useful when a script requires Windows PowerShell 5.1 or PowerShell 7." -AllowExecution $true
    New-CommandItem -Id "get-process-cpu" -Name "Top processes by CPU" -Category "Processes" -Shell "PowerShell" -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name,Id,CPU" -Description "Shows the processes with the highest accumulated CPU time." -Explanation "This is a read-only diagnostic command." -AllowExecution $true
    New-CommandItem -Id "test-connection" -Name "Ping with PowerShell" -Category "Network" -Shell "PowerShell" -Command "Test-Connection 1.1.1.1 -Count 4" -Description "Sends ICMP echo requests with PowerShell." -Explanation "Replace 1.1.1.1 with a hostname or IP address." -AllowExecution $true
    New-CommandItem -Id "dns-lookup" -Name "Resolve DNS name" -Category "Network" -Shell "PowerShell" -Command "Resolve-DnsName cloudflare.com" -Description "Performs a DNS lookup." -Explanation "Replace cloudflare.com with the target domain you want to inspect." -AllowExecution $true
    New-CommandItem -Id "current-directory" -Name "Show current directory" -Category "Files" -Shell "CMD" -Command "cd" -Description "Prints the current working directory." -Explanation "Useful before running file commands." -AllowExecution $true
    New-CommandItem -Id "list-files" -Name "List files" -Category "Files" -Shell "CMD" -Command "dir" -Description "Lists files and folders in the current directory." -Explanation "Read-only directory listing." -AllowExecution $true
    New-CommandItem -Id "disk-free" -Name "Disk free space" -Category "System information" -Shell "PowerShell" -Command "Get-PSDrive -PSProvider FileSystem | Select-Object Name,Used,Free" -Description "Shows free and used space for filesystem drives." -Explanation "Read-only disk space overview." -AllowExecution $true
    New-CommandItem -Id "route-print" -Name "Routing table" -Category "Network" -Shell "CMD" -Command "route print" -Description "Prints the local routing table." -Explanation "Useful for VPN and gateway troubleshooting." -AllowExecution $true
    New-CommandItem -Id "arp-cache" -Name "ARP cache" -Category "Network" -Shell "CMD" -Command "arp -a" -Description "Shows cached IP-to-MAC mappings." -Explanation "Useful on local networks when investigating device reachability." -AllowExecution $true
    New-CommandItem -Id "netsh-wlan" -Name "Wi-Fi profiles" -Category "Network" -Shell "CMD" -Command "netsh wlan show profiles" -Description "Lists saved Wi-Fi profiles." -Explanation "This command lists profile names only. It does not reveal keys." -AllowExecution $true
    New-CommandItem -Id "sfc-scan" -Name "System file checker" -Category "Troubleshooting" -Shell "CMD" -Command "sfc /scannow" -Description "Scans and repairs protected Windows system files." -Explanation "This can take a while and should be run from an elevated terminal." -RequiresAdministrator $true -AllowExecution $false
    New-CommandItem -Id "dism-restorehealth" -Name "DISM restore health" -Category "Troubleshooting" -Shell "CMD" -Command "DISM /Online /Cleanup-Image /RestoreHealth" -Description "Repairs the Windows component store." -Explanation "Use when system image corruption is suspected." -RequiresAdministrator $true -AllowExecution $false
)
#endregion

#region Embedded XAML
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TeslaPro Tools"
        Width="1180"
        Height="760"
        MinWidth="980"
        MinHeight="640"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        ResizeMode="CanResize"
        Background="#101116"
        FontFamily="Segoe UI"
        Foreground="#F6F7FB">
    <Window.Resources>
        <SolidColorBrush x:Key="WindowBackgroundBrush" Color="#101116"/>
        <SolidColorBrush x:Key="SidebarBrush" Color="#171922"/>
        <SolidColorBrush x:Key="PanelBrush" Color="#1D202B"/>
        <SolidColorBrush x:Key="CardBrush" Color="#252936"/>
        <SolidColorBrush x:Key="CardHoverBrush" Color="#2C3344"/>
        <SolidColorBrush x:Key="SelectedBrush" Color="#173A55"/>
        <SolidColorBrush x:Key="AccentBrush" Color="#30A4FF"/>
        <SolidColorBrush x:Key="AccentHoverBrush" Color="#55B6FF"/>
        <SolidColorBrush x:Key="MutedBrush" Color="#AEB6C8"/>
        <SolidColorBrush x:Key="TextBrush" Color="#F6F7FB"/>
        <SolidColorBrush x:Key="LineBrush" Color="#333A4D"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#D84F5B"/>
        <SolidColorBrush x:Key="SuccessBrush" Color="#62C370"/>

        <Style x:Key="BaseButtonStyle" TargetType="{x:Type Button}">
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}"/>
            <Setter Property="Background" Value="{DynamicResource CardBrush}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource LineBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="MinHeight" Value="34"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Center"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border x:Name="Chrome"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                              VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource CardHoverBrush}"/>
                                <Setter TargetName="Chrome" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Chrome" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Chrome" Property="Opacity" Value="0.45"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PrimaryButtonStyle" TargetType="{x:Type Button}" BasedOn="{StaticResource BaseButtonStyle}">
            <Setter Property="Background" Value="{DynamicResource AccentBrush}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
            <Setter Property="Foreground" Value="#07111C"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>

        <Style x:Key="DangerButtonStyle" TargetType="{x:Type Button}" BasedOn="{StaticResource BaseButtonStyle}">
            <Setter Property="Background" Value="{DynamicResource DangerBrush}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource DangerBrush}"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
        </Style>

        <Style x:Key="NavButtonStyle" TargetType="{x:Type Button}" BasedOn="{StaticResource BaseButtonStyle}">
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Margin" Value="12,4"/>
            <Setter Property="Padding" Value="14,10"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="14"/>
        </Style>

        <Style x:Key="WindowButtonStyle" TargetType="{x:Type Button}" BasedOn="{StaticResource BaseButtonStyle}">
            <Setter Property="Width" Value="38"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="Padding" Value="0"/>
            <Setter Property="Margin" Value="4,0"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <Style x:Key="InputStyle" TargetType="{x:Type TextBox}">
            <Setter Property="Background" Value="{DynamicResource CardBrush}"/>
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource LineBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="CaretBrush" Value="{DynamicResource AccentBrush}"/>
            <Setter Property="MinHeight" Value="36"/>
        </Style>

        <Style x:Key="ComboStyle" TargetType="{x:Type ComboBox}">
            <Setter Property="Background" Value="{DynamicResource CardBrush}"/>
            <Setter Property="Foreground" Value="{DynamicResource TextBrush}"/>
            <Setter Property="BorderBrush" Value="{DynamicResource LineBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="7,6"/>
            <Setter Property="MinHeight" Value="36"/>
        </Style>

        <Style x:Key="SelectableListItemStyle" TargetType="{x:Type ListBoxItem}">
            <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
            <Setter Property="Margin" Value="0,0,0,7"/>
            <Setter Property="Padding" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ListBoxItem}">
                        <Border x:Name="ItemBorder"
                                Background="{DynamicResource CardBrush}"
                                BorderBrush="{DynamicResource LineBrush}"
                                BorderThickness="1"
                                CornerRadius="8"
                                Padding="12">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="{DynamicResource CardHoverBrush}"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="{DynamicResource SelectedBrush}"/>
                                <Setter TargetName="ItemBorder" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/>
                                <Setter TargetName="ItemBorder" Property="BorderThickness" Value="2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <DataTemplate x:Key="ToolRowTemplate">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel>
                    <TextBlock Text="{Binding Name}" FontWeight="SemiBold" FontSize="15" Foreground="{DynamicResource TextBrush}"/>
                    <TextBlock Text="{Binding Author}" FontSize="12" Foreground="{DynamicResource MutedBrush}" Margin="0,3,0,0"/>
                    <TextBlock Text="{Binding Description}" FontSize="12" Foreground="{DynamicResource MutedBrush}" TextWrapping="Wrap" Margin="0,4,0,0" MaxHeight="36"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="12,0,0,0" HorizontalAlignment="Right">
                    <Border Background="#203448" CornerRadius="6" Padding="8,3">
                        <TextBlock Text="{Binding Category}" FontSize="11" Foreground="{DynamicResource AccentBrush}"/>
                    </Border>
                    <TextBlock Text="{Binding Status}" FontSize="11" Foreground="{DynamicResource MutedBrush}" Margin="0,7,0,0" HorizontalAlignment="Right"/>
                </StackPanel>
            </Grid>
        </DataTemplate>

        <DataTemplate x:Key="CommandRowTemplate">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel>
                    <TextBlock Text="{Binding Name}" FontWeight="SemiBold" FontSize="15" Foreground="{DynamicResource TextBrush}"/>
                    <TextBlock Text="{Binding Command}" FontFamily="Consolas" FontSize="12" Foreground="{DynamicResource MutedBrush}" TextWrapping="Wrap" Margin="0,5,0,0"/>
                    <TextBlock Text="{Binding Description}" FontSize="12" Foreground="{DynamicResource MutedBrush}" TextWrapping="Wrap" Margin="0,5,0,0" MaxHeight="34"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Margin="12,0,0,0">
                    <Border Background="#203448" CornerRadius="6" Padding="8,3">
                        <TextBlock Text="{Binding Category}" FontSize="11" Foreground="{DynamicResource AccentBrush}"/>
                    </Border>
                    <TextBlock Text="{Binding Shell}" FontSize="11" Foreground="{DynamicResource MutedBrush}" Margin="0,7,0,0" HorizontalAlignment="Right"/>
                </StackPanel>
            </Grid>
        </DataTemplate>

        <DataTemplate x:Key="DownloadRowTemplate">
            <Border Background="{DynamicResource CardBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,0,8">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel>
                        <TextBlock Text="{Binding ToolName}" FontWeight="SemiBold" FontSize="15"/>
                        <TextBlock Text="{Binding FileName}" Foreground="{DynamicResource MutedBrush}" FontSize="12" Margin="0,3,0,0"/>
                        <TextBlock Text="{Binding SourceUrl}" Foreground="{DynamicResource MutedBrush}" FontSize="11" TextWrapping="Wrap" Margin="0,3,0,0"/>
                    </StackPanel>
                    <TextBlock Grid.Column="1" Text="{Binding Status}" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold" Margin="14,0,0,0"/>
                    <ProgressBar Grid.Row="1" Grid.ColumnSpan="2" Height="10" Minimum="0" Maximum="100" Value="{Binding Progress}" Margin="0,10,0,0"/>
                    <Grid Grid.Row="2" Grid.ColumnSpan="2" Margin="0,9,0,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel>
                            <TextBlock Text="{Binding BytesText}" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                            <TextBlock Text="{Binding SpeedText}" Foreground="{DynamicResource MutedBrush}" FontSize="12" Margin="0,2,0,0"/>
                            <TextBlock Text="{Binding ErrorText}" Foreground="{DynamicResource DangerBrush}" FontSize="12" TextWrapping="Wrap" Margin="0,2,0,0"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right">
                            <Button x:Name="BtnDownloadCancel" Content="Cancel" Style="{StaticResource BaseButtonStyle}" IsEnabled="{Binding CanCancel}" Margin="4,0"/>
                            <Button x:Name="BtnDownloadRetry" Content="Retry" Style="{StaticResource BaseButtonStyle}" IsEnabled="{Binding CanRetry}" Margin="4,0"/>
                            <Button x:Name="BtnDownloadOpen" Content="Open" Style="{StaticResource PrimaryButtonStyle}" IsEnabled="{Binding CanOpen}" Margin="4,0"/>
                        </StackPanel>
                    </Grid>
                </Grid>
            </Border>
        </DataTemplate>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="44"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <Border x:Name="TitleBar" Grid.Row="0" Background="{DynamicResource SidebarBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="0,0,0,1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="16,0,0,0">
                    <TextBlock Text="TeslaPro Tools" FontSize="15" FontWeight="SemiBold"/>
                    <TextBlock x:Name="TxtTitleVersion" Text="v" FontSize="12" Foreground="{DynamicResource MutedBrush}" Margin="8,2,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,8,0">
                    <Button x:Name="BtnWindowMinimize" Content="_" Style="{StaticResource WindowButtonStyle}"/>
                    <Button x:Name="BtnWindowClose" Content="X" Style="{StaticResource WindowButtonStyle}"/>
                </StackPanel>
            </Grid>
        </Border>

        <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="230"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="{DynamicResource SidebarBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="0,0,1,0">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel Margin="0,20,0,0">
                        <TextBlock Text="Launcher" Foreground="{DynamicResource MutedBrush}" FontSize="12" Margin="22,0,0,10"/>
                        <Button x:Name="BtnNavHome" Content="Home" Style="{StaticResource NavButtonStyle}"/>
                        <Button x:Name="BtnNavTools" Content="Tools" Style="{StaticResource NavButtonStyle}"/>
                        <Button x:Name="BtnNavCommands" Content="CMD Commands" Style="{StaticResource NavButtonStyle}"/>
                        <Button x:Name="BtnNavDownloads" Content="Downloads" Style="{StaticResource NavButtonStyle}"/>
                        <Button x:Name="BtnNavInfo" Content="Info" Style="{StaticResource NavButtonStyle}"/>
                        <Button x:Name="BtnNavSettings" Content="Settings" Style="{StaticResource NavButtonStyle}"/>
                    </StackPanel>
                    <StackPanel Grid.Row="2" Margin="12,0,12,16">
                        <Border Background="{DynamicResource PanelBrush}" CornerRadius="8" Padding="12" Margin="0,0,0,10">
                            <StackPanel>
                                <TextBlock Text="Official-source mode" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold" FontSize="12"/>
                                <TextBlock Text="TeslaPro does not host or repackage external tools." Foreground="{DynamicResource MutedBrush}" TextWrapping="Wrap" FontSize="11" Margin="0,5,0,0"/>
                            </StackPanel>
                        </Border>
                        <Button x:Name="BtnNavExit" Content="Exit" Style="{StaticResource DangerButtonStyle}"/>
                    </StackPanel>
                </Grid>
            </Border>

            <Grid x:Name="PageHost" Grid.Column="1" Background="{DynamicResource WindowBackgroundBrush}">
                <Grid x:Name="PageHome" Margin="30">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <StackPanel>
                        <TextBlock Text="Welcome to TeslaPro Tools" FontSize="32" FontWeight="Bold"/>
                        <TextBlock Text="A focused launcher for official tool sources and reusable CMD commands." Foreground="{DynamicResource MutedBrush}" FontSize="15" Margin="0,8,0,0"/>
                    </StackPanel>
                    <Grid Grid.Row="1" VerticalAlignment="Center">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="24"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Button x:Name="BtnHomeTools" Grid.Column="0" Height="150" Style="{StaticResource PrimaryButtonStyle}">
                            <StackPanel>
                                <TextBlock Text="Tools" FontSize="28" FontWeight="Bold" HorizontalAlignment="Center"/>
                                <TextBlock Text="Browse official sources and downloads" FontSize="13" HorizontalAlignment="Center" Margin="0,8,0,0"/>
                            </StackPanel>
                        </Button>
                        <Button x:Name="BtnHomeCommands" Grid.Column="2" Height="150" Style="{StaticResource PrimaryButtonStyle}">
                            <StackPanel>
                                <TextBlock Text="CMD Commands" FontSize="28" FontWeight="Bold" HorizontalAlignment="Center"/>
                                <TextBlock Text="Copy safe, documented commands" FontSize="13" HorizontalAlignment="Center" Margin="0,8,0,0"/>
                            </StackPanel>
                        </Button>
                    </Grid>
                    <Border Grid.Row="2" Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="14">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock x:Name="TxtHomeToolCount" Text="Tools: 0" Foreground="{DynamicResource MutedBrush}"/>
                            <TextBlock x:Name="TxtHomeCommandCount" Grid.Column="1" Text="Commands: 0" Foreground="{DynamicResource MutedBrush}" HorizontalAlignment="Center"/>
                            <TextBlock x:Name="TxtHomeStatus" Grid.Column="2" Text="Ready" Foreground="{DynamicResource SuccessBrush}" HorizontalAlignment="Right"/>
                        </Grid>
                    </Border>
                </Grid>

                <Grid x:Name="PageTools" Visibility="Collapsed" Margin="24">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel>
                            <TextBlock Text="Tools" FontSize="28" FontWeight="Bold"/>
                            <TextBlock Text="Select a tool to view official sources, warnings, credits and actions." Foreground="{DynamicResource MutedBrush}" Margin="0,5,0,0"/>
                        </StackPanel>
                        <Button x:Name="BtnToolsBackHome" Grid.Column="1" Content="Back to Home" Style="{StaticResource BaseButtonStyle}" VerticalAlignment="Center"/>
                    </Grid>
                    <Grid Grid.Row="1" Margin="0,18,0,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="430"/>
                            <ColumnDefinition Width="18"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="12">
                                <StackPanel>
                                    <TextBlock Text="Search" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                    <TextBox x:Name="TxtToolSearch" Style="{StaticResource InputStyle}" Margin="0,5,0,10"/>
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="10"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel>
                                            <TextBlock Text="Category" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                            <ComboBox x:Name="CmbToolCategory" Style="{StaticResource ComboStyle}" Margin="0,5,0,0"/>
                                        </StackPanel>
                                        <StackPanel Grid.Column="2">
                                            <TextBlock Text="Status" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                            <ComboBox x:Name="CmbToolStatus" Style="{StaticResource ComboStyle}" Margin="0,5,0,0"/>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Margin="0,10,0,0">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="10"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <ComboBox x:Name="CmbToolSort" Style="{StaticResource ComboStyle}"/>
                                        <Button x:Name="BtnToolClearFilters" Grid.Column="2" Content="Clear filters" Style="{StaticResource BaseButtonStyle}"/>
                                    </Grid>
                                    <TextBlock x:Name="TxtToolResultCount" Text="0 tools found" Foreground="{DynamicResource MutedBrush}" Margin="0,10,0,0"/>
                                </StackPanel>
                            </Border>
                            <Grid Grid.Row="1" Margin="0,12,0,0">
                                <ListBox x:Name="ListTools"
                                         ItemTemplate="{StaticResource ToolRowTemplate}"
                                         ItemContainerStyle="{StaticResource SelectableListItemStyle}"
                                         Background="Transparent"
                                         BorderThickness="0"
                                         ScrollViewer.CanContentScroll="True"
                                         VirtualizingStackPanel.IsVirtualizing="True"
                                         VirtualizingStackPanel.VirtualizationMode="Recycling"/>
                                <Border x:Name="TxtToolNoResults" Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="18" Visibility="Collapsed" VerticalAlignment="Top">
                                    <TextBlock Text="No tools found" Foreground="{DynamicResource MutedBrush}" HorizontalAlignment="Center"/>
                                </Border>
                            </Grid>
                        </Grid>

                        <Border Grid.Column="2" Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="18">
                            <Grid>
                                <Grid x:Name="ToolDetailEmpty" VerticalAlignment="Center">
                                    <TextBlock Text="No tool selected" Foreground="{DynamicResource MutedBrush}" FontSize="18" HorizontalAlignment="Center"/>
                                </Grid>
                                <ScrollViewer x:Name="ToolDetailContent" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">
                                    <StackPanel>
                                        <TextBlock x:Name="TxtToolName" FontSize="27" FontWeight="Bold" TextWrapping="Wrap"/>
                                        <TextBlock x:Name="TxtToolAuthor" Foreground="{DynamicResource MutedBrush}" FontSize="14" Margin="0,4,0,14"/>
                                        <TextBlock x:Name="TxtToolDescription" TextWrapping="Wrap" FontSize="14" LineHeight="20"/>
                                        <UniformGrid Columns="2" Margin="0,16,0,0">
                                            <StackPanel Margin="0,0,12,10">
                                                <TextBlock Text="Version" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtToolVersion" FontWeight="SemiBold"/>
                                            </StackPanel>
                                            <StackPanel Margin="0,0,0,10">
                                                <TextBlock Text="Category" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtToolCategory" FontWeight="SemiBold"/>
                                            </StackPanel>
                                            <StackPanel Margin="0,0,12,10">
                                                <TextBlock Text="Download status" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtToolDownloadStatus" FontWeight="SemiBold"/>
                                            </StackPanel>
                                            <StackPanel Margin="0,0,0,10">
                                                <TextBlock Text="Hash status" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtToolHashStatus" FontWeight="SemiBold"/>
                                            </StackPanel>
                                        </UniformGrid>
                                        <Border Background="{DynamicResource CardBrush}" CornerRadius="8" Padding="12" Margin="0,10,0,0">
                                            <StackPanel>
                                                <TextBlock Text="Official sources" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold"/>
                                                <TextBlock x:Name="TxtToolWebsite" TextWrapping="Wrap" Foreground="{DynamicResource MutedBrush}" Margin="0,6,0,0"/>
                                                <TextBlock x:Name="TxtToolRepository" TextWrapping="Wrap" Foreground="{DynamicResource MutedBrush}" Margin="0,4,0,0"/>
                                                <TextBlock x:Name="TxtToolReleases" TextWrapping="Wrap" Foreground="{DynamicResource MutedBrush}" Margin="0,4,0,0"/>
                                                <TextBlock x:Name="TxtToolDownloadSource" TextWrapping="Wrap" Foreground="{DynamicResource MutedBrush}" Margin="0,4,0,0"/>
                                            </StackPanel>
                                        </Border>
                                        <Border Background="{DynamicResource CardBrush}" CornerRadius="8" Padding="12" Margin="0,10,0,0">
                                            <StackPanel>
                                                <TextBlock Text="Warnings and credits" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold"/>
                                                <TextBlock x:Name="TxtToolWarning" TextWrapping="Wrap" Foreground="{DynamicResource MutedBrush}" Margin="0,6,0,0"/>
                                                <TextBlock x:Name="TxtToolCredits" TextWrapping="Wrap" Foreground="{DynamicResource MutedBrush}" Margin="0,6,0,0"/>
                                            </StackPanel>
                                        </Border>
                                        <WrapPanel Margin="0,16,0,0">
                                            <Button x:Name="BtnToolPrimaryAction" Content="Open" Style="{StaticResource PrimaryButtonStyle}" MinWidth="160" Margin="0,0,8,8"/>
                                            <Button x:Name="BtnToolOpenWebsite" Content="Website" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                                            <Button x:Name="BtnToolOpenRepo" Content="GitHub" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                                            <Button x:Name="BtnToolOpenReleases" Content="Releases" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                                            <Button x:Name="BtnToolLaunchDownloaded" Content="Start/Open downloaded file" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                                        </WrapPanel>
                                    </StackPanel>
                                </ScrollViewer>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>

                <Grid x:Name="PageCommands" Visibility="Collapsed" Margin="24">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel>
                            <TextBlock Text="CMD Commands" FontSize="28" FontWeight="Bold"/>
                            <TextBlock Text="Select a command, inspect it, then copy it. Commands are not executed automatically." Foreground="{DynamicResource MutedBrush}" Margin="0,5,0,0"/>
                        </StackPanel>
                        <Button x:Name="BtnCommandsBackHome" Grid.Column="1" Content="Back to Home" Style="{StaticResource BaseButtonStyle}" VerticalAlignment="Center"/>
                    </Grid>
                    <Grid Grid.Row="1" Margin="0,18,0,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="430"/>
                            <ColumnDefinition Width="18"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="12">
                                <StackPanel>
                                    <TextBlock Text="Search" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                    <TextBox x:Name="TxtCommandSearch" Style="{StaticResource InputStyle}" Margin="0,5,0,10"/>
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="10"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel>
                                            <TextBlock Text="Category" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                            <ComboBox x:Name="CmbCommandCategory" Style="{StaticResource ComboStyle}" Margin="0,5,0,0"/>
                                        </StackPanel>
                                        <StackPanel Grid.Column="2">
                                            <TextBlock Text="Shell" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                            <ComboBox x:Name="CmbCommandShell" Style="{StaticResource ComboStyle}" Margin="0,5,0,0"/>
                                        </StackPanel>
                                    </Grid>
                                    <Grid Margin="0,10,0,0">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="10"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <ComboBox x:Name="CmbCommandSort" Style="{StaticResource ComboStyle}"/>
                                        <Button x:Name="BtnCommandClearFilters" Grid.Column="2" Content="Clear filters" Style="{StaticResource BaseButtonStyle}"/>
                                    </Grid>
                                    <TextBlock x:Name="TxtCommandResultCount" Text="0 commands found" Foreground="{DynamicResource MutedBrush}" Margin="0,10,0,0"/>
                                </StackPanel>
                            </Border>
                            <Grid Grid.Row="1" Margin="0,12,0,0">
                                <ListBox x:Name="ListCommands"
                                         ItemTemplate="{StaticResource CommandRowTemplate}"
                                         ItemContainerStyle="{StaticResource SelectableListItemStyle}"
                                         Background="Transparent"
                                         BorderThickness="0"
                                         ScrollViewer.CanContentScroll="True"
                                         VirtualizingStackPanel.IsVirtualizing="True"
                                         VirtualizingStackPanel.VirtualizationMode="Recycling"/>
                                <Border x:Name="TxtCommandNoResults" Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="18" Visibility="Collapsed" VerticalAlignment="Top">
                                    <TextBlock Text="No commands found" Foreground="{DynamicResource MutedBrush}" HorizontalAlignment="Center"/>
                                </Border>
                            </Grid>
                        </Grid>

                        <Border Grid.Column="2" Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="18">
                            <Grid>
                                <Grid x:Name="CommandDetailEmpty" VerticalAlignment="Center">
                                    <TextBlock Text="No command selected" Foreground="{DynamicResource MutedBrush}" FontSize="18" HorizontalAlignment="Center"/>
                                </Grid>
                                <ScrollViewer x:Name="CommandDetailContent" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">
                                    <StackPanel>
                                        <TextBlock x:Name="TxtCommandName" FontSize="27" FontWeight="Bold" TextWrapping="Wrap"/>
                                        <TextBlock x:Name="TxtCommandMeta" Foreground="{DynamicResource MutedBrush}" FontSize="14" Margin="0,4,0,14"/>
                                        <Border Background="#101116" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="12">
                                            <TextBox x:Name="TxtCommandFull" IsReadOnly="True" TextWrapping="Wrap" FontFamily="Consolas" FontSize="14" Background="#101116" Foreground="{DynamicResource TextBrush}" BorderThickness="0"/>
                                        </Border>
                                        <TextBlock x:Name="TxtCommandDescription" TextWrapping="Wrap" Margin="0,14,0,0" FontSize="14" LineHeight="20"/>
                                        <TextBlock x:Name="TxtCommandExplanation" TextWrapping="Wrap" Foreground="{DynamicResource MutedBrush}" Margin="0,8,0,0" LineHeight="19"/>
                                        <UniformGrid Columns="2" Margin="0,16,0,0">
                                            <StackPanel Margin="0,0,12,10">
                                                <TextBlock Text="Category" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtCommandCategory" FontWeight="SemiBold"/>
                                            </StackPanel>
                                            <StackPanel Margin="0,0,0,10">
                                                <TextBlock Text="Shell" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtCommandShell" FontWeight="SemiBold"/>
                                            </StackPanel>
                                            <StackPanel Margin="0,0,12,10">
                                                <TextBlock Text="Administrator" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtCommandAdmin" FontWeight="SemiBold"/>
                                            </StackPanel>
                                            <StackPanel Margin="0,0,0,10">
                                                <TextBlock Text="Execution" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                                                <TextBlock x:Name="TxtCommandExecution" FontWeight="SemiBold"/>
                                            </StackPanel>
                                        </UniformGrid>
                                        <Border Background="{DynamicResource CardBrush}" CornerRadius="8" Padding="12" Margin="0,8,0,0">
                                            <StackPanel>
                                                <TextBlock Text="Example and warning" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold"/>
                                                <TextBlock x:Name="TxtCommandExample" TextWrapping="Wrap" FontFamily="Consolas" Foreground="{DynamicResource MutedBrush}" Margin="0,6,0,0"/>
                                                <TextBlock x:Name="TxtCommandWarning" TextWrapping="Wrap" Foreground="{DynamicResource DangerBrush}" Margin="0,6,0,0"/>
                                            </StackPanel>
                                        </Border>
                                        <WrapPanel Margin="0,16,0,0">
                                            <Button x:Name="BtnCommandCopy" Content="Copy" Style="{StaticResource PrimaryButtonStyle}" MinWidth="130" Margin="0,0,8,8"/>
                                            <Button x:Name="BtnCommandRun" Content="Run after confirmation" Style="{StaticResource BaseButtonStyle}" MinWidth="180" Margin="0,0,8,8"/>
                                        </WrapPanel>
                                    </StackPanel>
                                </ScrollViewer>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>

                <Grid x:Name="PageDownloads" Visibility="Collapsed" Margin="24">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel>
                            <TextBlock Text="Downloads" FontSize="28" FontWeight="Bold"/>
                            <TextBlock Text="Active and completed downloads from official sources." Foreground="{DynamicResource MutedBrush}" Margin="0,5,0,0"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                            <Button x:Name="BtnOpenDownloadFolder" Content="Open download folder" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,0"/>
                            <Button x:Name="BtnDownloadsBackHome" Content="Back to Home" Style="{StaticResource BaseButtonStyle}"/>
                        </StackPanel>
                    </Grid>
                    <ListBox x:Name="ListDownloads"
                             Grid.Row="1"
                             Margin="0,18,0,0"
                             ItemTemplate="{StaticResource DownloadRowTemplate}"
                             Background="Transparent"
                             BorderThickness="0"
                             ScrollViewer.CanContentScroll="True"
                             VirtualizingStackPanel.IsVirtualizing="True"
                             VirtualizingStackPanel.VirtualizationMode="Recycling"/>
                </Grid>

                <Grid x:Name="PageInfo" Visibility="Collapsed" Margin="30">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <StackPanel>
                        <TextBlock Text="TeslaPro Tools" FontSize="32" FontWeight="Bold"/>
                        <TextBlock x:Name="TxtInfoVersion" Text="Version" Foreground="{DynamicResource MutedBrush}" Margin="0,6,0,0"/>
                    </StackPanel>
                    <Border Grid.Row="1" Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="20" Margin="0,20,0,0" VerticalAlignment="Top">
                        <StackPanel>
                            <TextBlock Text="TeslaPro Tools is an independent launcher that points users to official websites, repositories and distribution channels of external tools. TeslaPro Tools does not host, modify, bundle or repackage these external tools. All rights, ownership and credits remain with the original creators." TextWrapping="Wrap" FontSize="15" LineHeight="22"/>
                            <TextBlock Text="Official Discord server: TeslaPro" Foreground="{DynamicResource AccentBrush}" FontWeight="SemiBold" Margin="0,18,0,0"/>
                            <TextBlock Text="Developed with AI assistance. Reviewed for one-file structure, WPF binding, responsive navigation and official-source download handling." Foreground="{DynamicResource MutedBrush}" TextWrapping="Wrap" Margin="0,8,0,0"/>
                            <WrapPanel Margin="0,18,0,0">
                                <Button x:Name="BtnInfoDiscord" Content="Open Discord" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                                <Button x:Name="BtnInfoWebsite" Content="Open TeslaPro site" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                            </WrapPanel>
                        </StackPanel>
                    </Border>
                </Grid>

                <Grid x:Name="PageSettings" Visibility="Collapsed" Margin="30">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <TextBlock Text="Settings" FontSize="32" FontWeight="Bold"/>
                    <Border Grid.Row="1" Background="{DynamicResource PanelBrush}" BorderBrush="{DynamicResource LineBrush}" BorderThickness="1" CornerRadius="8" Padding="20" Margin="0,20,0,0" VerticalAlignment="Top">
                        <StackPanel>
                            <CheckBox x:Name="ChkAnimations" Content="Enable animations" IsChecked="True" Foreground="{DynamicResource TextBrush}" Margin="0,0,0,10"/>
                            <CheckBox x:Name="ChkConfirmTools" Content="Confirm before launching downloaded tools" IsChecked="True" Foreground="{DynamicResource TextBrush}" Margin="0,0,0,10"/>
                            <CheckBox x:Name="ChkConfirmCommands" Content="Confirm before running allowed commands" IsChecked="True" Foreground="{DynamicResource TextBrush}" Margin="0,0,0,10"/>
                            <CheckBox x:Name="ChkSafeMode" Content="Safe mode: block downloads and execution" Foreground="{DynamicResource TextBrush}" Margin="0,0,0,10"/>
                            <CheckBox x:Name="ChkDownloadNotifications" Content="Show download notifications" IsChecked="True" Foreground="{DynamicResource TextBrush}" Margin="0,0,0,16"/>
                            <Grid Margin="0,0,0,14">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="12"/>
                                    <ColumnDefinition Width="220"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Text="Theme" VerticalAlignment="Center" Foreground="{DynamicResource MutedBrush}"/>
                                <ComboBox x:Name="CmbTheme" Grid.Column="2" Style="{StaticResource ComboStyle}"/>
                            </Grid>
                            <TextBlock Text="Download folder" Foreground="{DynamicResource MutedBrush}" FontSize="12"/>
                            <Grid Margin="0,5,0,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="TxtDownloadFolder" Style="{StaticResource InputStyle}" IsReadOnly="True"/>
                                <Button x:Name="BtnChooseDownloadFolder" Grid.Column="1" Content="Choose" Style="{StaticResource BaseButtonStyle}" Margin="8,0,0,0"/>
                                <Button x:Name="BtnSettingsOpenDownloadFolder" Grid.Column="2" Content="Open" Style="{StaticResource BaseButtonStyle}" Margin="8,0,0,0"/>
                            </Grid>
                            <WrapPanel Margin="0,16,0,0">
                                <Button x:Name="BtnCleanupPartFiles" Content="Clean temporary downloads" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                                <Button x:Name="BtnSettingsBackHome" Content="Back to Home" Style="{StaticResource BaseButtonStyle}" Margin="0,0,8,8"/>
                            </WrapPanel>
                        </StackPanel>
                    </Border>
                </Grid>
            </Grid>

            <Border x:Name="NotificationBorder"
                    Grid.Column="1"
                    Visibility="Collapsed"
                    Background="{DynamicResource CardBrush}"
                    BorderBrush="{DynamicResource AccentBrush}"
                    BorderThickness="1"
                    CornerRadius="8"
                    Padding="14"
                    HorizontalAlignment="Right"
                    VerticalAlignment="Bottom"
                    Margin="0,0,26,24"
                    MaxWidth="420">
                <TextBlock x:Name="TxtNotification" Text="Notification" TextWrapping="Wrap"/>
            </Border>

            <Grid x:Name="WelcomeOverlay" Grid.ColumnSpan="2" Background="#E6101116">
                <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                    <TextBlock Text="Welcome to TeslaPro Tools" FontSize="34" FontWeight="Bold" HorizontalAlignment="Center"/>
                    <TextBlock Text="Loading official-source launcher" Foreground="{DynamicResource MutedBrush}" FontSize="15" HorizontalAlignment="Center" Margin="0,8,0,18"/>
                    <ProgressBar Width="280" Height="8" IsIndeterminate="True"/>
                </StackPanel>
            </Grid>
        </Grid>
    </Grid>
</Window>
'@
#endregion

#region GUI mapping
function Initialize-Window {
    $xml = [xml]$script:xaml
    $reader = New-Object System.Xml.XmlNodeReader $xml
    $script:Window = [Windows.Markup.XamlReader]::Load($reader)
    $script:Window.DataContext = $script:Window

    $names = @(
        "TitleBar","TxtTitleVersion","BtnWindowMinimize","BtnWindowClose",
        "BtnNavHome","BtnNavTools","BtnNavCommands","BtnNavDownloads","BtnNavInfo","BtnNavSettings","BtnNavExit",
        "PageHost","PageHome","PageTools","PageCommands","PageDownloads","PageInfo","PageSettings",
        "BtnHomeTools","BtnHomeCommands","TxtHomeToolCount","TxtHomeCommandCount","TxtHomeStatus",
        "BtnToolsBackHome","TxtToolSearch","CmbToolCategory","CmbToolStatus","CmbToolSort","BtnToolClearFilters","TxtToolResultCount","ListTools","TxtToolNoResults",
        "ToolDetailEmpty","ToolDetailContent","TxtToolName","TxtToolAuthor","TxtToolDescription","TxtToolVersion","TxtToolCategory","TxtToolDownloadStatus","TxtToolHashStatus",
        "TxtToolWebsite","TxtToolRepository","TxtToolReleases","TxtToolDownloadSource","TxtToolWarning","TxtToolCredits",
        "BtnToolPrimaryAction","BtnToolOpenWebsite","BtnToolOpenRepo","BtnToolOpenReleases","BtnToolLaunchDownloaded",
        "BtnCommandsBackHome","TxtCommandSearch","CmbCommandCategory","CmbCommandShell","CmbCommandSort","BtnCommandClearFilters","TxtCommandResultCount","ListCommands","TxtCommandNoResults",
        "CommandDetailEmpty","CommandDetailContent","TxtCommandName","TxtCommandMeta","TxtCommandFull","TxtCommandDescription","TxtCommandExplanation","TxtCommandCategory","TxtCommandShell","TxtCommandAdmin","TxtCommandExecution","TxtCommandExample","TxtCommandWarning","BtnCommandCopy","BtnCommandRun",
        "BtnOpenDownloadFolder","BtnDownloadsBackHome","ListDownloads",
        "TxtInfoVersion","BtnInfoDiscord","BtnInfoWebsite",
        "ChkAnimations","ChkConfirmTools","ChkConfirmCommands","ChkSafeMode","ChkDownloadNotifications","CmbTheme","TxtDownloadFolder","BtnChooseDownloadFolder","BtnSettingsOpenDownloadFolder","BtnCleanupPartFiles","BtnSettingsBackHome",
        "NotificationBorder","TxtNotification","WelcomeOverlay"
    )

    foreach ($name in $names) {
        $control = $script:Window.FindName($name)
        if ($null -eq $control) { throw "XAML control '$name' was not found." }
        Set-Variable -Name $name -Value $control -Scope Script
    }
}
#endregion

#region General helpers
function Get-TextValue {
    param([object]$Value, [string]$Fallback = "")
    if ($null -eq $Value) { return $Fallback }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $Fallback }
    return $text
}

function Invoke-OnUi {
    param([scriptblock]$ScriptBlock)
    if ($null -eq $script:Window) {
        & $ScriptBlock
        return
    }
    if ($script:Window.Dispatcher.CheckAccess()) {
        & $ScriptBlock
    } else {
        [void]$script:Window.Dispatcher.Invoke([Action]{ & $ScriptBlock })
    }
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -lt 0) { return "Unknown size" }
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function New-Brush {
    param([string]$Color)
    New-Object Windows.Media.SolidColorBrush ([Windows.Media.ColorConverter]::ConvertFromString($Color))
}

function Set-ResourceBrush {
    param([string]$Key, [string]$Color)
    $script:Window.Resources[$Key] = New-Brush $Color
}

function Get-UniqueSorted {
    param([object[]]$Values, [string]$AllLabel)
    $items = @($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Sort-Object -Unique)
    @($AllLabel) + $items
}

function Show-Message {
    param(
        [string]$Text,
        [string]$Title = $script:AppName,
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
    )
    [void][System.Windows.MessageBox]::Show($script:Window, $Text, $Title, [System.Windows.MessageBoxButton]::OK, $Icon)
}

function Confirm-Action {
    param(
        [string]$Text,
        [string]$Title = $script:AppName,
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Warning
    )
    $result = [System.Windows.MessageBox]::Show($script:Window, $Text, $Title, [System.Windows.MessageBoxButton]::YesNo, $Icon)
    return ($result -eq [System.Windows.MessageBoxResult]::Yes)
}
#endregion

#region Navigation
function Set-ActiveNavButton {
    param([string]$PageName)
    $map = @{
        PageHome      = $script:BtnNavHome
        PageTools     = $script:BtnNavTools
        PageCommands  = $script:BtnNavCommands
        PageDownloads = $script:BtnNavDownloads
        PageInfo      = $script:BtnNavInfo
        PageSettings  = $script:BtnNavSettings
    }

    foreach ($entry in $map.GetEnumerator()) {
        if ($entry.Key -eq $PageName) {
            $entry.Value.Background = $script:Window.Resources["SelectedBrush"]
            $entry.Value.BorderThickness = New-Object Windows.Thickness 1
            $entry.Value.BorderBrush = $script:Window.Resources["AccentBrush"]
        } else {
            $entry.Value.Background = [Windows.Media.Brushes]::Transparent
            $entry.Value.BorderThickness = New-Object Windows.Thickness 0
        }
    }
}

function Show-Page {
    param([Parameter(Mandatory)][string]$PageName)

    $pages = @($script:PageHome, $script:PageTools, $script:PageCommands, $script:PageDownloads, $script:PageInfo, $script:PageSettings)
    $target = $pages | Where-Object { $_.Name -eq $PageName } | Select-Object -First 1
    if ($null -eq $target) { throw "Unknown page '$PageName'." }

    foreach ($page in $pages) {
        $page.Visibility = if ($page.Name -eq $PageName) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }
    }

    $script:CurrentPage = $PageName
    Set-ActiveNavButton -PageName $PageName

    if ($script:Settings.AnimationsEnabled) {
        Start-FadeIn -Element $target
    } else {
        $target.Opacity = 1
    }
}
#endregion

#region Animations
function Start-FadeIn {
    param([Windows.UIElement]$Element)
    if ($null -eq $Element) { return }
    $Element.Opacity = 0
    $animation = New-Object Windows.Media.Animation.DoubleAnimation
    $animation.From = 0
    $animation.To = 1
    $animation.Duration = New-Object Windows.Duration ([TimeSpan]::FromMilliseconds(160))
    $Element.BeginAnimation([Windows.UIElement]::OpacityProperty, $animation)
}

function Hide-WelcomeOverlay {
    if ($script:Settings.AnimationsEnabled) {
        $animation = New-Object Windows.Media.Animation.DoubleAnimation
        $animation.From = 1
        $animation.To = 0
        $animation.Duration = New-Object Windows.Duration ([TimeSpan]::FromMilliseconds(260))
        $animation.Add_Completed({
            $script:WelcomeOverlay.Visibility = [Windows.Visibility]::Collapsed
            $script:WelcomeOverlay.Opacity = 1
        })
        $script:WelcomeOverlay.BeginAnimation([Windows.UIElement]::OpacityProperty, $animation)
    } else {
        $script:WelcomeOverlay.Visibility = [Windows.Visibility]::Collapsed
    }
}
#endregion

#region Notifications
function Show-Notification {
    param([string]$Text, [int]$Milliseconds = 2600)
    if (-not $script:Settings.DownloadNotifications -and $Text -match "download") { return }
    Invoke-OnUi {
        $script:TxtNotification.Text = $Text
        $script:NotificationBorder.Visibility = [Windows.Visibility]::Visible
        if ($script:Settings.AnimationsEnabled) { Start-FadeIn -Element $script:NotificationBorder }

        $timer = New-Object Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds($Milliseconds)
        $timer.Add_Tick({
            $this.Stop()
            $script:NotificationBorder.Visibility = [Windows.Visibility]::Collapsed
        })
        $script:Timers += $timer
        $timer.Start()
    }
}
#endregion

#region Home
function Update-HomeStats {
    $script:TxtTitleVersion.Text = "v$script:AppVersion"
    $script:TxtInfoVersion.Text = "Version $script:AppVersion"
    $script:TxtHomeToolCount.Text = "Tools: {0}" -f $script:Tools.Count
    $script:TxtHomeCommandCount.Text = "Commands: {0}" -f $script:Commands.Count
    $script:TxtHomeStatus.Text = "Ready - official sources only"
}
#endregion

#region Tools rendering
function Initialize-ToolBinding {
    $script:ToolsCollection.Clear()
    foreach ($tool in $script:Tools) { [void]$script:ToolsCollection.Add($tool) }

    $script:ToolsView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($script:ToolsCollection)
    $script:ToolsView.Filter = [Predicate[object]]{ param($item) Test-ToolMatchesFilter -Tool $item }
    $script:ListTools.ItemsSource = $script:ToolsView

    $script:CmbToolCategory.ItemsSource = Get-UniqueSorted -Values ($script:Tools | ForEach-Object { $_.Category }) -AllLabel "All categories"
    $script:CmbToolStatus.ItemsSource = Get-UniqueSorted -Values ($script:Tools | ForEach-Object { $_.Status }) -AllLabel "All statuses"
    $script:CmbToolSort.ItemsSource = @("Name (A-Z)", "Name (Z-A)", "Author (A-Z)", "Category (A-Z)")
    $script:CmbToolCategory.SelectedIndex = 0
    $script:CmbToolStatus.SelectedIndex = 0
    $script:CmbToolSort.SelectedIndex = 0

    Set-ToolSort
    Update-ToolResultCount
    Update-ToolDetail -Tool $null
}

function Test-ToolMatchesFilter {
    param([object]$Tool)
    if ($null -eq $Tool) { return $false }

    $query = ""
    if ($null -ne $script:TxtToolSearch) { $query = $script:TxtToolSearch.Text.Trim().ToLowerInvariant() }

    $category = [string]$script:CmbToolCategory.SelectedItem
    $status = [string]$script:CmbToolStatus.SelectedItem

    if (-not [string]::IsNullOrWhiteSpace($category) -and $category -ne "All categories" -and $Tool.Category -ne $category) { return $false }
    if (-not [string]::IsNullOrWhiteSpace($status) -and $status -ne "All statuses" -and $Tool.Status -ne $status) { return $false }

    if ([string]::IsNullOrWhiteSpace($query)) { return $true }

    $haystack = @(
        $Tool.Name, $Tool.Author, $Tool.Description, $Tool.Category, $Tool.Status,
        $Tool.OfficialWebsite, $Tool.GitHubRepository, $Tool.GitHubReleasePage, $Tool.DirectDownloadUrl
    ) -join " "
    return $haystack.ToLowerInvariant().Contains($query)
}

function Set-ToolSort {
    if ($null -eq $script:ToolsView) { return }
    $script:ToolsView.SortDescriptions.Clear()
    switch ([string]$script:CmbToolSort.SelectedItem) {
        "Name (Z-A)"     { $script:ToolsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Descending)) }
        "Author (A-Z)"   { $script:ToolsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Author", [System.ComponentModel.ListSortDirection]::Ascending)) }
        "Category (A-Z)" { $script:ToolsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Category", [System.ComponentModel.ListSortDirection]::Ascending)); $script:ToolsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Ascending)) }
        default          { $script:ToolsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Ascending)) }
    }
}

function Refresh-ToolView {
    if ($null -eq $script:ToolsView) { return }
    Set-ToolSort
    $script:ToolsView.Refresh()
    Update-ToolResultCount
}

function Update-ToolResultCount {
    $count = 0
    if ($null -ne $script:ToolsView) {
        foreach ($item in $script:ToolsView) { $count++ }
    }
    $script:TxtToolResultCount.Text = "{0} tools found" -f $count
    $script:TxtToolNoResults.Visibility = if ($count -eq 0) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }
}
#endregion

#region Tools filtering and sorting
function Clear-ToolFilters {
    $script:TxtToolSearch.Text = ""
    $script:CmbToolCategory.SelectedIndex = 0
    $script:CmbToolStatus.SelectedIndex = 0
    $script:CmbToolSort.SelectedIndex = 0
    Refresh-ToolView
}
#endregion

#region Tool detail panel
function Get-PrimaryActionText {
    param([object]$Tool)
    if ($null -eq $Tool) { return "Open" }
    switch ($Tool.ActionType) {
        "OfficialWebsite"     { return "Official website" }
        "GitHubRepository"    { return "Open GitHub" }
        "GitHubReleasePage"   { return "Open releases" }
        "DirectDownload"      { return "Download" }
        "GitHubReleaseAsset"  { return "Download release asset" }
        "LaunchDownloadedFile"{ return "Start/Open" }
        default               { return "Open" }
    }
}

function Update-ToolDetail {
    param([object]$Tool)

    if ($null -eq $Tool) {
        $script:ToolDetailEmpty.Visibility = [Windows.Visibility]::Visible
        $script:ToolDetailContent.Visibility = [Windows.Visibility]::Collapsed
        foreach ($button in @($script:BtnToolPrimaryAction,$script:BtnToolOpenWebsite,$script:BtnToolOpenRepo,$script:BtnToolOpenReleases,$script:BtnToolLaunchDownloaded)) {
            $button.IsEnabled = $false
        }
        return
    }

    $script:ToolDetailEmpty.Visibility = [Windows.Visibility]::Collapsed
    $script:ToolDetailContent.Visibility = [Windows.Visibility]::Visible

    $script:TxtToolName.Text = $Tool.Name
    $script:TxtToolAuthor.Text = "By {0}" -f $Tool.Author
    $script:TxtToolDescription.Text = $Tool.Description
    $script:TxtToolVersion.Text = Get-TextValue $Tool.Version "Unknown"
    $script:TxtToolCategory.Text = Get-TextValue $Tool.Category "General"
    $script:TxtToolDownloadStatus.Text = Get-TextValue $Tool.DownloadStatus "Not downloaded"
    $script:TxtToolHashStatus.Text = Get-TextValue $Tool.HashStatus "No SHA-256 configured"
    $script:TxtToolWebsite.Text = "Website: " + (Get-TextValue $Tool.OfficialWebsite "Not configured")
    $script:TxtToolRepository.Text = "GitHub: " + (Get-TextValue $Tool.GitHubRepository "Not configured")
    $script:TxtToolReleases.Text = "Releases: " + (Get-TextValue $Tool.GitHubReleasePage "Not configured")
    $source = switch ($Tool.ActionType) {
        "DirectDownload"     { Get-TextValue $Tool.DirectDownloadUrl "Not configured" }
        "GitHubReleaseAsset" { Get-TextValue $Tool.GitHubReleasePage $Tool.GitHubRepository }
        default              { Get-TextValue $Tool.OfficialWebsite (Get-TextValue $Tool.GitHubRepository $Tool.GitHubReleasePage) }
    }
    $script:TxtToolDownloadSource.Text = "Used source: " + (Get-TextValue $source "Not configured")
    $script:TxtToolWarning.Text = "Warning: " + (Get-TextValue $Tool.Warning "No extra warning.")
    $script:TxtToolCredits.Text = "Credits: " + (Get-TextValue $Tool.Credits "All credits belong to the original creator.")

    $script:BtnToolPrimaryAction.Content = Get-PrimaryActionText -Tool $Tool
    $script:BtnToolPrimaryAction.IsEnabled = $true
    $script:BtnToolOpenWebsite.IsEnabled = -not [string]::IsNullOrWhiteSpace($Tool.OfficialWebsite)
    $script:BtnToolOpenRepo.IsEnabled = -not [string]::IsNullOrWhiteSpace($Tool.GitHubRepository)
    $script:BtnToolOpenReleases.IsEnabled = -not [string]::IsNullOrWhiteSpace($Tool.GitHubReleasePage)
    $script:BtnToolLaunchDownloaded.IsEnabled = (-not [string]::IsNullOrWhiteSpace($Tool.LocalPath) -and (Test-Path -LiteralPath $Tool.LocalPath))
}
#endregion

#region Commands rendering
function Initialize-CommandBinding {
    $script:CommandsCollection.Clear()
    foreach ($command in $script:Commands) { [void]$script:CommandsCollection.Add($command) }

    $script:CommandsView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($script:CommandsCollection)
    $script:CommandsView.Filter = [Predicate[object]]{ param($item) Test-CommandMatchesFilter -Command $item }
    $script:ListCommands.ItemsSource = $script:CommandsView

    $script:CmbCommandCategory.ItemsSource = Get-UniqueSorted -Values ($script:Commands | ForEach-Object { $_.Category }) -AllLabel "All categories"
    $script:CmbCommandShell.ItemsSource = Get-UniqueSorted -Values ($script:Commands | ForEach-Object { $_.Shell }) -AllLabel "All shells"
    $script:CmbCommandSort.ItemsSource = @("Name (A-Z)", "Name (Z-A)", "Category (A-Z)", "Shell (A-Z)")
    $script:CmbCommandCategory.SelectedIndex = 0
    $script:CmbCommandShell.SelectedIndex = 0
    $script:CmbCommandSort.SelectedIndex = 0

    Set-CommandSort
    Update-CommandResultCount
    Update-CommandDetail -Command $null
}

function Test-CommandMatchesFilter {
    param([object]$Command)
    if ($null -eq $Command) { return $false }

    $query = ""
    if ($null -ne $script:TxtCommandSearch) { $query = $script:TxtCommandSearch.Text.Trim().ToLowerInvariant() }

    $category = [string]$script:CmbCommandCategory.SelectedItem
    $shell = [string]$script:CmbCommandShell.SelectedItem

    if (-not [string]::IsNullOrWhiteSpace($category) -and $category -ne "All categories" -and $Command.Category -ne $category) { return $false }
    if (-not [string]::IsNullOrWhiteSpace($shell) -and $shell -ne "All shells" -and $Command.Shell -ne $shell) { return $false }

    if ([string]::IsNullOrWhiteSpace($query)) { return $true }

    $haystack = @($Command.Name, $Command.Command, $Command.Description, $Command.Explanation, $Command.Category, $Command.Shell) -join " "
    return $haystack.ToLowerInvariant().Contains($query)
}

function Set-CommandSort {
    if ($null -eq $script:CommandsView) { return }
    $script:CommandsView.SortDescriptions.Clear()
    switch ([string]$script:CmbCommandSort.SelectedItem) {
        "Name (Z-A)"      { $script:CommandsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Descending)) }
        "Category (A-Z)"  { $script:CommandsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Category", [System.ComponentModel.ListSortDirection]::Ascending)); $script:CommandsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Ascending)) }
        "Shell (A-Z)"     { $script:CommandsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Shell", [System.ComponentModel.ListSortDirection]::Ascending)); $script:CommandsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Ascending)) }
        default           { $script:CommandsView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Ascending)) }
    }
}

function Refresh-CommandView {
    if ($null -eq $script:CommandsView) { return }
    Set-CommandSort
    $script:CommandsView.Refresh()
    Update-CommandResultCount
}

function Update-CommandResultCount {
    $count = 0
    if ($null -ne $script:CommandsView) {
        foreach ($item in $script:CommandsView) { $count++ }
    }
    $script:TxtCommandResultCount.Text = "{0} commands found" -f $count
    $script:TxtCommandNoResults.Visibility = if ($count -eq 0) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }
}
#endregion

#region Commands filtering and sorting
function Clear-CommandFilters {
    $script:TxtCommandSearch.Text = ""
    $script:CmbCommandCategory.SelectedIndex = 0
    $script:CmbCommandShell.SelectedIndex = 0
    $script:CmbCommandSort.SelectedIndex = 0
    Refresh-CommandView
}
#endregion

#region Command detail panel
function Update-CommandDetail {
    param([object]$Command)

    if ($null -eq $Command) {
        $script:CommandDetailEmpty.Visibility = [Windows.Visibility]::Visible
        $script:CommandDetailContent.Visibility = [Windows.Visibility]::Collapsed
        $script:BtnCommandCopy.IsEnabled = $false
        $script:BtnCommandRun.IsEnabled = $false
        return
    }

    $script:CommandDetailEmpty.Visibility = [Windows.Visibility]::Collapsed
    $script:CommandDetailContent.Visibility = [Windows.Visibility]::Visible
    $script:TxtCommandName.Text = $Command.Name
    $script:TxtCommandMeta.Text = "{0} / {1}" -f $Command.Category, $Command.Shell
    $script:TxtCommandFull.Text = $Command.Command
    $script:TxtCommandDescription.Text = $Command.Description
    $script:TxtCommandExplanation.Text = $Command.Explanation
    $script:TxtCommandCategory.Text = $Command.Category
    $script:TxtCommandShell.Text = $Command.Shell
    $script:TxtCommandAdmin.Text = if ($Command.RequiresAdministrator) { "Required" } else { "Not required" }
    $script:TxtCommandExecution.Text = if ($Command.AllowExecution) { "Allowed after confirmation" } else { "Copy only" }
    $script:TxtCommandExample.Text = $Command.Example
    $script:TxtCommandWarning.Text = Get-TextValue $Command.Warning "No extra warning."
    $script:BtnCommandCopy.IsEnabled = $true
    $script:BtnCommandRun.IsEnabled = [bool]$Command.AllowExecution
}
#endregion

#region URL validation
function ConvertTo-ValidatedUri {
    param(
        [Parameter(Mandatory)][string]$Url,
        [string[]]$AllowedDomains = @()
    )

    if ([string]::IsNullOrWhiteSpace($Url)) { throw "URL is empty." }
    $uri = $null
    if (-not [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri)) { throw "Invalid URL: $Url" }
    if ($uri.Scheme -ne "https") { throw "Only HTTPS URLs are allowed: $Url" }
    if ($AllowedDomains.Count -gt 0 -and -not (Test-DomainAllowed -Host $uri.Host -AllowedDomains $AllowedDomains)) {
        throw "Domain '$($uri.Host)' is not allowed for this item."
    }
    return $uri
}

function Open-SafeUrl {
    param(
        [Parameter(Mandatory)][string]$Url,
        [string[]]$AllowedDomains = @()
    )

    try {
        $uri = ConvertTo-ValidatedUri -Url $Url -AllowedDomains $AllowedDomains
        $psi = New-Object Diagnostics.ProcessStartInfo
        $psi.FileName = $uri.AbsoluteUri
        $psi.UseShellExecute = $true
        [Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Show-Message -Text $_.Exception.Message -Icon ([System.Windows.MessageBoxImage]::Warning)
    }
}
#endregion

#region Domain validation
function Test-DomainAllowed {
    param(
        [Parameter(Mandatory)][string]$Host,
        [string[]]$AllowedDomains
    )

    if ([string]::IsNullOrWhiteSpace($Host)) { return $false }
    $normalizedHost = $Host.Trim().ToLowerInvariant()
    foreach ($domain in $AllowedDomains) {
        if ([string]::IsNullOrWhiteSpace($domain)) { continue }
        $normalizedDomain = $domain.Trim().ToLowerInvariant()
        if ($normalizedHost -eq $normalizedDomain) { return $true }
        if ($normalizedHost.EndsWith("." + $normalizedDomain, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}
#endregion

#region GitHub handling
function Get-GitHubRepoParts {
    param([string]$GitHubRepository)
    $uri = ConvertTo-ValidatedUri -Url $GitHubRepository -AllowedDomains @("github.com")
    $parts = $uri.AbsolutePath.Trim("/").Split("/")
    if ($parts.Count -lt 2) { throw "GitHub repository URL must contain owner and repository." }
    [PSCustomObject]@{ Owner = $parts[0]; Repo = $parts[1] }
}

function Test-ExcludedGitHubAssetName {
    param([string]$Name)
    $lower = $Name.ToLowerInvariant()
    $blockedTerms = @("source code","source-code","src","debug","symbols","symbol","pdb","checksum","checksums","sha256","sha512","signature",".sig",".asc","linux","macos","darwin","arm64","aarch64")
    foreach ($term in $blockedTerms) {
        if ($lower.Contains($term)) { return $true }
    }
    return $false
}

function Get-GitHubLatestAssetCandidate {
    param([object]$Tool)

    if ([string]::IsNullOrWhiteSpace($Tool.GitHubRepository)) { throw "No GitHub repository configured." }
    if ([string]::IsNullOrWhiteSpace($Tool.GitHubAssetPattern)) { throw "No GitHub asset pattern configured." }

    $repo = Get-GitHubRepoParts -GitHubRepository $Tool.GitHubRepository
    $apiUrl = "https://api.github.com/repos/{0}/{1}/releases/latest" -f $repo.Owner, $repo.Repo
    $headers = @{ "User-Agent" = $script:UserAgent; "Accept" = "application/vnd.github+json" }
    $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get

    $matches = @()
    foreach ($asset in $release.assets) {
        $name = [string]$asset.name
        if ([string]::IsNullOrWhiteSpace($name)) { continue }
        if (Test-ExcludedGitHubAssetName -Name $name) { continue }
        if ($name -notmatch $Tool.GitHubAssetPattern) { continue }
        if (-not (Test-AllowedExtension -FileName $name -AllowedExtensions $Tool.AllowedExtensions)) { continue }
        $matches += $asset
    }

    if ($matches.Count -eq 0) { throw "No safe release asset matched '$($Tool.GitHubAssetPattern)'." }
    if ($matches.Count -gt 1) { throw "Multiple release assets matched. Open the releases page and choose manually." }

    [PSCustomObject]@{
        Name = [string]$matches[0].name
        Url  = [string]$matches[0].browser_download_url
    }
}

function Start-GitHubReleaseAssetDownload {
    param([object]$Tool)

    if ($script:Settings.SafeMode) {
        Show-Notification "Safe mode blocks downloads."
        return
    }

    Show-Notification "Resolving latest GitHub release asset for $($Tool.Name)..."
    $worker = New-Object ComponentModel.BackgroundWorker
    $worker.WorkerReportsProgress = $false
    $worker.WorkerSupportsCancellation = $false
    $worker.Add_DoWork({
        param($sender, $e)
        try {
            $asset = Get-GitHubLatestAssetCandidate -Tool $e.Argument
            $e.Result = @{ Success = $true; Asset = $asset; Tool = $e.Argument }
        } catch {
            $e.Result = @{ Success = $false; Error = $_.Exception.Message; Tool = $e.Argument }
        }
    })
    $worker.Add_RunWorkerCompleted({
        param($sender, $e)
        Invoke-OnUi {
            $result = $e.Result
            if ($result.Success) {
                Start-OfficialDownload -Tool $result.Tool -Url $result.Asset.Url -SuggestedFileName $result.Asset.Name
            } else {
                Show-Notification $result.Error
                if (-not [string]::IsNullOrWhiteSpace($result.Tool.GitHubReleasePage)) {
                    Open-SafeUrl -Url $result.Tool.GitHubReleasePage -AllowedDomains $result.Tool.AllowedDomains
                }
            }
        }
    })
    $worker.RunWorkerAsync($Tool)
}
#endregion

#region Download engine
function Test-AllowedExtension {
    param([string]$FileName, [string[]]$AllowedExtensions)
    if ($AllowedExtensions.Count -eq 0) { return $false }
    $extension = [IO.Path]::GetExtension($FileName)
    if ([string]::IsNullOrWhiteSpace($extension)) { return $false }
    foreach ($allowed in $AllowedExtensions) {
        if ($extension.Equals($allowed, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Get-SafeFileName {
    param([string]$FileName)
    $name = [IO.Path]::GetFileName($FileName)
    if ([string]::IsNullOrWhiteSpace($name)) { throw "Download file name is empty." }
    foreach ($char in [IO.Path]::GetInvalidFileNameChars()) {
        $name = $name.Replace([string]$char, "_")
    }
    if ($name -eq "." -or $name -eq "..") { throw "Unsafe file name." }
    return $name
}

function Test-PathInsideRoot {
    param([string]$Path, [string]$Root)
    $rootFull = [IO.Path]::GetFullPath((Join-Path $Root "."))
    $pathFull = [IO.Path]::GetFullPath($Path)
    return $pathFull.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)
}

function Get-SafeDestinationPath {
    param([string]$FileName)
    if (-not (Test-Path -LiteralPath $script:Settings.DownloadRoot)) {
        [IO.Directory]::CreateDirectory($script:Settings.DownloadRoot) | Out-Null
    }
    $safeName = Get-SafeFileName -FileName $FileName
    $destination = Join-Path $script:Settings.DownloadRoot $safeName
    if (-not (Test-PathInsideRoot -Path $destination -Root $script:Settings.DownloadRoot)) {
        throw "Blocked unsafe download path."
    }
    return [IO.Path]::GetFullPath($destination)
}

function Resolve-FinalDownloadUri {
    param(
        [Parameter(Mandatory)][Uri]$Uri,
        [string[]]$AllowedDomains
    )

    $current = $Uri
    for ($i = 0; $i -lt 8; $i++) {
        if (-not (Test-DomainAllowed -Host $current.Host -AllowedDomains $AllowedDomains)) {
            throw "Redirect target domain '$($current.Host)' is not allowed."
        }

        $request = [Net.HttpWebRequest]::Create($current)
        $request.Method = "GET"
        $request.AllowAutoRedirect = $false
        $request.UserAgent = $script:UserAgent
        $request.Timeout = 20000
        $response = $null
        try {
            $response = [Net.HttpWebResponse]$request.GetResponse()
            $status = [int]$response.StatusCode
            if ($status -ge 300 -and $status -lt 400) {
                $location = $response.Headers["Location"]
                if ([string]::IsNullOrWhiteSpace($location)) { throw "Redirect without Location header." }
                $next = $null
                if ([Uri]::TryCreate($location, [UriKind]::Absolute, [ref]$next)) {
                    $current = $next
                } else {
                    $current = New-Object Uri $current, $location
                }
                if ($current.Scheme -ne "https") { throw "Redirect to non-HTTPS URL blocked." }
                continue
            }
            if ($status -lt 200 -or $status -ge 300) { throw "Unexpected HTTP status: $status" }
            return $current
        } finally {
            if ($null -ne $response) { $response.Close() }
        }
    }

    throw "Too many redirects."
}

function Start-OfficialDownload {
    param(
        [Parameter(Mandatory)][object]$Tool,
        [Parameter(Mandatory)][string]$Url,
        [string]$SuggestedFileName = ""
    )

    if ($script:Settings.SafeMode) {
        Show-Notification "Safe mode blocks downloads."
        return
    }

    try {
        $uri = ConvertTo-ValidatedUri -Url $Url -AllowedDomains $Tool.AllowedDomains
        $fileName = if (-not [string]::IsNullOrWhiteSpace($SuggestedFileName)) { $SuggestedFileName } elseif (-not [string]::IsNullOrWhiteSpace($Tool.DownloadFileName)) { $Tool.DownloadFileName } else { [IO.Path]::GetFileName($uri.AbsolutePath) }
        $fileName = Get-SafeFileName -FileName $fileName
        if (-not (Test-AllowedExtension -FileName $fileName -AllowedExtensions $Tool.AllowedExtensions)) {
            throw "File extension is not allowed for this tool: $fileName"
        }

        $destination = Get-SafeDestinationPath -FileName $fileName
        if (Test-Path -LiteralPath $destination) {
            $overwrite = Confirm-Action -Text "The file already exists:`n$destination`n`nOverwrite it?" -Title "Overwrite download?"
            if (-not $overwrite) { return }
        }

        foreach ($existing in $script:DownloadContexts.Values) {
            if ($existing.Tool.Id -eq $Tool.Id -and $existing.Status -eq "Active") {
                Show-Notification "A download for $($Tool.Name) is already active."
                return
            }
        }

        $downloadId = [Guid]::NewGuid().ToString("N")
        $item = New-Object TeslaProTools.DownloadItem
        $item.Id = $downloadId
        $item.ToolId = $Tool.Id
        $item.ToolName = $Tool.Name
        $item.FileName = $fileName
        $item.SourceUrl = $uri.AbsoluteUri
        $item.Status = "Queued"
        $item.Progress = 0
        $item.BytesText = "Waiting"
        $item.SpeedText = ""
        $item.ErrorText = ""
        $item.FilePath = $destination
        $item.HashStatus = if ([string]::IsNullOrWhiteSpace($Tool.Sha256)) { "No SHA-256 configured" } else { "Pending SHA-256 check" }
        $item.CanCancel = $true
        $item.CanRetry = $false
        $item.CanOpen = $false
        $item.Tool = $Tool
        [void]$script:DownloadsCollection.Insert(0, $item)

        $context = @{
            Id                = $downloadId
            Tool              = $Tool
            Item              = $item
            Uri               = $uri
            Url               = $uri.AbsoluteUri
            DestinationPath   = $destination
            PartPath          = $destination + ".part"
            AllowedDomains    = $Tool.AllowedDomains
            AllowedExtensions = $Tool.AllowedExtensions
            Sha256            = $Tool.Sha256
            Status            = "Active"
            SuggestedFileName = $fileName
        }
        $script:DownloadContexts[$downloadId] = $context

        $worker = New-Object ComponentModel.BackgroundWorker
        $worker.WorkerReportsProgress = $true
        $worker.WorkerSupportsCancellation = $true
        $script:DownloadWorkers[$downloadId] = $worker

        $worker.Add_DoWork({
            param($sender, $e)
            $ctx = $e.Argument
            $started = [DateTime]::UtcNow
            $received = [long]0
            $response = $null
            $inputStream = $null
            $outputStream = $null

            try {
                if ([IO.File]::Exists($ctx.PartPath)) { [IO.File]::Delete($ctx.PartPath) }

                $finalUri = Resolve-FinalDownloadUri -Uri $ctx.Uri -AllowedDomains $ctx.AllowedDomains
                $request = [Net.HttpWebRequest]::Create($finalUri)
                $request.Method = "GET"
                $request.AllowAutoRedirect = $false
                $request.UserAgent = $script:UserAgent
                $request.Timeout = 30000
                $response = [Net.HttpWebResponse]$request.GetResponse()
                $total = [long]$response.ContentLength
                $inputStream = $response.GetResponseStream()
                $outputStream = New-Object IO.FileStream ($ctx.PartPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
                $buffer = New-Object byte[] 81920

                while ($true) {
                    if ($sender.CancellationPending) {
                        throw (New-Object OperationCanceledException "Download canceled.")
                    }
                    $read = $inputStream.Read($buffer, 0, $buffer.Length)
                    if ($read -le 0) { break }
                    $outputStream.Write($buffer, 0, $read)
                    $received += $read
                    $elapsed = [Math]::Max(0.1, ([DateTime]::UtcNow - $started).TotalSeconds)
                    $speed = [long]($received / $elapsed)
                    $percent = if ($total -gt 0) { [Math]::Min(100, [int](($received * 100) / $total)) } else { 0 }
                    $sender.ReportProgress($percent, @{ Id = $ctx.Id; Received = $received; Total = $total; Speed = $speed })
                }

                $outputStream.Flush()
                $outputStream.Dispose(); $outputStream = $null
                $inputStream.Dispose(); $inputStream = $null
                $response.Close(); $response = $null

                if ([IO.File]::Exists($ctx.DestinationPath)) { [IO.File]::Delete($ctx.DestinationPath) }
                [IO.File]::Move($ctx.PartPath, $ctx.DestinationPath)

                $hashStatus = "No SHA-256 configured"
                if (-not [string]::IsNullOrWhiteSpace($ctx.Sha256)) {
                    $actual = (Get-FileHash -LiteralPath $ctx.DestinationPath -Algorithm SHA256).Hash
                    if (-not $actual.Equals($ctx.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                        [IO.File]::Delete($ctx.DestinationPath)
                        throw "SHA-256 mismatch. The downloaded file was removed."
                    }
                    $hashStatus = "SHA-256 verified"
                }

                $e.Result = @{
                    Success = $true
                    Id = $ctx.Id
                    Path = $ctx.DestinationPath
                    FinalUrl = $finalUri.AbsoluteUri
                    HashStatus = $hashStatus
                    Received = $received
                }
            } catch [OperationCanceledException] {
                if ($null -ne $outputStream) { $outputStream.Dispose() }
                if ($null -ne $inputStream) { $inputStream.Dispose() }
                if ($null -ne $response) { $response.Close() }
                if ([IO.File]::Exists($ctx.PartPath)) { [IO.File]::Delete($ctx.PartPath) }
                $e.Cancel = $true
                $e.Result = @{ Success = $false; Id = $ctx.Id; Canceled = $true; Error = "Download canceled." }
            } catch {
                if ($null -ne $outputStream) { $outputStream.Dispose() }
                if ($null -ne $inputStream) { $inputStream.Dispose() }
                if ($null -ne $response) { $response.Close() }
                if ([IO.File]::Exists($ctx.PartPath)) { [IO.File]::Delete($ctx.PartPath) }
                $e.Result = @{ Success = $false; Id = $ctx.Id; Error = $_.Exception.Message }
            }
        })

        $worker.Add_ProgressChanged({
            param($sender, $e)
            $state = $e.UserState
            Invoke-OnUi {
                if (-not $script:DownloadContexts.ContainsKey($state.Id)) { return }
                $download = $script:DownloadContexts[$state.Id].Item
                $download.Status = "Downloading"
                $download.Progress = $e.ProgressPercentage
                $receivedText = Format-Bytes -Bytes ([long]$state.Received)
                $totalText = if ([long]$state.Total -gt 0) { Format-Bytes -Bytes ([long]$state.Total) } else { "Unknown size" }
                $download.BytesText = "$receivedText / $totalText"
                $download.SpeedText = "{0}/s" -f (Format-Bytes -Bytes ([long]$state.Speed))
            }
        })

        $worker.Add_RunWorkerCompleted({
            param($sender, $e)
            Invoke-OnUi {
                $result = $e.Result
                $ctx = $script:DownloadContexts[$result.Id]
                $download = $ctx.Item
                $ctx.Status = "Finished"
                $download.CanCancel = $false

                if ($result.Success) {
                    $download.Status = "Completed"
                    $download.Progress = 100
                    $download.FilePath = $result.Path
                    $download.SourceUrl = $result.FinalUrl
                    $download.HashStatus = $result.HashStatus
                    $download.BytesText = Format-Bytes -Bytes ([long]$result.Received)
                    $download.SpeedText = "Completed"
                    $download.ErrorText = ""
                    $download.CanOpen = $true
                    $download.CanRetry = $false
                    $ctx.Tool.LocalPath = $result.Path
                    $ctx.Tool.DownloadStatus = "Downloaded"
                    $ctx.Tool.HashStatus = $result.HashStatus
                    if ($script:ListTools.SelectedItem -eq $ctx.Tool) { Update-ToolDetail -Tool $ctx.Tool }
                    Show-Notification "Download completed: $($ctx.Tool.Name)"
                } elseif ($result.Canceled) {
                    $download.Status = "Canceled"
                    $download.ErrorText = "Canceled by user."
                    $download.BytesText = ""
                    $download.SpeedText = ""
                    $download.CanRetry = $true
                    $download.CanOpen = $false
                    $ctx.Tool.DownloadStatus = "Canceled"
                    if ($script:ListTools.SelectedItem -eq $ctx.Tool) { Update-ToolDetail -Tool $ctx.Tool }
                    Show-Notification "Download canceled: $($ctx.Tool.Name)"
                } else {
                    $download.Status = "Failed"
                    $download.ErrorText = $result.Error
                    $download.BytesText = ""
                    $download.SpeedText = ""
                    $download.CanRetry = $true
                    $download.CanOpen = $false
                    $ctx.Tool.DownloadStatus = "Failed"
                    if ($script:ListTools.SelectedItem -eq $ctx.Tool) { Update-ToolDetail -Tool $ctx.Tool }
                    Show-Notification "Download failed: $($ctx.Tool.Name)"
                }
            }
        })

        $worker.RunWorkerAsync($context)
        Show-Page -PageName "PageDownloads"
        Show-Notification "Download queued: $($Tool.Name)"
    } catch {
        Show-Message -Text $_.Exception.Message -Icon ([System.Windows.MessageBoxImage]::Warning)
    }
}
#endregion

#region Download security
function Test-FileHashForTool {
    param([object]$Tool, [string]$Path)

    if ([string]::IsNullOrWhiteSpace($Tool.Sha256)) { return "No SHA-256 configured" }
    if (-not (Test-Path -LiteralPath $Path)) { return "File missing" }

    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual.Equals($Tool.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
        return "SHA-256 verified"
    }
    return "SHA-256 mismatch"
}

function Cancel-DownloadItem {
    param([TeslaProTools.DownloadItem]$Download)
    if ($null -eq $Download -or -not $Download.CanCancel) { return }
    if ($script:DownloadWorkers.ContainsKey($Download.Id)) {
        $Download.Status = "Canceling"
        $Download.CanCancel = $false
        $script:DownloadWorkers[$Download.Id].CancelAsync()
    }
}

function Retry-DownloadItem {
    param([TeslaProTools.DownloadItem]$Download)
    if ($null -eq $Download -or -not $Download.CanRetry) { return }
    if (-not $script:DownloadContexts.ContainsKey($Download.Id)) { return }
    $ctx = $script:DownloadContexts[$Download.Id]
    Start-OfficialDownload -Tool $ctx.Tool -Url $ctx.Url -SuggestedFileName $ctx.SuggestedFileName
}
#endregion

#region ZIP extraction
function Expand-SafeZip {
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$DestinationRoot
    )

    if (-not (Test-Path -LiteralPath $ZipPath)) { throw "ZIP file does not exist." }
    if (-not (Test-Path -LiteralPath $DestinationRoot)) { [IO.Directory]::CreateDirectory($DestinationRoot) | Out-Null }

    $rootFull = [IO.Path]::GetFullPath((Join-Path $DestinationRoot "."))
    $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach ($entry in $archive.Entries) {
            $target = [IO.Path]::GetFullPath((Join-Path $DestinationRoot $entry.FullName))
            if (-not $target.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Blocked unsafe ZIP entry: $($entry.FullName)"
            }
            if ([string]::IsNullOrWhiteSpace($entry.Name)) {
                [IO.Directory]::CreateDirectory($target) | Out-Null
                continue
            }
            $parent = [IO.Path]::GetDirectoryName($target)
            if (-not (Test-Path -LiteralPath $parent)) { [IO.Directory]::CreateDirectory($parent) | Out-Null }
            if (Test-Path -LiteralPath $target) { throw "ZIP extraction would overwrite: $target" }
        }

        foreach ($entry in $archive.Entries) {
            if ([string]::IsNullOrWhiteSpace($entry.Name)) { continue }
            $target = [IO.Path]::GetFullPath((Join-Path $DestinationRoot $entry.FullName))
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $false)
        }
    } finally {
        $archive.Dispose()
    }
}
#endregion

#region Tool launch handling
function Invoke-ToolAction {
    param([object]$Tool)
    if ($null -eq $Tool) { return }

    switch ($Tool.ActionType) {
        "OfficialWebsite"     { Open-SafeUrl -Url $Tool.OfficialWebsite -AllowedDomains $Tool.AllowedDomains }
        "GitHubRepository"    { Open-SafeUrl -Url $Tool.GitHubRepository -AllowedDomains $Tool.AllowedDomains }
        "GitHubReleasePage"   { Open-SafeUrl -Url $Tool.GitHubReleasePage -AllowedDomains $Tool.AllowedDomains }
        "DirectDownload"      { Start-OfficialDownload -Tool $Tool -Url $Tool.DirectDownloadUrl -SuggestedFileName $Tool.DownloadFileName }
        "GitHubReleaseAsset"  { Start-GitHubReleaseAssetDownload -Tool $Tool }
        "LaunchDownloadedFile"{ Invoke-LaunchDownloadedTool -Tool $Tool }
        default               { Show-Notification "Unsupported action: $($Tool.ActionType)" }
    }
}

function Invoke-LaunchDownloadedTool {
    param([object]$Tool)

    if ($script:Settings.SafeMode) {
        Show-Notification "Safe mode blocks execution."
        return
    }

    $path = Get-TextValue $Tool.LocalPath
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) {
        Show-Notification "No downloaded file is available for $($Tool.Name)."
        return
    }

    $hashStatus = Test-FileHashForTool -Tool $Tool -Path $path
    $Tool.HashStatus = $hashStatus
    if ($hashStatus -eq "SHA-256 mismatch") {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        $Tool.LocalPath = ""
        $Tool.DownloadStatus = "Blocked by hash mismatch"
        Update-ToolDetail -Tool $Tool
        Show-Message -Text "SHA-256 mismatch. The file was removed and will not be launched." -Icon ([System.Windows.MessageBoxImage]::Error)
        return
    }

    $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
    $details = @(
        "Tool: $($Tool.Name)",
        "Maker: $($Tool.Author)",
        "Source: $(Get-TextValue $Tool.DirectDownloadUrl (Get-TextValue $Tool.GitHubReleasePage $Tool.OfficialWebsite))",
        "File: $path",
        "Type: $extension",
        "Hash: $hashStatus",
        "",
        "External code or files may be opened. Continue?"
    ) -join "`n"

    if ($script:Settings.ConfirmToolLaunch -and -not (Confirm-Action -Text $details -Title "Confirm tool launch")) { return }

    if ($Tool.RequiresAdministrator) {
        if (-not (Confirm-Action -Text "$($Tool.Name) is marked as requiring administrator rights. Elevate now?" -Title "Administrator rights required")) { return }
    }

    switch ($extension) {
        ".exe" {
            if ($Tool.RequiresAdministrator) { Start-Process -FilePath $path -Verb RunAs }
            else { Start-Process -FilePath $path }
        }
        ".msi" {
            $args = "/i `"$path`""
            if ($Tool.RequiresAdministrator) { Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Verb RunAs }
            else { Start-Process -FilePath "msiexec.exe" -ArgumentList $args }
        }
        ".ps1" {
            Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile","-File","`"$path`"")
        }
        ".bat" { Start-Process -FilePath "cmd.exe" -ArgumentList @("/k","`"$path`"") }
        ".cmd" { Start-Process -FilePath "cmd.exe" -ArgumentList @("/k","`"$path`"") }
        ".zip" {
            $psi = New-Object Diagnostics.ProcessStartInfo
            $psi.FileName = "explorer.exe"
            $psi.Arguments = "/select,`"$path`""
            [Diagnostics.Process]::Start($psi) | Out-Null
        }
        default {
            $psi = New-Object Diagnostics.ProcessStartInfo
            $psi.FileName = $path
            $psi.UseShellExecute = $true
            [Diagnostics.Process]::Start($psi) | Out-Null
        }
    }
}
#endregion

#region Command copy handling
function Copy-SelectedCommand {
    $command = $script:ListCommands.SelectedItem
    if ($null -eq $command) { return }
    try {
        [Windows.Clipboard]::SetText($command.Command)
        Show-Notification "Command copied"
    } catch {
        Show-Message -Text "Could not copy command: $($_.Exception.Message)" -Icon ([System.Windows.MessageBoxImage]::Warning)
    }
}

function Test-CommandSafeForExecution {
    param([string]$CommandText)
    $dangerous = @(
        "del ","erase ","rd ","rmdir ","format ","diskpart","bcdedit","reg delete","net user","net localgroup","sc delete",
        "Remove-Item","Invoke-Expression","iwr ","irm ","curl ","wget ","Set-ExecutionPolicy","Disable-","Stop-Service","Set-MpPreference"
    )
    foreach ($term in $dangerous) {
        if ($CommandText.IndexOf($term, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $false }
    }
    return $true
}

function Invoke-SelectedCommand {
    $command = $script:ListCommands.SelectedItem
    if ($null -eq $command) { return }
    if (-not $command.AllowExecution) {
        Show-Notification "This command is copy-only."
        return
    }
    if ($script:Settings.SafeMode) {
        Show-Notification "Safe mode blocks command execution."
        return
    }
    if (-not (Test-CommandSafeForExecution -CommandText $command.Command)) {
        Show-Message -Text "This command was blocked by the built-in safety filter." -Icon ([System.Windows.MessageBoxImage]::Warning)
        return
    }

    $message = @(
        "Command:",
        $command.Command,
        "",
        "Shell: $($command.Shell)",
        "Administrator: $(if ($command.RequiresAdministrator) { 'required' } else { 'not required' })",
        "",
        "Run in a visible terminal now?"
    ) -join "`n"

    if ($script:Settings.ConfirmCommandRun -and -not (Confirm-Action -Text $message -Title "Confirm command execution")) { return }

    if ($command.RequiresAdministrator -and -not (Confirm-Action -Text "This command requires administrator rights. Elevate now?" -Title "Administrator rights required")) { return }

    if ($command.Shell -eq "PowerShell") {
        $args = @("-NoProfile","-NoExit","-Command",$command.Command)
        if ($command.RequiresAdministrator) { Start-Process -FilePath "powershell.exe" -ArgumentList $args -Verb RunAs }
        else { Start-Process -FilePath "powershell.exe" -ArgumentList $args }
    } else {
        $args = @("/k", $command.Command)
        if ($command.RequiresAdministrator) { Start-Process -FilePath "cmd.exe" -ArgumentList $args -Verb RunAs }
        else { Start-Process -FilePath "cmd.exe" -ArgumentList $args }
    }
}
#endregion

#region Settings
function Apply-Theme {
    param([string]$Theme)
    if ($Theme -eq "Light") {
        Set-ResourceBrush "WindowBackgroundBrush" "#F4F6FA"
        Set-ResourceBrush "SidebarBrush" "#E9EDF5"
        Set-ResourceBrush "PanelBrush" "#FFFFFF"
        Set-ResourceBrush "CardBrush" "#F6F8FC"
        Set-ResourceBrush "CardHoverBrush" "#E9F3FF"
        Set-ResourceBrush "SelectedBrush" "#D9ECFF"
        Set-ResourceBrush "MutedBrush" "#596274"
        Set-ResourceBrush "TextBrush" "#111827"
        Set-ResourceBrush "LineBrush" "#CFD7E6"
    } else {
        Set-ResourceBrush "WindowBackgroundBrush" "#101116"
        Set-ResourceBrush "SidebarBrush" "#171922"
        Set-ResourceBrush "PanelBrush" "#1D202B"
        Set-ResourceBrush "CardBrush" "#252936"
        Set-ResourceBrush "CardHoverBrush" "#2C3344"
        Set-ResourceBrush "SelectedBrush" "#173A55"
        Set-ResourceBrush "MutedBrush" "#AEB6C8"
        Set-ResourceBrush "TextBrush" "#F6F7FB"
        Set-ResourceBrush "LineBrush" "#333A4D"
    }
}

function Update-SettingsFromUi {
    $script:Settings.AnimationsEnabled = [bool]$script:ChkAnimations.IsChecked
    $script:Settings.ConfirmToolLaunch = [bool]$script:ChkConfirmTools.IsChecked
    $script:Settings.ConfirmCommandRun = [bool]$script:ChkConfirmCommands.IsChecked
    $script:Settings.SafeMode = [bool]$script:ChkSafeMode.IsChecked
    $script:Settings.DownloadNotifications = [bool]$script:ChkDownloadNotifications.IsChecked
    $script:Settings.Theme = [string]$script:CmbTheme.SelectedItem
    Apply-Theme -Theme $script:Settings.Theme
}

function Choose-DownloadFolder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Choose a download folder for TeslaPro Tools"
    $dialog.SelectedPath = $script:Settings.DownloadRoot
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:Settings.DownloadRoot = $dialog.SelectedPath
        if (-not (Test-Path -LiteralPath $script:Settings.DownloadRoot)) { [IO.Directory]::CreateDirectory($script:Settings.DownloadRoot) | Out-Null }
        $script:TxtDownloadFolder.Text = $script:Settings.DownloadRoot
        Show-Notification "Download folder updated."
    }
}

function Open-DownloadFolder {
    if (-not (Test-Path -LiteralPath $script:Settings.DownloadRoot)) { [IO.Directory]::CreateDirectory($script:Settings.DownloadRoot) | Out-Null }
    Start-Process -FilePath $script:Settings.DownloadRoot
}
#endregion

#region Cleanup
function Cleanup-PartialDownloads {
    if (-not (Test-Path -LiteralPath $script:Settings.DownloadRoot)) { return 0 }
    $removed = 0
    Get-ChildItem -LiteralPath $script:Settings.DownloadRoot -Filter "*.part" -File -ErrorAction SilentlyContinue | ForEach-Object {
        if (Test-PathInsideRoot -Path $_.FullName -Root $script:Settings.DownloadRoot) {
            Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
            $removed++
        }
    }
    return $removed
}

function Test-HasActiveDownloads {
    foreach ($ctx in $script:DownloadContexts.Values) {
        if ($ctx.Status -eq "Active") { return $true }
    }
    return $false
}

function Stop-ApplicationWork {
    foreach ($timer in $script:Timers) {
        try { $timer.Stop() } catch { }
    }
    foreach ($worker in $script:DownloadWorkers.Values) {
        try {
            if ($worker.IsBusy -and $worker.WorkerSupportsCancellation) { $worker.CancelAsync() }
        } catch { }
    }
    [void](Cleanup-PartialDownloads)
}
#endregion

#region Application startup
function Wire-Events {
    $script:TitleBar.Add_MouseLeftButtonDown({
        param($sender, $e)
        if ($e.ClickCount -eq 2) {
            if ($script:Window.WindowState -eq [Windows.WindowState]::Maximized) { $script:Window.WindowState = [Windows.WindowState]::Normal }
            else { $script:Window.WindowState = [Windows.WindowState]::Maximized }
        } else {
            try { $script:Window.DragMove() } catch { }
        }
    })

    $script:BtnWindowMinimize.Add_Click({ $script:Window.WindowState = [Windows.WindowState]::Minimized })
    $script:BtnWindowClose.Add_Click({ $script:Window.Close() })

    $script:BtnNavHome.Add_Click({ Show-Page -PageName "PageHome" })
    $script:BtnNavTools.Add_Click({ Show-Page -PageName "PageTools" })
    $script:BtnNavCommands.Add_Click({ Show-Page -PageName "PageCommands" })
    $script:BtnNavDownloads.Add_Click({ Show-Page -PageName "PageDownloads" })
    $script:BtnNavInfo.Add_Click({ Show-Page -PageName "PageInfo" })
    $script:BtnNavSettings.Add_Click({ Show-Page -PageName "PageSettings" })
    $script:BtnNavExit.Add_Click({ $script:Window.Close() })
    $script:BtnHomeTools.Add_Click({ Show-Page -PageName "PageTools" })
    $script:BtnHomeCommands.Add_Click({ Show-Page -PageName "PageCommands" })
    $script:BtnToolsBackHome.Add_Click({ Show-Page -PageName "PageHome" })
    $script:BtnCommandsBackHome.Add_Click({ Show-Page -PageName "PageHome" })
    $script:BtnDownloadsBackHome.Add_Click({ Show-Page -PageName "PageHome" })
    $script:BtnSettingsBackHome.Add_Click({ Show-Page -PageName "PageHome" })

    $script:ToolSearchTimer = New-Object Windows.Threading.DispatcherTimer
    $script:ToolSearchTimer.Interval = [TimeSpan]::FromMilliseconds(220)
    $script:ToolSearchTimer.Add_Tick({ $this.Stop(); Refresh-ToolView })
    $script:Timers += $script:ToolSearchTimer
    $script:TxtToolSearch.Add_TextChanged({ $script:ToolSearchTimer.Stop(); $script:ToolSearchTimer.Start() })
    $script:CmbToolCategory.Add_SelectionChanged({ Refresh-ToolView })
    $script:CmbToolStatus.Add_SelectionChanged({ Refresh-ToolView })
    $script:CmbToolSort.Add_SelectionChanged({ Refresh-ToolView })
    $script:BtnToolClearFilters.Add_Click({ Clear-ToolFilters })
    $script:ListTools.Add_SelectionChanged({ Update-ToolDetail -Tool $script:ListTools.SelectedItem })
    $script:ListTools.Add_MouseDoubleClick({
        $tool = $script:ListTools.SelectedItem
        if ($null -ne $tool -and $tool.ActionType -in @("OfficialWebsite","GitHubRepository","GitHubReleasePage")) {
            Invoke-ToolAction -Tool $tool
        }
    })

    $script:BtnToolPrimaryAction.Add_Click({ Invoke-ToolAction -Tool $script:ListTools.SelectedItem })
    $script:BtnToolOpenWebsite.Add_Click({ $tool = $script:ListTools.SelectedItem; if ($null -ne $tool) { Open-SafeUrl -Url $tool.OfficialWebsite -AllowedDomains $tool.AllowedDomains } })
    $script:BtnToolOpenRepo.Add_Click({ $tool = $script:ListTools.SelectedItem; if ($null -ne $tool) { Open-SafeUrl -Url $tool.GitHubRepository -AllowedDomains $tool.AllowedDomains } })
    $script:BtnToolOpenReleases.Add_Click({ $tool = $script:ListTools.SelectedItem; if ($null -ne $tool) { Open-SafeUrl -Url $tool.GitHubReleasePage -AllowedDomains $tool.AllowedDomains } })
    $script:BtnToolLaunchDownloaded.Add_Click({ Invoke-LaunchDownloadedTool -Tool $script:ListTools.SelectedItem })

    $script:CommandSearchTimer = New-Object Windows.Threading.DispatcherTimer
    $script:CommandSearchTimer.Interval = [TimeSpan]::FromMilliseconds(220)
    $script:CommandSearchTimer.Add_Tick({ $this.Stop(); Refresh-CommandView })
    $script:Timers += $script:CommandSearchTimer
    $script:TxtCommandSearch.Add_TextChanged({ $script:CommandSearchTimer.Stop(); $script:CommandSearchTimer.Start() })
    $script:CmbCommandCategory.Add_SelectionChanged({ Refresh-CommandView })
    $script:CmbCommandShell.Add_SelectionChanged({ Refresh-CommandView })
    $script:CmbCommandSort.Add_SelectionChanged({ Refresh-CommandView })
    $script:BtnCommandClearFilters.Add_Click({ Clear-CommandFilters })
    $script:ListCommands.Add_SelectionChanged({ Update-CommandDetail -Command $script:ListCommands.SelectedItem })
    $script:BtnCommandCopy.Add_Click({ Copy-SelectedCommand })
    $script:BtnCommandRun.Add_Click({ Invoke-SelectedCommand })

    $script:ListDownloads.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
        param($sender, $e)
        $source = $e.OriginalSource
        while ($null -ne $source -and -not ($source -is [System.Windows.Controls.Button])) {
            $source = [Windows.Media.VisualTreeHelper]::GetParent($source)
        }
        if ($null -eq $source) { return }
        $download = $source.DataContext
        switch ($source.Name) {
            "BtnDownloadCancel" { Cancel-DownloadItem -Download $download; $e.Handled = $true }
            "BtnDownloadRetry"  { Retry-DownloadItem -Download $download; $e.Handled = $true }
            "BtnDownloadOpen"   {
                if ($null -ne $download.Tool) {
                    $download.Tool.LocalPath = $download.FilePath
                    Invoke-LaunchDownloadedTool -Tool $download.Tool
                }
                $e.Handled = $true
            }
        }
    })

    $script:BtnOpenDownloadFolder.Add_Click({ Open-DownloadFolder })
    $script:BtnSettingsOpenDownloadFolder.Add_Click({ Open-DownloadFolder })
    $script:BtnChooseDownloadFolder.Add_Click({ Choose-DownloadFolder })
    $script:BtnCleanupPartFiles.Add_Click({
        $removed = Cleanup-PartialDownloads
        Show-Notification "Removed $removed temporary download file(s)."
    })

    foreach ($checkbox in @($script:ChkAnimations,$script:ChkConfirmTools,$script:ChkConfirmCommands,$script:ChkSafeMode,$script:ChkDownloadNotifications)) {
        $checkbox.Add_Click({ Update-SettingsFromUi })
    }
    $script:CmbTheme.Add_SelectionChanged({ Update-SettingsFromUi })

    $script:BtnInfoDiscord.Add_Click({
        Show-Message -Text "No Discord invite URL is embedded in this one-file build. Open the official TeslaPro Discord invite manually if you have it."
    })
    $script:BtnInfoWebsite.Add_Click({
        Show-Message -Text "No official TeslaPro website URL is embedded in this one-file build."
    })

    $script:Window.Add_Closing({
        param($sender, $e)
        if (Test-HasActiveDownloads) {
            $close = Confirm-Action -Text "Downloads are still active. Cancel downloads and exit?" -Title "Active downloads"
            if (-not $close) {
                $e.Cancel = $true
                return
            }
        }
        Stop-ApplicationWork
    })
}

function Initialize-Application {
    Initialize-Window
    $script:CmbTheme.ItemsSource = @("Dark","Light")
    $script:CmbTheme.SelectedItem = $script:Settings.Theme
    $script:TxtDownloadFolder.Text = $script:Settings.DownloadRoot
    Update-HomeStats
    Initialize-ToolBinding
    Initialize-CommandBinding
    $script:ListDownloads.ItemsSource = $script:DownloadsCollection
    Wire-Events
    Show-Page -PageName "PageHome"

    $welcomeTimer = New-Object Windows.Threading.DispatcherTimer
    $welcomeTimer.Interval = [TimeSpan]::FromMilliseconds(720)
    $welcomeTimer.Add_Tick({ $this.Stop(); Hide-WelcomeOverlay })
    $script:Timers += $welcomeTimer
    $welcomeTimer.Start()
}

function Invoke-SelfTest {
    Initialize-Application

    $requiredControls = @("BtnHomeTools","BtnHomeCommands","ListTools","ListCommands","ListDownloads","BtnToolPrimaryAction","BtnCommandCopy","BtnOpenDownloadFolder")
    foreach ($name in $requiredControls) {
        if ($null -eq (Get-Variable -Name $name -Scope Script -ValueOnly)) { throw "Self-test missing control: $name" }
    }

    if ($script:Tools.Count -lt 10) { throw "Self-test expected at least 10 real tool definitions." }
    if ($script:Commands.Count -lt 10) { throw "Self-test expected at least 10 command definitions." }

    foreach ($tool in $script:Tools) {
        foreach ($prop in @("Id","Name","Author","Description","Category","ActionType","AllowedDomains","Credits")) {
            if ($null -eq $tool.PSObject.Properties[$prop]) { throw "Tool '$($tool.Name)' is missing property '$prop'." }
        }
        if ($tool.ActionType -in @("OfficialWebsite","DirectDownload") -and [string]::IsNullOrWhiteSpace($tool.OfficialWebsite) -and [string]::IsNullOrWhiteSpace($tool.DirectDownloadUrl)) {
            throw "Tool '$($tool.Name)' has no official URL."
        }
    }

    $stress = New-Object 'System.Collections.ObjectModel.ObservableCollection[object]'
    for ($i = 0; $i -lt 140; $i++) {
        [void]$stress.Add($script:Tools[$i % $script:Tools.Count])
    }
    $stressView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($stress)
    $stressView.Filter = [Predicate[object]]{ param($item) $null -ne $item }
    $stressView.SortDescriptions.Add([System.ComponentModel.SortDescription]::new("Name", [System.ComponentModel.ListSortDirection]::Ascending))
    $stressView.Refresh()
    $stressCount = 0
    foreach ($item in $stressView) { $stressCount++ }
    if ($stressCount -ne 140) { throw "Virtualized stress view returned $stressCount items." }

    $script:ListTools.SelectedItem = $script:Tools[0]
    Update-ToolDetail -Tool $script:Tools[0]
    if ($script:ToolDetailContent.Visibility -ne [Windows.Visibility]::Visible -or [string]::IsNullOrWhiteSpace($script:TxtToolName.Text)) {
        throw "Tool detail panel did not populate."
    }

    $script:TxtToolSearch.Text = "__no_such_tool__"
    Refresh-ToolView
    $filteredToolCount = 0
    foreach ($item in $script:ToolsView) { $filteredToolCount++ }
    if ($filteredToolCount -ne 0 -or $script:TxtToolNoResults.Visibility -ne [Windows.Visibility]::Visible) {
        throw "Tool search empty-state failed."
    }

    Clear-ToolFilters
    $script:CmbToolCategory.SelectedItem = $script:Tools[0].Category
    Refresh-ToolView
    $categoryCount = 0
    foreach ($item in $script:ToolsView) { $categoryCount++ }
    if ($categoryCount -lt 1) { throw "Tool category filter failed." }
    Clear-ToolFilters

    $script:ListCommands.SelectedItem = $script:Commands[0]
    Update-CommandDetail -Command $script:Commands[0]
    if ($script:CommandDetailContent.Visibility -ne [Windows.Visibility]::Visible -or [string]::IsNullOrWhiteSpace($script:TxtCommandFull.Text)) {
        throw "Command detail panel did not populate."
    }

    $script:TxtCommandSearch.Text = "__no_such_command__"
    Refresh-CommandView
    $filteredCommandCount = 0
    foreach ($item in $script:CommandsView) { $filteredCommandCount++ }
    if ($filteredCommandCount -ne 0 -or $script:TxtCommandNoResults.Visibility -ne [Windows.Visibility]::Visible) {
        throw "Command search empty-state failed."
    }

    Clear-CommandFilters
    Show-Page -PageName "PageTools"
    Show-Page -PageName "PageCommands"
    Show-Page -PageName "PageDownloads"
    Show-Page -PageName "PageSettings"
    Show-Page -PageName "PageHome"
    Stop-ApplicationWork

    "SELFTEST OK: XAML loaded, controls mapped, views/filtering/sorting initialized, 140-item stress view passed."
}

if ($SelfTest) {
    Invoke-SelfTest
    return
}

Initialize-Application
[void]$script:Window.ShowDialog()
#endregion
