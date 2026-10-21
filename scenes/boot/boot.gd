## Point d'entrée : ouvre la sauvegarde, applique les migrations, affiche l'état.
extends Control

const Database := preload("res://src/persistence/database.gd")
const SAVE_PATH := "user://peloton.db"

@onready var _status: Label = $Status

var _db := Database.new()


func _ready() -> void:
	var msg: String
	if _db.open(SAVE_PATH) and _db.migrate():
		msg = "PROJECT PELOTON — socle OK (schéma v%d)" % _db.schema_version()
		print("[boot] ", msg)
	else:
		msg = "Erreur de sauvegarde : %s" % _db.last_error
		push_error("[boot] " + msg)
	_status.text = msg


func _exit_tree() -> void:
	_db.close()
