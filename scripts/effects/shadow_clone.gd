extends Node2D
## 그림자 분신: 대시를 시작한 자리에 남는 검은 킬비. life초 동안 적을 끌어모은 뒤 터진다.

const KilviVisual := preload("res://scripts/kilvi_visual.gd")
const Explosion := preload("res://scripts/effects/explosion.gd")

var player: Player
var life := 1.0
var radius := 50.0
var damage := 30.0
var facing_x := 1.0
var _t := 0.0
var _tint: Node2D # 킬비 그림을 감싸서 색을 입힌다 (킬비 그림은 자기 modulate를 매 프레임 덮어쓴다)


func _ready() -> void:
	_tint = Node2D.new()
	add_child(_tint)
	var body: Node2D = KilviVisual.new()
	body.base_scale = 1.4
	body.scale = Vector2(facing_x, 1.0) * 1.4
	_tint.add_child(body)
	if player:
		player.decoy = self


func _process(delta: float) -> void:
	_t += delta
	# 그림자 색으로 칠하고, 터질 때가 다가오면 붉게 깜빡인다
	var warn := _t > life - 0.35 and int(_t * 20.0) % 2 == 0
	_tint.modulate = Color(1.0, 0.3, 0.3, 0.9) if warn else Color(0.3, 0.22, 0.5, 0.85)
	queue_redraw()
	if _t >= life:
		_explode()


func _explode() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var to: Vector2 = enemy.global_position - global_position
		if to.length() < radius + enemy.radius * enemy.size_mult:
			enemy.take_damage(damage, to.normalized() * 220.0)
			if not enemy.dead:
				enemy.add_mark()
	var fx: Node2D = Explosion.new()
	fx.position = position
	fx.radius = radius
	fx.color = Color(0.6, 0.35, 1.0)
	get_parent().add_child(fx)
	if player and player.decoy == self:
		player.decoy = null
	queue_free()


func _draw() -> void:
	# 적을 끄는 동안 발밑에 보라 고리
	var k := _t / life
	draw_arc(Vector2(0, 10), 14.0 + sin(_t * 12.0) * 2.0, 0, TAU, 24, Color(0.6, 0.35, 1.0, 0.7), 1.5)
	draw_arc(Vector2(0, 10), radius * k, 0, TAU, 40, Color(0.6, 0.35, 1.0, 0.25), 1.0)
