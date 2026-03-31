Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.IO.Compression.FileSystem

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "4.1"

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="TeslaPro's SS Tools Downloader"
    Width="1220"
    Height="760"
    MinWidth="1220"
    MinHeight="760"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent">

    <Window.Resources>
        <LinearGradientBrush x:Key="WindowBackground" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#06080D" Offset="0"/>
            <GradientStop Color="#0A0F18" Offset="0.45"/>
            <GradientStop Color="#071722" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="SidebarBackground" StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#0B111A" Offset="0"/>
            <GradientStop Color="#0D1420" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="PrimaryButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#18D7FF" Offset="0"/>
            <GradientStop Color="#00A7D6" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="DangerButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#1C2736" Offset="0"/>
            <GradientStop Color="#141C27" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="CardBackground" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#101723" Offset="0"/>
            <GradientStop Color="#0B1018" Offset="1"/>
        </LinearGradientBrush>

        <Style x:Key="ActionButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="52"/>
            <Setter Property="Margin" Value="0,0,0,14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Background" Value="#1A2432"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Root" Background="{TemplateBinding Background}" CornerRadius="16" SnapsToDevicePixels="True">
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="18" ShadowDepth="0" Opacity="0.28"/>
                            </Border.Effect>
                            <Grid Margin="16,0,16,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Width="28" Height="28" CornerRadius="9" Background="#20FFFFFF" VerticalAlignment="Center">
                                    <TextBlock Text="•" FontSize="16" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="White"/>
                                </Border>
                                <ContentPresenter Grid.Column="1" Margin="12,0,0,0" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Root" Property="Opacity" Value="0.94"/>
                                <Setter TargetName="Root" Property="RenderTransform">
                                    <Setter.Value>
                                        <TranslateTransform Y="-1"/>
                                    </Setter.Value>
                                </Setter>
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

        <Style x:Key="SmallWindowButtonStyle" TargetType="Button">
            <Setter Property="Width" Value="34"/>
            <Setter Property="Height" Value="34"/>
            <Setter Property="Margin" Value="8,0,0,0"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="16"/>
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
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.90"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.72"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="CardBorderStyle" TargetType="Border">
            <Setter Property="CornerRadius" Value="22"/>
            <Setter Property="Padding" Value="22"/>
            <Setter Property="Background" Value="{StaticResource CardBackground}"/>
            <Setter Property="BorderBrush" Value="#1C2A3C"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
    </Window.Resources>

    <Border CornerRadius="24" Background="{StaticResource WindowBackground}" BorderBrush="#1D2938" BorderThickness="1">
        <Border.Effect>
            <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.4"/>
        </Border.Effect>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="64"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <Ellipse Width="520" Height="520" Fill="#1DDCFF" Opacity="0.06" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-180,-170,0,0"/>
            <Ellipse Width="420" Height="420" Fill="#0E86FF" Opacity="0.05" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-110,-120"/>

            <Border Grid.Row="0" Background="#0A0F17" CornerRadius="24,24,0,0" BorderBrush="#162232" BorderThickness="0,0,0,1">
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
                            <TextBlock Text="TeslaPro's SS Tools Downloader" FontSize="18" FontWeight="Bold" Foreground="White"/>
                            <TextBlock Text="Premium Installer UI" FontSize="11" Foreground="#7E92A6" Margin="0,2,0,0"/>
                        </StackPanel>
                    </StackPanel>

                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button x:Name="MinButton" Content="—" Style="{StaticResource SmallWindowButtonStyle}"/>
                        <Button x:Name="CloseButton" Content="✕" Style="{StaticResource SmallWindowButtonStyle}" Background="#1F2330"/>
                    </StackPanel>
                </Grid>
            </Border>

            <Grid Grid.Row="1" Margin="20">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="290"/>
                    <ColumnDefinition Width="20"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Border Grid.Column="0" Background="{StaticResource SidebarBackground}" CornerRadius="22" BorderBrush="#192537" BorderThickness="1" Padding="20">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="18"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <StackPanel>
                            <TextBlock Text="Control Center" FontSize="24" FontWeight="Bold" Foreground="White"/>
                            <TextBlock Text="A polished installer experience for TeslaPro SS Tools." TextWrapping="Wrap" Margin="0,8,0,0" Foreground="#8EA2B6" FontSize="13"/>
                        </StackPanel>

                        <StackPanel Grid.Row="2">
                            <Button x:Name="InstallButton" Content="Install / Update Tools" Style="{StaticResource ActionButtonStyle}" Background="{StaticResource PrimaryButtonBrush}"/>
                            <Button x:Name="DeleteButton" Content="Remove Installed Tools" Style="{StaticResource ActionButtonStyle}" Background="{StaticResource DangerButtonBrush}"/>
                            <Button x:Name="OpenFolderButton" Content="Open Install Folder" Style="{StaticResource ActionButtonStyle}" Background="#16202C"/>
                            <Button x:Name="ExitButton" Content="Exit Application" Style="{StaticResource ActionButtonStyle}" Background="#121923"/>
                        </StackPanel>

                        <Border Grid.Row="4" Background="#0B1017" CornerRadius="18" Padding="16" BorderBrush="#1B2837" BorderThickness="1">
                            <StackPanel>
                                <TextBlock Text="Install Path" FontSize="12" Foreground="#7890A6"/>
                                <TextBlock x:Name="LocationText" Margin="0,8,0,0" TextWrapping="Wrap" Foreground="White" FontSize="13"/>
                                <Border Margin="0,14,0,0" CornerRadius="14" Background="#101722" Padding="12" BorderBrush="#203042" BorderThickness="1">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel>
                                            <TextBlock Text="Toolkit Version" Foreground="#7A92A8" FontSize="11"/>
                                            <TextBlock x:Name="VersionText" Text="Version 4.1" Foreground="#74E8FF" FontSize="16" FontWeight="Bold" Margin="0,4,0,0"/>
                                        </StackPanel>
                                        <Border Grid.Column="1" Width="68" Height="30" CornerRadius="15" Background="#122232" BorderBrush="#234760" BorderThickness="1" VerticalAlignment="Center">
                                            <TextBlock x:Name="StateChip" Text="IDLE" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#74E8FF" FontSize="12" FontWeight="Bold"/>
                                        </Border>
                                    </Grid>
                                </Border>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Border>

                <Grid Grid.Column="2">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="150"/>
                        <RowDefinition Height="18"/>
                        <RowDefinition Height="150"/>
                        <RowDefinition Height="18"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Style="{StaticResource CardBorderStyle}">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="290"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel>
                                <TextBlock x:Name="StatusText" Text="Ready" FontSize="30" FontWeight="Bold" Foreground="White"/>
                                <TextBlock x:Name="SubStatusText" Text="Waiting for action." Margin="0,8,0,0" FontSize="14" Foreground="#9DB1C4"/>
                                <Border Margin="0,18,0,0" CornerRadius="14" Background="#0B121B" Padding="12" BorderBrush="#1A293A" BorderThickness="1">
                                    <TextBlock Text="Install, update, and manage TeslaPro’s SS toolkit through a clean premium desktop interface." Foreground="#84A1BA" TextWrapping="Wrap"/>
                                </Border>
                            </StackPanel>

                            <Border Grid.Column="1" HorizontalAlignment="Right" Width="260" Height="104" CornerRadius="22" Background="#0B1119" BorderBrush="#1E3145" BorderThickness="1">
                                <Grid Margin="16">
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>
                                    <TextBlock Text="Toolkit State" Foreground="#7990A5" FontSize="12"/>
                                    <StackPanel Grid.Row="1" VerticalAlignment="Center">
                                        <TextBlock x:Name="BigChipText" Text="IDLE" HorizontalAlignment="Center" Foreground="#74E8FF" FontSize="22" FontWeight="Bold"/>
                                        <TextBlock x:Name="FooterText" Text="Ready" HorizontalAlignment="Center" Foreground="#8FA4B8" FontSize="12" Margin="0,6,0,0"/>
                                    </StackPanel>
                                </Grid>
                            </Border>
                        </Grid>
                    </Border>

                    <Grid Grid.Row="2">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="16"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="16"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <Border Grid.Column="0" Style="{StaticResource CardBorderStyle}" Padding="18">
                            <StackPanel>
                                <TextBlock Text="Current Step" FontSize="12" Foreground="#7C93A8"/>
                                <TextBlock x:Name="StepText" Text="Waiting" FontSize="22" FontWeight="Bold" Foreground="White" Margin="0,8,0,0"/>
                                <TextBlock Text="Real-time installer phase." Margin="0,6,0,0" Foreground="#8DA3B7" FontSize="12"/>
                            </StackPanel>
                        </Border>

                        <Border Grid.Column="2" Style="{StaticResource CardBorderStyle}" Padding="18">
                            <StackPanel>
                                <TextBlock Text="Progress" FontSize="12" Foreground="#7C93A8"/>
                                <TextBlock x:Name="ProgressLabel" Text="0%" FontSize="22" FontWeight="Bold" Foreground="White" Margin="0,8,0,0"/>
                                <TextBlock Text="Installer completion status." Margin="0,6,0,0" Foreground="#8DA3B7" FontSize="12"/>
                            </StackPanel>
                        </Border>

                        <Border Grid.Column="4" Style="{StaticResource CardBorderStyle}" Padding="18">
                            <StackPanel>
                                <TextBlock Text="Detected Tools" FontSize="12" Foreground="#7C93A8"/>
                                <TextBlock x:Name="ToolCountText" Text="0" FontSize="22" FontWeight="Bold" Foreground="White" Margin="0,8,0,0"/>
                                <TextBlock Text="Executable files found after install." Margin="0,6,0,0" Foreground="#8DA3B7" FontSize="12"/>
                            </StackPanel>
                        </Border>
                    </Grid>

                    <Border Grid.Row="4" Style="{StaticResource CardBorderStyle}">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="16"/>
                                <RowDefinition Height="12"/>
                                <RowDefinition Height="18"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>

                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel>
                                    <TextBlock Text="Activity Console" FontSize="22" FontWeight="Bold" Foreground="White"/>
                                    <TextBlock Text="Installer output and diagnostics" Foreground="#91A7BB" FontSize="12" Margin="0,6,0,0"/>
                                </StackPanel>
                                <Border Grid.Column="1" Width="140" Height="34" HorizontalAlignment="Right" VerticalAlignment="Top" CornerRadius="17" Background="#0B121B" BorderBrush="#203447" BorderThickness="1">
                                    <TextBlock x:Name="MiniStateText" Text="READY" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#74E8FF" FontWeight="Bold"/>
                                </Border>
                            </Grid>

                            <ProgressBar x:Name="MainProgressBar" Grid.Row="2" Height="12" Minimum="0" Maximum="100" Value="0" Background="#091018" Foreground="#22D6FF" BorderThickness="0"/>

                            <TextBox x:Name="LogBox"
                                     Grid.Row="4"
                                     Background="#091018"
                                     Foreground="#D8E8F5"
                                     BorderBrush="#1A2B3C"
                                     BorderThickness="1"
                                     FontFamily="Consolas"
                                     FontSize="13"
                                     IsReadOnly="True"
                                     VerticalScrollBarVisibility="Auto"
                                     HorizontalScrollBarVisibility="Auto"
                                     TextWrapping="Wrap"
                                     AcceptsReturn="True"
                                     Padding="14"/>
                        </Grid>
                    </Border>
                </Grid>
            </Grid>
        </Grid>
    </Border>
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
$StateChip        = $window.FindName("StateChip")
$BigChipText      = $window.FindName("BigChipText")
$MiniStateText    = $window.FindName("MiniStateText")
$FooterText       = $window.FindName("FooterText")

