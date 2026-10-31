class_name ColorContrast
extends RefCounted

## WCAG 2 contrast ratio of two opaque colors, from 1 (same luminance) to 21 (black on white).
static func calculate_ratio(first: Color, second: Color) -> float:
	var first_luminance: float = calculate_relative_luminance(first)
	var second_luminance: float = calculate_relative_luminance(second)
	return (maxf(first_luminance, second_luminance) + 0.05) / (minf(first_luminance, second_luminance) + 0.05)


static func calculate_relative_luminance(color: Color) -> float:
	var linear: Color = color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b
