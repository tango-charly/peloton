## Simulation de course à pas fixe, headless et déterministe pour une graine et une version données.
## Ordre de calcul : décisions de tous les coureurs sur l'état t, puis intégration (aucune dépendance à l'ordre).
extends RefCounted

const Physics := preload("res://src/race/physics.gd")

const DEFAULT_DT_S := 0.5
const MAX_DT_S := 1.0
const DEFAULT_MAX_TIME_S := 12.0 * 3600.0
const MAX_RIDERS := 200
const FORM_SIGMA := 0.02  # écart-type de la forme du jour (estimation)
const FORM_MAX_DEVIATION := 0.05

var route = null  # route.gd
var riders: Array = []  # rider.gd, triés par id
var seed: int = 0
var dt_s: float = DEFAULT_DT_S
var max_time_s: float = DEFAULT_MAX_TIME_S
var time_s: float = 0.0
var finished_count: int = 0

var _external_w := {}  # id -> watts


## Prépare la course. Renvoie "" si valide, sinon le message d'erreur.
func setup(p_route, p_riders: Array, p_seed: int, config: Dictionary = {}) -> String:
	if p_route == null or p_route.distance_m <= 0.0:
		return "parcours invalide"
	if p_riders.is_empty() or p_riders.size() > MAX_RIDERS:
		return "nombre de coureurs invalide (%d, 1 à %d)" % [p_riders.size(), MAX_RIDERS]
	var ids := {}
	for r in p_riders:
		var err: String = r.validate()
		if err != "":
			return err
		if ids.has(r.id):
			return "identifiant de coureur en double : %s" % r.id
		ids[r.id] = true
	dt_s = float(config.get("dt_s", DEFAULT_DT_S))
	if not is_finite(dt_s) or dt_s <= 0.0 or dt_s > MAX_DT_S:
		return "pas de temps invalide (%s s, 0 < dt <= %s)" % [dt_s, MAX_DT_S]
	max_time_s = float(config.get("max_time_s", DEFAULT_MAX_TIME_S))
	route = p_route
	seed = p_seed
	riders = p_riders.duplicate()
	riders.sort_custom(func(a, b): return a.id < b.id)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for r in riders:
		r.reset_state()
		var f := 1.0 + rng.randfn(0.0, FORM_SIGMA)
		r.form = clampf(f, 1.0 - FORM_MAX_DEVIATION, 1.0 + FORM_MAX_DEVIATION)
	time_s = 0.0
	finished_count = 0
	_external_w.clear()
	return ""


## Puissance imposée de l'extérieur (joueur, test). Renvoie false si refusée.
func set_external_power(rider_id: String, watts: float) -> bool:
	if not is_finite(watts) or watts < 0.0 or watts > 3000.0:
		return false
	for r in riders:
		if r.id == rider_id:
			r.external_power = true
			_external_w[rider_id] = watts
			return true
	return false


func is_finished() -> bool:
	return finished_count == riders.size() or time_s >= max_time_s


func step() -> void:
	if is_finished():
		return
	# 1. Ordre sur la route (position décroissante, départage par id) et écart à la roue de devant.
	var active: Array = riders.filter(func(r): return not r.is_finished())
	active.sort_custom(func(a, b): return a.position_m > b.position_m or (a.position_m == b.position_m and a.id < b.id))
	for k in active.size():
		active[k].draft_gap_m = -1.0 if k == 0 else active[k - 1].position_m - active[k].position_m
	# 2. Décisions sur l'état t.
	for r in active:
		r.power_w = _external_w[r.id] if r.external_power else _pace(r, route.grade_at(r.position_m))
	# 3. Intégration.
	for r in active:
		var grade: float = route.grade_at(r.position_m)
		var cda: float = r.cda_m2 * Physics.draft_factor(r.draft_gap_m)
		var v0: float = r.speed_mps
		var v1 := Physics.next_speed(v0, r.power_w, grade, r.total_mass_kg(), route.crr_at(r.position_m), cda, dt_s)
		var x0: float = r.position_m
		var x1 := x0 + 0.5 * (v0 + v1) * dt_s
		r.wbal_j = Physics.next_wbal(r.wbal_j, r.power_w, r.cp_w, r.wprime_j, dt_s)
		r.speed_mps = v1
		if x1 >= route.distance_m:
			var frac: float = (route.distance_m - x0) / maxf(x1 - x0, 1e-9)
			r.finish_time_s = time_s + frac * dt_s
			r.position_m = route.distance_m
			finished_count += 1
		else:
			r.position_m = x1
	time_s += dt_s


func run_to_finish() -> Array:
	while not is_finished():
		step()
	return results()


## Classement : arrivés par temps (départage id), puis non-arrivés par position.
func results() -> Array:
	var sorted: Array = riders.duplicate()
	sorted.sort_custom(func(a, b):
		if a.is_finished() != b.is_finished():
			return a.is_finished()
		if a.is_finished():
			return a.finish_time_s < b.finish_time_s or (a.finish_time_s == b.finish_time_s and a.id < b.id)
		return a.position_m > b.position_m or (a.position_m == b.position_m and a.id < b.id))
	var out: Array = []
	var best: float = sorted[0].finish_time_s if sorted[0].is_finished() else -1.0
	for i in sorted.size():
		var r = sorted[i]
		out.append({
			"rank": i + 1,
			"rider_id": r.id,
			"name": r.name,
			"finished": r.is_finished(),
			"time_s": r.finish_time_s,
			"gap_s": r.finish_time_s - best if r.is_finished() and best >= 0.0 else -1.0,
			"distance_m": r.position_m,
		})
	return out


## État lisible par la présentation (copie, triée par id).
func snapshot() -> Array:
	var out: Array = []
	for r in riders:
		out.append({"id": r.id, "position_m": r.position_m, "speed_mps": r.speed_mps,
			"power_w": r.power_w, "wbal_j": r.wbal_j, "finished": r.is_finished()})
	return out


## Allure de base des IA (remplacée par les tactiques d'AI-001). Fraction de CP selon la pente.
func _pace(r, grade: float) -> float:
	var intensity: float
	if grade >= 0.03:
		intensity = 0.90 + minf(grade - 0.03, 0.05)
	elif grade > -0.01:
		intensity = 0.72
	else:
		intensity = maxf(0.72 - (-0.01 - grade) * 10.0, 0.15)
	var target: float = r.cp_w * r.form * intensity
	if target > r.cp_w and r.wbal_j < 0.25 * r.wprime_j:
		target = r.cp_w
	return target
