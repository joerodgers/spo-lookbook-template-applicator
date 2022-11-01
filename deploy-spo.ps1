#requires -modules "PnP.PowerShell"

param
(
    [Parameter(Mandatory=$true)]
    [string]
    $PowerAutomateOrLogicAppTriggerUrl,

    [Parameter(Mandatory=$true)]
    [string]
    $Tenant,

    [Parameter(Mandatory=$true)]
    [string]
    $ClientId,

    [Parameter(Mandatory=$true)]
    [string]
    $CertificateThumbprint,

    [Parameter(Mandatory=$false)]
    [switch]
    $Force
)

[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 
[System.Net.ServicePointManager]::SecurityProtocol   = [System.Net.SecurityProtocolType]::Tls12

# connect to tenant root and upload thumbnails

    Connect-PnPOnline `
        -Url        "https://$Tenant.sharepoint.com" `
        -ClientId   $ClientId `
        -Thumbprint $CertificateThumbprint `
        -Tenant     "$Tenant.onmicrosoft.com" `
        -ErrorAction Stop

    Add-PnPFile `
        -Path        "$PSScriptRoot\images\thumbnail-thelanding.jpg" `
        -Folder      "SiteAssets" `
        -ErrorAction Stop 

    Add-PnPFile `
        -Path        "$PSScriptRoot\images\thumbnail-theperspective.jpg" `
        -Folder      "SiteAssets" `
        -ErrorAction Stop 

    Disconnect-PnPOnline

# uploaded images to the root location

    $landingThumbnailImageUrl     = "https://$Tenant.sharepoint.com/SiteAssets/thumbnail-thelanding.jpg"
    $perspectiveThumbnailImageUrl = "https://$Tenant.sharepoint.com/SiteAssets/thumbnail-theperspective.jpg"


# connect to tenant admin

    Connect-PnPOnline `
        -Url        "https://$Tenant-admin.sharepoint.com" `
        -ClientId   $ClientId `
        -Thumbprint $CertificateThumbprint `
        -Tenant     "$Tenant.onmicrosoft.com"

# create site script 

    $template = '
    {{
    "$schema" : "schema.json",
    "actions" : [
        {{
        "verb" : "triggerFlow",
        "url"  : "{0}",
        "name" : "Apply Site Template",
        "parameters" : {{
            "event"    : "site creation",
            "product"  : "SharePoint Online",
            "template" : "{1}",
            "force"    : false
        }}
        }}
    ]
    }}
    '

    if( $Force.IsPresent -or -not ($landingSiteScript = Get-PnPSiteScript | Where-Object -Property "Title" -eq "Landing Template Applicator") )
    {
        Write-Host "Provisioning Site Script: Landing"

        $schema = $template -f $powerAutomateOrLogicAppTriggerUrl, "Landing"

        $landingSiteScript = Add-PnPSiteScript `
                                    -Title       "Landing Template Applicator" `
                                    -Description "Applies 'The Landing' template to a SharePoint Online Communications site." `
                                    -Content     $schema
    }


    if( -not $Force.IsPresent -and -not ($perspectiveSiteScript = Get-PnPSiteScript | Where-Object -Property "Title" -eq "Perspective Template Applicator") )
    {
        Write-Host "Provisioning Site Script: Perspective"

        $schema = $template -f $powerAutomateOrLogicAppTriggerUrl, "Perspective"

        $perspectiveSiteScript = Add-PnPSiteScript `
                                    -Title       "Perspective Template Applicator" `
                                    -Description "Applies 'The Perspective' template to a SharePoint Online Communications site." `
                                    -Content     $schema
    }


# create the site designs

if( -not (Get-PnPSiteDesign | Where-Object -Property "Title" -eq "The Landing - News, resources, personalized content" ) )
{
    Write-Host "Provisioning Site Design: Landing"

    Add-PnPSiteDesign `
        -Title           "The Landing - News, resources, personalized content" `
        -Description     "This communication site is designed to be the place where your employees can find the news and resources they need, plus personalized content tailored just for them." `
        -ThumbnailUrl    $landingThumbnailImageUrl `
        -SiteScriptIds   $landingSiteScript.Id `
        -WebTemplate     "CommunicationSite"
}
else
{
    Write-Warning "The Landing site design already exists, skipping."
}

if( -not (Get-PnPSiteDesign | Where-Object -Property "Title" -eq "The Perspective - News, video, personalized content" ) )
{
    Write-Host "Provisioning Site Design: Perspective"

    Add-PnPSiteDesign `
        -Title           "The Perspective - News, video, personalized content" `
        -Description     "Designed to offer news and personalized content, this site also includes videos to inspire even more engagement." `
        -ThumbnailUrl    $perspectiveThumbnailImageUrl `
        -SiteScriptIds   $perspectiveSiteScript.Id `
        -WebTemplate     "CommunicationSite"
}
else
{
    Write-Warning "The Perspective site design already exists, skipping."
}

<# 

# Remove Solution Commands

    Get-PnPSiteDesign | Where-Object -Property "Title" -eq "The Perspective - News, video, personalized content" | Remove-PnPSiteDesign -Force
    Get-PnPSiteDesign | Where-Object -Property "Title" -eq "The Landing - News, resources, personalized content" | Remove-PnPSiteDesign -Force

    Get-PnPSiteScript | Where-Object -Property "Title" -eq "Landing Template Applicator"     | Remove-PnPSiteScript -Force
    Get-PnPSiteScript | Where-Object -Property "Title" -eq "Perspective Template Applicator" | Remove-PnPSiteScript -Force

#>
