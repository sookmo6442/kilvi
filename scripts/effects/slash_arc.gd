extends Node2D
## 쿠나이 베기·회전 베기 이펙트. start_angle에서 sweep만큼 빠르게 휘두르는 칼자국.
## follow가 있으면 그 노드를 따라다닌다(회전 베기).

var radius := 40.0
var start_angle := 0.0
var sweep := 2.0
var duration := 0.16
var color := Color(0.95, 0.95, 1.0)
var follow: Node2D = null
var _t := 0.0


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	_t += delta
	if follow and is_instance_valid(follow):
		global_position = follow.global_position
	if _t >= duration + 0.12:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0) # 휘두른 정도
	var fade := 1.0 - clampf((_t - duration) / 0.12, 0.0, 1.0)
	var head := start_angle + sweep * k
	var tail := start_angle + sweep * maxf(0.0, k - 0.7)
	if absf(head - tail) < 0.01:
		return
	var n := 18
	# 칼자국: 바깥 두꺼운 호 + 안쪽 옅은 면
	var pts := PackedVector2Array()
	for i in n + 1:
		pts.append(Vector2.from_angle(lerpf(tail, head, float(i) / n)) * radius)
	for i in n + 1:
		pts.append(Vector2.from_angle(lerpf(head, tail, float(i) / n)) * radius * 0.6)
	draw_colored_polygon(pts, Color(color.r, color.g, color.b, 0.35 * fade))
	draw_arc(Vector2.ZERO, radius, minf(tail, head), maxf(tail, head), n, Color(color.r, color.g, color.b, fade), 2.5)
	# 칼끝 반짝임
	draw_circle(Vector2.from_angle(head) * radius, 2.5, Color(1, 1, 1, fade))
