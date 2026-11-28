extends Node2D
## 기폭수리검 폭발. 빠르게 퍼지는 불꽃과 고리.

const LIFE := 0.35

var radius := 30.0
var _life := LIFE


func _ready() -> void:
	z_index = 3


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _life / LIFE # 0 → 1
	var r := radius * (0.4 + 0.6 * sqrt(k))
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.55, 0.15, 0.55 * (1.0 - k)))
	draw_circle(Vector2.ZERO, r * 0.55, Color(1.0, 0.9, 0.6, 0.8 * (1.0 - k)))
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(1.0, 0.35, 0.1, 1.0 - k), 2.0)
