## Tests du moteur de course (RACE-001). Aucun test ne charge de scène : la course est headless.
extends "res://tests/test_suite.gd"

const Route := preload("res://src/race/route.gd")
const Physics := preload("res://src/race/physics.gd")
const Rider := preload("res://src/race/rider.gd")
const RaceSim := preload("res://src/race/race_sim.gd")
const PelotonFactory := preload("res://src/race/peloton_factory.gd")

const STAGE_PATH := "res://data/routes/etape_montagne_01.json"


func _route(segments: Array) -> Object:
	return Route.parse({"format_version": 1, "id": "test", "name": "test", "segments": segments})["route"]


## 10 km : 5 km plat puis 5 km à 6 %.
func _short_route() -> Object:
	return _route([
		{"length_m": 5000, "grade_pct": 0.0},
		{"length_m": 5000, "grade_pct": 6.0},
	])


func _solo_rider(id: String) -> Object:
	var r := Rider.new()
	r.id = id
	r.mass_kg = 70.0
	r.cp_w = 300.0
	r.wprime_j = 20000.0
	r.cda_m2 = 0.32
	return r


func _solo_time(route, watts: float) -> float:
	var sim := RaceSim.new()
	var r = _solo_rider("J")
	sim.setup(route, [r], 1)
	sim.set_external_power("J", watts)
	sim.run_to_finish()
	return r.finish_time_s


# --- parcours ------------------------------------------------------------------

func test_route_parse_and_lookup() -> bool:
	var r = _short_route()
	_check(is_equal_approx(r.distance_m, 10000.0), "distance totale")
	_check(r.grade_at(0.0) == 0.0 and r.grade_at(4999.9) == 0.0, "pente du premier segment")
	_check(is_equal_approx(r.grade_at(5000.0), 0.06), "pente au début du second segment")
	_check(is_equal_approx(r.elevation_at(10000.0), 300.0), "dénivelé cumulé 300 m")
	_check(is_equal_approx(r.crr_at(100.0), 0.004), "Crr asphalte par défaut")
	return true


func test_route_rejects_invalid() -> bool:
	var bad := [
		{},
		{"format_version": 2, "id": "x", "segments": [{"length_m": 10}]},
		{"format_version": 1, "id": "x", "segments": []},
		{"format_version": 1, "id": "x", "segments": [{"length_m": -5}]},
		{"format_version": 1, "id": "x", "segments": [{"length_m": 100, "grade_pct": 40}]},
		{"format_version": 1, "id": "x", "segments": [{"length_m": 100, "surface": "glace"}]},
		{"format_version": 1, "id": "x", "segments": [{"length_m": 100}], "sprints": [{"at_m": 500}]},
	]
	for d in bad:
		_check(Route.parse(d).has("error"), "parcours invalide refusé : %s" % str(d))
	return true


func test_stage_file_loads() -> bool:
	var res := Route.load_json(STAGE_PATH)
	_check(res.has("route"), "étape chargée : %s" % res.get("error", ""))
	_check(Route.load_json("res://data/routes/absent.json").has("error"), "fichier absent -> erreur")
	return true


# --- physique ------------------------------------------------------------------

func test_physics_reference_values() -> bool:
	var flat := Physics.steady_speed(250.0, 0.0, 83.0, 0.004, 0.32) * 3.6
	_check(flat > 34.0 and flat < 40.0, "250 W sur le plat : %.1f km/h (34-40)" % flat)
	var climb := Physics.steady_speed(300.0, 0.08, 78.0, 0.004, 0.32) * 3.6
	_check(climb > 13.0 and climb < 18.0, "300 W à 8 %% : %.1f km/h (13-18)" % climb)
	return true


func test_physics_monotonic() -> bool:
	var m := 80.0
	_check(Physics.steady_speed(300.0, 0.0, m, 0.004, 0.32) > Physics.steady_speed(200.0, 0.0, m, 0.004, 0.32), "plus de puissance -> plus vite")
	_check(Physics.steady_speed(250.0, 0.05, m, 0.004, 0.32) < Physics.steady_speed(250.0, 0.0, m, 0.004, 0.32), "plus de pente -> moins vite")
	_check(Physics.resistive_force(12.0, 0.0, m, 0.004, 0.32 * Physics.draft_factor(1.0)) < Physics.resistive_force(12.0, 0.0, m, 0.004, 0.32), "abri -> moins de résistance")
	_check(Physics.draft_factor(1.0) < Physics.draft_factor(3.0) and Physics.draft_factor(3.0) < 1.0, "abri décroît avec l'écart")
	_check(Physics.draft_factor(10.0) == 1.0 and Physics.draft_factor(-1.0) == 1.0, "pas d'abri loin ou en tête")
	return true


func test_wprime_balance() -> bool:
	var w := Physics.next_wbal(20000.0, 400.0, 300.0, 20000.0, 10.0)
	_check(is_equal_approx(w, 19000.0), "au-dessus de CP : -1000 J en 10 s à +100 W")
	var rec := Physics.next_wbal(10000.0, 200.0, 300.0, 20000.0, 10.0)
	_check(rec > 10000.0 and rec < 20000.0, "sous CP : recharge partielle (%.0f J)" % rec)
	_check(Physics.next_wbal(100.0, 1000.0, 300.0, 20000.0, 10.0) == 0.0, "jamais négatif")
	return true


# --- course --------------------------------------------------------------------

