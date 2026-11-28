extends Weapon
## 체술 기술의 자리표시 노드. 스스로 공격하지 않고, player.gd의 대시가
## weapon_level("gale"/"leap"/"kick")을 보고 동작을 바꾼다.


func get_cooldown() -> float:
	return 9999.0


func can_fire() -> bool:
	return false
