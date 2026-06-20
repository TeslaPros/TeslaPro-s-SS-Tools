<#
.SYNOPSIS
    TeslaPro Tools - Onafhankelijke Launcher en Downloadmanager
.DESCRIPTION
    Volledig herschreven launcher gebaseerd op de originele installer.
    - Geen centrale pakketten
    - Asynchrone veilige downloads via Runspaces
    - Volledige GUI in WPF (1 bestand)
#>
#Requires -Version 5.1

#region Metadata and requirements
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
#endregion

#region Assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.IO.Compression.FileSystem
#endregion

#region Application configuration
$appVersion = "4.0.0"
$defaultDownloadDir = Join-Path $env:LOCALAPPDATA "TeslaProTools\Downloads"

# Maak veilige map aan als deze niet bestaat (LOCALAPPDATA is afgeschermd per gebruiker, veiliger dan C:\ of Temp)
if (-not (Test-Path $defaultDownloadDir)) {
    New-Item -ItemType Directory -Path $defaultDownloadDir -Force | Out-Null
}
#endregion

#region Application state
$script:Settings = [PSCustomObject]@{
    AnimationsEnabled = $true
    ConfirmExecute    = $true
    DownloadDir       = $defaultDownloadDir
$script:Settings = [ordered]@{
    AnimationsEnabled = $true
}
    SafeMode          = $false
}

$script:ActiveDownloads = @{}
$script:RunspacePool = [runspacefactory]::CreateRunspacePool(1, 3)
$script:RunspacePool.Open()
#endregion

#region Tool definitions
$script:Tools = @(
    [PSCustomObject]@{
        Id                    = "sysinternals-procexp"
        Name                  = "Process Explorer"
        Author                = "Microsoft Sysinternals"
        Description           = "Geavanceerde process manager. Handig voor het opsporen van verborgen processen en malware."
        Version               = "Latest"
        Category              = "System"
        OfficialWebsite       = "https://learn.microsoft.com/en-us/sysinternals/downloads/process-explorer"
        GitHubRepository      = ""
        GitHubReleasePage     = ""
        ActionType            = "DirectDownload"
        DirectDownloadUrl     = "https://download.sysinternals.com/files/ProcessExplorer.zip"
        DownloadFileName      = "ProcessExplorer.zip"
        GitHubAssetPattern    = ""
        LaunchFileName        = "procexp.exe"
        LaunchType            = "ExtractAndLaunch"
        LaunchArguments       = ""
        RequiresAdministrator = $true
        AllowedDomains        = @("download.sysinternals.com")
        AllowedExtensions     = @(".zip")
        Sha256                = ""
        Credits               = "Alle rechten en credits behoren toe aan Microsoft Sysinternals."
        Warning               = "Deze tool wordt gestart met administratorrechten."
        Icon                  = ""
    },
    [PSCustomObject]@{
        Id                    = "rufus"
        Name                  = "Rufus"
        Author                = "Pete Batard"
        Description           = "Maak eenvoudig opstartbare USB-drives aan."
        Version               = "Latest"
        Category              = "Algemeen"
        OfficialWebsite       = "https://rufus.ie/"
        GitHubRepository      = "https://github.com/pbatard/rufus"
        GitHubReleasePage     = "https://github.com/pbatard/rufus/releases"
        ActionType            = "GitHubReleasePage"
        DirectDownloadUrl     = ""
        DownloadFileName      = ""
        GitHubAssetPattern    = ""
        LaunchFileName        = ""
        LaunchType            = "None"
        LaunchArguments       = ""
        RequiresAdministrator = $false
        AllowedDomains        = @("github.com")
        AllowedExtensions     = @(".exe")
        Sha256                = ""
        Credits               = "Pete Batard en open-source contributors."
        Warning               = ""
        Icon                  = ""
    }
)
#endregion

#region Command definitions
$script:Commands = @(
    [PSCustomObject]@{
        Id                    = "ipconfig-all"
        Name                  = "Netwerkconfiguratie (All)"
        Category              = "Netwerk"
        Shell                 = "CMD"
        Command               = "ipconfig /all"
        Description           = "Toont uitgebreide informatie over alle netwerkadapters."
        Explanation           = "Dit commando geeft gedetailleerde informatie over IP-adressen, DNS-servers, MAC-adressen en actieve adapters op het systeem."
        Example               = "ipconfig /all"
        Warning               = ""
        RequiresAdministrator = $false
        AllowExecution        = $true
    },
    [PSCustomObject]@{
        Id                    = "sfc-scannow"
        Name                  = "Systeembestanden herstellen"
        Category              = "Troubleshooting"
        Shell                 = "CMD"
        Command               = "sfc /scannow"
        Description           = "Scant op beschadigde Windows-systeembestanden en herstelt deze."
        Explanation           = "System File Checker (SFC) is een ingebouwde Windows tool. Het verifieert de integriteit van essentiële bestanden. Uitvoeren kan enige tijd duren."
        Example               = "sfc /scannow"
        Warning               = "Systeemwijzigingen kunnen optreden bij herstel."
        RequiresAdministrator = $true
        AllowExecution        = $true
    },
    [PSCustomObject]@{
        Id                    = "flush-dns"
        Name                  = "DNS Cache legen"
        Category              = "Netwerk"
        Shell                 = "CMD"
        Command               = "ipconfig /flushdns"
        Description           = "Wist de DNS-resolvercache."
        Explanation           = "Handig als websites niet laden of als DNS-gegevens recent zijn gewijzigd."
        Example               = "ipconfig /flushdns"
        Warning               = ""
        RequiresAdministrator = $false
        AllowExecution        = $true
    }
)
#endregion

