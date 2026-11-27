extends Node2D
## 임시 바닥: 카메라 주변에 풀과 돌을 규칙적으로 흩뿌려 이동감을 준다.
## 바닥 타일이 그려지면 TileMapLayer로 바꾸면 된다.

const CELL := 32
var target: Node2D


func _ready() -> void:
	z_index = -10


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if target == null:
		return
	var c := target.global_position
	var x0 := int(floor((c.x - 360.0) / CELL))
	var x1 := int(floor((c.x + 360.0) / CELL))
	var y0 := int(floor((c.y - 220.0) / CELL))
	var y1 := int(floor((c.y + 220.0) / CELL))
	for gx in range(x0, x1 + 1):
		for gy in range(y0, y1 + 1):
			var h := hash(Vector2i(gx, gy))
			var p := Vector2(gx * CELL + (h % 23), gy * CELL + ((h >> 5) % 23))
			match h % 9:
				0, 1:
					# 풀 한 포기
					var g := Color(0.26, 0.32, 0.24)
					draw_line(p, p + Vector2(-2, -5), g, 1.0)
					draw_line(p, p + Vector2(0, -6), g, 1.0)
					draw_line(p, p + Vector2(2, -4), g, 1.0)
				2:
					draw_circle(p, 1.5, Color(0.3, 0.31, 0.28))
				3:
					# 대나무 잎
					draw_line(p, p + Vector2(5, 2), Color(0.45, 0.55, 0.32), 2.0)
