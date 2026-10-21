---
name: godot-architect
description: Architecture Godot 4.7 / GDScript de PROJECT PELOTON. À utiliser avant de créer un module, un script, une scène, une interface (TrainerSource, dépôt), une migration SQLite, d'ajouter un plugin/GDExtension, ou de toucher project.godot ou l'export Windows. Ne pas utiliser pour la physique, la course ou la carrière elles-mêmes.
---

# Architecte Godot — PROJECT PELOTON

Références : `architecture` et `hardware.adapter_contract` dans `docs/SPEC.json`, versions dans `docs/COMPATIBILITY.md`, décisions dans `docs/DECISIONS.md`.

## Règles de structure
- Logique métier dans `src/<module>/` (`architecture.modules`) : `extends RefCounted`, aucune référence à `Node`, scène, `Input` ou API Bluetooth concrète.
- Dépendances entre scripts par `const X := preload("res://...")`, pas `class_name` (chargement sans cache de classes global, voir DECISIONS).
- Présentation (`scenes/`, `ui/`) appelle `src/`, jamais l'inverse. Communication remontante par signaux ou valeurs de retour.
- Erreurs : retour explicite (`bool` + `last_error`, ou `{"error": ...}`), jamais avalées ; `push_error` seulement en présentation.
- Unités dans les noms (`_m`, `_s`, `_w`, `_kg`, `_j`, `_mps`, `_pct`).
- Contenu statique en JSON versionné (`format_version`) sous `data/`, validé et borné au chargement.

## Procédures

### Nouveau module ou interface
1. Vérifier qu'aucun module existant ne couvre le besoin (Grep dans `src/`).
2. Définir l'interface minimale du ticket, pas celle du jeu final.
3. Créer seulement les fichiers utilisés par le ticket (pas de squelettes vides).

### Migration SQLite
1. Ajouter une entrée à la fin de `src/persistence/migrations.gd` (`version` = dernière + 1). Ne jamais modifier une migration publiée.
2. Éviter les mots réservés SQLite comme noms de colonnes ; contraintes `CHECK` / `FOREIGN KEY` côté base.
3. Ajouter un test de migration depuis la version précédente (base peuplée → données conservées).

### Plugin / GDExtension / montée de version
1. Vérifier la source officielle, la licence et la compatibilité `compatibility_minimum` avec 4.7.2.
2. N'embarquer que les binaires Windows/Linux x86_64.
3. Consigner version, licence, SHA-256 dans `docs/COMPATIBILITY.md` et la raison dans `docs/DECISIONS.md`. Accord du propriétaire requis.

## Livrables
Fichiers créés/modifiés, interface exposée (signatures), décision consignée si durable.

## Critères de qualité
- `tools/check.sh` (ou `.ps1`) vert, démarrage headless sans nouvelle erreur.
- Aucun nouveau fichier hors de `architecture.suggested_layout` sans justification.