#region Embedded XAML
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="TeslaPro Tools" Width="1320" Height="830" MinWidth="1320" MinHeight="830"
    WindowStartupLocation="CenterScreen" ResizeMode="NoResize" WindowStyle="None"
    AllowsTransparency="True" Background="Transparent" FontFamily="Segoe UI" Opacity="1">

    <Window.Resources>
        <LinearGradientBrush x:Key="WindowBackground" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#05070B" Offset="0"/>
            <GradientStop Color="#09111B" Offset="0.46"/>
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

        <Style x:Key="ActionButtonStyle" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="56"/>
            <Setter Property="Margin" Value="0,0,0,14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Background" Value="{StaticResource NeutralButtonBrush}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Root" Background="{TemplateBinding Background}" CornerRadius="17" BorderBrush="#203040" BorderThickness="1">
                            <Grid Margin="16,0,16,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="12"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Width="36" Height="36" CornerRadius="11" Background="#18FFFFFF" BorderBrush="#24FFFFFF" BorderThickness="1" VerticalAlignment="Center">
                                    <TextBlock Text="{TemplateBinding Tag}" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                                <ContentPresenter Grid.Column="2" VerticalAlignment="Center" RecognizesAccessKey="True"/>
                            </Grid>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Root" Property="Opacity" Value="0.97"/>
                                <Setter TargetName="Root" Property="BorderBrush" Value="#35D9FF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Root" Property="Opacity" Value="0.82"/>
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
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <Style x:Key="CardBorderStyle" TargetType="Border">
            <Setter Property="CornerRadius" Value="22"/>
            <Setter Property="Padding" Value="22"/>
            <Setter Property="Background" Value="{StaticResource CardBackground}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Border CornerRadius="24" Background="{StaticResource WindowBackground}" BorderBrush="#1D2938" BorderThickness="1">
            <Border.Effect><DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.45"/></Border.Effect>
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="64"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Ellipse Width="560" Height="560" Fill="#1DDCFF" Opacity="0.06" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-190,-180,0,0"/>
                <Ellipse Width="430" Height="430" Fill="#0E86FF" Opacity="0.05" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-120,-130"/>

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
                                <TextBlock Text="TeslaPro Tools" FontSize="18" FontWeight="SemiBold" Foreground="White"/>
                                <TextBlock Text="Launcher &amp; Command Manager" FontSize="11" Foreground="#7E92A6" Margin="0,2,0,0"/>
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
                        <ColumnDefinition Width="280"/>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <Border Grid.Column="0" Background="{StaticResource SidebarBackground}" CornerRadius="22" BorderBrush="#192537" BorderThickness="1" Padding="20">
                        <Grid>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="20"/>
                                <RowDefinition Height="*"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            <StackPanel>
                                <TextBlock Text="Navigatie" FontSize="24" FontWeight="SemiBold" Foreground="White"/>
                            </StackPanel>
                            <StackPanel Grid.Row="2">
                                <Button x:Name="NavHome" Tag="" Content="Home" Style="{StaticResource ActionButtonStyle}" Background="#182434"/>
                                <Button x:Name="NavTools" Tag="" Content="Tools" Style="{StaticResource ActionButtonStyle}" Background="#182434"/>
                                <Button x:Name="NavCmd" Tag="" Content="CMD Commands" Style="{StaticResource ActionButtonStyle}" Background="#182434"/>
                                <Button x:Name="NavDownloads" Tag="" Content="Downloads" Style="{StaticResource ActionButtonStyle}" Background="#182434"/>
                                <Button x:Name="NavInfo" Tag="" Content="Info" Style="{StaticResource ActionButtonStyle}" Background="#182434"/>
                                <Button x:Name="NavSettings" Tag="" Content="Settings" Style="{StaticResource ActionButtonStyle}" Background="#182434"/>
                            </StackPanel>
                            <StackPanel Grid.Row="3">
                                <Button x:Name="ExitButton" Tag="" Content="Exit Launcher" Style="{StaticResource ActionButtonStyle}" Background="#141C28"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <Grid Grid.Column="2">
                        
                        <Grid x:Name="PageHome" Visibility="Visible">
                            <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                                <TextBlock Text="Welcome to TeslaPro Tools" FontSize="36" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center"/>
                                <TextBlock Text="Kies een onderdeel om te beginnen." FontSize="16" Foreground="#8DA3B7" HorizontalAlignment="Center" Margin="0,10,0,40"/>
                                
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="340"/>
                                        <ColumnDefinition Width="40"/>
                                        <ColumnDefinition Width="340"/>
                                    </Grid.ColumnDefinitions>
                                    
                                    <Border x:Name="HomeBtnTools" Grid.Column="0" Height="220" Background="{StaticResource PrimaryButtonBrush}" CornerRadius="22" Cursor="Hand">
                                        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                                            <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="50" Foreground="White" HorizontalAlignment="Center"/>
                                            <TextBlock Text="Tools" FontSize="28" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" Margin="0,15,0,0"/>
                                            <TextBlock Text="Bekijk, download en open tools" FontSize="14" Foreground="#E0F7FA" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                                        </StackPanel>
                                    </Border>
                                    
                                    <Border x:Name="HomeBtnCmd" Grid.Column="2" Height="220" Background="#1A2B42" BorderBrush="#35D9FF" BorderThickness="1" CornerRadius="22" Cursor="Hand">
                                        <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                                            <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="50" Foreground="White" HorizontalAlignment="Center"/>
                                            <TextBlock Text="CMD Commands" FontSize="28" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center" Margin="0,15,0,0"/>
                                            <TextBlock Text="Bekijk en kopieer commando's" FontSize="14" Foreground="#A9C2D8" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                                        </StackPanel>
                                    </Border>
                                </Grid>
                            </StackPanel>
                        </Grid>

                        <Grid x:Name="PageTools" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="20"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Style="{StaticResource CardBorderStyle}" Padding="15">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="300"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel>
                                        <TextBlock Text="Tools Overzicht" FontSize="26" FontWeight="SemiBold" Foreground="White"/>
                                        <TextBlock Text="Kies een officiële tool om te downloaden of te starten." Foreground="#9DB1C4" FontSize="14" Margin="0,4,0,0"/>
                                    </StackPanel>
                                    <TextBox x:Name="SearchTools" Grid.Column="1" Height="38" Background="#121A26" Foreground="White" BorderBrush="#203040" Padding="10,8" VerticalContentAlignment="Center" Margin="0,5,0,0" ToolTip="Zoeken..."/>
                                </Grid>
                            </Border>
                            <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                <WrapPanel x:Name="ToolsContainer" Orientation="Horizontal" Margin="0,0,-15,0"/>
                            </ScrollViewer>
                        </Grid>

                        <Grid x:Name="PageCmd" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="20"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Style="{StaticResource CardBorderStyle}" Padding="15">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="300"/>
                                    </Grid.ColumnDefinitions>
                                    <StackPanel>
                                        <TextBlock Text="CMD Commands" FontSize="26" FontWeight="SemiBold" Foreground="White"/>
                                        <TextBlock Text="Handige commando's voor netwerk en systeembeheer." Foreground="#9DB1C4" FontSize="14" Margin="0,4,0,0"/>
                                    </StackPanel>
                                    <TextBox x:Name="SearchCmd" Grid.Column="1" Height="38" Background="#121A26" Foreground="White" BorderBrush="#203040" Padding="10,8" VerticalContentAlignment="Center" Margin="0,5,0,0" ToolTip="Zoeken..."/>
                                </Grid>
                            </Border>
                            <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                                <StackPanel x:Name="CmdContainer" Margin="0,0,15,0"/>
                            </ScrollViewer>
                        </Grid>

                        <Grid x:Name="PageDownloads" Visibility="Collapsed">
                             <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="20"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <Border Style="{StaticResource CardBorderStyle}" Padding="15">
                                <StackPanel>
                                    <TextBlock Text="Downloads" FontSize="26" FontWeight="SemiBold" Foreground="White"/>
                                    <TextBlock Text="Overzicht van actieve en voltooide downloads." Foreground="#9DB1C4" FontSize="14" Margin="0,4,0,0"/>
                                </StackPanel>
                            </Border>
                            <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                                <StackPanel x:Name="DownloadsContainer"/>
                            </ScrollViewer>
                        </Grid>

                        <Grid x:Name="PageInfo" Visibility="Collapsed">
                            <Border Style="{StaticResource CardBorderStyle}" VerticalAlignment="Top">
                                <StackPanel>
                                    <TextBlock Text="Over TeslaPro Tools" FontSize="26" FontWeight="SemiBold" Foreground="White"/>
                                    <TextBlock Text="Onafhankelijke Launcher &amp; Manager" FontSize="14" Foreground="#74E8FF" Margin="0,5,0,20"/>
                                    
                                    <TextBlock TextWrapping="Wrap" Foreground="#DCE7F2" FontSize="14" LineHeight="22">
