extends Node2D
## 뇌둔 번개 한 줄기. warn초 동안 바닥에 예고 원을 그리며 목표를 따라가다가 떨어진다.
## 떨어진 자리의 적에게 피해. 맞은 적이 젖어 있으면 근처 젖은 적에게 연쇄로 튄다.

var target: Enemy = null
var damage := 22.0
var radius := 16.0
var _t := 0.0
var _struck := false
var _bolts: Array = [] # 그릴 번개 줄기: [from, to] (전역 좌표)


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	var warn: float = GameData.TECH.thunder.warn
	if not _struck:
		if target and is_instance_valid(target) and not target.dead:
			global_position = target.global_position
		if _t >= warn:
			_strike()
	elif _t >= warn + 0.25:
		queue_free()
		return
	queue_redraw()


func _strike() -> void:
	_struck = true
	var center := global_position
	_bolts.append([center + Vector2(randf_range(-20, 20), -200), center])
	var hit_wet: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		if center.distance_to(enemy.global_position) <= radius + enemy.radius:
			if enemy.wet_left > 0.0:
				hit_wet.append(enemy)
			enemy.take_damage(damage)
	_chain(hit_wet)


## 감전: 젖은 적에서 시작해 가까운 젖은 적으로 chain_max번까지 튄다.
func _chain(start: Array) -> void:
	var t: Dictionary = GameData.TECH.thunder
	var done := {}
	var frontier: Array = start.duplicate()
	for e in start:
		done[e.get_instance_id()] = true
	var jumps := 0
	var dmg := damage * float(t.chain_mult)
	var from_pos := {}
	for e in start:
		from_pos[e.get_instance_id()] = e.global_position
	while not frontier.is_empty() and jumps < int(t.chain_max):
		var src: Enemy = frontier.pop_front()
		var src_pos: Vector2 = from_pos[src.get_instance_id()]
		for e in get_tree().get_nodes_in_group("enemies"):
			var enemy := e as Enemy
			if enemy == null or enemy.dead or enemy.wet_left <= 0.0 or done.has(enemy.get_instance_id()):
				continue
			if src_pos.distance_to(enemy.global_position) <= float(t.chain_range):
				done[enemy.get_instance_id()] = true
				from_pos[enemy.get_instance_id()] = enemy.global_position
				_bolts.append([src_pos, enemy.global_position])
				enemy.take_damage(dmg)
				frontier.append(enemy)
				jumps += 1
				break


func _draw() -> void:
	var warn: float = GameData.TECH.thunder.warn
	if not _struck:
		var k := _t / warn
		draw_arc(Vector2.ZERO, radius, 0, TAU, 20, Color(0.6, 0.85, 1.0, 0.4 + 0.5 * k), 1.0)
		draw_circle(Vector2.ZERO, radius * k, Color(0.6, 0.85, 1.0, 0.25))
		return
	var fade := 1.0 - clampf((_t - warn) / 0.25, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.8, 0.92, 1.0, 0.5 * fade))
	for b in _bolts:
		_draw_bolt(to_local(b[0]), to_local(b[1]), fade)


func _draw_bolt(a: Vector2, b: Vector2, fade: float) -> void:
	var pts := PackedVector2Array([a])
	var n := 6
	var side := (b - a).orthogonal().normalized()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(a.x * 13.0 + b.y * 7.0)
	for i in range(1, n):
		pts.append(a.lerp(b, float(i) / n) + side * rng.randf_range(-6.0, 6.0))
	pts.append(b)
	draw_polyline(pts, Color(0.55, 0.8, 1.0, fade), 3.0)
	draw_polyline(pts, Color(1, 1, 1, fade), 1.2)
