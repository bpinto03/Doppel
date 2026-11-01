shader_type canvas_item;

// Draws a texture as an engraved silhouette: its shape in engraving_color over a light lip, the same shape
// shifted down by lip_offset (in UV) in highlight_color. Colors are given as stored, without conversion.

uniform vec4 engraving_color;
uniform vec4 highlight_color;
uniform vec2 lip_offset;

void fragment() {
	float shape = texture(TEXTURE, UV).a * engraving_color.a;
	float lip = texture(TEXTURE, UV - lip_offset).a * highlight_color.a;
	float alpha = shape + lip * (1.0 - shape);
	vec3 rgb = (engraving_color.rgb * shape + highlight_color.rgb * lip * (1.0 - shape)) / max(alpha, 0.0001);
	COLOR = vec4(rgb, alpha);
}
