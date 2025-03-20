#BasicInfo:
$ariaAutoServer = "Aria Auto FQDN"

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

#Get Refresh Token:
$uri = "https://" + $ariaAutoServer + "/csp/gateway/am/api/login?access_token"
$refreshToken = Invoke-RestMethod -uri $uri -Method POST -Headers $header -Body ($authBody | ConvertTo-Json) -SkipCertificateCheck
$refreshToken = $refreshToken.refresh_token
$refreshTokenBody = @{
    "refreshToken" = $refreshToken
}

#Get Access Token:
$uri = "https://" + $ariaAutoServer + "/iaas/api/login"
$accessToken = Invoke-RestMethod -Uri $uri -Method POST -Headers $header -body ($refreshTokenBody | ConvertTo-JSON) -SkipCertificateCheck
$accessToken = "Bearer " + $accessToken.token

#add access token to Header
$header.Add("Authorization",$accessToken)