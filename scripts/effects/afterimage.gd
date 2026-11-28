extends Node2D
## 체술 대시의 잔상. 킬비 그림을 한 장 복사해 남색으로 물들여 빠르게 사라지게 한다.

const KilviVisual := preload("res://scripts/kilvi_visual.gd")
const LIFE := 0.22

var visual_scale := Vector2.ONE
var visual_rotation := 0.0
var _life := LIFE


func _ready() -> void:
	z_index = -1
	var v := KilviVisual.new()
	v.scale = visual_scale
	v.rotation = visual_rotation
	v.set_process(false)
	add_child(v)
	modulate = Color(0.45, 0.55, 1.0, 0.55)


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	modulate.a = 0.55 * _life / LIFE
