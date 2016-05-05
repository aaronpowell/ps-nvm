#requires -version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$nvmwPath = Join-Path $PSScriptRoot 'vs'

function Set-NodeVersion {
    <#
    .Synopsis
       Set the node.js version for the current session
    .Description
       Set's the node.js version that was either provided with the -Version parameter or from using the .nvmrc file in the current working directory.
    .Parameter $Version
       A version string for the node.js version you wish to use. Use the format of v#.#.#. This also supports fuzzy matching, so v# will be the latest installed version starting with that major
    .Example
       Set based on the .nvmrc
       Set-NodeVersion
    .Example
       Set-NodeVersion v5
       Set using fuzzy matching
    .Example
       Set-NodeVersion v5.0.1
       Set using explicit version
    #>
    param(
        [string]
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^v\d(\.\d{1,2}){0,2}$')]
        $Version
    )

    if ([string]::IsNullOrEmpty($Version)) {
        if (Test-Path .\.nvmrc) {
            $VersionToUse = Get-Content .\.nvmrc -Raw
        }
        else {
            "Version not given and no .nvmrc file found in folder"
            return
        }
    }
    else {
        $VersionToUse = $version
    }

    $VersionToUse = $VersionToUse.replace("`n","").replace("`r","")

    if (!($VersionToUse -match "v\d\.\d{1,2}\.\d{1,2}")) {
        "Version found is not a full version, using fuzzy matching"
        $VersionToUse = Get-NodeVersions -Filter $VersionToUse | Select-Object -First 1

        if (!$VersionToUse) {
            "No version found to fuzzy match against"
            return
        }
    }

    $requestedVersion = Join-Path $nvmwPath $VersionToUse

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find node version $VersionToUse"
        return
    }

    $env:Path = "$requestedVersion;$env:Path"
    $env:NODE_PATH = "$requestedVersion;"
    npm config set prefix $requestedVersion
    $env:NODE_PATH += npm root -g
    "Switched to node version $VersionToUse"
}

