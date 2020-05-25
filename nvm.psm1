#requires -version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/autocomplete-utils.ps1"

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
    .Parameter Version
        A semver version range for the node.js version you wish to use.
    .Parameter SemVer
        A SemVer object returned from Get-NodeVersions.
    .Parameter Persist
        If present, this will also set the node.js version to the permanent system path, of the specified scope, which will persist this setting for future powershell sessions and causes this version of node.js to be referenced outside of powershell.
    .Example
        C:\PS> Set-NodeVersion
        Set based on the .nvmrc or package.json engines node field
    .Example
        C:\PS> Set-NodeVersion 5.0.1
        Set using explicit version
    .Example
        C:\PS> Set-NodeVersion ~5.2
        Sets to the latest installed patch version of v5.2
    .Example
        C:\PS> Set-NodeVersion ^5
        Sets to the latest installed v5 version
    .Example
        C:\PS> Set-NodeVersion '>=5.0.0 <7.0.0'
        Sets to the latest installed version between v5 and v7
    .Example
        C:\PS> Get-NodeVersions '>=5.0.0 <7.0.0' | Set-NodeVersion
        Sets to the latest installed version between v5 and v7 that's actually installed
    .Example
        C:\PS> Set-NodeVersion v5.0.1 -Persist User
        Set and persist in permanent system path for the current user
    .Example
        C:\PS> Set-NodeVersion v5.0.1 -Persist Machine
        Set and persist in permanent system path for the machine (Note: requires an admin shell)
    .Link
        https://github.com/aaronpowell/ps-nvm/blob/master/.docs/reference.md/blob/master/.docs/reference.md#set-nodeversion
    #>
    [CmdletBinding(DefaultParameterSetName = 'String')]
    param(
        [string]
        [Parameter(ParameterSetName = 'String', Position = 0, ValueFromPipelineByPropertyName = $true)]
        $Version,
        [semver.version]
        [Parameter(ParameterSetName = 'SemVer', ValueFromPipeline = $true)]
        $SemVer,
        [string]
        [ValidateSet('User', 'Machine')]
        [Parameter(Mandatory = $false)]
        $Persist
    )

    if ($SemVer) {
        $Version = $SemVer.ToString()
    }

    $Version = Get-TargetNodeVersion($Version).Trim()

    $matchedVersion = if (!($Version -match "v\d+\.\d+\.\d+")) {
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

    # If the requested version is already reachable (and first priority in the PATH),
    # return early to not clutter the PATH with duplicate entries
    # and only log "switched ..." when the version was actually switched.
    # This makes it save to put Set-NodeVersion in the prompt function
    try {
        if ((Get-Command node -CommandType Application -ErrorAction SilentlyContinue).Source -eq (Join-Path $binPath 'node')) {
            Write-Verbose "Version $requestedVersion already set"
            return
        }
    }
    catch {
        # node is not in PATH yet, ignore
        Write-Verbose -Message 'PATH does not contain node.'
    }

    # separator
    $separator = [System.IO.Path]::PathSeparator

    # get PATH entries without nvm-install paths
    $nonNvmPath = ($env:PATH -split $separator | Where-Object { -not $_.StartsWith($nvmPath) }) -join $separator

    # immediately add to the current powershell session path
    # NOTE: it's important to use uppercase PATH for Unix systems as env vars
    # are case-sensitive on Unix but case-insensitive on Windows
    $env:PATH = @($binPath, $nonNvmPath) -join $separator
    $env:NPM_CONFIG_GLOBALCONFIG = (Join-Path $binPath npmrc)

    # make the path persistent (only on windows)
    if ($Persist -ne '') {
        if (-not ((IsMac) -or (IsLinux))) {
            $originalPath = [Environment]::GetEnvironmentVariable('PATH', $Persist)
            $cleanedPath = ($originalPath -split $separator | Where-Object { -not $_.StartsWith($nvmPath) }) -join $separator
            [Environment]::SetEnvironmentVariable('PATH', (@($binPath, $cleanedPath) -join $separator), $Persist)
            [Environment]::SetEnvironmentVariable('NPM_CONFIG_GLOBALCONFIG', (Join-Path $binPath npmrc), $Persist)
        }
        else {
            Add-NvmToProfile $Version $Persist
        }
    }

    Write-Information "Switched to node version $matchedVersion"

}

function Get-TargetNodeVersion($Version) {

    if (![string]::IsNullOrEmpty($Version)) {
        return $Version
    }

    if (Test-Path ./.nvmrc) {
        return Get-Content ./.nvmrc -Raw
    }

    if (Test-Path ./package.json) {
        $packageJson = Get-Content ./package.json -Raw | ConvertFrom-Json
        if ((Get-Member -InputObject $packageJson -Name 'engines') -and (Get-Member -InputObject $packageJson.engines -Name 'node')) {
            # Use node engine field as version range
            return $packageJson.engines.node
        }
    }

    $vsDefault = Join-Path (Get-NodeInstallLocation) "default"
    if (Test-Path $vsDefault) {
        return Get-Content $vsDefault -Raw
    }

    throw "Version not given, no .nvmrc found in folder, and package.json missing or does not contain node engines field"
}

