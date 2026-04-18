Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.IO.Compression.FileSystem

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "3.3"

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Tesla Launcher"
    Width="1320"
    Height="830"
    MinWidth="1320"
    MinHeight="830"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    FontFamily="Segoe UI"
    Opacity="1">

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

        <LinearGradientBrush x:Key="DangerButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#3A2028" Offset="0"/>
            <GradientStop Color="#24151A" Offset="1"/>
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
                        <Border x:Name="Root"
                                Background="{TemplateBinding Background}"
                                CornerRadius="17"
                                BorderBrush="#203040"
                                BorderThickness="1">
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="18" ShadowDepth="0" Opacity="0.22"/>
                            </Border.Effect>

                            <Grid Margin="16,0,16,0">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="12"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <Border Width="36"
                                        Height="36"
                                        CornerRadius="11"
                                        Background="#18FFFFFF"
                                        BorderBrush="#24FFFFFF"
                                        BorderThickness="1"
                                        VerticalAlignment="Center">
                                    <TextBlock Text="{TemplateBinding Tag}"
                                               FontFamily="Segoe MDL2 Assets"
                                               FontSize="15"
                                               Foreground="White"
                                               HorizontalAlignment="Center"
                                               VerticalAlignment="Center"/>
                                </Border>

                                <ContentPresenter Grid.Column="2"
                                                  VerticalAlignment="Center"
                                                  RecognizesAccessKey="True"/>
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
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <Style x:Key="MiniStatStyle" TargetType="Border">
            <Setter Property="CornerRadius" Value="20"/>
            <Setter Property="Padding" Value="18"/>
            <Setter Property="Background" Value="{StaticResource CardBackground}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrushSoft}"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Border CornerRadius="24" Background="{StaticResource WindowBackground}" BorderBrush="#1D2938" BorderThickness="1">
            <Border.Effect>
                <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.45"/>
            </Border.Effect>

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
                                <TextBlock Text="Tesla Launcher" FontSize="18" FontWeight="SemiBold" Foreground="White"/>
                                <TextBlock Text="TeslaPro SS Tools" FontSize="11" Foreground="#7E92A6" Margin="0,2,0,0"/>
                            </StackPanel>
                        </StackPanel>

                        <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                            <Button x:Name="InfoButtonTop" Content="ⓘ" Style="{StaticResource SmallWindowButtonStyle}" Background="#163043"/>
                            <Button x:Name="MinButton" Content="—" Style="{StaticResource SmallWindowButtonStyle}"/>
                            <Button x:Name="CloseButton" Content="✕" Style="{StaticResource SmallWindowButtonStyle}" Background="#1F2330"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <Grid Grid.Row="1" Margin="20">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="300"/>
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
                                <TextBlock Text="Control Center" FontSize="24" FontWeight="SemiBold" Foreground="White"/>
                                <TextBlock Text="Install, update or remove the TeslaPro toolkit from one clean window." TextWrapping="Wrap" Margin="0,8,0,0" Foreground="#8EA2B6" FontSize="13"/>
                            </StackPanel>

                            <StackPanel Grid.Row="2">
                                <Button x:Name="InstallButton"
                                        Tag="&#xE898;"
                                        Content="Install / Update Tools"
                                        Style="{StaticResource ActionButtonStyle}"
                                        Background="{StaticResource PrimaryButtonBrush}"/>

                                <Button x:Name="DeleteButton"
                                        Tag="&#xE74D;"
                                        Content="Remove Installed Tools"
                                        Style="{StaticResource ActionButtonStyle}"
                                        Background="{StaticResource DangerButtonBrush}"/>

                                <Button x:Name="OpenFolderButton"
                                        Tag="&#xE838;"
                                        Content="Open Install Folder"
                                        Style="{StaticResource ActionButtonStyle}"
                                        Background="#182434"/>

                                <Button x:Name="CmdCommandsButton"
                                        Tag="&#xE756;"
                                        Content="CMD Commands"
                                        Style="{StaticResource ActionButtonStyle}"
                                        Background="#182434"/>

                                <Button x:Name="ExitButton"
                                        Tag="&#xE8BB;"
                                        Content="Exit Launcher"
                                        Style="{StaticResource ActionButtonStyle}"
                                        Background="#141C28"/>
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
                                                <TextBlock Text="Launcher Version" Foreground="#7A92A8" FontSize="11"/>
                                                <TextBlock x:Name="VersionText" Text="Version 3.3" Foreground="#74E8FF" FontSize="16" FontWeight="Bold" Margin="0,4,0,0"/>
                                            </StackPanel>

                                            <Border Grid.Column="1" Width="110" Height="30" CornerRadius="15" Background="#122232" BorderBrush="#234760" BorderThickness="1" VerticalAlignment="Center">
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
                            <RowDefinition Height="165"/>
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
                                    <TextBlock x:Name="StatusText" Text="Ready" FontSize="30" FontWeight="SemiBold" Foreground="White"/>
                                    <TextBlock x:Name="SubStatusText" Text="Everything is ready. Pick an action on the left." Margin="0,8,0,0" FontSize="14" Foreground="#9DB1C4"/>
                                    <Border Margin="0,18,0,0" CornerRadius="14" Background="#0B121B" Padding="12" BorderBrush="#1A293A" BorderThickness="1">
                                        <TextBlock Text="A cleaner and sharper launcher for TeslaPro SS Tools." Foreground="#84A1BA" TextWrapping="Wrap"/>
                                    </Border>
                                </StackPanel>

                                <Border Grid.Column="1" HorizontalAlignment="Right" Width="260" Height="110" CornerRadius="22" Background="#0B1119" BorderBrush="#1E3145" BorderThickness="1">
                                    <Grid Margin="16">
                                        <Grid.RowDefinitions>
                                            <RowDefinition Height="Auto"/>
                                            <RowDefinition Height="*"/>
                                        </Grid.RowDefinitions>
                                        <TextBlock Text="Launcher Status" Foreground="#7990A5" FontSize="12"/>
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

                            <Border Grid.Column="0" Style="{StaticResource MiniStatStyle}">
                                <StackPanel>
                                    <TextBlock Text="Step" FontSize="12" Foreground="#7C93A8"/>
                                    <TextBlock x:Name="StepText" Text="Waiting" FontSize="22" FontWeight="SemiBold" Foreground="White" Margin="0,8,0,0"/>
                                    <TextBlock Text="Current launcher task." Margin="0,6,0,0" Foreground="#8DA3B7" FontSize="12"/>
                                </StackPanel>
                            </Border>

                            <Border Grid.Column="2" Style="{StaticResource MiniStatStyle}">
                                <StackPanel>
                                    <TextBlock Text="Progress" FontSize="12" Foreground="#7C93A8"/>
                                    <TextBlock x:Name="ProgressLabel" Text="0%" FontSize="22" FontWeight="SemiBold" Foreground="White" Margin="0,8,0,0"/>
                                    <TextBlock Text="Overall progress." Margin="0,6,0,0" Foreground="#8DA3B7" FontSize="12"/>
                                </StackPanel>
                            </Border>

                            <Border Grid.Column="4" Style="{StaticResource MiniStatStyle}">
                                <StackPanel>
                                    <TextBlock Text="Detected Tools" FontSize="12" Foreground="#7C93A8"/>
                                    <TextBlock x:Name="ToolCountText" Text="0" FontSize="22" FontWeight="SemiBold" Foreground="White" Margin="0,8,0,0"/>
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
                                        <TextBlock Text="Activity Console" FontSize="22" FontWeight="SemiBold" Foreground="White"/>
                                        <TextBlock Text="Installer output and current status" Foreground="#91A7BB" FontSize="12" Margin="0,6,0,0"/>
                                    </StackPanel>

                                    <Border Grid.Column="1" Width="140" Height="34" HorizontalAlignment="Right" VerticalAlignment="Top" CornerRadius="17" Background="#0B121B" BorderBrush="#203447" BorderThickness="1">
                                        <TextBlock x:Name="MiniStateText" Text="READY" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#74E8FF" FontWeight="Bold"/>
                                    </Border>
                                </Grid>

                                <Border Grid.Row="2" CornerRadius="8" Background="#091018" BorderBrush="#1A2B3C" BorderThickness="1">
                                    <ProgressBar x:Name="MainProgressBar" Height="12" Minimum="0" Maximum="100" Value="0" Background="Transparent" Foreground="#22D6FF" BorderThickness="0"/>
                                </Border>

                                <Border Grid.Row="4"
                                        CornerRadius="18"
                                        Background="#091018"
                                        BorderBrush="#1A2B3C"
                                        BorderThickness="1"
                                        Padding="14">
                                    <TextBox x:Name="ActivityBox"
                                             Background="Transparent"
                                             Foreground="#D8E8F5"
                                             BorderThickness="0"
                                             FontFamily="Consolas"
                                             FontSize="13"
                                             IsReadOnly="True"
                                             VerticalScrollBarVisibility="Auto"
                                             HorizontalScrollBarVisibility="Disabled"
                                             TextWrapping="Wrap"
                                             AcceptsReturn="True"/>
                                </Border>
                            </Grid>
                        </Border>
                    </Grid>
                </Grid>
            </Grid>
        </Border>

        <Grid x:Name="InfoRoot" Visibility="Collapsed" Opacity="0" Background="#A0000000">
            <Border Width="620" Padding="24" CornerRadius="22" Background="#0D141D" BorderBrush="#203447" BorderThickness="1" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Border.Effect>
                    <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.35"/>
                </Border.Effect>
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
                            <TextBlock Text="i" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="21" FontWeight="Bold" Foreground="#74E8FF"/>
                        </Border>

                        <StackPanel Grid.Column="1" Margin="14,0,0,0">
                            <TextBlock Text="About This Launcher" FontSize="22" FontWeight="SemiBold" Foreground="White"/>
                            <TextBlock Text="Tesla Launcher information" Foreground="#8FA4B8" FontSize="12" Margin="0,4,0,0"/>
                        </StackPanel>

                        <Button x:Name="InfoCloseButton" Grid.Column="2" Content="✕" Width="34" Height="34" Style="{StaticResource SmallWindowButtonStyle}" Background="#1F2330"/>
                    </Grid>

                    <StackPanel Grid.Row="2">
                        <Border CornerRadius="16" Background="#0A1018" BorderBrush="#1C2E40" BorderThickness="1" Padding="16">
                            <TextBlock TextWrapping="Wrap" Foreground="#DCE7F2" FontSize="13">
