# Import the script containing the Split-Version function
. "$PSScriptRoot/../Test-ChocoUpgrade.ps1"

Describe "Split-Version" {
    It "should split version '1.2.3' correctly" {
        $result = Split-Version -Version "1.2.3"
        $expected = @{ Major = 1; Minor = 2; Hotfix = 3; Build = 0 }
        $result | Should -BeExactly $expected
    }

    It "should split version '4.5.6.789' correctly" {
        $result = Split-Version -Version "4.5.6.789"
        $expected = @{ Major = 4; Minor = 5; Hotfix = 6; Build = 789 }
        $result | Should -BeExactly $expected
    }

    It "should split version '7.8.9' correctly" {
        $result = Split-Version -Version "7.8.9"
        $expected = @{ Major = 7; Minor = 8; Hotfix = 9; Build = 0 }
        $result | Should -BeExactly $expected
    }

    It "should split version '10.11.12.1314' correctly" {
        $result = Split-Version -Version "10.11.12.1314"
        $expected = @{ Major = 10; Minor = 11; Hotfix = 12; Build = 1314 }
        $result | Should -BeExactly $expected
    }
}