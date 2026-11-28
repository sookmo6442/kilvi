class_name Player
extends Node2D
## 킬비. 이동과 대시만 직접 조작하고, 공격은 무기 노드가 자동으로 한다.

signal died
signal leveled_up
signal hp_changed(hp: float, max_hp: float)
signal xp_changed(xp: int, xp_needed: int, level: int)
signal weapon_evolved(weapon_id: String)

const KilviVisual := preload("res://scripts/kilvi_visual.gd")
const OverheadBars := preload("res://scripts/ui/overhead_bars.gd")
const WEAPON_SCRIPTS := {
	"kunai": preload("res://scripts/weapons/kunai.gd"),
	"shuriken": preload("res://scripts/weapons/shuriken.gd"),
	"smoke": preload("res://scripts/weapons/smoke.gd"),
	"bomb": preload("res://scripts/weapons/bomb_shuriken.gd"),
	"gale": preload("res://scripts/weapons/body_tech.gd"),
	"burst": preload("res://scripts/weapons/body_tech.gd"),
	"clone": preload("res://scripts/weapons/body_tech.gd"),
	"fire": preload("res://scripts/weapons/fire_jutsu.gd"),
	"water": preload("res://scripts/weapons/water_jutsu.gd"),
	"thunder": preload("res://scripts/weapons/thunder_jutsu.gd"),
}

const DASH_DISTANCE := 64.0
const DASH_TIME := 0.12
const DASH_COOLDOWN := 2.0
const INVULN_TIME := 0.5
const HIT_RADIUS := 8.0
const STEALTH_TIME := 2.0
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


## 공격 범위가 눈에 보이도록 크기는 범위 증가분의 2배로 키운다.
## (검은 털 5레벨 = 범위 1.5배 → 쿠나이·표창 크기 2배)
func area_visual() -> float:
	return 1.0 + (area - 1.0) * 2.0

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

## 특수 스킬: 판마다 1개. GameData.SKILLS의 id.
var skill_id := ""
var skill_cooldown_left := 0.0
## 통나무 둔갑으로 남긴 통나무. 살아 있는 동안 적이 이쪽으로 몰려간다.
var decoy: Node2D = null

var _invuln := 0.0
var _dash_time := 0.0
var _dash_dir := Vector2.ZERO
var _dash_speed := 0.0
var _visual: Node2D


func _ready() -> void:
	_visual = KilviVisual.new()
	_visual.base_scale = 1.4
	_visual.scale = Vector2.ONE * 1.4
	add_child(_visual)
	add_child(OverheadBars.new())


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_invuln = maxf(_invuln - delta, 0.0)
	_recharge_dash(delta)
	skill_cooldown_left = maxf(skill_cooldown_left - delta, 0.0)
	if stealth_left > 0.0:
		stealth_left = maxf(stealth_left - delta, 0.0)
	else:
		last_seen_position = global_position
	if Input.is_action_just_pressed("skill"):
		use_skill()

	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir != Vector2.ZERO:
		facing = move_dir.normalized()

	_double_grace = maxf(_double_grace - delta, 0.0)
	if _dash_time > 0.0:
		_dash_time -= delta
		position += _dash_dir * _dash_speed * delta
		if _body_dash:
			_update_body_dash(delta)
		if _dash_time <= 0.0:
			_double_grace = DOUBLE_GRACE
		if Input.is_action_just_pressed("dash"):
			_try_clone()
	else:
		position += move_dir * base_speed * speed_mult * delta
		_handle_dash_input(delta)

	_visual.moving = move_dir != Vector2.ZERO
	_visual.dashing = _dash_time > 0.0 and not _body_dash_visible()
	_visual.invulnerable = _invuln > 0.0 and _dash_time <= 0.0 and stealth_left <= 0.0
	_visual.stealthed = stealth_left > 0.0
	_visual.ambush = ambush_ready
	if absf(facing.x) > 0.01:
		_visual.scale = Vector2(signf(facing.x), 1.0) * _visual.base_scale


func _body_dash_visible() -> bool:
	# 체술을 하나라도 들면 대시 중에도 몸이 보이고 잔상이 남는다
	return weapon_level("gale") > 0 or weapon_level("burst") > 0 or weapon_level("clone") > 0


func _start_dash() -> void:
	dash_charges -= 1
	if dash_cooldown_left <= 0.0:
		dash_cooldown_left = DASH_COOLDOWN
	_dash_dir = facing
	# 질풍 레벨이 오를수록 더 멀리 간다(시간은 조금만 늘려 더 빨라 보이게)
	var mult := _body_tech("gale", "dash_mult") if weapon_level("gale") > 0 else 1.0
	_dash_time = DASH_TIME * sqrt(mult)
	_dash_speed = DASH_DISTANCE * mult / _dash_time
	_invuln = maxf(_invuln, _dash_time + 0.1)
	_body_dash = _body_dash_visible()
	_gale_hit.clear()
	_dash_start = position
	_afterimage_t = 0.0
	_clone_ready = weapon_level("clone") > 0
	_spawn_puff(position)


