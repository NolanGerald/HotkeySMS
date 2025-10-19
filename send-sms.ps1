param(
    [string]$GmailAddress,
    [string]$GmailAppPassword,
    [string]$SmsGateway,
    [string]$Message,
    [string]$TimestampEnabled
)

# Remove any spaces from app password (Gmail adds spaces when copying)
$GmailAppPassword = $GmailAppPassword -replace '\s', ''

try {
    # Create SMTP client (like Python's smtplib)
    $smtp = New-Object System.Net.Mail.SmtpClient('smtp.gmail.com', 587)
    $smtp.EnableSsl = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($GmailAddress, $GmailAppPassword)

    # Create email message
    $mailMessage = New-Object System.Net.Mail.MailMessage
    $mailMessage.From = $GmailAddress
    $mailMessage.To.Add($SmsGateway)
    $mailMessage.Subject = ''

    # Add timestamp if enabled
    if ($TimestampEnabled -eq "true") {
        $timestamp = Get-Date -Format "[HH:mm]"
        $mailMessage.Body = "$Message $timestamp"
    } else {
        $mailMessage.Body = $Message
    }

    # Send the message
    $smtp.Send($mailMessage)

    Write-Host "SMS sent successfully to $SmsGateway!"
    Write-Host "Message: $Message"

    # Cleanup
    $mailMessage.Dispose()
    $smtp.Dispose()

    exit 0
} catch {
    Write-Host "Error sending SMS: $($_.Exception.Message)"
    Write-Host "Gmail: $GmailAddress"
    Write-Host "Gateway: $SmsGateway"
    exit 1
}
