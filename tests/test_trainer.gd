## Tests HW-001 : décodage FTMS sur trames construites selon la norme, chargement de GDBLE.
extends "res://tests/test_suite.gd"

const Ftms := preload("res://src/trainer/ftms.gd")


func _bytes(hex: String) -> PackedByteArray:
	return hex.replace(" ", "").hex_decode()


func test_feature_bits() -> bool:
	# Machine : cadence (bit 1) + mesure de puissance (bit 14). Consignes : puissance (bit 3) + simulation (bit 13).
	var f := Ftms.parse_feature(_bytes("02 40 00 00 08 20 00 00"))
	_check(f["machine"]["cadence"] and f["machine"]["power_measurement"], "capacités lues")
	_check(not f["machine"]["inclination"], "capacité absente à false")
	_check(f["target"]["power_target"] and f["target"]["indoor_bike_simulation"], "consignes ERG et simulation lues")
	_check(not f["target"]["resistance_target"], "consigne absente à false")
	_check(Ftms.parse_feature(_bytes("02 40 00")).has("error"), "trame courte refusée")
	return true


func test_indoor_bike_data_speed_cadence_power() -> bool:
	# Flags 0x0044 : vitesse (bit 0 à 0), cadence (bit 2), puissance (bit 6).
	var d := Ftms.parse_indoor_bike_data(_bytes("44 00 B2 0C B4 00 FA 00"))
	_check(is_equal_approx(d["speed_kmh"], 32.5), "vitesse 32,5 km/h")
	_check(is_equal_approx(d["cadence_rpm"], 90.0), "cadence 90 rpm (résolution 0,5)")
	_check(d["power_w"] == 250, "puissance 250 W")
	_check(not d.has("avg_speed_kmh"), "champ absent non inventé")
	return true


func test_indoor_bike_data_more_data_and_signed() -> bool:
	# Flags 0x0041 : bit 0 à 1 (vitesse absente), puissance signée -5 W.
	var d := Ftms.parse_indoor_bike_data(_bytes("41 00 FB FF"))
	_check(not d.has("speed_kmh"), "vitesse absente quand More Data = 1")
	_check(d["power_w"] == -5, "puissance signée")
	# Distance sur 3 octets (bit 4) + fréquence cardiaque (bit 9) + temps écoulé (bit 11).
	var e := Ftms.parse_indoor_bike_data(_bytes("11 0A 10 27 00 8C 3C 00"))
	_check(e["distance_m"] == 10000, "distance uint24 : %s" % str(e.get("distance_m")))
	_check(e["heart_rate_bpm"] == 140 and e["elapsed_s"] == 60, "FC et temps écoulé")
	return true


func test_indoor_bike_data_truncated() -> bool:
	_check(Ftms.parse_indoor_bike_data(_bytes("44 00 B2 0C B4")).has("error"), "trame tronquée refusée")
	_check(Ftms.parse_indoor_bike_data(_bytes("44")).has("error"), "trame vide refusée")
	return true


func test_power_range_and_uuid() -> bool:
	var r := Ftms.parse_power_range(_bytes("00 00 D0 07 01 00"))
	_check(r["min_w"] == 0 and r["max_w"] == 2000 and r["step_w"] == 1, "plage 0-2000 W pas 1")
	_check(Ftms.normalize_uuid("2AD2") == Ftms.INDOOR_BIKE_DATA, "UUID court normalisé")
	_check(Ftms.normalize_uuid(" 00001826-0000-1000-8000-00805F9B34FB ") == Ftms.SERVICE, "UUID long normalisé")
	return true


func test_gdble_extension_and_probe_load() -> bool:
	_check(ClassDB.class_exists("BluetoothManager") and ClassDB.class_exists("BleDevice"), "GDBLE chargé (classes enregistrées)")
	var probe: GDScript = load("res://scenes/dev/ble_probe.gd")
	_check(probe != null and probe.can_instantiate(), "script de la sonde compile")
	return true