function Install-NodeVersion {
    <#
    .Synopsis
        Install a version of node.js
    .Description
        Download and install the specified version of node.js into the nvm directory. Once installed it can be used with Set-NodeVersion
    .Parameter $Version
        The version of node.js to install
    .Parameter $Force
        Reinstall an already installed version of node.js
    .Parameter $architecture
        The architecture of node.js to install, defaults to $env:PROCESSOR_ARCHITECTURE
    .Example
        Install-NodeVersion v5.0.0
        Install version 5.0.0 of node.js into the module directory
    .Example
        Install-NodeVersion v5.0.0 -architecture x86
        Installs the x86 version even if you're on an x64 machine
    #>
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$|^latest$')]
        $Version,

        [switch]
        $Force,

        [string]
        $architecture = $env:PROCESSOR_ARCHITECTURE
    )

    if ($version -match "latest") {
        $listing = "http://nodejs.org/dist/latest/"
         $r = (wget -UseBasicParsing $listing).content
         if ($r -match "node-(v[0-9\.]+).*?\.msi") {
             $version = $matches[1]
         }
         else {
             throw "failed to retrieve latest version from '$listing'"
         }
    }

    $requestedVersion = Join-Path $nvmwPath $version

    if ((Test-Path -Path $requestedVersion) -And (-Not $force)) {
        "Version $version is already installed, use -Force to reinstall"
        return
    }

    if (-Not (Test-Path -Path $requestedVersion)) {
        New-Item $requestedVersion -ItemType 'Directory'
    }

    $msiFile = "node-$version-x86.msi"
    $nodeUrl = "http://nodejs.org/dist/$version/$msiFile"

    if ($architecture -eq 'AMD64') {
        $msiFile = "node-$version-x64.msi"

        if ($version -match '^v0\.\d{1,2}\.\d{1,2}$') {
            $nodeUrl = "http://nodejs.org/dist/$version/x64/$msiFile"
        } else {
            $nodeUrl = "http://nodejs.org/dist/$version/$msiFile"
        }
    }

    Invoke-WebRequest -Uri $nodeUrl -OutFile (Join-Path $requestedVersion $msiFile)

    if (-Not (Get-Command msiexec)) {
        "msiexec is not in your path"
        return
    }

    $unpackPath = Join-Path $requestedVersion '.u'
    if (Test-Path $unpackPath) {
        Remove-Item $unpackPath -Recurse -Force
    }

    New-Item $unpackPath -ItemType Directory

    $args = @("/a", (Join-Path $requestedVersion $msiFile), "/qb", "TARGETDIR=`"$unpackPath`"")

    Start-Process -FilePath "msiexec.exe" -Wait -PassThru -ArgumentList $args

    Move-Item (Join-Path (Join-Path $unpackPath 'nodejs') '*') -Destination $requestedVersion -Force
    Remove-Item $unpackPath -Recurse -Force
}

function Remove-NodeVersion {
    <#
    .Synopsis
        Removes an installed version of node.js
    .Description
        Removes an installed version of node.js along with any installed npm modules
    .Parameter $Version
        The full version string of the node.js package to remove
    .Example
        Remove-NodeVersion v5.0.0
        Removes the v5.0.0 version of node.js from the nvm store
    #>
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version
    )

    $requestedVersion = Join-Path $nvmwPath $Version

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find node version $Version"
        return
    }

    Remove-Item $requestedVersion -Force -Recurse
}

function Get-NodeVersions {
    <#
    .Synopsis
        List local or remote node.js versions
    .Description
        Used to show all the node.js versions installed to nvm, using the -Remote option allows you to list versions of node.js available for install. Providing a -Filter parameter can reduce the versions using the pattern, either local or remote versions
    .Parameter $Remote
        Indicate whether or not to list local or remote versions
    .Parameter $Filter
        A version filter supporting fuzzy filters
    .Example
        Get-NodeVersions -Remote -Filter v4.2
        version
        -------
        v4.2.6
        v4.2.5
        v4.2.4
        v4.2.3
        v4.2.2
        v4.2.1
        v4.2.0
    #>
    param(
        [switch]
        $Remote,

        [string]
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^v\d(\.\d{1,2}){0,2}$')]
        $Filter
    )

    if ($Remote) {
        $versions = Invoke-WebRequest -Uri https://nodejs.org/dist/index.json | ConvertFrom-Json

        if ($Filter) {
            $versions = $versions | Where-Object { $_.version.Contains($filter) }
        }

        $versions | Select-Object version | Sort-Object -Descending -Property version
    } else {
        if (!(Test-Path -Path $nvmwPath)) {
            "No Node.js versions have been installed"
        } else {
            $versions = Get-ChildItem $nvmwPath | %{ $_.Name }

            if ($Filter) {
                $versions = $versions | Where-Object { $_.Contains($filter) }
            }

            $versions | Sort-Object -Descending
        }
    }
}

# Start io.js handling

$iojsvmwPath = Join-Path $PSScriptRoot 'vs-iojs'

function Set-iojsVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        #[ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version,

        [switch]
        $NoAlias
    )

    $requestedVersion = Join-Path $iojsvmwPath $version

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find io.js version $version"
        return
    }

    $env:Path = "$requestedVersion;$env:Path"

    if (!$NoAlias) {
        $env:NODE_PATH = "$requestedVersion;"
        $env:NODE_PATH += npm root -g
    }

    $env:IOJS_PATH = "$requestedVersion;"
    npm config set prefix $requestedVersion
    $env:IOJS_PATH += npm root -g

}

function Install-iojsVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        #[ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version,

        [switch]
        $Force,

        [switch]
        $Nightly
    )


    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-Not $isAdmin) {
        $continue = Read-Host 'You are not running as an admin, it is likely that the installer will fail later trying to create the node symlink. Continue (y/N)?'

        if ($continue -ne 'y') {
            return
        }
    }

    $requestedVersion = Join-Path $iojsvmwPath $version

    if ($Nightly) {
        $type = 'download/nightly'
    } else {
        $type = 'dist'
    }

    if ((Test-Path -Path $requestedVersion) -And (-Not $force)) {
        "Version $version is already installed, use -Force to reinstall"
        return
    }

    if (-Not (Test-Path -Path $requestedVersion)) {
        New-Item $requestedVersion -ItemType 'Directory'
    }

    $msiFile = "iojs-$version-x86.msi"
    $iojsUrl = "https://iojs.org/$type/$version/$msiFile"

    if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
        $msiFile = "iojs-$version-x64.msi"
        $iojsUrl = "https://iojs.org/$type/$version/$msiFile"
    }

    Invoke-WebRequest -Uri $iojsUrl -OutFile (Join-Path $requestedVersion $msiFile)

    if (-Not (Get-Command msiexec)) {
        "msiexec is not in your path"
        return
    }

    $unpackPath = Join-Path $requestedVersion '.u'
    if (Test-Path $unpackPath) {
        Remove-Item $unpackPath -Recurse -Force
    }

    New-Item $unpackPath -ItemType Directory

    $args = @("/a", (Join-Path $requestedVersion $msiFile), "/qb", "TARGETDIR=`"$unpackPath`"")

    Start-Process -FilePath "msiexec.exe" -Wait -PassThru -ArgumentList $args

    Move-Item (Join-Path (Join-Path $unpackPath 'iojs') '*') -Destination $requestedVersion -Force
    Remove-Item $unpackPath -Recurse -Force

    cmd /c mklink (Join-Path $requestedVersion 'node.exe') (Join-Path $requestedVersion 'iojs.exe')
}

function Remove-iojsVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        #[ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version
    )

    $requestedVersion = Join-Path $iojsvmwPath $Version

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find io.js version $Version"
        return
    }

    Remove-Item $requestedVersion -Force -Recurse
}

function Get-iojsVersions {
    if (!(Test-Path -Path $iojsvmwPath)) {
        New-Item $iojsvmwPath -ItemType Directory
    }

    Get-ChildItem $iojsvmwPath | %{ $_.Name }
}
