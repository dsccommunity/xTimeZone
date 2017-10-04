# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath (Join-Path -Path 'TimezoneDsc.ResourceHelper' `
            -ChildPath 'TimezoneDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'TimezoneDsc.Common' `
    -ResourcePath $PSScriptRoot

<#
    .SYNOPSIS
        Get the of the current timezone Id.
#>
function Get-TimeZoneId
{
    [CmdletBinding()]
    param()

    if (Test-Command -Name 'Get-Timezone' -Module 'Microsoft.PowerShell.Management')
    {
        Write-Verbose -Message ($LocalizedData.GettingTimezoneMessage -f 'Cmdlets')

        $Timezone = (Get-Timezone).StandardName
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.GettingTimezoneMessage -f 'CIM')

        $TimeZone = (Get-CimInstance `
                -ClassName WIN32_Timezone `
                -Namespace root\cimv2).StandardName
    }

    Write-Verbose -Message ($LocalizedData.CurrentTimezoneMessage `
            -f $Timezone)

    $timeZoneInfo = [System.TimeZoneInfo]::GetSystemTimeZones() |
        Where-Object StandardName -eq $TimeZone

    return $timeZoneInfo.Id
} # function Get-TimeZoneId

<#
    .SYNOPSIS
        Compare a timezone Id with the current timezone Id.

    .PARAMETER TimeZoneId
        The Id of the Timezone to compare with the current timezone.
#>
function Test-TimeZoneId
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    # Test Expected is same as Current
    $currentTimeZoneId = Get-TimeZoneId

    return $TimeZoneId -eq $currentTimeZoneId
} # function Test-TimeZoneId

<#
    .SYNOPSIS
        Sets the current timezone using a timezone Id.

    .PARAMETER TimeZoneId
        The Id of the Timezone to set.
#>
function Set-TimeZoneId
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    if (Test-Command -Name 'Set-Timezone' -Module 'Microsoft.PowerShell.Management')
    {
        Set-Timezone -Id $TimezoneId
    }
    else
    {
        if (Test-Command -Name 'Add-Type' -Module 'Microsoft.Powershell.Utility')
        {
            # We can use Reflection to modify the TimeZone
            Write-Verbose -Message ($LocalizedData.SettingTimezoneMessage `
                    -f $TimeZoneId, '.NET')

            Set-TimeZoneUsingNET -TimezoneId $TimeZoneId
        }
        else
        {
            # For anything else use TZUTIL.EXE
            Write-Verbose -Message ($LocalizedData.SettingTimezoneMessage `
                    -f $TimeZoneId, 'TZUTIL.EXE')

            try
            {
                & tzutil.exe @('/s', $TimeZoneId)
            }
            catch
            {
                $errorMsg = $_.Exception.Message

                Write-Verbose -Message $errorMsg
            } # try
        } # if
    } # if

    Write-Verbose -Message ($LocalizedData.TimezoneUpdatedMessage `
            -f $TimeZone)
} # function Set-TimeZoneId

<#
    .SYNOPSIS
        This function exists so that the ::Set method can be mocked by Pester.

    .PARAMETER TimeZoneId
        The Id of the Timezone to set using .NET
#>
function Set-TimeZoneUsingNET
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    # Add the [TimeZoneHelper.TimeZone] type if it is not defined.
    if (-not ([System.Management.Automation.PSTypeName]'TimeZoneHelper.TimeZone').Type)
    {
        Write-Verbose -Message ($LocalizedData.AddingSetTimeZonedotNetTypeMessage)

        $setTimeZoneCs = Get-Content `
            -Path (Join-Path -Path $PSScriptRoot -ChildPath 'SetTimeZone.cs') `
            -Raw

        Add-Type `
            -Language CSharp `
            -TypeDefinition $setTimeZoneCs
    } # if

    [Microsoft.PowerShell.xTimeZone.TimeZone]::Set($TimeZoneId)
} # function Set-TimeZoneUsingNET

<#
    .SYNOPSIS
        This function tests if a cmdlet exists.

    .PARAMETER Name
        The name of the cmdlet to check for.

    .PARAMETER Module
        The module containing the command.
#>
function Test-Command
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Module
    )

    return ($null -ne (Get-Command @PSBoundParameters -ErrorAction SilentlyContinue))
} # function Test-Command

Export-ModuleMember -Function @(
    'Get-TimeZoneId'
    'Test-TimeZoneId'
    'Set-TimeZoneId'
    'Set-TimeZoneUsingNET'
    'Test-Command'
)
