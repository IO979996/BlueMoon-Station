# Copy from WhiteMoon to BlueMoon only the assets required for HFR and Crystallizer.
# Run from BlueMoon-Station root. Pass WhiteMoon root as first argument, or use sibling folder.
param([string]$WhiteMoonRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) "WhiteMoon-Station"))

$ErrorActionPreference = "Stop"
$BlueMoon = $PSScriptRoot
if (-not (Test-Path $WhiteMoonRoot)) {
    Write-Error "WhiteMoon root not found: $WhiteMoonRoot. Pass it as first argument."
}

# Required for HFR: single icon file (all HFR parts use it)
$hfrIcon = "icons\obj\machines\atmospherics\hypertorus.dmi"
$src = Join-Path $WhiteMoonRoot $hfrIcon
$dst = Join-Path $BlueMoon $hfrIcon
if (Test-Path $src) {
    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    Copy-Item -Path $src -Destination $dst -Force
    Write-Host "Copied: $hfrIcon"
} else {
    Write-Warning "Missing in WhiteMoon: $hfrIcon (HFR will have no sprites)."
}

# Crystallizer: machine icon, crystal items, pipe underlays for overlay
$crystallizerFiles = @(
    "icons\obj\machines\atmospherics\machines.dmi",
    "icons\obj\pipes_n_cables\atmos.dmi",
    "icons\obj\pipes_n_cables\pipe_underlays.dmi"
)
foreach ($rel in $crystallizerFiles) {
    $src = Join-Path $WhiteMoonRoot $rel
    $dst = Join-Path $BlueMoon $rel
    if (Test-Path $src) {
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        Copy-Item -Path $src -Destination $dst -Force
        Write-Host "Copied: $rel"
    } else {
        Write-Warning "Missing in WhiteMoon: $rel"
    }
}

# HFR countdown announcement sound
$soundNotice = "sound\announcer\notice\notice3.ogg"
$srcSound = Join-Path $WhiteMoonRoot $soundNotice
$dstSound = Join-Path $BlueMoon $soundNotice
if (Test-Path $srcSound) {
    $dstSoundDir = Split-Path $dstSound -Parent
    if (-not (Test-Path $dstSoundDir)) { New-Item -ItemType Directory -Path $dstSoundDir -Force | Out-Null }
    Copy-Item -Path $srcSound -Destination $dstSound -Force
    Write-Host "Copied: $soundNotice"
} else {
    Write-Warning "Missing in WhiteMoon: $soundNotice"
}

Write-Host "Done. HFR and Crystallizer assets copied."
