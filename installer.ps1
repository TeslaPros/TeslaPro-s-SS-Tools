# =========================
# HIDE CONSOLE IMMEDIATELY
# =========================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class TeslaWin32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

try {
    $consolePtr = [TeslaWin32]::GetConsoleWindow()
    if ($consolePtr -ne [IntPtr]::Zero) {
        [TeslaWin32]::ShowWindow($consolePtr, 0) | Out-Null
    }
}
catch {}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Xaml

$userDir   = [Environment]::GetFolderPath("UserProfile")
$downloads = Join-Path $userDir "Downloads"
$url       = "https://github.com/TeslaPros/TeslaPro-s-SS-Tools/releases/latest/download/SS.TeslaPro.zip"
$zip       = Join-Path $downloads "SS.TeslaPro.zip"
$dest      = Join-Path $downloads "TeslaPro-Tools"
$version   = "2.0"

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Tesla Launcher"
    Width="1260"
    Height="790"
    MinWidth="1260"
    MinHeight="790"
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
            <GradientStop Color="#0A1018" Offset="0.45"/>
            <GradientStop Color="#071A24" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="SidebarBackground" StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#0B1118" Offset="0"/>
            <GradientStop Color="#0D1520" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="PrimaryButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#33E3FF" Offset="0"/>
            <GradientStop Color="#00A9D9" Offset="1"/>
        </LinearGradientBrush>

        <LinearGradientBrush x:Key="DangerButtonBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#3B2028" Offset="0"/>
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
                                BorderThickness="1"
                                SnapsToDevicePixels="True">
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
                                <Setter TargetName="Root" Property="Opacity" Value="0.96"/>
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
            <Setter Property="BorderBrush" Value="#1C2A3C"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>

        <Style x:Key="MiniStatStyle" TargetType="Border">
            <Setter Property="CornerRadius" Value="20"/>
            <Setter Property="Padding" Value="18"/>
            <Setter Property="Background" Value="{StaticResource CardBackground}"/>
            <Setter Property="BorderBrush" Value="#1C2A3C"/>
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

                                <Button x:Name="InfoButton"
                                        Tag="&#xE946;"
                                        Content="About / Info"
                                        Style="{StaticResource ActionButtonStyle}"
                                        Background="#172231"/>

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
                                                <TextBlock x:Name="VersionText" Text="Version 2.0" Foreground="#74E8FF" FontSize="16" FontWeight="Bold" Margin="0,4,0,0"/>
                                            </StackPanel>

                                            <Border Grid.Column="1" Width="78" Height="30" CornerRadius="15" Background="#122232" BorderBrush="#234760" BorderThickness="1" VerticalAlignment="Center">
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
                                        <TextBlock Text="This launcher helps you download and manage TeslaPro's SS Tools in a clean and simple way." Foreground="#84A1BA" TextWrapping="Wrap"/>
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
                                        <TextBlock Text="Activity" FontSize="22" FontWeight="SemiBold" Foreground="White"/>
                                        <TextBlock Text="Live output from the launcher" Foreground="#91A7BB" FontSize="12" Margin="0,6,0,0"/>
                                    </StackPanel>

                                    <Border Grid.Column="1" Width="140" Height="34" HorizontalAlignment="Right" VerticalAlignment="Top" CornerRadius="17" Background="#0B121B" BorderBrush="#203447" BorderThickness="1">
                                        <TextBlock x:Name="MiniStateText" Text="READY" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#74E8FF" FontWeight="Bold"/>
                                    </Border>
                                </Grid>

                                <Border Grid.Row="2" CornerRadius="8" Background="#091018" BorderBrush="#1A2B3C" BorderThickness="1">
                                    <ProgressBar x:Name="MainProgressBar" Height="12" Minimum="0" Maximum="100" Value="0" Background="Transparent" Foreground="#22D6FF" BorderThickness="0"/>
                                </Border>

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

        <Grid x:Name="OverlayRoot" Visibility="Collapsed" Opacity="0" Background="#A0000000">
            <Border Width="620"
                    Padding="24"
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

                        <Button x:Name="OverlayCloseButton" Grid.Column="2" Content="✕" Width="34" Height="34" Style="{StaticResource SmallWindowButtonStyle}" Background="#1F2330"/>
                    </Grid>

                    <StackPanel Grid.Row="2">
                        <Border CornerRadius="16" Background="#0A1018" BorderBrush="#1C2E40" BorderThickness="1" Padding="16">
                            <TextBlock TextWrapping="Wrap" Foreground="#DCE7F2" FontSize="13">
