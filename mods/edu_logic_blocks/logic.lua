local logic = {}
logic.patterns = {
	{sequence = {"red", "blue", "red"}, answer = "blue"},
	{sequence = {"yellow", "green", "yellow"}, answer = "green"},
	{sequence = {"red", "blue", "green"}, answer = "yellow"},
}

function logic.is_correct(pattern, answer)
	return answer == pattern.answer
end

return logic
