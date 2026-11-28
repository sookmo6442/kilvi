extends Area2D
## 수둔 유도탄. 처음엔 아무 방향으로 튀어나갔다가 목표를 향해 휘어 들어간다.
## 목표가 죽으면 가장 가까운 적으로 바꾼다. 맞으면 물이 튀어 주변 적까지 젖는다.

const Splash := preload("res://scripts/effects/water_splash.gd")

var velocity := Vector2.RIGHT * 170.0
var target: Enemy = null
var damage := 7.0
var wet_time := 3.0
var slow_time := 1.5
var splash_radius := 26.0
var life := 3.0
var _trail: Array[Vector2] = []
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	z_index = 2
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if target == null or not is_instance_valid(target) or target.dead:
		target = _nearest()
	var spd := GameData.TECH.water.speed as float
	if target:
		var want := (target.global_position - global_position).normalized() * spd
		velocity = velocity.lerp(want, minf(1.0, 5.0 * delta))
		velocity = velocity.normalized() * spd
	_trail.push_front(global_position)
	if _trail.size() > 6:
		_trail.pop_back()
	position += velocity * delta
	queue_redraw()


func _nearest() -> Enemy:
	var best: Enemy = null
	var best_d := 300.0 * 300.0
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy and not enemy.dead:
			var d := global_position.distance_squared_to(enemy.global_position)
			if d < best_d:
				best_d = d
				best = enemy
	return best


func _on_area_entered(area: Area2D) -> void:
	if _done:
		return
	var enemy := area as Enemy
	if enemy == null or enemy.dead:
		return
	_done = true
	# 물이 튀어서 주변 적까지 젖는다 (피해는 맞은 적에게만)
	var center := global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		var other := e as Enemy
		if other and not other.dead and center.distance_to(other.global_position) <= splash_radius + other.radius:
			other.apply_wet(wet_time)
			other.slow_time = maxf(other.slow_time, slow_time)
	enemy.take_damage(damage, velocity.normalized() * 40.0)
	var fx := Splash.new()
	fx.position = center
	fx.radius = splash_radius
	get_parent().add_child(fx)
	queue_free()


func _draw() -> void:
	for i in _trail.size():
		var k := 1.0 - float(i) / _trail.size()
		draw_circle(to_local(_trail[i]), 3.5 * k, Color(0.4, 0.7, 1.0, 0.5 * k))
	draw_circle(Vector2.ZERO, 4.5, Color(0.35, 0.65, 1.0))
	draw_circle(Vector2(-1.2, -1.2), 1.6, Color(0.9, 0.97, 1.0))
