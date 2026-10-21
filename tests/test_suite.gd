## Base des suites de tests. Chaque méthode `test_*` doit finir par `return true` :
## une erreur d'exécution l'interrompt (retour null) et le lanceur la compte en échec.
extends RefCounted

var tmp_dir := ""
var passed := 0
var failed := 0
var current := ""


func _check(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		printerr("ÉCHEC [%s] %s" % [current, label])
