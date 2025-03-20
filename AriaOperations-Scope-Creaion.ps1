#BasicInfo:
$ariaOpsServer = "Aria Operations FQDN"
#$authSource = "local"
$resourceKind = "ClusterComputeResource"

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
$accessToken = Invoke-RestMethod -Uri $uri -Method POST -Headers $header -body ($authbody | ConvertTo-JSON) -SkipCertificateCheck
$accessToken = "OpsToken " + $accessToken.token

#add access token to Header
$header.Add("Authorization",$accessToken)

$resources = Invoke-RestMethod -uri "https://$ariaOpsServer/suite-api/api/resources?page=0&pageSize=1000&resourceKind=$resourceKind&_no_links=true" -Method "GET" -Headers $header

$resources = $resources.resourceList
Foreach ($res in $resources){
    $resName = $res.ResourceKey.Name
    $resID = $res.identifier
    $resourceSelection = @{
        "type" = "PROPAGATE"
        "resourceId" = @($resID)
    }
    $traversalSpecInstances = @{
            "adapterKind" = "VMWARE"
            "resourceKind" = "vSphere World"
            "name" = "vSphere Hosts and Clusters"
            "selectAllResources" = $false
            "resourceSelection" = @($resourceSelection)    }
    $body = @{
        "description" = "Scripted Scope Creation of $resName"
        "name" = "Scripted Scope Creation of $resName"
        "traversalSpecInstances" = @($traversalSpecInstances)
    }
    Invoke-restMethod -uri "https://$ariaOpsServer/suite-api/api/auth/scopes" -Method "POST" -header $header -body ($body | convertTo-Json -depth 10)  -SkipCertificateCheck
}

#Create Group and Assign it to a Scope:
$groupRolePermissions = @{
    "roleName" = "PowerUser"
    "allowAllObjects" = $false
    "scopeId" = "f386ab7e-75ec-47b2-a92b-2516b8a6b415"
}
$groupBody = @{
    "name" = "Group Name"
    "role-permissions" = @($groupRolePermissions)
}

#Example output of a scope
<#{
    "id": "e7e038ab-77a0-4437-8350-3eac24e903f1",
    "name": "wkld01 Only",
    "description": "",
    "createdBy": "993d3935-0531-4c4c-a608-2bd3ba1d06e8",
    "creationTime": 1741790930709,
    "lastModifiedBy": "993d3935-0531-4c4c-a608-2bd3ba1d06e8",
    "lastModifiedTime": 1741790930709,
    "traversalSpecInstances": [
      {
        "adapterKind": "VMWARE",
        "resourceKind": "vSphere World",
        "name": "vSphere Hosts and Clusters",
        "resourceSelection": [
          {
            "type": "SPECIFIC",
            "resourceId": [
              "c2a132f3-c900-49ca-8023-21fcb309f68e"
            ]
          }
        ],
        "selectAllResources": false
      }
    ]
  } 
 #>

 #Example output of a group
<#{
    "id": "27e3cccc-0848-4ea5-a6b3-e4c44dad0361",
    "name": "wkldGroup",
    "description": "",
    "displayName": "wkldGroup",
    "userIds": [
      "c02e909b-7d42-4d28-9df6-914eeafa109b"
    ],
    "roleNames": [
      "PowerUser"
    ],
    "role-permissions": [
      {
        "roleName": "PowerUser",
        "scopeId": "60fc6b21-21dd-419c-9781-8f44f462cefb",
        "allowAllObjects": false
      }
    ],
    "links": [
      {
        "href": "/suite-api/api/auth/users/c02e909b-7d42-4d28-9df6-914eeafa109b",
        "rel": "RELATED",
        "name": "containedUser"
      },
      {
        "href": "/suite-api/api/auth/usergroups/27e3cccc-0848-4ea5-a6b3-e4c44dad0361",
        "rel": "SELF",
        "name": "linkToSelf"
      },
      {
        "href": "/suite-api/api/auth/usergroups/27e3cccc-0848-4ea5-a6b3-e4c44dad0361/permissions",
        "rel": "RELATED",
        "name": "userGroupPermissions"
      }
    ]
  }
  #>