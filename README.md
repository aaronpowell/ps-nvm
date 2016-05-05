# Node Version Manager for Windows

This is a simple PowerShell module for installing and using multiple Node.js versions on Windows.

# Install

Clone this repository or put the `psm1` somewhere on disk and import the module:

    Import-Module <path to nvm.psm1>

# Commands

There are 4 PowerShell commands exposed.

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
