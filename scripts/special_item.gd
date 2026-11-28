class_name SpecialItem
extends Node2D
## 땅에 떨어진 특수 아이템. 밟는 순간 바로 발동한다.
## 위아래로 떠다니며 빛나고, 화면 밖이면 가장자리에 화살표가 뜬다.
## LIFE초 동안 안 주우면 마지막 5초 깜빡이다가 사라진다.

signal picked(kind: String)

const LIFE := 30.0
const PICK_RADIUS := 16.0

var kind := "carrot" # bell, charm, sand, carrot
var player: Player
var _t := 0.0
var _life := LIFE


static func spawn(parent: Node, pos: Vector2, k: String, p: Player, on_pick: Callable) -> SpecialItem:
	var it := SpecialItem.new()
	it.kind = k
	it.player = p
	it.position = pos
	it.picked.connect(on_pick)
	parent.add_child.call_deferred(it)
	return it


func _ready() -> void:
	z_index = 1


func _physics_process(delta: float) -> void:
	_t += delta
	_life -= delta
	queue_redraw()
	if _life <= 0.0:
		queue_free()
		return
	if player and not player.is_dead and global_position.distance_to(player.global_position) < PICK_RADIUS:
		picked.emit(kind)
		queue_free()


func _draw() -> void:
	if _life < 5.0 and fmod(_t, 0.25) < 0.1:
		return
	var y := sin(_t * 3.5) * 2.5 - 4.0
	var glow := GameData.ITEMS[kind].color as Color
	draw_circle(Vector2(0, 8), 7.0, Color(0, 0, 0, 0.3))
	draw_circle(Vector2(0, y), 12.0 + sin(_t * 5.0) * 1.5, Color(glow, 0.22))
	match kind:
		"bell": # 금색 방울
			draw_circle(Vector2(0, y + 1), 6.0, Color(1.0, 0.8, 0.25))
			draw_rect(Rect2(-6, y - 1, 12, 2), Color(0.75, 0.5, 0.1))
			draw_circle(Vector2(0, y + 4), 1.5, Color(0.35, 0.2, 0.05))
			draw_line(Vector2(0, y - 5), Vector2(0, y - 8), Color(0.85, 0.2, 0.2), 2.0)
		"charm": # 보라 부적
			draw_rect(Rect2(-4, y - 8, 8, 15), Color(0.95, 0.9, 0.8))
			draw_rect(Rect2(-4, y - 8, 8, 15), Color(0.6, 0.3, 0.9), false, 1.0)
			draw_line(Vector2(0, y - 5), Vector2(0, y + 4), Color(0.55, 0.2, 0.85), 2.0)
			draw_line(Vector2(-2, y - 2), Vector2(2, y - 2), Color(0.55, 0.2, 0.85), 1.0)
		"sand": # 은색 모래주머니
			draw_circle(Vector2(0, y + 2), 6.0, Color(0.8, 0.85, 0.95))
			draw_colored_polygon(PackedVector2Array([Vector2(-3, y - 4), Vector2(3, y - 4), Vector2(1, y - 1), Vector2(-1, y - 1)]), Color(0.65, 0.7, 0.85))
			draw_line(Vector2(-3, y - 2), Vector2(3, y - 2), Color(0.4, 0.55, 1.0), 1.5)
			draw_circle(Vector2(-2, y + 2), 1.0, Color(0.6, 0.8, 1.0))
		"carrot": # 당근
			draw_colored_polygon(PackedVector2Array([Vector2(-4, y - 3), Vector2(4, y - 3), Vector2(0, y + 9)]), Color(1.0, 0.55, 0.15))
			draw_line(Vector2(0, y - 3), Vector2(-3, y - 9), Color(0.3, 0.75, 0.3), 2.0)
			draw_line(Vector2(0, y - 3), Vector2(3, y - 9), Color(0.3, 0.75, 0.3), 2.0)
	draw_offscreen_arrow(self, player, glow)


## 화면 밖에 있으면 화면 가장자리(킬비 기준)에 작은 화살표를 그린다. 임무 표식도 같이 쓴다.
static func draw_offscreen_arrow(node: Node2D, p: Player, col: Color) -> void:
	if p == null:
		return
	var off := node.global_position - p.global_position
	var half := Vector2(300, 160)
	if absf(off.x) < half.x + 10 and absf(off.y) < half.y + 10:
		return
	var k := minf(half.x / maxf(absf(off.x), 0.01), half.y / maxf(absf(off.y), 0.01))
	var at := p.global_position + off * k - node.global_position # node 기준 좌표
	var d := off.normalized()
	var side := d.orthogonal()
	node.draw_colored_polygon(PackedVector2Array([at + d * 7.0, at - d * 4.0 + side * 5.0, at - d * 4.0 - side * 5.0]), col)
	node.draw_polyline(PackedVector2Array([at + d * 7.0, at - d * 4.0 + side * 5.0, at - d * 4.0 - side * 5.0, at + d * 7.0]), Color.BLACK, 1.0)
