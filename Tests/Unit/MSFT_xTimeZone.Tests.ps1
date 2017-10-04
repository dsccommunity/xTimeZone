$Script:DSCModuleName = 'xTimeZone'
$Script:DSCResourceName = 'MSFT_xTimeZone'

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $Script:DSCResourceName {
        $Script:DSCResourceName = 'MSFT_xTimeZone'

        Describe 'Schema' {
            It 'IsSingleInstance should be mandatory with one value.' {
                $timeZoneResource = Get-DscResource -Name xTimeZone
                $timeZoneResource.Properties.Where{ $_.Name -eq 'IsSingleInstance' }.IsMandatory | Should be $true
                $timeZoneResource.Properties.Where{ $_.Name -eq 'IsSingleInstance' }.Values | Should be 'Yes'
            }
        }

        Describe "$($Script:DSCResourceName)\Get-TargetResource" {
            Mock `
                -ModuleName xTimeZone `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            $TimeZone = Get-TargetResource `
                -TimeZone 'Pacific Standard Time' `
                -IsSingleInstance 'Yes'

            It 'Should return hashtable with Key TimeZone' {
                $TimeZone.ContainsKey('TimeZone') | Should Be $true
            }

            It 'Should return hashtable with Value that matches "Pacific Standard Time"' {
                $TimeZone.TimeZone = 'Pacific Standard Time'
            }
        }

        Describe "$($Script:DSCResourceName)\Set-TargetResource" {
            Mock `
                -ModuleName xTimeZone `
                -CommandName Set-TimeZoneId
            Mock `
                -ModuleName xTimeZone `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Eastern Standard Time' }

            It 'Call Set-TimeZoneId' {
                Set-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes'

                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -ModuleName xTimeZone `
                    -Exactly 1
            }

            It 'Should not call Set-TimeZoneId when Current TimeZone already set to desired State' {
                $SystemTimeZone = Get-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes'

                Set-TargetResource `
                    -TimeZone $SystemTimeZone.TimeZone `
                    -IsSingleInstance 'Yes'

                Assert-MockCalled `
                    -CommandName Set-TimeZoneId `
                    -ModuleName xTimeZone `
                    -Scope It `
                    -Exactly 0
            }
        }

        Describe "$($Script:DSCResourceName)\Test-TargetResource" {
            Mock `
                -ModuleName TimezoneHelper `
                -CommandName Get-TimeZoneId `
                -MockWith { 'Pacific Standard Time' }

            It 'Should return true when Test is passed Time Zone thats already set' {
                Test-TargetResource `
                    -TimeZone 'Pacific Standard Time' `
                    -IsSingleInstance 'Yes' | Should Be $true
            }

            It 'Should return false when Test is passed Time Zone that is not set' {
                Test-TargetResource `
                    -TimeZone 'Eastern Standard Time' `
                    -IsSingleInstance 'Yes' | Should Be $false
            }

        }
    } #end InModuleScope $DSCResourceName
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}
