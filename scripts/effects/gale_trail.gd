extends Node2D
## 질풍: 대시가 지나간 길에 남는 칼자국.

const LIFE := 0.3
var from := Vector2.ZERO
var to := Vector2.ZERO
var _life := LIFE


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _life / LIFE
	var side := (to - from).orthogonal().normalized() * 3.0 * k
	draw_line(from + side, to + side, Color(1.0, 0.62, 0.1, 0.7 * k), 3.0 * k + 1.0)
	draw_line(from - side, to - side, Color(1.0, 1.0, 1.0, k), 1.5)
