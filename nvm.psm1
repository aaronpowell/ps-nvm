#requires -version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Set-NodeVersion {
    <#
    .Synopsis
       Set the node.js version for the current session
    .Description
       Set's the node.js version that was either provided with the -Version parameter or from using the .nvmrc file in the current working directory.
    .Parameter $Version
       A version string for the node.js version you wish to use. Use the format of v#.#.#. This also supports fuzzy matching, so v# will be the latest installed version starting with that major
    .Parameter $Persist
       If present, this will also set the node.js version to the permanent system path, of the specified scope, which will persist this setting for future powershell sessions and causes this version of node.js to be referenced outside of powershell.
    .Example
       Set based on the .nvmrc
       Set-NodeVersion
    .Example
       Set-NodeVersion v5
       Set using fuzzy matching
    .Example
       Set-NodeVersion v5.0.1
       Set using explicit version
    .Example
       Set-NodeVersion v5.0.1 -Persist User
       Set and persist in permamant system path for the current user
    .Example
       Set-NodeVersion v5.0.1 -Persist Machine
       Set and persist in permamant system path for the machine (Note: requires an admin shell)
    #>
    param(
        [string]
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^v\d(\.\d{1,2}){0,2}$')]
        $Version,
        [string]
        [ValidateSet('User', 'Machine')]
        [Parameter(Mandatory=$false)]
        $Persist
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

    $nvmwPath = Get-NodeInstallLocation

    $requestedVersion = Join-Path $nvmwPath $VersionToUse

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find node version $VersionToUse"
        return
    }

    # immediately add to the current powershell session path
    $env:Path = "$requestedVersion;$env:Path"

    if ($Persist -ne '') {
        # also add to the permanent windows path
        $persistedPaths = @($requestedVersion)
        [Environment]::GetEnvironmentVariable('Path', $Persist) -split ';' | % {
          if (-not($_ -like "$nvmwPath*")) {
            $persistedPaths += $_
          }
        }
        [Environment]::SetEnvironmentVariable('Path', $persistedPaths -join ';', $Persist)
    }

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
    .Parameter $proxy
        Define HTTP proxy used when downloading an installer
    .Example
        Install-NodeVersion v5.0.0
        Install version 5.0.0 of node.js into the module directory
    .Example
        Install-NodeVersion v5.0.0 -architecture x86
        Installs the x86 version even if you're on an x64 machine
    .Example
        Install-NodeVersion v5.0.0 -architecture x86 -proxy http://localhost:3128
        Installs the x86 version even if you're on an x64 machine using default CNTLM proxy
    #>
    param(
        [string]
        [Parameter(Mandatory=$true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$|^latest$')]
        $Version,

        [switch]
        $Force,

        [string]
        $architecture = $env:PROCESSOR_ARCHITECTURE,
        
        [string]
        $proxy
    )

    if ($version -match "latest") {
        $listing = "https://nodejs.org/dist/latest/"
         $r = (wget -UseBasicParsing $listing).content
         if ($r -match "node-(v[0-9\.]+).*?\.msi") {
             $version = $matches[1]
         }
         else {
             throw "failed to retrieve latest version from '$listing'"
         }
    }

    $nvmwPath = Get-NodeInstallLocation

    $requestedVersion = Join-Path $nvmwPath $version

    if ((Test-Path -Path $requestedVersion) -And (-Not $force)) {
        "Version $version is already installed, use -Force to reinstall"
        return
    }

    if (-Not (Test-Path -Path $requestedVersion)) {
        New-Item $requestedVersion -ItemType 'Directory'
    }

    $msiFile = "node-$version-x86.msi"
    $nodeUrl = "https://nodejs.org/dist/$version/$msiFile"

    if ($architecture -eq 'AMD64') {
        $msiFile = "node-$version-x64.msi"

        if ($version -match '^v0\.\d{1,2}\.\d{1,2}$') {
            $nodeUrl = "https://nodejs.org/dist/$version/x64/$msiFile"
        } else {
            $nodeUrl = "https://nodejs.org/dist/$version/$msiFile"
        }
    }

    if ($proxy) {
        Invoke-WebRequest -Uri $nodeUrl -OutFile (Join-Path $requestedVersion $msiFile) -Proxy $proxy
    } else {
        Invoke-WebRequest -Uri $nodeUrl -OutFile (Join-Path $requestedVersion $msiFile)
    }
    

    if (-Not (Get-Command msiexec)) {
        "msiexec is not in your path"
        return
    }

    $unpackPath = Join-Path $requestedVersion '.u'
    if (Test-Path $unpackPath) {
        Remove-Item $unpackPath -Recurse -Force
    }

    New-Item $unpackPath -ItemType Directory

    $msiFilePath = (Join-Path $requestedVersion $msiFile)
    $args = @("/a", "`"$msiFilePath`"", "/qb", "TARGETDIR=`"$unpackPath`"")
    
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

    $nvmwPath = Get-NodeInstallLocation

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
        $nvmwPath = Get-NodeInstallLocation

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

function Set-NodeInstallLocation {
    <#
    .Synopsis
        Sets the path where node.js versions will be installed into
    .Description
        This is used to override the default node.js install path for nvm, which is relative to the module install location. You would want to use this to get around the Windows path limit problem that plagues node.js installed. Note that to avoid collisions the unpacked files will be in a folder `.nvm\<version>` in the specified location.
    .Parameter $Path
        THe root folder for nvm
    .Example
        Set-NodeInstallLocation -Path C:\Temp
    #>
    param(
        [string]
        [Parameter(Mandatory=$true)]
        $Path
    )

    $settings = $null
    $settingsFile = Join-Path $PSScriptRoot 'settings.json'

    if ((Test-Path $settingsFile) -eq $true) {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
    } else {
        $settings = @{ 'InstallPath' = Get-NodeInstallLocation }
    }

    $settings.InstallPath = Join-Path $Path '.nvm'

    ConvertTo-Json $settings | Out-File (Join-Path $PSScriptRoot 'settings.json')
}

function Get-NodeInstallLocation {
    <#
    .Synopsis
        Gets the currnet node.js install path
    .Description
        Will return the path that node.js versions will be installed into
    .Example
        Get-NodeInstallLocation
        c:\tmp\.nvm
    #>
    $settings = $null
    $settingsFile = Join-Path $PSScriptRoot 'settings.json'

    if ((Test-Path $settingsFile) -eq $true) {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
    } else {
        $settings = New-Object -TypeName PSObject -Prop @{ InstallPath = (Join-Path $PSScriptRoot 'vs') }
    }

    $settings.InstallPath
}
