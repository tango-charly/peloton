## Dépôt des carrières. Retourne des Dictionary simples ; aucune dépendance aux scènes.
extends RefCounted

const Ids := preload("res://src/core/ids.gd")
const Database := preload("res://src/persistence/database.gd")

const STATUSES := ["active", "retired"]
const NAME_MAX_LENGTH := 64

var _db: Database
var last_error: String = ""


func _init(database: Database) -> void:
	_db = database


## Crée une carrière et renvoie son identifiant, ou "" en cas d'erreur (voir last_error).
func create(name: String, game_date: String) -> String:
	last_error = ""
	var clean := name.strip_edges()
	if clean.is_empty() or clean.length() > NAME_MAX_LENGTH:
		last_error = "nom de carrière vide ou trop long (%d caractères max)" % NAME_MAX_LENGTH
		return ""
	if RegEx.create_from_string("[\\x00-\\x1f\\x7f]").search(clean) != null:
		last_error = "nom de carrière avec caractère de contrôle"
		return ""
	if not is_iso_date(game_date):
		last_error = "date de jeu invalide (AAAA-MM-JJ attendu) : %s" % game_date
		return ""
	var id := Ids.new_uuid()
	var created_at := Time.get_datetime_string_from_system(true) + "Z"
	if not _db.exec(
		"INSERT INTO career (id, name, game_date, status, created_at) VALUES (?, ?, ?, 'active', ?);",
		[id, clean, game_date, created_at]
	):
		last_error = _db.last_error
		return ""
	return id


## Renvoie la carrière ou un Dictionary vide. Vide + last_error "" = absente ; vide + last_error = erreur.
func find(id: String) -> Dictionary:
	last_error = ""
	var rows: Array = _db.select(
		"SELECT id, name, game_date, status, created_at FROM career WHERE id = ?;", [id]
	)
	if rows.is_empty():
		last_error = _db.last_error
		return {}
	return rows[0]


static func is_iso_date(value: String) -> bool:
	var re := RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}$")
	if re.search(value) == null:
		return false
	var parts := value.split("-")
	var m := int(parts[1])
	var d := int(parts[2])
	if m < 1 or m > 12 or d < 1:
		return false
	var days := [31, 29 if _is_leap(int(parts[0])) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	return d <= days[m - 1]


static func _is_leap(y: int) -> bool:
	return (y % 4 == 0 and y % 100 != 0) or y % 400 == 0
