<#
.SYNOPSIS
    Smart wrapper to locate and invoke the root LightSword build.ps1 script from subdirectories.
#>

[CmdletBinding()]
param (
    [switch]$Clean,
    [int]$Port = 0
)

$dir = $PSScriptRoot
while ($dir -and -not (Test-Path (Join-Path $dir "bible_core"))) {
    $parent = Split-Path -Parent $dir
    if ($parent -eq $dir) { break }
    $dir = $parent
}

$rootBuildScript = Join-Path $dir "build.ps1"

if (Test-Path $rootBuildScript) {
    & $rootBuildScript -Clean:$Clean -Port:$Port
} else {
    Write-Error "Could not locate root build.ps1"
}
