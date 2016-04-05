$TestTimeZone = [PSObject]@{
    TimeZone         = 'Pacific Standard Time'
    IsSingleInstance = 'Yes'
}

configuration xTimezone_Config {
    Import-DscResource -ModuleName xTimeZone -ModuleVersion 1.3.0.0
    node localhost {
        xTimeZone Integration_Test {
            TimeZone         = $TestTimeZone.TimeZone
            IsSingleInstance = $TestTimeZone.IsSingleInstance
        }
    }
}
