extends Area2D
## 날아가는 쿠나이 한 자루.

var velocity := Vector2.RIGHT * 300.0
var damage := 5.0
var pierce := 1
var life := 1.2
var _spent := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	rotation = velocity.angle()
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent:
		return
	var enemy := area as Enemy
	if enemy == null or enemy.dead:
		return
	enemy.take_damage(damage, velocity.normalized() * 60.0)
	pierce -= 1
	if pierce <= 0:
		_spent = true
		queue_free()


func _draw() -> void:
	# 칼날
	draw_colored_polygon(PackedVector2Array([
		Vector2(7, 0), Vector2(0, -2), Vector2(-2, 0), Vector2(0, 2)]), Color(0.85, 0.87, 0.92))
	# 손잡이와 고리
	draw_line(Vector2(-2, 0), Vector2(-6, 0), Color(0.2, 0.2, 0.22), 2.0)
	draw_arc(Vector2(-8, 0), 2.0, 0, TAU, 8, Color(0.85, 0.87, 0.92), 1.0)