$StepText         = $window.FindName("StepText")
$ProgressLabel    = $window.FindName("ProgressLabel")
$ToolCountText    = $window.FindName("ToolCountText")
$LogBox           = $window.FindName("LogBox")
$MainProgressBar  = $window.FindName("MainProgressBar")
$LocationText     = $window.FindName("LocationText")
$VersionText      = $window.FindName("VersionText")

$LocationText.Text = $dest
$VersionText.Text = "Version $version"

$script:InstallWorker = $null
$script:RemoveWorker  = $null

function Invoke-UI {
    param([scriptblock]$Action)
    $window.Dispatcher.Invoke($Action)
}

function Write-Log {
    param([string]$Text)
    Invoke-UI {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $LogBox.AppendText("[$timestamp] $Text`r`n")
        $LogBox.ScrollToEnd()
    }
}

function Set-UiState {
    param(
        [string]$Title,
        [string]$SubTitle,
        [string]$Chip,
        [string]$Step,
        [double]$Progress = 0
    )

    Invoke-UI {
        $StatusText.Text       = $Title
        $SubStatusText.Text    = $SubTitle
        $StateChip.Text        = $Chip.ToUpper()
        $BigChipText.Text      = $Chip.ToUpper()
        $MiniStateText.Text    = $Chip.ToUpper()
        $FooterText.Text       = $Title
        $StepText.Text         = $Step
        $MainProgressBar.Value = $Progress
        $ProgressLabel.Text    = ("{0}%" -f [int]$Progress)
    }
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    Invoke-UI {
        $InstallButton.IsEnabled    = $Enabled
        $DeleteButton.IsEnabled     = $Enabled
        $OpenFolderButton.IsEnabled = $Enabled
        $ExitButton.IsEnabled       = $Enabled
    }
}

