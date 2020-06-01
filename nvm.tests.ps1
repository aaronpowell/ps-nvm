Remove-Module nvm -Force -ErrorAction SilentlyContinue
Import-Module ./nvm.psd1

Describe "Get-NodeVersions" {
    InModuleScope nvm {
        Context "Local versions" {
            It "Gets known versions" {
                $tmpDir = [system.io.path]::GetTempPath()
                Mock Get-NodeInstallLocation { Join-Path $tmpDir '.nvm\settings.json' }
                Mock Test-Path { return $true }
                Mock Get-ChildItem {
                    [PSCustomObject]@{
                        Name = 'v8.9.0'
                        Path = "$Path\v8.9.0"
                    }
                    [PSCustomObject]@{
                        Name = 'v9.0.0'
                        Path = "$Path\v9.0.0"
                    }
                }
                Mock Get-ChildItem -ParameterFilter { $Filter -match 'node' } {
                    [PSCustomObject]@{
                        Name        = 'node.exe'
                        VersionInfo = [PSCustomObject]@{
                            ProductVersion = ( Split-Path -Path $Path -Leaf ).Replace('v', '')
                        }
                    }
                }

                $versions = Get-NodeVersions
                $versions.Count | Should -Be 2
                $versions | Should -Be @('v9.0.0'; 'v8.9.0')
            }

            It "Gets known versions with filter" {
                $tmpDir = [system.io.path]::GetTempPath()
                Mock Get-NodeInstallLocation { Join-Path $tmpDir '.nvm\settings.json' }
                Mock Test-Path { return $true }
                Mock Get-ChildItem {
                    [PSCustomObject]@{
                        Name = 'v8.9.0'
                        Path = "$Path\v8.9.0"
                    }
                    [PSCustomObject]@{
                        Name = 'v9.0.0'
                        Path = "$Path\v9.0.0"
                    }
                }
                Mock Get-ChildItem -ParameterFilter { $Filter -match 'node' } {
                    [PSCustomObject]@{
                        Name        = 'node.exe'
                        VersionInfo = [PSCustomObject]@{
                            ProductVersion = ( Split-Path -Path $Path -Leaf ).Replace('v', '')
                        }
                    }
                }

                $versions = Get-NodeVersions -Filter 'v8.9.0'
                $versions | Should -Be 'v8.9.0'

            }

            It "Returns nothing when no versions are installed" {
                $tmpDir = [system.io.path]::GetTempPath()
                Mock Get-NodeInstallLocation { Join-Path $tmpDir '.nvm\settings.json' }
                Mock Test-Path { return $false }
                Get-NodeVersions -Filter 'v8.9.0' | Should -BeNullOrEmpty
            }
        }

        Context "Remote versions" {
            It "Will list remote versions" {
                $mockJson = "[
                    {""version"":""v9.0.0"",""date"":""2017-10-31"",""files"":[""aix-ppc64"",""headers"",""linux-arm64"",""linux-armv6l"",""linux-armv7l"",""linux-ppc64le"",""linux-x64"",""linux-x86"",""osx-x64-pkg"",""osx-x64-tar"",""src"",""sunos-x64"",""sunos-x86"",""win-x64-7z"",""win-x64-exe"",""win-x64-msi"",""win-x64-zip"",""win-x86-7z"",""win-x86-exe"",""win-x86-msi"",""win-x86-zip""],""npm"":""5.5.1"",""v8"":""6.2.414.32"",""uv"":""1.15.0"",""zlib"":""1.2.11"",""openssl"":""1.0.2l"",""modules"":""59"",""lts"":false},
                    {""version"":""v8.9.0"",""date"":""2017-10-31"",""files"":[""aix-ppc64"",""headers"",""linux-arm64"",""linux-armv6l"",""linux-armv7l"",""linux-ppc64le"",""linux-x64"",""linux-x86"",""osx-x64-pkg"",""osx-x64-tar"",""src"",""sunos-x64"",""sunos-x86"",""win-x64-7z"",""win-x64-exe"",""win-x64-msi"",""win-x64-zip"",""win-x86-7z"",""win-x86-exe"",""win-x86-msi"",""win-x86-zip""],""npm"":""5.5.1"",""v8"":""6.1.534.46"",""uv"":""1.15.0"",""zlib"":""1.2.11"",""openssl"":""1.0.2l"",""modules"":""57"",""lts"":""Carbon""},
                    {""version"":""v8.8.1"",""date"":""2017-10-25"",""files"":[""aix-ppc64"",""headers"",""linux-arm64"",""linux-armv6l"",""linux-armv7l"",""linux-ppc64le"",""linux-x64"",""linux-x86"",""osx-x64-pkg"",""osx-x64-tar"",""src"",""sunos-x64"",""sunos-x86"",""win-x64-7z"",""win-x64-exe"",""win-x64-msi"",""win-x64-zip"",""win-x86-7z"",""win-x86-exe"",""win-x86-msi"",""win-x86-zip""],""npm"":""5.4.2"",""v8"":""6.1.534.42"",""uv"":""1.15.0"",""zlib"":""1.2.11"",""openssl"":""1.0.2l"",""modules"":""57"",""lts"":false}
                ]"

                Mock Invoke-WebRequest { return $mockJson }

                $versions = Get-NodeVersions -Remote
                $versions.Count | Should -Be 3
            }

            It "Will list remote versions with filter" {
                $mockJson = "[
                    {""version"":""v9.0.0"",""date"":""2017-10-31"",""files"":[""aix-ppc64"",""headers"",""linux-arm64"",""linux-armv6l"",""linux-armv7l"",""linux-ppc64le"",""linux-x64"",""linux-x86"",""osx-x64-pkg"",""osx-x64-tar"",""src"",""sunos-x64"",""sunos-x86"",""win-x64-7z"",""win-x64-exe"",""win-x64-msi"",""win-x64-zip"",""win-x86-7z"",""win-x86-exe"",""win-x86-msi"",""win-x86-zip""],""npm"":""5.5.1"",""v8"":""6.2.414.32"",""uv"":""1.15.0"",""zlib"":""1.2.11"",""openssl"":""1.0.2l"",""modules"":""59"",""lts"":false},
                    {""version"":""v8.9.0"",""date"":""2017-10-31"",""files"":[""aix-ppc64"",""headers"",""linux-arm64"",""linux-armv6l"",""linux-armv7l"",""linux-ppc64le"",""linux-x64"",""linux-x86"",""osx-x64-pkg"",""osx-x64-tar"",""src"",""sunos-x64"",""sunos-x86"",""win-x64-7z"",""win-x64-exe"",""win-x64-msi"",""win-x64-zip"",""win-x86-7z"",""win-x86-exe"",""win-x86-msi"",""win-x86-zip""],""npm"":""5.5.1"",""v8"":""6.1.534.46"",""uv"":""1.15.0"",""zlib"":""1.2.11"",""openssl"":""1.0.2l"",""modules"":""57"",""lts"":""Carbon""},
                    {""version"":""v8.8.1"",""date"":""2017-10-25"",""files"":[""aix-ppc64"",""headers"",""linux-arm64"",""linux-armv6l"",""linux-armv7l"",""linux-ppc64le"",""linux-x64"",""linux-x86"",""osx-x64-pkg"",""osx-x64-tar"",""src"",""sunos-x64"",""sunos-x86"",""win-x64-7z"",""win-x64-exe"",""win-x64-msi"",""win-x64-zip"",""win-x86-7z"",""win-x86-exe"",""win-x86-msi"",""win-x86-zip""],""npm"":""5.4.2"",""v8"":""6.1.534.42"",""uv"":""1.15.0"",""zlib"":""1.2.11"",""openssl"":""1.0.2l"",""modules"":""57"",""lts"":false}
                ]"

                Mock Invoke-WebRequest { return $mockJson }

                $versions = Get-NodeVersions -Remote -Filter "v8"
                $versions.Count | Should -Be 2
            }
        }
    }
}

