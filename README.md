# Node/io.js Version Manager for Windows

This is a simple PowerShell module for installing and using multiple Node.js and io.js versions on Windows.

# Install

Clone this repository or put the `psm1` somewhere on disk and import the module:

    Import-Module <path to nvm.psm1>

# Commands

There are 4 PowerShell commands exposed. They are similar for both Node.js and io.js, with the difference being whether you use `Node` or `iojs` in the command name.

_Note: Node.js will restrict you to a version number of v#.#.#, where as io.js will allow anything at the moment, as it runs off the nightly builds and the version string is more complex and I'm too lazy to write its regex._

## `Install-NodeVersion <version>`/`Install-iojsVersion <version>`

    Install-NodeVersion v0.10.33

This will install the specified Node.js/io.js version. You can also use a `-Force` flag to override an existing install. If you do not specify a version, the module searches for a .nvmrc file and reads the version from this file if available.

*Note: the `iojs` command accepts a `-Nightly` flag if you want to install from the nightly download list.*

## `Remove-NodeVersion <version>`/`Remove-iojsVersion <version>`

    Remove-NodeVersion v0.10.33

This will remove the specified Node.js/io.js version from your machine.

## `Get-NodeVersions`/`Get-iojsVersions`

    Get-NodeVersions

Shows a list of what Node.js/io.js versions are available.

## `Set-NodeVersion <version>`/`Set-iojsVersions`

    Set-NodeVersion v0.10.33

Makes the specified Node.js/io.js version the currently loaded Node.js/io.js version for your terminal.

*Note: the `iojs` command will alias `iojs` to `node` as well, pass the `-NoAlias` flag if you don't want it aliased.*
