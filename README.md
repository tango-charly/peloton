# PROJECT PELOTON

Jeu solo de carrière cycliste piloté au home trainer (Godot 4.7.2 · GDScript · SQLite).

## Démarrer
1. Installer Godot **4.7.2-stable** (version verrouillée, voir `docs/COMPATIBILITY.md`).
2. Ouvrir `project.godot` dans l'éditeur, puis F5. La scène affiche « socle OK (schéma v1) ».

## Vérifier
- Windows : `$env:GODOT="C:\...\Godot_v4.7.2-stable_win64_console.exe"; .\tools\check.ps1`
- Linux : `GODOT=/chemin/Godot_v4.7.2-stable_linux.x86_64 tools/check.sh`

La sauvegarde est dans le dossier utilisateur Godot `ProjectPeloton` (Windows : `%APPDATA%\ProjectPeloton\peloton.db`).

## Arborescence
- `src/core` : identifiants · `src/persistence` : SQLite, migrations, dépôts
- `scenes/boot` : point d'entrée · `tests` : tests headless · `docs` : état, décisions, compatibilité
