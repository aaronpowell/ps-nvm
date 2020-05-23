# Node Version Manager for PowerShell

[![powershellgallery](https://img.shields.io/powershellgallery/v/nvm.svg)](https://www.powershellgallery.com/packages/nvm)
[![downloads](https://img.shields.io/powershellgallery/dt/nvm.svg?label=downloads)](https://www.powershellgallery.com/packages/nvm)
[![codecov](https://codecov.io/gh/aaronpowell/ps-nvm/branch/master/graph/badge.svg)](https://codecov.io/gh/aaronpowell/ps-nvm)
[![Docs Build](https://github.com/aaronpowell/ps-nvm/workflows/Docs%20Build/badge.svg)](https://github.com/aaronpowell/ps-nvm/actions?query=workflow%3A%22Docs+Build%22)
[![Build](https://github.com/aaronpowell/ps-nvm/workflows/Build/badge.svg)](https://github.com/aaronpowell/ps-nvm/actions?query=workflow%3ABuild)
[![Release](https://github.com/aaronpowell/ps-nvm/workflows/Release/badge.svg)](https://github.com/aaronpowell/ps-nvm/actions?query=workflow%3ARelease)

This is a simple PowerShell module for installing and using multiple Node.js versions in PowerShell. This is inspired by [creationix's nvm](https://github.com/creationix/nvm) tool for bash.

Works on Windows, macOS and Linux.

## Getting Started

```powershell
# Install from the PowerShell Gallery
Install-Module nvm

# Install Node v7
Install-NodeVersion 7

# Set active Node version in PATH to v7
Set-NodeVersion 7

# Set default Node version for the current user to v7 (Windows only)
Set-NodeVersion -Persist User 7

# Install the Node version specified in .nvmrc or package.json engine field
Install-NodeVersion
```

📖 [Full Command Reference](./.docs/reference.md)

## Features

### Semver ranges

ps-nvm works with [semver ranges as used by npm](https://docs.npmjs.com/misc/semver#ranges).
For example, you can pass `^6.0.0` or just `6` to `Install-NodeVersion` to install the latest 6.x.x version, or even `>=6.0.0 <9.0.0` to install the latest version between v6 and v7.
Versions returned are [`SemVer.Version` objects](https://github.com/adamreeve/semver.net#readme) that can be compared with comparison operators like `-gt` and `-lt`.

### .nvmrc

If you don't specify a version for commands, ps-nvm will look for an .nvmrc plain text file in the current directory containing a node version to install.

### package.json `engines.node`

If you don't specify a version and no .nvmrc is found, ps-nvm will read a package.json file in the current directory and use whatever version satisfies the [`engines.node` field](https://docs.npmjs.com/files/package.json#engines).

## Contributing

```powershell
# Install dependencies
cd .scripts
dotnet publish -o ..
cd ..

# Run tests
Install-Module Pester
Invoke-Pester

# Regenerate documentation
./.scripts/GenerateDocumentation.ps1
```
