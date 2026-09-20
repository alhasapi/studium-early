local logic = {}
logic.patterns = {
	{id = "logic:builtin-ab-red-blue", sequence = {"red", "blue", "red"}, answer = "blue"},
	{id = "logic:builtin-ab-yellow-green", sequence = {"yellow", "green", "yellow"}, answer = "green"},
	{id = "logic:builtin-abc-red-blue-green", sequence = {"red", "blue", "green"}, answer = "yellow"},
}

function logic.is_correct(pattern, answer)
	return answer == pattern.answer
end

return logic
