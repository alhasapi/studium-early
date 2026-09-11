-- Pure arithmetic logic. Kept independent from the Luanti API for testing.
local logic = {}

function logic.new_puzzle(random)
	local addition = random(1, 2) == 1
	local left = random(0, 10)
	local right = addition and random(0, 10) or random(0, left)
	return {
		left = left,
		right = right,
		op = addition and "+" or "-",
		answer = addition and left + right or left - right,
	}
end

function logic.is_correct(puzzle, answer)
	return type(answer) == "number" and answer == puzzle.answer
end

function logic.number_from_node(node_name)
	local value = node_name:match("^edu_number_blocks:number_(%d+)$")
	return value and tonumber(value) or nil
end

return logic
