# Guide de style — stylisé soigné

Décision : `art_direction` dans `docs/SPEC.json` (rev. 2). Références : Zwift (semi-stylisé propre), démo NCT Cycling (plancher à dépasser).

## Principes
1. **Formes simples, finition propre** : peu de polygones mais silhouettes nettes, normales lissées sur les objets organiques, arêtes vives sur le bâti.
2. **Le coureur est la star** : c'est lui qu'on regarde 90 % du temps. Le décor accompagne, il ne rivalise pas.
3. **La lumière fait l'ambiance** : heure du jour, ombres douces, brouillard de distance plutôt que du détail.
4. **Lisibilité avant tout** : équipes reconnaissables de loin, HUD lisible depuis le home trainer.

## Palette (valeurs de départ, à ajuster sur la scène témoin)
| Rôle | Couleur | Note |
|---|---|---|
| Asphalte | `#3B3F45` | légèrement bleuté, jamais noir pur |
| Marquage | `#E9E6DC` | |
| Herbe / prés | `#6FA84A` → `#8DBF5A` | deux tons, variation par zone |
| Feuillage | `#4E8A3C` → `#79B04F` | |
| Roche / montagne | `#8E8A82` | |
| Ciel jour | `#9CC9EE` → `#E6F1F8` | dégradé vers l'horizon |
| Bâti | murs `#E8DCC4` / `#C9714B`, toits `#5A4A44` | inspiration village alpin fictif |
| Équipes | teintes saturées et contrastées entre elles | jamais proches du vert ou du gris du décor |

## Lumière et environnement (Godot 4.7, renderer Forward+)
- `DirectionalLight3D` : ombres activées, angle soleil 35-50° le jour, couleur légèrement chaude (`#FFF1DC`).
- `WorldEnvironment` : ciel procédural (`ProceduralSkyMaterial`), tonemap `ACES` ou `AgX`, SSAO léger, glow faible.
- Brouillard de distance activé, teinte du ciel à l'horizon : il masque la fin du décor et donne de la profondeur.
- Préréglages à créer : matin, midi, fin d'après-midi (un fichier `Environment` chacun sous `assets/env/`).

## Caméra
- Plan principal : derrière le coureur à 4-6 m, 1,8-2,2 m de haut, focale ~60° ; léger roulis dans les virages et petit tremblement proportionnel à la vitesse.
- Plans additionnels (après validation) : trois-quarts avant en montée, latéral au sprint.

## Coureur et vélo
- Proportions humaines crédibles, stylisées sans caricature (pas de grosse tête).
- Animation : un cycle de pédalage en boucle, vitesse liée à la cadence (rpm/60 cycles par seconde) ; danseuse en option plus tard.
- Maillot, cuissard, casque : une texture par équipe sur un modèle unique (atlas ou matériau par équipe).

## Budgets
| Élément | LOD0 | LOD éloigné | Textures |
|---|---|---|---|
| Coureur + vélo | 8 000 à 15 000 triangles | 1 500 à 3 000 | 1024², 2048² maximum |
| Arbre | 300 à 1 500 | imposteur ou 100 | atlas partagé |
| Maison | 500 à 3 000 | 200 | atlas partagé |
| Portion de route (1 km) | générée depuis `Route` | — | asphalte en texture répétée |

Peloton de 20 coureurs : 60 fps visés sur la configuration de référence (D05, à fixer).

## Plans de référence pour la validation (ART-001)
1. Plat, caméra principale, peloton groupé devant.
2. Montée à 8 %, caméra principale, coureur seul.
3. Arrêt sur image, HUD visible, capture depuis 2 m de l'écran.

## Assets de la scène témoin
| Asset | Source envisagée | Statut |
|---|---|---|
| Arbres, rochers, herbe | Packs CC0 (Kenney, Quaternius) | à sélectionner |
| Maisons de village | Pack CC0 ou modélisation simple | à sélectionner |
| Coureur + vélo riggés | Provisoire généré par script Blender ; définitif acheté ou commandé (D08) | à produire |
| Animation de pédalage | Sur le modèle définitif ; provisoire procédurale | à produire |
| Maillots | Textures générées, équipes fictives | à produire |
