## Lanceur de tests headless sans dépendance externe.
## godot --headless --path . --script res://tests/run_tests.gd
## Code de sortie 0 = tout passe, 1 = au moins un échec.
extends SceneTree

const Database := preload("res://src/persistence/database.gd")
const CareerRepository := preload("res://src/persistence/career_repository.gd")
const Migrations := preload("res://src/persistence/migrations.gd")
const Ids := preload("res://src/core/ids.gd")

var _tmp_dir := ""
var _failures := 0
var _passed := 0
var _current := ""


func _initialize() -> void:
	# Hors du dossier de sauvegarde réel (user://) : un test planté ne pollue pas la vraie save.
	_tmp_dir = OS.get_cache_dir().path_join("ProjectPeloton_tests_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_tmp_dir)
	for t in [
		"test_create_and_read",
		"test_reopen_reads_same_id",
		"test_reopen_migrated_db_is_noop",
		"test_unreachable_path_fails_explicitly",
		"test_newer_schema_is_refused",
		"test_invalid_input_rejected",
		"test_uuid_format",
		"test_multi_migration_backup_and_rollback",
		"test_corrupted_file_rejected",
		"test_find_missing_vs_error",
	]:
		_current = t
		# Chaque test finit par `return true` : une erreur d'exécution l'interrompt et renvoie null.
		if call(t) != true:
			_check(false, "test interrompu par une erreur d'exécution")
	_cleanup()
	print("\n%d vérifications OK, %d échec(s)" % [_passed, _failures])
	quit(1 if _failures > 0 else 0)


func _db_path(name: String) -> String:
	return "%s/%s.db" % [_tmp_dir, name]


func _open_migrated(p: String):
	var db = Database.new()
	_check(db.open(p), "ouverture %s : %s" % [p, db.last_error])
	_check(db.migrate(), "migration : %s" % db.last_error)
	return db


# --- tests -------------------------------------------------------------------

func test_create_and_read() -> bool:
	var db = _open_migrated(_db_path("create"))
	var repo = CareerRepository.new(db)
	var id: String = repo.create("Carrière test", "2027-01-01")
	_check(id != "", "création : %s" % repo.last_error)
	var row: Dictionary = repo.find(id)
	_check(row.get("id") == id, "relecture id")
	_check(row.get("name") == "Carrière test", "relecture nom")
	_check(row.get("game_date") == "2027-01-01", "relecture date")
	_check(row.get("status") == "active", "statut initial")
	_check(repo.find(Ids.new_uuid()).is_empty(), "id inconnu -> vide")
	db.close()
	return true


func test_reopen_reads_same_id() -> bool:
	var p := _db_path("reopen")
	var db = _open_migrated(p)
	var id: String = CareerRepository.new(db).create("Persistance", "2027-02-01")
	db.close()
	var db2 = _open_migrated(p)
	_check(CareerRepository.new(db2).find(id).get("id") == id, "id relu après fermeture/réouverture")
	db2.close()
	return true


func test_reopen_migrated_db_is_noop() -> bool:
	var p := _db_path("noop")
	var db = _open_migrated(p)
	var id: String = CareerRepository.new(db).create("Noop", "2027-03-01")
	db.close()
	for i in 2:
		var again = _open_migrated(p)
		_check(again.schema_version() == Migrations.latest_version(), "version stable")
		_check(again.select("SELECT COUNT(*) AS n FROM career;")[0]["n"] == 1, "données intactes")
		_check(CareerRepository.new(again).find(id).get("name") == "Noop", "carrière intacte")
		again.close()
	var bak := p + ".v1.bak"
	_check(not FileAccess.file_exists(bak), "pas de copie de secours sans migration")
	return true


func test_unreachable_path_fails_explicitly() -> bool:
	var db = Database.new()
	var ok: bool = db.open(_tmp_dir + "/dossier/inexistant/save.db")
	_check(not ok, "ouverture refusée")
	_check(db.last_error.contains("inexistant"), "message explicite : '%s'" % db.last_error)
	_check(not db.is_open(), "base non ouverte")
	_check(not db.migrate() and db.last_error != "", "migrate sans base -> erreur")
	var db2 = Database.new()
	_check(not db2.open(_tmp_dir + "/sans_extension"), "extension .db exigée")
	return true


func test_newer_schema_is_refused() -> bool:
	var p := _db_path("newer")
	var db = _open_migrated(p)
	db.exec("PRAGMA user_version = %d;" % (Migrations.latest_version() + 1))
	db.close()
	var db2 = Database.new()
	db2.open(p)
	_check(not db2.migrate(), "schéma futur refusé")
	_check(db2.last_error.contains("plus récente"), "message : '%s'" % db2.last_error)
	db2.close()
	return true


func test_invalid_input_rejected() -> bool:
	var db = _open_migrated(_db_path("invalid"))
	var repo = CareerRepository.new(db)
	_check(repo.create("   ", "2027-01-01") == "", "nom vide refusé")
	_check(repo.create("X", "2027-02-30") == "", "date impossible refusée")
	_check(repo.create("X", "01/02/2027") == "", "format de date refusé")
	_check(repo.create("X", "2028-02-29") != "", "29 février bissextile accepté")
	_check(repo.create("x".repeat(65), "2027-01-01") == "", "nom > 64 refusé")
	_check(repo.create("a\u0007b", "2027-01-01") == "", "caractère de contrôle refusé")
	_check(not db.exec("INSERT INTO career (id, name, game_date, status, created_at) VALUES ('a','b','2027-01-01','zombie','t');"),
		"statut hors liste refusé par la base")
	db.close()
	return true


func test_uuid_format() -> bool:
	var a := Ids.new_uuid()
	_check(Ids.is_uuid(a), "uuid v4 valide : %s" % a)
	_check(a != Ids.new_uuid(), "uuid uniques")
	return true


func test_multi_migration_backup_and_rollback() -> bool:
	var p := _db_path("multi")
	var db = _open_migrated(p)
	var id: String = CareerRepository.new(db).create("Avant migration", "2027-04-01")
	db.close()
	var v2 := {"version": 2, "name": "add_table", "statements": ["CREATE TABLE extra (x INTEGER);"]}
	var v3_broken := {"version": 3, "name": "broken", "statements": ["CREATE TABLE oops (;"]}
	var db2 = Database.new()
	db2.open(p)
	_check(not db2.migrate([Migrations.ALL[0], v2, v3_broken]), "lot avec migration cassée refusé")
	_check(db2.last_error.contains("annulée") and db2.last_error.contains("v1"), "message exact : '%s'" % db2.last_error)
	_check(db2.schema_version() == 1, "tout ou rien : base restée en v1")
	_check(db2.select("SELECT name FROM sqlite_master WHERE name = 'extra';").is_empty(), "aucune table partielle")
	_check(FileAccess.file_exists(p + ".v1.bak"), "copie de secours créée avant migration")
	_check(db2.migrate([Migrations.ALL[0], v2]), "reprise avec un lot valide : %s" % db2.last_error)
	_check(db2.schema_version() == 2, "base en v2")
	_check(CareerRepository.new(db2).find(id).get("name") == "Avant migration", "données conservées")
	db2.close()
	# La copie doit être une base v1 valide et contenir la carrière.
	var restored := _db_path("restored")
	DirAccess.copy_absolute(p + ".v1.bak", restored)
	var bak = Database.new()
	_check(bak.open(restored), "copie de secours ouvrable : %s" % bak.last_error)
	_check(bak.schema_version() == 1, "copie de secours en v1")
	_check(CareerRepository.new(bak).find(id).get("id") == id, "copie de secours contient la carrière")
	bak.close()
	return true


func test_corrupted_file_rejected() -> bool:
	var p := _db_path("corrupt")
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string("ceci n'est pas une base SQLite, ceci n'est pas une base SQLite, ceci n'est pas une base")
	f.close()
	var db = Database.new()
	_check(not db.open(p), "fichier corrompu refusé à l'ouverture")
	_check(db.last_error.contains("corrompue"), "message explicite : '%s'" % db.last_error)
	_check(not db.is_open(), "base non laissée ouverte")
	return true


func test_find_missing_vs_error() -> bool:
	var db = _open_migrated(_db_path("find"))
	var repo = CareerRepository.new(db)
	db.exec("SELECT * FROM table_inexistante;")
	_check(repo.find(Ids.new_uuid()).is_empty() and repo.last_error == "", "absente après une erreur antérieure -> pas d'erreur")
	db.close()
	_check(repo.find(Ids.new_uuid()).is_empty() and repo.last_error != "", "base fermée -> erreur signalée")
	return true


# --- outillage ---------------------------------------------------------------

func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failures += 1
		printerr("ÉCHEC [%s] %s" % [_current, label])


func _cleanup() -> void:
	var abs := _tmp_dir
	var dir := DirAccess.open(abs)
	if dir == null:
		return
	for f in dir.get_files():
		dir.remove(f)
	DirAccess.remove_absolute(abs)