TeslaPro Tools is een onafhankelijke launcher die gebruikers doorverwijst naar de officiële websites, repositories en distributiekanalen van externe tools. TeslaPro Tools host, wijzigt of herverpakt deze externe tools niet. Alle rechten, eigendommen en credits behoren toe aan de oorspronkelijke makers.
<LineBreak/><LineBreak/>
Ontwikkeld met ondersteuning van AI, specifiek ontworpen om veiligheid, stabiliteit en transparantie te garanderen. Er worden geen tools stilletjes geïnstalleerd.
                                    </TextBlock>
                                </StackPanel>
                            </Border>
                        </Grid>
<Grid x:Name="PageSettings" Visibility="Collapsed">
    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
        <TextBlock Text="Settings" FontSize="26" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center" Margin="0,0,0,20"/>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="0,10">
            <CheckBox x:Name="ChkAnimations" Content="Animaties inschakelen" IsChecked="True" Foreground="White" FontSize="14"/>
        </StackPanel>
    </StackPanel>
</Grid>

                    </Grid>
                </Grid>
            </Grid>
        </Border>

        <Grid x:Name="OverlayRoot" Visibility="Collapsed" Opacity="0" Background="#A0000000">
            <Border x:Name="OverlayPanel" Width="600" Padding="24" CornerRadius="22" Background="#0D141D" BorderBrush="#203447" BorderThickness="1" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Border.Effect><DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.35"/></Border.Effect>
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="18"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="20"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Border Width="44" Height="44" CornerRadius="14" Background="#112130" BorderBrush="#28445C" BorderThickness="1">
                            <TextBlock x:Name="OverlayIcon" Text="i" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="21" FontWeight="Bold" Foreground="#74E8FF"/>
                        </Border>
                        <StackPanel Grid.Column="1" Margin="14,0,0,0">
                            <TextBlock x:Name="OverlayTitle" Text="Titel" FontSize="22" FontWeight="SemiBold" Foreground="White"/>
                            <TextBlock x:Name="OverlaySub" Text="Ondertitel" Foreground="#8FA4B8" FontSize="12" Margin="0,4,0,0"/>
                        </StackPanel>
                        <Button x:Name="OverlayCloseBtnTop" Grid.Column="2" Content="✕" Style="{StaticResource SmallWindowButtonStyle}" Background="#1F2330"/>
                    </Grid>

                    <ScrollViewer Grid.Row="2" MaxHeight="450" VerticalScrollBarVisibility="Auto">
                        <Border CornerRadius="16" Background="#0A1018" BorderBrush="#1C2E40" BorderThickness="1" Padding="16">
                            <TextBlock x:Name="OverlayContent" TextWrapping="Wrap" Foreground="#DCE7F2" FontSize="14" LineHeight="20"/>
                        </Border>
                    </ScrollViewer>

                    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="OverlayActionBtn" Visibility="Collapsed" Style="{StaticResource ActionButtonStyle}" Width="140" Margin="0,0,10,0"/>
                        <Button x:Name="OverlayCloseBtn" Content="Sluiten" Style="{StaticResource ActionButtonStyle}" Background="#182434" Width="120" Margin="0"/>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