# --- 체술: 대시 버튼을 강화한다 ------------------------------------------
# 질풍(gale): 대시가 지나간 길의 적을 베고, 끝에서 초승달 검기를 휘두른다.
#   레벨마다 대시가 길어지고, 3·6레벨에 대시 충전 +1.
# 잔영 폭발(burst): 대시가 끝나면 도착점이 터진다. 4·7레벨에는 지나온 잔영도 차례로 터진다.
# 그림자 분신(clone): 대시 중(또는 끝난 직후 DOUBLE_GRACE초)에 한 번 더 누르면
#   출발한 자리에 분신이 남아 적을 끌어모았다가 터진다. 대시 충전은 쓰지 않는다.
const DOUBLE_GRACE := 0.15
const Afterimage := preload("res://scripts/effects/afterimage.gd")
const GaleTrail := preload("res://scripts/effects/gale_trail.gd")
const SlashArc := preload("res://scripts/effects/slash_arc.gd")
const BurstChain := preload("res://scripts/effects/burst_chain.gd")
const ShadowClone := preload("res://scripts/effects/shadow_clone.gd")

var dash_charges := 1
var _body_dash := false
var _gale_hit := {}
var _dash_start := Vector2.ZERO
var _afterimage_t := 0.0
var _clone_ready := false # 이번 대시에서 분신을 아직 안 남겼다
var _double_grace := 0.0


func max_dash_charges() -> int:
	var lv := weapon_level("gale")
	return 1 + (1 if lv >= 3 else 0) + (1 if lv >= 6 else 0)


func _recharge_dash(delta: float) -> void:
	var cap := max_dash_charges()
	if dash_charges >= cap:
		dash_charges = cap
		dash_cooldown_left = 0.0
		return
	dash_cooldown_left -= delta
	if dash_cooldown_left <= 0.0:
		dash_charges += 1
		dash_cooldown_left = DASH_COOLDOWN if dash_charges < cap else 0.0


func _body_tech(id: String, key: String) -> float:
	var d: Dictionary = GameData.TECH[id]
	return d[key] + d.get(key + "_lv", 0.0) * (weapon_level(id) - 1)


func _handle_dash_input(_delta: float) -> void:
	if not Input.is_action_just_pressed("dash"):
		return
	# 대시가 막 끝났을 때 누른 것도 분신으로 받아 준다(두 번 빠르게 누르기)
	if _double_grace > 0.0 and _clone_ready:
		_try_clone()
		return
	if dash_charges > 0:
		_start_dash()


func _update_body_dash(delta: float) -> void:
	_afterimage_t -= delta
	if _afterimage_t <= 0.0:
		_afterimage_t = 0.025
		_spawn_afterimage()
	if weapon_level("gale") > 0:
		var r := 12.0 * area_visual()
		var dmg := _body_tech("gale", "damage") * might
		for e in get_tree().get_nodes_in_group("enemies"):
			var enemy := e as Enemy
			if enemy == null or enemy.dead or _gale_hit.has(enemy.get_instance_id()):
				continue
			if position.distance_to(enemy.global_position) <= r + enemy.radius * enemy.size_mult:
				_gale_hit[enemy.get_instance_id()] = true
				enemy.take_damage(dmg, _dash_dir.orthogonal() * (90.0 if randf() < 0.5 else -90.0))
	if _dash_time <= 0.0:
		_body_dash = false
		if weapon_level("gale") > 0 and world:
			var trail := GaleTrail.new()
			trail.from = _dash_start
			trail.to = position
			world.add_child(trail)
			_gale_crescent()
		if weapon_level("burst") > 0 and world:
			_burst()


func _spawn_afterimage() -> void:
	if world == null:
		return
	var a := Afterimage.new()
	a.position = position + _visual.position
	a.visual_scale = _visual.scale
	a.visual_rotation = _visual.rotation
	world.add_child(a)


## 질풍: 대시 끝에서 앞쪽으로 초승달 검기를 휘두른다. 검기 안의 적은 질풍 피해를 한 번 더 받는다.
func _gale_crescent() -> void:
	var r := _body_tech("gale", "crescent") * area_visual()
	var fx: Node2D = SlashArc.new()
	fx.position = position
	fx.radius = r
	fx.sweep = 2.8 * (1.0 if randf() < 0.5 else -1.0)
	fx.start_angle = _dash_dir.angle() - fx.sweep / 2.0
	fx.duration = 0.1
	fx.color = Color(1.0, 0.75, 0.35)
	world.add_child(fx)
	var dmg := _body_tech("gale", "damage") * might
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var to := enemy.global_position - position
		if to.length() <= r + enemy.radius * enemy.size_mult and to.dot(_dash_dir) > -4.0:
			enemy.take_damage(dmg, to.normalized() * 120.0)


