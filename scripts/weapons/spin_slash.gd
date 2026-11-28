extends Weapon
## 체술 · 회전 베기: 주기적으로 킬비 주위를 한 바퀴 벤다.
## 매 레벨: 피해·범위 증가, 쿨타임 감소

const SlashArc := preload("res://scripts/effects/slash_arc.gd")


func get_cooldown() -> float:
	return maxf(0.8, tech("spin", "cooldown"))


func fire() -> void:
	var r := tech("spin", "radius") * player.area_visual()
	var fx := SlashArc.new()
	fx.radius = r
	fx.start_angle = player.facing.angle()
	fx.sweep = TAU
	fx.duration = 0.22
	fx.follow = player
	fx.color = Color(1.0, 0.75, 0.4)
	player.world.add_child(fx)
	fx.global_position = player.global_position
	var dmg := tech("spin", "damage") * player.might
	for enemy in enemies_in_radius(player.global_position, r):
		var to := enemy.global_position - player.global_position
		enemy.take_damage(dmg, to.normalized() * 140.0)
