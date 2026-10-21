# Compatibilité — versions verrouillées

| Composant | Version | Licence | Source | SHA-256 de l'archive |
|---|---|---|---|---|
| Godot Engine | 4.7.2-stable (`4.7.2.stable.official.ed1daf0bf`) | MIT | github.com/godotengine/godot/releases/tag/4.7.2-stable | Linux x86_64 zip : `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4` |
| godot-sqlite (2shady4u) | v4.7 (`compatibility_minimum = 4.5`) | MIT (en-tête du code de l'addon) | github.com/2shady4u/godot-sqlite/releases/tag/v4.7 | demo.zip : `26966044757cf86a223a8027f8bc88c49c289ab047dcf8138bb591d7632e580e` |
| SQLite (embarqué dans godot-sqlite) | celle de godot-sqlite v4.7 | Domaine public | sqlite.org | — |

Binaires de l'addon embarqués : Windows x86_64 et Linux x86_64 (debug + release). Les autres plateformes ont été retirées du `.gdextension`.
Les DLL Windows ne dépendent que de KERNEL32 et de l'UCRT (présents sur Windows 10/11).

## Vérifié
- Linux x86_64, Godot 4.7.2 headless : import, 66 vérifications de tests, démarrage de la scène d'entrée.

## Non vérifié
- Exécution sous Windows (à faire avec `tools/check.ps1`).
- Export Windows hors éditeur (ticket QA-001).

## Matériel testé
Aucun (HW-001).
