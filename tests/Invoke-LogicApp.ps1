[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 
[System.Net.ServicePointManager]::SecurityProtocol   = [System.Net.SecurityProtocolType]::Tls12

$siteUrl  = "https://contoso.sharepoint.com/sites/teamsite"
$template = "Landing" # Landing OR Perspective 

# url of your logic app
$logicAppUri = 'https://prod-61.eastus.logic.azure.com:443/workflows/<........>' 

# request body
$body = ( [PSCustomObject] @{ webUrl = $siteUrl; parameters = [PSCustomObject] @{ template = $template; } } ) | ConvertTo-Json

# simulate spo site creation webhook post request
Invoke-RestMethod -Method Post -Uri $logicAppUri -Body $body -ContentType "application/json"
