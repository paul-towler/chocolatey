# Import the functions
$global:functionsPath = Join-Path ((Get-Item $PSScriptRoot).Parent) -ChildPath "source/functions.ps1"
. $functionsPath

# Load the functions into Pester
BeforeAll { . $functionsPath }

Describe "Chocolatey Package Management" {
    Context "Get-RemotePackage Function" {
        BeforeAll {
            Mock choco {
                if ($args[0] -eq "search" -and $args[1] -eq "notepadplusplus") {
                    return "notepadplusplus|8.4.7"
                }
                if ($args[0] -eq "list" -and $args[1] -eq "notepadplusplus" -and $args.Contains("--local")) {
                    return "notepadplusplus|7.8.9"
                }
                # Handle both search and list for non-existent packages
                if (($args[0] -eq "search" -or $args[0] -eq "list") -and $args[1] -ne "notepadplusplus") {
                    return $null
                }
                throw "Mocked choco command not recognized"
            }
        }

        It "Should get remote package version for 'notepadplusplus'" {
            $result = Get-RemotePackage -Package "notepadplusplus" -Remote
            $result | Should -Be "8.4.7"
        }

        It "Should get local package version for 'notepadplusplus'" {
            $result = Get-RemotePackage -Package "notepadplusplus" -Local
            $result | Should -Be "7.8.9"
        }

        It "Should handle error when package does not exist remotely" {
            { Get-RemotePackage -Package "fakepackage" -Remote } | Should -Throw
        }

        It "Should handle error when package does not exist locally" {
            { Get-RemotePackage -Package "fakepackage" -Local } | Should -Throw
        }
    }

    Context "Split-Version Function" {
        It "Should split valid version string" {
            $version = Split-Version -Version "1.2.3"
            $version.Major | Should -Be 1
            $version.Minor | Should -Be 2
            $version.Hotfix | Should -Be 3
            $version.Build | Should -Be 0
        }

        It "Should handle version with build number" {
            $version = Split-Version -Version "1.2.3.4"
            $version.Build | Should -Be 4
        }

        It "Should return error for invalid version format" {
            { Split-Version -Version "1.2a" } | Should -Throw
        }
    }

    Context "Test-Versions Function" {
        It "Should detect need for an upgrade when major version differs" {
            $local = @{ Major = 1; Minor = 0; Hotfix = 0; Build = 0 }
            $remote = @{ Major = 2; Minor = 0; Hotfix = 0; Build = 0 }
            Test-Versions -Local $local -Remote $remote -Package "test" | Should -Be $true
        }

        It "Should detect no need for upgrade when versions are identical" {
            $local = @{ Major = 1; Minor = 2; Hotfix = 3; Build = 4 }
            $remote = @{ Major = 1; Minor = 2; Hotfix = 3; Build = 4 }
            Test-Versions -Local $local -Remote $remote -Package "test" | Should -Be $false
        }
    }
}