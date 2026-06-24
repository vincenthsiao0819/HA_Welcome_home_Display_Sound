param(
    [string]$Base64Text = "",
    [string]$AudioFile = ""
)

Get-WmiObject Win32_Process -Filter "Name='powershell.exe' AND CommandLine LIKE '%Welcome_Chat.ps1%'" | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { $_.Terminate() }

$decodedText = ""
if ($Base64Text) {
    try {
        $decodedText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Text))
    } catch {}
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = [System.Drawing.Color]::Black
$form.Opacity = 0.85
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized

if ($decodedText) {
    $label = New-Object Windows.Forms.Label
    $label.Text = $decodedText
    $label.ForeColor = [System.Drawing.Color]::White
    $label.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 60, [System.Drawing.FontStyle]::Bold)
    $label.Dock = [System.Windows.Forms.DockStyle]::Fill
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $form.Controls.Add($label)
}

$safetyTimer = New-Object Windows.Forms.Timer
$safetyTimer.Interval = 35000
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
            public class AudioPlayer2 {
                [DllImport("winmm.dll", CharSet = CharSet.Auto)]
                public static extern long mciSendString(string command, string buffer, int bufferSize, int hwndCallback);
            }
"@
            [AudioPlayer2]::mciSendString("open `"$AudioFile`" type mpegvideo alias myaudio", $null, 0, 0) | Out-Null
            [AudioPlayer2]::mciSendString("play myaudio", $null, 0, 0) | Out-Null
        } catch {}
        $pollTimer.Start()
    } else {
        Start-Sleep -Seconds 10
        $form.Close()
    }
})

$form.add_FormClosed({
    try {
        [AudioPlayer2]::mciSendString("stop myaudio", $null, 0, 0) | Out-Null
        [AudioPlayer2]::mciSendString("close myaudio", $null, 0, 0) | Out-Null
    } catch {}
})

[System.Windows.Forms.Application]::Run($form)
