# État du projet

**Ticket actif** : RACE-001 — en pause (travail commencé dans `git stash` : « RACE-001 en cours »).
**Fait** : CORE-001 (vérifié sous Linux ; Windows restant à vérifier). Spec rev. 2. Organisation Claude Code (`CLAUDE.md`, `.claude/skills/`, agent `code-reviewer`).
**Ensuite** : reprendre RACE-001 (`git stash pop`), puis ART-001. HW-001 en parallèle dès que le modèle de trainer est connu.

## Acquis vérifiés
- Projet Godot 4.7.2 qui s'importe et démarre en headless ; la scène d'entrée ouvre `user://peloton.db` et migre.
- Migration initiale v1 (`career`) ; rejouée sans effet ni corruption.
- Création/relecture de carrière, réouverture, refus de chemin inaccessible, de version future, de fichier corrompu.
- Migrations multiples atomiques + copie de secours testées avec un lot injecté.
- `tools/check.sh` : 66 vérifications OK. Lanceur de tests par suites (`tests/test_*.gd`), filtre `-- <nom>`.

## Blocages / restes
- Vérification sous Windows : lancer `tools/check.ps1`.

## Revue CORE-001 (sous-agent, 2026-10-22)
Corrigés : atomicité multi-migrations, faux positifs des tests, tests de backup/rollback, `last_error` résiduel, message sur base corrompue, `busy_timeout`, ROLLBACK vérifié, dossier de tests séparé, typage du dépôt, nom borné (64, sans caractères de contrôle).
