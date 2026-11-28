extends Weapon
## 표창: 킬비 주위를 계속 도는 칼날.
## 레벨 2·4·6·8: 개수 +1 / 매 레벨: 피해·회전 속도 증가

const Blade := preload("res://scripts/weapons/shuriken_blade.gd")

var _blades: Array = []
var _angle := 0.0


func _count() -> int:
	var n := 1 + int(level / 2) + player.extra_projectiles
	return n * 2 if evolved else n


func _radius() -> float:
	return 42.0 * player.area


func _damage() -> float:
	return (4.0 + 1.5 * (level - 1)) * player.might * (1.5 if evolved else 1.0)


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	if _blades.size() != _count():
		_rebuild()
	_angle = wrapf(_angle + (3.0 + 0.2 * level) * delta, 0.0, TAU)
	var n := _blades.size()
	if evolved:
		# 혼돈의 고리: 바깥 고리와 안쪽 고리가 반대로 돈다
		var half := n / 2
		for i in n:
			var b: Area2D = _blades[i]
			var outer := i < half
			var k := i if outer else i - half
			var ring_n := half if outer else n - half
			var ang := _angle if outer else -_angle * 1.3
			var r := _radius() * (1.45 if outer else 0.75)
			b.position = Vector2.from_angle(ang + TAU * k / ring_n) * r
			b.damage = _damage()
			b.scale = Vector2.ONE * player.area_visual() * 1.3
			b.evolved = true
		return
	for i in n:
		var b: Area2D = _blades[i]
		b.position = Vector2.from_angle(_angle + TAU * i / n) * _radius()
		b.damage = _damage()
		b.scale = Vector2.ONE * player.area_visual()


func _rebuild() -> void:
	for b in _blades:
		b.queue_free()
	_blades.clear()
	for i in _count():
		var b := Blade.new()
		add_child(b)
		_blades.append(b)
