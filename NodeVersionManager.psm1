#requires -version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$nvmwPath = Join-Path $PSScriptRoot 'vs'

function Set-NodeVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version
    )

    $requestedVersion = Join-Path $nvmwPath $version

    if (!(Test-Path -Path $requestedVersion)) {
        Write-Host "Could not find node version $version"
        return
    }

    $env:Path = "$requestedVersion;$env:Path"
    $env:NODE_PATH = "$requestedVersion;"
    npm config set prefix $requestedVersion
    $env:NODE_PATH += npm root -g
}

function Install-NodeVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version,

        [switch]
        $Force
    )

    $requestedVersion = Join-Path $nvmwPath $version

    if ((Test-Path -Path $requestedVersion) -And (-Not $force)) {
        Write-Host "Version $version is already installed, use -Force to reinstall"
        return
    }

    if (-Not (Test-Path -Path $requestedVersion)) {
        New-Item $requestedVersion -ItemType 'Directory'
    }

    $msiFile = "node-$version-x86.msi"
    $nodeUrl = "http://nodejs.org/dist/$version/$msiFile"

    if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
        $msiFile = "node-$version-x64.msi"

        if ($version -match '^v0\.\d{1,2}\.\d{1,2}$') {
            $nodeUrl = "http://nodejs.org/dist/$version/x64/$msiFile"
        } else {
            $nodeUrl = "http://nodejs.org/dist/$version/$msiFile"
        }
    }

    Invoke-WebRequest -Uri $nodeUrl -OutFile (Join-Path $requestedVersion $msiFile)

    if (-Not (Get-Command msiexec)) {
        Write-Host "msiexec is not in your path"
        return
    }

    $unpackPath = Join-Path $requestedVersion '.unpack'
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
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version
    )

    $requestedVersion = Join-Path $nvmwPath $Version

    if (!(Test-Path -Path $requestedVersion)) {
        Write-Host "Could not find node version $Version"
        return
    }

    Remove-Item $requestedVersion -Force -Recurse
}

function Get-NodeVersions {
    Get-ChildItem $nvmwPath | %{ $_.Name }
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
        Write-Host "Could not find io.js version $version"
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
        Write-Host "Version $version is already installed, use -Force to reinstall"
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
        Write-Host "msiexec is not in your path"
        return
    }

    $unpackPath = Join-Path $requestedVersion '.unpack'
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
        Write-Host "Could not find io.js version $Version"
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