## 잔영 폭발: 지나온 길(4·7레벨)과 도착점이 차례로 터진다.
func _burst() -> void:
	var lv := weapon_level("burst")
	var trail_points := 0 if lv < 4 else (2 if lv < 7 else 4)
	var r := _body_tech("burst", "radius") * area
	var chain: Node2D = BurstChain.new()
	chain.damage = _body_tech("burst", "damage") * might
	var t := 0.05
	for i in trail_points:
		var k := float(i + 1) / float(trail_points + 1)
		chain.points.append(_dash_start.lerp(position, k))
		chain.delays.append(t)
		chain.radii.append(r * 0.6)
		t += 0.06
	chain.points.append(position)
	chain.delays.append(t + 0.04)
	chain.radii.append(r)
	world.add_child(chain)


## 그림자 분신: 출발한 자리에 분신을 남긴다. 한 번의 대시에 하나.
func _try_clone() -> void:
	if not _clone_ready or world == null:
		return
	_clone_ready = false
	_double_grace = 0.0
	var c: Node2D = ShadowClone.new()
	c.player = self
	c.position = _dash_start
	c.facing_x = signf(_visual.scale.x)
	c.life = _body_tech("clone", "life")
	c.radius = _body_tech("clone", "radius") * area
	c.damage = _body_tech("clone", "damage") * might
	world.add_child(c)
	_spawn_puff(_dash_start)


func _spawn_puff(at: Vector2) -> void:
	if world:
		var puff := preload("res://scripts/effects/smoke_puff.gd").new()
		puff.position = at
		world.add_child(puff)


func skill_cooldown() -> float:
	return GameData.SKILLS[skill_id].cooldown if skill_id != "" else 1.0


## Q 키로 쓰는 스킬. 자동 스킬(통나무 둔갑)은 여기서 아무것도 하지 않는다.
func use_skill() -> void:
	if is_dead or skill_id == "" or skill_cooldown_left > 0.0:
		return
	if skill_id == "stealth":
		skill_cooldown_left = skill_cooldown()
		last_seen_position = global_position
		stealth_left = STEALTH_TIME
		ambush_ready = true
		_spawn_puff(position)
	elif skill_id == "flash":
		_flash_slash()


## 섬광 베기: 바라보는 방향으로 빠르게 돌진하며 초승달 검기를 날린다.
func _flash_slash() -> void:
	var f: Dictionary = GameData.FLASH
	skill_cooldown_left = skill_cooldown()
	_dash_dir = facing
	_dash_time = f.dash_time
	_dash_speed = f.dash_distance / f.dash_time
	_invuln = maxf(_invuln, f.dash_time + 0.15)
	var wave := preload("res://scripts/effects/flash_wave.gd").new()
	wave.position = position
	wave.direction = facing
	wave.damage = f.damage * might
	wave.size = area_visual()
	wave.life = f.wave_life * duration
	world.add_child(wave)


## 통나무 둔갑: 맞는 순간 통나무를 남기고 빈자리로 순간이동한다.
func _try_substitution() -> bool:
	if skill_id != "log" or skill_cooldown_left > 0.0:
		return false
	skill_cooldown_left = skill_cooldown()
	var log_node: Node2D = preload("res://scripts/effects/log_decoy.gd").new()
	log_node.position = position
	log_node.player = self
	world.add_child(log_node)
	decoy = log_node
	_spawn_puff(position)
	position = _find_escape_spot()
	_spawn_puff(position)
	_invuln = 0.6
	return true


func _find_escape_spot() -> Vector2:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best := position
	var best_score := INF
	for i in 12:
		var cand := position + Vector2.from_angle(randf() * TAU) * randf_range(80.0, 140.0)
		var score := 0.0
		for e in enemies:
			var d: float = cand.distance_to(e.global_position)
			if d < 60.0:
				score += 60.0 - d
		if score < best_score:
			best_score = score
			best = cand
	return best


func is_stealthed() -> bool:
	return stealth_left > 0.0


## 적이 쫓아갈 위치. 통나무가 있으면 통나무, 은신 중에는 마지막으로 본 자리.
func chase_position() -> Vector2:
	if decoy != null and is_instance_valid(decoy):
		return decoy.global_position
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
	if _try_substitution():
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


## 진화할 수 있는 무기 id. 없으면 "".
func evolvable_weapon() -> String:
	for id in weapons:
		var w: Weapon = weapons[id]
		var evo: Dictionary = GameData.EVOLUTIONS.get(id, {})
		if evo.is_empty() or w.evolved:
			continue
		if w.level >= GameData.WEAPONS[id].max_level and passive_level(evo.passive) > 0:
			return id
	return ""


func evolve_weapon(id: String) -> void:
	weapons[id].evolve()
	weapon_evolved.emit(id)


func add_passive(id: String) -> void:
	passives[id] = passive_level(id) + 1
	match id:
		"wraps": extra_projectiles += 1
		"fur": area += 0.10
		"collar": duration += 0.15
		"charm": might += 0.10
		"legs": speed_mult += 0.08
		"ears": pickup_mult += 0.25
