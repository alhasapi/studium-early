-- Pure question generation for the arithmetic kiosk.
-- Kept independent from the Luanti API so it can be tested in plain Lua.
local logic = {}

function logic.make_question(random)
	local left = random(0, 10)
	local right = random(0, 10)
	local addition = random(1, 2) == 1

	if addition then
		return {text = string.format("%d + %d = ?", left, right), answer = left + right}
	end

	-- Keep subtraction answers non-negative for early learners.
	if right > left then
		left, right = right, left
	end
	return {text = string.format("%d - %d = ?", left, right), answer = left - right}
end

function logic.is_correct(question, answer)
	return type(answer) == "number" and question ~= nil and answer == question.answer
end

return logic
