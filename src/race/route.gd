## Parcours segmenté. Unités : mètres, pente en fraction (0.05 = 5 %).
## Construit depuis un Dictionary (JSON) validé ; aucune dépendance aux scènes.
extends RefCounted

const FORMAT_VERSION := 1
const MAX_SEGMENTS := 5000
const MAX_ABS_GRADE := 0.25
## Coefficients de résistance au roulement par surface (estimations, à calibrer).
const SURFACE_CRR := {
	"asphalt": 0.004,
	"rough": 0.006,
	"gravel": 0.008,
	"cobbles": 0.010,
}

var id: String = ""
var name: String = ""
var distance_m: float = 0.0
var sprints: Array = []  # [{at_m, name}]
var climbs: Array = []  # [{start_m, end_m, category, name}]

var _starts := PackedFloat64Array()  # début de chaque segment
var _grades := PackedFloat64Array()
var _crrs := PackedFloat64Array()
var _elev_start := PackedFloat64Array()  # altitude relative au début de chaque segment


## Renvoie {"route": Route} ou {"error": String}.
static func parse(d: Dictionary) -> Dictionary:
	var script: GDScript = load("res://src/race/route.gd")
	var r = script.new()
	var err: String = r._fill(d)
	if err != "":
		return {"error": err}
	return {"route": r}


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": "parcours introuvable : %s" % path}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return {"error": "parcours illisible (JSON objet attendu) : %s" % path}
	return parse(data)


func segment_index_at(x_m: float) -> int:
	# Recherche dichotomique du dernier segment dont le début est <= x.
	var lo := 0
	var hi := _starts.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if _starts[mid] <= x_m:
			lo = mid
		else:
			hi = mid - 1
	return lo


func grade_at(x_m: float) -> float:
	return _grades[segment_index_at(x_m)]


func crr_at(x_m: float) -> float:
	return _crrs[segment_index_at(x_m)]


func elevation_at(x_m: float) -> float:
	var i := segment_index_at(clampf(x_m, 0.0, distance_m))
	return _elev_start[i] + (clampf(x_m, 0.0, distance_m) - _starts[i]) * _grades[i]


func segment_count() -> int:
	return _starts.size()


func _fill(d: Dictionary) -> String:
	if int(d.get("format_version", -1)) != FORMAT_VERSION:
		return "format_version %s non supporté (attendu %d)" % [str(d.get("format_version")), FORMAT_VERSION]
	id = str(d.get("id", ""))
	name = str(d.get("name", ""))
	if id.is_empty():
		return "identifiant de parcours manquant"
	var segs = d.get("segments", [])
	if typeof(segs) != TYPE_ARRAY or segs.is_empty():
		return "parcours sans segment"
	if segs.size() > MAX_SEGMENTS:
		return "trop de segments (%d > %d)" % [segs.size(), MAX_SEGMENTS]
	var x := 0.0
	var z := 0.0
	for i in segs.size():
		var s = segs[i]
		if typeof(s) != TYPE_DICTIONARY:
			return "segment %d invalide" % i
		var length := float(s.get("length_m", 0.0))
		var grade := float(s.get("grade_pct", 0.0)) / 100.0
		var surface := str(s.get("surface", "asphalt"))
		if not is_finite(length) or length <= 0.0:
			return "segment %d : longueur invalide (%s)" % [i, str(s.get("length_m"))]
		if not is_finite(grade) or absf(grade) > MAX_ABS_GRADE:
			return "segment %d : pente hors bornes (%s %%)" % [i, str(s.get("grade_pct"))]
		if not SURFACE_CRR.has(surface):
			return "segment %d : surface inconnue '%s'" % [i, surface]
		_starts.append(x)
		_grades.append(grade)
		_crrs.append(SURFACE_CRR[surface])
		_elev_start.append(z)
		x += length
		z += length * grade
	distance_m = x
	sprints = d.get("sprints", [])
	climbs = d.get("climbs", [])
	for sp in sprints:
		if float(sp.get("at_m", -1.0)) < 0.0 or float(sp.get("at_m", -1.0)) > distance_m:
			return "sprint hors parcours : %s" % str(sp)
	for c in climbs:
		var a := float(c.get("start_m", -1.0))
		var b := float(c.get("end_m", -1.0))
		if a < 0.0 or b <= a or b > distance_m:
			return "montée hors parcours : %s" % str(c)
	return ""
