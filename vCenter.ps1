#Basic Info:
$vCenterFQDN = <vCenter FQDN>

#Prompt for credentials and format it appropriately for the request
$Credential = Get-Credential
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.UserName+':'+$Credential.GetNetworkCredential().Password))

#Build Header:
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("Accept","application/json")
$header.Add("Content-Type","application/json")
$header.Add("Authorization","Basic $auth")

#Generate an authenticated session/session ID
$res = Invoke-REstMethod -uri "https://$vCenterFQDN/api/session" -Method "POST" -Headers $header -SkipCertificateCheck

#Use this variable as your header going forward. You do not need to use the ConvertTo-JSON cmdlet
$session = @{
    "vmware-api-session-id" = $res.value
}

#sample API call to get list of VMs
$result = Invoke-RestMethod -uri "https://$vCenterFQDN/api/vcenter/vm" -Method "GET" -Headers $header -SkipCertificateCheck
