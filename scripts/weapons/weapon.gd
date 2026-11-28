class_name Weapon
extends Node2D
## 모든 무기의 기본형. 쿨타임마다 fire()를 부른다.

var player: Player
var level := 1
var evolved := false
var _cooldown_left := 0.3


func get_cooldown() -> float:
	return 1.0


func fire() -> void:
	pass


## false면 쿨타임이 끝나도 쏘지 않고 기다린다.
func can_fire() -> bool:
	return true


func level_up() -> void:
	level += 1


func evolve() -> void:
	evolved = true


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0 and can_fire():
		_cooldown_left = get_cooldown()
		fire()


func nearest_enemy(max_dist: float = 99999.0) -> Enemy:
	var best: Enemy = null
	var best_d := max_dist * max_dist
	var origin := player.global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var d := origin.distance_squared_to(enemy.global_position)
		if d < best_d:
			best_d = d
			best = enemy
	return best


## GameData.TECH[id]에서 레벨에 맞는 값: base + base_lv * (level - 1)
func tech(id: String, key: String) -> float:
	var d: Dictionary = GameData.TECH[id]
	return d[key] + d.get(key + "_lv", 0.0) * (level - 1)


func enemies_in_radius(center: Vector2, r: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		if center.distance_to(enemy.global_position) <= r + enemy.radius * enemy.size_mult:
			out.append(enemy)
	return out
