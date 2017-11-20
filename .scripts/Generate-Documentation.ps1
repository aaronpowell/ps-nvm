
$toc = ''
$doc = ''

(Get-Module nvm).ExportedCommands.Values.Name | Sort-Object | ForEach-Object {
    $help = Get-Help $_

    $toc += @"
- [``$($help.Name)``](#$($help.Name.ToLower()))

"@

    $examples = $help.examples.example | ForEach-Object {
        @"

``````powershell
$($_.code)
``````

$($_.remarks.Text)

"@
    }

    $parameters = if ($help.parameters.parameter -eq $null) {
        'None'
    }
    else {
        $help.parameters.parameter | ForEach-Object {
            @"
- ``-$($_.name) <$($_.type.name)>``$('  ')
  $($_.description.Text)

"@
        }
    }

    $inlineParameters = ($help.parameters.parameter | Where-Object { $_ -ne $null } | ForEach-Object { "-$($_.name) <$($_.type.name)>" }) -join ' '

    $commandDoc = @"
### ``$($help.Name)``
<a id="$($help.Name.ToLower())"></a>

$($help.description.Text)

``````powershell
$($help.Name) $inlineParameters
``````

#### Parameters
$parameters


#### Examples
$examples
"@
    $doc += $commandDoc
}

$fullMd = @"
<!-- BEGIN OF GENERATED DOCUMENTATION -->
<!-- to regenerate, run .scripts/Generate-Documentation.ps1 -->
## Command Reference

$toc
$doc
<!-- END OF GENERATED DOCUMENTATION -->
"@

# Escape regexp special characters ($)
$replacement = $fullMd -replace '\$', '$$$$'

((Get-Content -Raw "$PSScriptRoot/../README.md") -replace '(?ms)<!-- BEGIN OF GENERATED DOCUMENTATION -->.*<!-- END OF GENERATED DOCUMENTATION -->', $replacement).TrimEnd() | Out-File "$PSScriptRoot/../README.md"
