extends Area2D
## 연기 구름. 0.5초마다 안에 있는 적에게 피해를 주고 느리게 만든다.

var radius := 30.0
var life := 2.0
var damage := 3.0
var _tick := 0.0
var _max_life := 2.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	z_index = -1
	_max_life = life
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		for area in get_overlapping_areas():
			var enemy := area as Enemy
			if enemy != null and not enemy.dead:
				enemy.slow_time = 0.6
				enemy.take_damage(damage)
	queue_redraw()


func _draw() -> void:
	var k := clampf(life / _max_life, 0.0, 1.0)
	var a := 0.45 * minf(k * 3.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.55, 0.6, a * 0.6))
	draw_circle(Vector2(-radius * 0.35, -radius * 0.2), radius * 0.55, Color(0.7, 0.7, 0.75, a))
	draw_circle(Vector2(radius * 0.3, radius * 0.15), radius * 0.6, Color(0.65, 0.65, 0.7, a))
