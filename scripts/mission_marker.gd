extends Node2D
## 임무 표식: 두루마리, 도착 지점, 결계 원. 화면 밖이면 가장자리에 화살표가 뜬다.

var kind := "scroll" # scroll, goal, barrier
var player: Player
var radius := 60.0
var progress := 0.0 # 결계: 0~1
var carried := false # 두루마리: 킬비가 들고 있음
var _t := 0.0

const SCROLL_COLOR := Color(0.95, 0.85, 0.55)
const GOAL_COLOR := Color(0.4, 1.0, 0.55)
const BARRIER_COLOR := Color(0.55, 0.75, 1.0)


func _ready() -> void:
	z_index = 1 if kind == "scroll" else -1


func _process(delta: float) -> void:
	_t += delta
	if kind == "scroll" and carried and player:
		global_position = player.global_position + Vector2(0, -34)
	queue_redraw()


func _draw() -> void:
	match kind:
		"scroll":
			var y := 0.0 if carried else sin(_t * 3.5) * 2.0 - 3.0
			if not carried:
				draw_circle(Vector2(0, 7), 6.0, Color(0, 0, 0, 0.3))
				draw_circle(Vector2(0, y), 11.0 + sin(_t * 5.0) * 1.5, Color(SCROLL_COLOR, 0.25))
			draw_rect(Rect2(-6, y - 3, 12, 6), Color(0.95, 0.9, 0.75))
			draw_rect(Rect2(-8, y - 4, 3, 8), Color(0.6, 0.15, 0.15))
			draw_rect(Rect2(5, y - 4, 3, 8), Color(0.6, 0.15, 0.15))
			draw_line(Vector2(-3, y), Vector2(3, y), Color(0.3, 0.2, 0.1), 1.0)
			if not carried:
				SpecialItem.draw_offscreen_arrow(self, player, SCROLL_COLOR)
		"goal":
			var r := 16.0 + sin(_t * 4.0) * 2.0
			draw_circle(Vector2.ZERO, r, Color(GOAL_COLOR, 0.15))
			draw_arc(Vector2.ZERO, r, 0, TAU, 28, Color(GOAL_COLOR, 0.9), 2.0)
			draw_line(Vector2(0, -2), Vector2(0, -26), Color(0.4, 0.3, 0.2), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(1, -26), Vector2(14, -22), Vector2(1, -17)]), GOAL_COLOR)
			SpecialItem.draw_offscreen_arrow(self, player, GOAL_COLOR)
		"barrier":
			var pulse := 0.5 + 0.5 * sin(_t * 3.0)
			draw_circle(Vector2.ZERO, radius, Color(BARRIER_COLOR, 0.08 + 0.05 * pulse))
			draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(BARRIER_COLOR, 0.5), 1.5)
			if progress > 0.0:
				draw_arc(Vector2.ZERO, radius - 3, -PI / 2, -PI / 2 + TAU * progress, 48, Color(1.0, 1.0, 1.0, 0.85), 3.0)
			# 가운데 문양
			for i in 4:
				var a := _t * 0.6 + TAU * i / 4.0
				draw_line(Vector2.from_angle(a) * 8.0, Vector2.from_angle(a) * 18.0, Color(BARRIER_COLOR, 0.6), 1.5)
			SpecialItem.draw_offscreen_arrow(self, player, BARRIER_COLOR)
