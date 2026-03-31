Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.IO.Compression.FileSystem

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "3.0"

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="TeslaPro's SS Tools Downloader"
    Width="980"
    Height="640"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    Background="#090B10"
    Foreground="White">

    <Window.Resources>
        <LinearGradientBrush x:Key="WindowGlow" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#0D1118" Offset="0"/>
            <GradientStop Color="#0A1220" Offset="0.5"/>
            <GradientStop Color="#081B24" Offset="1"/>
        </LinearGradientBrush>

        <Style x:Key="MenuButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="46"/>
            <Setter Property="Margin" Value="0,0,0,14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="BtnBorder" CornerRadius="12" Background="{TemplateBinding Background}">
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="14" ShadowDepth="0" Opacity="0.25"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.92"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.80"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="BtnBorder" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="CardStyle" TargetType="Border">
            <Setter Property="CornerRadius" Value="18"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Margin" Value="0"/>
            <Setter Property="Background" Value="#11161F"/>
            <Setter Property="BorderBrush" Value="#223044"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
    </Window.Resources>

    <Grid Background="{StaticResource WindowGlow}">
        <Grid.RowDefinitions>
            <RowDefinition Height="92"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="72"/>
        </Grid.RowDefinitions>

        <!-- Background accents -->
        <Ellipse Width="420" Height="420" Fill="#0E5C7A" Opacity="0.08" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-120,-120,0,0"/>
        <Ellipse Width="300" Height="300" Fill="#00E6FF" Opacity="0.06" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-60,-60"/>

        <!-- Header -->
        <Border Grid.Row="0" Background="#0C1017" BorderBrush="#1D2B3C" BorderThickness="0,0,0,1">
            <Grid Margin="28,16,28,16">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="70"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="180"/>
                </Grid.ColumnDefinitions>

                <Border Width="52" Height="52" CornerRadius="14" Background="#101A27" BorderBrush="#244866" BorderThickness="1" VerticalAlignment="Center">
                    <TextBlock Text="T" FontSize="28" FontWeight="Bold" Foreground="#6BE7FF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>

                <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="16,0,0,0">
                    <TextBlock Text="TeslaPro's SS Tools Downloader" FontSize="24" FontWeight="Bold" Foreground="White"/>
                    <TextBlock Text="Premium installer interface" FontSize="13" Foreground="#8EA3B7" Margin="0,4,0,0"/>
                </StackPanel>

                <Border Grid.Column="2" Width="150" Height="36" HorizontalAlignment="Right" VerticalAlignment="Center" CornerRadius="18" Background="#101A27" BorderBrush="#224B66" BorderThickness="1">
                    <TextBlock Name="VersionText" Text="Version 3.0" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#6BE7FF" FontWeight="SemiBold"/>
                </Border>
            </Grid>
        </Border>

        <!-- Main -->
        <Grid Grid.Row="1" Margin="28,24,28,24">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="280"/>
                <ColumnDefinition Width="20"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Left panel -->
            <Border Grid.Column="0" Style="{StaticResource CardStyle}" Background="#0F141D">
                <StackPanel>
                    <TextBlock Text="Control Panel" FontSize="22" FontWeight="Bold" Foreground="White"/>
                    <TextBlock Text="Install, update, or remove the TeslaPro toolkit with a cleaner desktop-style experience." 
                               TextWrapping="Wrap" Margin="0,8,0,22" Foreground="#95A8B9" FontSize="13"/>

                    <Button Name="InstallButton" Content="Install / Update Tools" Style="{StaticResource MenuButtonStyle}" Background="#00B4D8"/>
                    <Button Name="DeleteButton" Content="Remove Installed Tools" Style="{StaticResource MenuButtonStyle}" Background="#1E2A38"/>
                    <Button Name="OpenFolderButton" Content="Open Install Folder" Style="{StaticResource MenuButtonStyle}" Background="#17202C"/>
                    <Button Name="ExitButton" Content="Exit" Style="{StaticResource MenuButtonStyle}" Background="#131922"/>

                    <Border Margin="0,18,0,0" CornerRadius="14" Background="#0C1118" BorderBrush="#1E2A38" BorderThickness="1" Padding="14">
                        <StackPanel>
                            <TextBlock Text="Install Location" Foreground="#7D93A8" FontSize="12"/>
                            <TextBlock Name="LocationText" Text="" Foreground="White" TextWrapping="Wrap" Margin="0,6,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </Border>

            <!-- Right panel -->
            <Grid Grid.Column="2">
                <Grid.RowDefinitions>
                    <RowDefinition Height="110"/>
                    <RowDefinition Height="18"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Border Grid.Row="0" Style="{StaticResource CardStyle}" Background="#0F141D">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="240"/>
                        </Grid.ColumnDefinitions>

                        <StackPanel>
                            <TextBlock Text="System Status" FontSize="22" FontWeight="Bold" Foreground="White"/>
                            <TextBlock Name="StatusText" Text="Ready" Margin="0,10,0,0" FontSize="16" Foreground="#6BE7FF" FontWeight="SemiBold"/>
                            <TextBlock Name="SubStatusText" Text="Waiting for action." Margin="0,6,0,0" FontSize="13" Foreground="#95A8B9"/>
                        </StackPanel>

                        <Border Grid.Column="1" HorizontalAlignment="Right" Width="210" Height="58" CornerRadius="14" Background="#0C1118" BorderBrush="#244866" BorderThickness="1" VerticalAlignment="Center">
                            <StackPanel VerticalAlignment="Center">
                                <TextBlock Text="Toolkit State" HorizontalAlignment="Center" Foreground="#7D93A8" FontSize="11" Margin="0,8,0,2"/>
                                <TextBlock Name="StateChip" Text="IDLE" HorizontalAlignment="Center" Foreground="#6BE7FF" FontSize="17" FontWeight="Bold"/>
                            </StackPanel>
                        </Border>
                    </Grid>
                </Border>

                <Border Grid.Row="2" Style="{StaticResource CardStyle}" Background="#0F141D">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="34"/>
                            <RowDefinition Height="34"/>
                            <RowDefinition Height="18"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <TextBlock Text="Activity Log" FontSize="20" FontWeight="Bold" Foreground="White"/>
                        <ProgressBar Name="MainProgressBar" Grid.Row="1" Height="12" Minimum="0" Maximum="100" Value="0" Background="#0B0F14" Foreground="#00D1FF" BorderThickness="0" Margin="0,8,0,0"/>
                        <TextBox Name="LogBox"
                                 Grid.Row="3"
                                 Margin="0,0,0,0"
                                 Background="#0A0E14"
                                 Foreground="#D9E6F2"
                                 BorderBrush="#1F2C3C"
                                 BorderThickness="1"
                                 FontFamily="Consolas"
                                 FontSize="13"
                                 IsReadOnly="True"
                                 VerticalScrollBarVisibility="Auto"
                                 HorizontalScrollBarVisibility="Auto"
                                 TextWrapping="Wrap"
                                 AcceptsReturn="True"/>
                    </Grid>
                </Border>
            </Grid>
        </Grid>

        <!-- Footer -->
        <Border Grid.Row="2" Background="#0B0F15" BorderBrush="#1D2B3C" BorderThickness="1,1,0,0">
            <Grid Margin="28,0,28,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="220"/>
                </Grid.ColumnDefinitions>

                <TextBlock Text="TeslaPro Installer UI • WPF Edition" VerticalAlignment="Center" Foreground="#768CA1" FontSize="12"/>
                <TextBlock Name="FooterText" Grid.Column="1" Text="Ready" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#6BE7FF" FontSize="12" FontWeight="SemiBold"/>
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
$StatusText       = $window.FindName("StatusText")
$SubStatusText    = $window.FindName("SubStatusText")
$StateChip        = $window.FindName("StateChip")
$LogBox           = $window.FindName("LogBox")
$MainProgressBar  = $window.FindName("MainProgressBar")
$LocationText     = $window.FindName("LocationText")
$FooterText       = $window.FindName("FooterText")
$VersionText      = $window.FindName("VersionText")

