#Requires -Version 5.1
#Requires -RunAsAdministrator

Function Get-ChocoPackage
{
    param
    (
        [string]$Package,
        [switch]$Local,
        [switch]$Remote
    )

    if ($Remote)
    {
        $tmp = (choco search $Package --limit-output --exact --yes).split("|")
        return $tmp[1]
    }

    if ($Local)
    {
        $tmp = (choco list $Package --local --limit-output --exact --yes).split("|")
        return $tmp[1]
    }

    $tmp = $Package.split("|")
    return $tmp[0], $tmp[1]
}

Write-Host " Check choco Packages for Upgrades." -ForegroundColor Cyan
$local = choco list --local --limit-output
$local | ForEach-Object {
    $package, $versionLocal = Get-ChocoPackage -Package $_
    $versionRemote =  Get-ChocoPackage -Package $package -Remote

    Write-Host " Checking Package '$($package)'....." -ForegroundColor Gray
    Write-Host " Local Version is: $($versionLocal)" -ForegroundColor White
    Write-Host " Remote Version is: $($versionRemote)" -ForegroundColor White
    try
    {
        Switch ($versionLocal)
        {
            {$PSItem -lt $versionRemote}
            {
                Write-Host " Upgrading '$($package)' to '$($versionRemote)'....." -ForegroundColor Yellow
                $null = choco upgrade $package --limit-output --no-progress --nocolor --yes
                $versionLocalNew = Get-ChocoPackage -Package $package -Local
                Write-Host " SUCCESS! '$($package)' is upgraded to version '$($versionLocalNew)'`r`n" -ForegroundColor Green
                break
            }
            default
            { Write-Host " No Action required`r`n" -ForegroundColor Magenta}
        }
    }
    catch
    { $_ }
}
