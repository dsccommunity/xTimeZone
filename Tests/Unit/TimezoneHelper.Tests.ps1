[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if (Get-Module -Name TimezoneHelper -ErrorAction SilentlyContinue)
{
    Remove-Module -Name TimezoneHelper
}
Import-Module -Name (Join-Path -Path $moduleRoot -ChildPath 'DSCResources\TimezoneHelper.psm1') -Force

#region Pester Tests
InModuleScope TimezoneHelper {
    Describe 'Get-Timezone' {
        Context "Current Timezone is set to 'Pacific Standard Time'" {
            Mock -CommandName Get-CimInstance -MockWith {
                @{ StandardName = 'Pacific Standard Time' }
            }
            It "Returns 'Pacific Standard Time'." {
                Get-Timezone | should be 'Pacific Standard Time'
            }
            Assert-MockCalled -CommandName Get-CimInstance -Exactly 1

        }
    }
    Describe 'Set-Timezone' {
        Context "'Add-Type' is not available, Tzutil Returns 0" {
            Mock -CommandName Get-Command
            Mock -CommandName 'TzUtil.exe' -MockWith { $Global:LASTEXITCODE = 0; return "OK" }
            Mock -CommandName Add-Type
            It "Should not throw exception" {
                { Set-Timezone -Timezone 'Eastern Standard Time'}  | Should Not Throw
            }
            Assert-MockCalled -CommandName Get-Command -Exactly 1
            Assert-MockCalled -CommandName TzUtil.exe -Exactly 1
            Assert-MockCalled -CommandName Add-Type -Exactly 0
        }
        Context "'Add-Type' is available" {
            Mock -CommandName Get-Command -MockWith { @{ Name = 'Add-Type'} }
            Mock -CommandName 'TzUtil.exe' -MockWith { $Global:LASTEXITCODE = 0; return "OK" }
            Mock -CommandName Set-TimeZoneUsingNET
            It "Should throw exception" {
                { Set-Timezone -Timezone 'Eastern Standard Time'}  | Should Not Throw
            }
            Assert-MockCalled -CommandName Get-Command -Exactly 1
            Assert-MockCalled -CommandName TzUtil.exe -Exactly 0
            Assert-MockCalled -CommandName Set-TimeZoneUsingNET -Exactly 1
        }
    }
}