$LocationText.Text = $dest
$VersionText.Text = "Version $version"

function Write-Log {
    param([string]$Text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $LogBox.AppendText("[$timestamp] $Text`r`n")
    $LogBox.ScrollToEnd()
}

function Set-UiState {
    param(
        [string]$Title,
        [string]$SubTitle,
        [string]$Chip,
        [double]$Progress = 0
    )
    $StatusText.Text = $Title
    $SubStatusText.Text = $SubTitle
    $StateChip.Text = $Chip.ToUpper()
    $MainProgressBar.Value = $Progress
    $FooterText.Text = $Title
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $InstallButton.IsEnabled    = $Enabled
    $DeleteButton.IsEnabled     = $Enabled
    $OpenFolderButton.IsEnabled = $Enabled
    $ExitButton.IsEnabled       = $Enabled
}

function Invoke-UiRefresh {
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([action]{}, "Background")
}

function Test-SystemRequirements {
    Write-Log "Running system diagnostics..."
    Set-UiState "System Check" "Validating environment and dependencies." "Checking" 10
    Invoke-UiRefresh

    if ($env:OS -ne "Windows_NT") {
        throw "This installer only supports Windows."
    }
    Write-Log "Windows environment detected."

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or higher is required."
    }
    Write-Log "PowerShell version verified: $($PSVersionTable.PSVersion)"

    if (!(Test-Path $downloads)) {
        throw "Downloads folder was not found."
    }
    Write-Log "Downloads folder found."

    $testFile = Join-Path $downloads "teslapro_write_test.tmp"
    "test" | Out-File $testFile -Force
    Remove-Item $testFile -Force
    Write-Log "Write permission confirmed."

    $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
    $drive = Get-PSDrive -Name $driveName
    if ($drive.Free -lt 100MB) {
        throw "Not enough free disk space. At least 100 MB is required."
    }
    Write-Log ("Free disk space available: {0:N2} GB" -f ($drive.Free / 1GB))

    Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null
    Write-Log "Internet connection and GitHub access verified."
}

