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

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore

$form = New-Object Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = [System.Drawing.Color]::Black

if ($HideUI) {
    $form.Opacity = 0
    $form.ShowInTaskbar = $false
    $form.Size = New-Object System.Drawing.Size(1,1)
    $form.StartPosition = 'Manual'
    $form.Location = New-Object System.Drawing.Point(-2000, -2000)
} else {
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $form.Opacity = 0.85
    $form.TopMost = $true
    $form.ShowInTaskbar = $false
    $form.StartPosition = 'CenterScreen'
    
    $label = New-Object Windows.Forms.Label
    $label.Text = $PersonName + [Environment]::NewLine + $Greeting
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 120, [System.Drawing.FontStyle]::Bold)
    $label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($label)
}

$safetyTimer = New-Object Windows.Forms.Timer
$safetyTimer.Interval = 20000
$safetyTimer.add_Tick({ $form.Close() })

$pollTimer = New-Object Windows.Forms.Timer
$pollTimer.Interval = 150
$pollTimer.add_Tick({
    if ($global:player -and $global:player.NaturalDuration.HasTimeSpan) {
        if ($global:player.Position -ge $global:player.NaturalDuration.TimeSpan) {
            $pollTimer.Stop()
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
        if ($HideUI) { $form.Close() } else { Start-Sleep -Seconds 3; $form.Close() }
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