This launcher was made by TeslaPro.

If you find a bug or if you have any questions, you can always send a message on Discord:
@teamwsf

These tools may only be used with TeslaPro's permission.
                            </TextBlock>
                        </Border>
                    </StackPanel>

                    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="InfoOkButton"
                                Tag="&#xE73E;"
                                Content="Close"
                                Style="{StaticResource ActionButtonStyle}"
                                Background="{StaticResource PrimaryButtonBrush}"
                                Width="140"
                                Margin="0"/>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>

        <Grid x:Name="PopupRoot" Visibility="Collapsed" Opacity="0" Background="#A0000000">
            <Border Width="520"
                    Padding="22"
                    CornerRadius="22"
                    Background="#0D141D"
                    BorderBrush="#203447"
                    BorderThickness="1"
                    HorizontalAlignment="Center"
                    VerticalAlignment="Center">
                <Border.Effect>
                    <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.35"/>
                </Border.Effect>

                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="16"/>
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
                            <TextBlock x:Name="PopupIconText"
                                       Text="i"
                                       HorizontalAlignment="Center"
                                       VerticalAlignment="Center"
                                       FontSize="20"
                                       FontWeight="Bold"
                                       Foreground="#74E8FF"/>
                        </Border>

                        <StackPanel Grid.Column="1" Margin="14,0,0,0">
                            <TextBlock x:Name="PopupTitleText"
                                       Text="Message"
                                       FontSize="22"
                                       FontWeight="SemiBold"
                                       Foreground="White"/>
                            <TextBlock x:Name="PopupSubtitleText"
                                       Text="Tesla Launcher"
                                       Foreground="#8FA4B8"
                                       FontSize="12"
                                       Margin="0,4,0,0"/>
                        </StackPanel>

                        <Button x:Name="PopupCloseButton"
                                Grid.Column="2"
                                Content="✕"
                                Width="34"
                                Height="34"
                                Style="{StaticResource SmallWindowButtonStyle}"
                                Background="#1F2330"/>
                    </Grid>

                    <Border Grid.Row="2"
                            CornerRadius="16"
                            Background="#0A1018"
                            BorderBrush="#1C2E40"
                            BorderThickness="1"
                            Padding="16">
                        <TextBlock x:Name="PopupMessageText"
                                   TextWrapping="Wrap"
                                   Foreground="#DCE7F2"
                                   FontSize="13"
                                   Text="Message goes here."/>
                    </Border>

                    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="PopupOkButton"
                                Tag="&#xE73E;"
                                Content="OK"
                                Style="{StaticResource ActionButtonStyle}"
                                Background="{StaticResource PrimaryButtonBrush}"
                                Width="130"
                                Margin="0"/>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$InstallButton      = $window.FindName("InstallButton")