Describe "Get-NodeInstallLocation" {
    InModuleScope nvm {
        It "Should return the location when it exists" {
            $tmpDir = [system.io.path]::GetTempPath()
            $installPath = Join-Path $tmpDir '.nvm'
            Mock Test-Path { return $true }
            Mock Get-Content { return @{ InstallPath = $installPath } | ConvertTo-Json }

            $location = Get-NodeInstallLocation
            $location | Should -Be $installPath
        }
    }
}

Describe "Install-NodeVersion" {
    InModuleScope nvm {
        Context "auto-discovery" {
            BeforeEach {
                $nodeVersion = 'v9.0.0'
            }

            It "Install version from the .nvmrc file" -Skip:($env:include_integration_tests -ne $true) {
                Mock Test-Path -ParameterFilter { $Path -match '.nvmrc$' } { return $true }
                Mock Get-Content -ParameterFilter { $Path -match '.nvmrc$' } { return $nodeVersion }

                Install-NodeVersion

                $versions = Get-NodeVersions -Filter 'v9.0.0'
                $versions | Should -Be 'v9.0.0'
            }

            It "Install version from the package.json field" -Skip:($env:include_integration_tests -ne $true) {
                Mock Test-Path -ParameterFilter { $Path -match '.nvmrc$' } { return $false }
                Mock Test-Path -ParameterFilter { $Path -match 'package.json$' } { return $true }
                Mock Get-Content -ParameterFilter { $Path -match 'package.json$' } {
                    return @{
                        engines = @{
                            node = '^9.0.0'
                        }
                    } | ConvertTo-Json
                }

                Install-NodeVersion

                $versions = Get-NodeVersions -Filter 'v9.*'
                $versions | Should -BeLike 'v9.*'
            }

            It "Will error if no version in the package.json field" -Skip:($env:include_integration_tests -ne $true) {
                Mock Test-Path -ParameterFilter { $Path -match '.nvmrc$' } { return $false }
                Mock Test-Path -ParameterFilter { $Path -match 'package.json$' } { return $true }
                Mock Get-Content -ParameterFilter { $Path -match 'package.json$' } {
                    return @{
                        engines = @{
                        }
                    } | ConvertTo-Json
                }

                { Install-NodeVersion } | Should -Throw
            }

            It "Will error if no version, no .nvmrc and no package.json, no default" -Skip:($env:include_integration_tests -ne $true) {
                Mock Get-NodeInstallLocation { return "/" }
                Mock Test-Path -ParameterFilter { $Path -eq '/default' } { return $false }
                Mock Test-Path -ParameterFilter { $Path -match '.nvmrc$' } { return $false }
                Mock Test-Path -ParameterFilter { $Path -match 'package.json$' } { return $false }

                { Install-NodeVersion } | Should -Throw "Version not given, no .nvmrc found in folder, and package.json missing or does not contain node engines field"
            }
        }

        Context "Installing with a specific version" {
            It "Install a requested version" -Skip:($env:include_integration_tests -ne $true) {
                Install-NodeVersion -Version 'v9.0.0'

                $versions = Get-NodeVersions -Filter 'v9.0.0'
                $versions | Should -Be 'v9.0.0'
            }

            It "Throws when version already exists" -Skip:($env:include_integration_tests -ne $true) {
                Install-NodeVersion -Version 'v9.0.0'
                { Install-NodeVersion -Version 'v9.0.0' } | Should -Throw
            }

            It "Won't throw when version already exists if you use the -Force flag" -Skip:($env:include_integration_tests -ne $true) {
                { Install-NodeVersion -Version 'v9.0.0' -Force } | Should -Not -Throw
            }

            It "Can install without a 'v' prefix" -Skip:($env:include_integration_tests -ne $true) {
                { Install-NodeVersion -Version '9.0.0' -Force } | Should -Not -Throw
            }

            It "Can install multiple versions" -Skip:($env:include_integration_tests -ne $true) {
                { Install-NodeVersion -Version '10.0.0', '11.0.0' } | Should -Not -Throw
            }
        }

        Context "Major version installing" {
            It "Can install from just a major version" -Skip:($env:include_integration_tests -ne $true) {
                Install-NodeVersion -Version '9'

                $versions = Get-NodeVersions -Filter 'v9'
                $versions | Should -Match 'v9'
            }
        }

        Context "Major and minor version installing" {
            It "Can install from just a major and minor version" -Skip:($env:include_integration_tests -ne $true) {
                Install-NodeVersion -Version '9.0'

                $versions = Get-NodeVersions -Filter 'v9.0'
                $versions | Should -Match 'v9.0'
            }
        }

        Context "Installing with a keyword" {
            It "Installs under the `latest` flag" -Skip:($env:include_integration_tests -ne $true) {
                Install-NodeVersion -Version 'latest'

                $versions = Get-NodeVersions
                $versions.GetType() | Should -Be 'SemVer.Version'
            }
        }

        Context "Incomplete installation" {
            BeforeEach {
                Mock Get-Command -ParameterFilter { $Name -match 'node' -or $Name -match 'npm' } {
                    throw (
                        "The term '$Name' is not recognized as the name of a cmdlet, function, script file, or " +
                        "operable program. Check the spelling of the name, or if a path was included, verify that " +
                        "the path is correct and try again."
                    )
                }
            }

            It "Will error if node or npm can't be called" -Skip:($env:include_integration_tests -ne $true) {
                { Install-NodeVersion latest } | Should -Throw
            }
        }
    }

    BeforeEach {
        $basePath = if ($IsWindows) { $env:SystemDrive } else { [system.io.path]::GetTempPath() }
        $installLocation = Join-Path $basePath '.nvm'
        Set-NodeInstallLocation -Path $installLocation
    }

    AfterEach {
        if (Test-Path $installLocation) {
            Remove-Item -Recurse -Force $installLocation
        }

        $settingsFile = Join-Path $PSScriptRoot 'settings.json'

        if ((Test-Path $settingsFile) -eq $true) {
            Remove-Item -Force $settingsFile
        }
    }
}

