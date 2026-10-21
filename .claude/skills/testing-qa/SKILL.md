---
name: testing-qa
description: Tests et vérification de PROJECT PELOTON. À utiliser pour écrire ou lancer des tests GDScript headless, vérifier les critères d'acceptation d'un ticket, préparer la clôture d'un ticket (definition_of_done), ou diagnostiquer un test en échec. Ne pas utiliser pour concevoir une fonctionnalité.
---

# Tests et QA — PROJECT PELOTON

Références : critères du ticket dans `delivery.backlog`, `definition_of_done.per_ticket` dans `docs/SPEC.json`, format de rapport dans `AGENTS.md`.

## Lancer
- Tout : `GODOT=<exe 4.7.2> tools/check.sh` (Linux) ou `tools/check.ps1` (Windows) : import, tests, démarrage de la scène d'entrée.
- Un sous-ensemble : `"$GODOT" --headless --path . --script res://tests/run_tests.gd -- <filtre>` (filtre sur le nom des tests).
- Ne pas relancer une suite verte sans changement de code.

## Écrire un test
- Une méthode `test_*` par comportement, qui finit par `return true` (sinon le lanceur compte un échec). Vérifications via `_check(cond, "libellé")`.
- Fichiers temporaires uniquement dans `tmp_dir` fourni par le lanceur, jamais dans `user://`.
- Tester le comportement métier et ses erreurs (entrées invalides, échec d'écriture, reprise), pas recopier l'implémentation.
- Données de test construites dans le test (parcours court, 20 coureurs max) ; pas de dépendance à l'heure réelle ni au réseau.
- Une erreur moteur volontairement provoquée (ex. contrainte SQL) est commentée dans le test.

## Clôturer un ticket
1. Cocher chaque critère d'acceptation avec sa preuve (nom du test, commande, sortie).
2. Matériel non testé physiquement : le dire, ce n'est pas une validation.
3. Mettre à jour `docs/PROJECT_STATE.md` en quelques lignes.
4. Optionnel, en fin de ticket et sur demande : lancer l'agent `code-reviewer`, une seule fois, après tests verts.

## Livrable
Rapport de clôture au format `AGENTS.md`, avec les vérifications réellement exécutées et leur résultat.
