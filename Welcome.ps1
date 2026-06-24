param(
    [string]$Base64Name = "",
    [string]$AudioFile = "",
    [switch]$HideUI
)

Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%Welcome.ps1%'" | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { $_.Terminate() }

$PersonName = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("5a625Lq6"))
if ($Base64Name -ne "") {
    try { $PersonName = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Name)) } catch {}
}
$Greeting = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("5q2h6L+O5Zue5a62"))
$FullText = $PersonName + "&#x0a;" + $Greeting

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

if ($HideUI) {
    $Opacity = "0"
    $WinState = "Normal"
    $Width = "1"
    $Height = "1"
    $Left = "-2000"
    $Top = "-2000"
} else {
    $Opacity = "0.85"
    $WinState = "Maximized"
    $Width = "Auto"
    $Height = "Auto"
    $Left = "0"
    $Top = "0"
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Welcome" WindowStyle="None" WindowState="$WinState" 
        Topmost="True" Background="Black" AllowsTransparency="True" Opacity="$Opacity"
        ShowInTaskbar="False" Width="$Width" Height="$Height" Left="$Left" Top="$Top">
    <Grid>
        <TextBlock Text="$FullText" Foreground="White" FontSize="120" FontWeight="Bold" FontFamily="Microsoft JhengHei"
                   HorizontalAlignment="Center" VerticalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$win = [Windows.Markup.XamlReader]::Load($reader)

$safetyTimer = New-Object System.Windows.Threading.DispatcherTimer
$safetyTimer.Interval = [TimeSpan]::FromSeconds(20)
$safetyTimer.Add_Tick({ $win.Close() })

$pollTimer = New-Object System.Windows.Threading.DispatcherTimer
$pollTimer.Interval = [TimeSpan]::FromMilliseconds(150)
$pollTimer.Add_Tick({
    if ($global:player -and $global:player.NaturalDuration.HasTimeSpan) {
        if ($global:player.Position -ge $global:player.NaturalDuration.TimeSpan) {
            $pollTimer.Stop()
            $win.Close()
        }
    }
})

$win.Add_Loaded({
    $safetyTimer.Start()
    if ($AudioFile -ne "" -and (Test-Path $AudioFile)) {
        $global:player = New-Object System.Windows.Media.MediaPlayer
        $global:player.Volume = 1.0
        $global:player.Open([uri]$AudioFile)
        $global:player.Play()
        $pollTimer.Start()
    } else {
        if ($HideUI) { $win.Close() } else { 
            # Dispatcher timer for 3s close instead of sleep
            $closeTimer = New-Object System.Windows.Threading.DispatcherTimer
            $closeTimer.Interval = [TimeSpan]::FromSeconds(3)
            $closeTimer.Add_Tick({ $win.Close(); $closeTimer.Stop() })
            $closeTimer.Start()
        }
    }
})

$win.Add_Closed({
    if ($global:player) {
        try {
            $global:player.Stop()
            $global:player.Close()
        } catch {}
    }
})

$app = New-Object System.Windows.Application
$app.Run($win) | Out-Null
