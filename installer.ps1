<#
    Tesla Launcher - Discord Code Protected Template
    Filename: installer.ps1

    IMPORTANT:
    - Reset the Discord bot token you pasted publicly.
    - Put your NEW token in $discordBotToken below.
    - This script sends a 4-letter code to your Discord channel.
    - The launcher only opens after the correct code is entered.

    This safe template does NOT run hidden remote PowerShell commands.
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName Microsoft.VisualBasic

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "3.3"

# Discord login settings
# Replace this locally with your NEW reset bot token.
$discordBotToken  = "MTUwMTk4MTkxODc3Mjg1NDg4NQ.Gocs5Y.xY7MSIlpoqMcYV7tSDiC3YwxzQVQWs73zPSodE"
$discordChannelId = "1501503898211324109"
$loginCode        = ""

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Tesla Launcher"
    Width="860"
    Height="560"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    FontFamily="Segoe UI">

    <Window.Resources>
        <LinearGradientBrush x:Key="WindowBackground" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#05070B" Offset="0"/>
            <GradientStop Color="#09111B" Offset="0.48"/>
            <GradientStop Color="#071B27" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="PrimaryButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#39E5FF" Offset="0"/>
            <GradientStop Color="#00A8D8" Offset="1"/>
        </LinearGradientBrush>

        <Style x:Key="ActionButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="48"/>
            <Setter Property="Margin" Value="0,0,0,12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Background" Value="#182332"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Root" Background="{TemplateBinding Background}" CornerRadius="15" BorderBrush="#203040" BorderThickness="1">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Root" Property="BorderBrush" Value="#35D9FF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Root" Property="Opacity" Value="0.75"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Root" Property="Opacity" Value="0.42"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid>
        <Border CornerRadius="24" Background="{StaticResource WindowBackground}" BorderBrush="#1D2938" BorderThickness="1" Padding="22">
            <Border.Effect>
                <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.45"/>
            </Border.Effect>

            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="56"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Grid Grid.Row="0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel>
                        <TextBlock Text="Tesla Launcher" FontSize="24" FontWeight="SemiBold" Foreground="White"/>
                        <TextBlock Text="Discord protected installer" FontSize="12" Foreground="#8FA4B8" Margin="0,3,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal">
                        <Button x:Name="MinButton" Content="—" Width="36" Height="36" Margin="0,0,8,0" Style="{StaticResource ActionButtonStyle}"/>
                        <Button x:Name="CloseButton" Content="✕" Width="36" Height="36" Style="{StaticResource ActionButtonStyle}" Background="#1F2330"/>
                    </StackPanel>
                </Grid>

                <Grid Grid.Row="1" Margin="0,18,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="250"/>
                        <ColumnDefinition Width="18"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Border Grid.Column="0" CornerRadius="20" Background="#0B1118" BorderBrush="#192537" BorderThickness="1" Padding="18">
                        <StackPanel>
                            <TextBlock Text="Control Center" FontSize="21" FontWeight="SemiBold" Foreground="White" Margin="0,0,0,14"/>
                            <Button x:Name="InstallButton" Content="Install / Update Tools" Style="{StaticResource ActionButtonStyle}" Background="{StaticResource PrimaryButtonBrush}"/>
                            <Button x:Name="DeleteButton" Content="Remove Installed Tools" Style="{StaticResource ActionButtonStyle}" Background="#3A2028"/>
                            <Button x:Name="OpenFolderButton" Content="Open Install Folder" Style="{StaticResource ActionButtonStyle}"/>
                            <Button x:Name="ExitButton" Content="Exit Launcher" Style="{StaticResource ActionButtonStyle}"/>

                            <Border Margin="0,20,0,0" CornerRadius="16" Background="#0A1018" BorderBrush="#1C2E40" BorderThickness="1" Padding="13">
                                <StackPanel>
                                    <TextBlock Text="Install Path" Foreground="#7890A6" FontSize="12"/>
                                    <TextBlock x:Name="LocationText" TextWrapping="Wrap" Foreground="White" FontSize="12" Margin="0,7,0,0"/>
                                    <TextBlock x:Name="VersionText" Foreground="#74E8FF" FontSize="14" FontWeight="Bold" Margin="0,12,0,0"/>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </Border>

                    <Border Grid.Column="2" CornerRadius="20" Background="#101824" BorderBrush="#1C2A3C" BorderThickness="1" Padding="20">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="14"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="14"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>

                            <StackPanel>
                                <TextBlock x:Name="StatusText" Text="Ready" FontSize="30" FontWeight="SemiBold" Foreground="White"/>
                                <TextBlock x:Name="SubStatusText" Text="Everything is ready." FontSize="14" Foreground="#9DB1C4" Margin="0,8,0,0"/>
                            </StackPanel>

                            <Grid Grid.Row="2">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="14"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="14"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <Border Grid.Column="0" CornerRadius="16" Background="#0B1017" BorderBrush="#1B2837" BorderThickness="1" Padding="14">
                                    <StackPanel>
                                        <TextBlock Text="Step" Foreground="#7C93A8"/>
                                        <TextBlock x:Name="StepText" Text="Waiting" Foreground="White" FontSize="19" FontWeight="SemiBold" Margin="0,6,0,0"/>
                                    </StackPanel>
                                </Border>

                                <Border Grid.Column="2" CornerRadius="16" Background="#0B1017" BorderBrush="#1B2837" BorderThickness="1" Padding="14">
                                    <StackPanel>
                                        <TextBlock Text="Progress" Foreground="#7C93A8"/>
                                        <TextBlock x:Name="ProgressLabel" Text="0%" Foreground="White" FontSize="19" FontWeight="SemiBold" Margin="0,6,0,0"/>
                                    </StackPanel>
                                </Border>

                                <Border Grid.Column="4" CornerRadius="16" Background="#0B1017" BorderBrush="#1B2837" BorderThickness="1" Padding="14">
                                    <StackPanel>
                                        <TextBlock Text="Tools" Foreground="#7C93A8"/>
                                        <TextBlock x:Name="ToolCountText" Text="0" Foreground="White" FontSize="19" FontWeight="SemiBold" Margin="0,6,0,0"/>
                                    </StackPanel>
                                </Border>
                            </Grid>

                            <ProgressBar Grid.Row="4" x:Name="MainProgressBar" Height="12" VerticalAlignment="Top" Minimum="0" Maximum="100" Value="0" Foreground="#22D6FF" Margin="0,0,0,0"/>

                            <Border Grid.Row="4" Margin="0,26,0,0" CornerRadius="18" Background="#091018" BorderBrush="#1A2B3C" BorderThickness="1" Padding="14">
                                <TextBox x:Name="ActivityBox" Background="Transparent" Foreground="#D8E8F5" BorderThickness="0" FontFamily="Consolas" FontSize="13" IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" AcceptsReturn="True"/>
                            </Border>
                        </Grid>
                    </Border>
                </Grid>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$InstallButton    = $window.FindName("InstallButton")
