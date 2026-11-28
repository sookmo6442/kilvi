# 킬비 프로젝트 규칙

- 엔진: Godot 4.3 이상, GDScript. 씬은 `scenes/main.tscn` 하나이고 나머지는 코드로 만든다.
- 밸런스 수치(적, 보스, 무기, 스킬, 스폰표)는 `scripts/game_data.gd`에 모은다.
- 버전: `GameData.VERSION`과 `project.godot`의 `config/version`을 함께 올린다. 화면 오른쪽 아래에 표시된다.
- **테스트 빌드 이름:** 사용자에게 빌드를 보낼 때는 항상 `kilvi_test_(버전).zip` 형식으로 보낸다 (예: `kilvi_test_0.6.zip`). 기능 이름을 붙이지 않는다.
  - `git archive --format=zip --prefix=kilvi/ -o kilvi_test_X.Y.zip <브랜치>`로 만든다.
- 작업은 기능 브랜치에서 하고 PR로 main에 합친다. 사용자가 직접 Merge한다.