"@
#endregion

#region GUI element mapping
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Window buttons
$MinButton       = $window.FindName("MinButton")
$CloseButton     = $window.FindName("CloseButton")
$ExitButton      = $window.FindName("ExitButton")

# Nav buttons
$NavHome         = $window.FindName("NavHome")
$NavTools        = $window.FindName("NavTools")
$NavCmd          = $window.FindName("NavCmd")
$NavDownloads    = $window.FindName("NavDownloads")
$NavInfo         = $window.FindName("NavInfo")
$NavSettings     = $window.FindName("NavSettings")

# Home Big Buttons
$HomeBtnTools    = $window.FindName("HomeBtnTools")
$HomeBtnCmd      = $window.FindName("HomeBtnCmd")

# Pages
$PageHome        = $window.FindName("PageHome")
$PageTools       = $window.FindName("PageTools")
$PageCmd         = $window.FindName("PageCmd")
$PageDownloads   = $window.FindName("PageDownloads")
$PageInfo        = $window.FindName("PageInfo")
$PageSettings   = $window.FindName("PageSettings")
$ChkAnimations  = $window.FindName("ChkAnimations")
$null = Register-ObjectEvent -InputObject $ChkAnimations -EventName Click -Action {
    $script:Settings["AnimationsEnabled"] = $ChkAnimations.IsChecked
}

# Containers
$ToolsContainer  = $window.FindName("ToolsContainer")
$CmdContainer    = $window.FindName("CmdContainer")
$DownloadsContainer = $window.FindName("DownloadsContainer")

# Search
$SearchTools     = $window.FindName("SearchTools")
$SearchCmd       = $window.FindName("SearchCmd")

