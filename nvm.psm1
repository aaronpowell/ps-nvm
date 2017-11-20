#requires -version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function IsMac() {
    return (Test-Path variable:global:IsMacOS) -and $IsMacOS
}

function IsLinux() {
    return (Test-Path variable:global:IsLinux) -and $IsLinux
}

function IsWindows() {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell less than v6 didn't work on anything other than Windows
        # This means we can shortcut out here
        return $true;
    }

    return (Test-Path variable:global:IsWindows) -and $IsWindows
}

function Set-NodeVersion {
    <#
    .Synopsis
       Set the node.js version for the current session
    .Description
       Set's the node.js version that was either provided with the -Version parameter, from using the .nvmrc file or the node engines field in package.json in the current working directory.
    .Parameter $Version
       A semver version range for the node.js version you wish to use.
    .Parameter $Persist
       If present, this will also set the node.js version to the permanent system path, of the specified scope, which will persist this setting for future powershell sessions and causes this version of node.js to be referenced outside of powershell.
    .Example
       Set based on the .nvmrc or package.json engines node field
       Set-NodeVersion
    .Example
       Set-NodeVersion 5.0.1
       Set using explicit version
    .Example
       Set-NodeVersion ~5.2
       Sets to the latest installed patch version of v5.2
    .Example
       Set-NodeVersion ^5
       Sets to the latest installed v5 version
    .Example
       Set-NodeVersion '>=5.0.0 <7.0.0'
       Sets to the latest installed version between v5 and v7
    .Example
       Set-NodeVersion v5.0.1 -Persist User
       Set and persist in permamant system path for the current user
    .Example
       Set-NodeVersion v5.0.1 -Persist Machine
       Set and persist in permamant system path for the machine (Note: requires an admin shell)
    #>
    param(
        [string]
        [Parameter(Mandatory = $false)]
        $Version,
        [string]
        [ValidateSet('User', 'Machine')]
        [Parameter(Mandatory = $false)]
        $Persist
    )

    if ([string]::IsNullOrEmpty($Version)) {
        if (Test-Path ./.nvmrc) {
            $Version = Get-Content ./.nvmrc -Raw
        }
        elseif (Test-Path ./package.json) {
            $packageJson = Get-Content ./package.json -Raw | ConvertFrom-Json
            if ((Get-Member -InputObject $packageJson -Name 'engines') -and (Get-Member -InputObject $packageJson.engines -Name 'node')) {
                # Use node engine field as version range
                $Version = $packageJson.engines.node
            }
            else {
                throw "Version not given, no .nvmrc found in folder and package.json does not contain node engines field"
            }
        }
        else {
            throw "Version not given and no .nvmrc or package.json found in folder"
        }
    }

    $Version = $Version.Trim()

    $matchedVersion = if (!($Version -match "v\d\.\d{1,2}\.\d{1,2}")) {
        Get-NodeVersions -Filter $Version | Select-Object -First 1
    }
    else {
        $Version
    }

    if (!$matchedVersion) {
        throw "No version found that matches $Version"
    }

    $nvmPath = Get-NodeInstallLocation

    $requestedVersion = Join-Path $nvmPath $matchedVersion
    $binPath = if ((IsMac) -or (IsLinux)) {
        # Under macOS, the node binary is in a bin folder
        Join-Path $requestedVersion "bin"
    }
    else {
        $requestedVersion
    }

    if (!(Test-Path -Path $requestedVersion)) {
        "Could not find node version $matchedVersion"
        return
    }

    # immediately add to the current powershell session path
    # NOTE: it's important to use uppercase PATH for Unix systems as env vars
    # are case-sensitive on Unix but case-insensitive on Windows
    $env:PATH = $binPath + [System.IO.Path]::PathSeparator + $env:PATH

    if ($Persist -ne '') {
        # also add to the permanent windows path
        $persistedPaths = @($requestedVersion)
        [Environment]::GetEnvironmentVariable('PATH', $Persist) -split [System.IO.Path]::PathSeparator | ForEach-Object {
            if (-not($_ -like "$nvmPath*")) {
                $persistedPaths += $_
            }
        }
        [Environment]::SetEnvironmentVariable('PATH', $persistedPaths -join [System.IO.Path]::PathSeparator, $Persist)
    }

    "Switched to node version $matchedVersion"
}

