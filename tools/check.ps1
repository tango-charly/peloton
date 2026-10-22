# Vérification CORE-001 sous Windows. Usage : $env:GODOT="C:\chemin\Godot_v4.7.2-stable_win64_console.exe"; .\tools\check.ps1
$ErrorActionPreference = "Stop"
if (-not $env:GODOT) { throw "Définir GODOT vers Godot_v4.7.2-stable_win64_console.exe" }
$root = Split-Path $PSScriptRoot -Parent
& $env:GODOT --headless --path $root --import | Out-Null
if (-not (Test-Path "$root\.godot\extension_list.cfg")) { throw "Import Godot incomplet" }
& $env:GODOT --headless --path $root --script res://tests/run_tests.gd
if ($LASTEXITCODE -ne 0) { throw "Tests en échec ($LASTEXITCODE)" }
& $env:GODOT --headless --path $root --quit-after 30
