extends Node2D
## 수둔 유도탄이 맞았을 때 튀는 물.

const LIFE := 0.3
var radius := 26.0
var _life := LIFE


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _life / LIFE
	var r := radius * (0.5 + 0.5 * k)
	draw_circle(Vector2.ZERO, r, Color(0.4, 0.7, 1.0, 0.25 * (1.0 - k)))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(0.6, 0.85, 1.0, 1.0 - k), 1.5)
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		draw_circle(Vector2.from_angle(a) * r * 1.1, 1.5, Color(0.7, 0.9, 1.0, 1.0 - k))