$DeleteButton       = $window.FindName("DeleteButton")
$OpenFolderButton   = $window.FindName("OpenFolderButton")
$CmdCommandsButton  = $window.FindName("CmdCommandsButton")
$ExitButton         = $window.FindName("ExitButton")
$CloseButton        = $window.FindName("CloseButton")
$MinButton          = $window.FindName("MinButton")
$InfoButtonTop      = $window.FindName("InfoButtonTop")

$StatusText         = $window.FindName("StatusText")
$SubStatusText      = $window.FindName("SubStatusText")
$StateChip          = $window.FindName("StateChip")
$BigChipText        = $window.FindName("BigChipText")
$MiniStateText      = $window.FindName("MiniStateText")
$FooterText         = $window.FindName("FooterText")
$StepText           = $window.FindName("StepText")
$ProgressLabel      = $window.FindName("ProgressLabel")
$ToolCountText      = $window.FindName("ToolCountText")
$MainProgressBar    = $window.FindName("MainProgressBar")
$LocationText       = $window.FindName("LocationText")
$VersionText        = $window.FindName("VersionText")
$ActivityBox        = $window.FindName("ActivityBox")

$InfoRoot           = $window.FindName("InfoRoot")
$InfoCloseButton    = $window.FindName("InfoCloseButton")
$InfoOkButton       = $window.FindName("InfoOkButton")

