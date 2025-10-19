; SMS Sender via Gmail AutoHotkey Script
#Persistent
#SingleInstance Force

; Read and parse settings from JSON file
FileRead, settingsJson, %A_ScriptDir%\settings.json

; Parse common settings
gmailAddress := RegExReplace(settingsJson, "[\s\S]*""gmailAddress""\s*:\s*""([^""]+)""[\s\S]*", "$1")
gmailAppPassword := RegExReplace(settingsJson, "[\s\S]*""gmailAppPassword""\s*:\s*""([^""]+)""[\s\S]*", "$1")
telusSmsGateway := RegExReplace(settingsJson, "[\s\S]*""telusSmsGateway""\s*:\s*""([^""]+)""[\s\S]*", "$1")
timestampEnabled := RegExReplace(settingsJson, "[\s\S]*""timestampEnabled""\s*:\s*(true|false)[\s\S]*", "$1")

; Set up individual hotkeys with their messages
Hotkey, ^!+1, SendSMS1
Hotkey, ^!+2, SendSMS2
Hotkey, ^!+3, SendSMS3
Hotkey, ^!+4, SendSMS4
Hotkey, ^!+5, SendSMS5

return

SendSMS1:
    msg := RegExReplace(settingsJson, "[\s\S]*\^\!\+1[^}]*""message""\s*:\s*""([^""]+)""[\s\S]*", "$1")
    SendSMSMessage(msg)
return

SendSMS2:
    msg := RegExReplace(settingsJson, "[\s\S]*\^\!\+2[^}]*""message""\s*:\s*""([^""]+)""[\s\S]*", "$1")
    SendSMSMessage(msg)
return

SendSMS3:
    msg := RegExReplace(settingsJson, "[\s\S]*\^\!\+3[^}]*""message""\s*:\s*""([^""]+)""[\s\S]*", "$1")
    SendSMSMessage(msg)
return

SendSMS4:
    msg := RegExReplace(settingsJson, "[\s\S]*\^\!\+4[^}]*""message""\s*:\s*""([^""]+)""[\s\S]*", "$1")
    SendSMSMessage(msg)
return

SendSMS5:
    msg := RegExReplace(settingsJson, "[\s\S]*\^\!\+5[^}]*""message""\s*:\s*""([^""]+)""[\s\S]*", "$1")
    SendSMSMessage(msg)
return

; Function to send SMS
SendSMSMessage(message)
{
    global gmailAddress, gmailAppPassword, telusSmsGateway, timestampEnabled

    ; Add timestamp if enabled
    if (timestampEnabled = "true")
    {
        FormatTime, timestamp, , [HH:mm]
        displayMessage := message . " " . timestamp
    }
    else
    {
        displayMessage := message
    }

    ; Call PowerShell script with parameters
    scriptPath := A_ScriptDir . "\send-sms.ps1"
    psCommand := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ . scriptPath . """ -GmailAddress """ . gmailAddress . """ -GmailAppPassword """ . gmailAppPassword . """ -SmsGateway """ . telusSmsGateway . """ -Message """ . message . """ -TimestampEnabled """ . timestampEnabled . """"

    ; Run PowerShell script
    RunWait, %psCommand%, , Hide

    ; Show notification (0=no icon, uses tray icon if set)
    TrayTip, SMS Sent, %displayMessage%, 3, 0
}