This launcher was made by TeslaPro.

If you find a bug or if you have any questions, you can always send me a message on Discord:
@teamwsf

These tools may only be used with TeslaPro's permission.
                            </TextBlock>
                        </Border>

                        <Border Margin="0,14,0,0" CornerRadius="16" Background="#0A1018" BorderBrush="#1C2E40" BorderThickness="1" Padding="16">
                            <StackPanel>
                                <TextBlock Text="Notes" Foreground="White" FontSize="15" FontWeight="SemiBold"/>
                                <TextBlock Margin="0,8,0,0" TextWrapping="Wrap" Foreground="#9BB0C4" FontSize="13">
Please keep this launcher private and use it responsibly. If anything is unclear, contact TeslaPro before using or sharing the tools.
                                </TextBlock>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="DiscordCopyButton"
                                Tag="&#xE8C8;"
                                Content="Copy Discord"
                                Style="{StaticResource ActionButtonStyle}"
                                Background="#163043"
                                Width="160"
                                Margin="0,0,12,0"/>

                        <Button x:Name="OverlayOkButton"
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

                        <Border Width="44"
                                Height="44"
                                CornerRadius="14"
                                Background="#112130"
                                BorderBrush="#28445C"
                                BorderThickness="1">
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

        <Grid x:Name="ConfirmRoot" Visibility="Collapsed" Opacity="0" Background="#A0000000">
            <Border Width="540"
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

                        <Border Width="44"
                                Height="44"
                                CornerRadius="14"
                                Background="#112130"
                                BorderBrush="#28445C"
                                BorderThickness="1">
                            <TextBlock x:Name="ConfirmIconText"
                                       Text="?"
                                       HorizontalAlignment="Center"
                                       VerticalAlignment="Center"
                                       FontSize="20"
                                       FontWeight="Bold"
                                       Foreground="#FFC857"/>
                        </Border>

                        <StackPanel Grid.Column="1" Margin="14,0,0,0">
                            <TextBlock x:Name="ConfirmTitleText"
                                       Text="Please Confirm"
                                       FontSize="22"
                                       FontWeight="SemiBold"
                                       Foreground="White"/>
                            <TextBlock x:Name="ConfirmSubtitleText"
                                       Text="Tesla Launcher"
                                       Foreground="#8FA4B8"
                                       FontSize="12"
                                       Margin="0,4,0,0"/>
                        </StackPanel>

                        <Button x:Name="ConfirmCloseButton"
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
                        <TextBlock x:Name="ConfirmMessageText"
                                   TextWrapping="Wrap"
                                   Foreground="#DCE7F2"
                                   FontSize="13"
                                   Text="Confirmation text goes here."/>
                    </Border>

                    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
                        <Button x:Name="ConfirmNoButton"
                                Tag="&#xE711;"
                                Content="Cancel"
                                Style="{StaticResource ActionButtonStyle}"
                                Background="#172231"
                                Width="140"
                                Margin="0,0,12,0"/>

                        <Button x:Name="ConfirmYesButton"
                                Tag="&#xE73E;"
                                Content="Continue"
                                Style="{StaticResource ActionButtonStyle}"
                                Background="{StaticResource PrimaryButtonBrush}"
                                Width="150"
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

$InstallButton       = $window.FindName("InstallButton")
$DeleteButton        = $window.FindName("DeleteButton")
$OpenFolderButton    = $window.FindName("OpenFolderButton")
$InfoButton          = $window.FindName("InfoButton")
$InfoButtonTop       = $window.FindName("InfoButtonTop")
$ExitButton          = $window.FindName("ExitButton")
$CloseButton         = $window.FindName("CloseButton")
$MinButton           = $window.FindName("MinButton")

