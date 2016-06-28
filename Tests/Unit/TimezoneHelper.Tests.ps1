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
    Describe 'Get-TimezoneId' {
        Context "Test Timezone where standard name is different to Id" {
            It "Should return 'Russia Time Zone 11'" {
                Get-TimezoneId -Timezone 'Russia TZ 11 Standard Time' | Should Be 'Russia Time Zone 11'
            }
        }
        Context "Test Timezone where standard name is the same as Id" {
            It "Should return 'GMT Standard Time'" {
                Get-TimezoneId -Timezone 'GMT Standard Time' | Should Be 'GMT Standard Time'
            }
        }
        Context "Test Timezone that does not exist" {
            It "Should return Empty" {
                Get-TimezoneId -Timezone 'Wonderland Time' | Should BeNullOrEmpty
            }
        }
    }
    Describe 'Test-Timezone' {
        Mock Get-TimeZone -MockWith { 'Russia TZ 11 Standard Time' }
        Context "Current timezone matches desired timezone" {
            It "Should return True" {
                Test-Timezone -ExpectTimeZoneId 'Russia Time Zone 11' | Should Be $True
            }
        }
        Context "Current timezone does not match desired timezone" {
            It "Should return False" {
                Test-Timezone -ExpectTimeZoneId 'GMT Standard Time' | Should Be $False
            }
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
