extends Node2D
## 킬비 임시 그림. 스프라이트가 완성되면 이 노드를 AnimatedSprite2D로 바꾸면 된다.
## 오른쪽을 보는 모습으로 그리고, 왼쪽은 player.gd에서 scale.x = -1 로 뒤집는다.

const BLACK := Color(0.06, 0.06, 0.07)
const HOOD := Color(0.86, 0.83, 0.76)
const LEG := Color(0.80, 0.78, 0.72)
const EYE := Color(1.0, 0.62, 0.1)

var moving := false
var dashing := false
var invulnerable := false
var dead := false
var base_scale := 1.0

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if invulnerable:
		modulate.a = 0.35 if int(_t * 20.0) % 2 == 0 else 1.0
	elif dashing:
		modulate.a = 0.4
	else:
		modulate.a = 1.0
	queue_redraw()


func _draw() -> void:
	if dead:
		rotation = PI / 2.0
	var bob := sin(_t * 14.0) * 1.5 if moving else sin(_t * 3.0) * 0.5
	var step := sin(_t * 14.0) * 2.0 if moving else 0.0

	# 그림자
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)

	# 다리(허벅지 스타킹)
	draw_rect(Rect2(-5 + step, 4, 4, 9), LEG)
	draw_rect(Rect2(1 - step, 4, 4, 9), LEG)
	# 몸통
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6), Vector2(7, 2), Vector2(5, 6), Vector2(-5, 6), Vector2(-7, 2)]), BLACK)
	# 크롭 재킷
	draw_rect(Rect2(-7, -8, 14, 5), HOOD)
	# 쿠나이(허벅지)
	draw_line(Vector2(5, 5), Vector2(6, 11), Color(0.75, 0.75, 0.8), 1.0)
	# 긴 귀
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -17), Vector2(-1, -17), Vector2(-9, -32), Vector2(-11, -30)]), BLACK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(1, -17), Vector2(4, -17), Vector2(9, -33), Vector2(6, -33)]), BLACK)
	# 후드
	draw_circle(Vector2(0, -13), 7.0, HOOD)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -17), Vector2(-3, -23), Vector2(-1, -18)]), HOOD)
	# 얼굴(그림자)
	draw_circle(Vector2(1.5, -12.5), 5.0, BLACK)
	# 주황 눈
	draw_rect(Rect2(0, -14, 2, 3), EYE)
	draw_rect(Rect2(4, -14, 2, 3), EYE)
