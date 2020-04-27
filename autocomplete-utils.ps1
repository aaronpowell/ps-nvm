[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
[CmdletBinding()]
param ()

$completion_AvailableNodeVersions = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-NodeVersions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', ('{0} ({1})' -f $_, $_)
    }
}

if (-not (Test-Path variable:global:options)) { $global:options = @{CustomArgumentCompleters = @{};NativeArgumentCompleters = @{}}}
$global:options['CustomArgumentCompleters']['Remove-NodeVersion:Version'] = $completion_AvailableNodeVersions
$global:options['CustomArgumentCompleters']['Set-NodeVersion:Version'] = $completion_AvailableNodeVersions

$function:tabexpansion2 = $function:tabexpansion2 -replace 'End\r\n{','End { if ($null -ne $options) { $options += $global:options} else {$options = $global:options}'
