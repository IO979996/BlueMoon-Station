# Build atmos_reactions: static library (atmos_reactions.lib / libatmos_reactions.a)
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$buildDir = Join-Path $root "build"
$outDir = Join-Path $root "out"

# Prefer CMake if available
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if ($cmake) {
    Write-Host "Using CMake..."
    if (!(Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }
    Push-Location $buildDir
    try {
        cmake $root -DCMAKE_BUILD_TYPE=Release
        cmake --build . --config Release
        if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
        $lib = Get-ChildItem -Recurse -Filter "atmos_reactions.*" | Where-Object { $_.Extension -match '\.(lib|a)$' } | Select-Object -First 1
        if ($lib) { Copy-Item $lib.FullName $outDir }
        Write-Host "Build done. Output: $outDir"
    } finally {
        Pop-Location
    }
    exit 0
}

# Add MSYS2 UCRT64 to PATH if present (g++ from winget MSYS2)
$msysUcrt = "C:\msys64\ucrt64\bin"
if (Test-Path (Join-Path $msysUcrt "g++.exe")) {
    $env:Path = $msysUcrt + ";" + $env:Path
}

# Fallback: try compilers directly
$compilers = @(
    @{ Name = "g++"; Cmd = "g++"; Args = "-std=c++17", "-O2", "-c", "reactions.cpp", "-I.", "-o", "reactions.o" },
    @{ Name = "clang++"; Cmd = "clang++"; Args = "-std=c++17", "-O2", "-c", "reactions.cpp", "-I.", "-o", "reactions.o" }
)

foreach ($c in $compilers) {
    $exe = Get-Command $c.Cmd -ErrorAction SilentlyContinue
    if ($exe) {
        Write-Host "Building with $($c.Name)..."
        Set-Location $root
        & $exe.Source $c.Args
        if ($LASTEXITCODE -eq 0) {
            if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
            Copy-Item "reactions.o" (Join-Path $outDir "reactions.o")
            # Build BYOND extension DLL if we have reaction_runner
            if (Test-Path "reaction_runner.cpp") {
                & $exe.Source "-std=c++17", "-O2", "-c", "reaction_runner.cpp", "-I.", "-o", "reaction_runner.o"
                if ($LASTEXITCODE -eq 0) {
                    & $exe.Source "-std=c++17", "-O2", "-shared", "-o", "atmos_cpp.dll", "byond_bridge.cpp", "reaction_runner.o", "reactions.o", "-I.", "-static-libgcc", "-static-libstdc++"
                    if ($LASTEXITCODE -eq 0) {
                        Copy-Item "atmos_cpp.dll" $outDir -Force
                        $projRoot = (Resolve-Path (Join-Path $root "..\..\..")).Path
                        Copy-Item "atmos_cpp.dll" $projRoot -Force -ErrorAction SilentlyContinue
                        Write-Host "OK: atmos_cpp.dll -> $outDir and project root"
                    }
                }
            }
            Write-Host "OK: reactions.o -> $outDir"
            exit 0
        }
    }
}

Write-Host "No compiler found. Install one of:"
Write-Host "  - Visual Studio (Build Tools) with C++ workload, then run from 'Developer Command Prompt'"
Write-Host "  - MinGW-w64 / MSYS2: pacman -S mingw-w64-ucrt-x86_64-gcc"
Write-Host "  - CMake: choco install cmake"
exit 1
