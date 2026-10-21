## Coureur : paramètres physiques (constants pendant la course) + état de course.
## cp_w : puissance critique, assimilée à la FTP pour le moteur (W). wprime_j : réserve anaérobie (J).
extends RefCounted

const BIKE_MASS_KG := 8.0

# Paramètres
var id: String = ""
var name: String = ""
var profile: String = ""
var mass_kg: float = 70.0
var cp_w: float = 300.0
var wprime_j: float = 20000.0
var cda_m2: float = 0.32
var form: float = 1.0  # forme du jour (multiplicateur), tirée de la graine
var external_power: bool = false  # puissance fournie de l'extérieur (joueur, test)

# État
var position_m: float = 0.0
var speed_mps: float = 0.0
var power_w: float = 0.0
var wbal_j: float = 0.0
var draft_gap_m: float = -1.0
var finish_time_s: float = -1.0


func total_mass_kg() -> float:
	return mass_kg + BIKE_MASS_KG


func is_finished() -> bool:
	return finish_time_s >= 0.0


func reset_state() -> void:
	position_m = 0.0
	speed_mps = 0.0
	power_w = 0.0
	wbal_j = wprime_j
	draft_gap_m = -1.0
	finish_time_s = -1.0


## Validation des paramètres : "" si valide, sinon message.
func validate() -> String:
	if id.is_empty():
		return "coureur sans identifiant"
	for v in [mass_kg, cp_w, wprime_j, cda_m2, form]:
		if not is_finite(v) or v <= 0.0:
			return "coureur %s : paramètre physique invalide" % id
	if mass_kg < 35.0 or mass_kg > 150.0:
		return "coureur %s : masse hors bornes (%s kg)" % [id, mass_kg]
	return ""
