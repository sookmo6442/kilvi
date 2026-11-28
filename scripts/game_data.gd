class_name GameData
extends RefCounted
## 밸런스 수치와 이름을 한곳에 모아 둔 데이터. 숫자는 여기서만 고치면 된다.

const RUN_LENGTH := 1200.0 # 한 판 길이(초). 이때 최종 보스가 나오고, 잡으면 클리어.
const MAX_WEAPONS := 6
const MAX_PASSIVES := 6
const VERSION := "0.19"
const MAX_ENEMIES := 500

## 갈래: 체술(쿠나이를 쥐고 베기), 비술(닌자 도구), 인술(속성 술법).
## 지금은 레벨업 카드에 갈래를 표시만 한다. 숙련도·마스터는 다음 단계.
const SCHOOLS := {
	"체술": Color(1.0, 0.62, 0.1),
	"비술": Color(0.8, 0.8, 0.85),
	"인술": Color(0.45, 0.75, 1.0),
}

const WEAPONS := {
	"kunai": {"name": "쿠나이", "school": "비술", "desc": "기본 공격 강화. 가장 가까운 적에게 던지는 쿠나이의 피해가 오르고, 짝수 레벨마다 한 자루씩 늘어난다.", "max_level": 8},
	"shuriken": {"name": "표창", "school": "비술", "desc": "킬비 주위를 도는 표창.", "max_level": 8},
	"smoke": {"name": "연기탄", "school": "비술", "desc": "발밑에 적을 느리게 하는 연기를 남긴다.", "max_level": 8},
	"bomb": {"name": "기폭수리검", "school": "비술", "desc": "아무 방향으로 날아가 적에게 박히고, 2초 뒤 폭발한다. 레벨이 오를수록 폭발이 세지고 커진다.", "max_level": 8},
	"gale": {"name": "질풍", "school": "체술", "desc": "[대시 강화] 대시가 지나간 길의 적을 베고, 끝에서 초승달 검기를 휘두른다. 레벨마다 대시가 길어지고, 3·6레벨에 대시를 한 번 더 연달아 쓸 수 있다.", "max_level": 8},
	"burst": {"name": "잔영 폭발", "school": "체술", "desc": "[대시 강화] 대시가 끝나면 도착한 자리가 터진다. 맞고 살아남은 적에게 표식. 4·7레벨에는 지나온 잔영도 차례로 터진다.", "max_level": 8},
	"clone": {"name": "그림자 분신", "school": "체술", "desc": "[대시 강화] 대시 중에 스페이스를 한 번 더 누르면 출발한 자리에 분신이 남아 적을 끌어모으고, 잠시 뒤 터진다.", "max_level": 8},
	"fire": {"name": "화둔", "school": "인술", "desc": "바라보는 방향으로 불덩이를 쏜다. 맞으면 터지고 주변 적이 불탄다.", "max_level": 8},
	"water": {"name": "수둔", "school": "인술", "desc": "적을 따라가는 물 유도탄. 맞으면 물이 튀어 주변 적까지 느려지고 젖는다.", "max_level": 8},
	"thunder": {"name": "뇌둔", "school": "인술", "desc": "랜덤한 적에게 번개가 떨어진다. 젖은 적을 먼저 노리고, 주변 젖은 적에게도 튄다.", "max_level": 8},
}

## 첫 레벨업에 반드시 나오는 무기
const EARLY_WEAPON := "bomb"

const PASSIVES := {
	"wraps": {"name": "손목 붕대", "school": "비술", "desc": "투사체 +1  (쿠나이 진화 재료)", "max_level": 5},
	"fur": {"name": "검은 털", "school": "체술", "desc": "공격 범위 +10%. 쿠나이·표창·베기가 커진다. (표창 진화 재료)", "max_level": 5},
	"collar": {"name": "스파이크 목걸이", "school": "인술", "desc": "지속시간 +15%  (연기탄 진화 재료)", "max_level": 5},
	"charm": {"name": "주황 부적", "school": "인술", "desc": "공격력 +10%", "max_level": 5},
	"legs": {"name": "단련된 다리", "school": "체술", "desc": "이동 속도 +8%", "max_level": 5},
	"ears": {"name": "긴 귀", "school": "체술", "desc": "획득 범위 +25%", "max_level": 5},
}