# Overlay
$OverlayRoot     = $window.FindName("OverlayRoot")
$OverlayTitle    = $window.FindName("OverlayTitle")
$OverlaySub      = $window.FindName("OverlaySub")
$OverlayContent  = $window.FindName("OverlayContent")
$OverlayIcon     = $window.FindName("OverlayIcon")
$OverlayCloseBtnTop = $window.FindName("OverlayCloseBtnTop")
$OverlayCloseBtn = $window.FindName("OverlayCloseBtn")
$OverlayActionBtn = $window.FindName("OverlayActionBtn")
#endregion

#region General helpers
function Refresh-Ui {
    $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

function Show-FadeElement {
    if (-not $script:Settings["AnimationsEnabled"]) {
        param($e); $e.Visibility = "Visible"; return
    }
    param([System.Windows.UIElement]$Element, [int]$DurationMs=180)
    $Element.Visibility = "Visible"
    if ($script:Settings.AnimationsEnabled) {
        $Element.Opacity = 0
        $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
        $animation.From = 0
        $animation.To = 1
        $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($DurationMs))
        $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animation)
    } else {
        $Element.Opacity = 1
        $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    }
}

function Hide-FadeElement {
    if (-not $script:Settings["AnimationsEnabled"]) {
        param($e); $e.Visibility = "Collapsed"; return
    }
    param([System.Windows.UIElement]$Element)
    $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $Element.Opacity = 0
    $Element.Visibility = "Collapsed"
}

function Show-Overlay {
    param([string]$Title, [string]$Sub, [string]$Content, [string]$Icon="i", [scriptblock]$Action=$null, [string]$ActionText="")
    $OverlayTitle.Text = $Title
    $OverlaySub.Text = $Sub
    $OverlayContent.Text = $Content
    $OverlayIcon.Text = $Icon
    
    if ($Action -ne $null) {
        $OverlayActionBtn.Visibility = "Visible"
        $OverlayActionBtn.Content = $ActionText
        # Remove old handlers to prevent memory leaks/duplicate fires
        $OverlayActionBtn.RemoveHandler([System.Windows.Controls.Button]::ClickEvent, $script:CurrentOverlayHandler)
        $script:CurrentOverlayHandler = [System.Windows.RoutedEventHandler]{ param($s,$e) & $Action; Hide-FadeElement $OverlayRoot }
        $OverlayActionBtn.Add_Click($script:CurrentOverlayHandler)
    } else {
        $OverlayActionBtn.Visibility = "Collapsed"
    }

    Show-FadeElement $OverlayRoot
}
#endregion

#region Navigation
function Switch-Page {
    param([System.Windows.UIElement]$TargetPage)
    $Pages = @($PageHome, $PageTools, $PageCmd, $PageDownloads, $PageInfo, $PageSettings)
    foreach ($p in $Pages) {
        if ($p -eq $TargetPage) {
            Show-FadeElement $p
        } else {
            Hide-FadeElement $p
        }
    }
}

$NavHome.Add_Click({ Switch-Page $PageHome })
$NavTools.Add_Click({ Switch-Page $PageTools })
$NavCmd.Add_Click({ Switch-Page $PageCmd })
$NavDownloads.Add_Click({ Switch-Page $PageDownloads })
$NavInfo.Add_Click({ Switch-Page $PageInfo })
$NavSettings.Add_Click({ Switch-Page $PageSettings })

$HomeBtnTools.Add_MouseLeftButtonUp({ Switch-Page $PageTools })
$HomeBtnCmd.Add_MouseLeftButtonUp({ Switch-Page $PageCmd })
#endregion

#region URL and domain validation
function Test-SafeUrl {
    param([string]$Url, [array]$AllowedDomains)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
    try {
        $uri = [System.Uri]::new($Url)
        if ($uri.Scheme -ne "https") { return $false }
        $hostMatch = $false
        foreach ($domain in $AllowedDomains) {
            if ($uri.Host -eq $domain -or $uri.Host.EndsWith(".$domain")) {
                $hostMatch = $true
                break
            }
        }
        return $hostMatch
    } catch {
        return $false
    }
}
#endregion

