# Node Version Manager for PowerShell

This is a simple PowerShell module for installing and using multiple Node.js versions in PowerShell. This is inspired by [creationix's nvm](https://github.com/creationix/nvm) tool for bash.
Works on Windows and on macOS.

# Install via PowerShell Gallery

nvm is available on the [PowerShell Gallery](https://www.powershellgallery.com/) as [nvm](https://www.powershellgallery.com/packages/nvm) and can easily be installed with:

```
PS> Install-Module -Name nvm
```

You can then import the module or add it to your profile for auto-importing.

# Installing manually

Clone this repository or put the `psm1` somewhere on disk and import the module:

    Import-Module <path to nvm.psm1>

# Commands

There are 6 PowerShell commands exposed. You're best using `Get-Help <command>` for proper help, but here's a quick overview.

_Note: Node.js will restrict you to a version number of v#.#.#_

## `Install-NodeVersion <version>`

    Install-NodeVersion v0.10.33

This will install the specified Node.js. You can also use a `-Force` flag to override an existing install. If you do not specify a version, the module searches for a .nvmrc file and reads the version from this file if available.


## `Remove-NodeVersion <version>`

    Remove-NodeVersion v0.10.33

This will remove the specified Node.js version from your machine.

## `Get-NodeVersions`

    Get-NodeVersions

Shows a list of what Node.js versions are available.

## `Set-NodeVersion <version>`

    Set-NodeVersion v0.10.33

Makes the specified Node.js version the currently loaded Node.js version for your terminal.

If you omit the `version` argument it will search for a `.nvmrc` file in the current directory and use that as the version.

## `Get-NodeInstallLocation`

    Get-NodeInstallLocation

Returns the path where Node.js will be looking for and installing new versions into.

## `Set-NodeInstallLocation`

    Set-NodeInstallLocation -Path C:\temp

Sets the base folder which Node.js versions will be installed into.

