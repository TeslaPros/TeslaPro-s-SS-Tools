
<# =====================================================================
   TeslaProTools.ps1  (v4.2)
   One‑file PowerShell/WPF launcher
   Generated: 2026-06-20 09:21:37
   ===================================================================== #>

#region Metadata and requirements
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Relaunch in STA if needed
if ([Threading.Thread]::CurrentThread.ApartmentState -ne "STA") {{
    Write-Verbose "Restarting in STA mode..."
    $psi = [Diagnostics.ProcessStartInfo]::new("powershell.exe",
        "-NoProfile -Sta -ExecutionPolicy Bypass -File `"$PSCommandPath`"")
    [Diagnostics.Process]::Start($psi) | Out-Null
    exit
}}
#endregion

#region Assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
#endregion

#region Application configuration
$AppVersion = "0.9.2-beta"
$DownloadRoot = Join-Path $env:LOCALAPPDATA "TeslaProTools\Downloads"
if (-not (Test-Path $DownloadRoot)) {{ [IO.Directory]::CreateDirectory($DownloadRoot) | Out-Null }}
#endregion

#region Application state
$script:Settings = [PSCustomObject]@{{ AnimationsEnabled = $true }}
#endregion

#region Tool definitions
$script:Tools = @(
    [PSCustomObject]@{{
        Id="7zip"; Name="7-Zip"; Author="Igor Pavlov";
        Description="Bestandsarchiver met hoge compressie";
        Version="24.05"; Category="Utilities";
        OfficialWebsite="https://www.7-zip.org/";
        ActionType="OfficialWebsite";
        DirectDownloadUrl="https://www.7-zip.org/a/7z2405-x64.exe";
        AllowedDomains=@("www.7-zip.org","7-zip.org");
        AllowedExtensions=@(".exe"); Sha256=""; RequiresAdministrator=$false;
    }},
    [PSCustomObject]@{{
        Id="winscp"; Name="WinSCP"; Author="Martin Prikryl";
        Description="SFTP/FTP/SCP client";
        Version="6.3.3"; Category="Utilities";
        GitHubRepository="https://github.com/winscp/winscp";
        ActionType="GitHubRepository"; DirectDownloadUrl="";
        AllowedDomains=@("github.com","winscp.net");
        AllowedExtensions=@(".exe",".msi");
        Sha256=""; RequiresAdministrator=$false;
    }}
)
#endregion

#region Command definitions
$script:Commands = @(
    [PSCustomObject]@{{
        Id="ipconfig-all"; Name="Volledige netwerkconfiguratie";
        Category="Netwerk"; Shell="CMD"; Command="ipconfig /all";
        Description="Toont uitgebreide info over alle netwerkadapters.";
        RequiresAdministrator=$false; AllowExecution=$false;
    }},
    [PSCustomObject]@{{
        Id="open-ports"; Name="Open poorten weergeven";
        Category="Netwerk"; Shell="CMD";
        Command='netstat -ano | find "LISTEN"';
        Description="Welke poorten luisteren er lokaal?";
        RequiresAdministrator=$false; AllowExecution=$false;
    }}
)
#endregion

#region Embedded XAML
$xaml = @"
<Window xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
        xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
        Title=""TeslaPro Tools"" Height=""640"" Width=""1000"" ResizeMode=""CanMinimize""
        Background=""#1e1e1e"" Foreground=""White"" WindowStartupLocation=""CenterScreen"">
    <Window.Resources>
        <Style x:Key=""PrimaryButton"" TargetType=""Button"">
            <Setter Property=""Background"" Value=""#0078d4""/>
            <Setter Property=""Foreground"" Value=""White""/>
            <Setter Property=""Padding"" Value=""10 6""/>
            <Setter Property=""Margin"" Value=""4""/>
            <Setter Property=""Cursor"" Value=""Hand""/>
            <Setter Property=""BorderThickness"" Value=""0""/>
            <Setter Property=""FontSize"" Value=""15""/>
            <Setter Property=""Template"">
                <Setter.Value>
                    <ControlTemplate TargetType=""Button"">
                        <Border CornerRadius=""8"" Background=""{{TemplateBinding Background}}"">
                           <ContentPresenter HorizontalAlignment=""Center"" VerticalAlignment=""Center""/>
                        </Border>
                        <ControlTemplate.Triggers>
                           <Trigger Property=""IsMouseOver"" Value=""True"">
                              <Setter Property=""Background"" Value=""#0a84ff""/>
                           </Trigger>
                           <Trigger Property=""IsPressed"" Value=""True"">
                              <Setter Property=""Background"" Value=""#005a9e""/>
                           </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid>
        <!-- Sidebar -->
        <StackPanel x:Name=""Sidebar"" Width=""220"" Background=""#252526"" VerticalAlignment=""Stretch"">
            <Button x:Name=""BtnNavHome"" Content=""Home"" Style=""{{StaticResource PrimaryButton}}""/>
            <Button x:Name=""BtnNavTools"" Content=""Tools"" Style=""{{StaticResource PrimaryButton}}""/>
            <Button x:Name=""BtnNavCmd"" Content=""CMD Commands"" Style=""{{StaticResource PrimaryButton}}""/>
            <Button x:Name=""BtnNavDownloads"" Content=""Downloads"" Style=""{{StaticResource PrimaryButton}}""/>
            <Button x:Name=""BtnNavInfo"" Content=""Info"" Style=""{{StaticResource PrimaryButton}}""/>
            <Button x:Name=""BtnNavSettings"" Content=""Settings"" Style=""{{StaticResource PrimaryButton}}""/>
            <Button x:Name=""BtnNavExit"" Content=""Exit"" Style=""{{StaticResource PrimaryButton}}""/>
        </StackPanel>

        <!-- Page host -->
        <Grid x:Name=""PageHost"" Margin=""220,0,0,0"">
            <!-- Home -->
            <Grid x:Name=""PageHome"">
                <StackPanel HorizontalAlignment=""Center"" VerticalAlignment=""Center"" xmlns:sys=""clr-namespace:System;assembly=mscorlib"">
                    <TextBlock Text=""Welcome to TeslaPro Tools"" FontSize=""30"" FontWeight=""Bold"" TextAlignment=""Center""/>
                    <StackPanel Orientation=""Horizontal"" HorizontalAlignment=""Center"" Margin=""0,18,0,0"">
                        <Button x:Name=""BtnHomeTools"" Content=""Tools"" Width=""200"" Height=""90"" Style=""{{StaticResource PrimaryButton}}""/>
                        <Button x:Name=""BtnHomeCmd"" Content=""CMD Commands"" Width=""200"" Height=""90"" Style=""{{StaticResource PrimaryButton}}"" Margin=""30,0,0,0""/>
                    </StackPanel>
                </StackPanel>
            </Grid>

            <!-- Tools -->
            <Grid x:Name=""PageTools"" Visibility=""Collapsed"">
                <Grid.RowDefinitions>
                    <RowDefinition Height=""Auto""/><RowDefinition/>
                </Grid.RowDefinitions>
                <StackPanel Orientation=""Horizontal"" Margin=""10"">
                    <TextBlock Text=""Tools"" FontSize=""24"" FontWeight=""Bold"" VerticalAlignment=""Center""/>
                    <TextBox x:Name=""TxtSearchTools"" Width=""220"" Margin=""20 0"" VerticalAlignment=""Center""
                             Background=""#333"" Foreground=""White""/>
                </StackPanel>
                <ScrollViewer Grid.Row=""1"" Margin=""10"">
                    <StackPanel x:Name=""ToolsPanel""/>
                </ScrollViewer>
            </Grid>

            <!-- CMD Commands -->
            <Grid x:Name=""PageCmd"" Visibility=""Collapsed"">
                <Grid.RowDefinitions>
                    <RowDefinition Height=""Auto""/><RowDefinition/>
                </Grid.RowDefinitions>
                <StackPanel Orientation=""Horizontal"" Margin=""10"">
                    <TextBlock Text=""CMD Commands"" FontSize=""24"" FontWeight=""Bold"" VerticalAlignment=""Center""/>
                    <TextBox x:Name=""TxtSearchCmd"" Width=""220"" Margin=""20 0"" VerticalAlignment=""Center""
                             Background=""#333"" Foreground=""White""/>
                </StackPanel>
                <ScrollViewer Grid.Row=""1"" Margin=""10"">
                    <StackPanel x:Name=""CmdPanel""/>
                </ScrollViewer>
            </Grid>

            <!-- Downloads -->
            <Grid x:Name=""PageDownloads"" Visibility=""Collapsed"">
                <TextBlock Text=""Downloads (binnenkort)"" HorizontalAlignment=""Center"" VerticalAlignment=""Center""/>
            </Grid>

            <!-- Info -->
            <Grid x:Name=""PageInfo"" Visibility=""Collapsed"">
                <StackPanel HorizontalAlignment=""Center"" VerticalAlignment=""Center"" Width=""450"" TextAlignment=""Center"" Spacing=""12"">
                    <TextBlock Text=""TeslaPro Tools"" FontSize=""28"" FontWeight=""Bold""/>
                    <TextBlock Text=""Versie $AppVersion"" FontSize=""14""/>
                    <TextBlock TextWrapping=""Wrap"">
                        TeslaPro Tools is een onafhankelijke launcher ...
                    </TextBlock>
                </StackPanel>
            </Grid>

            <!-- Settings -->
            <Grid x:Name=""PageSettings"" Visibility=""Collapsed"">
                <StackPanel Margin=""30"" Spacing=""14"">
                    <TextBlock Text=""Instellingen"" FontSize=""24"" FontWeight=""Bold""/>
                    <CheckBox x:Name=""ChkAnim"" Content=""Animaties inschakelen"" IsChecked=""True""/>
                </StackPanel>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@
#endregion

#region Load and helper functions
$reader = [System.Xml.XmlReader]::Create([IO.StringReader]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

function Show-Page {{
    param($name)
    foreach($ch in $window.PageHost.Children) {{
        $ch.Visibility = if($ch.Name -eq $name) {{ "Visible" }} else {{ "Collapsed" }}
    }}
}}
#endregion

#region Clipboard helper
function Set-ClipboardText {{
    param([string]$text)
    Add-Type -AssemblyName PresentationCore
    [Windows.Clipboard]::SetText($text)
}}
#endregion

#region Download helper
function Test-AllowedDownload {{
    param($Url,$AllowedDomains,$AllowedExt)
    try {{
        $uri=[Uri]$Url
        if($uri.Scheme -ne "https"){{throw}}
        if(-not ($AllowedDomains -contains $uri.Host)){{throw}}
        if(-not ($AllowedExt -contains [IO.Path]::GetExtension($uri.AbsolutePath))){{throw}}
        return $true
    }}catch{{[Windows.MessageBox]::Show("Download geblokkeerd");return $false}}
}}
function Start-Download {{
    param($Tool)
    if(-not (Test-AllowedDownload $Tool.DirectDownloadUrl $Tool.AllowedDomains $Tool.AllowedExtensions)){{return}}
    $dest=Join-Path $DownloadRoot ([IO.Path]::GetFileName($Tool.DirectDownloadUrl))
    try{{(New-Object Net.WebClient).DownloadFile($Tool.DirectDownloadUrl,$dest);[Windows.MessageBox]::Show("Gedownload")}}
    catch{{[Windows.MessageBox]::Show("Fout: $_")}}
}}
#endregion

#region List rendering functions
function Render-Tools {{
    $p=$window.ToolsPanel; $p.Children.Clear()
    $q=$window.TxtSearchTools.Text.ToLower()
    foreach($t in $script:Tools|Where-Object{{ $q -eq "" -or $_.Name.ToLower().Contains($q) -or $_.Description.ToLower().Contains($q)}}){{
        $b=[Windows.Controls.Border]@{{Background="#333";CornerRadius=6;Margin="4";Padding="6"}}
        $s=[Windows.Controls.StackPanel]@{{}}
        $ttl=[Windows.Controls.TextBlock]@{{Text=$t.Name;FontSize=16;FontWeight="Bold"}}
        $desc=[Windows.Controls.TextBlock]@{{Text=$t.Description;FontSize=12;TextWrapping="Wrap"}}
        $btn=[Windows.Controls.Button]@{{Content="Open";Width=90;Style=$window.Resources.PrimaryButton;Tag=$t}}
        $btn.Add_Click{{Invoke-ToolAction $this.Tag}}
        $s.Children.Add($ttl);$s.Children.Add($desc);$s.Children.Add($btn)
        $b.Child=$s; $p.Children.Add($b)
    }}
}}
function Render-Cmd {{
    $p=$window.CmdPanel; $p.Children.Clear()
    $q=$window.TxtSearchCmd.Text.ToLower()
    foreach($c in $script:Commands|Where-Object{{ $q -eq "" -or $_.Name.ToLower().Contains($q) -or $_.Command.ToLower().Contains($q)}}){{
        $b=[Windows.Controls.Border]@{{Background="#333";CornerRadius=6;Margin="4";Padding="6"}}
        $s=[Windows.Controls.StackPanel]@{{}}
        $ttl=[Windows.Controls.TextBlock]@{{Text=$c.Name;FontSize=16;FontWeight="Bold"}}
        $cmd=[Windows.Controls.TextBlock]@{{Text=$c.Command;FontFamily="Consolas";Background="#222";Foreground="White";Padding="4"}}
        $btn=[Windows.Controls.Button]@{{Content="Kopiëren";Width=90;Style=$window.Resources.PrimaryButton;Tag=$c}}
        $btn.Add_Click{{Set-ClipboardText $this.Tag.Command;[Windows.MessageBox]::Show("Gekopieerd")}}
        $s.Children.Add($ttl);$s.Children.Add($cmd);$s.Children.Add($btn)
        $b.Child=$s; $p.Children.Add($b)
    }}
}}
#endregion

#region Actions
function Invoke-ToolAction($Tool){{
    switch($Tool.ActionType){{
        "OfficialWebsite"{{Start-Process $Tool.OfficialWebsite}}
        "GitHubRepository"{{Start-Process $Tool.GitHubRepository}}
        "DirectDownload"{{Start-Download $Tool}}
        default{{[Windows.MessageBox]::Show("Niet geïmplementeerd")}}
    }}
}}
#endregion

#region Navigation button hookup
$map=@{{BtnNavHome="PageHome";BtnNavTools="PageTools";BtnNavCmd="PageCmd";BtnNavDownloads="PageDownloads";BtnNavInfo="PageInfo";BtnNavSettings="PageSettings"}}
foreach($k in $map.Keys){{
    $window.FindName($k).Add_Click{{param($s,$e)
        switch($s.Name){{
            "BtnNavTools"{{Render-Tools}}
            "BtnNavCmd"  {{Render-Cmd}}
        }}
        Show-Page $($map[$s.Name])
    }}
}}
$window.BtnNavExit.Add_Click{{$window.Close()}}
$window.BtnHomeTools.Add_Click{{Render-Tools;Show-Page "PageTools"}}
$window.BtnHomeCmd.Add_Click  {{Render-Cmd;Show-Page "PageCmd"}}
#endregion

#region Search text events
Register-ObjectEvent $window.TxtSearchTools TextChanged -Action {{Render-Tools}}
Register-ObjectEvent $window.TxtSearchCmd   TextChanged -Action {{Render-Cmd}}
#endregion

#region Exit confirm
$window.Add_Closing{{param($sender,$e)
    $res=[Windows.MessageBox]::Show("Afsluiten?","TeslaPro Tools",[Windows.MessageBoxButton]::YesNo)
    if($res -ne [Windows.MessageBoxResult]::Yes){{$e.Cancel=$true}}
}}
#endregion

# Initial page
Show-Page "PageHome"
$window.ShowDialog() | Out-Null