#region Download Engine (Async via Runspaces)
function Start-ToolDownload {
    param($Tool)

    if ($Tool.ActionType -ne "DirectDownload") {
        Show-Overlay "Geen directe download" $Tool.Name "Deze tool wordt niet ondersteund voor automatische download.`nOpen de website of GitHub releases."
        return
    }

    $Url = $Tool.DirectDownloadUrl
    if (-not (Test-SafeUrl $Url $Tool.AllowedDomains)) {
        Show-Overlay "Veiligheidsblokkade" "Ongeldig Domein" "De URL of het domein is niet toegestaan in de allowlist voor deze tool.`nURL: $Url" "×"
        return
    }

    $fileName = $Tool.DownloadFileName
    # Path traversal protectie
    if ($fileName -match "(\.\.|/|\\)") {
        Show-Overlay "Veiligheidsblokkade" "Ongeldige bestandsnaam" "Bestandsnaam bevat illegale tekens." "×"
        return
    }

    $finalPath = Join-Path $script:Settings.DownloadDir $fileName
    $partPath = $finalPath + ".part"

    if (Test-Path $finalPath) {
        Show-Overlay "Bestand bestaat al" $Tool.Name "Het bestand is al gedownload.`nKlaar om te starten of openen." "✓"
        return
    }

    if ($script:ActiveDownloads.ContainsKey($Tool.Id)) {
        Show-Overlay "Download loopt" $Tool.Name "Er is al een download actief voor deze tool." "i"
        return
    }

    # Runspace opzetten
    $ps = [powershell]::Create()
    $ps.RunspacePool = $script:RunspacePool
    [void]$ps.AddScript({
        param($Uri, $OutFilePart, $OutFileFinal)
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFilePart -UseBasicParsing -ErrorAction Stop
            Rename-Item -Path $OutFilePart -NewName (Split-Path $OutFileFinal -Leaf) -Force
            return "SUCCESS"
        } catch {
            if (Test-Path $OutFilePart) { Remove-Item $OutFilePart -Force -ErrorAction SilentlyContinue }
            return "ERROR: $_"
        }
    }).AddArgument($Url).AddArgument($partPath).AddArgument($finalPath)

    $asyncResult = $ps.BeginInvoke()
    
    $downloadObj = [PSCustomObject]@{
        Tool = $Tool
        PS = $ps
        AsyncResult = $asyncResult
        Status = "Downloading"
        UiElement = $null
    }
    
    $script:ActiveDownloads[$Tool.Id] = $downloadObj
    Render-Downloads
    Switch-Page $PageDownloads
}

$script:DownloadTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:DownloadTimer.Interval = [TimeSpan]::FromMilliseconds(500)
$script:DownloadTimer.Add_Tick({
    $completedKeys = @()
    foreach ($key in $script:ActiveDownloads.Keys) {
        $dl = $script:ActiveDownloads[$key]
        if ($dl.AsyncResult.IsCompleted) {
            try {
                $result = $dl.PS.EndInvoke($dl.AsyncResult)
                if ($result -eq "SUCCESS") {
                    $dl.Status = "Voltooid"
                } else {
                    $dl.Status = "Fout: $result"
                }
            } catch {
                $dl.Status = "Fout bij afronden"
            } finally {
                $dl.PS.Dispose()
            }
            $completedKeys += $key
            Render-Downloads # update UI
        }
    }
    # Verwijder ze niet uit de dictionary, verander status zodat we ze in de lijst houden
})
$script:DownloadTimer.Start()
#endregion

#region Tool rendering
function Get-ToolCardXaml {
    param($Name, $Category, $Icon, $Id)
    return @"
<Border Width="260" Height="140" Background="#101824" CornerRadius="18" BorderBrush="#1C2A3C" BorderThickness="1" Margin="0,0,15,15">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal">
            <TextBlock Text="$Icon" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#35D9FF" VerticalAlignment="Center"/>
            <TextBlock Text="$Name" FontSize="16" FontWeight="SemiBold" Foreground="White" Margin="10,0,0,0" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" MaxWidth="190"/>
        </StackPanel>
        <TextBlock Grid.Row="1" Text="$Category" Foreground="#8FA4B8" FontSize="12" Margin="30,2,0,0"/>
        
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button x:Name="InfoBtn_$Id" Tag="$Id" Content="i" Width="32" Height="32" CornerRadius="8" Background="#182434" Foreground="#74E8FF" FontSize="16" FontWeight="Bold" BorderThickness="0" Cursor="Hand" ToolTip="Informatie"/>
            <Button x:Name="ActionBtn_$Id" Tag="$Id" Grid.Column="1" Content="Actie" Height="32" Margin="10,0,0,0" Background="#1CCEF2" Foreground="#0A1018" FontWeight="SemiBold" BorderThickness="0" Cursor="Hand">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="8"/>
                    </Style>
                </Button.Resources>
            </Button>
        </Grid>
    </Grid>
</Border>
"@
}

