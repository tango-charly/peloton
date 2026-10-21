## Accès SQLite : ouverture, migrations atomiques, sauvegarde avant migration.
## Aucune dépendance aux scènes. Toutes les erreurs sont renvoyées, jamais avalées.
extends RefCounted

const Migrations := preload("res://src/persistence/migrations.gd")
const BUSY_TIMEOUT_MS := 2000

var path: String = ""
var last_error: String = ""
var _db: SQLite = null


## Ouvre (et crée si besoin) la base. `db_path` doit finir par .db ("user://..." ou chemin absolu).
func open(db_path: String) -> bool:
	last_error = ""
	if _db != null:
		return _fail("base déjà ouverte : %s" % path)
	if not db_path.ends_with(".db"):
		return _fail("chemin de base invalide (extension .db attendue) : %s" % db_path)
	var dir := ProjectSettings.globalize_path(db_path).get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		return _fail("dossier inexistant ou inaccessible : %s" % dir)
	var db := SQLite.new()
	db.path = db_path
	db.verbosity_level = SQLite.QUIET
	if not db.open_db():
		return _fail("ouverture impossible (%s) : %s" % [db_path, db.error_message])
	_db = db
	path = db_path
	# quick_check détecte aussi un fichier qui n'est pas une base SQLite.
	var checks := select("PRAGMA quick_check;")
	if checks.is_empty() or str(checks[0].values()[0]) != "ok":
		var cause := last_error if last_error != "" else str(checks)
		close()
		return _fail("sauvegarde illisible ou corrompue (%s) : %s" % [db_path, cause])
	if not (exec("PRAGMA foreign_keys = ON;") and exec("PRAGMA busy_timeout = %d;" % BUSY_TIMEOUT_MS)):
		var err := last_error
		close()
		return _fail(err)
	return true


func close() -> void:
	if _db != null:
		_db.close_db()
	_db = null


func is_open() -> bool:
	return _db != null


func schema_version() -> int:
	var rows := select("PRAGMA user_version;")
	if rows.is_empty():
		return -1
	return int(rows[0].get("user_version", -1))


## Applique les migrations manquantes dans UNE seule transaction (tout ou rien). Idempotent.
## Copie de secours si une base existante (version > 0) est migrée.
## `migrations` est injectable pour les tests ; par défaut la liste du jeu.
func migrate(migrations: Array = Migrations.ALL) -> bool:
	if not _require_open():
		return false
	var current := schema_version()
	if current < 0:
		return _fail("lecture de la version de schéma impossible : %s" % last_error)
	var target: int = migrations[migrations.size() - 1]["version"]
	if current > target:
		return _fail("sauvegarde en version %d, plus récente que le jeu (%d)" % [current, target])
	if current == target:
		return true
	var backup := ""
	if current > 0:
		backup = _backup(current)
		if backup == "":
			return false
	if not exec("BEGIN IMMEDIATE;"):
		return _fail("migration v%d -> v%d impossible à démarrer : %s" % [current, target, last_error])
	for m in migrations:
		if m["version"] <= current:
			continue
		var ok := true
		for sql in m["statements"]:
			if not exec(sql):
				ok = false
				break
		if ok:
			ok = exec("PRAGMA user_version = %d;" % m["version"])
		if not ok:
			return _abort_migration("migration %d (%s) échouée : %s" % [m["version"], m["name"], last_error], current, backup)
	if not exec("COMMIT;"):
		return _abort_migration("validation des migrations échouée : %s" % last_error, current, backup)
	return true


func exec(sql: String, bindings: Array = []) -> bool:
	if not _require_open():
		return false
	last_error = ""
	var ok: bool = _db.query_with_bindings(sql, bindings) if not bindings.is_empty() else _db.query(sql)
	if not ok:
		return _fail("SQL : %s" % _db.error_message)
	return true


## Retourne les lignes (Array de Dictionary) ; tableau vide si aucune ligne OU erreur :
## distinguer par last_error (vide = pas d'erreur).
func select(sql: String, bindings: Array = []) -> Array:
	if not exec(sql, bindings):
		return []
	return _db.query_result.duplicate(true)


## Annule la transaction en cours. Si l'annulation échoue, ferme la base pour ne pas
## laisser une connexion dans une transaction fantôme.
func _abort_migration(msg: String, kept_version: int, backup: String) -> bool:
	if not _db.query("ROLLBACK;"):
		var rb := _db.error_message
		close()
		return _fail("%s ; ROLLBACK échoué (%s), base fermée. Copie de secours : %s" % [msg, rb, backup if backup != "" else "aucune"])
	var suffix := " Copie de secours : %s" % backup if backup != "" else ""
	return _fail("%s ; annulée, base restée en v%d.%s" % [msg, kept_version, suffix])


## Copie le fichier de base avant migration. Renvoie le chemin de la copie ou "" en cas d'échec.
func _backup(version: int) -> String:
	var src := ProjectSettings.globalize_path(path)
	var dst := "%s.v%d.bak" % [src, version]
	var err := DirAccess.copy_absolute(src, dst)
	if err != OK:
		_fail("copie de secours impossible avant migration (%s) : erreur %d" % [dst, err])
		return ""
	return dst


func _require_open() -> bool:
	if _db == null:
		return _fail("base non ouverte")
	return true


func _fail(msg: String) -> bool:
	last_error = msg
	return false
