extends CanvasLayer
## 화면 전체 효과: 달빛 비네팅(항상), 처형 순간 흑백 + 붉은 테두리 번쩍임.

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float desat = 0.0;
uniform float flash = 0.0;
uniform float vignette = 0.55;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	// 달빛: 살짝 푸르고 어둡게
	c = mix(c, c * vec3(0.82, 0.88, 1.05), 0.6);
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(g), desat);
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.6, 1.0);
	float v = smoothstep(0.35, 0.95, length(d));
	c *= 1.0 - v * vignette;
	c = mix(c, vec3(0.9, 0.1, 0.08), v * flash * 0.8);
	COLOR = vec4(c, 1.0);
}
"""

var _mat: ShaderMaterial
var _desat := 0.0
var _flash := 0.0


func _ready() -> void:
	layer = 3
	process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	rect.material = _mat
	add_child(rect)


func execution_flash(strength: float = 1.0) -> void:
	_desat = maxf(_desat, 0.85 * strength)
	_flash = maxf(_flash, 0.6 * strength)


func _process(delta: float) -> void:
	_desat = move_toward(_desat, 0.0, delta * 4.0)
	_flash = move_toward(_flash, 0.0, delta * 3.0)
	_mat.set_shader_parameter("desat", _desat)
	_mat.set_shader_parameter("flash", _flash)