function Update-ToolCount {
    try {
        $count = 0
        if (Test-Path $dest) {
            $tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe -ErrorAction SilentlyContinue
            $count = ($tools | Measure-Object).Count
        }

        Invoke-UI {
            $ToolCountText.Text = $count.ToString()
        }
    }
    catch {
        Invoke-UI {
            $ToolCountText.Text = "0"
        }
    }
}

function Safe-DeletePath {
    param([string]$Path)

    if (!(Test-Path $Path)) { return }

    $maxAttempts = 3
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            Remove-Item $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            if ($i -eq $maxAttempts) {
                throw
            }
            Start-Sleep -Milliseconds 400
        }
    }
}

function Test-SystemRequirements {
    Write-Log "Running system diagnostics..."

    if ($env:OS -ne "Windows_NT") {
        throw "This installer only supports Windows."
    }
    Write-Log "Windows environment detected."

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or higher is required."
    }
    Write-Log "PowerShell version verified: $($PSVersionTable.PSVersion)"

    if (!(Test-Path $downloads)) {
        throw "The Downloads folder was not found."
    }
    Write-Log "Downloads folder located."

    $testFile = Join-Path $downloads "teslapro_write_test.tmp"
    "test" | Out-File $testFile -Force
    Remove-Item $testFile -Force
    Write-Log "Write permission confirmed."

    $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
    $drive = Get-PSDrive -Name $driveName -ErrorAction Stop
    if ($drive.Free -lt 100MB) {
        throw "Not enough free disk space. At least 100 MB is required."
    }
    Write-Log ("Free disk space available: {0:N2} GB" -f ($drive.Free / 1GB))

    try {
        $req = [System.Net.WebRequest]::Create("https://github.com")
        $req.Method = "HEAD"
        $req.Timeout = 10000
        $resp = $req.GetResponse()
        $resp.Close()
    }
    catch {
        throw "GitHub could not be reached. Check your internet connection."
    }

    Write-Log "Internet connection and GitHub access verified."
}

