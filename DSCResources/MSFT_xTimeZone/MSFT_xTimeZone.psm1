$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the Networking Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'TimeZoneDsc.Common' `
            -ChildPath 'TimeZoneDsc.Common.psm1'))

# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'TimeZoneDsc.ResourceHelper' `
            -ChildPath 'TimeZoneDsc.ResourceHelper.psm1'))

# Import Localization Strings
$LocalizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xTimeZone' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
    Returns the current Timezone of the node.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER TimeZone
    Specifies the TimeZone.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TimeZone
    )

    Write-Verbose -Message ($LocalizedData.GettingTimezoneMessage)

    # Get the current TimeZone Id
    $currentTimeZone = Get-TimeZoneId

    $returnValue = @{
        IsSingleInstance = 'Yes'
        TimeZone         = $currentTimeZone
    }

    # Output the target resource
    return $returnValue
}

<#
    .SYNOPSIS
    Sets the current Timezone of the node.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER TimeZone
    Specifies the TimeZone.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TimeZone
    )

    $currentTimeZone = Get-TimeZoneId

    if ($currentTimeZone -ne $TimeZone)
    {
        Write-Verbose -Message ($LocalizedData.SettingTimezoneMessage)
        Set-TimeZoneId -TimeZone $TimeZone
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.TimezoneAlreadySetMessage `
                -f $Timezone)
    }
}

<#
    .SYNOPSIS
    Tests the current Timezone of the node.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER TimeZone
    Specifies the TimeZone.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TimeZone
    )

    Write-Verbose -Message ($LocalizedData.TestingTimezoneMessage)

    return Test-TimeZoneId -TimeZoneId $TimeZone
}

Export-ModuleMember -Function *-TargetResource
