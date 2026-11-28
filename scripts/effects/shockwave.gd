extends Node2D
## 토끼 튕겨 차기 충격파.

const LIFE := 0.35
var radius := 52.0
var _life := LIFE


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _life / LIFE
	var r := radius * (0.3 + 0.7 * sqrt(k))
	draw_circle(Vector2.ZERO, r, Color(0.92, 0.89, 0.82, 0.25 * (1.0 - k)))
	draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(1.0, 0.62, 0.1, 1.0 - k), 3.0)
	draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 32, Color(1, 1, 1, 0.6 * (1.0 - k)), 1.5)
