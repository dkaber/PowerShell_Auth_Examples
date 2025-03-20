#BasicInfo:
$ariaOpsServer = "Aria Operations FQDN"
$authSource = "local"

#Get Credentials to build auth:
$credential = Get-Credential
$username = $credential.UserName
$pass = $credential.Password
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
$authBody  = @{
    "username" = $username
    "password" = $password
}

#Build Header:
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("Accept","application/json")
$header.Add("Content-Type","application/json")

#Get Access Token:
$uri = "https://" + $ariaOpsServer + "/suite-api/api/auth/token/acquire"
$accessToken = Invoke-RestMethod -Uri $uri -Method POST -Headers $header -body ($refreshTokenBody | ConvertTo-JSON) -SkipCertificateCheck
$accessToken = "OpsToken " + $accessToken.token

#add access token to Header
$header.Add("Authorization",$accessToken)