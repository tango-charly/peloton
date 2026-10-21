# Consignes pour l'IA codeuse

1. Lire `docs/PROJECT_STATE.md` d'abord, puis le ticket actif dans `docs/SPEC.json` (`delivery.backlog`) par lecture ciblée (`jq` ou Grep), ses dépendances et les seuls fichiers concernés.
2. Un ticket à la fois. Pas de refactorisation hors ticket. Pas de nouvelle dépendance, service payant ou cloud sans accord.
3. Ne pas modifier `docs/SPEC.json` sans validation du propriétaire.
4. Pas d'agents en parallèle ni de sous-agent sans demande explicite.
5. Logique métier dans `src/` sans dépendance aux scènes ni au Bluetooth concret.
6. Migrations : ne jamais modifier une migration publiée, en ajouter une à la fin de `src/persistence/migrations.gd`.
7. Vérifier avant de déclarer fini : `GODOT=... tools/check.sh` (Linux) ou `tools/check.ps1` (Windows).
8. À la fin : mettre à jour `docs/PROJECT_STATE.md` (court), consigner une décision durable une seule fois dans `docs/DECISIONS.md`, versions/licences dans `docs/COMPATIBILITY.md`.
9. Rapport : ticket, comportement obtenu, fichiers modifiés, vérifications réellement exécutées, limites, prochain ticket.
