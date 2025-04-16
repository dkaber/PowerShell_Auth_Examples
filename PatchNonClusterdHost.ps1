#Basic Info:
$vCenterFQDN = "vcenter-mgmt.vcf.sddc.lab"
#$vCenterFQDN = <vCenter FQDN>
#hostID = <HostID>
#You can use the API calls below to select a sepcific host by name and have it return the MOID needed for this
$hostID = "host-3949390"

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
    "vmware-api-session-id" = $res
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$draftID = Invoke-RestMethod -uri "https://$vCenterFQDN/api/esx/settings/hosts/$hostID/software/drafts" -Method "POST" -Headers $session -SkipCertificateCheck

$baseImageBody = @{
    "version" = "8.0.3-0.60.24585383"
}

$componentBody = @{
    "components_to_set" = @{
            "VMware-VM-Tools" = "12.5.1.24649672-24649907"
    }
}

#Vendor Add-On Example using the Dell Add-On for PowerEdge Servers version 803-A03
$vendorAddOnBody = @{
    "name" = "DEL-ESXi"
    "version" = "803.24414501-A03"
}

$result = Invoke-RestMethod -uri "https://$vCenterFQDN/api/esx/settings/hosts/$hostID/software/drafts/$draftID/software/base-image" -Method "PUT" -Headers $session -body ($baseImageBody | ConvertTO-JSON) -SkipCertificateCheck
$componentResult = Invoke-RestMethod -uri "https://$vCenterFQDN/api/esx/settings/hosts/$hostID/software/drafts/$draftID/software/components" -Method "PATCH" -Headers $session -body ($componentBody | ConvertTO-JSON) -SkipCertificateCheck
$addOnResult = Invoke-RestMethod -uri "https://$vCenterFQDN/api/esx/settings/hosts/$hostID/software/drafts/$draftID/software/add-on" -Method "PUT" -Headers $session -body ($vendorAddOnBody | ConvertTO-JSON) -SkipCertificateCheck

#Scan the draft:
$result = Invoke-RestMethod -uri "https://$vCenterFQDN/api/esx/settings/hosts/$hostID/software/drafts/$draftID`?action=scan&vmw-task=true" -Method "POST" -headers $session -SkipCertificateCheck

#wait until the scan job is complete before moving on:
$percentComplete = 0
do {
    Start-Sleep -seconds 30
    $jobStatus = Invoke-RestMethod -uri "https://$vCenterFQDN/api/cis/tasks/$result" -Method "GET" -headers $session -SkipCertificateCheck
    $percentComplete = $jobStatus.Progress.completed
    write-host "Percent Complete: $percentComplete"
}until($percentComplete -eq 100)

#Commit And Scan
#Example Output From API Explorer:
#curl -X POST 'https://vcenter-mgmt.vcf.sddc.lab/api/esx/settings/hosts/host-3949363/software/drafts/29?action=commit&vmw-task=true' -H 'vmware-api-session-id: <valid-vapi-session-id>' -H 'Content-type: application/json' -d '{ "message": "" }'
$messageBody = @{
    "message" = $null
}
$result = Invoke-RestMethod -uri "https://$vCenterFQDN/api/esx/settings/hosts/$hostID/software/drafts/$draftID`?action=commit&vmw-task=true" -Method "POST" -headers $session -body ($messageBody | ConvertTo-JSON) -SkipCertificateCheck

#wait until the scan job is complete before moving on:
$percentComplete = 0
do {
    Start-Sleep -seconds 30
    $jobStatus = Invoke-RestMethod -uri "https://$vCenterFQDN/api/cis/tasks/$result" -Method "GET" -headers $session -SkipCertificateCheck
    $percentComplete = $jobStatus.Progress.completed
    write-host "Percent Complete: $percentComplete"
}until($percentComplete -eq 100)

#Apply Software:
#Example Output From API Explorer:
#curl -X POST 'https://vcenter-mgmt.vcf.sddc.lab/api/esx/settings/hosts/host-3949363/software?action=apply&vmw-task=true' -H 'vmware-api-session-id: <valid-vapi-session-id>' -H 'Content-type: application/json' -d '{ "accept_eula": true, "commit": "" }'
$commitBody = @{
    "accept_eula" = $true
    "commit" = ""
}
Invoke-RestMethod -uri "https://$vCenterFQDN/api/esx/settings/hosts/$hostID/software?action=apply&vmw-task=true" -Method "POST" -headers $session -body ($commitBody | ConvertTo-JSON) -SkipCertificateCheck