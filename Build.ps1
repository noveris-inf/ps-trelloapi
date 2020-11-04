<#
#>

[CmdletBinding()]
param(
)

########
# Global settings
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2

########
# Modules
Remove-Module Noveris.Build -EA SilentlyContinue
Import-Module ./source/Noveris.Build

########
# Project settings
$projectName = "Noveris.TrelloApi"

########
# Capture version information
$version = Get-BuildVersionInfo -Sources @(
    $Env:GITHUB_REF,
    $Env:BUILD_SOURCEBRANCH,
    $Env:CI_COMMIT_TAG,
    $Env:BUILD_VERSION,
    "v0.1.0"
)

########
# Set up build directory
Use-BuildDirectories @(
    "package",
    "stage"
)

########
# Build stage
Invoke-BuildStage -Name "Build" -Script {

    Write-Information "Updating version information"
    Write-Information ("Setting BUILD_VERSION: " + $version.Full)
    Write-Information ("##vso[task.setvariable variable=BUILD_VERSION;]" + $version.Full)

    # Clear build directories
    Clear-BuildDirectories

    # Template PowerShell module definition
    Write-Information "Templating Noveris.TrelloApi.psd1"
    Format-TemplateFile -Template source/Noveris.TrelloApi.psd1.tpl -Target source/Noveris.TrelloApi/Noveris.TrelloApi.psd1 -Content @{
        __FULLVERSION__ = $version.Full
    }

    # Publish module
    Publish-Module -Path ./source/Noveris.TrelloApi -NuGetApiKey $Env:NUGET_API_KEY

    Copy-Item ./source/Noveris.TrelloApi/* ./stage/ -Force -Recurse

    Write-Information "Packaging artifacts"
    $version = $version.Full
    $artifactName = "package/${projectName}-${version}.zip"
    Write-Information "Target file: ${artifactName}"

    Compress-Archive -Destination $artifactName -Path "./stage/*" -Force
}