function Install-NodeVersion {
    <#
    .Synopsis
        Install a version of node.js
    .Description
        Download and install the specified version of node.js into the nvm directory. Once installed it can be used with Set-NodeVersion
    .Parameter $Version
        A semver range for the version of node.js to install
    .Parameter $Force
        Reinstall an already installed version of node.js
    .Parameter $architecture
        The architecture of node.js to install, defaults to [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    .Parameter $proxy
        Define HTTP proxy used when downloading an installer
    .Example
        Install-NodeVersion v5.0.0
        Install version 5.0.0 of node.js into the module directory
    .Example
        Install-NodeVersion ^5
        Install the latest 5.x.x version of node.js into the module directory
    .Example
        Install-NodeVersion v5.0.0 -Architecture x86
        Installs the x86 version even if you're on an x64 machine
    .Example
        Install-NodeVersion v5.0.0 -Architecture x86 -proxy http://localhost:3128
        Installs the x86 version even if you're on an x64 machine using default CNTLM proxy
    #>
    param(
        [string]
        [Parameter(Mandatory = $true)]
        $Version,

        [switch]
        $Force,

        [string]
        [ValidateSet('Arm', 'Arm64', 'X64', 'X86', 'AMD64')]
        $Architecture,

        [string]
        $Proxy
    )

    if ([string]::IsNullOrEmpty($Architecture)) {
        if (IsWindows) {
            $Architecture = $env:PROCESSOR_ARCHITECTURE
        }
        else {
            $Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
        }
    }

    $Architecture = $Architecture.ToLower()

    if ($version -match "latest") {
        $listing = "https://nodejs.org/dist/latest/"
        $r = (Invoke-WebRequest -UseBasicParsing $listing).content
        if ($r -match "node-(v[0-9\.]+)") {
            $version = $matches[1]
        }
        else {
            throw "failed to retrieve latest version from '$listing'"
        }
    }

    $matchedVersion = Get-NodeVersions -Filter $version -Remote | Select-Object -First 1

    $nvmPath = Get-NodeInstallLocation

    $versionPath = Join-Path $nvmPath $matchedVersion

    if ((Test-Path -Path $versionPath)) {
        if ($Force) {
            Remove-Item -Recurse -Force $versionPath
        }
        else {
            throw "Version $matchedVersion is already installed, use -Force to reinstall"
        }
    }

    New-Item $versionPath -ItemType 'Directory' | Out-Null

    if (IsMac) {
        # Download .tar.gz for macOS
        $file = "node-$matchedVersion-darwin-$architecture.tar.gz"
        $nodeUrl = "https://nodejs.org/dist/$matchedVersion/$file"
    }
    elseif (IsWindows) {
        $file = "node-$matchedVersion-x86.msi"
        $nodeUrl = "https://nodejs.org/dist/$matchedVersion/$file"

        if ($architecture -eq 'amd64') {
            $file = "node-$matchedVersion-x64.msi"

            if ($matchedVersion -match '^v0\.\d{1,2}\.\d{1,2}$') {
                $nodeUrl = "https://nodejs.org/dist/$matchedVersion/x64/$file"
            }
            else {
                $nodeUrl = "https://nodejs.org/dist/$matchedVersion/$file"
            }
        }
    }
    elseif (IsLinux) {
        $file = "node-$matchedVersion-linux-$architecture.tar.gz"
        $nodeUrl = "https://nodejs.org/dist/$matchedVersion/$file"
    }
    else {
        throw "Unsupported OS Platform: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)"
    }

    $outFile = Join-Path $versionPath $file
    Write-Host "Downloading $nodeUrl"
    if ($Proxy) {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $outFile -Proxy $Proxy
    }
    else {
        Invoke-WebRequest -Uri $nodeUrl -OutFile $outFile
    }

    $unpackPath = Join-Path $versionPath '.u'
    New-Item $unpackPath -ItemType Directory | Out-Null

    if ((IsMac) -or (IsLinux)) {
        # Extract .tar.gz
        tar -zxf $outFile --directory $unpackPath --strip=1
        Remove-Item -Force $outFile
        Move-Item (Join-Path $unpackPath '*') -Destination $versionPath -Force
    }
    elseif (IsWindows) {
        if (-Not (Get-Command msiexec)) {
            throw "msiexec is not in your path"
        }

        $args = @("/a", "`"$outFile`"", "/qb", "TARGETDIR=`"$unpackPath`"", '/quiet')

        Start-Process -FilePath "msiexec.exe" -Wait -PassThru -ArgumentList $args

        Move-Item (Join-Path (Join-Path $unpackPath 'nodejs') '*') -Destination $versionPath -Force
    }

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
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^v\d\.\d{1,2}\.\d{1,2}$')]
        $Version
    )

    $nvmPath = Get-NodeInstallLocation

    $requestedVersion = Join-Path $nvmPath $Version

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
        Used to show all the node.js versions installed to nvm, using the -Remote option allows you to list versions of node.js available for install. Providing a -Filter parameter can filter the versions using the pattern, either local or remote versions. The versions are sorted from highest to lowest and can be compared with PowerShell operators.
    .Parameter $Remote
        Indicate whether or not to list local or remote versions
    .Parameter $Filter
        A semver version range to filter versions
    .Example
        Get-NodeVersions -Filter '>=7.0.0 <9.0.0'

        Major      : 8
        Minor      : 9
        Patch      : 1
        PreRelease :
        Build      :

        Major      : 7
        Minor      : 9
        Patch      : 0
        PreRelease :
        Build      :
    .Example
        Get-NodeVersions -Filter '>=7.0.0 <9.0.0' | % {"$_"}

        v8.9.1
        v7.9.0
    .Example
        (Get-NodeVersions | Select-Object -First 1) -lt (Get-NodeVersions -Remote | Select-Object -First 1)

        True
    #>
    param(
        [switch]
        $Remote,

        [string]
        [Parameter(Mandatory = $false)]
        $Filter
    )

    $range = [SemVer.Range]::new($Filter)
    $versions = if ($Remote) {
        Invoke-WebRequest -Uri https://nodejs.org/dist/index.json | ConvertFrom-Json | ForEach-Object { $_.version } | ForEach-Object { [SemVer.Version]::new($_, $true) }
    }
    else {
        $nvmPath = Get-NodeInstallLocation

        if (!(Test-Path -Path $nvmPath)) {
            throw "No Node.js versions have been installed"
        }
        else {
            Get-ChildItem $nvmPath | ForEach-Object { [SemVer.Version]::new($_.Name, $true) }
        }
    }

    $versions | Where-Object { $range.IsSatisfied($_) } | Sort-Object -Descending
}

function Set-NodeInstallLocation {
    <#
    .Synopsis
        Sets the path where node.js versions will be installed into
    .Description
        This is used to override the default node.js install path for nvm, which is relative to the module install location. You would want to use this to get around the Windows path limit problem that plagues node.js installed. Note that to avoid collisions the unpacked files will be in a folder `.nvm\<version>` in the specified location.
    .Parameter $Path
        The root folder for nvm
    .Example
        Set-NodeInstallLocation -Path C:\Temp
    #>
    param(
        [string]
        [Parameter(Mandatory = $true)]
        $Path
    )

    $settings = $null
    $settingsFile = Join-Path $PSScriptRoot 'settings.json'

    if ((Test-Path $settingsFile) -eq $true) {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
    }
    else {
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
    }
    else {
        $settings = New-Object -TypeName PSObject -Prop @{ InstallPath = (Join-Path $PSScriptRoot 'vs') }
    }

    $settings.InstallPath
}
