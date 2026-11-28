class_name EnemyBullet
extends Node2D
## 적이 쏘는 탄(깃털, 여우불 등). 킬비와의 거리로만 충돌을 검사한다.

var velocity := Vector2.ZERO
var damage := 5.0
var player: Player
var color := Color.WHITE
var size := 3.0
var life := 4.0


static func fire(parent: Node, pos: Vector2, vel: Vector2, dmg: float, p: Player, col: Color, sz: float = 3.0) -> EnemyBullet:
	var b := EnemyBullet.new()
	b.position = pos
	b.velocity = vel
	b.damage = dmg
	b.player = p
	b.color = col
	b.size = sz
	parent.add_child(b)
	return b


func _ready() -> void:
	z_index = 2
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0 or player == null:
		queue_free()
		return
	if global_position.distance_to(player.global_position) < size + Player.HIT_RADIUS:
		player.take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, size + 1.5, Color(color, 0.35))
	draw_colored_polygon(PackedVector2Array([
		Vector2(size * 1.8, 0), Vector2(0, -size), Vector2(-size, 0), Vector2(0, size)]), color)
