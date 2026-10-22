## Décodage du protocole Bluetooth FTMS (Fitness Machine Service, GATT 0x1826).
## Fonctions pures sur des PackedByteArray : aucune dépendance au transport BLE.
## Réf. : Bluetooth SIG, Fitness Machine Service 1.0 (Indoor Bike Data, Fitness Machine Feature).
extends RefCounted

const SERVICE := "00001826-0000-1000-8000-00805f9b34fb"
const FEATURE := "00002acc-0000-1000-8000-00805f9b34fb"
const INDOOR_BIKE_DATA := "00002ad2-0000-1000-8000-00805f9b34fb"
const SUPPORTED_RESISTANCE_RANGE := "00002ad6-0000-1000-8000-00805f9b34fb"
const SUPPORTED_POWER_RANGE := "00002ad8-0000-1000-8000-00805f9b34fb"
const CONTROL_POINT := "00002ad9-0000-1000-8000-00805f9b34fb"
const MACHINE_STATUS := "00002ada-0000-1000-8000-00805f9b34fb"
## Repli si FTMS absent : Cycling Power Service.
const CYCLING_POWER_SERVICE := "00001818-0000-1000-8000-00805f9b34fb"
const CYCLING_POWER_MEASUREMENT := "00002a63-0000-1000-8000-00805f9b34fb"

const MACHINE_FEATURES := [
	"average_speed", "cadence", "total_distance", "inclination", "elevation_gain", "pace",
	"step_count", "resistance_level", "stride_count", "expended_energy", "heart_rate",
	"metabolic_equivalent", "elapsed_time", "remaining_time", "power_measurement",
	"force_on_belt_and_power_output", "user_data_retention",
]
const TARGET_FEATURES := [
	"speed_target", "inclination_target", "resistance_target", "power_target", "heart_rate_target",
	"expended_energy_target", "step_number_target", "stride_number_target", "distance_target",
	"training_time_target", "two_hr_zones_target", "three_hr_zones_target", "five_hr_zones_target",
	"indoor_bike_simulation", "wheel_circumference", "spin_down_control", "cadence_target",
]


## Normalise un UUID (16 ou 128 bits, casse quelconque) en forme longue minuscule.
static func normalize_uuid(uuid: String) -> String:
	var u := uuid.strip_edges().to_lower()
	if u.length() == 4:
		return "0000%s-0000-1000-8000-00805f9b34fb" % u
	return u


## Fitness Machine Feature (0x2ACC) : 2 × uint32. Renvoie {machine: {nom: bool}, target: {nom: bool}} ou {error}.
static func parse_feature(data: PackedByteArray) -> Dictionary:
	if data.size() < 8:
		return {"error": "Fitness Machine Feature trop court (%d octets, 8 attendus)" % data.size()}
	var m := data.decode_u32(0)
	var t := data.decode_u32(4)
	var machine := {}
	var target := {}
	for i in MACHINE_FEATURES.size():
		machine[MACHINE_FEATURES[i]] = (m >> i) & 1 == 1
	for i in TARGET_FEATURES.size():
		target[TARGET_FEATURES[i]] = (t >> i) & 1 == 1
	return {"machine": machine, "target": target}


## Indoor Bike Data (0x2AD2). Renvoie les champs présents en unités SI usuelles, ou {error}.
## Champs possibles : speed_kmh, avg_speed_kmh, cadence_rpm, avg_cadence_rpm, distance_m,
## resistance_level, power_w, avg_power_w, energy_kcal, heart_rate_bpm, met, elapsed_s, remaining_s.
static func parse_indoor_bike_data(data: PackedByteArray) -> Dictionary:
	if data.size() < 2:
		return {"error": "Indoor Bike Data trop court"}
	var flags := data.decode_u16(0)
	var out := {}
	var o := 2
	# [bit, nom, taille, signé, échelle] ; bit 0 inversé (« More Data » : 0 = vitesse présente).
	var fields := [
		[0, "speed_kmh", 2, false, 0.01],
		[1, "avg_speed_kmh", 2, false, 0.01],
		[2, "cadence_rpm", 2, false, 0.5],
		[3, "avg_cadence_rpm", 2, false, 0.5],
		[4, "distance_m", 3, false, 1.0],
		[5, "resistance_level", 2, true, 1.0],
		[6, "power_w", 2, true, 1.0],
		[7, "avg_power_w", 2, true, 1.0],
	]
	for f in fields:
		var present: bool = ((flags & 1) == 0) if f[0] == 0 else ((flags >> f[0]) & 1) == 1
		if not present:
			continue
		if o + f[2] > data.size():
			return {"error": "Indoor Bike Data tronqué au champ %s" % f[1]}
		var v: int
		match f[2]:
			2:
				v = data.decode_s16(o) if f[3] else data.decode_u16(o)
			3:
				v = data[o] | (data[o + 1] << 8) | (data[o + 2] << 16)
		out[f[1]] = v * f[4]
		o += f[2]
	if (flags >> 8) & 1:  # énergie : total u16 + par heure u16 + par minute u8
		if o + 5 > data.size():
			return {"error": "Indoor Bike Data tronqué au champ energy"}
		out["energy_kcal"] = data.decode_u16(o)
		o += 5
	for f in [[9, "heart_rate_bpm", 1, 1.0], [10, "met", 1, 0.1], [11, "elapsed_s", 2, 1.0], [12, "remaining_s", 2, 1.0]]:
		if (flags >> f[0]) & 1:
			if o + f[2] > data.size():
				return {"error": "Indoor Bike Data tronqué au champ %s" % f[1]}
			out[f[1]] = (data[o] if f[2] == 1 else data.decode_u16(o)) * f[3]
			o += f[2]
	return out


## Supported Power Range (0x2AD8) : min, max (sint16 W), incrément (uint16 W).
static func parse_power_range(data: PackedByteArray) -> Dictionary:
	if data.size() < 6:
		return {"error": "Supported Power Range trop court"}
	return {"min_w": data.decode_s16(0), "max_w": data.decode_s16(2), "step_w": data.decode_u16(4)}
