class_name Player
extends Node2D
## 킬비. 이동과 대시만 직접 조작하고, 공격은 무기 노드가 자동으로 한다.

signal died
signal leveled_up
signal hp_changed(hp: float, max_hp: float)
signal xp_changed(xp: int, xp_needed: int, level: int)

const KilviVisual := preload("res://scripts/kilvi_visual.gd")
const WEAPON_SCRIPTS := {
	"kunai": preload("res://scripts/weapons/kunai.gd"),
	"shuriken": preload("res://scripts/weapons/shuriken.gd"),
	"smoke": preload("res://scripts/weapons/smoke.gd"),
}

const DASH_DISTANCE := 64.0
const DASH_TIME := 0.12
const DASH_COOLDOWN := 3.0
const INVULN_TIME := 0.5
const HIT_RADIUS := 8.0
const STEALTH_TIME := 1.5
const AMBUSH_MULT := 3.0

var world: Node2D

var max_hp := 80.0
var hp := 80.0
var base_speed := 120.0
var base_pickup := 40.0

# 패시브로 오르는 배율
var might := 1.0
var area := 1.0
var duration := 1.0
var extra_projectiles := 0
var speed_mult := 1.0
var pickup_mult := 1.0

var level := 1
var xp := 0
var xp_needed := GameData.xp_for_level(1)
var pending_levelups := 0

var weapons := {} # id -> Weapon
var passives := {} # id -> level

var facing := Vector2.RIGHT
var move_dir := Vector2.ZERO
var dash_cooldown_left := 0.0
var is_dead := false

## 그림자 은신: 대시하면 잠깐 사라지고, 적은 마지막으로 본 위치를 쫓는다.
var stealth_left := 0.0
var last_seen_position := Vector2.ZERO
## 은신이 끝난 뒤 첫 쿠나이 공격이 치명타가 된다.
var ambush_ready := false

var _invuln := 0.0
var _dash_time := 0.0
var _dash_dir := Vector2.ZERO
var _visual: Node2D


func _ready() -> void:
	_visual = KilviVisual.new()
	_visual.base_scale = 1.4
	_visual.scale = Vector2.ONE * 1.4
	add_child(_visual)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_invuln = maxf(_invuln - delta, 0.0)
	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	if stealth_left > 0.0:
		stealth_left = maxf(stealth_left - delta, 0.0)
	else:
		last_seen_position = global_position

	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir != Vector2.ZERO:
		facing = move_dir.normalized()

	if _dash_time > 0.0:
		_dash_time -= delta
		position += _dash_dir * (DASH_DISTANCE / DASH_TIME) * delta
	else:
		position += move_dir * base_speed * speed_mult * delta
		if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0.0:
			_start_dash()

	_visual.moving = move_dir != Vector2.ZERO
	_visual.dashing = _dash_time > 0.0
	_visual.invulnerable = _invuln > 0.0 and _dash_time <= 0.0 and stealth_left <= 0.0
	_visual.stealthed = stealth_left > 0.0
	_visual.ambush = ambush_ready
	if absf(facing.x) > 0.01:
		_visual.scale = Vector2(signf(facing.x), 1.0) * _visual.base_scale


func _start_dash() -> void:
	_dash_dir = facing
	_dash_time = DASH_TIME
	dash_cooldown_left = DASH_COOLDOWN
	_invuln = maxf(_invuln, DASH_TIME + 0.1)
	last_seen_position = global_position
	stealth_left = STEALTH_TIME
	ambush_ready = true
	if world:
		var puff := preload("res://scripts/effects/smoke_puff.gd").new()
		puff.position = position
		world.add_child(puff)


func is_stealthed() -> bool:
	return stealth_left > 0.0


## 적이 쫓아갈 위치. 은신 중에는 마지막으로 본 자리.
func chase_position() -> Vector2:
	return last_seen_position if stealth_left > 0.0 else global_position


## 기습 치명타를 한 번 꺼내 쓴다. 준비돼 있으면 배율, 아니면 1.
func consume_ambush() -> float:
	if ambush_ready and stealth_left <= 0.0:
		ambush_ready = false
		return AMBUSH_MULT
	return 1.0


func pickup_range() -> float:
	return base_pickup * pickup_mult


func take_damage(amount: float) -> void:
	if is_dead or _invuln > 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	_invuln = INVULN_TIME
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		is_dead = true
		_visual.dead = true
		died.emit()


func heal(amount: float) -> void:
	hp = minf(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)


func grant_levelups(count: int) -> void:
	pending_levelups += count
	leveled_up.emit()


func add_xp(amount: int) -> void:
	if is_dead:
		return
	xp += amount
	var gained := false
	while xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = GameData.xp_for_level(level)
		pending_levelups += 1
		gained = true
	xp_changed.emit(xp, xp_needed, level)
	if gained:
		leveled_up.emit()


func weapon_level(id: String) -> int:
	return weapons[id].level if weapons.has(id) else 0


func passive_level(id: String) -> int:
	return passives.get(id, 0)


func add_or_level_weapon(id: String) -> void:
	if weapons.has(id):
		weapons[id].level_up()
		return
	var w: Weapon = WEAPON_SCRIPTS[id].new()
	w.player = self
	weapons[id] = w
	add_child(w)


func add_passive(id: String) -> void:
	passives[id] = passive_level(id) + 1
	match id:
		"wraps": extra_projectiles += 1
		"fur": area += 0.10
		"collar": duration += 0.15
		"charm": might += 0.10
		"legs": speed_mult += 0.08
		"ears": pickup_mult += 0.25
