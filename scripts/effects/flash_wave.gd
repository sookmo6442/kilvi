extends Area2D
## 섬광 베기의 초승달 검기. 앞으로 날아가며 닿는 적을 모두 벤다(관통).
## 표식이 있는 적은 즉시 처형한다. 표적은 표식이 절반 이상일 때 처형.
## 보스는 처형되지 않는 대신 피해와 표식 2개를 받는다.

var direction := Vector2.RIGHT
var damage := 25.0
var size := 1.0
var life := 0.45
var _max_life := 0.45
var _hit := {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameData.FLASH.wave_radius
	shape.shape = circle
	add_child(shape)
	rotation = direction.angle()
	scale = Vector2.ONE * size
	z_index = 4
	_max_life = life
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * GameData.FLASH.wave_speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	var enemy := area as Enemy
	if enemy == null or enemy.dead or _hit.has(enemy.get_instance_id()):
		return
	_hit[enemy.get_instance_id()] = true
	var push := direction * 80.0
	if enemy.is_boss:
		enemy.take_damage(damage * 2.0, push)
		for i in GameData.FLASH.boss_marks:
			enemy.add_mark()
		return
	var need := ceili(enemy.mark_limit / 2.0) if enemy.is_target else 1
	if enemy.marks >= need:
		enemy.executed = true
		enemy.take_damage(enemy.hp + 1.0, push)
	else:
		enemy.take_damage(damage, push)
		if not enemy.dead:
			enemy.add_mark()


func _draw() -> void:
	# 앞쪽이 볼록한 초승달: 바깥 호와, 뒤로 물러난 안쪽 호 사이를 채운다
	var k := clampf(life / _max_life, 0.0, 1.0)
	var r := GameData.FLASH.wave_radius + 4.0
	var pts := PackedVector2Array()
	var n := 16
	for i in n + 1:
		var a := lerpf(-1.2, 1.2, float(i) / n)
		pts.append(Vector2.from_angle(a) * r)
	for i in n + 1:
		var a := lerpf(1.0, -1.0, float(i) / n)
		pts.append(Vector2(-r * 0.45, 0) + Vector2.from_angle(a) * r * 0.95)
	draw_colored_polygon(pts, Color(0.75, 0.9, 1.0, 0.55 * k))
	draw_polyline(pts.slice(0, n + 1), Color(1, 1, 1, k), 2.0)
	# 잔상
	draw_arc(Vector2(-10, 0), r * 0.9, -0.9, 0.9, 12, Color(0.6, 0.8, 1.0, 0.3 * k), 1.5)
