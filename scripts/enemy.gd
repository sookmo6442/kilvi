class_name Enemy
extends Area2D
## 일반 적. 플레이어를 향해 다가가고, 닿으면 피해를 준다.
## 충돌 레이어 2(enemies)에 있어서 무기가 감지한다.

signal killed(enemy: Enemy)

var type_id := "wisp"
var player: Player
var max_hp := 6.0
var hp := 6.0
var speed := 38.0
var damage := 5.0
var radius := 7.0
var xp_value := 1
var color := Color.WHITE
var behavior := "chase"
var dead := false
var slow_time := 0.0

var _knock := Vector2.ZERO
var _flash := 0.0
var _t := 0.0
var _charge_timer := 0.0
var _charge_dir := Vector2.ZERO
var _charging := 0.0


func setup(id: String, p: Player, hp_mult: float) -> void:
	var d: Dictionary = GameData.ENEMIES[id]
	type_id = id
	player = p
	max_hp = d.hp * hp_mult
	hp = max_hp
	speed = d.speed
	damage = d.damage
	radius = d.radius
	xp_value = d.xp
	color = d.color
	behavior = d.behavior
	_charge_timer = randf_range(1.5, 3.0)
	_t = randf() * 10.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	if dead or player == null:
		return
	_t += delta
	slow_time = maxf(slow_time - delta, 0.0)
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player / dist if dist > 0.01 else Vector2.ZERO
	var spd := speed * (0.5 if slow_time > 0.0 else 1.0)

	if behavior == "charge":
		_charge_timer -= delta
		if _charging > 0.0:
			_charging -= delta
			dir = _charge_dir
			spd *= 2.8
		elif _charge_timer <= 0.0 and dist < 180.0:
			_charge_dir = dir
			_charging = 0.45
			_charge_timer = randf_range(2.2, 3.2)

	position += dir * spd * delta + _knock * delta
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)

	if dist < radius + Player.HIT_RADIUS:
		player.take_damage(damage)

	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()
	# 좌우 방향 + 살랑임
	var flip := -1.0 if to_player.x < 0.0 else 1.0
	scale = Vector2(flip, 1.0 + sin(_t * 8.0) * 0.06)


func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	hp -= amount
	_knock += knockback
	_flash = 0.08
	queue_redraw()
	if hp <= 0.0:
		dead = true
		killed.emit(self)
		queue_free()


func _draw() -> void:
	var c := Color.WHITE if _flash > 0.0 else color
	if type_id == "wisp":
		draw_circle(Vector2.ZERO, radius, c)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-radius, 0), Vector2(0, -radius * 2.2), Vector2(radius, 0)]), c)
		draw_rect(Rect2(1, -2, 2, 3), Color(0.1, 0.1, 0.2))
		draw_rect(Rect2(-3, -2, 2, 3), Color(0.1, 0.1, 0.2))
	else:
		# 여우 자객: 몸통 + 귀 + 꼬리 + 가면
		draw_circle(Vector2.ZERO, radius, c)
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -6), Vector2(-3, -15), Vector2(0, -7)]), c)
		draw_colored_polygon(PackedVector2Array([Vector2(1, -7), Vector2(5, -15), Vector2(7, -5)]), c)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 2), Vector2(-17, -4), Vector2(-14, 6)]), c)
		draw_circle(Vector2(3, -1), 4.0, Color(0.95, 0.93, 0.88))
		draw_line(Vector2(1, -2), Vector2(3, -2), Color.RED, 1.0)
		draw_line(Vector2(4, -2), Vector2(6, -2), Color.RED, 1.0)
