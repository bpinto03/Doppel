class_name ColorVisionFixture
extends RefCounted

## Color distance as people see it: CIE L*a*b* lightness, CIEDE2000, and color vision deficiency simulated with
## the Machado 2009 matrices at full severity, applied to linear RGB. Used to keep tile levels apart (see 0003).

enum Vision { NORMAL, DEUTERANOPIA, PROTANOPIA, TRITANOPIA }

const SIMULATION_MATRICES: Dictionary[Vision, Basis] = {
	Vision.DEUTERANOPIA: Basis(Vector3(0.367322, 0.280085, -0.011820), Vector3(0.860646, 0.672501, 0.042940), Vector3(-0.227968, 0.047413, 0.968881)),
	Vision.PROTANOPIA: Basis(Vector3(0.152286, 0.114503, -0.003882), Vector3(1.052583, 0.786281, -0.048116), Vector3(-0.204868, 0.099216, 1.051998)),
	Vision.TRITANOPIA: Basis(Vector3(1.255528, -0.078411, 0.004733), Vector3(-0.076749, 0.930809, 0.691367), Vector3(-0.178779, 0.147602, 0.303900)),
}
## D65 white point and the CIE L*a*b* constants.
const WHITE_X: float = 0.95047
const WHITE_Z: float = 1.08883
const LAB_EPSILON: float = 216.0 / 24389.0
const LAB_KAPPA: float = 24389.0 / 27.0


static func simulate(color: Color, vision: Vision) -> Color:
	if vision == Vision.NORMAL:
		return color
	var linear := Vector3(color.srgb_to_linear().r, color.srgb_to_linear().g, color.srgb_to_linear().b)
	var simulated: Vector3 = (SIMULATION_MATRICES[vision] * linear).clamp(Vector3.ZERO, Vector3.ONE)
	return Color(simulated.x, simulated.y, simulated.z).linear_to_srgb()


static func to_lab(color: Color) -> Vector3:
	var linear: Color = color.srgb_to_linear()
	var x: float = (0.4124 * linear.r + 0.3576 * linear.g + 0.1805 * linear.b) / WHITE_X
	var y: float = 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b
	var z: float = (0.0193 * linear.r + 0.1192 * linear.g + 0.9505 * linear.b) / WHITE_Z
	var fx: float = _lab_curve(x)
	var fy: float = _lab_curve(y)
	var fz: float = _lab_curve(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


## The L* gap of two colors, as a grayscale picture shows them.
static func calculate_gray_gap(first: Color, second: Color) -> float:
	return absf(to_lab(first).x - to_lab(second).x)


static func calculate_color_difference(first: Color, second: Color, vision: Vision) -> float:
	return calculate_ciede2000(to_lab(simulate(first, vision)), to_lab(simulate(second, vision)))


## Sharma, Wu and Dalal's formulation of CIEDE2000.
static func calculate_ciede2000(first: Vector3, second: Vector3) -> float:
	var chroma_mean: float = (Vector2(first.y, first.z).length() + Vector2(second.y, second.z).length()) / 2.0
	var g: float = 0.5 * (1.0 - sqrt(pow(chroma_mean, 7) / (pow(chroma_mean, 7) + pow(25.0, 7))))
	var a1: float = (1.0 + g) * first.y
	var a2: float = (1.0 + g) * second.y
	var c1: float = Vector2(a1, first.z).length()
	var c2: float = Vector2(a2, second.z).length()
	var h1: float = fposmod(rad_to_deg(atan2(first.z, a1)), 360.0)
	var h2: float = fposmod(rad_to_deg(atan2(second.z, a2)), 360.0)
	var hue_step: float = 0.0
	if c1 * c2 != 0.0:
		hue_step = h2 - h1
		if hue_step > 180.0:
			hue_step -= 360.0
		elif hue_step < -180.0:
			hue_step += 360.0
	var delta_l: float = second.x - first.x
	var delta_c: float = c2 - c1
	var delta_h: float = 2.0 * sqrt(c1 * c2) * sin(deg_to_rad(hue_step / 2.0))
	var lightness_mean: float = (first.x + second.x) / 2.0
	var chroma_prime_mean: float = (c1 + c2) / 2.0
	var hue_mean: float = h1 + h2
	if c1 * c2 != 0.0:
		hue_mean = (h1 + h2) / 2.0 if absf(h1 - h2) <= 180.0 else (h1 + h2 + 360.0) / 2.0 if h1 + h2 < 360.0 else (h1 + h2 - 360.0) / 2.0
	var t: float = 1.0 - 0.17 * cos(deg_to_rad(hue_mean - 30.0)) + 0.24 * cos(deg_to_rad(2.0 * hue_mean)) \
		+ 0.32 * cos(deg_to_rad(3.0 * hue_mean + 6.0)) - 0.20 * cos(deg_to_rad(4.0 * hue_mean - 63.0))
	var rotation: float = 30.0 * exp(-pow((hue_mean - 275.0) / 25.0, 2))
	var chroma_weight: float = 2.0 * sqrt(pow(chroma_prime_mean, 7) / (pow(chroma_prime_mean, 7) + pow(25.0, 7)))
	var lightness_scale: float = 1.0 + 0.015 * pow(lightness_mean - 50.0, 2) / sqrt(20.0 + pow(lightness_mean - 50.0, 2))
	var chroma_scale: float = 1.0 + 0.045 * chroma_prime_mean
	var hue_scale: float = 1.0 + 0.015 * chroma_prime_mean * t
	var rotation_term: float = -sin(deg_to_rad(2.0 * rotation)) * chroma_weight
	return sqrt(pow(delta_l / lightness_scale, 2) + pow(delta_c / chroma_scale, 2) + pow(delta_h / hue_scale, 2)
		+ rotation_term * (delta_c / chroma_scale) * (delta_h / hue_scale))


static func _lab_curve(value: float) -> float:
	return pow(value, 1.0 / 3.0) if value > LAB_EPSILON else (LAB_KAPPA * value + 16.0) / 116.0
