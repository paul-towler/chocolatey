# Dot-source the functions file
. "$PSScriptRoot/Functions.ps1"

# Main script to check and upgrade packages
$ErrorActionPreference = "Continue"

Write-Host " Check choco Packages for Upgrades." -ForegroundColor Cyan
$localPackages = choco list --local --limit-output

foreach ($localPackage in $localPackages)
{
    $package = $localPackage.split("|")[0] # Extract package name
    $localVersion = $localPackage.split("|")[1] # Extract local version
    $remoteVersion = Get-RemotePackage -Package $package -Remote # Get remote version

    $localVersionParts = Split-Version -Version $localVersion # Split local version into components
    $remoteVersionParts = Split-Version -Version $remoteVersion # Split remote version into components

    Write-Host "`r`n Checking Package '$($package)'....." -ForegroundColor Gray
    Write-Host " Local Version is: $($localVersion)" -ForegroundColor White
    Write-Host " Remote Version is: $($remoteVersion)" -ForegroundColor White

    # Check if upgrade is required
    $upgradeRequired = Test-Versions -Local $localVersionParts -Remote $remoteVersionParts -Package $package

    try
    {
        Switch ($upgradeRequired)
        {
            $true
            {
                Write-Host " Upgrading '$($package)' to '$($remoteVersion)'....." -ForegroundColor Yellow
                $null = choco upgrade $package --version $remoteVersion --limit-output --no-progress --nocolor --yes
                $exitCode = $LASTEXITCODE # Capture the exit code of the choco upgrade command

                if ($exitCode -eq 0)
                {
                    $newLocalVersion = Get-RemotePackage -Package $package -Local # Get the new local version after upgrade
                    Write-Host " SUCCESS! '$($package)' is upgraded to version '$($newLocalVersion)'" -ForegroundColor Green
                }
                else
                {
                    Write-Host " Failed to upgrade package '$package'. Exit code: $exitCode" -ForegroundColor Red
                }
            }
            default
            { Write-Host " No Action required" -ForegroundColor Magenta }
        }
    }
    catch
    {
        Write-Host " ERROR: $_" -ForegroundColor Red
    }
}