func test_classification_of_20_riders() -> bool:
	var sim := RaceSim.new()
	_check(sim.setup(_short_route(), PelotonFactory.build(20, 7), 42) == "", "setup")
	var res: Array = sim.run_to_finish()
	_check(res.size() == 20, "20 classés")
	var ids := {}
	var prev := -1.0
	var ordered := true
	for i in res.size():
		_check(res[i]["rank"] == i + 1 and res[i]["finished"], "rang %d arrivé" % (i + 1))
		ids[res[i]["rider_id"]] = true
		ordered = ordered and res[i]["time_s"] >= prev
		prev = res[i]["time_s"]
	_check(ids.size() == 20, "coureurs uniques")
	_check(ordered, "temps croissants")
	_check(res[0]["gap_s"] == 0.0 and res[19]["gap_s"] > 0.0, "écarts au vainqueur")
	return true


func test_determinism_same_seed() -> bool:
	var a := RaceSim.new()
	a.setup(_short_route(), PelotonFactory.build(20, 7), 42)
	var ra: Array = a.run_to_finish()
	var b := RaceSim.new()
	b.setup(_short_route(), PelotonFactory.build(20, 7), 42)
	var rb: Array = b.run_to_finish()
	var same := true
	for i in ra.size():
		same = same and ra[i]["rider_id"] == rb[i]["rider_id"] and ra[i]["time_s"] == rb[i]["time_s"]
	_check(same, "même graine -> même classement et mêmes temps au bit près")
	var c := RaceSim.new()
	c.setup(_short_route(), PelotonFactory.build(20, 7), 43)
	var rc: Array = c.run_to_finish()
	var differs := false
	for i in ra.size():
		differs = differs or ra[i]["time_s"] != rc[i]["time_s"]
	_check(differs, "graine différente -> résultat différent")
	return true


func test_power_and_grade_effects() -> bool:
	var flat := _route([{"length_m": 5000, "grade_pct": 0.0}])
	var hill := _route([{"length_m": 5000, "grade_pct": 5.0}])
	_check(_solo_time(flat, 300.0) < _solo_time(flat, 200.0), "plus de watts -> plus rapide")
	_check(_solo_time(hill, 250.0) > _solo_time(flat, 250.0), "pente -> plus lent")
	return true


func test_drafting_helps_follower() -> bool:
	# Deux coureurs identiques à puissance égale : le suiveur abrité a besoin de moins de force.
	var route := _route([{"length_m": 3000, "grade_pct": 0.0}])
	var sim := RaceSim.new()
	var lead = _solo_rider("A")
	var follow = _solo_rider("B")
	sim.setup(route, [lead, follow], 1)
	sim.set_external_power("A", 300.0)
	sim.set_external_power("B", 300.0)
	sim.step()
	lead.position_m = 100.0
	follow.position_m = 99.0
	lead.speed_mps = 11.0
	follow.speed_mps = 11.0
	sim.step()
	_check(follow.speed_mps > lead.speed_mps, "le suiveur à 1 m accélère plus que le leader")
	return true


func test_time_step_sensitivity() -> bool:
	var times := []
	for dt in [0.5, 0.25]:
		var sim := RaceSim.new()
		var r = _solo_rider("J")
		sim.setup(_short_route(), [r], 1, {"dt_s": dt})
		sim.set_external_power("J", 280.0)
		sim.run_to_finish()
		times.append(r.finish_time_s)
	var rel: float = absf(times[0] - times[1]) / times[1]
	_check(rel < 0.005, "dt 0,5 s vs 0,25 s : écart %.4f %% (< 0,5 %%)" % (rel * 100.0))
	return true


func test_setup_rejects_invalid() -> bool:
	var sim := RaceSim.new()
	_check(sim.setup(null, PelotonFactory.build(2, 1), 1) != "", "parcours nul refusé")
	_check(sim.setup(_short_route(), [], 1) != "", "aucun coureur refusé")
	var dup := [_solo_rider("X"), _solo_rider("X")]
	_check(sim.setup(_short_route(), dup, 1) != "", "id en double refusé")
	_check(sim.setup(_short_route(), [_solo_rider("Y")], 1, {"dt_s": 5.0}) != "", "pas de temps trop grand refusé")
	_check(sim.setup(_short_route(), [_solo_rider("Z")], 1) == "", "config valide acceptée")
	_check(not sim.set_external_power("Z", -10.0) and not sim.set_external_power("Z", INF), "puissance invalide refusée")
	_check(not sim.set_external_power("inconnu", 200.0), "coureur inconnu refusé")
	return true


func test_full_stage_performance() -> bool:
	var route = Route.load_json(STAGE_PATH)["route"]
	var sim := RaceSim.new()
	sim.setup(route, PelotonFactory.build(20, 2026), 2026)
	var t0 := Time.get_ticks_msec()
	var res: Array = sim.run_to_finish()
	var ms := Time.get_ticks_msec() - t0
	_check(res.size() == 20 and res[19]["finished"], "étape de 76 km bouclée par les 20 coureurs")
	print("  [perf] étape %.0f km, 20 coureurs, dt %.2f s : %d ms, vainqueur %s en %s" % [
		route.distance_m / 1000.0, sim.dt_s, ms, res[0]["name"], _hms(res[0]["time_s"])])
	return true


func _hms(s: float) -> String:
	return "%dh%02d'%02d\"" % [int(s) / 3600, (int(s) % 3600) / 60, int(s) % 60]
