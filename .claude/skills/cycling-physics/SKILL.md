---
name: cycling-physics
description: Modèles physiques et physiologiques du cyclisme pour PROJECT PELOTON. À utiliser pour écrire, modifier ou calibrer la relation puissance/vitesse, la pente, le roulement, la traînée, l'aspiration, l'énergie anaérobie (W'/CP), les zones et cibles en % de FTP, ou les consignes ERG/simulation envoyées au trainer. Ne pas utiliser pour les tactiques IA ni la carrière.
---

# Physique cycliste — PROJECT PELOTON

Périmètre fixé par `race_engine.minimum_physics` et `race_engine.anti_scope` dans `docs/SPEC.json`. Code cible : `src/race/physics.gd` (créé par RACE-001), constantes « estimation » commentées sur place.

## Procédure
1. Écrire le modèle en unités SI ; nommer les unités dans les variables.
2. Toute constante non issue d'une mesure est marquée `# estimation` et listée dans `docs/DECISIONS.md` (valeur, source ou raisonnement).
3. Garder des fonctions statiques pures (entrées → sortie), testables sans course.
4. Tester contre des ordres de grandeur connus (tableau ci-dessous), puis la monotonie (plus de puissance → plus vite ; plus de pente → moins vite ; abri → moins de force).
5. Vérifier la stabilité numérique au pas de temps utilisé (comparer dt et dt/2, écart < 0,5 %).

## Valeurs de contrôle (ordres de grandeur, coureur + vélo ≈ 78-83 kg, CdA 0,30-0,33, Crr 0,004)
| Situation | Attendu |
|---|---|
| 250 W, plat | 34-40 km/h |
| 300 W, 8 % | 13-18 km/h |
| Abri à 1 m | traînée réduite d'environ 30-40 % |
| W' typique | 15-30 kJ |

## Règles
- La FTP réelle du joueur sert aux cibles ERG ; elle n'est jamais modifiée par une récompense (`career.progression_policy`).
- Une consigne ERG/pente vers le matériel respecte `hardware.requirements` et `hardware.ftms_notes` : pas de saut brutal, fréquence ≤ 1-2 Hz.
- Pas d'aérodynamique complexe ni de collisions (`anti_scope`).

## Livrables
Fonction(s) pure(s), tests de valeurs de contrôle et de monotonie, constantes documentées.
