class_name CaseLogic
## Evaluates answers for the three reusable case types.
##  choice: answer = option index
##  sort:   answer = Array of step indices in the player's order (data lists steps in correct order)
##  match:  answer = Dictionary {item_index: column_id}


static func check(c: Dictionary, answer: Variant) -> Dictionary:
	match c.get("type", "choice"):
		"choice":
			var opt: Dictionary = c["options"][int(answer)]
			return {"correct": opt.get("correct", false), "feedback": opt.get("feedback", ""), "wrong": []}
		"sort":
			var wrong: Array = []
			var order: Array = answer
			for i in order.size():
				if int(order[i]) != i:
					wrong.append(i)
			return {
				"correct": wrong.is_empty(),
				"feedback": c.get("feedback_ok", "") if wrong.is_empty() else c.get("feedback_bad", ""),
				"wrong": wrong,
			}
		"match":
			var wrong: Array = []
			var items: Array = c["items"]
			var ans: Dictionary = answer
			for i in items.size():
				if ans.get(i, "") != items[i]["answer"]:
					wrong.append(i)
			return {
				"correct": wrong.is_empty(),
				"feedback": c.get("feedback_ok", "") if wrong.is_empty() else c.get("feedback_bad", ""),
				"wrong": wrong,
			}
	return {"correct": false, "feedback": "", "wrong": []}


static func shuffled_indices(n: int, seed_value: int) -> Array:
	var idx: Array = range(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = idx[i]
		idx[i] = idx[j]
		idx[j] = t
	if n > 1 and idx == range(n):
		idx.reverse()
	return idx
