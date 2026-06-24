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
Add-Type -AssemblyName System.Windows.Forms

$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds

if ($HideUI) {
    $Opacity = "0"
    $WinState = "Normal"
    $Width = "1"
    $Height = "1"
    $Left = "-2000"
    $Top = "-2000"
} else {
    $Opacity = "0.85"
    $WinState = "Normal"
    # Hardcode for 27-inch portrait 1080x1920 (or 2160x3840)
    # If the system applies 150% scaling, 1080x1920 logical is what we want.
    # To be absolutely sure, we use the raw primary screen bounds or a massive number that will just bleed off screen
    $Width = "3840"
    $Height = "3840"
    $Left = "0"
    $Top = "0"
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Welcome" WindowStyle="None" WindowState="Maximized" 
        Topmost="True" Background="Black" AllowsTransparency="True" Opacity="$Opacity"
        ShowInTaskbar="False">
    <Grid>
        <TextBlock Text="$FullText" Foreground="White" FontSize="120" FontWeight="Bold" FontFamily="Microsoft JhengHei"
                   HorizontalAlignment="Center" VerticalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$win = [Windows.Markup.XamlReader]::Load($reader)

# Let's use the exact screen bounds from WinForms in WPF
$win.WindowState = "Normal"
$win.Left = $bounds.X
$win.Top = $bounds.Y
$win.Width = $bounds.Width
$win.Height = $bounds.Height

# If the bounds returned 1024x768 (Session 0 fallback), override to at least 1080x1920
if ($bounds.Width -le 1024) {
    $win.Width = 3840
    $win.Height = 3840
}

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
