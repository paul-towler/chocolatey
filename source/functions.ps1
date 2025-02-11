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
        throw " Failed to get package information for '$Package'. Error: $_"
    }
}

function Install-ChocoPackage
{
    param
    (   
        [Parameter(Mandatory = $true, HelpMessage="Name of the Chocolatey package")]
        [string]$Package
    )

    try
    {
        if (Get-RemotePackage -Package $Package -Local)
        {
            Write-Host "'$Package' is already installed." -ForegroundColor Magenta
            return $true
        }
        else
        {
            Write-Host " Installing package '$Package'....." -ForegroundColor Yellow
            $null = choco install $Package --limit-output --no-progress --nocolor --yes
            $exitCode = $LASTEXITCODE # Capture the exit code of the choco install command

            if ($exitCode -eq 0)
            {
                Write-Host " SUCCESS! '$Package' is installed." -ForegroundColor Green
                return $true
            }
            else
            {
                throw " Failed to install package '$Package'. Exit code: $exitCode"
            }
        }
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
        throw " Invalid version format: $Version"
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
