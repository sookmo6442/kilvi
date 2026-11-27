class_name Weapon
extends Node2D
## 모든 무기의 기본형. 쿨타임마다 fire()를 부른다.

var player: Player
var level := 1
var _cooldown_left := 0.3


func get_cooldown() -> float:
	return 1.0


func fire() -> void:
	pass


func level_up() -> void:
	level += 1


func _physics_process(delta: float) -> void:
	if player == null or player.is_dead:
		return
	_cooldown_left -= delta
	if _cooldown_left <= 0.0:
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