function Add-NvmToProfile {
    param(
        [string]
        $Version,
        [ValidateSet('User', 'Machine')]
        $Scope
    )

    # Write default version number
    $vsDefault = Join-Path (Get-NodeInstallLocation) "default"
    $Version | Set-Content $vsDefault

    # Add command to profile script
    $targetProfile = $Profile.CurrentUserCurrentHost
    if ($Scope -eq 'Machine') {
        $targetProfile = $Profile.AllUsersCurrentHost
    }

    $profileSrc = if (Test-Path $targetProfile) { Get-Content $targetProfile } else { "" }
    if (!($profileSrc.Contains("Set-NodeVersion"))) {
        "`n# nvm`nSet-NodeVersion" | Add-Content $targetProfile
    }
}

function Install-NodeVersion {
    <#
    .Synopsis
        Install a version of node.js
    .Description
        Download and install the specified version of node.js into the nvm directory. Once installed it can be used with Set-NodeVersion
    .Parameter Version
        A semver range for the version of node.js to install
    .Parameter Force
        Reinstall an already installed version of node.js
    .Parameter Architecture
        The architecture of node.js to install, defaults to [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    .Parameter Proxy
        Define HTTP proxy used when downloading an installer
    .Example
        C:\PS> Install-NodeVersion v5.0.0
        Install version 5.0.0 of node.js into the module directory
    .Example
        C:\PS> Install-NodeVersion v5.0.0, v6.0.0
        Installs versions 5.0.0 and 6.0.0 of node.js into the module directory
    .Example
        C:\PS> Install-NodeVersion ^5
        Install the latest 5.x.x version of node.js into the module directory
    .Example
        C:\PS> Install-NodeVersion v5.0.0 -Architecture x86
        Installs the x86 version even if you're on an x64 machine
    .Example
        C:\PS> Install-NodeVersion v5.0.0 -Architecture x86 -proxy http://localhost:3128
        Installs the x86 version even if you're on an x64 machine using default CNTLM proxy
    .Link
        https://github.com/aaronpowell/ps-nvm/blob/master/.docs/reference.md#install-nodeversion
    #>
    [CmdletBinding()]
    param(
        [string[]]
        [Parameter(Mandatory = $false)]
        $Version,

        [switch]
        $Force,

        [string]
        [ValidateSet('Arm', 'Arm64', 'X64', 'X86', 'AMD64')]
        $Architecture,

        [string]
        $Proxy
    )

    # Turn off progress bar to speed up Invoke-WebRequest
    $CurrentProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    if ([string]::IsNullOrEmpty($Version)) {
        $Version = @(Get-TargetNodeVersion $Version $false)
    }

    foreach ($versionNumber in $Version) {
        $versionNumber = $versionNumber.Trim()

        if ([string]::IsNullOrEmpty($Architecture)) {
            if (IsWindows) {
                $Architecture = $env:PROCESSOR_ARCHITECTURE
            }
            else {
                $Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
            }
        }

        $Architecture = $Architecture.ToLower()

        if ($versionNumber -match "latest") {
            $listing = "https://nodejs.org/dist/latest/"
            $r = ( Invoke-WebRequest $listing -UseBasicParsing ).Content
            if ($r -match "node-(v[0-9\.]+)") {
                $versionNumber = $matches[1]
            }
            else {
                throw "failed to retrieve latest version from '$listing'"
            }
        }

        $matchedVersion = Get-NodeVersions -Filter $versionNumber -Remote | Select-Object -First 1

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

                if ($matchedVersion -match '^v0\.\d+\.\d+$') {
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
            Invoke-WebRequest -Uri $nodeUrl -OutFile $outFile -Proxy $Proxy -UseBasicParsing
        }
        else {
            Invoke-WebRequest -Uri $nodeUrl -OutFile $outFile -UseBasicParsing
        }

        $ProgressPreference = $CurrentProgressPreference

        # Make the unpack directory short to comply with Windows's 260 character path limit
        $unpackPath = Join-Path $versionPath '.u'
        Remove-Item $unpackPath -Force -Recurse -ErrorAction SilentlyContinue
        New-Item $unpackPath -ItemType Directory | Out-Null

        Write-Host "Installing $nodeUrl"
        if ((IsMac) -or (IsLinux)) {
            # Extract .tar.gz
            tar -zxf $outFile --directory $unpackPath --strip=1
            Remove-Item -Force $outFile
            Move-Item (Join-Path $unpackPath '*') -Destination $versionPath -Force

            # Ensure installation actually completed
            Get-Command (Join-Path (Join-Path $versionPath 'bin') 'node')

        }
        elseif (IsWindows) {
            if (-Not (Get-Command msiexec)) {
                throw "msiexec is not in your path"
            }

            $args = @("/a", "`"$outFile`"", "/qb", "TARGETDIR=`"$unpackPath`"")

            # Make sure to catch any errors since Start-Process doesn't throw based on the process ExitCode
            $result = Start-Process `
                -FilePath "msiexec.exe" `
                -Wait `
                -PassThru `
                -ArgumentList $args `
                -RedirectStandardError "$env:TEMP\stderr.log"
            if ($result.ExitCode -ne 0) {
                $errMsg = "ExitCode $($result.ExitCode): $(Get-Content "$env:TEMP\stderr.log")"
                Remove-Item "$env:TEMP\stderr.log"
                throw $errMsg
            }

            Move-Item (Join-Path (Join-Path $unpackPath 'nodejs') '*') -Destination $versionPath -Force

            # Ensure installation actually completed
            Get-Command (Join-Path $versionPath 'node.exe')
        }

        Set-Content -Value "prefix=$versionPath" -Path (Join-Path $versionPath npmrc)

        Remove-Item $unpackPath -Recurse -Force
    }
}

function Remove-NodeVersion {
    <#
    .Synopsis
        Removes an installed version of node.js
    .Description
        Removes an installed version of node.js along with any installed npm modules
    .Parameter Version
        The full version string of the node.js package to remove
    .Example
        C:\PS> Remove-NodeVersion v5.0.0
        Removes the v5.0.0 version of node.js from the nvm store
    .Example
        C:\PS> Get-NodeVersions | Remove-NodeVersion
        Remove ALL versions of node.js from the nvm store
    .Link
        https://github.com/aaronpowell/ps-nvm/blob/master/.docs/reference.md#get-nodeversion
    #>
    [CmdletBinding()]
    param(
        [string[]]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidatePattern('^v\d+\.\d+\.\d+$')]
        $Version
    )

    process {
        foreach ($versionNumber in $Version) {
            $nvmPath = Get-NodeInstallLocation

            $requestedVersion = Join-Path $nvmPath $versionNumber

            if (!(Test-Path -Path $requestedVersion)) {
                throw "Could not find node version $versionNumber"
            }

            Remove-Item $requestedVersion -Force -Recurse
        }
    }
}

function Get-NodeVersions {
    <#
    .Synopsis
        List local or remote node.js versions
    .Description
        Used to show all the node.js versions installed to nvm, using the -Remote option allows you to list versions of node.js available for install. Providing a -Filter parameter can filter the versions using the pattern, either local or remote versions. The versions are sorted from highest to lowest and can be compared with PowerShell operators.
    .Parameter Remote
        Indicate whether or not to list local or remote versions
    .Parameter Filter
        A semver version range to filter versions
    .Example
        C:\PS> Get-NodeVersions -Remote -Filter ">=7.0.0 <9.0.0"
        Show all versions available to download between v7 and v9
    .Example
        C:\PS> Get-NodeVersions -Filter '>=7.0.0 <9.0.0'
        Return the installed versions as strings
    .Example
        C:\PS>(Get-NodeVersions | Select-Object -First 1) -lt (Get-NodeVersions -Remote | Select-Object -First 1)
    .Link
        https://github.com/aaronpowell/ps-nvm/blob/master/.docs/reference.md#get-nodeversion
    #>
    [CmdletBinding()]
    param(
        [switch]
        $Remote,

        [string]
        [Parameter(Mandatory = $false)]
        $Filter
    )

    $range = [SemVer.Range]::new($Filter)
    $versions = @()
    $versions += if ($Remote) {
        $currentProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri https://nodejs.org/dist/index.json | ConvertFrom-Json | ForEach-Object { $_.version } | ForEach-Object { [SemVer.Version]::new($_, $true) }
        $ProgressPreference = $currentProgressPreference
    }
    else {
        $nvmPath = Get-NodeInstallLocation

        if (Test-Path -Path $nvmPath) {
            Get-ChildItem $nvmPath -Attributes Directory | ForEach-Object { [SemVer.Version]::new($_.Name, $true) }
        }
    }

    $versions | Where-Object { $range.IsSatisfied($_) } | Sort-Object -Descending -Property Major, Minor, Patch, PreRelease, Build
}

function Set-NodeInstallLocation {
    <#
    .Synopsis
        Sets the path where node.js versions will be installed into
    .Description
        This is used to override the default node.js install path for nvm, which is relative to the module install location. You would want to use this to get around the Windows path limit problem that plagues node.js installed. Note that to avoid collisions the unpacked files will be in a folder `.nvm\<version>` in the specified location.
    .Parameter Path
        The root folder for nvm
    .Example
        C:\PS> Set-NodeInstallLocation -Path C:\Temp
    #>
    [CmdletBinding()]
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
        Gets the current node.js install path
    .Description
        Will return the path that node.js versions will be installed into
    .EXAMPLE
        Get-NodeInstallLocation
    .Link
        https://github.com/aaronpowell/ps-nvm/blob/master/.docs/reference.md#get-nodeinstalllocation
    #>
    [CmdletBinding()]
    param ()
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
