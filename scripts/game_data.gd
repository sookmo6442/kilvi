class_name GameData
extends RefCounted
## 밸런스 수치와 이름을 한곳에 모아 둔 데이터. 숫자는 여기서만 고치면 된다.

const RUN_LENGTH := 1200.0 # 한 판 길이(초). 이때 최종 보스가 나오고, 잡으면 클리어.
const MAX_WEAPONS := 4
const MAX_PASSIVES := 6
const VERSION := "0.8"
const MAX_ENEMIES := 500

const WEAPONS := {
	"kunai": {"name": "쿠나이", "desc": "가장 가까운 적에게 쿠나이를 던진다.", "max_level": 8},
	"shuriken": {"name": "표창", "desc": "킬비 주위를 도는 표창.", "max_level": 8},
	"smoke": {"name": "연기탄", "desc": "발밑에 적을 느리게 하는 연기를 남긴다.", "max_level": 8},
	"bomb": {"name": "기폭수리검", "desc": "아무 방향으로 날아가 적에게 박히고, 2초 뒤 폭발한다. 레벨이 오를수록 폭발이 세지고 커진다.", "max_level": 8},
}

## 첫 레벨업에 반드시 나오는 무기
const EARLY_WEAPON := "bomb"

const PASSIVES := {
	"wraps": {"name": "손목 붕대", "desc": "투사체 +1  (쿠나이 진화 재료)", "max_level": 5},
	"fur": {"name": "검은 털", "desc": "공격 범위 +10%. 쿠나이·표창이 커진다. (표창 진화 재료)", "max_level": 5},
	"collar": {"name": "스파이크 목걸이", "desc": "지속시간 +15%  (연기탄 진화 재료)", "max_level": 5},
	"charm": {"name": "주황 부적", "desc": "공격력 +10%", "max_level": 5},
	"legs": {"name": "단련된 다리", "desc": "이동 속도 +8%", "max_level": 5},
	"ears": {"name": "긴 귀", "desc": "획득 범위 +25%", "max_level": 5},
}

## 진화: 무기가 최대 레벨이고 짝 패시브를 1레벨 이상 갖고 있으면
## 다음 보물 상자에서 진화한다.
const EVOLUTIONS := {
	"kunai": {"passive": "wraps", "name": "쿠나이 폭풍", "desc": "조준 사격과 함께 사방으로 쿠나이를 퍼붓는다."},
	"shuriken": {"passive": "fur", "name": "혼돈의 고리", "desc": "안팎 두 겹의 고리가 서로 반대로 돈다."},
	"smoke": {"passive": "collar", "name": "그림자 안개", "desc": "킬비를 따라다니는 안개가 적에게 표식을 새긴다."},
}

## 특수 스킬: 판 시작 전에 1개만 골라 들고 간다.
const SKILLS := {
	"stealth": {"name": "그림자 은신", "key": "Q", "cooldown": 20.0,
		"desc": "2초간 사라진다. 적은 마지막 자리로 몰리고, 은신 후 첫 쿠나이는 3배 치명타."},
	"log": {"name": "통나무 둔갑", "key": "자동", "cooldown": 25.0,
		"desc": "맞는 순간 통나무를 남기고 빈자리로 이동. 통나무는 적을 2초간 모은 뒤 터진다."},
}

const ENEMIES := {
	"wisp": {"name": "도깨비불", "hp": 4.0, "speed": 38.0, "damage": 5.0, "radius": 7.0, "xp": 1,
		"color": Color(0.55, 0.8, 1.0), "behavior": "chase"},
	"fox": {"name": "여우 자객", "hp": 14.0, "speed": 62.0, "damage": 8.0, "radius": 9.0, "xp": 2,
		"color": Color(0.95, 0.5, 0.2), "behavior": "charge"},
	"crow": {"name": "까마귀 궁수", "hp": 12.0, "speed": 50.0, "damage": 6.0, "radius": 8.0, "xp": 3,
		"color": Color(0.2, 0.2, 0.28), "behavior": "ranged"},
	"turtle": {"name": "돌 거북", "hp": 70.0, "speed": 22.0, "damage": 12.0, "radius": 12.0, "xp": 6,
		"color": Color(0.5, 0.55, 0.5), "behavior": "tank"},
	"bat": {"name": "박쥐", "hp": 6.0, "speed": 85.0, "damage": 5.0, "radius": 6.0, "xp": 2,
		"color": Color(0.35, 0.2, 0.4), "behavior": "swarm"},
	"imp": {"name": "작은 도깨비", "hp": 22.0, "speed": 45.0, "damage": 9.0, "radius": 9.0, "xp": 3,
		"color": Color(0.75, 0.3, 0.3), "behavior": "chase", "split": "wisp"},
	"ninja": {"name": "그림자 닌자", "hp": 30.0, "speed": 55.0, "damage": 10.0, "radius": 8.0, "xp": 5,
		"color": Color(0.12, 0.12, 0.16), "behavior": "ninja"},
}

## 시간대별 등장 비율. [시작 초, {적: 가중치}] — 해당 시각 이후 가장 마지막 항목을 쓴다.
const SPAWN_TABLE := [
	[0.0, {"wisp": 1.0}],
	[60.0, {"wisp": 0.75, "bat": 0.25}],
	[120.0, {"wisp": 0.5, "bat": 0.25, "fox": 0.25}],
	[210.0, {"wisp": 0.35, "bat": 0.2, "fox": 0.25, "imp": 0.2}],
	[300.0, {"wisp": 0.3, "bat": 0.2, "fox": 0.2, "imp": 0.15, "crow": 0.15}],
	[420.0, {"wisp": 0.25, "bat": 0.15, "fox": 0.2, "imp": 0.15, "crow": 0.15, "ninja": 0.1}],
	[600.0, {"wisp": 0.2, "bat": 0.15, "fox": 0.15, "imp": 0.15, "crow": 0.15, "ninja": 0.1, "turtle": 0.1}],
	[900.0, {"wisp": 0.15, "bat": 0.15, "fox": 0.15, "imp": 0.15, "crow": 0.15, "ninja": 0.15, "turtle": 0.1}],
]

## 보스. time초에 등장. mark_limit만큼 표식이 쌓이면 그로기.
const BOSSES := [
	{"id": "big_goblin", "time": 120.0, "name": "큰 도깨비", "hp": 400.0, "speed": 32.0, "damage": 15.0,
		"radius": 18.0, "mark_limit": 12, "color": Color(0.85, 0.3, 0.3)},
	{"id": "gumiho", "time": 420.0, "name": "구미호", "hp": 1500.0, "speed": 42.0, "damage": 18.0,
		"radius": 16.0, "mark_limit": 16, "color": Color(1.0, 0.85, 0.6)},
	{"id": "great_crow", "time": 720.0, "name": "대까마귀", "hp": 3000.0, "speed": 55.0, "damage": 20.0,
		"radius": 18.0, "mark_limit": 20, "color": Color(0.15, 0.12, 0.2)},
	{"id": "moon_hunter", "time": 1200.0, "name": "달의 사냥꾼", "hp": 8000.0, "speed": 70.0, "damage": 25.0,
		"radius": 14.0, "mark_limit": 25, "color": Color(0.9, 0.9, 1.0), "final": true},
]

static func xp_for_level(level: int) -> int:
	var n := level - 1
	return int(5 + n * 10 + n * n * 0.6)
