## Peloton fictif déterministe pour les tests et la verticale.
## Valeurs de profils : estimations de niveau professionnel, à calibrer (voir docs/DECISIONS.md).
extends RefCounted

const Rider := preload("res://src/race/rider.gd")

const PROFILES := [
	{"id": "sprinter", "mass_kg": 76.0, "cp_wkg": 4.6, "wprime_j": 28000.0, "cda_m2": 0.33},
	{"id": "classics", "mass_kg": 71.0, "cp_wkg": 5.1, "wprime_j": 22000.0, "cda_m2": 0.32},
	{"id": "climber", "mass_kg": 61.0, "cp_wkg": 5.7, "wprime_j": 16000.0, "cda_m2": 0.31},
	{"id": "rouleur", "mass_kg": 77.0, "cp_wkg": 5.3, "wprime_j": 19000.0, "cda_m2": 0.29},
]
const FIRST_NAMES := ["Luc", "Matteo", "Jonas", "Arno", "Iker", "Tom", "Hugo", "Nils", "Rémi", "Sven"]
const LAST_NAMES := ["Varenne", "Brosset", "Kalden", "Morvan", "Ostrander", "Delcour", "Vianey", "Rask", "Tassin", "Albrecht"]
const MAX_RIDERS := 200
const VARIATION := 0.03  # ±3 % autour du profil


## Renvoie un Array de rider.gd, identifiants "R01".."Rnn", profils en rotation.
static func build(count: int, seed: int) -> Array:
	var out: Array = []
	if count < 1 or count > MAX_RIDERS:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in count:
		var p: Dictionary = PROFILES[i % PROFILES.size()]
		var r := Rider.new()
		r.id = "R%02d" % (i + 1)
		r.name = "%s %s" % [FIRST_NAMES[i % FIRST_NAMES.size()], LAST_NAMES[(i * 7 + i / FIRST_NAMES.size()) % LAST_NAMES.size()]]
		r.profile = p["id"]
		r.mass_kg = p["mass_kg"] * (1.0 + rng.randf_range(-VARIATION, VARIATION))
		r.cp_w = p["cp_wkg"] * r.mass_kg * (1.0 + rng.randf_range(-VARIATION, VARIATION))
		r.wprime_j = p["wprime_j"] * (1.0 + rng.randf_range(-VARIATION, VARIATION))
		r.cda_m2 = p["cda_m2"] * (1.0 + rng.randf_range(-VARIATION, VARIATION))
		out.append(r)
	return out
