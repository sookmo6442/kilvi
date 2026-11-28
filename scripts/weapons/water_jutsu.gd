extends Weapon
## 인술 · 수둔: 적을 끝까지 따라가는 물 유도탄. 맞은 적은 느려지고 젖는다.
## 매 레벨: 피해 증가, 쿨타임 감소 / 2·4·6·8레벨: 유도탄 +1

const WaterBolt := preload("res://scripts/weapons/water_bolt.gd")


func get_cooldown() -> float:
	return maxf(0.6, tech("water", "cooldown"))


func _count() -> int:
	return 1 + int(level / 2)


func fire() -> void:
	# 가까운 적부터 서로 다른 적을 노린다
	var targets := []
	var all := get_tree().get_nodes_in_group("enemies").filter(func(e): return not e.dead)
	all.sort_custom(func(a, b): return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	for i in _count():
		var b := WaterBolt.new()
		b.position = player.global_position
		b.target = all[i % all.size()] if all.size() > 0 else null
		b.velocity = Vector2.from_angle(randf() * TAU) * GameData.TECH.water.speed
		b.damage = tech("water", "damage") * player.might
		b.wet_time = GameData.TECH.water.wet_time * player.duration
		b.slow_time = GameData.TECH.water.slow_time * player.duration
		b.splash_radius = GameData.TECH.water.splash * player.area
		player.world.add_child(b)
