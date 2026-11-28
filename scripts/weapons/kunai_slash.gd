extends Weapon
## 체술 · 쿠나이 베기: 바라보는 방향 앞을 부채꼴로 벤다. 맞은 적에게 표식 1개.
## 매 레벨: 피해·범위 증가, 쿨타임 감소 / 5레벨부터 반대로 한 번 더 벤다.

const SlashArc := preload("res://scripts/effects/slash_arc.gd")


func get_cooldown() -> float:
	return maxf(0.4, tech("slash", "cooldown"))


func fire() -> void:
	_swing(1.0)
	if level >= int(GameData.TECH.slash.double_from):
		await get_tree().create_timer(0.14, false).timeout
		if is_instance_valid(self) and player and not player.is_dead:
			_swing(-1.0)


func _swing(side: float) -> void:
	var r := tech("slash", "radius") * player.area_visual()
	var half := deg_to_rad(GameData.TECH.slash.arc_deg) / 2.0
	var aim := player.facing.angle()
	var fx := SlashArc.new()
	fx.radius = r
	fx.start_angle = aim - half * side
	fx.sweep = 2.0 * half * side
	fx.follow = player
	fx.color = Color(1.0, 0.85, 0.6)
	player.world.add_child(fx)
	fx.global_position = player.global_position
	var dmg := tech("slash", "damage") * player.might
	for enemy in enemies_in_radius(player.global_position, r):
		var to := enemy.global_position - player.global_position
		if absf(angle_difference(aim, to.angle())) > half + 0.2:
			continue
		enemy.take_damage(dmg, to.normalized() * 110.0)
		if not enemy.dead:
			enemy.add_mark()