$StatusText          = $window.FindName("StatusText")
$SubStatusText       = $window.FindName("SubStatusText")
$StateChip           = $window.FindName("StateChip")
$BigChipText         = $window.FindName("BigChipText")
$MiniStateText       = $window.FindName("MiniStateText")
$FooterText          = $window.FindName("FooterText")

$StepText            = $window.FindName("StepText")
$ProgressLabel       = $window.FindName("ProgressLabel")
$ToolCountText       = $window.FindName("ToolCountText")
$LogBox              = $window.FindName("LogBox")
$MainProgressBar     = $window.FindName("MainProgressBar")
$LocationText        = $window.FindName("LocationText")
$VersionText         = $window.FindName("VersionText")

$OverlayRoot         = $window.FindName("OverlayRoot")
$OverlayCloseButton  = $window.FindName("OverlayCloseButton")
$OverlayOkButton     = $window.FindName("OverlayOkButton")
$DiscordCopyButton   = $window.FindName("DiscordCopyButton")

$PopupRoot           = $window.FindName("PopupRoot")
$PopupCloseButton    = $window.FindName("PopupCloseButton")
$PopupOkButton       = $window.FindName("PopupOkButton")
$PopupTitleText      = $window.FindName("PopupTitleText")
$PopupSubtitleText   = $window.FindName("PopupSubtitleText")
$PopupMessageText    = $window.FindName("PopupMessageText")
$PopupIconText       = $window.FindName("PopupIconText")

$ConfirmRoot         = $window.FindName("ConfirmRoot")
$ConfirmCloseButton  = $window.FindName("ConfirmCloseButton")
$ConfirmYesButton    = $window.FindName("ConfirmYesButton")
$ConfirmNoButton     = $window.FindName("ConfirmNoButton")
$ConfirmTitleText    = $window.FindName("ConfirmTitleText")
$ConfirmSubtitleText = $window.FindName("ConfirmSubtitleText")
$ConfirmMessageText  = $window.FindName("ConfirmMessageText")
$ConfirmIconText     = $window.FindName("ConfirmIconText")

$LocationText.Text = $dest
$VersionText.Text  = "Version $version"

$script:ConfirmDialogResult = $null
$script:ConfirmDialogFrame  = $null

function Write-Log {
    param(
        [string]$Text,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $LogBox.AppendText("[$timestamp] [$Level] $Text`r`n")
    $LogBox.ScrollToEnd()
}

function Show-FadeElement {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.UIElement]$Element,
        [int]$DurationMs = 180
    )

    $Element.Visibility = "Visible"
    $Element.Opacity = 0

    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animation.From = 0
    $animation.To = 1
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($DurationMs))

    $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animation)
}

function Hide-FadeElement {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.UIElement]$Element,
        [int]$DurationMs = 140
    )

    $animation = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animation.From = $Element.Opacity
    $animation.To = 0
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds($DurationMs))

    $animation.Add_Completed({
        $Element.Visibility = "Collapsed"
        $Element.Opacity = 0
    })

    $Element.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animation)
}

function Set-ProgressAnimated {
    param(
        [double]$Value,
        [int]$DurationMs = 220
    )

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

    $StatusText.Text     = $Title
    $SubStatusText.Text  = $SubTitle
    $StateChip.Text      = $Chip.ToUpper()
    $BigChipText.Text    = $Chip.ToUpper()
    $MiniStateText.Text  = $Chip.ToUpper()
    $FooterText.Text     = $Title
    $StepText.Text       = $Step
    Set-ProgressAnimated $Progress
    $ProgressLabel.Text  = ("{0}%" -f [int]$Progress)
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)

    $InstallButton.IsEnabled    = $Enabled
    $DeleteButton.IsEnabled     = $Enabled
    $OpenFolderButton.IsEnabled = $Enabled
    $InfoButton.IsEnabled       = $Enabled
    $InfoButtonTop.IsEnabled    = $Enabled
    $ExitButton.IsEnabled       = $Enabled
}

