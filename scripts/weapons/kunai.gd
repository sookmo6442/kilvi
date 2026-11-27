extends Weapon
## 쿠나이: 가장 가까운 적에게 연달아 던진다.
## 레벨 2·4·6·8: 개수 +1 / 레벨 5·8: 관통 +1 / 매 레벨: 피해 증가, 쿨타임 감소
## 맞힌 적에게 암살 표식을 남긴다. 은신 중에는 던지지 않고 기다렸다가,
## 은신이 끝나면 기습 치명타(3배, 관통 +2)로 던진다.

const KunaiProjectile := preload("res://scripts/weapons/kunai_projectile.gd")


func get_cooldown() -> float:
	var cd := 0.8 * (1.0 - 0.04 * (level - 1))
	return cd * 0.7 if evolved else cd


func _count() -> int:
	return 1 + int(level / 2) + player.extra_projectiles


func _damage() -> float:
	return (6.0 + 2.0 * (level - 1)) * player.might * (1.5 if evolved else 1.0)


func _pierce() -> int:
	return 1 + (1 if level >= 5 else 0) + (1 if level >= 8 else 0)


func can_fire() -> bool:
	return not player.is_stealthed()


func fire() -> void:
	var ambush_mult := player.consume_ambush()
	var crit := ambush_mult > 1.0
	if evolved:
		_storm_burst(ambush_mult, crit)
	var target := nearest_enemy(320.0)
	var base_dir := player.facing
	for i in _count():
		if player == null or player.is_dead:
			return
		if target != null and is_instance_valid(target) and not target.dead:
			base_dir = (target.global_position - player.global_position).normalized()
		var p := KunaiProjectile.new()
		p.position = player.global_position
		p.velocity = base_dir.rotated(randf_range(-0.08, 0.08)) * 300.0
		p.damage = _damage() * ambush_mult
		p.pierce = _pierce() + (2 if crit else 0)
		p.crit = crit
		p.life = 1.2 * player.duration
		player.world.add_child(p)
		if i < _count() - 1:
			await get_tree().create_timer(0.04 if evolved else 0.07, false).timeout
			if not is_instance_valid(self):
				return


## 쿠나이 폭풍: 8방향(+투사체 보너스)으로 한 번에 퍼붓는다.
var _storm_angle := 0.0


func _storm_burst(mult: float, crit: bool) -> void:
	var n := 8 + player.extra_projectiles * 2
	_storm_angle += 0.3
	for i in n:
		var p := KunaiProjectile.new()
		p.position = player.global_position
		p.velocity = Vector2.from_angle(_storm_angle + TAU * i / n) * 260.0
		p.damage = _damage() * 0.6 * mult
		p.pierce = 2 + (2 if crit else 0)
		p.crit = crit
		p.life = 0.9 * player.duration
		player.world.add_child(p)