$PopupRoot          = $window.FindName("PopupRoot")
$PopupCloseButton   = $window.FindName("PopupCloseButton")
$PopupOkButton      = $window.FindName("PopupOkButton")
$PopupTitleText     = $window.FindName("PopupTitleText")
$PopupSubtitleText  = $window.FindName("PopupSubtitleText")
$PopupMessageText   = $window.FindName("PopupMessageText")
$PopupIconText      = $window.FindName("PopupIconText")

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
    catch {
        return $false
    }
}

function Show-FadeElement {
    param([System.Windows.UIElement]$Element,[int]$DurationMs=180)
    $Element.Visibility = "Visible"
    $Element.Opacity = 0
    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animation.From = 0
    $animation.To = 1
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($DurationMs))
    $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animation)
}

function Hide-FadeElement {
    param([System.Windows.UIElement]$Element)
    $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $Element.Opacity = 0
    $Element.Visibility = "Collapsed"
}

function Set-ProgressAnimated {
    param([double]$Value,[int]$DurationMs=220)
    if ($Value -lt 0) { $Value = 0 }
    if ($Value -gt 100) { $Value = 100 }

    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animation.To = $Value
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($DurationMs))
    $animation.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
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
    $StateChip.Text = $Chip.ToUpper()
    $BigChipText.Text = $Chip.ToUpper()
    $MiniStateText.Text = $Chip.ToUpper()
    $FooterText.Text = $Title
    $StepText.Text = $Step
    $ProgressLabel.Text = ("{0}%" -f [int]$Progress)
    Set-ProgressAnimated $Progress
    Refresh-Ui
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $InstallButton.IsEnabled = $Enabled
    $DeleteButton.IsEnabled = $Enabled
    $OpenFolderButton.IsEnabled = $Enabled
    $CmdCommandsButton.IsEnabled = $Enabled
    $ExitButton.IsEnabled = $Enabled
    Refresh-Ui
}

function Write-Activity {
    param([string]$Text)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $ActivityBox.AppendText("[$timestamp] $Text`r`n")
    $ActivityBox.ScrollToEnd()
    Refresh-Ui
}

