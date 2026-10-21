# Architecture M1 (course, scène témoin, séance sans matériel)

Règles générales : skill `godot-architect`. Ce document fixe les interfaces entre modules pour M1 ; il évolue ticket par ticket.

## Flux

```
TrainerSource ──télémétrie──▶ Session ──puissance joueur──▶ RaceSim ──snapshot──▶ RaceView (3D)
     ▲                          │  ▲                           ▲
     └──consigne ERG/pente──────┘  └──cible──── Workout         └── Route (data/routes/*.json)
```
Seule `Session` connaît plusieurs modules. `RaceSim` ignore le matériel, `RaceView` ne modifie jamais la simulation.

## Modules et interfaces

### race (RACE-001, AI-001)
| Fichier | Rôle | API principale |
|---|---|---|
| `route.gd` | Parcours segmenté validé | `parse(dict)`, `load_json(path)` → `{route}` ou `{error}` ; `grade_at(x)`, `crr_at(x)`, `elevation_at(x)` |
| `physics.gd` | Fonctions pures | `next_speed`, `steady_speed`, `draft_factor`, `next_wbal` |
| `rider.gd` | Paramètres + état d'un coureur | `validate()`, `reset_state()` |
| `peloton_factory.gd` | Peloton fictif déterministe | `build(count, seed)` |
| `race_sim.gd` | Boucle à pas fixe | `setup(route, riders, seed, config)` → erreur ou "" ; `step()` ; `run_to_finish()` ; `snapshot()` ; `results()` ; `set_external_power(id, w)` |

Contrôle de la puissance des IA : allure simple dans RACE-001, remplacée en AI-001 par un « cerveau » par coureur (`decide(rider, contexte) -> puissance cible`), sans changer l'API de `RaceSim`.

### trainer (HW-000, HW-001, HW-002)
`trainer_source.gd` (interface) : états `hardware.states`, `capabilities()`, `latest()` → `{power_w, cadence_rpm, age_ms, stale}`, `request_control()`, `set_erg_target(w)`, `set_simulation(grade, crr, cda)`, `release_control()`. Implémentations : `fake_trainer.gd` (scriptable), puis `gdble_trainer.gd` ou `bridge_trainer.gd` (UDP 127.0.0.1) selon HW-001.

### workout (WORKOUT-001, IMPORT-001)
`workout.gd` : blocs `{type, duration_s, target_start_pct, target_end_pct}` en fraction de FTP ; `target_w_at(t_s, ftp_w)`, `total_duration_s()`. `zwo_import.gd` : sous-ensemble ZWO → `Workout` ou erreur.

### session (SESSION-001)
`session.gd` : machine d'états de `gameplay.erg_timeline.states`, trois horloges (murale, séance, course), `tick(delta_wall_s)`. Écrit les consignes au trainer à 2 Hz maximum.

## Présentation (ART-001)
- `scenes/race/race_view.tscn` : `Node3D` racine. La simulation avance par pas fixes dans `_process` (accumulateur), le rendu interpole entre les deux derniers snapshots.
- La route 3D est générée depuis `Route` (abscisse curviligne → position 3D sur une courbe), pas modélisée à la main.
- Un `RiderVisual` par coureur, réutilisé (pool) ; maillot = texture par équipe.
- Caméra : rig dédié (suivi arrière, roulis léger), séparé de la logique.

## Données
| Dossier | Contenu | Format |
|---|---|---|
| `data/routes/` | Parcours | JSON `format_version: 1`, pentes en `grade_pct`, longueurs en `length_m` |
| `data/workouts/` | Séances internes | JSON (WORKOUT-001) |
| `assets/` | Modèles, textures | glTF 2.0 (`.glb`), licence dans `assets/LICENSES.md` |

## Décisions de M1 à prendre sur mesure
- Pas de simulation (`race_engine.time_step`) : mesuré en RACE-001.
- Transport BLE : GDBLE ou pont local, tranché par HW-001.
