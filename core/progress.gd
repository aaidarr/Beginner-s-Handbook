class_name Progress
## Pure functions: adaptation progress derived from GameState + Content.

const W_QUESTS := 0.50
const W_CASES := 0.20
const W_CARDS := 0.15
const W_TEST := 0.15
const PASS_RATIO := 0.7

const STATUSES := [
	[1.0, "Готов к работе"],
	[0.7, "Почти свой"],
	[0.3, "Осваиваюсь"],
	[0.0, "Новичок"],
]


static func quests() -> Vector2i:
	var mq: Array = Quests.mandatory()
	var done := 0
	for q in mq:
		if GameState.quests_done.has(q["id"]):
			done += 1
	return Vector2i(done, mq.size())


static func cases() -> Vector2i:
	var total := 0
	var done := 0
	for id in Content.cases:
		if Content.cases[id].get("optional", false):
			continue
		total += 1
		if GameState.cases.has(id):
			done += 1
	return Vector2i(done, total)


static func cards(section_id := "") -> Vector2i:
	var total := 0
	var done := 0
	for c in Content.cards.values():
		if not c.has("learn"):
			continue
		if section_id != "" and c.get("section", "") != section_id:
			continue
		total += 1
		if GameState.studied.has(c["id"]):
			done += 1
	return Vector2i(done, total)


static func test_passed() -> bool:
	for r in GameState.quiz_results:
		if r.get("passed", false):
			return true
	return false


static func best_test() -> Dictionary:
	var best := {}
	for r in GameState.quiz_results:
		if best.is_empty() or float(r["score"]) / r["total"] > float(best["score"]) / best["total"]:
			best = r
	return best


static func ratio(v: Vector2i) -> float:
	return 0.0 if v.y == 0 else float(v.x) / v.y


static func overall() -> float:
	return W_QUESTS * ratio(quests()) + W_CASES * ratio(cases()) \
		+ W_CARDS * ratio(cards()) + W_TEST * (1.0 if test_passed() else 0.0)


static func status(p := -1.0) -> String:
	if p < 0.0:
		p = overall()
	for s in STATUSES:
		if p >= s[0] - 0.0001:
			return s[1]
	return "Новичок"


## Checklist stage progress. Day items are quests (auto); week/month are manual.
static func stage(stage_id: String) -> Vector2i:
	if stage_id == "day":
		return quests()
	var items: Array = Content.checklist.get(stage_id, {}).get("items", [])
	var done := 0
	for it in items:
		if GameState.checklist_manual.has(it["id"]):
			done += 1
	return Vector2i(done, items.size())
