class_name GameData
extends RefCounted
## 밸런스 수치와 이름을 한곳에 모아 둔 데이터. 숫자는 여기서만 고치면 된다.

const RUN_LENGTH := 300.0 # 프로토타입 한 판 길이(초). 설계상 정식 판은 1200초.
const MAX_WEAPONS := 3
const MAX_PASSIVES := 6
const MAX_ENEMIES := 350

const WEAPONS := {
	"kunai": {"name": "쿠나이", "desc": "가장 가까운 적에게 쿠나이를 던진다.", "max_level": 8},
	"shuriken": {"name": "표창", "desc": "킬비 주위를 도는 표창.", "max_level": 8},
	"smoke": {"name": "연기탄", "desc": "발밑에 적을 느리게 하는 연기를 남긴다.", "max_level": 8},
}

const PASSIVES := {
	"wraps": {"name": "손목 붕대", "desc": "투사체 +1", "max_level": 3},
	"fur": {"name": "검은 털", "desc": "공격 범위 +10%", "max_level": 5},
	"collar": {"name": "스파이크 목걸이", "desc": "지속시간 +15%", "max_level": 5},
	"charm": {"name": "주황 부적", "desc": "공격력 +10%", "max_level": 5},
	"legs": {"name": "단련된 다리", "desc": "이동 속도 +8%", "max_level": 5},
	"ears": {"name": "긴 귀", "desc": "획득 범위 +25%", "max_level": 5},
}

## 특수 스킬: 판 시작 전에 1개만 골라 들고 간다.
const SKILLS := {
	"stealth": {"name": "그림자 은신", "key": "Q", "cooldown": 20.0,
		"desc": "2초간 사라진다. 적은 마지막 자리로 몰리고,\n   은신 후 첫 쿠나이는 3배 치명타."},
	"log": {"name": "통나무 둔갑", "key": "자동", "cooldown": 25.0,
		"desc": "맞는 순간 통나무를 남기고 빈자리로 이동.\n   통나무는 적을 2초간 모은 뒤 터진다."},
}

const ENEMIES := {
	"wisp": {"name": "도깨비불", "hp": 4.0, "speed": 38.0, "damage": 5.0, "radius": 7.0, "xp": 1,
		"color": Color(0.55, 0.8, 1.0), "behavior": "chase"},
	"fox": {"name": "여우 자객", "hp": 14.0, "speed": 62.0, "damage": 8.0, "radius": 9.0, "xp": 2,
		"color": Color(0.95, 0.5, 0.2), "behavior": "charge"},
}

static func xp_for_level(level: int) -> int:
	return 5 + (level - 1) * 7
