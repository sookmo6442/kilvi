extends Node2D
## 표적을 처치하면 떨어지는 보물 상자.
## 진화할 수 있는 무기가 있으면 진화시키고, 없으면 레벨업 1~3회.

var player: Player
var _t := 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if player and not player.is_dead and global_position.distance_to(player.global_position) < 16.0:
		var evo_id := player.evolvable_weapon()
		if evo_id != "":
			player.evolve_weapon(evo_id)
		else:
			var roll := randf()
			player.grant_levelups(3 if roll < 0.1 else (2 if roll < 0.4 else 1))
		queue_free()


func _draw() -> void:
	var y := sin(_t * 4.0) * 1.5
	draw_circle(Vector2(0, 8), 7.0, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(-8, -6 + y, 16, 11), Color(0.45, 0.25, 0.12))
	draw_rect(Rect2(-8, -6 + y, 16, 4), Color(0.6, 0.35, 0.15))
	draw_rect(Rect2(-2, -3 + y, 4, 4), Color(1.0, 0.62, 0.1))
	draw_arc(Vector2(0, y), 12.0 + sin(_t * 6.0) * 2.0, 0, TAU, 20, Color(1.0, 0.62, 0.1, 0.4), 1.0)
