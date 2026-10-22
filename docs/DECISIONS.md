# Décisions

## 2026-10-22 — D02 : Godot 4.7.2 + godot-sqlite v4.7
- **Raison** : dernières versions stables trouvées ; MIT ; aucune royalty ; scènes et scripts en texte (adapté à une IA codeuse) ; tests headless en CLI.
- **Comparaison** : Unity 6 (gratuit < 200 k$ de revenus, éditeur lourd, scènes YAML peu lisibles), Unreal 5 (5 % au-delà de 1 M$, C++/Blueprints, lourd), web/Three.js (Web Bluetooth natif mais pas d'éditeur, Electron pour Steam). Aucun n'est nettement meilleur pour ce projet.
- **Conséquence** : pas de BLE natif dans Godot → HW-001 doit trancher entre une GDExtension BLE (ex. GDBLE, Rust/btleplug, à vérifier sous 4.7 et Windows) et un pont local (Python bleak ou .NET WinRT → UDP 127.0.0.1). Garder `TrainerSource` découplé du moteur.

## 2026-10-22 — Persistance
- Version du schéma dans `PRAGMA user_version`.
- Toutes les migrations manquantes s'appliquent dans **une seule transaction** (tout ou rien).
- Copie `peloton.db.vN.bak` avant toute migration d'une base existante.
- Une sauvegarde en version future est refusée (jamais rétrogradée).
- `PRAGMA quick_check` à l'ouverture : un fichier corrompu est refusé avec un message explicite.
- Colonne `game_date` plutôt que `current_date` (mot réservé SQLite).

## 2026-10-22 — Tests
- Lanceur maison `tests/run_tests.gd` (pas de dépendance GUT/gdUnit pour l'instant). Chaque test finit par `return true`, sinon il compte comme échec.
- Les tests écrivent dans `OS.get_cache_dir()`, jamais dans le dossier de sauvegarde réel.
- `preload` plutôt que `class_name` : les scripts se chargent sans cache de classes globales.

## 2026-10-22 — Moteur de course (RACE-001)
- Pas de simulation : **0,5 s** par défaut (configurable, max 1 s). Écart de temps final < 0,5 % avec 0,25 s ; étape de 76 km à 20 coureurs en ~2 s.
- Intégration Euler explicite, position par moyenne des vitesses ; décisions de tous les coureurs sur l'état t avant intégration (indépendant de l'ordre).
- Estimations à calibrer : rendement de transmission 0,976 ; aspiration -35 % à ≤ 1 m, nulle à 5 m ; Crr par surface ; forme du jour σ = 2 % (bornée ±5 %) ; profils du peloton fictif (W/kg, W', CdA).
- W' : modèle différentiel de Skiba.
- Lanceur de tests : une suite qui ne compile pas compte en échec (avant : blocage) ; `check.sh` borne la durée et ferme l'entrée standard.

## 2026-10-22 — BLE (HW-001)
- GDBLE v0.5.5 retenu en premier (binaire Windows fourni, MIT, chargé sous 4.7.2). Décision définitive après l'essai sur le KICKR CORE ; repli : pont local.
- Décodage FTMS en GDScript pur (`src/trainer/ftms.gd`), indépendant du transport.
- Sonde en lecture seule : aucune écriture sur le point de contrôle avant HW-002.
- Appels de déconnexion via `BluetoothManager.disconnect_device` : `BleDevice.disconnect()` masque `Object.disconnect(signal, callable)`.