function Render-Tools {
    param([string]$Filter = "")
    $ToolsContainer.Children.Clear()

    foreach ($tool in $script:Tools) {
        if ($Filter -ne "" -and $tool.Name -notmatch "(?i)$Filter" -and $tool.Description -notmatch "(?i)$Filter") { continue }
        
        $xamlStr = Get-ToolCardXaml -Name $tool.Name -Category $tool.Category -Icon $tool.Icon -Id $tool.Id
        $card = [Windows.Markup.XamlReader]::Parse($xamlStr)
        
        $infoBtn = $card.FindName("InfoBtn_$($tool.Id)")
        $actionBtn = $card.FindName("ActionBtn_$($tool.Id)")

        # Koppel i-knop
        $infoBtn.Add_Click({
            $tId = $this.Tag
            $t = $script:Tools | Where-Object { $_.Id -eq $tId }
            $infoText = "Maker: $($t.Author)`nVersie: $($t.Version)`nCategorie: $($t.Category)`n`nBeschrijving:`n$($t.Description)`n`nBron: $($t.OfficialWebsite)`nActietype: $($t.ActionType)`n`nCredits:`n$($t.Credits)"
            if ($t.Warning) { $infoText += "`n`nWAARSCHUWING: $($t.Warning)" }
            Show-Overlay -Title $t.Name -Sub "Tool Informatie" -Content $infoText -Icon "i"
        })

        # Bepaal Actie tekst
        if ($tool.ActionType -eq "DirectDownload") {
            $expectedPath = Join-Path $script:Settings.DownloadDir $tool.DownloadFileName
            if (Test-Path $expectedPath) {
                $actionBtn.Content = "Starten"
                $actionBtn.Background = "#4DDB8A"
            } else {
                $actionBtn.Content = "Downloaden"
            }
        } elseif ($tool.ActionType -eq "GitHubReleasePage" -or $tool.ActionType -eq "OfficialWebsite") {
            $actionBtn.Content = "Open Site"
        }

        # Koppel Actie-knop
        $actionBtn.Add_Click({
            $tId = $this.Tag
            $t = $script:Tools | Where-Object { $_.Id -eq $tId }
            
            if ($t.ActionType -eq "GitHubReleasePage") {
                if (Test-SafeUrl $t.GitHubReleasePage $t.AllowedDomains) {
                    Start-Process $t.GitHubReleasePage
                } else {
                    Show-Overlay "Blokkade" "Ongeldige URL" "De GitHub link is niet veilig bevonden." "×"
                }
            }
            elseif ($t.ActionType -eq "OfficialWebsite") {
                if (Test-SafeUrl $t.OfficialWebsite $t.AllowedDomains) {
                    Start-Process $t.OfficialWebsite
                }
            }
            elseif ($t.ActionType -eq "DirectDownload") {
                $expectedPath = Join-Path $script:Settings.DownloadDir $t.DownloadFileName
                if (Test-Path $expectedPath) {
                    # Starten flow
                    if ($script:Settings.ConfirmExecute) {
                        Show-Overlay "Bevestig Starten" "Code uitvoeren" "Weet je zeker dat je $($t.LaunchFileName) wilt starten?`n`nPad: $expectedPath" "!" {
                            Start-Process $expectedPath
                        } "Ja, Starten"
                    } else {
                        Start-Process $expectedPath
                    }
                } else {
                    # Download flow
                    Start-ToolDownload $t
                }
            }
        })

        $ToolsContainer.Children.Add($card) | Out-Null
    }
}
#endregion

#region Command rendering
function Get-CmdCardXaml {
    param($Name, $Category, $Shell, $Id)
    return @"
<Border Width="500" Background="#101824" CornerRadius="12" BorderBrush="#1C2A3C" BorderThickness="1" Margin="0,0,0,10" Padding="15">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel>
            <TextBlock Text="$Name" FontSize="16" FontWeight="SemiBold" Foreground="White"/>
            <StackPanel Orientation="Horizontal" Margin="0,4,0,0">
                <Border Background="#1A2B42" CornerRadius="4" Padding="6,2" Margin="0,0,8,0">
                    <TextBlock Text="$Shell" FontSize="11" Foreground="#74E8FF" FontWeight="Bold"/>
                </Border>
                <TextBlock Text="$Category" Foreground="#8FA4B8" FontSize="12" VerticalAlignment="Center"/>
            </StackPanel>
        </StackPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
            <Button x:Name="CmdInfo_$Id" Tag="$Id" Content="i" Width="30" Height="30" CornerRadius="8" Background="#182434" Foreground="#74E8FF" FontSize="16" FontWeight="Bold" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0"/>
            <Button x:Name="CmdCopy_$Id" Tag="$Id" Content="Kopiëren" Height="30" Background="#182434" Foreground="White" BorderThickness="1" BorderBrush="#203447" Cursor="Hand" Padding="10,0">
                 <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="6"/>
                    </Style>
                </Button.Resources>
            </Button>
        </StackPanel>
    </Grid>
</Border>
"@
}

