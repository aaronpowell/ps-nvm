#requires -version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$nvmwPath = Join-Path $PSScriptRoot 'vs'

function Set-NodeVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{2}\.\d{2}$')]
        $Version
    )

    $requestedVersion = Join-Path $nvmwPath $version

    if (!(Test-Path -Path $requestedVersion)) {
        Write-Host "Could not find node version $version"
        return
    }

    $env:Path = "$requestedVersion;$env:Path"
}

function Install-NodeVersion {
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{2}\.\d{2}$')]
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
        $nodeUrl = "http://nodejs.org/dist/$version/x64/$msiFile"
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
        [ValidatePattern('^v\d\.\d{2}\.\d{2}$')]
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