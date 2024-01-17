# powershell 6.0

$base_url = 'https://yoursplunkserverfqdn:8089'
$auth_endpoint = "$base_url/services/auth/login"
$search_endpoint = "$base_url/servicesNS/nobody/search/search/jobs/export"

$cred = Get-Credential

$res = Invoke-WebRequest -Method Post -Uri $auth_endpoint -ContentType 'application/x-www-form-urlencoded' -Body @{username = $cred.UserName; password = $cred.GetNetworkCredential().password} -TimeoutSec 30 -ErrorAction Stop -SkipCertificateCheck

$sessionKey = if ($res.StatusCode -eq 200) {
    ([xml]$res.Content).ChildNodes.sessionKey
}
else {
    throw "$($res.RawContent)"
}


$res = Invoke-WebRequest -Method Post -Uri $search_endpoint -Headers @{Authorization = "Splunk $sessionKey"} -Body @{
    search = "search * | head 5"
    output_mode = "json"
} -TimeoutSec 30 -ErrorAction Stop -SkipCertificateCheck

$content = if ($res.StatusCode -eq 200) {
    $res.Content
}
else {
    throw "$($res.RawContent)"
}

$content -split "`n" | ForEach-Object { $_ | ConvertFrom-Json | Select-Object -ExpandProperty result }