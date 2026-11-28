extends Node2D
## 잔영 폭발: 대시가 지나간 자리의 잔영이 출발점부터 차례로 터지고, 마지막에 도착점이 크게 터진다.
## points[i]가 delays[i]초 뒤에 radii[i] 크기로 터진다. 맞은 적 중 살아남으면 표식 1개.

const Explosion := preload("res://scripts/effects/explosion.gd")

var points: Array = []
var delays: Array = []
var radii: Array = []
var damage := 20.0
var _t := 0.0
var _next := 0


func _process(delta: float) -> void:
	_t += delta
	while _next < points.size() and _t >= delays[_next]:
		_blow(points[_next], radii[_next])
		_next += 1
	if _next >= points.size():
		queue_free()


func _blow(at: Vector2, r: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var to: Vector2 = enemy.global_position - at
		if to.length() < r + enemy.radius * enemy.size_mult:
			enemy.take_damage(damage, to.normalized() * 160.0)
			if not enemy.dead:
				enemy.add_mark()
	var fx: Node2D = Explosion.new()
	fx.position = at
	fx.radius = r
	fx.color = Color(0.55, 0.3, 0.95)
	get_parent().add_child(fx)
