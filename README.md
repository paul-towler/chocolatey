# Chocolatey Package Upgrade Script

This PowerShell script checks for updates to installed Chocolatey packages and upgrades them if a newer version is available.

## Requirements

- PowerShell 5.1 or later
- Chocolatey

## Script Overview

The script performs the following tasks:

1. Retrieves the local and remote versions of installed Chocolatey packages.
2. Splits the version strings into components (Major, Minor, Hotfix, Build).
3. Compares the local and remote versions to determine if an upgrade is required.
4. Upgrades the package if a newer version is available.
5. Logs the results of the upgrade process.

## Functions

### `Get-RemotePackage`

Retrieves the package version from the remote or local repository.

**Parameters:**

- `Package` (string): Name of the Chocolatey package.
- `Local` (switch): Switch to get the local package version.
- `Remote` (switch): Switch to get the remote package version.

### `Split-Version`

Splits the version string into components.

**Parameters:**

- `Version` (string): Version string to split.

### `Test-Versions`

Tests if an upgrade is required by comparing version components.

**Parameters:**

- `Local` (hashtable): Hashtable containing local version components.
- `Remote` (hashtable): Hashtable containing remote version components.
- `Package` (string): Name of the Chocolatey package.

## Usage

1. Open PowerShell
2. Run the script:

```powershell
.\Update-ChocoPackages.ps1
```

> **NOTE:**
>
> If you have installed packages with elevated admin privileges, you must run this script with administrator privileges.
