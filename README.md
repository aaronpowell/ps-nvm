# Node Version Manager for Windows

This is a simple PowerShell module for installing and using multiple Node.js versions on Windows.

# Install

Clone tihs repository or put the `NodeVersionManager.psm1` somewhere on disk and import the module:

    Import-Module <path to NodeVersionManager.psm1>

# Commands

There are 4 PowerShell commands exposed:

## `Install-NodeVersion <version>`

    Install-NodeVersion v0.10.33

This will install the specified Node.js version. You can also use a `-Force` flag to override an existing install

## `Remove-NodeVersion <version>`

    Remove-NodeVersion v0.10.33

This will remove the specified Node.js version from your machine.

## `Get-NodeVersions`

    Get-NodeVersions

Shows a list of what Node.js versions are available.

## `Set-NodeVersion <version>`

    Set-NodeVersion v0.10.33

Makes the specified Node.js version the currently loaded Node.js version for your terminal.