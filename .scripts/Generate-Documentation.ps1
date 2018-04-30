
Import-Module "$PSScriptRoot/../nvm.psd1"
$version = (Import-PowerShellDataFile "$PSScriptRoot/../nvm.psd1").ModuleVersion

$toc = ''
$doc = ''


(Get-Module nvm | Where-Object { $_.Version -eq $version }).ExportedCommands.Values.Name | Sort-Object | ForEach-Object {
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
<!-- This file is generated. To regenerate, run .scripts/Generate-Documentation.ps1 -->

# Command Reference

$toc
$doc
"@

$fullMd | Out-File "$PSScriptRoot/../.docs/reference.md"
