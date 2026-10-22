## Sonde Bluetooth HW-001 : lecture seule, n'envoie AUCUNE commande au trainer.
## Scanne, se connecte au premier appareil dont le nom contient TARGET_NAME, liste services et
## caractéristiques, lit les capacités FTMS, enregistre 30 s de télémétrie, puis écrit un rapport.
extends Control

const Ftms := preload("res://src/trainer/ftms.gd")

const TARGET_NAME := "KICKR"
const SCAN_S := 12.0
const STEP_TIMEOUT_S := 25.0
const SAMPLE_S := 30.0
const REPORT_PATH := "user://ble_probe_report.txt"

@onready var _log_label: RichTextLabel = $Log

var _bt  # BluetoothManager (GDExtension GDBLE)
var _dev  # BleDevice
var _address := ""
var _lines: PackedStringArray = []
var _phase := ""
var _phase_started_ms := 0
var _samples := 0
var _last_sample := {}
var _next_print_ms := 0


func _ready() -> void:
	_log("PROJECT PELOTON — sonde BLE (HW-001), lecture seule")
	_log("Moteur %s, OS %s" % [Engine.get_version_info()["string"], OS.get_name()])
	if not ClassDB.class_exists("BluetoothManager"):
		_finish("ÉCHEC : extension GDBLE non chargée (BluetoothManager absent)")
		return
	_bt = ClassDB.instantiate("BluetoothManager")
	add_child(_bt)
	_bt.adapter_initialized.connect(_on_adapter)
	_bt.device_discovered.connect(func(info): _log("  vu : %s  [%s]  %s dBm" % [info.get("name", "?"), info.get("address"), info.get("rssi")]))
	_bt.scan_stopped.connect(_on_scan_stopped)
	_bt.error_occurred.connect(func(e): _log("ERREUR adaptateur : %s" % e))
	_set_phase("init")
	_bt.initialize()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _phase in ["init", "connect", "discover"] and now - _phase_started_ms > STEP_TIMEOUT_S * 1000:
		_finish("ÉCHEC : délai dépassé à l'étape « %s »" % _phase)
	elif _phase == "sample":
		if now >= _next_print_ms and not _last_sample.is_empty():
			_log("  %s" % _fmt_sample(_last_sample))
			_next_print_ms = now + 1000
		if now - _phase_started_ms > SAMPLE_S * 1000:
			_log("Notifications reçues : %d en %d s (%.1f/s)" % [_samples, SAMPLE_S, _samples / SAMPLE_S])
			_dev.unsubscribe_characteristic(Ftms.SERVICE, Ftms.INDOOR_BIKE_DATA)
			_finish("TERMINÉ")


func _on_adapter(ok: bool, err: String) -> void:
	if not ok:
		_finish("ÉCHEC : adaptateur Bluetooth indisponible (%s)" % err)
		return
	_log("Adaptateur OK. Scan %d s… (pédale doucement pour réveiller le trainer)" % SCAN_S)
	_set_phase("scan")
	_bt.start_scan(SCAN_S)


func _on_scan_stopped() -> void:
	if _phase != "scan":
		return
	var target := {}
	for d in _bt.get_discovered_devices():
		if str(d.get("name", "")).to_upper().contains(TARGET_NAME):
			target = d
			break
	if target.is_empty():
		_finish("ÉCHEC : aucun appareil dont le nom contient « %s ». Zwift est-il fermé ?" % TARGET_NAME)
		return
	_address = str(target.get("address"))
	_log("Cible : %s [%s]" % [target.get("name"), _address])
	_dev = _bt.connect_device(target.get("address"))
	if _dev == null:
		_finish("ÉCHEC : connect_device a renvoyé null")
		return
	_dev.connected.connect(_on_connected)
	_dev.connection_failed.connect(func(e): _finish("ÉCHEC connexion : %s" % e))
	_dev.services_discovered.connect(_on_services)
	_dev.characteristic_read.connect(_on_read)
	_dev.characteristic_notified.connect(_on_notified)
	_dev.operation_failed.connect(func(op, e): _log("ERREUR opération %s : %s" % [op, e]))
	_dev.disconnected.connect(func(): _log("Déconnecté."))
	_set_phase("connect")
	_dev.connect_async()


