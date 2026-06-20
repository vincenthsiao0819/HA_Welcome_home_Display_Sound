# Welcome Home Display & Sound (Standalone Native API)

這套系統是一組獨立於 MagicMirror 的純 Windows 迎賓看板解決方案。
它透過 Node.js 接收 HTTP 請求，並觸發 Windows 原生的 PowerShell (WinForms + TTS) 彈出滿版半透明的黑底毛玻璃畫面與語音播報。

## 核心特點
1. **完全免疫 Windows 亂碼**：HTTP 請求收到的中文名稱，會透過 Node.js 轉成 `Base64` 字串，再傳遞給 PowerShell 解碼，保證 `歡迎回家` 與人名絕對不會因為系統 ANSI/UTF-8 設定而出現亂碼破圖。
2. **破除 Session 0 隱形隔離**：透過 Windows 工作排程器 (Interactive 模式) 執行，確保畫面與語音一定會出現在實體螢幕上，而不會被卡在背景管理員會話。
3. **滿版毛玻璃特效**：自動適應螢幕解析度，上下斷行置中顯示。

## 檔案說明
- `server.js`: Node.js 背景伺服器 (Port: 8081)，負責接收 API 請求、將名稱轉換為 Base64，並呼叫 PowerShell 腳本。
- `Welcome.ps1`: WinForms UI 與 System.Speech 語音合成腳本。
- `start_api.vbs`: 用來無痕 (隱藏 CMD 視窗) 啟動 `server.js` 的 VBScript。

## 部署與啟動方式

1. 將這三個檔案放置於 `C:\Users\magic\WelcomeAPI\` 目錄下。
2. **建立並啟動工作排程 (非常重要！不可直接雙擊執行！)**
   為了讓系統能把畫面推送到實體螢幕，必須建立一個互動式 (Interactive) 的工作排程：
   ```cmd
   schtasks /create /tn RunWelcomeAPI /tr "wscript.exe C:\Users\magic\WelcomeAPI\start_api.vbs" /sc once /st 00:00 /it /f
   ```
3. **啟動 API 伺服器**：
   ```cmd
   schtasks /run /tn RunWelcomeAPI
   ```

## 觸發方式
透過 HTTP GET 或 POST 發送請求即可觸發：
- 測試網址：\`http://192.168.50.204:8081/welcome?name=Vincent\`
- Home Assistant 等自動化系統可直接 Call 此 Webhook。

> 註：畫面預設顯示時間為 60,000 毫秒 (60秒)，時間到後會自動平滑關閉。