Describe "Set-NodeVersion" {
    InModuleScope nvm {
        BeforeEach {
            $nodeVersion = 'v9.0.0'
        }
        Context "auto-discovery" {

            It "Will set from the .nvmrc file" {
                $tmpDir = [system.io.path]::GetTempPath()
                $nvmDir = Join-Path $tmpDir '.nvm'
                Mock Test-Path { return $true } -ParameterFilter { $Path.StartsWith('variable') -eq $false }
                Mock Get-Content -ParameterFilter { $Path -match '\.nvmrc$' } { return $nodeVersion }
                Mock Get-NodeInstallLocation { return $nvmDir }

                Set-NodeVersion -InformationVariable infos
                $infos | Should -Be "Switched to node version $nodeVersion"
            }

            It "Will set from the engines package.json field" {
                $tmpDir = [system.io.path]::GetTempPath()
                Mock Test-Path -ParameterFilter { $Path.StartsWith('variable') -eq $false } {
                    return (-not ($Path -match '\.nvmrc$'))
                }
                Mock Get-Content -ParameterFilter { $Path -match 'package.json$' } {
                    return @{
                        engines = @{
                            node = '^9.0.0'
                        }
                    } | ConvertTo-Json
                }
                Mock Get-NodeVersions { return 'v9.1.0' }
                Mock Get-NodeInstallLocation { return Join-Path $tmpDir '.nvm' }

                Set-NodeVersion -InformationVariable infos
                $infos | Should -Be "Switched to node version v9.1.0"
            }

            It "Will set from the default file" {
                $tmpDir = [system.io.path]::GetTempPath()
                $nvmDir = Join-Path $tmpDir '.nvm'
                Mock Test-Path { return $false } -ParameterFilter { $Path.Contains('.nvmrc') }
                Mock Test-Path { return $false } -ParameterFilter { $Path.Contains('./package.json') }
                Mock Test-Path { return $true } -ParameterFilter { $Path.Contains((Join-Path $nvmDir 'default')) }
                Mock Get-Content -ParameterFilter { $Path -match 'default$' } { return $nodeVersion }
                Mock Get-NodeInstallLocation { return $nvmDir }

                Set-NodeVersion -InformationVariable infos
                $infos | Should -Be "Switched to node version $nodeVersion"
            }

            It "Will error if no version in the package.json field" {
                Mock Test-Path -ParameterFilter { $Path.StartsWith('variable') -eq $false } {
                    return (-not ($Path -match '\.nvmrc$'))
                }
                Mock Get-Content -ParameterFilter { $Path -match 'package.json$' } {
                    return @{
                        engines = @{
                        }
                    } | ConvertTo-Json
                }

                { Set-NodeVersion } | Should -Throw
            }

            It "Will error if no version, no .nvmrc and no package.json, no default" {
                Mock Get-NodeInstallLocation { return "/" }
                Mock Test-Path { return $false } -ParameterFilter { $Path -eq (Join-Path (Get-NodeInstallLocation) 'default') }
                Mock Test-Path { return $false } -ParameterFilter { $Path.Contains('.nvmrc') }
                Mock Test-Path { return $false } -ParameterFilter { $Path.Contains('./package.json') }

                { Set-NodeVersion } | Should -Throw "Version not given, no .nvmrc found in folder, and package.json missing or does not contain node engines field"
            }
        }

        Context "Set from version string" {
            It "Will set from the supplied version" {
                Set-NodeVersion $nodeVersion -InformationVariable infos
                $infos | Should -Be "Switched to node version $nodeVersion"
            }

            It "Will set from a version range" {
                Mock Get-NodeVersions { return @('v9.0.0'; 'v8.9.0') }

                Set-NodeVersion 'v9' -InformationVariable infos
                $infos | Should -Be "Switched to node version $nodeVersion"
            }

            It "Will set from a version range with caret" {
                Mock Get-NodeVersions { return @('v9.0.0'; 'v8.9.0') }

                Set-NodeVersion '^9.0.0' -InformationVariable infos
                $infos | Should -Be "Switched to node version $nodeVersion"
            }

            It "Will throw error on unmatched version range" {
                {
                    Mock Get-NodeVersions { return @() }

                    Set-NodeVersion 'v7'
                } | Should -Throw "No version found that matches v7"
            }

            It "Will set npm config path" {
                Mock Get-NodeVersions { return @('v9.0.0') }

                Set-NodeVersion 'v9' -InformationVariable infos
                $env:NPM_CONFIG_GLOBALCONFIG | Should -Not -Be $null
            }

            It "Will update environment path" {
                $explicitVersion = "v9.32.99"
                $nvmPath = Get-NodeInstallLocation
                Set-NodeVersion -Version 'v9.0.0' -InformationVariable infos
                Set-NodeVersion -Version $explicitVersion -InformationVariable infos
                $separator = [System.IO.Path]::PathSeparator
                [System.String[]]$nvmPaths = ($env:PATH -split $separator) | Where-Object { $_.StartsWith($nvmPath) }
                $nvmPaths.Count | Should -Be 1
                $nvmPaths | Should -Match $explicitVersion
            }

            BeforeEach {
                $tmpDir = [system.io.path]::GetTempPath()
                Mock Get-NodeInstallLocation { return Join-Path $tmpDir '.nvm' }
                Mock Test-Path { return $true } -ParameterFilter { $Path.StartsWith((Join-Path $tmpDir '.nvm')) -eq $true }
            }
        }

        Context "pipeline" {
            BeforeEach {
                $nodeVersion = "v9.0.0"
                Mock Test-Path -ParameterFilter { $Path -match 'vs' } { return $true }
                Mock Get-ChildItem {
                    [PSCustomObject]@{
                        Name = 'v9.0.0'
                        Path = "$Path\v9.0.0"
                    }
                }
                Mock Get-ChildItem -ParameterFilter { $Filter -match 'node' } {
                    [PSCustomObject]@{
                        Name        = 'node.exe'
                        VersionInfo = [PSCustomObject]@{
                            ProductVersion = ( Split-Path -Path $Path -Leaf ).Replace('v', '')
                        }
                    }
                }
            }
            It "Will set from the supplied version via Install-NodeVersion pipeline output" {
                [PSCustomObject]@{
                    Name    = 'node.exe'
                    Version = '9.0.0'
                } | Set-NodeVersion -InformationVariable infos
                $infos | Should -Be "Switched to node version $nodeVersion"
            }

            It "Will set from the supplied version via Get-NodeVersion pipeline output" {
                [SemVer.Version]::new($nodeVersion, $true) | Set-NodeVersion -InformationVariable infos
                $infos | Should -Be "Switched to node version $nodeVersion"
            }
        }
    }
    AfterEach {
        $settingsFile = Join-Path $PSScriptRoot 'settings.json'

        if ((Test-Path $settingsFile) -eq $true) {
            Remove-Item -Force $settingsFile
        }
    }
}