function Refresh-Ui {
    $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
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

function Show-InfoOverlay {
    Show-FadeElement -Element $OverlayRoot -DurationMs 180
}

function Hide-InfoOverlay {
    Hide-FadeElement -Element $OverlayRoot -DurationMs 140
}

function Show-AppMessage {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")]
        [string]$Type = "Info"
    )

    $PopupTitleText.Text    = $Title
    $PopupSubtitleText.Text = "Tesla Launcher"
    $PopupMessageText.Text  = $Message

    switch ($Type) {
        "Info" {
            $PopupIconText.Text = "i"
            $PopupIconText.Foreground = "#74E8FF"
        }
        "Success" {
            $PopupIconText.Text = "✓"
            $PopupIconText.Foreground = "#4DDB8A"
        }
        "Warning" {
            $PopupIconText.Text = "!"
            $PopupIconText.Foreground = "#FFC857"
        }
        "Error" {
            $PopupIconText.Text = "×"
            $PopupIconText.Foreground = "#FF6B6B"
        }
    }

    Show-FadeElement -Element $PopupRoot -DurationMs 180
}

function Hide-AppMessage {
    Hide-FadeElement -Element $PopupRoot -DurationMs 140
}

function Close-ConfirmDialog {
    if ($script:ConfirmDialogFrame -ne $null) {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(150)
        $timer.Add_Tick({
            $this.Stop()
            if ($script:ConfirmDialogFrame -ne $null) {
                $script:ConfirmDialogFrame.Continue = $false
            }
        })
        $timer.Start()
    }
}

function Hide-ConfirmDialog {
    Hide-FadeElement -Element $ConfirmRoot -DurationMs 140
}

function Show-ConfirmDialog {
    param(
        [string]$Title,
        [string]$Message,
        [ValidateSet("Question","Warning","Danger")]
        [string]$Type = "Question"
    )

    $ConfirmTitleText.Text    = $Title
    $ConfirmSubtitleText.Text = "Tesla Launcher"
    $ConfirmMessageText.Text  = $Message

    switch ($Type) {
        "Question" {
            $ConfirmIconText.Text = "?"
            $ConfirmIconText.Foreground = "#FFC857"
        }
        "Warning" {
            $ConfirmIconText.Text = "!"
            $ConfirmIconText.Foreground = "#FFC857"
        }
        "Danger" {
            $ConfirmIconText.Text = "!"
            $ConfirmIconText.Foreground = "#FF6B6B"
        }
    }

    $script:ConfirmDialogResult = $null
    Show-FadeElement -Element $ConfirmRoot -DurationMs 180
    Refresh-Ui

    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $script:ConfirmDialogFrame = $frame
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)

    $result = $script:ConfirmDialogResult
    $script:ConfirmDialogFrame = $null
    return $result
}

function Test-SystemRequirements {
    Set-UiState "Checking your system" "Making sure everything is ready." "Checking" "System Check" 10
    Refresh-Ui
    Write-Log "Running system checks"

    if ($env:OS -ne "Windows_NT") {
        throw "This launcher only works on Windows."
    }
    Write-Log "Windows detected" "OK"

    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or newer is required."
    }
    Write-Log ("PowerShell version OK: " + $PSVersionTable.PSVersion.ToString()) "OK"

    if (!(Test-Path $downloads)) {
        throw "The Downloads folder was not found."
    }
    Write-Log "Downloads folder found" "OK"

    $testFile = Join-Path $downloads "teslapro_write_test.tmp"
    "test" | Out-File $testFile -Force
    Remove-Item $testFile -Force
    Write-Log "Write access confirmed" "OK"

    $driveName = (Split-Path $downloads -Qualifier).Replace(":", "")
    $drive = Get-PSDrive -Name $driveName
    if ($drive.Free -lt 100MB) {
        throw "Not enough free disk space. At least 100 MB is required."
    }
    Write-Log ("Free space available: {0:N2} GB" -f ($drive.Free / 1GB)) "OK"

    Invoke-WebRequest -UseBasicParsing -Method Head -Uri "https://github.com" | Out-Null
    Write-Log "Internet connection looks good" "OK"
}

