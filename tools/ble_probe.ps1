# Sonde Bluetooth HW-001 (lecture seule, aucune commande envoyée au trainer).
# Usage : $env:GODOT="C:\...\Godot_v4.7.2-stable_win64.exe"; .\tools\ble_probe.ps1
# Avant : fermer Zwift (et toute appli connectée au trainer), pédaler pour réveiller le KICKR.
$ErrorActionPreference = "Stop"
if (-not $env:GODOT) { throw "Définir GODOT vers l'exécutable Godot 4.7.2" }
$root = Split-Path $PSScriptRoot -Parent
& $env:GODOT --path $root --import | Out-Null
& $env:GODOT --path $root res://scenes/dev/ble_probe.tscn
$report = Join-Path $env:APPDATA "ProjectPeloton\ble_probe_report.txt"
if (Test-Path $report) { Write-Host "Rapport : $report"; Get-Content $report | Set-Clipboard; Write-Host "(copié dans le presse-papiers)" }
