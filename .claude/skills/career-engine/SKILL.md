---
name: career-engine
description: Moteur de carrière de PROJECT PELOTON. À utiliser pour le calendrier et la saison, les profils et rôles, la progression physique et de carrière, l'application des résultats, les contrats et transferts, les trophées, archives et la retraite, ainsi que leurs tables et dépôts SQLite. Ne pas utiliser pour la simulation de course elle-même.
---

# Moteur de carrière — PROJECT PELOTON

Références : `career`, `gameplay.season`, `architecture.entities` et `architecture.integrity` dans `docs/SPEC.json`. Persistance : `src/persistence/` (migrations via godot-architect).

## Invariants
- Un seul résultat final persistant par coureur et événement.
- Appliquer un résultat (progression, confiance, trophée) est idempotent : rejouer l'application ne double rien.
- Toute écriture qui change l'état de carrière (résultat + progression + trophée, fin de saison) se fait dans une transaction unique.
- Les récompenses ne modifient jamais la FTP de référence du joueur (`career.progression_policy`).
- Résultat simulé et résultat joué alimentent les mêmes classements.
- En cas d'échec d'écriture, rien n'est présenté comme enregistré (`architecture.failure_policy`).

## Procédure
1. Identifier les entités touchées dans `architecture.entities` ; écart avec la spec → passer par peloton-product-owner.
2. Écrire la règle métier en fonction pure (état + événement → nouvel état), puis le dépôt qui la persiste.
3. Tests obligatoires : application unique, rejeu sans doublon, échec d'écriture au milieu (aucune récompense partielle), relecture après fermeture/réouverture.
4. Paramètres d'équilibrage (gains, seuils) dans `data/` en JSON, pas en dur ; valeurs par défaut de `open_decisions` D06.

## Livrables
Règles pures + dépôt + migration, tests d'idempotence et de transaction, paramètres d'équilibrage en données.
