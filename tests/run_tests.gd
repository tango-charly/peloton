## Lanceur de tests headless sans dépendance externe.
## godot --headless --path . --script res://tests/run_tests.gd [-- filtre]
## Code de sortie 0 = tout passe, 1 = au moins un échec.
extends SceneTree

const SUITES: Array[String] = [
	"res://tests/test_persistence.gd",
	"res://tests/test_race.gd",
	"res://tests/test_trainer.gd",
]


func _initialize() -> void:
	# Hors du dossier de sauvegarde réel (user://) : un test planté ne pollue pas la vraie save.
	var tmp := OS.get_cache_dir().path_join("ProjectPeloton_tests_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(tmp)
	var filter: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ""
	var passed := 0
	var failed := 0
	for path in SUITES:
		var script: GDScript = load(path)
		# Une suite qui ne compile pas doit échouer, pas bloquer le lanceur.
		if script == null or not script.can_instantiate():
			printerr("ÉCHEC suite introuvable ou invalide (erreur de compilation ?) : %s" % path)
			failed += 1
			continue
		var suite = script.new()
		suite.tmp_dir = tmp
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_") or (filter != "" and not name.contains(filter)):
				continue
			suite.current = name
			if suite.call(name) != true:
				suite._check(false, "test interrompu par une erreur d'exécution")
		passed += suite.passed
		failed += suite.failed
	_remove_dir(tmp)
	print("\n%d vérifications OK, %d échec(s)" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _remove_dir(abs: String) -> void:
	var dir := DirAccess.open(abs)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	DirAccess.remove_absolute(abs)
