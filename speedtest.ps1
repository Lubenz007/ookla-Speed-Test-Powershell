$StorageAccountName = "StorageAcount"
$Key = "Storagekey"
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $Key
$Table = (Get-AzStorageTable -Context $StorageContext | Where-Object {$_.name -eq "Speedtest"}).CloudTable
$applocation = "C:\apps\speedtest"
$SpeedTestTxt = "c:\temp\speedtext.txt"
 
$i = 0
while ($i -eq 0)
{
    $PartitionKey = "1"
    $SpeedTestResults=@()
    $SpeedtestObj=@()
    $SpeedTestResults = & "$($applocation)\speedtest.exe" --progress=no --format=json
    $SpeedtestResults = $SpeedTestResults | ConvertFrom-Json
    [PSCustomObject]$SpeedtestObj = @{
        Time = Get-Date -Format "dd/MM/yyyy HH:mm K"
        downloadspeed = [math]::Round($SpeedtestResults.download.bandwidth / 1000000 * 8, 2)
        uploadspeed   = [math]::Round($SpeedtestResults.upload.bandwidth / 1000000 * 8, 2)
        packetloss    = ($($SpeedtestResults.packetLoss).ToString("P"))
        isp           = $SpeedtestResults.isp
        ExternalIP    = $SpeedtestResults.interface.externalIp
        InternalIP    = $SpeedtestResults.interface.internalIp
        UsedServer    = $SpeedtestResults.server.host
        location      = $SpeedTestResults.server.location
        Jitter        = [math]::Round($SpeedtestResults.ping.jitter)
        Latency       = [math]::Round($SpeedtestResults.ping.latency)       
    }
    # Henda í table storage
    #Add-AzTableRow -table $Table -PartitionKey $PartitionKey -RowKey (Get-Date).Ticks -property $SpeedtestObj
    # Henda í skrá
    "$($SpeedtestObj.time)`t   DL: $($SpeedtestObj.downloadspeed)` Mbps   UL: $($SpeedtestObj.uploadspeed)` Mbps   PING: $($SpeedtestObj.Latency)`ms   LOSS: $($SpeedtestObj.packetloss)   ISP: $($SpeedtestObj.isp) ($($SpeedtestObj.ExternalIP))   SERVER: $($SpeedtestObj.location) $($SpeedtestObj.UsedServer)" | Out-File -Append -FilePath $SpeedTestTxt
    Start-Sleep -Seconds 300
}
