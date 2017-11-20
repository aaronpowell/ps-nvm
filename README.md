# Node Version Manager for PowerShell

[![powershellgallery](https://img.shields.io/powershellgallery/v/nvm.svg)](https://www.powershellgallery.com/packages/nvm)
[![downloads](https://img.shields.io/powershellgallery/dt/nvm.svg?label=downloads)](https://www.powershellgallery.com/packages/nvm)
[![codecov](https://codecov.io/gh/aaronpowell/ps-nvm/branch/master/graph/badge.svg)](https://codecov.io/gh/aaronpowell/ps-nvm)
[![windows build](https://img.shields.io/appveyor/ci/aaronpowell/ps-nvm/master.svg?label=windows+build)](https://ci.appveyor.com/project/aaronpowell/ps-nvm)
[![macos/linux build](https://img.shields.io/travis/aaronpowell/ps-nvm/master.svg?label=macos/linux+build)](https://travis-ci.org/aaronpowell/ps-nvm)

This is a simple PowerShell module for installing and using multiple Node.js versions in PowerShell. This is inspired by [creationix's nvm](https://github.com/creationix/nvm) tool for bash.

Works on Windows, macOS and Linux.

## Install via PowerShell Gallery

nvm is available on the [PowerShell Gallery](https://www.powershellgallery.com/) as [nvm](https://www.powershellgallery.com/packages/nvm) and can easily be installed with:

```ps
Install-Module -Name nvm
```

You can then import the module or add it to your profile for auto-importing.

## Installing manually

Clone this repository or put the `psm1` somewhere on disk and import the module:

```ps
Import-Module path/to/nvm.psm1
```

## Semver ranges

ps-nvm works with [semver ranges as used by npm](https://docs.npmjs.com/misc/semver#ranges).
For example, you can pass `^6.0.0` or just `6` to `Install-NodeVersion` to install the latest 6.x.x version, or even `>=6.0.0 <9.0.0` to install the latest version between v6 and v7.
Versions returned are [`SemVer.Version` objects](https://github.com/adamreeve/semver.net#readme) that can be compared with comparison operators like `-gt` and `-lt`.

## .nvmrc

If you don't specify a version for commands, ps-nvm will look for an .nvmrc plain text file in the current directory containing a node version to install.

## package.json `engines.node`

If you don't specify a version and no .nvmrc is found, ps-nvm will read a package.json file in the current directory and use whatever version satisfies the [`engines.node` field](https://docs.npmjs.com/files/package.json#engines).

<!-- BEGIN OF GENERATED DOCUMENTATION -->
<!-- to regenerate, run .scripts/Generate-Documentation.ps1 -->
## Command Reference

- [`Get-NodeInstallLocation`](#get-nodeinstalllocation)
- [`Get-NodeVersions`](#get-nodeversions)
- [`Install-NodeVersion`](#install-nodeversion)
- [`Remove-NodeVersion`](#remove-nodeversion)
- [`Set-NodeInstallLocation`](#set-nodeinstalllocation)
- [`Set-NodeVersion`](#set-nodeversion)

### `Get-NodeInstallLocation`
<a id="get-nodeinstalllocation"></a>

Will return the path that node.js versions will be installed into

```powershell
Get-NodeInstallLocation 
```

#### Parameters
None


#### Examples

```powershell
Get-NodeInstallLocation
```

    
### `Get-NodeVersions`
<a id="get-nodeversions"></a>

Used to show all the node.js versions installed to nvm, using the -Remote option allows you to list versions of node.js available for install. Providing a -Filter parameter can filter the versions using the pattern, either local or remote versions. The versions are sorted from highest to lowest and can be compared with PowerShell operators.

```powershell
Get-NodeVersions -Remote <SwitchParameter> -Filter <String>
```

#### Parameters
- `-Remote <SwitchParameter>`  
  Indicate whether or not to list local or remote versions
 - `-Filter <String>`  
  A semver version range to filter versions



#### Examples

```powershell
Get-NodeVersions -Remote -Filter ">=7.0.0 <9.0.0"
```

Show all versions available to download between v7 and v9    
 
```powershell
Get-NodeVersions -Filter '>=7.0.0 <9.0.0' | % {"$_"}
```

Return the installed versions as strings    
 
```powershell
(Get-NodeVersions | Select-Object -First 1) -lt (Get-NodeVersions -Remote | Select-Object -First 1)
```

    
### `Install-NodeVersion`
<a id="install-nodeversion"></a>

Download and install the specified version of node.js into the nvm directory. Once installed it can be used with Set-NodeVersion

```powershell
Install-NodeVersion -Version <String> -Force <SwitchParameter> -Architecture <String> -Proxy <String>
```

#### Parameters
- `-Version <String>`  
  A semver range for the version of node.js to install
 - `-Force <SwitchParameter>`  
  Reinstall an already installed version of node.js
 - `-Architecture <String>`  
  The architecture of node.js to install, defaults to [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
 - `-Proxy <String>`  
  Define HTTP proxy used when downloading an installer



#### Examples

```powershell
Install-NodeVersion v5.0.0
```

Install version 5.0.0 of node.js into the module directory    
 
```powershell
Install-NodeVersion ^5
```

Install the latest 5.x.x version of node.js into the module directory    
 
```powershell
Install-NodeVersion v5.0.0 -Architecture x86
```

Installs the x86 version even if you're on an x64 machine    
 
```powershell
Install-NodeVersion v5.0.0 -Architecture x86 -proxy http://localhost:3128
```

Installs the x86 version even if you're on an x64 machine using default CNTLM proxy    
### `Remove-NodeVersion`
<a id="remove-nodeversion"></a>

Removes an installed version of node.js along with any installed npm modules

```powershell
Remove-NodeVersion -Version <String>
```

#### Parameters
- `-Version <String>`  
  The full version string of the node.js package to remove



#### Examples

```powershell
Remove-NodeVersion v5.0.0
```

Removes the v5.0.0 version of node.js from the nvm store    
### `Set-NodeInstallLocation`
<a id="set-nodeinstalllocation"></a>

This is used to override the default node.js install path for nvm, which is relative to the module install location. You would want to use this to get around the Windows path limit problem that plagues node.js installed. Note that to avoid collisions the unpacked files will be in a folder `.nvm\<version>` in the specified location.

```powershell
Set-NodeInstallLocation -Path <String>
```

#### Parameters
- `-Path <String>`  
  The root folder for nvm



#### Examples

```powershell
Set-NodeInstallLocation -Path C:\Temp
```

    
### `Set-NodeVersion`
<a id="set-nodeversion"></a>

Set's the node.js version that was either provided with the -Version parameter, from using the .nvmrc file or the node engines field in package.json in the current working directory.

```powershell
Set-NodeVersion -Version <String> -Persist <String>
```

#### Parameters
- `-Version <String>`  
  A semver version range for the node.js version you wish to use.
 - `-Persist <String>`  
  If present, this will also set the node.js version to the permanent system path, of the specified scope, which will persist this setting for future powershell sessions and causes this version of node.js to be referenced outside of powershell.



#### Examples

```powershell
Set-NodeVersion
```

Set based on the .nvmrc or package.json engines node field    
 
```powershell
Set-NodeVersion 5.0.1
```

Set using explicit version    
 
```powershell
Set-NodeVersion ~5.2
```

Sets to the latest installed patch version of v5.2    
 
```powershell
Set-NodeVersion ^5
```

Sets to the latest installed v5 version    
 
```powershell
Set-NodeVersion '>=5.0.0 <7.0.0'
```

Sets to the latest installed version between v5 and v7    
 
```powershell
Set-NodeVersion v5.0.1 -Persist User
```

Set and persist in permamant system path for the current user    
 
```powershell
Set-NodeVersion v5.0.1 -Persist Machine
```

Set and persist in permamant system path for the machine (Note: requires an admin shell)    

<!-- END OF GENERATED DOCUMENTATION -->
