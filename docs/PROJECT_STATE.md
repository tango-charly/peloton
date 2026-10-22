# État du projet

**Ticket actif** : HW-001 — partie logicielle livrée, attend l'essai sur le KICKR CORE (`tools/ble_probe.ps1`).
**Fait** : CORE-001, spec rev. 2, organisation Claude Code (skills + `code-reviewer`), skill `art-director`, `docs/ARCHITECTURE.md`, `docs/ART_DIRECTION.md`, RACE-001, spec rev. 3 (D03, D08 tranchées, ticket HW-003).

## Plan (priorisation PO, 2026-10-22)
1. HW-001 : GDBLE v0.5.5 intégré et chargé sous 4.7.2, décodage FTMS testé, sonde prête. Reste : essai physique (Windows + KICKR CORE).
2. ART-001 scène témoin (risque R07). Coureur MakeHuman/MPFB + vélo scripté + pédalage IK (D08 : 0 €).
3. HW-000 interface TrainerSource + FakeTrainer.
4. WORKOUT-001, puis AI-001, IMPORT-001, SESSION-001 (fin de M1).
5. M2 : CAREER-001, HW-002, HUB-001.

## Acquis vérifiés
- Projet Godot 4.7.2 qui s'importe et démarre en headless ; la scène d'entrée ouvre `user://peloton.db` et migre.
- Migration initiale v1 (`career`) ; rejouée sans effet ni corruption.
- Création/relecture de carrière, réouverture, refus de chemin inaccessible, de version future, de fichier corrompu.
- Migrations multiples atomiques + copie de secours testées avec un lot injecté.
- RACE-001 : parcours JSON validé, physique (valeurs de contrôle OK), aspiration, W', classement de 20 coureurs, déterminisme au bit près, effets puissance/pente, sensibilité au pas < 0,5 %.
- Étape `etape_montagne_01` (76 km) simulée en ~2 s pour 20 coureurs, pas de 0,5 s (sandbox Linux).
- HW-001 : GDBLE chargé (Linux), décodage FTMS (Feature, Indoor Bike Data, plage de puissance) testé sur trames normées.
- `tools/check.sh` : 149 vérifications OK. Lanceur de tests par suites (`tests/test_*.gd`), filtre `-- <nom>`.

## Blocages / restes
- Limite connue RACE-001 : sans tactique de groupe (AI-001), chaque coureur roule seul ; les rouleurs gagnent même au sommet. Attendu, corrigé par l'état « Suivre » d'AI-001.
- Vérification sous Windows : lancer `tools/check.ps1`.

## Revue CORE-001 (sous-agent, 2026-10-22)
Corrigés : atomicité multi-migrations, faux positifs des tests, tests de backup/rollback, `last_error` résiduel, message sur base corrompue, `busy_timeout`, ROLLBACK vérifié, dossier de tests séparé, typage du dépôt, nom borné (64, sans caractères de contrôle).
