class_name EnemyBullet
extends Node2D
## 적이 쏘는 탄(깃털, 여우불 등). 킬비와의 거리로만 충돌을 검사한다.

var velocity := Vector2.ZERO
var damage := 5.0
var player: Player
var color := Color.WHITE
var size := 3.0
var life := 4.0
## 탄막용 옵션 (fire()가 돌려준 탄에 바로 넣는다)
var accel := 0.0 # 초당 속도 변화(px/s²). 음수면 느려진다
var max_speed := 260.0
var turn := 0.0 # 초당 회전(rad). 곡선을 그리며 날아간다
var delay := 0.0 # 이 시간 동안 제자리에 떠 있다가(흐리게 깜빡임) 날아간다


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
	if Enemy.frozen_left > 0.0:
		return
	if delay > 0.0:
		delay -= delta
		queue_redraw()
		return
	if turn != 0.0:
		velocity = velocity.rotated(turn * delta)
		rotation = velocity.angle()
	if accel != 0.0:
		var spd := clampf(velocity.length() + accel * delta, 20.0, max_speed)
		velocity = velocity.normalized() * spd
	position += velocity * delta
	life -= delta
	if life <= 0.0 or player == null:
		queue_free()
		return
	# 탄막을 피할 만하게 판정은 그림보다 조금 작다
	if global_position.distance_to(player.global_position) < size + Player.HIT_RADIUS * 0.6:
		player.take_damage(damage)
		queue_free()


func _draw() -> void:
	if delay > 0.0:
		# 대기 중: 깜빡이는 예고 (아직 맞지 않는다)
		var a := 0.35 + 0.3 * sin(delay * 30.0)
		draw_circle(Vector2.ZERO, size + 1.5, Color(color, a))
		return
	# 바깥 빛 → 색 몸통 → 하얀 심. 어두운 바닥과 적 무리 위에서도 잘 보이게
	draw_circle(Vector2.ZERO, size + 2.5, Color(color, 0.3))
	draw_circle(Vector2.ZERO, size, color)
	draw_circle(Vector2.ZERO, size * 0.45, Color(1, 1, 0.95))
