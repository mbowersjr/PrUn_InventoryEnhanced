[CmdletBinding(SupportsShouldProcess)]
param(
    # [Parameter(Mandatory=$false)]
    # [string]
    # $BaseDirectory,

    # [Parameter(Mandatory=$false)]
    # [string]
    # $OutputPath
)

# Path settings
$outputDirName = "dist"
$sourceDirName = "src"
$outputName = "PrUn_InventoryEnhanced.user.js"
$scriptName = "main.js"
$headerTemplateName = "header.template.js"
$headerValuesName = "header.values.json"

function Test-FileExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [ValidateNotNullOrEmpty()]
        [string]
        $ErrorMessage
    )

    if (!(Test-Path -LiteralPath $Path)) {
        $msg = ($null -ne $ErrorMessage) ? $ErrorMessage : "Required file does not exist: $Path"
        $ex = [System.Management.Automation.ItemNotFoundException]::new($msg)
        $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errRecord = [System.Management.Automation.ErrorRecord]::new($ex, 'PathNotFound', $category, $Path)
        $PSCmdlet.WriteError($errRecord)

        return $false;
    }

    return $true;
}

$outputDir = Join-Path -Path . -ChildPath $outputDirName
$sourceDir = Join-Path -Path . -ChildPath $sourceDirName
$scriptPath = Join-Path -Path $sourceDir -ChildPath $scriptName
$headerTemplatePath = Join-Path -Path $sourceDir -ChildPath $headerTemplateName
$headerValuesPath = Join-Path -Path $sourceDir -ChildPath $headerValuesName
$outputPath = Join-Path -Path $outputDir -ChildPath $outputName

Write-Host "Building script from:"
Write-Host "-->  $scriptPath"
Write-Host "-->  $headerTemplatePath"
Write-Host "-->  $headerValuesPath"
Write-Host ""

$filesExist = (Test-FileExists -Path $scriptPath -ErrorMessage "Could not find main script file at expected path '$scriptPath'") -and
              (Test-FileExists -Path $headerTemplatePath -ErrorMessage "Could not find header template file at expected path '$headerTemplatePath'") -and
              (Test-FileExists -Path $headerValuesPath -ErrorMessage "Could not find header values file at expected path '$headerValuesPath'")

if (!$filesExist) {
    # $errorMessages = Join-String -InputObject ($err | % Message) -Separator [Environment]::NewLine
    throw [System.InvalidOperationException]::new("Build failed. Required file(s) could not be found.")
}

$scriptText = Get-Content -Path $scriptPath -Raw
$headerTemplateText = Get-Content -Path $headerTemplatePath -Raw
$headerValuesJson = Get-Content -Path $headerValuesPath -Raw
$headerValuesHash = ConvertFrom-Json -InputObject $headerValuesJson -AsHashtable

$versionValue = Get-Date -Format "yyyy-MM-dd_HH-mm"
$headerValuesHash.Add("version", $versionValue)

Write-Host "Creating userscript header..."

foreach ($kv in $headerValuesHash.GetEnumerator()) {
    $key = $($kv.Key)
    $value = $($kv.Value)
    $placeholder = "{{$key}}"

    Write-Host "-->  $key : $value"

    $headerTemplateText = $headerTemplateText.Replace($placeholder, $value)
}

Write-Host ""

if (!(Test-Path -LiteralPath $outputDir)) {
    Write-Host "Creating output directory: $outputDir"
    New-Item -ItemType Directory -Path $outputDir
}

$outputText = $headerTemplateText + [Environment]::NewLine + $scriptText
Out-File -FilePath $outputPath -InputObject $outputText -Encoding utf8

Write-Host "Build complete: $outputPath"
