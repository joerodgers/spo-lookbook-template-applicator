#requires -Modules "AzureAD"

param
(
    [Parameter(Mandatory=$true)]
    [Guid]
    $FunctionMSIObjectId
)

Connect-AzureAD 

$spo = Get-AzureADServicePrincipal `
    -Filter "appId eq '00000003-0000-0ff1-ce00-000000000000'"

$function = Get-AzureADServicePrincipal `
    -ObjectId   $FunctionMSIObjectId `
    -ErrorAction Stop

New-AzureAdServiceAppRoleAssignment `
    -ObjectId    $function.ObjectId `
    -PrincipalId $function.ObjectId `
    -ResourceId  $spo.ObjectId `
    -Id          "678536fe-1083-478a-9c59-b99265e6b0d3"  <# Sites.FullControl.All #>