function Install-Tools {
    if ($script:InstallWorker -and $script:InstallWorker.IsBusy) { return }

    $overwrite = $true
    if (Test-Path $dest) {
        $overwrite = [System.Windows.MessageBox]::Show(
            "An existing installation was found.`n`nDo you want to overwrite it?",
            "TeslaPro Installer",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        ) -eq [System.Windows.MessageBoxResult]::Yes
    }

    if (-not $overwrite) {
        Set-UiState "Cancelled" "The existing installation was not modified." "Cancelled" "Stopped" 0
        Write-Log "Installation cancelled by user."
        return
    }

    $script:InstallWorker = New-Object System.ComponentModel.BackgroundWorker
    $script:InstallWorker.WorkerReportsProgress = $true

    $script:InstallWorker.add_DoWork({
        param($sender, $e)

        try {
            Set-ButtonsEnabled $false
            Invoke-UI {
                $LogBox.Clear()
                $ToolCountText.Text = "0"
            }

            Write-Log "TeslaPro installation started."
            Set-UiState "System Check" "Validating environment and required dependencies." "Checking" "Diagnostics" 10
            Test-SystemRequirements

            Set-UiState "Downloading" "Fetching the latest TeslaPro package." "Downloading" "Download" 35

            if (Test-Path $zip) {
                Remove-Item $zip -Force -ErrorAction SilentlyContinue
                Write-Log "Old temporary ZIP removed."
            }

            $client = New-Object System.Net.WebClient
            try {
                $client.Headers.Add("User-Agent", "TeslaProInstaller")
                $client.DownloadFile($url, $zip)
            }
            finally {
                $client.Dispose()
            }

            if (!(Test-Path $zip)) {
                throw "ZIP file was not created after download."
            }

            $zipSize = (Get-Item $zip -ErrorAction Stop).Length
            if ($zipSize -lt 1000) {
                throw "Downloaded ZIP appears invalid or corrupted."
            }

            Write-Log ("Download completed: {0:N2} MB" -f ($zipSize / 1MB))

            Set-UiState "Installing" "Extracting and preparing toolkit files." "Installing" "Extraction" 68

            if (Test-Path $dest) {
                Safe-DeletePath $dest
                Write-Log "Previous installation folder removed."
            }

            New-Item -ItemType Directory -Path $dest -Force | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $dest)

            $items = Get-ChildItem -Path $dest -Recurse -Force -ErrorAction Stop
            $count = ($items | Measure-Object).Count
            if ($count -eq 0) {
                throw "Extraction failed because the destination folder is empty."
            }

            Write-Log "Extraction completed successfully."
            Write-Log "Extracted items: $count"

            if (Test-Path $zip) {
                Remove-Item $zip -Force -ErrorAction SilentlyContinue
                Write-Log "Temporary ZIP removed."
            }

            $tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe -ErrorAction SilentlyContinue | Sort-Object Name
            $toolCount = ($tools | Measure-Object).Count

            if ($toolCount -gt 0) {
                Write-Log "Executable tools detected: $toolCount"
            }
            else {
                Write-Log "Warning: no .exe files were found in the extracted package."
            }

            Set-UiState "Installation Complete" "TeslaPro SS Tools are ready to use." "Installed" "Finished" 100
            Write-Log "Installation finished successfully."

            try {
                Start-Process $dest
                Write-Log "Installation folder opened automatically."
            }
            catch {
                Write-Log "Installation folder could not be opened automatically."
            }

            $e.Result = @{
                Success = $true
                ToolCount = $toolCount
            }
        }
        catch {
            $e.Result = @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    })

    $script:InstallWorker.add_RunWorkerCompleted({
        param($sender, $e)

        try {
            if (-not $e.Result.Success) {
                Set-UiState "Installation Failed" $e.Result.Error "Error" "Failed" 0
                Write-Log ("ERROR: " + $e.Result.Error)

                [System.Windows.MessageBox]::Show(
                    $e.Result.Error,
                    "Installation Failed",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                ) | Out-Null
            }
            else {
                Update-ToolCount

                [System.Windows.MessageBox]::Show(
                    "TeslaPro SS Tools were installed successfully.",
                    "Installation Complete",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                ) | Out-Null
            }
        }
        finally {
            Set-ButtonsEnabled $true
            $script:InstallWorker.Dispose()
            $script:InstallWorker = $null
        }
    })

    $script:InstallWorker.RunWorkerAsync()
}

