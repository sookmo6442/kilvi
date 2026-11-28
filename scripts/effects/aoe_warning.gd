class_name AoeWarning
extends Node2D
## 바닥 경고 원: delay초 동안 차오른 뒤 범위 안의 킬비에게 피해를 준다.

var radius := 30.0
var delay := 1.0
var damage := 15.0
var player: Player
var color := Color(1.0, 0.25, 0.2)
var _t := 0.0
var _done := false


static func spawn(parent: Node, pos: Vector2, r: float, d: float, dmg: float, p: Player, col: Color = Color(1.0, 0.25, 0.2)) -> void:
	var w := AoeWarning.new()
	w.position = pos
	w.radius = r
	w.delay = d
	w.damage = dmg
	w.player = p
	w.color = col
	parent.add_child(w)


func _ready() -> void:
	z_index = -2


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if not _done and _t >= delay:
		_done = true
		if player and global_position.distance_to(player.global_position) < radius + Player.HIT_RADIUS * 0.5:
			player.take_damage(damage)
	if _t >= delay + 0.2:
		queue_free()


func _draw() -> void:
	if _done:
		draw_circle(Vector2.ZERO, radius, Color(color, 0.6 * (1.0 - (_t - delay) / 0.2)))
		return
	var k := clampf(_t / delay, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(color, 0.12))
	draw_circle(Vector2.ZERO, radius * k, Color(color, 0.25))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(color, 0.8), 1.0)