Describe "Remove-NodeVersion" {
    InModuleScope nvm {
        It "Should remove a version" {
            $tmpDir = [system.io.path]::GetTempPath()
            Mock Get-NodeInstallLocation { return $tmpDir }
            Mock Test-Path { return $true }
            Mock Remove-Item { }

            Remove-NodeVersion 'v9.0.0'

            Assert-MockCalled -CommandName Remove-Item -Times 1 -ParameterFilter { $Path -eq (Join-Path $tmpDir 'v9.0.0') }
        }

        It "Should remove multiple versions" {
            $tmpDir = [system.io.path]::GetTempPath()
            Mock Get-NodeInstallLocation { return $tmpDir }
            Mock Test-Path { return $true }
            Mock Remove-Item { }

            Remove-NodeVersion 'v9.0.0', 'v10.0.0'

            Assert-MockCalled -CommandName Remove-Item -Times 1 -ParameterFilter { $Path -eq (Join-Path $tmpDir 'v9.0.0') }
            Assert-MockCalled -CommandName Remove-Item -Times 1 -ParameterFilter { $Path -eq (Join-Path $tmpDir 'v10.0.0') }
        }

        It "Should remove versions passed from the pipeline" {
            $tmpDir = [system.io.path]::GetTempPath()
            Mock Get-NodeInstallLocation { return $tmpDir }
            Mock Test-Path { return $true }
            Mock Remove-Item { }
            Mock Get-NodeVersions {
                'v9.0.0'
                'v10.0.0'
            }

            Get-NodeVersions | Remove-NodeVersion

            Assert-MockCalled -CommandName Remove-Item -Times 1 -ParameterFilter { $Path -eq (Join-Path $tmpDir 'v9.0.0') }
            Assert-MockCalled -CommandName Remove-Item -Times 1 -ParameterFilter { $Path -eq (Join-Path $tmpDir 'v10.0.0') }
        }

        It "Should throw when version doesn't exist" {
            $tmpDir = [system.io.path]::GetTempPath()
            Mock Get-NodeInstallLocation { return $tmpDir }
            Mock Test-Path { return $false }
            Mock Remove-Item { }

            $version = 'v9.0.0'
 { Remove-NodeVersion $version } | Should -Throw "Could not find node version $version"
        }
    }
}
