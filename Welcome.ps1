param(
    [string]$Base64Name = "",
    [string]$AudioFile = "",
    [switch]$HideUI
)

Get-WmiObject Win32_Process -Filter "CommandLine LIKE '%Welcome.ps1%'" | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { $_.Terminate() }

$PersonName = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("5a625Lq6"))
if ($Base64Name -ne "") {
    try {
        $PersonName = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Base64Name))
    } catch {}
}

$Greeting = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("5q2h6L+O5Zue5a62"))

if ($HideUI) {
    if ($AudioFile -ne "" -and (Test-Path $AudioFile)) {
        $wmp = New-Object -ComObject WMPlayer.OCX
        $wmp.settings.volume = 100
        $wmp.URL = $AudioFile
        $wmp.controls.play()
        
        # Give it a tiny bit more time to buffer
        Start-Sleep -Milliseconds 1500
        
        # 3=Playing, 9=Transitioning, 10=Ready, 6=Buffering, 1=Stopped
        $timeout = 0
        while (($wmp.playState -eq 3 -or $wmp.playState -eq 9 -or $wmp.playState -eq 6) -and $timeout -lt 60) {
            Start-Sleep -Milliseconds 500
            $timeout++
        }
        
        $wmp.close()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wmp) | Out-Null
    }
    Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$form.BackColor = [System.Drawing.Color]::Black
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

$timer = New-Object Windows.Forms.Timer
$timer.Interval = 60000
$timer.add_Tick({ $form.Close() })
$timer.Start()

$form.add_Shown({
    if ($AudioFile -ne "" -and (Test-Path $AudioFile)) {
        $global:wmp = New-Object -ComObject WMPlayer.OCX
        $global:wmp.settings.volume = 100
        $global:wmp.URL = $AudioFile
        $global:wmp.controls.play()
    }
})

$form.add_FormClosed({
    if ($AudioFile -ne "" -and (Test-Path $AudioFile)) {
        try {
            $global:wmp.close()
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($global:wmp) | Out-Null
        } catch {}
    }
})

[System.Windows.Forms.Application]::Run($form)
