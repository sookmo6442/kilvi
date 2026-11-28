extends Weapon
## 인술 · 뇌둔: 화면 안의 랜덤한 적에게 번개가 떨어진다(바닥 예고 후).
## 젖은 적이 화면에 있으면 그쪽을 먼저 노리고, 근처의 젖은 적에게도 연쇄로 튄다(감전).
## 매 레벨: 피해 증가, 쿨타임 감소 / 3·5·7레벨: 번개 +1

const Strike := preload("res://scripts/effects/lightning_strike.gd")

const SCREEN_HALF := Vector2(320, 180)


func get_cooldown() -> float:
	return maxf(0.8, tech("thunder", "cooldown"))


func _count() -> int:
	return 1 + (1 if level >= 3 else 0) + (1 if level >= 5 else 0) + (1 if level >= 7 else 0)


func fire() -> void:
	var on_screen := []
	var origin := player.global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Enemy
		if enemy == null or enemy.dead:
			continue
		var d := (enemy.global_position - origin).abs()
		if d.x < SCREEN_HALF.x and d.y < SCREEN_HALF.y:
			on_screen.append(enemy)
	on_screen.shuffle()
	# 번개는 젖은 적에게 끌린다: 젖은 적을 먼저 노린다
	var wet := on_screen.filter(func(e): return e.wet_left > 0.0)
	var dry := on_screen.filter(func(e): return e.wet_left <= 0.0)
	on_screen = wet + dry
	for i in mini(_count(), on_screen.size()):
		var s := Strike.new()
		s.target = on_screen[i]
		s.position = on_screen[i].global_position
		s.damage = tech("thunder", "damage") * player.might
		s.radius = GameData.TECH.thunder.radius * player.area
		player.world.add_child(s)