$DeleteButton     = $window.FindName("DeleteButton")
$OpenFolderButton = $window.FindName("OpenFolderButton")
$ExitButton       = $window.FindName("ExitButton")
$CloseButton      = $window.FindName("CloseButton")
$MinButton        = $window.FindName("MinButton")
$StatusText       = $window.FindName("StatusText")
$SubStatusText    = $window.FindName("SubStatusText")
$StepText         = $window.FindName("StepText")
$ProgressLabel    = $window.FindName("ProgressLabel")
$ToolCountText    = $window.FindName("ToolCountText")
$MainProgressBar  = $window.FindName("MainProgressBar")
$LocationText     = $window.FindName("LocationText")
$VersionText      = $window.FindName("VersionText")
$ActivityBox      = $window.FindName("ActivityBox")

$LocationText.Text = $dest
$VersionText.Text  = "Version $version"

function Refresh-Ui {
    $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

function Test-IsAdministrator {
    try {
        $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

function Write-Activity {
    param([string]$Text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $ActivityBox.AppendText("[$timestamp] $Text`r`n")
    $ActivityBox.ScrollToEnd()
    Refresh-Ui
}

function Set-UiState {
    param(
        [string]$Title,
        [string]$SubTitle,
        [string]$Step,
        [double]$Progress = 0
    )

    $StatusText.Text = $Title
    $SubStatusText.Text = $SubTitle
    $StepText.Text = $Step
    $ProgressLabel.Text = ("{0}%" -f [int]$Progress)
    $MainProgressBar.Value = [Math]::Max(0, [Math]::Min(100, $Progress))
    Refresh-Ui
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $InstallButton.IsEnabled = $Enabled
    $DeleteButton.IsEnabled = $Enabled
    $OpenFolderButton.IsEnabled = $Enabled
    $ExitButton.IsEnabled = $Enabled
    Refresh-Ui
}

function Show-AppMessage {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")]
        [string]$Type = "Info"
    )

    $icon = switch ($Type) {
        "Success" { [System.Windows.MessageBoxImage]::Information }
        "Warning" { [System.Windows.MessageBoxImage]::Warning }
        "Error"   { [System.Windows.MessageBoxImage]::Error }
        default   { [System.Windows.MessageBoxImage]::Information }
    }

    [System.Windows.MessageBox]::Show($Message, $Title, [System.Windows.MessageBoxButton]::OK, $icon) | Out-Null
}

function New-LoginCode {
    $letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $code = ""
    for ($i = 0; $i -lt 4; $i++) {
        $code += $letters[(Get-Random -Minimum 0 -Maximum $letters.Length)]
    }
    return $code
}

function Send-DiscordMessage {
    param([string]$Message)

    if ($discordBotToken -eq "ZET_HIER_JE_NIEUWE_BOT_TOKEN" -or [string]::IsNullOrWhiteSpace($discordBotToken)) {
        throw "Vul eerst je nieuwe Discord bot-token in bij `$discordBotToken."
    }

    $uri = "https://discord.com/api/v10/channels/$discordChannelId/messages"
    $headers = @{
        "Authorization" = "Bot $discordBotToken"
        "Content-Type"  = "application/json"
    }
    $body = @{ content = $Message } | ConvertTo-Json

    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body | Out-Null
}

function Require-DiscordCode {
    try {
        $script:loginCode = New-LoginCode

        $msg = @"
Tesla Launcher login code:

Code: **$script:loginCode**
User: `$env:USERNAME`
PC: `$env:COMPUTERNAME`

This code expires when the launcher closes.
"@

        Send-DiscordMessage -Message $msg

        $enteredCode = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Enter the 4-letter code that was sent to Discord:",
            "Tesla Launcher Login",
            ""
        )

        if ([string]::IsNullOrWhiteSpace($enteredCode)) {
            Show-AppMessage "Access Denied" "No code was entered." "Error"
            return $false
        }

        if ($enteredCode.ToUpper() -eq $script:loginCode) {
            Show-AppMessage "Access Granted" "Correct Discord code." "Success"
            return $true
        }

        Show-AppMessage "Access Denied" "Wrong Discord code." "Error"
        return $false
    }
    catch {
        $message = if ($_.Exception.Message) { $_.Exception.Message } else { "Could not send Discord code." }
        Show-AppMessage "Discord Error" $message "Error"
        return $false
    }
}

function Update-ToolCount {
    try {
        if (Test-Path $dest) {
            $tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe -ErrorAction SilentlyContinue
            $ToolCountText.Text = (($tools | Measure-Object).Count).ToString()
        }
        else { $ToolCountText.Text = "0" }
    }
    catch { $ToolCountText.Text = "0" }
}

function Safe-RemovePath {
    param([string]$Path)
    if (!(Test-Path $Path)) { return }
    Remove-Item $Path -Recurse -Force -ErrorAction Stop
}

function Download-File {
    param([string]$SourceUrl, [string]$OutFile)
    $client = New-Object System.Net.WebClient
    try {
        $client.Headers.Add("User-Agent", "TeslaLauncher/$version")
        $client.DownloadFile($SourceUrl, $OutFile)
    }
    finally { $client.Dispose() }
}

function Extract-Zip {
    param([string]$ZipPath, [string]$Destination)
    if (!(Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $Destination, $true)
    }
    catch {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $Destination)
    }
}

function Apply-StartupState {
    Update-ToolCount
    if (Test-Path $dest) {
        Set-UiState "Installed" "The toolkit folder is present." "Ready" 100
    }
    else {
        Set-UiState "Ready" "Everything is ready. Pick an action on the left." "Waiting" 0
    }
}

function Start-Install {
    try {
        Set-ButtonsEnabled $false
        $ActivityBox.Clear()

        Set-UiState "Checking system" "Making sure everything is ready." "System Check" 10
        Write-Activity "Running system checks..."

        if ($env:OS -ne "Windows_NT") { throw "This launcher only works on Windows." }
        if ($PSVersionTable.PSVersion.Major -lt 5) { throw "PowerShell 5.0 or newer is required." }
        if (!(Test-Path $downloads)) { throw "The Downloads folder was not found." }

        Set-UiState "Downloading package" "Getting the latest release ZIP." "Download" 35
        if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
        Download-File -SourceUrl $url -OutFile $zip

        if (!(Test-Path $zip)) { throw "The ZIP file was not created after download." }
        $zipItem = Get-Item $zip -ErrorAction Stop
        if ($zipItem.Length -lt 1000) { throw "The downloaded ZIP looks invalid or corrupted." }
        Write-Activity ("Download complete: {0:N2} MB" -f ($zipItem.Length / 1MB))

        Set-UiState "Installing files" "Unpacking the toolkit." "Extracting" 68
        if (Test-Path $dest) { Safe-RemovePath $dest }
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Extract-Zip -ZipPath $zip -Destination $dest

        $items = Get-ChildItem -Path $dest -Recurse -Force -ErrorAction Stop
        $count = ($items | Measure-Object).Count
        if ($count -eq 0) { throw "The install folder is empty after extraction." }

        if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
        Update-ToolCount

        Set-UiState "Install complete" "Everything looks good and the tools are ready." "Done" 100
        Write-Activity "Extracted items: $count"
        Write-Activity "Detected tools: $($ToolCountText.Text)"
        Show-AppMessage "Install Complete" "TeslaPro SS Tools were installed successfully." "Success"
    }
    catch {
        $message = if ($_.Exception.Message) { $_.Exception.Message } else { "Unknown install error." }
        Set-UiState "Install failed" $message "Failed" 0
        Write-Activity "Install failed: $message"
        Show-AppMessage "Install Failed" $message "Error"
    }
    finally { Set-ButtonsEnabled $true }
}

function Start-Remove {
    try {
        if (!(Test-Path $dest)) {
            Set-UiState "Nothing to remove" "No install was found on this system." "Waiting" 0
            Update-ToolCount
            return
        }

        $result = [System.Windows.MessageBox]::Show(
            "This will remove:`n`n$dest`n`nContinue?",
            "Remove installed tools?",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )

        if ($result -ne [System.Windows.MessageBoxResult]::Yes) {
            Set-UiState "Removal cancelled" "No files were removed." "Stopped" 0
            return
        }

        Set-ButtonsEnabled $false
        $ActivityBox.Clear()
        Set-UiState "Removing files" "Cleaning up the installed toolkit." "Removal" 40
        Safe-RemovePath $dest
        if (Test-Path $zip) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
        Update-ToolCount
        Set-UiState "Removal complete" "The installed files were removed successfully." "Done" 100
        Show-AppMessage "Removal Complete" "TeslaPro SS Tools were removed successfully." "Success"
    }
    catch {
        $message = if ($_.Exception.Message) { $_.Exception.Message } else { "Unknown removal error." }
        Set-UiState "Removal failed" $message "Failed" 0
        Show-AppMessage "Removal Failed" $message "Error"
    }
    finally { Set-ButtonsEnabled $true }
}

$window.Add_MouseLeftButtonDown({ try { $window.DragMove() } catch {} })
$CloseButton.Add_Click({ $window.Close() })
$MinButton.Add_Click({ $window.WindowState = "Minimized" })
$ExitButton.Add_Click({ $window.Close() })
$InstallButton.Add_Click({ Start-Install })
$DeleteButton.Add_Click({ Start-Remove })
$OpenFolderButton.Add_Click({
    try {
        if (!(Test-Path $dest)) {
            Show-AppMessage "Open Folder" "The install folder does not exist yet." "Info"
            return
        }
        Start-Process $dest
        Write-Activity "Install folder opened manually."
    }
    catch {
        $message = if ($_.Exception.Message) { $_.Exception.Message } else { "Could not open the install folder." }
        Show-AppMessage "Open Folder Failed" $message "Error"
    }
})

Apply-StartupState

if (Require-DiscordCode) {
    Write-Activity "Discord login accepted."
    $window.ShowDialog() | Out-Null
}
else {
    Write-Activity "Discord login denied."
    $window.Close()
}