function Render-Commands {
    param([string]$Filter = "")
    $CmdContainer.Children.Clear()

    foreach ($cmd in $script:Commands) {
        if ($Filter -ne "" -and $cmd.Name -notmatch "(?i)$Filter" -and $cmd.Description -notmatch "(?i)$Filter" -and $cmd.Command -notmatch "(?i)$Filter") { continue }

        $xamlStr = Get-CmdCardXaml -Name $cmd.Name -Category $cmd.Category -Shell $cmd.Shell -Id $cmd.Id
        $card = [Windows.Markup.XamlReader]::Parse($xamlStr)
        
        $infoBtn = $card.FindName("CmdInfo_$($cmd.Id)")
        $copyBtn = $card.FindName("CmdCopy_$($cmd.Id)")

        $infoBtn.Add_Click({
            $cId = $this.Tag
            $c = $script:Commands | Where-Object { $_.Id -eq $cId }
            $infoText = "Commando:`n$($c.Command)`n`nShell: $($c.Shell)`nCategorie: $($c.Category)`n`nUitleg:`n$($c.Explanation)`n`nVoorbeeld:`n$($c.Example)"
            if ($c.RequiresAdministrator) { $infoText += "`n`nVEREIST ADMINISTRATORRECHTEN" }
            if ($c.Warning) { $infoText += "`n`nWAARSCHUWING: $($c.Warning)" }
            
            $act = $null
            $actText = ""
            if ($c.AllowExecution -and -not $script:Settings.SafeMode) {
                $actText = "Uitvoeren"
                $act = {
                    Show-Overlay "Bevestig Uitvoeren" "Veiligheidswaarschuwing" "Weet je zeker dat je dit wilt uitvoeren?`n`n$($c.Command)" "!" {
                        if ($c.Shell -eq "CMD") { Start-Process "cmd.exe" -ArgumentList "/c $($c.Command)" }
                        else { Start-Process "powershell.exe" -ArgumentList "-NoProfile -Command $($c.Command)" }
                    } "Bevestig & Voer uit"
                }
            }

            Show-Overlay -Title $c.Name -Sub "Commando Detail" -Content $infoText -Icon "i" -Action $act -ActionText $actText
        })

        $copyBtn.Add_Click({
            $cId = $this.Tag
            $c = $script:Commands | Where-Object { $_.Id -eq $cId }
            [System.Windows.Clipboard]::SetText($c.Command)
            $this.Content = "Gekopieerd!"
            $this.Foreground = "#4DDB8A"
        })

        $CmdContainer.Children.Add($card) | Out-Null
    }
}
#endregion

#region Downloads rendering
function Get-DownloadCardXaml {
    param($Name, $Status, $File)
    return @"
<Border Width="500" Background="#101824" CornerRadius="12" BorderBrush="#1C2A3C" BorderThickness="1" Margin="0,0,0,10" Padding="15" HorizontalAlignment="Left">
    <Grid>
        <StackPanel>
            <TextBlock Text="$Name" FontSize="16" FontWeight="SemiBold" Foreground="White"/>
            <TextBlock Text="$File" Foreground="#8FA4B8" FontSize="12" Margin="0,2,0,0"/>
            <TextBlock Text="Status: $Status" Foreground="#74E8FF" FontSize="12" Margin="0,4,0,0"/>
        </StackPanel>
    </Grid>
</Border>
"@
}

function Render-Downloads {
    $DownloadsContainer.Children.Clear()
    if ($script:ActiveDownloads.Count -eq 0) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "Geen actieve of voltooide downloads in deze sessie."
        $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#8FA4B8")
        $DownloadsContainer.Children.Add($tb) | Out-Null
        return
    }

    foreach ($key in $script:ActiveDownloads.Keys) {
        $dl = $script:ActiveDownloads[$key]
        $xamlStr = Get-DownloadCardXaml -Name $dl.Tool.Name -Status $dl.Status -File $dl.Tool.DownloadFileName
        $card = [Windows.Markup.XamlReader]::Parse($xamlStr)
        $DownloadsContainer.Children.Add($card) | Out-Null
    }
}
#endregion

#region Search and Filtering
$SearchTools.Add_TextChanged({ Render-Tools $SearchTools.Text })
$SearchCmd.Add_TextChanged({ Render-Commands $SearchCmd.Text })
#endregion

#region Dialogs and Overlays
$OverlayCloseBtnTop.Add_Click({ Hide-FadeElement $OverlayRoot })
$OverlayCloseBtn.Add_Click({ Hide-FadeElement $OverlayRoot })
#endregion

#region Window Drag and Window Controls
$window.Add_MouseLeftButtonDown({
    try { $window.DragMove() } catch {}
})
$MinButton.Add_Click({ $window.WindowState = "Minimized" })
$CloseButton.Add_Click({ $window.Close() })
$ExitButton.Add_Click({ $window.Close() })
#endregion

#region Cleanup
$window.Add_Closing({
    $result = [System.Windows.MessageBox]::Show("Weet je zeker dat je wilt afsluiten?", "TeslaPro Tools", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($result -ne [System.Windows.MessageBoxResult]::Yes) { $_.Cancel = $true; return }
    # Stop timer and clean up runspaces
    $script:DownloadTimer.Stop()
    if ($script:RunspacePool) {
        $script:RunspacePool.Dispose()
    }
})
#endregion

#region Application startup
Render-Tools
Render-Commands
Render-Downloads
$window.ShowDialog() | Out-Null
#endregion