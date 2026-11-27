extends Node2D
## 대시할 때 남는 연기 한 덩어리.

var _life := 0.35


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _life / 0.35
	var c := Color(0.75, 0.75, 0.75, 0.6 * k)
	var r := 10.0 + (1.0 - k) * 8.0
	draw_circle(Vector2(-5, 2), r * 0.7, c)
	draw_circle(Vector2(5, -2), r * 0.6, c)
	draw_circle(Vector2(0, 0), r * 0.8, c)
