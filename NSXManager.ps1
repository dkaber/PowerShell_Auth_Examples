<# Old code to suppress self-signed certs. Moving forward, use PowerShell 7 and the -SkipCertificateCheck flag when using the Invoke-RestMethod CMDLET
This should hopefully prevent any issues with the "underlying connection was closed: An unexpected error occured on a send" message
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Ignore self-signed certs (source: https://aventistech.com/kb/how-to-connect-to-vcenter-6-7-via-rest-api-using-powershell/)
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()
#>
#Update These Variables to reflect your enviornment:
#FQDN for NSX GM
$nsxGM = "<NSX Manager FQDN or IP>"
$domainID = "<Insert Domain Name>"

#Get Credentials to build auth:
$credential = Get-Credential
$username = $credential.UserName
$pass = $credential.Password
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
$userpass  = $username + ":" + $password

#Build Auth Header:
$bytes= [System.Text.Encoding]::UTF8.GetBytes($userpass)
$encodedlogin=[Convert]::ToBase64String($bytes)
$authheader = "Basic " + $encodedlogin
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("Authorization",$authheader)
$header.Add("Content-Type","application/json")