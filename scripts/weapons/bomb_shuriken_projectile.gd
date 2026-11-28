extends Area2D
## 날아가는 기폭수리검. 적에게 박히면 그 적을 따라다니다 fuse초 뒤 폭발한다.
## 박힌 적이 먼저 죽으면 그 자리에서 터진다. 아무것도 못 맞히면 사라진다.

const Explosion := preload("res://scripts/effects/explosion.gd")

var velocity := Vector2.RIGHT * 200.0
var life := 1.4
var fuse := 2.0
var damage := 14.0
var blast_radius := 30.0
var size := 1.0

var _stuck_to: Enemy = null
var _stuck := false
var _offset := Vector2.ZERO
var _fuse_left := 0.0
var _spin := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	scale = Vector2.ONE * size
	z_index = 2
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if not _stuck:
		_spin += 18.0 * delta
		position += velocity * delta
		life -= delta
		if life <= 0.0:
			queue_free()
		queue_redraw()
		return
	if _stuck_to != null and is_instance_valid(_stuck_to) and not _stuck_to.dead:
		global_position = _stuck_to.global_position + _offset
	_fuse_left -= delta
	queue_redraw()
	if _fuse_left <= 0.0:
		_explode()


func _on_area_entered(area: Area2D) -> void:
	if _stuck:
		return
	var enemy := area as Enemy
	if enemy == null or enemy.dead:
		return
	_stuck = true
	_stuck_to = enemy
	_fuse_left = fuse
	_offset = (global_position - enemy.global_position).limit_length(enemy.radius * 0.6)
	set_deferred("monitoring", false)


func _explode() -> void:
	var center := global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var to := enemy.global_position - center
		if to.length() <= blast_radius + enemy.radius:
			enemy.take_damage(damage, to.normalized() * 90.0)
	var fx := Explosion.new()
	fx.position = center
	fx.radius = blast_radius
	get_parent().add_child(fx)
	queue_free()


func _draw() -> void:
	# 네 날 수리검 + 가운데 기폭 부적
	var steel := Color(0.85, 0.87, 0.92)
	var rot := _spin if not _stuck else 0.6
	for k in 4:
		var a := rot + TAU * k / 4.0
		var tip := Vector2.from_angle(a) * 6.0
		var side := Vector2.from_angle(a + PI / 2.0) * 1.8
		draw_colored_polygon(PackedVector2Array([tip, side, -side * 0.2, -side]), steel)
	var core := UiStyle.ORANGE
	if _stuck:
		# 터지기 직전일수록 빠르게 깜빡인다
		var rate := 4.0 + (1.0 - _fuse_left / fuse) * 14.0
		if fmod(_fuse_left * rate, 1.0) < 0.5:
			core = Color(1.0, 0.2, 0.15)
		# 폭발 범위 미리보기
		draw_arc(Vector2.ZERO, blast_radius / size, 0, TAU, 32,
			Color(1.0, 0.4, 0.15, 0.25 + 0.35 * (1.0 - _fuse_left / fuse)), 1.0)
	draw_circle(Vector2.ZERO, 2.0, core)
