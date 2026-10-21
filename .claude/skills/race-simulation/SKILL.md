---
name: race-simulation
description: Moteur de course de PROJECT PELOTON. À utiliser pour la boucle de simulation (pas de temps, état des coureurs, classements), l'IA tactique déterministe (suivre, attaquer, chasser, sprinter, protéger le leader), le parcours segmenté, la simulation rapide, ou le mapping séance/course et les transitions accélérées en ERG (gameplay.erg_timeline). Pour les formules physiques, utiliser aussi cycling-physics.
---

# Simulation de course — PROJECT PELOTON

Références : `race_engine` et `gameplay.erg_timeline` dans `docs/SPEC.json` ; code sous `src/race/` et `src/session/`.

## Invariants (à tester, pas seulement à respecter)
- Headless : aucune dépendance aux scènes ; la 3D lit l'état, ne le modifie pas.
- Déterminisme pour une graine et une version : `RandomNumberGenerator` seedé et enregistré, une seule source d'aléa, itérations sur des `Array` triés avec départage par `id` (jamais l'ordre d'un `Dictionary`), aucune lecture d'horloge murale dans la logique.
- Même modèle physique et mêmes limites d'énergie pour IA et joueur.
- En ERG : la cible suit la séance, jamais la course ; une transition accélérée n'avance aucun bloc de séance (`erg_timeline.invariants`).

## Procédures

### Modifier la boucle ou l'IA
1. Écrire d'abord le scénario de test (parcours court construit dans le test, 20 coureurs ou moins).
2. Une décision IA = règle explicable ; journal de debug activable, désactivé par défaut.
3. Vérifier : classement complet et rangs uniques, deux exécutions même graine identiques au bit près, graine différente → résultat différent.

### Pas de temps et performance
Comparer dt et dt/2 (écart de temps final < 0,5 %), mesurer la durée d'une étape complète à 20 coureurs et l'écrire dans `docs/PROJECT_STATE.md`. Ne pas augmenter le nombre de coureurs sans mesure (`race_engine.performance`).

### Transitions ERG accélérées
Construire les fenêtres de course avant lancement ; tester qu'une séance de référence conserve la durée de chaque bloc, y compris pause et perte de connexion.

## Livrables
Code `src/race/` ou `src/session/`, tests de scénario et de déterminisme, mesure de performance consignée.
