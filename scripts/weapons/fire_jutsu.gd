extends Weapon
## 인술 · 화둔: 바라보는 방향으로 불덩이를 쏜다. 맞으면 터지고, 폭발에 휘말린 적은 불탄다.
## 매 레벨: 폭발 피해·범위·불탐 피해 증가, 쿨타임 감소 / 3·6레벨: 불덩이 +1

const Fireball := preload("res://scripts/weapons/fireball.gd")


func get_cooldown() -> float:
	return maxf(0.7, tech("fire", "cooldown"))


func _count() -> int:
	return 1 + (1 if level >= 3 else 0) + (1 if level >= 6 else 0)


func fire() -> void:
	var n := _count()
	var aim := player.facing.angle()
	for i in n:
		var b := Fireball.new()
		b.position = player.global_position
		var spread := (i - (n - 1) / 2.0) * 0.22
		b.velocity = Vector2.from_angle(aim + spread) * GameData.TECH.fire.speed
		b.damage = tech("fire", "damage") * player.might
		b.blast_radius = tech("fire", "blast") * player.area
		b.burn_time = GameData.TECH.fire.burn_time * player.duration
		b.burn_dps = tech("fire", "burn_dps") * player.might
		b.life = 1.3 * player.duration
		player.world.add_child(b)
