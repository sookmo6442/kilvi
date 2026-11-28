extends Weapon
## 기폭수리검: 아무 방향으로 날아가다 처음 닿은 적에게 박히고, 2초 뒤 폭발한다.
## 레벨 3·6: 개수 +1 / 매 레벨: 폭발 피해·폭발 크기·수리검 크기 증가, 쿨타임 감소

const BombProjectile := preload("res://scripts/weapons/bomb_shuriken_projectile.gd")

const FUSE_TIME := 2.0


func get_cooldown() -> float:
	return 1.8 * (1.0 - 0.03 * (level - 1))


func _count() -> int:
	return 1 + (1 if level >= 3 else 0) + (1 if level >= 6 else 0) + player.extra_projectiles


func explosion_damage() -> float:
	return (14.0 + 7.0 * (level - 1)) * player.might


func explosion_radius() -> float:
	return (30.0 + 5.0 * (level - 1)) * player.area


func fire() -> void:
	var n := _count()
	var base := randf() * TAU
	for i in n:
		var p := BombProjectile.new()
		p.position = player.global_position
		# 아무 방향이지만 여러 개면 서로 겹치지 않게 벌린다
		var ang := base + TAU * i / n + randf_range(-0.4, 0.4)
		p.velocity = Vector2.from_angle(ang) * 200.0
		p.life = 1.4 * player.duration
		p.fuse = FUSE_TIME
		p.damage = explosion_damage()
		p.blast_radius = explosion_radius()
		p.size = (1.0 + 0.08 * (level - 1)) * player.area_visual()
		player.world.add_child(p)
