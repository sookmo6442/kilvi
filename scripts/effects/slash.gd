extends Node2D
## 처형할 때 그어지는 붉은 베기 선.

var length := 34.0
var _life := 0.25


func _ready() -> void:
	rotation = randf_range(-0.9, -0.5)
	z_index = 5


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _life / 0.25
	var half := length * (1.2 - k * 0.2) / 2.0
	draw_line(Vector2(-half, 0), Vector2(half, 0), Color(1.0, 0.15, 0.1, k), 3.0 * k + 1.0)
	draw_line(Vector2(-half * 0.8, 0), Vector2(half * 0.8, 0), Color(1, 1, 1, k), 1.0)
