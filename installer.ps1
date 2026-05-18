    Height="360"
    WindowStartupLocation="CenterScreen"
    ResizeMode="NoResize"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    ShowInTaskbar="True"
    FontFamily="Segoe UI">
    <Border CornerRadius="22" Background="#0D141D" BorderBrush="#203447" BorderThickness="1" Padding="24">
        <Border.Effect>
            <DropShadowEffect BlurRadius="30" ShadowDepth="0" Opacity="0.45"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="14"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="14"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Border Width="46" Height="46" CornerRadius="14" Background="#112130" BorderBrush="#28445C" BorderThickness="1">
                    <TextBlock Text="&#x1F512;" FontSize="22" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#74E8FF"/>
                </Border>
                <StackPanel Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                    <TextBlock Text="Two-Factor Authentication" FontSize="20" FontWeight="SemiBold" Foreground="White"/>
                    <TextBlock x:Name="SubTitle" Text="Enter the code that was sent to Discord" Foreground="#8FA4B8" FontSize="12" Margin="0,4,0,0"/>
                </StackPanel>
                <Button x:Name="AuthCloseBtn" Grid.Column="2" Content="&#x2715;" Width="34" Height="34" Foreground="White" FontSize="14" FontWeight="Bold" Background="#1F2330" BorderThickness="0" Cursor="Hand"/>
            </Grid>

            <Border Grid.Row="2" CornerRadius="14" Background="#0A1018" BorderBrush="#1C2E40" BorderThickness="1" Padding="14">
                <StackPanel>
                    <TextBlock Text="PC" Foreground="#7A92A8" FontSize="11"/>
                    <TextBlock x:Name="PcNameText" Foreground="#74E8FF" FontSize="15" FontWeight="SemiBold" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>

            <Border Grid.Row="4" CornerRadius="14" Background="#0A1018" BorderBrush="#1C2E40" BorderThickness="1" Padding="14">
                <StackPanel>
                    <TextBlock Text="Auth Code (6 digits)" Foreground="#7A92A8" FontSize="11"/>
                    <TextBox x:Name="CodeBox"
                             Margin="0,8,0,0"
                             Background="Transparent"
                             Foreground="White"
                             BorderThickness="0"
                             FontFamily="Consolas"
                             FontSize="28"
                             FontWeight="Bold"
                             MaxLength="6"
                             CaretBrush="#74E8FF"/>
                    <TextBlock x:Name="ErrorText" Text="" Foreground="#FF6B6B" FontSize="12" Margin="0,6,0,0"/>
                </StackPanel>
            </Border>

            <StackPanel Grid.Row="6" Orientation="Horizontal" HorizontalAlignment="Right">
                <TextBlock x:Name="AttemptsText" Text="" Foreground="#8FA4B8" FontSize="12" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <Button x:Name="AuthCancelBtn" Content="Cancel" Width="120" Height="44" Foreground="White" FontSize="13" FontWeight="SemiBold" Background="#172231" BorderThickness="0" Cursor="Hand" Margin="0,0,10,0"/>
                <Button x:Name="AuthOkBtn" Content="Verify" Width="140" Height="44" Foreground="White" FontSize="13" FontWeight="SemiBold" Background="#1CCEF2" BorderThickness="0" Cursor="Hand"/>
            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader $authXaml
    $dlg    = [Windows.Markup.XamlReader]::Load($reader)

    $CodeBox       = $dlg.FindName("CodeBox")
    $ErrorText     = $dlg.FindName("ErrorText")
    $AttemptsText  = $dlg.FindName("AttemptsText")
    $PcNameText    = $dlg.FindName("PcNameText")
    $AuthOkBtn     = $dlg.FindName("AuthOkBtn")
    $AuthCancelBtn = $dlg.FindName("AuthCancelBtn")
    $AuthCloseBtn  = $dlg.FindName("AuthCloseBtn")
    $SubTitle      = $dlg.FindName("SubTitle")

    $PcNameText.Text   = "$env:COMPUTERNAME  /  $env:USERNAME"
    $AttemptsText.Text = "Attempts: 0 / $MaxAttempts"

    $script:AuthResult   = $false
    $script:AuthAttempts = 0

    $tryVerify = {
        $entered = ($CodeBox.Text).Trim()
        if ($entered.Length -eq 0) {
            $ErrorText.Text = "Enter the code first."
            return
        }
        $script:AuthAttempts++
        if ($entered -eq $ExpectedCode) {
            $script:AuthResult = $true
            $dlg.Close()
            return
        }

        $ErrorText.Text = "Incorrect code. Try again."
        $CodeBox.Text = ""
        $AttemptsText.Text = "Attempts: $($script:AuthAttempts) / $MaxAttempts"
        if ($script:AuthAttempts -ge $MaxAttempts) {
            $script:AuthResult = $false
            $dlg.Close()
        }
    }

    $AuthOkBtn.Add_Click($tryVerify)
    $AuthCancelBtn.Add_Click({ $script:AuthResult = $false; $dlg.Close() })
    $AuthCloseBtn.Add_Click({ $script:AuthResult = $false; $dlg.Close() })

    $dlg.Add_MouseLeftButtonDown({ try { $dlg.DragMove() } catch {} })

    $dlg.Add_PreviewKeyDown({
        param($s, $e)
        if ($e.Key -eq "Escape") {
            $script:AuthResult = $false
            $dlg.Close()
            $e.Handled = $true
        }
        elseif ($e.Key -eq "Enter") {
            & $tryVerify
            $e.Handled = $true
        }
    })

    $CodeBox.Add_TextChanged({
        $filtered = ($CodeBox.Text -replace '\D', '')
        if ($filtered.Length -gt 6) { $filtered = $filtered.Substring(0,6) }
        if ($filtered -ne $CodeBox.Text) {
            $CodeBox.Text = $filtered
            $CodeBox.CaretIndex = $filtered.Length
        }
    })

    $dlg.Add_ContentRendered({ $CodeBox.Focus() | Out-Null })

    $dlg.ShowDialog() | Out-Null
    return $script:AuthResult
}

function Invoke-StartupAuth {
    if (-not $Enable2FA) { return $true }

    try {
        $code = New-AuthCode
        Send-DiscordAuthCode -Code $code
    }
    catch {
        $msg = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { "Unknown error while sending the auth code." }
        [System.Windows.MessageBox]::Show(
            "The 2FA code could not be sent to Discord:`n`n$msg`n`nThe launcher will now close.",
            "Tesla Launcher - 2FA Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        return $false
    }

    return (Show-AuthPrompt -ExpectedCode $code -MaxAttempts $MaxAuthAttempts)
}

if (-not (Invoke-StartupAuth)) {
    return
}

Apply-StartupState
$window.ShowDialog() | Out-Null