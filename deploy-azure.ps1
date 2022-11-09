#requires -modules "Az.Resources", "Az.Accounts", "Az.WebSites"

param
(
    [Parameter(Mandatory=$true)]
    [Guid]
    $TenantId,

    [Parameter(Mandatory=$true)]
    [Guid]
    $SubscriptionId,

    [Parameter(Mandatory=$true)]
    [string]
    $ResourceGroup,

    [Parameter(Mandatory=$false)]
    [string]
    $Location = "eastus"
)

[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials 
[System.Net.ServicePointManager]::SecurityProtocol   = [System.Net.SecurityProtocolType]::Tls12   

$ctx = Get-AzContext

if( $ctx.Tenant.Id -ne $TenantId.ToString() -or $ctx.Subscription.SubscriptionId -ne $SubscriptionId.ToString() )
{
    Write-Host "[$(Get-Date)] - Prompting for Azure credentials"
    Login-AzAccount -Tenant $TenantId -WarningAction SilentlyContinue

    $ctx = Get-AzContext
}

$subscription  = Select-AzSubscription -SubscriptionId $SubscriptionId -Tenant $TenantId -WarningAction SilentlyContinue -Force
$templatePath  = Join-Path -Path $PSScriptRoot -ChildPath "main.bicep"
$storageAclsBicepPath = Join-Path -Path $PSScriptRoot -ChildPath "storage-acls.bicep"

Write-Host ""
Write-Host "[$(Get-Date)] - Connected as:   $($ctx.Account.Id)"
Write-Host "[$(Get-Date)] - Subscription:   $($subscription.Subscription.Name)"
Write-Host "[$(Get-Date)] - Resource Group: $ResourceGroup"
Write-Host "[$(Get-Date)] - Template Path:  $templatePath"
Write-Host "[$(Get-Date)] - Log Path:       $PSScriptRoot\deploymentlogs"


# make sure log directory exists

    if( -not (Test-Path -Path "$PSScriptRoot\deploymentlogs" -PathType Container) )
    {
        $null = New-Item -ItemType Directory -Path "$PSScriptRoot\deploymentlogs"
    }

# resource group validation

    if( -not (Get-AzResourceGroup -Name $ResourceGroup -Location $Location -ErrorAction SilentlyContinue) )
    {
        Write-Error "Resource group not found: $ResourceGroup"
        return
    }

# start infrastructure deployment

    Write-Host 
    Write-Host "[$(Get-Date)] - Starting infrastructure deployment"
   
    $deployment = New-AzResourceGroupDeployment `
                        -ResourceGroupName     $ResourceGroup `
                        -TemplateFile          $templatePath `
                        -Verbose

    if( -not $deployment ) {return }
    
    Write-Host "[$(Get-Date)] - Deployment $($deployment.ProvisioningState)"

    if( $deployment.OutputsString )
    {
        $deployment.OutputsString | Set-Content -Path "$PSScriptRoot\deploymentlogs\deploymentoutput_$(Get-Date -Format FileDateTime).log"
    }

    if( $deployment.ProvisioningState -ne "Succeeded") { return }

    # start  zip deployment

    $timestamp = Get-Date -Format 'yyyy-MM-dd'

    Write-Host 
    Write-Host "[$(Get-Date)] - Starting Zip deployment"
    Write-Host "[$(Get-Date)] - Archiving function code to $PSScriptRoot\function_${timestamp}.zip"


    $null = Compress-Archive `
                -Path            "$PSScriptRoot\Functions\*" `
                -DestinationPath "$PSScriptRoot\function_${timestamp}.zip" `
                -Force `
                -ErrorAction Stop
      
    Write-Host "[$(Get-Date)] - Publishing compressed archive to Azure Function: $($deployment.Outputs.functionApp.Value)"

    $null = Publish-AzWebApp `
                -ResourceGroupName $ResourceGroup `
                -Name              $deployment.Outputs.functionApp.Value `
                -ArchivePath       "$PSScriptRoot\function_${timestamp}.zip" `
                -Force `
                -ErrorAction Stop
    
    Write-Host "[$(Get-Date)] - Completed Zip deployment"


    Write-Host "[$(Get-Date)] - Starting post-setup infrastructure deployment to secure storage account"

    $deployment = New-AzResourceGroupDeployment `
                        -ResourceGroupName     $ResourceGroup `
                        -TemplateFile          $storageAclsBicepPath `
                        -Verbose
