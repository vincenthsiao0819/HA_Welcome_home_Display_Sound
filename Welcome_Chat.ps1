param(
    [string]$Base64Text = "",
    [string]$AudioFile = ""
)

Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%Welcome_Chat.ps1%'" | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { $_.Terminate() }

$decodedText = ""
if ($Base64Text) {
    try {
        $decodedText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Text))
        # Escape for XML
        $decodedText = $decodedText.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("'", "&apos;").Replace('"', "&quot;")
        $decodedText = $decodedText.Replace([Environment]::NewLine, "&#x0a;").Replace("`n", "&#x0a;")
    } catch {}
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WelcomeChat" WindowStyle="None" WindowState="Maximized" 
        Topmost="True" Background="Black" AllowsTransparency="True" Opacity="0.85"
        ShowInTaskbar="False">
    <Grid>
        <TextBlock Foreground="White" FontSize="60" FontWeight="Bold" FontFamily="Microsoft JhengHei"
                   HorizontalAlignment="Center" VerticalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center">
            $decodedText
        </TextBlock>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$win = [Windows.Markup.XamlReader]::Load($reader)

$safetyTimer = New-Object System.Windows.Threading.DispatcherTimer
$safetyTimer.Interval = [TimeSpan]::FromSeconds(35)
$safetyTimer.Add_Tick({ $win.Close() })

$pollTimer = New-Object System.Windows.Threading.DispatcherTimer
$pollTimer.Interval = [TimeSpan]::FromMilliseconds(150)
$pollTimer.Add_Tick({
    if ($global:player -and $global:player.NaturalDuration.HasTimeSpan) {
        if ($global:player.Position -ge $global:player.NaturalDuration.TimeSpan) {
            $pollTimer.Stop()
            
            # 2 second delay before closing
            $closeTimer = New-Object System.Windows.Threading.DispatcherTimer
            $closeTimer.Interval = [TimeSpan]::FromSeconds(2)
            $closeTimer.Add_Tick({ $win.Close(); $closeTimer.Stop() })
            $closeTimer.Start()
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
        $closeTimer = New-Object System.Windows.Threading.DispatcherTimer
        $closeTimer.Interval = [TimeSpan]::FromSeconds(10)
        $closeTimer.Add_Tick({ $win.Close(); $closeTimer.Stop() })
        $closeTimer.Start()
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