function Install-Tools {
    try {
        Set-ButtonsEnabled $false
        $LogBox.Clear()
        $ToolCountText.Text = "0"

        Write-Log "Starting install"
        Test-SystemRequirements

        if (Test-Path $dest) {
            $overwrite = Show-ConfirmDialog "Replace existing install?" "An existing install was found.`n`nDo you want to replace it?" "Question"
            if (-not $overwrite) {
                Set-UiState "Install cancelled" "The current install was left unchanged." "Cancelled" "Stopped" 0
                Write-Log "Install cancelled by user" "WARN"
                return
            }

            Write-Log "Existing install will be replaced"
        }

        Set-UiState "Downloading package" "Getting the latest TeslaPro release." "Downloading" "Download" 32
        Refresh-Ui

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
            Write-Log "Old temporary ZIP removed"
        }

        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip

        if (!(Test-Path $zip)) {
            throw "The ZIP file was not created after download."
        }

        $zipSize = (Get-Item $zip).Length
        if ($zipSize -lt 1000) {
            throw "The downloaded ZIP looks invalid or corrupted."
        }

        Write-Log ("Download complete: {0:N2} MB" -f ($zipSize / 1MB)) "OK"

        Set-UiState "Installing files" "Unpacking the toolkit and preparing the folder." "Installing" "Extracting" 64
        Refresh-Ui

        if (Test-Path $dest) {
            Remove-Item $dest -Recurse -Force
            Write-Log "Previous install folder removed"
        }

        New-Item -ItemType Directory -Path $dest | Out-Null
        Expand-Archive -Path $zip -DestinationPath $dest -Force

        $items = Get-ChildItem -Path $dest -Recurse -Force
        $count = ($items | Measure-Object).Count
        if ($count -eq 0) {
            throw "The install folder is empty after extraction."
        }

        Write-Log "Files extracted successfully" "OK"
        Write-Log ("Extracted items: $count")

        if (Test-Path $zip) {
            Remove-Item $zip -Force
            Write-Log "Temporary ZIP removed"
        }

        $tools = Get-ChildItem -Path $dest -Recurse -Filter *.exe | Sort-Object Name
        $toolCount = ($tools | Measure-Object).Count
        $ToolCountText.Text = $toolCount.ToString()

        if ($toolCount -gt 0) {
            Write-Log "Executable tools detected: $toolCount" "OK"
            foreach ($tool in $tools) {
                Write-Log ("Found: " + $tool.Name)
            }
        }
        else {
            Write-Log "No .exe files were found in the extracted folder" "WARN"
        }

        Set-UiState "Install complete" "Everything looks good and the tools are ready." "Installed" "Done" 100
        Write-Log "Install finished successfully" "OK"

        try {
            Start-Process $dest
            Write-Log "Install folder opened automatically"
        }
        catch {
            Write-Log "Could not open the install folder automatically" "WARN"
        }

        Show-AppMessage "Install Complete" "TeslaPro SS Tools were installed successfully." "Success"
    }
    catch {
        Set-UiState "Install failed" $_.Exception.Message "Error" "Failed" 0
        Write-Log $_.Exception.Message "ERROR"
        Show-AppMessage "Install Failed" $_.Exception.Message "Error"
    }
    finally {
        Update-ToolCount
        Set-ButtonsEnabled $true
    }
}