function Install-Tools {
    try {
        Set-ButtonsEnabled $false
        $LogBox.Clear()
        Write-Log "TeslaPro installation started."
        Test-SystemRequirements

        if (Test-Path $dest) {
            $overwrite = [System.Windows.MessageBox]::Show(
                "An existing installation was found.`n`nDo you want to overwrite it?",
                "TeslaPro Installer",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )

            if ($overwrite -ne [System.Windows.MessageBoxResult]::Yes) {
                Write-Log "Installation cancelled by user."
                Set-UiState "Cancelled" "The existing installation was not modified." "Cancelled" 0
                return
            }

            Write-Log "Existing installation will be replaced."
        }

        Set-UiState "Downloading" "Downloading the latest TeslaPro package." "Download" 35
        Invoke-UiRefresh

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
            Write-Log "Old temporary ZIP removed."
        }

        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip

        if (!(Test-Path $zip)) {
            throw "ZIP file was not created after download."
        }

        $zipSize = (Get-Item $zip).Length
        if ($zipSize -lt 1000) {
            throw "Downloaded ZIP appears invalid or corrupted."
        }

        Write-Log ("Download completed: {0:N2} MB" -f ($zipSize / 1MB))

        Set-UiState "Installing" "Extracting package contents." "Extracting" 65
        Invoke-UiRefresh

        if (Test-Path $dest) {
            Remove-Item $dest -Recurse -Force
            Write-Log "Previous install directory removed."
        }

        New-Item -ItemType Directory -Path $dest | Out-Null
        Expand-Archive -Path $zip -DestinationPath $dest -Force

        $items = Get-ChildItem -Path $dest -Recurse -Force
        $count = ($items | Measure-Object).Count
        if ($count -eq 0) {
            throw "Extraction failed because the destination folder is empty."
        }

        Write-Log "Extraction completed successfully."
        Write-Log "Extracted items: $count"

        if (Test-Path $zip) {
            Remove-Item $zip -Force
            Write-Log "Temporary ZIP removed."
        }

        $tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe | Sort-Object Name
        $toolCount = ($tools | Measure-Object).Count

        if ($toolCount -gt 0) {
            Write-Log "Executable tools detected: $toolCount"
            foreach ($tool in $tools) {
                Write-Log (" - " + $tool.Name)
            }
        }
        else {
            Write-Log "Warning: no .exe files were found in the extracted package."
        }

        Set-UiState "Installation Complete" "TeslaPro SS Tools are ready to use." "Installed" 100
        Write-Log "Installation finished successfully."

        try {
            Start-Process $dest
            Write-Log "Install folder opened automatically."
        }
        catch {
            Write-Log "Install folder could not be opened automatically."
        }

        [System.Windows.MessageBox]::Show(
            "TeslaPro SS Tools were installed successfully.",
            "Installation Complete",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    }
    catch {
        Set-UiState "Installation Failed" $_.Exception.Message "Error" 0
        Write-Log ("ERROR: " + $_.Exception.Message)

        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            "Installation Failed",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    finally {
        Set-ButtonsEnabled $true
    }
}

function Remove-Tools {
    try {
        Set-ButtonsEnabled $false
        $LogBox.Clear()

        if (!(Test-Path $dest)) {
            Set-UiState "Nothing to Remove" "No existing installation was found." "Idle" 0
            Write-Log "No installation found."
            return
        }

        $confirm = [System.Windows.MessageBox]::Show(
            "This will permanently remove TeslaPro SS Tools from:`n`n$dest`n`nContinue?",
            "Confirm Removal",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )

        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
            Write-Log "Removal cancelled by user."
            Set-UiState "Cancelled" "No files were removed." "Cancelled" 0
            return
        }

        Set-UiState "Removing" "Deleting installed files." "Removing" 45
        Write-Log "Removing installed files..."
        Invoke-UiRefresh

        Remove-Item $dest -Recurse -Force -ErrorAction Stop

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
            Write-Log "Temporary ZIP removed."
        }

        Set-UiState "Removed" "TeslaPro SS Tools were removed successfully." "Removed" 100
        Write-Log "Removal completed successfully."

        [System.Windows.MessageBox]::Show(
            "TeslaPro SS Tools were removed successfully.",
            "Removal Complete",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    }
    catch {
        Set-UiState "Removal Failed" $_.Exception.Message "Error" 0
        Write-Log ("ERROR: " + $_.Exception.Message)

        [System.Windows.MessageBox]::Show(
            $_.Exception.Message,
            "Removal Failed",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
    }
    finally {
        Set-ButtonsEnabled $true
    }
}

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
$ExitButton.Add_Click({ $window.Close() })

Set-UiState "Ready" "Waiting for action." "Idle" 0
Write-Log "TeslaPro GUI initialized."
Write-Log "Ready."

$window.ShowDialog() | Out-Null