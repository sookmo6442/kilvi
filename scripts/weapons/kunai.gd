extends Weapon
## 쿠나이: 가장 가까운 적에게 연달아 던진다.
## 레벨 2·4·6·8: 개수 +1 / 레벨 5·8: 관통 +1 / 매 레벨: 피해 증가, 쿨타임 감소

const KunaiProjectile := preload("res://scripts/weapons/kunai_projectile.gd")


func get_cooldown() -> float:
	return 0.8 * (1.0 - 0.04 * (level - 1))


func _count() -> int:
	return 1 + int(level / 2) + player.extra_projectiles


func _damage() -> float:
	return (6.0 + 2.0 * (level - 1)) * player.might


func _pierce() -> int:
	return 1 + (1 if level >= 5 else 0) + (1 if level >= 8 else 0)


func fire() -> void:
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
		p.damage = _damage()
		p.pierce = _pierce()
		p.life = 1.2 * player.duration
		player.world.add_child(p)
		if i < _count() - 1:
			await get_tree().create_timer(0.07, false).timeout
			if not is_instance_valid(self):
				return
