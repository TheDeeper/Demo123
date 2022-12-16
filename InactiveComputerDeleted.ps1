#1-Sccm database'den inactive durumda olan clientlar filtre edilir.
#2-Foreach ile filtre edilen her bir inactive client'ın active directory hesabı kontrol edilir.
#3-Eğer AD'de yoksa ilgili computer sccm database'den silinir.
#4-Silinen computer accountları mail ile attach edilerek rapor halinde gönderilir. Ve temizlenir.

Set-Location 'D:\ConfigMgr\AdminConsole\bin\'
Import-Module .\ConfigurationManager.psd1
Set-Location EM1:
#1
$InactiveClients = Get-CMDevice | Where-Object { $_.ClientActiveStatus -eq 0 -or $_.ClientActiveStatus -eq $null -and $_.Name -notlike "*Unknown Computer*" -and $_.Name -notlike "*Provisioning Device*" }
ForEach($InactiveClient in $InactiveClients) {
     
    Try {
 
        If(-not(Get-ADComputer -Identity $($InactiveClient.Name))) { } #2
    }

    Catch {

        Write-Output $InactiveClient.Name | Out-File -FilePath C:\Users\onuromertunc\Desktop\RemoveDevice.TXT -Append 
        Write-Host $InactiveClient.Name -ForegroundColor Green 
        Remove-CMDevice -Name $($InactiveClient.Name) -Force #3
    }  
 
}
#4
$EmailRecipient = "mail@company.com.tr"
$CC = "mailcc@company.com.tr","mailcc@company.com.tr"
$EmailSender = "sccm@company.com.tr"
$SMTPServer = "internalsmtp.company.local"
If  ($InactiveClients.Count -ne 0) #Silinecek client sayisi 0'dan buyukse mail gonderir.
{
   $Body =  "SCCM'de inactive olupta active directory'de hesabi bulunmayan computer accountlari, SCCM database'den silinmistir. 
   Silinen bilgisayar isimleri ektedir."

    Send-MailMessage -To $EmailRecipient -Cc $CC -From $EmailSender  -Subject "SCCM'den Silinen Inactive Bilgisayarlar ($(Get-Date -format 'yyyy-MMM-dd'))" -SmtpServer $SMTPServer -Body $Body -Attachments "C:\Users\onuromertunc\Desktop\RemoveDevice.TXT" 
}

Start-Sleep -Seconds 10
Remove-Item -Path C:\Users\onuromertunc\Desktop\RemoveDevice.TXT -Recurse