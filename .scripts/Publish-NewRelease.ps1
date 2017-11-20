#requires -version 3.0
param(
    # NuGet API Key to publish to the gallery
    [Parameter(Mandatory=$true)]
    [string]
    $NuGetAPIKey
)

Publish-Module -Path $PSScriptRoot -NuGetApiKey $NuGetAPIKey
