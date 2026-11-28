extends Node2D
## 킬비 머리 위에 작게 뜨는 체력 바와 대시 바.
## 대시 충전이 여러 개면 대시 바가 칸으로 나뉘고, 다음 칸이 차오르는 모습이 보인다.

const WIDTH := 22.0
const Y := -54.0 # 귀 끝(-46) 바로 위
const HP_H := 3.0
const DASH_H := 2.0
const GAP := 1.0
const HP_COLOR := Color(0.9, 0.22, 0.26)
const HP_LOW := Color(1.0, 0.55, 0.3)
const DASH_COLOR := Color(1.0, 0.62, 0.2)
const DASH_EMPTY := Color(0.22, 0.15, 0.08)
const BG := Color(0, 0, 0, 0.7)

var _t := 0.0


func _ready() -> void:
	z_index = 50
	z_as_relative = false


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var p: Node = get_parent()
	if p == null or p.is_dead:
		return
	var x := -WIDTH / 2.0
	# 체력: 30% 아래면 깜빡인다
	var ratio := clampf(p.hp / p.max_hp, 0.0, 1.0)
	draw_rect(Rect2(x - 1, Y - 1, WIDTH + 2, HP_H + DASH_H + GAP + 2), BG)
	var hp_col := HP_COLOR
	if ratio < 0.3 and fmod(_t, 0.5) < 0.25:
		hp_col = HP_LOW
	draw_rect(Rect2(x, Y, roundf(WIDTH * ratio), HP_H), hp_col)

	# 대시: 칸마다 충전 상태
	var cap: int = p.max_dash_charges()
	var charges: int = p.dash_charges
	var progress := 1.0 - clampf(p.dash_cooldown_left / p.DASH_COOLDOWN, 0.0, 1.0)
	var y := Y + HP_H + GAP
	var seg_gap := 1.0 if cap > 1 else 0.0
	var seg_w := (WIDTH - seg_gap * (cap - 1)) / cap
	for i in cap:
		var sx := x + i * (seg_w + seg_gap)
		draw_rect(Rect2(sx, y, seg_w, DASH_H), DASH_EMPTY)
		var fill := 1.0 if i < charges else (progress if i == charges else 0.0)
		if fill > 0.0:
			draw_rect(Rect2(sx, y, roundf(seg_w * fill), DASH_H), DASH_COLOR if i < charges else DASH_COLOR.darkened(0.25))