function Remove-Tools {
    try {
        Set-ButtonsEnabled $false
        $LogBox.Clear()

        if (!(Test-Path $dest)) {
            Set-UiState "Nothing to remove" "No install was found on this system." "Idle" "Waiting" 0
            Write-Log "No install found" "WARN"
            Update-ToolCount
            return
        }

        $confirm = Show-ConfirmDialog "Remove installed tools?" "This will remove TeslaPro SS Tools from:`n`n$dest`n`nContinue?" "Danger"
        if (-not $confirm) {
            Set-UiState "Removal cancelled" "No files were removed." "Cancelled" "Stopped" 0
            Write-Log "Removal cancelled by user" "WARN"
            return
        }

        Set-UiState "Removing files" "Cleaning up the installed toolkit." "Removing" "Removal" 48
        Refresh-Ui
        Write-Log "Removing installed files"

        Remove-Item $dest -Recurse -Force -ErrorAction Stop

        if (Test-Path $zip) {
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
            Write-Log "Temporary ZIP removed"
        }

        Set-UiState "Removal complete" "The installed files were removed successfully." "Removed" "Done" 100
        Write-Log "Removal finished successfully" "OK"
        $ToolCountText.Text = "0"

        Show-AppMessage "Removal Complete" "TeslaPro SS Tools were removed successfully." "Success"
    }
    catch {
        Set-UiState "Removal failed" $_.Exception.Message "Error" "Failed" 0
        Write-Log $_.Exception.Message "ERROR"
        Update-ToolCount
        Show-AppMessage "Removal Failed" $_.Exception.Message "Error"
    }
    finally {
        Set-ButtonsEnabled $true
    }
}

$window.Add_MouseLeftButtonDown({
    try { $window.DragMove() } catch {}
})

$CloseButton.Add_Click({
    $window.Close()
})

$MinButton.Add_Click({
    $window.WindowState = "Minimized"
})

$ExitButton.Add_Click({
    $window.Close()
})

$InstallButton.Add_Click({
    Install-Tools
})

$DeleteButton.Add_Click({
    Remove-Tools
})

$OpenFolderButton.Add_Click({
    try {
        if (!(Test-Path $dest)) {
            Show-AppMessage "Open Folder" "The install folder does not exist yet." "Info"
            return
        }

        Start-Process $dest
        Write-Log "Install folder opened manually" "OK"
    }
    catch {
        Write-Log $_.Exception.Message "ERROR"
        Show-AppMessage "Open Folder Failed" $_.Exception.Message "Error"
    }
})

$InfoButton.Add_Click({
    Show-InfoOverlay
})

$InfoButtonTop.Add_Click({
    Show-InfoOverlay
})

$OverlayCloseButton.Add_Click({
    Hide-InfoOverlay
})

$OverlayOkButton.Add_Click({
    Hide-InfoOverlay
})

$DiscordCopyButton.Add_Click({
    try {
        [System.Windows.Clipboard]::SetText("@teamwsf")
        Write-Log "Discord tag copied to clipboard" "OK"
        Show-AppMessage "Copied" "Discord tag copied: @teamwsf" "Success"
    }
    catch {
        Write-Log "Could not copy the Discord tag" "ERROR"
        Show-AppMessage "Copy Failed" "The Discord tag could not be copied." "Error"
    }
})

$OverlayRoot.Add_MouseDown({
    if ($_.OriginalSource -eq $OverlayRoot) {
        Hide-InfoOverlay
    }
})

$PopupCloseButton.Add_Click({
    Hide-AppMessage
})

$PopupOkButton.Add_Click({
    Hide-AppMessage
})

$PopupRoot.Add_MouseDown({
    if ($_.OriginalSource -eq $PopupRoot) {
        Hide-AppMessage
    }
})

$ConfirmCloseButton.Add_Click({
    $script:ConfirmDialogResult = $false
    Hide-ConfirmDialog
    Close-ConfirmDialog
})

$ConfirmNoButton.Add_Click({
    $script:ConfirmDialogResult = $false
    Hide-ConfirmDialog
    Close-ConfirmDialog
})

$ConfirmYesButton.Add_Click({
    $script:ConfirmDialogResult = $true
    Hide-ConfirmDialog
    Close-ConfirmDialog
})

$ConfirmRoot.Add_MouseDown({
    if ($_.OriginalSource -eq $ConfirmRoot) {
        $script:ConfirmDialogResult = $false
        Hide-ConfirmDialog
        Close-ConfirmDialog
    }
})

# Smooth window fade-in
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

Set-UiState "Ready" "Everything is ready. Pick an action on the left." "Idle" "Waiting" 0
Write-Log "TeslaPro launcher started" "OK"
Write-Log "Ready" "INFO"
Update-ToolCount

$window.ShowDialog() | Out-Null