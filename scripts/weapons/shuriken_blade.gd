extends Area2D
## 표창 칼날 하나. 같은 적은 0.4초에 한 번만 때린다.

var damage := 4.0
var _last_hit := {} # instance_id -> 시각
var _spin := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_spin += 14.0 * delta
	queue_redraw()
	var now := Time.get_ticks_msec() / 1000.0
	for area in get_overlapping_areas():
		var enemy := area as Enemy
		if enemy == null or enemy.dead:
			continue
		var id := enemy.get_instance_id()
		if now - _last_hit.get(id, -10.0) < 0.4:
			continue
		_last_hit[id] = now
		var center: Vector2 = (get_parent() as Node2D).global_position
		var push := (enemy.global_position - center).normalized() * 120.0
		enemy.take_damage(damage, push)
	if _last_hit.size() > 200:
		_last_hit.clear()


func _draw() -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var r := 7.0 if i % 2 == 0 else 2.5
		pts.append(Vector2.from_angle(_spin + TAU * i / 8.0) * r)
	draw_colored_polygon(pts, Color(0.8, 0.82, 0.88))
	draw_circle(Vector2.ZERO, 1.2, Color(0.15, 0.15, 0.18))
