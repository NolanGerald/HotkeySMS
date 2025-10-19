; SMS Sender via Gmail AutoHotkey Script
#Persistent
#SingleInstance Force

; Read and parse settings from JSON file
FileRead, settingsJson, %A_ScriptDir%\settings.json

; Parse common settings
gmailAddress := RegExReplace(settingsJson, "[\s\S]*""gmailAddress""\s*:\s*""([^""]+)""[\s\S]*", "$1")
gmailAppPassword := RegExReplace(settingsJson, "[\s\S]*""gmailAppPassword""\s*:\s*""([^""]+)""[\s\S]*", "$1")
timestampEnabled := RegExReplace(settingsJson, "[\s\S]*""timestampEnabled""\s*:\s*(true|false)[\s\S]*", "$1")

; Parse recipients
recipients := []
recipientNames := []
recipientSection := RegExReplace(settingsJson, "[\s\S]*""recipients""\s*:\s*\[([\s\S]*?)\][\s\S]*", "$1")

; Extract each recipient object
pos := 1
while (pos := RegExMatch(recipientSection, """name""\s*:\s*""([^""]+)""", nameMatch, pos))
{
    recipientNames.Push(nameMatch1)
    pos += StrLen(nameMatch)
}

pos := 1
while (pos := RegExMatch(recipientSection, """smsGateway""\s*:\s*""([^""]+)""", gatewayMatch, pos))
{
    recipients.Push(gatewayMatch1)
    pos += StrLen(gatewayMatch)
}

; Parse messages
messages := []
msgSection := RegExReplace(settingsJson, "[\s\S]*""messages""\s*:\s*\[([\s\S]*?)\][\s\S]*", "$1")
Loop, Parse, msgSection, `n, `r
{
    if InStr(A_LoopField, """")
    {
        msg := RegExReplace(A_LoopField, ".*""([^""]+)"".*", "$1")
        if (msg != A_LoopField)
            messages.Push(msg)
    }
}

; Arrays to store hotkey mapping data
hotkeyRecipients := []
hotkeyMessages := []
hotkeyList := []

; Extract hotkeys section
hotkeySection := RegExReplace(settingsJson, "[\s\S]*""hotkeys""\s*:\s*\[([\s\S]*?)\]\s*\}[\s\S]*", "$1")

; Parse each hotkey object
currentPos := 1
while (currentPos > 0)
{
    ; Find next opening brace for a hotkey object
    openBrace := InStr(hotkeySection, "{", , currentPos)
    if (openBrace = 0)
        break

    ; Find the matching closing brace
    closeBrace := InStr(hotkeySection, "}", , openBrace)
    if (closeBrace = 0)
        break

    ; Extract this hotkey object
    objText := SubStr(hotkeySection, openBrace, closeBrace - openBrace + 1)

    ; Parse the fields
    hotkey := ""
    recipientIndex := -1
    messageIndex := -1

    if RegExMatch(objText, """hotkey""\s*:\s*""([^""]+)""", hkMatch)
        hotkey := hkMatch1
    if RegExMatch(objText, """recipientIndex""\s*:\s*(\d+)", riMatch)
        recipientIndex := riMatch1
    if RegExMatch(objText, """messageIndex""\s*:\s*(\d+)", miMatch)
        messageIndex := miMatch1

    ; If we got all three values, register the hotkey
    if (hotkey != "" && recipientIndex >= 0 && messageIndex >= 0)
    {
        ; Convert to 1-based index
        rIdx := recipientIndex + 1
        mIdx := messageIndex + 1

        ; Store in arrays
        hotkeyList.Push(hotkey)
        hotkeyRecipients.Push(rIdx)
        hotkeyMessages.Push(mIdx)

        ; Create the hotkey binding
        Hotkey, %hotkey%, HandleHotkey
    }

    ; Move to next object
    currentPos := closeBrace + 1
}

return

HandleHotkey:
    ; Get the hotkey that triggered this
    triggerKey := A_ThisHotkey

    ; Find the index of this hotkey in our list
    Loop, % hotkeyList.Length()
    {
        if (hotkeyList[A_Index] = triggerKey)
        {
            recipientIdx := hotkeyRecipients[A_Index]
            messageIdx := hotkeyMessages[A_Index]
            break
        }
    }

    ; Get recipient, name, and message
    recipient := recipients[recipientIdx]
    recipientName := recipientNames[recipientIdx]
    message := messages[messageIdx]

    ; Strip the number prefix from the message (e.g., "0: " from "0: Message text")
    cleanMessage := RegExReplace(message, "^\d+:\s*", "")

    SendSMSMessage(recipient, recipientName, cleanMessage)
return

; Function to send SMS
SendSMSMessage(recipient, recipientName, message)
{
    global gmailAddress, gmailAppPassword, timestampEnabled

    ; Add timestamp if enabled
    if (timestampEnabled = "true")
    {
        FormatTime, timestamp, , [HH:mm]
        displayMessage := recipientName . ", " . message . " " . timestamp
    }
    else
    {
        displayMessage := recipientName . ", " . message
    }

    ; Call PowerShell script with parameters
    scriptPath := A_ScriptDir . "\send-sms.ps1"
    psCommand := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ . scriptPath . """ -GmailAddress """ . gmailAddress . """ -GmailAppPassword """ . gmailAppPassword . """ -SmsGateway """ . recipient . """ -Message """ . message . """ -TimestampEnabled """ . timestampEnabled . """"

    ; Run PowerShell script
    RunWait, %psCommand%, , Hide

    ; Show notification (0=no icon, uses tray icon if set)
    TrayTip, SMS Sent, %displayMessage%, 3, 0
}