function Show-AppMessage {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")]
        [string]$Type = "Info"
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "Unknown error."
    }

    $PopupTitleText.Text = $Title
    $PopupSubtitleText.Text = "Tesla Launcher"
    $PopupMessageText.Text = $Message

    switch ($Type) {
        "Info"    { $PopupIconText.Text = "i"; $PopupIconText.Foreground = "#74E8FF" }
        "Success" { $PopupIconText.Text = "✓"; $PopupIconText.Foreground = "#4DDB8A" }
        "Warning" { $PopupIconText.Text = "!"; $PopupIconText.Foreground = "#FFC857" }
        "Error"   { $PopupIconText.Text = "×"; $PopupIconText.Foreground = "#FF6B6B" }
    }

    Show-FadeElement -Element $PopupRoot -DurationMs 180
}

function Hide-AppMessage {
    Hide-FadeElement -Element $PopupRoot
}

function Show-InfoOverlay {
    Show-FadeElement -Element $InfoRoot -DurationMs 180
}

function Hide-InfoOverlay {
    Hide-FadeElement -Element $InfoRoot
}

function Show-AdminRequiredState {
    Set-UiState `
        "Administrator required" `
        "This launcher must be started with Run as administrator before install, remove, or command actions can be used." `
        "Blocked" `
        "Admin Required" `
        0

    $ToolCountText.Text = "0"
    Write-Activity "Launcher started without administrator rights."
    Write-Activity "Run this launcher as Administrator to unlock all actions."

    $InstallButton.IsEnabled = $false
    $DeleteButton.IsEnabled = $false
    $OpenFolderButton.IsEnabled = $false
    $CmdCommandsButton.IsEnabled = $false
    Refresh-Ui
}

function Ask-Confirm {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Question","Warning","Danger")]
        [string]$Type = "Question"
    )

    [xml]$confirmXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Confirm"
    Width="540"
    Height="260"
    WindowStartupLocation="CenterOwner"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    ShowInTaskbar="False"
    FontFamily="Segoe UI">

    <Border CornerRadius="22"
            Background="#0D141D"
            BorderBrush="#203447"
            BorderThickness="1"
            Padding="22">
        <Border.Effect>
            <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.35"/>
        </Border.Effect>

        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="16"/>
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

                <Border Width="44"
                        Height="44"
                        CornerRadius="14"
                        Background="#112130"
                        BorderBrush="#28445C"
                        BorderThickness="1">
                    <TextBlock x:Name="IconText"
                               Text="?"
                               HorizontalAlignment="Center"
                               VerticalAlignment="Center"
                               FontSize="20"
                               FontWeight="Bold"
                               Foreground="#FFC857"/>
                </Border>

                <StackPanel Grid.Column="1" Margin="14,0,0,0">
                    <TextBlock x:Name="DialogTitle"
                               Text="Please Confirm"
                               FontSize="22"
                               FontWeight="SemiBold"
                               Foreground="White"/>
                    <TextBlock Text="Tesla Launcher"
                               Foreground="#8FA4B8"
                               FontSize="12"
                               Margin="0,4,0,0"/>
                </StackPanel>

                <Button x:Name="CloseBtn"
                        Grid.Column="2"
                        Content="✕"
                        Width="34"
                        Height="34"
                        Margin="8,0,0,0"
                        Foreground="White"
                        FontSize="16"
                        FontWeight="Bold"
                        Background="#1F2330"
                        BorderThickness="0"
                        Cursor="Hand"/>
            </Grid>

            <Border Grid.Row="2"
                    CornerRadius="16"
                    Background="#0A1018"
                    BorderBrush="#1C2E40"
                    BorderThickness="1"
                    Padding="16">
                <TextBlock x:Name="DialogMessage"
                           TextWrapping="Wrap"
                           Foreground="#DCE7F2"
                           FontSize="13"
                           Text="Confirmation text goes here."/>
            </Border>

            <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="NoBtn"
                        Content="Cancel"
                        Width="140"
                        Height="46"
                        Margin="0,0,12,0"
                        Foreground="White"
                        FontSize="14"
                        FontWeight="SemiBold"
                        Background="#172231"
                        BorderThickness="0"
                        Cursor="Hand"/>

                <Button x:Name="YesBtn"
                        Content="Continue"
                        Width="150"
                        Height="46"
                        Foreground="White"
                        FontSize="14"
                        FontWeight="SemiBold"
                        Background="#1CCEF2"
                        BorderThickness="0"
                        Cursor="Hand"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $confirmXaml
    $dialog = [Windows.Markup.XamlReader]::Load($reader)

    $DialogTitle   = $dialog.FindName("DialogTitle")
    $DialogMessage = $dialog.FindName("DialogMessage")
    $IconText      = $dialog.FindName("IconText")
    $CloseBtn      = $dialog.FindName("CloseBtn")
    $NoBtn         = $dialog.FindName("NoBtn")
    $YesBtn        = $dialog.FindName("YesBtn")

    $DialogTitle.Text   = $Title
    $DialogMessage.Text = $Message

    switch ($Type) {
        "Question" {
            $IconText.Text = "?"
            $IconText.Foreground = "#FFC857"
        }
        "Warning" {
            $IconText.Text = "!"
            $IconText.Foreground = "#FFC857"
        }
        "Danger" {
            $IconText.Text = "!"
            $IconText.Foreground = "#FF6B6B"
            $YesBtn.Background = "#1CCEF2"
        }
    }

    $dialog.Owner = $window
    $script:DialogResultValue = $false

    $dialog.Add_MouseLeftButtonDown({
        try { $dialog.DragMove() } catch {}
    })

    $CloseBtn.Add_Click({
        $script:DialogResultValue = $false
        $dialog.Close()
    })

    $NoBtn.Add_Click({
        $script:DialogResultValue = $false
        $dialog.Close()
    })

    $YesBtn.Add_Click({
        $script:DialogResultValue = $true
        $dialog.Close()
    })

    $dialog.Add_PreviewKeyDown({
        param($sender, $e)
        if ($e.Key -eq "Escape") {
            $script:DialogResultValue = $false
            $dialog.Close()
            $e.Handled = $true
        }
        elseif ($e.Key -eq "Enter") {
            $script:DialogResultValue = $true
            $dialog.Close()
            $e.Handled = $true
        }
    })

    $dialog.ShowDialog() | Out-Null
    return $script:DialogResultValue
}

function Update-ToolCount {
    try {
        if (Test-Path $dest) {
            $tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe -ErrorAction SilentlyContinue
            $ToolCountText.Text = (($tools | Measure-Object).Count).ToString()
        }
        else {
            $ToolCountText.Text = "0"
        }
    }
    catch {
        $ToolCountText.Text = "0"
    }
}

function Apply-StartupState {
    if (-not (Test-IsAdministrator)) {
        Show-AdminRequiredState
        return
    }

    if (Test-Path $dest) {
        Update-ToolCount
        if ([int]$ToolCountText.Text -gt 0) {
            Set-UiState "Installed" "The toolkit is already present on this system." "Installed" "Ready" 100
        }
        else {
            Set-UiState "Folder detected" "An install folder exists, but no executable tools were found." "Detected" "Review" 25
        }
    }
    else {
        Update-ToolCount
        Set-UiState "Ready" "Everything is ready. Pick an action on the left." "Idle" "Waiting" 0
    }
}

function Safe-RemovePath {
    param([string]$Path)

    if (!(Test-Path $Path)) { return }

    $maxAttempts = 4
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            Remove-Item $Path -Recurse -Force -ErrorAction Stop
            return
        }
        catch {
            if ($i -eq $maxAttempts) {
                throw
            }
            Start-Sleep -Milliseconds 500
        }
    }
}

function Download-File {
    param(
        [string]$SourceUrl,
        [string]$OutFile
    )

    $client = New-Object System.Net.WebClient
    try {
        $client.Headers.Add("User-Agent", "TeslaLauncher/$version")
        $client.DownloadFile($SourceUrl, $OutFile)
    }
    finally {
        $client.Dispose()
    }
}

function Extract-Zip {
    param(
        [string]$ZipPath,
        [string]$Destination
    )

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

function Start-Install {
    if (-not (Test-IsAdministrator)) {
        Show-AdminRequiredState
        Show-AppMessage "Administrator Required" "This action requires Run as administrator." "Error"
        return
    }

    try {
        if (Test-Path $dest) {
            $overwrite = Ask-Confirm "Replace existing install?" "An existing install was found.`n`nDo you want to replace it?" "Question"
            if (-not $overwrite) {
                Set-UiState "Install cancelled" "The current install was left unchanged." "Cancelled" "Stopped" 0
                Write-Activity "Install cancelled by user."
                return
            }
        }

        Set-ButtonsEnabled $false
        $ToolCountText.Text = "0"
        $ActivityBox.Clear()

        Set-UiState "Checking system" "Making sure everything is ready." "Checking" "System Check" 10
        Write-Activity "Running system checks..."

        if ($env:OS -ne "Windows_NT") { throw "This launcher only works on Windows." }
        if ($PSVersionTable.PSVersion.Major -lt 5) { throw "PowerShell 5.0 or newer is required." }
        if (!(Test-Path $downloads)) { throw "The Downloads folder was not found." }

        $testFile = Join-Path $downloads "teslapro_write_test.tmp"
        "test" | Out-File $testFile -Force
        Remove-Item $testFile -Force

        $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
        $drive = Get-PSDrive -Name $driveName -ErrorAction Stop
        if ($drive.Free -lt 100MB) { throw "Not enough free disk space. At least 100 MB is required." }

        Write-Activity "System checks passed."

        Set-UiState "Downloading package" "Getting the latest TeslaPro release." "Downloading" "Download" 35

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
            Write-Activity "Old ZIP removed."
        }

        Download-File -SourceUrl $url -OutFile $zip

        if (!(Test-Path $zip)) { throw "The ZIP file was not created after download." }

        $zipItem = Get-Item $zip -ErrorAction Stop
        if ($zipItem.Length -lt 1000) { throw "The downloaded ZIP looks invalid or corrupted." }

        Write-Activity ("Download complete: {0:N2} MB" -f ($zipItem.Length / 1MB))

        Set-UiState "Installing files" "Unpacking the toolkit and preparing the folder." "Installing" "Extracting" 68

        if (Test-Path $dest) {
            Safe-RemovePath $dest
            Write-Activity "Previous install removed."
        }

        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Extract-Zip -ZipPath $zip -Destination $dest

        $items = Get-ChildItem -Path $dest -Recurse -Force -ErrorAction Stop
        $count = ($items | Measure-Object).Count
        if ($count -eq 0) { throw "The install folder is empty after extraction." }

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
        }

        Update-ToolCount
        Write-Activity "Extracted items: $count"
        Write-Activity "Detected tools: $($ToolCountText.Text)"

        Set-UiState "Install complete" "Everything looks good and the tools are ready." "Installed" "Done" 100

        try {
            Start-Process $dest
            Write-Activity "Install folder opened automatically."
        }
        catch {
            Write-Activity "Install folder could not be opened automatically."
        }

        Show-AppMessage "Install Complete" "TeslaPro SS Tools were installed successfully." "Success"
    }
    catch {
        $message = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { ($_ | Out-String).Trim() }
        if ([string]::IsNullOrWhiteSpace($message)) { $message = "Unknown install error." }

        Set-UiState "Install failed" $message "Error" "Failed" 0
        Write-Activity "Install failed: $message"
        Show-AppMessage "Install Failed" $message "Error"
    }
    finally {
        if (Test-IsAdministrator) {
            Set-ButtonsEnabled $true
        }
    }
}

function Start-Remove {
    if (-not (Test-IsAdministrator)) {
        Show-AdminRequiredState
        Show-AppMessage "Administrator Required" "This action requires Run as administrator." "Error"
        return
    }

    try {
        if (!(Test-Path $dest)) {
            Set-UiState "Nothing to remove" "No install was found on this system." "Idle" "Waiting" 0
            Update-ToolCount
            Write-Activity "No installation found."
            return
        }

        $confirm = Ask-Confirm "Remove installed tools?" "This will remove TeslaPro SS Tools from:`n`n$dest`n`nContinue?" "Danger"
        if (-not $confirm) {
            Set-UiState "Removal cancelled" "No files were removed." "Cancelled" "Stopped" 0
            Write-Activity "Removal cancelled by user."
            return
        }

        Set-ButtonsEnabled $false
        $ActivityBox.Clear()

        Set-UiState "Removing files" "Cleaning up the installed toolkit." "Removing" "Removal" 40

        Safe-RemovePath $dest
        Write-Activity "Install folder removed."

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
            Write-Activity "Temporary ZIP removed."
        }

        Update-ToolCount
        $ToolCountText.Text = "0"

        Set-UiState "Removal complete" "The installed files were removed successfully." "Removed" "Done" 100
        Write-Activity "Removal completed successfully."

        Show-AppMessage "Removal Complete" "TeslaPro SS Tools were removed successfully." "Success"
    }
    catch {
        $message = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { ($_ | Out-String).Trim() }
        if ([string]::IsNullOrWhiteSpace($message)) { $message = "Unknown removal error." }

        Set-UiState "Removal failed" $message "Error" "Failed" 0
        Write-Activity "Removal failed: $message"
        Show-AppMessage "Removal Failed" $message "Error"
    }
    finally {
        if (Test-IsAdministrator) {
            Set-ButtonsEnabled $true
        }
    }
}

function Start-CmdCommands {
    if (-not (Test-IsAdministrator)) {
        Show-AdminRequiredState
        Show-AppMessage "Administrator Required" "CMD Commands requires administrator rights. Close this launcher and run it as Administrator." "Error"
        return
    }

    try {
        Set-ButtonsEnabled $false

        Set-UiState "Launching command" "Starting TeslaControlPannel..." "Running" "Command" 60
        Write-Activity "Launching TeslaControlPannel from GitHub..."

        $remoteCmd = "iex (irm 'https://raw.githubusercontent.com/TeslaPros/TeslaControlPannel/main/TeslaControlPannel.ps1')"
        
        # AANPASSING: Toegevoegd -WindowStyle Hidden om het blauwe venster te verbergen
        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden",
            "-Command", $remoteCmd
        )

        Set-UiState "Command started" "The control panel was launched." "Started" "Done" 100
        Write-Activity "TeslaControlPannel launched successfully."
        Show-AppMessage "Success" "TeslaControlPannel is gestart in een nieuw venster." "Success"
    }
    catch {
        $message = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { "Failed to start CMD Commands." }

        Set-UiState "Command blocked" $message "Blocked" "Stopped" 0
        Write-Activity "CMD Commands blocked: $message"
        Show-AppMessage "CMD Commands Blocked" $message "Error"
    }
    finally {
        if (Test-IsAdministrator) {
            Set-ButtonsEnabled $true
        }
    }
}

$window.Add_MouseLeftButtonDown({
    try { $window.DragMove() } catch {}
})

$CloseButton.Add_Click({ $window.Close() })
$MinButton.Add_Click({ $window.WindowState = "Minimized" })
$ExitButton.Add_Click({ $window.Close() })
$InfoButtonTop.Add_Click({ Show-InfoOverlay })

$InfoCloseButton.Add_Click({ Hide-InfoOverlay })
$InfoOkButton.Add_Click({ Hide-InfoOverlay })

$InstallButton.Add_Click({ Start-Install })
$DeleteButton.Add_Click({ Start-Remove })
$CmdCommandsButton.Add_Click({ Start-CmdCommands })

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
        $message = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { "Could not open the install folder." }
        Show-AppMessage "Open Folder Failed" $message "Error"
    }
})

$PopupCloseButton.Add_Click({ Hide-AppMessage })
$PopupOkButton.Add_Click({ Hide-AppMessage })

$PopupRoot.Add_MouseDown({
    if ($_.OriginalSource -eq $PopupRoot) {
        Hide-AppMessage
    }
})

$InfoRoot.Add_MouseDown({
    if ($_.OriginalSource -eq $InfoRoot) {
        Hide-InfoOverlay
    }
})

$window.Add_PreviewKeyDown({
    param($sender, $e)

    if ($PopupRoot.Visibility -eq "Visible") {
        if ($e.Key -eq "Enter" -or $e.Key -eq "Escape") {
            Hide-AppMessage
            $e.Handled = $true
        }
    }

    if ($InfoRoot.Visibility -eq "Visible" -and $e.Key -eq "Escape") {
        Hide-InfoOverlay
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

Apply-StartupState
$window.ShowDialog() | Out-Null