## Identifiants stables : UUID v4 générés à partir d'octets aléatoires cryptographiques.
extends RefCounted

const _HEX := "0123456789abcdef"


static func new_uuid() -> String:
	var b: PackedByteArray = Crypto.new().generate_random_bytes(16)
	b[6] = (b[6] & 0x0f) | 0x40  # version 4
	b[8] = (b[8] & 0x3f) | 0x80  # variante RFC 4122
	var s := ""
	for i in 16:
		if i == 4 or i == 6 or i == 8 or i == 10:
			s += "-"
		s += _HEX[b[i] >> 4] + _HEX[b[i] & 0x0f]
	return s


static func is_uuid(value: String) -> bool:
	var re := RegEx.create_from_string("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
	return re.search(value) != null
