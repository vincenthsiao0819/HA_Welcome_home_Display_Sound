param(
    [string]$Base64Text = "",
    [string]$AudioFile = ""
)

Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%Welcome_Chat.ps1%'" | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { $_.Terminate() }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore

$decodedText = ""
if ($Base64Text) {
    try {
        $decodedText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Text))
    } catch {}
}

$form = New-Object Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = [System.Drawing.Color]::Black
$form.Opacity = 0.85
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = 'CenterScreen'
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized

if ($decodedText) {
    $label = New-Object Windows.Forms.Label
    $label.Text = $decodedText
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 60, [System.Drawing.FontStyle]::Bold)
    $label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $label.AutoSize = $false
    $form.Controls.Add($label)
}

$safetyTimer = New-Object Windows.Forms.Timer
$safetyTimer.Interval = 35000
$safetyTimer.add_Tick({ $form.Close() })

$pollTimer = New-Object Windows.Forms.Timer
$pollTimer.Interval = 150
$pollTimer.add_Tick({
    if ($global:player -and $global:player.NaturalDuration.HasTimeSpan) {
        if ($global:player.Position -ge $global:player.NaturalDuration.TimeSpan) {
            $pollTimer.Stop()
            Start-Sleep -Seconds 2
            $form.Close()
        }
    }
})

$form.add_Shown({
    $safetyTimer.Start()
    if ($AudioFile -ne "" -and (Test-Path $AudioFile)) {
        $global:player = New-Object System.Windows.Media.MediaPlayer
        $global:player.Volume = 1.0
        $global:player.Open([uri]$AudioFile)
        $global:player.Play()
        $pollTimer.Start()
    } else {
        Start-Sleep -Seconds 10
        $form.Close()
    }
})

$form.add_FormClosed({
    if ($global:player) {
        try {
            $global:player.Stop()
            $global:player.Close()
        } catch {}
    }
})

[System.Windows.Forms.Application]::Run($form)