func _on_connected() -> void:
	_log("Connecté. Découverte des services…")
	_set_phase("discover")
	_dev.discover_services()


func _on_services(services: Array) -> void:
	var has_ftms := false
	var has_cps := false
	_log("Services (%d) :" % services.size())
	for s in services:
		var su := Ftms.normalize_uuid(str(s.get("uuid", "")))
		has_ftms = has_ftms or su == Ftms.SERVICE
		has_cps = has_cps or su == Ftms.CYCLING_POWER_SERVICE
		_log("  service %s" % su)
		for c in s.get("characteristics", []):
			var props: Dictionary = c.get("properties", {})
			var flags := []
			for k in ["read", "write", "write_without_response", "notify", "indicate"]:
				if props.get(k, false):
					flags.append(k)
			_log("    car. %s  %s" % [Ftms.normalize_uuid(str(c.get("uuid", ""))), ",".join(flags)])
	_log("FTMS présent : %s ; Cycling Power présent : %s" % ["OUI" if has_ftms else "NON", "OUI" if has_cps else "NON"])
	if not has_ftms:
		_finish("RÉSULTAT : pas de FTMS — prévoir le repli (Cycling Power ou pont local)")
		return
	_dev.read_characteristic(Ftms.SERVICE, Ftms.FEATURE)
	_dev.read_characteristic(Ftms.SERVICE, Ftms.SUPPORTED_POWER_RANGE)
	_dev.subscribe_characteristic(Ftms.SERVICE, Ftms.INDOOR_BIKE_DATA)
	_log("Télémétrie pendant %d s : pédale à allure variable." % SAMPLE_S)
	_set_phase("sample")


func _on_read(char_uuid: String, data: PackedByteArray) -> void:
	var u := Ftms.normalize_uuid(char_uuid)
	if u == Ftms.FEATURE:
		var f := Ftms.parse_feature(data)
		_log("Capacités machine : %s" % _true_keys(f.get("machine", {})))
		_log("Consignes acceptées : %s" % _true_keys(f.get("target", {})))
		_log("  → ERG (power_target) : %s ; simulation (indoor_bike_simulation) : %s" % [
			f.get("target", {}).get("power_target", false), f.get("target", {}).get("indoor_bike_simulation", false)])
	elif u == Ftms.SUPPORTED_POWER_RANGE:
		_log("Plage de puissance : %s" % str(Ftms.parse_power_range(data)))
	_log("  brut %s : %s" % [u.substr(4, 4), data.hex_encode()])


func _on_notified(char_uuid: String, data: PackedByteArray) -> void:
	if Ftms.normalize_uuid(char_uuid) != Ftms.INDOOR_BIKE_DATA:
		return
	_samples += 1
	_last_sample = Ftms.parse_indoor_bike_data(data)
	_last_sample["raw"] = data.hex_encode()


func _fmt_sample(s: Dictionary) -> String:
	if s.has("error"):
		return "trame invalide : %s (%s)" % [s["error"], s.get("raw", "")]
	return "puissance %s W | cadence %s rpm | vitesse %s km/h | brut %s" % [
		s.get("power_w", "—"), s.get("cadence_rpm", "—"), s.get("speed_kmh", "—"), s.get("raw", "")]


func _true_keys(d: Dictionary) -> String:
	var k := []
	for key in d:
		if d[key]:
			k.append(key)
	return ", ".join(k) if not k.is_empty() else "(aucune)"


func _set_phase(p: String) -> void:
	_phase = p
	_phase_started_ms = Time.get_ticks_msec()


func _finish(msg: String) -> void:
	if _phase == "done":
		return
	_phase = "done"
	_log(msg)
	# disconnect_device du gestionnaire : BleDevice.disconnect() masquerait Object.disconnect(signal, callable).
	if _bt != null and _address != "":
		_bt.disconnect_device(_address)
	var f := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(_lines))
		f.close()
		_log("Rapport : %s" % ProjectSettings.globalize_path(REPORT_PATH))
	else:
		_log("Rapport non écrit (%s)" % error_string(FileAccess.get_open_error()))


func _log(line: String) -> void:
	_lines.append(line)
	print(line)
	if _log_label != null:
		_log_label.append_text(line + "\n")
