## Physique cycliste minimale. Unités SI : W, m/s, kg, N, m².
## Modèle : propulsion = P × rendement / v ; résistances = gravité + roulement + traînée.
## Les constantes marquées « estimation » sont à calibrer (voir docs/DECISIONS.md).
extends RefCounted

const G := 9.80665
const RHO_AIR := 1.225  # kg/m³, niveau de la mer, 15 °C
const DRIVETRAIN_EFFICIENCY := 0.976  # estimation
## Vitesse plancher pour la force de propulsion : évite une force infinie à l'arrêt.
const V_MIN_PROPULSION := 2.0
## Aspiration : réduction de traînée maximale collé derrière une roue, nulle au-delà de DRAFT_RANGE_M.
const DRAFT_MAX_REDUCTION := 0.35  # estimation (~30-40 % mesurés à 1 m derrière un coureur)
const DRAFT_FULL_M := 1.0
const DRAFT_RANGE_M := 5.0


static func resistive_force(v: float, grade: float, mass_kg: float, crr: float, cda_m2: float) -> float:
	var theta := atan(grade)
	return mass_kg * G * (crr * cos(theta) + sin(theta)) + 0.5 * RHO_AIR * cda_m2 * v * absf(v)


## Avance la vitesse d'un pas de temps (Euler explicite ; stable pour dt <= 1 s, constante de temps ~20 s).
static func next_speed(v: float, power_w: float, grade: float, mass_kg: float, crr: float, cda_m2: float, dt: float) -> float:
	var propulsion := maxf(power_w, 0.0) * DRIVETRAIN_EFFICIENCY / maxf(v, V_MIN_PROPULSION)
	var a := (propulsion - resistive_force(v, grade, mass_kg, crr, cda_m2)) / mass_kg
	return maxf(v + a * dt, 0.0)


## Vitesse d'équilibre pour une puissance constante (dichotomie). Sert aux tests et aux estimations.
static func steady_speed(power_w: float, grade: float, mass_kg: float, crr: float, cda_m2: float) -> float:
	var lo := 0.0
	var hi := 40.0
	for i in 60:
		var mid := (lo + hi) * 0.5
		var needed := resistive_force(mid, grade, mass_kg, crr, cda_m2) * mid / DRIVETRAIN_EFFICIENCY
		if needed < power_w:
			lo = mid
		else:
			hi = mid
	return lo


## Multiplicateur de CdA selon l'écart (m) avec la roue de devant. 1.0 = aucun abri.
static func draft_factor(gap_m: float) -> float:
	if gap_m <= 0.0 or gap_m >= DRAFT_RANGE_M:
		return 1.0
	if gap_m <= DRAFT_FULL_M:
		return 1.0 - DRAFT_MAX_REDUCTION
	var t := (gap_m - DRAFT_FULL_M) / (DRAFT_RANGE_M - DRAFT_FULL_M)
	return 1.0 - DRAFT_MAX_REDUCTION * (1.0 - t)


## Bilan d'énergie anaérobie W' (modèle différentiel de Skiba).
## Au-dessus de CP : W' se vide de (P - CP)·dt. En dessous : recharge proportionnelle au manque.
static func next_wbal(wbal_j: float, power_w: float, cp_w: float, wprime_j: float, dt: float) -> float:
	if power_w > cp_w:
		return maxf(wbal_j - (power_w - cp_w) * dt, 0.0)
	return minf(wbal_j + (wprime_j - wbal_j) / wprime_j * (cp_w - power_w) * dt, wprime_j)