## 체술·인술 수치. 레벨 l에서 값 = base + per_level * (l - 1)
const TECH := {
	"gale": {"damage": 16.0, "damage_lv": 6.0, "dash_mult": 1.15, "dash_mult_lv": 0.1, "crescent": 26.0, "crescent_lv": 2.0},
	"burst": {"damage": 24.0, "damage_lv": 8.0, "radius": 34.0, "radius_lv": 3.0},
	"clone": {"damage": 30.0, "damage_lv": 10.0, "radius": 46.0, "radius_lv": 4.0, "life": 1.0, "life_lv": 0.1},
	"fire": {"damage": 16.0, "damage_lv": 6.0, "blast": 28.0, "blast_lv": 2.0, "cooldown": 1.8, "cooldown_lv": -0.06, "speed": 210.0, "burn_time": 3.0, "burn_dps": 4.0, "burn_dps_lv": 1.5},
	"water": {"damage": 7.0, "damage_lv": 3.0, "cooldown": 1.4, "cooldown_lv": -0.05, "speed": 170.0, "wet_time": 3.0, "slow_time": 1.5, "splash": 26.0},
	"thunder": {"damage": 22.0, "damage_lv": 8.0, "cooldown": 2.4, "cooldown_lv": -0.1, "radius": 16.0, "warn": 0.35, "chain_range": 80.0, "chain_max": 4, "chain_mult": 0.7},
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
	"flash": {"name": "섬광 베기", "key": "Q", "cooldown": 6.0,
		"desc": "바라보는 방향으로 돌진하며 초승달 검기를 날린다. 검기는 적을 관통하고, 표식이 있는 적은 즉시 처형한다."},
	"stealth": {"name": "그림자 은신", "key": "Q", "cooldown": 20.0,
		"desc": "2초간 사라진다. 적은 마지막 자리로 몰리고, 은신 후 첫 쿠나이는 3배 치명타."},
	"log": {"name": "통나무 둔갑", "key": "자동", "cooldown": 25.0,
		"desc": "맞는 순간 통나무를 남기고 빈자리로 이동. 통나무는 적을 2초간 모은 뒤 터진다."},
}

## 섬광 베기 수치
const FLASH := {"dash_distance": 90.0, "dash_time": 0.14, "damage": 25.0, "boss_marks": 2,
	"wave_speed": 480.0, "wave_life": 0.45, "wave_radius": 22.0}

const ENEMIES := {
	"wisp": {"name": "도깨비불", "hp": 4.0, "speed": 48.0, "damage": 5.0, "radius": 7.0, "xp": 1,
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

## 특수 아이템: 땅에 떨어지고 밟으면 바로 발동. drop은 일반 적 처치 시 확률(합계 약 0.3%).
const ITEMS := {
	"bell": {"name": "모우의 방울", "desc": "경험치 보석을 전부 끌어온다", "color": Color(1.0, 0.8, 0.25), "drop": 0.0005},
	"charm": {"name": "이오나의 정화 부적", "desc": "화면 안 적을 쓸어버린다", "color": Color(0.7, 0.4, 1.0), "drop": 0.0005},
	"sand": {"name": "달빛 모래", "desc": "5초 동안 적이 멈춘다", "color": Color(0.55, 0.75, 1.0), "drop": 0.0005},
	"carrot": {"name": "당근", "desc": "체력 30 회복", "color": Color(1.0, 0.55, 0.15), "drop": 0.0015},
}
const SAND_TIME := 5.0
const CARROT_HEAL := 30.0

## 임무: 처음 MISSION_FIRST초, 그 뒤 MISSION_INTERVAL초마다 하나씩 랜덤(보스전 중에는 쉰다).
## time은 제한 시간. hard면 보상으로 보물 상자와 특수 아이템을 둘 다 준다.
const MISSION_FIRST := 45.0
const MISSION_INTERVAL := 90.0
const MISSIONS := {
	"target": {"name": "표적 암살", "time": 30.0, "hard": false},
	"no_hit": {"name": "무피격", "time": 30.0, "hard": false},
	"scroll": {"name": "두루마리 운반", "time": 40.0, "hard": true, "dist_min": 150.0, "dist_max": 250.0},
	"barrier": {"name": "결계 지키기", "time": 45.0, "hard": true, "radius": 60.0, "hold": 15.0},
}

## 보스. time초에 등장. mark_limit만큼 표식이 쌓이면 그로기.
const BOSSES := [
	{"id": "big_goblin", "time": 120.0, "name": "큰 도깨비", "hp": 650.0, "speed": 32.0, "damage": 15.0,
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
