#requires -version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$iojsvmwPath = Join-Path $PSScriptRoot 'vs-iojs'

function Set-iojsVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        #[ValidatePattern('^v\d\.\d{2}\.\d{2}$')]
        $Version
    )

    $requestedVersion = Join-Path $iojsvmwPath $version

    if (!(Test-Path -Path $requestedVersion)) {
        Write-Host "Could not find io.js version $version"
        return
    }

    $env:Path = "$requestedVersion;$env:Path"
    $env:IOJS_PATH = "$requestedVersion;"
    npm config set prefix $requestedVersion
    $env:IOJS_PATH += npm root -g
}

function Install-iojsVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        #[ValidatePattern('^v\d\.\d{2}\.\d{2}$')]
        $Version,

        [switch]
        $Force
    )

    $requestedVersion = Join-Path $iojsvmwPath $version

    if ((Test-Path -Path $requestedVersion) -And (-Not $force)) {
        Write-Host "Version $version is already installed, use -Force to reinstall"
        return
    }

    if (-Not (Test-Path -Path $requestedVersion)) {
        New-Item $requestedVersion -ItemType 'Directory'
    }

    $msiFile = "iojs-$version-x86.msi"
    $iojsUrl = "https://iojs.org/download/nightly/$version/$msiFile"

    if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {
        $msiFile = "iojs-$version-x64.msi"
        $iojsUrl = "https://iojs.org/download/nightly/$version/$msiFile"
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
}

function Remove-iojsVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        #[ValidatePattern('^v\d\.\d{2}\.\d{2}$')]
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
