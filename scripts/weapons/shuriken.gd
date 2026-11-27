extends Weapon
## 표창: 킬비 주위를 계속 도는 칼날.
## 레벨 2·4·6·8: 개수 +1 / 매 레벨: 피해·회전 속도 증가

const Blade := preload("res://scripts/weapons/shuriken_blade.gd")

var _blades: Array = []
var _angle := 0.0


func _count() -> int:
	return 1 + int(level / 2) + player.extra_projectiles


func _radius() -> float:
	return 42.0 * player.area


func _damage() -> float:
	return (4.0 + 1.5 * (level - 1)) * player.might


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	if _blades.size() != _count():
		_rebuild()
	_angle = wrapf(_angle + (3.0 + 0.2 * level) * delta, 0.0, TAU)
	var n := _blades.size()
	for i in n:
		var b: Area2D = _blades[i]
		b.position = Vector2.from_angle(_angle + TAU * i / n) * _radius()
		b.damage = _damage()
		b.scale = Vector2.ONE * player.area


func _rebuild() -> void:
	for b in _blades:
		b.queue_free()
	_blades.clear()
	for i in _count():
		var b := Blade.new()
		add_child(b)
		_blades.append(b)
