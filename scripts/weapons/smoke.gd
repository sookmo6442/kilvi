extends Weapon
## 연기탄: 발밑에 연기 구름을 남긴다. 안에 있는 적은 느려지고 피해를 입는다.
## 레벨 5: 구름 +1 / 매 레벨: 피해·크기 증가, 쿨타임 감소

const Cloud := preload("res://scripts/weapons/smoke_cloud.gd")


func get_cooldown() -> float:
	return 3.0 - 0.15 * (level - 1)


func fire() -> void:
	var count := 1 + (1 if level >= 5 else 0) + player.extra_projectiles
	for i in count:
		var c := Cloud.new()
		var offset := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(30.0, 60.0)
		c.position = player.global_position + offset
		c.radius = 30.0 * player.area * (1.0 + 0.08 * (level - 1))
		c.life = 2.0 * player.duration
		c.damage = (3.0 + 1.0 * (level - 1)) * player.might
		player.world.add_child(c)
