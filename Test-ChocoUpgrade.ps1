#Requires -Version 5.1
#Requires -RunAsAdministrator

# Function to get the package version from remote or local repository
function Get-RemotePackage
{
    param
    (   
        [Parameter(Mandatory = $true, HelpMessage="Name of the Chocolatey package")]
        [string]$Package,

        [Parameter(Mandatory = $false, HelpMessage="Switch to get the local package version")]
        [switch]$Local,

        [Parameter(Mandatory = $false, HelpMessage="Switch to get the remote package version")]
        [switch]$Remote
    )

    try
    {
        # Get the remote package version
        if ($Remote) { return (choco search $Package --limit-output --exact --yes).split("|")[1] }

        # Get the local package version
        if ($Local) { return (choco list $Package --local --limit-output --exact --yes).split("|")[1] }
    }
    catch
    {
        Write-Host " Failed to get package information for '$Package'. Error: $_" -ForegroundColor Red
    }
}

# Function to split the version string into components
function Split-Version
{
    param
    (
        [Parameter(Mandatory = $true, HelpMessage="Version string to split")]
        [string]$Version
    )

    if ($Version -match '^(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?$')
    {
        return @{
            Major  = [int]$matches[1]
            Minor  = [int]$matches[2]
            Hotfix = [int]$matches[3]
            Build  = if ($matches[4]) { [int]$matches[4] } else { 0 }
        }
    }
    else
    {
        Write-Host " Invalid version format: $Version" -ForegroundColor Red
    }
}

# Function to test if an upgrade is required by comparing version components
function Test-Versions
{
    param 
    (
        [Parameter(Mandatory = $true, HelpMessage="Hashtable containing local version components")]
        [hashtable]$Local,

        [Parameter(Mandatory = $true, HelpMessage="Hashtable containing remote version components")]
        [hashtable]$Remote,

        [Parameter(Mandatory = $true, HelpMessage="Name of the Chocolatey package")]
        [string]$Package
    )

    $upgradeRequired = $false

    # Check if major version upgrade is required
    if ($Local.Major -lt $Remote.Major)
    {
        Write-Host " Major version upgrade required." -ForegroundColor Yellow -NoNewline
        $upgradeRequired = $true
    }

    # Check if minor version upgrade is required
    if ($Local.Minor -lt $Remote.Minor -and !$upgradeRequired)
    {
        Write-Host " Minor version upgrade required." -ForegroundColor Yellow -NoNewline
        $upgradeRequired = $true
    }

    # Check if hotfix version upgrade is required
    if ($Local.Hotfix -lt $Remote.Hotfix -and !$upgradeRequired)
    {
        Write-Host " Hotfix version upgrade required." -ForegroundColor Yellow -NoNewline
        $upgradeRequired = $true
    }

    # Check if build version upgrade is required
    if ($Local.Build -lt $Remote.Build -and !$upgradeRequired)
    {
        Write-Host " Build version upgrade required." -ForegroundColor Yellow -NoNewline
        $upgradeRequired = $true
    }

    return $upgradeRequired
}

# Main script to check and upgrade packages
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
        Write-Host " Failed to upgrade package '$package'. Error: $_" -ForegroundColor Red
    }
}