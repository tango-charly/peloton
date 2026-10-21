# État du projet

**Ticket actif** : CORE-001 — livré (vérifié sous Linux ; Windows restant à vérifier).
**Prochain ticket** : HW-001 (lever le risque FTMS).

## Acquis vérifiés
- Projet Godot 4.7.2 qui s'importe et démarre en headless ; la scène d'entrée ouvre `user://peloton.db` et migre.
- Migration initiale v1 (`career`) ; rejouée sans effet ni corruption.
- Création/relecture de carrière, réouverture, refus de chemin inaccessible, de version future, de fichier corrompu.
- Migrations multiples atomiques + copie de secours testées avec un lot injecté.
- `tools/check.sh` : 66 vérifications OK.

## Blocages / restes
- Vérification sous Windows : lancer `tools/check.ps1`.
- `docs/SPEC.json` : y déposer la spécification produit (source de vérité pour les tickets).

## Revue CORE-001 (sous-agent, 2026-10-22)
Corrigés : atomicité multi-migrations, faux positifs des tests, tests de backup/rollback, `last_error` résiduel, message sur base corrompue, `busy_timeout`, ROLLBACK vérifié, dossier de tests séparé, typage du dépôt, nom borné (64, sans caractères de contrôle).
