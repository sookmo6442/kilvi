extends Node2D
## 통나무 둔갑으로 남는 통나무. 2초 동안 적을 끌어모았다가 터진다.

const LIFE := 2.0
const BLAST_RADIUS := 56.0

var player: Player
var _life := LIFE


func _ready() -> void:
	z_index = 0


func _process(delta: float) -> void:
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		_explode()


func _explode() -> void:
	var dmg := 20.0 * (player.might if player else 1.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var to: Vector2 = enemy.global_position - global_position
		if to.length() < BLAST_RADIUS:
			enemy.take_damage(dmg, to.normalized() * 200.0)
	var puff := preload("res://scripts/effects/smoke_puff.gd").new()
	puff.position = position
	puff.scale = Vector2.ONE * 2.5
	get_parent().add_child(puff)
	queue_free()


func _draw() -> void:
	# 흔들리는 통나무 (끝날수록 빨리 흔들린다)
	var shake := sin(_life * (30.0 - _life * 10.0)) * (1.5 - _life * 0.5)
	draw_set_transform(Vector2(shake, 0), 0.0, Vector2.ONE)
	draw_circle(Vector2(0, 10), 9.0, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-6, -12, 12, 22), Color(0.5, 0.33, 0.18))
	draw_rect(Rect2(-6, -12, 3, 22), Color(0.4, 0.25, 0.13))
	draw_circle(Vector2(0, -12), 6.0, Color(0.72, 0.55, 0.35))
	draw_arc(Vector2(0, -12), 3.5, 0, TAU, 12, Color(0.5, 0.33, 0.18), 1.0)
	draw_line(Vector2(6, -2), Vector2(10, -6), Color(0.4, 0.25, 0.13), 2.0)
	# 터지기 직전 범위 표시
	if _life < 0.6:
		draw_arc(Vector2.ZERO, BLAST_RADIUS, 0, TAU, 32, Color(1.0, 0.62, 0.1, 0.5 * (1.0 - _life / 0.6)), 1.0)
