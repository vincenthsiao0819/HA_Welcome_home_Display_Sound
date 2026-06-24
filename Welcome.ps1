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
$pollTimer.Interval = 15000
$pollTimer.add_Tick({ $form.Close() })

$form.add_Shown({
    $safetyTimer.Start()
    if ($AudioFile -ne "" -and (Test-Path $AudioFile)) {
        try {
            Add-Type -TypeDefinition @"
            using System.Runtime.InteropServices;
            public class AudioPlayer {
                [DllImport("winmm.dll", CharSet = CharSet.Auto)]
                public static extern long mciSendString(string command, string buffer, int bufferSize, int hwndCallback);
            }
"@
            [AudioPlayer]::mciSendString("open `"$AudioFile`" type mpegvideo alias myaudio", $null, 0, 0) | Out-Null
            [AudioPlayer]::mciSendString("play myaudio", $null, 0, 0) | Out-Null
        } catch {}
        $pollTimer.Start()
    } else {
        if ($HideUI) { $form.Close() } else { Start-Sleep -Seconds 3; $form.Close() }
    }
})

$form.add_FormClosed({
    try {
        [AudioPlayer]::mciSendString("stop myaudio", $null, 0, 0) | Out-Null
        [AudioPlayer]::mciSendString("close myaudio", $null, 0, 0) | Out-Null
    } catch {}
})

[System.Windows.Forms.Application]::Run($form)