function Remove-Tools {
    if ($script:RemoveWorker -and $script:RemoveWorker.IsBusy) { return }

    if (!(Test-Path $dest)) {
        Set-UiState "Nothing to Remove" "No existing installation was found." "Idle" "Waiting" 0
        Write-Log "No installation found."
        Update-ToolCount
        return
    }

    $confirm = [System.Windows.MessageBox]::Show(
        "This will permanently remove TeslaPro SS Tools from:`n`n$dest`n`nContinue?",
        "Confirm Removal",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
        Set-UiState "Cancelled" "No files were removed." "Cancelled" "Stopped" 0
        Write-Log "Removal cancelled by user."
        return
    }

    $script:RemoveWorker = New-Object System.ComponentModel.BackgroundWorker

    $script:RemoveWorker.add_DoWork({
        param($sender, $e)

        try {
            Set-ButtonsEnabled $false
            Invoke-UI { $LogBox.Clear() }

            Set-UiState "Removing" "Deleting installed files and cleanup data." "Removing" "Removal" 48
            Write-Log "Removing installed files..."

            Safe-DeletePath $dest

            if (Test-Path $zip) {
                Remove-Item $zip -Force -ErrorAction SilentlyContinue
                Write-Log "Temporary ZIP removed."
            }

            Set-UiState "Removed" "TeslaPro SS Tools were removed successfully." "Removed" "Complete" 100
            Write-Log "Removal completed successfully."

            $e.Result = @{
                Success = $true
            }
        }
        catch {
            $e.Result = @{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    })

    $script:RemoveWorker.add_RunWorkerCompleted({
        param($sender, $e)

        try {
            if (-not $e.Result.Success) {
                Set-UiState "Removal Failed" $e.Result.Error "Error" "Failed" 0
                Write-Log ("ERROR: " + $e.Result.Error)
                Update-ToolCount

                [System.Windows.MessageBox]::Show(
                    $e.Result.Error,
                    "Removal Failed",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Error
                ) | Out-Null
            }
            else {
                Invoke-UI { $ToolCountText.Text = "0" }

                [System.Windows.MessageBox]::Show(
                    "TeslaPro SS Tools were removed successfully.",
                    "Removal Complete",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                ) | Out-Null
            }
        }
        finally {
            Set-ButtonsEnabled $true
            $script:RemoveWorker.Dispose()
            $script:RemoveWorker = $null
        }
    })

    $script:RemoveWorker.RunWorkerAsync()
}

$window.Add_MouseLeftButtonDown({
    try { $window.DragMove() } catch {}
})

$CloseButton.Add_Click({ $window.Close() })
$MinButton.Add_Click({ $window.WindowState = "Minimized" })
$ExitButton.Add_Click({ $window.Close() })

$InstallButton.Add_Click({ Install-Tools })
$DeleteButton.Add_Click({ Remove-Tools })

$OpenFolderButton.Add_Click({
    try {
        if (!(Test-Path $dest)) {
            [System.Windows.MessageBox]::Show(
                "The installation folder does not exist yet.",
                "Open Folder",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
            return
        }

        Start-Process $dest
        Write-Log "Installation folder opened manually."
    }
    catch {
        Write-Log ("ERROR: " + $_.Exception.Message)
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

Set-UiState "Ready" "Waiting for action." "Idle" "Waiting" 0
Write-Log "TeslaPro premium GUI initialized."
Write-Log "Ready."
Update-ToolCount

$window.ShowDialog() | Out-Null