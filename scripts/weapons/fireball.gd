extends Area2D
## 화둔 불덩이. 처음 닿은 적에게서 터진다. 아무것도 못 맞히면 수명이 끝날 때 그 자리에서 터진다.

const Explosion := preload("res://scripts/effects/explosion.gd")

var velocity := Vector2.RIGHT * 210.0
var damage := 16.0
var blast_radius := 28.0
var burn_time := 3.0
var burn_dps := 4.0
var life := 1.3
var _t := 0.0
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	shape.shape = circle
	add_child(shape)
	z_index = 2
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	position += velocity * delta
	life -= delta
	queue_redraw()
	if life <= 0.0:
		_explode()


func _on_area_entered(area: Area2D) -> void:
	var enemy := area as Enemy
	if enemy and not enemy.dead:
		_explode()


func _explode() -> void:
	if _done:
		return
	_done = true
	var center := global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var to := enemy.global_position - center
		if to.length() <= blast_radius + enemy.radius:
			enemy.take_damage(damage, to.normalized() * 70.0)
			if not enemy.dead:
				enemy.apply_burn(burn_time, burn_dps)
	var fx := Explosion.new()
	fx.position = center
	fx.radius = blast_radius
	get_parent().add_child(fx)
	queue_free()


func _draw() -> void:
	# 꼬리 불꽃 + 불덩이
	var back := -velocity.normalized()
	for i in 4:
		var k := float(i) / 4.0
		var wob := back.orthogonal() * sin(_t * 30.0 + i) * 1.5
		draw_circle(back * (4.0 + i * 4.0) + wob, 4.5 * (1.0 - k), Color(1.0, 0.45 + 0.1 * i, 0.1, 0.7 * (1.0 - k)))
	draw_circle(Vector2.ZERO, 5.5, Color(1.0, 0.5, 0.1))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.5))
