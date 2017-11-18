#requires -version 3.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    dotnet publish -o .
    Copy-Item -Path SemVer.dll -Destination (Join-Path -Path $PSScriptRoot '..')
}
