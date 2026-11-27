class_name XpGem
extends Node2D
## 경험치 보석. 획득 범위 안에 들어오면 킬비에게 끌려간다.

var value := 1
var player: Player
var _magnet := false
var _speed := 0.0


func _ready() -> void:
	add_to_group("gems")
	z_index = -1


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if not _magnet and dist < player.pickup_range():
		_magnet = true
		_speed = -60.0 # 살짝 튕겨 나갔다가 빨려 들어온다
	if _magnet:
		_speed += 900.0 * delta
		position += to_player.normalized() * _speed * delta
		if dist < 8.0:
			player.add_xp(value)
			queue_free()


func _draw() -> void:
	var c := Color(0.35, 0.7, 1.0)
	var s := 3.0
	if value >= 5:
		c = Color(1.0, 0.35, 0.4)
		s = 5.0
	elif value >= 2:
		c = Color(0.4, 1.0, 0.55)
		s = 4.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -s), Vector2(s * 0.7, 0), Vector2(0, s), Vector2(-s * 0.7, 0)]), c)
