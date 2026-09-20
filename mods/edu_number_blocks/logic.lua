-- Pure arithmetic logic. Kept independent from the Luanti API for testing.
local logic = {}

local function puzzle_from_item(item)
	return {
		id = item.id,
		left = item.left,
		right = item.right,
		op = item.op,
		answer = item.answer,
		skill = item.skill,
		band = item.band,
		-- Carried so the activity can offer exactly this task's blocks.
		accepted_nodes = item.accepted_nodes,
		distractor_nodes = item.distractor_nodes,
	}
end
logic.puzzle_from_item = puzzle_from_item

-- Fallback only: content packs are selected by the shared picker in edu_core.
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

function logic.answer_from_digits(digits)
	if type(digits) ~= "table" or #digits == 0 or #digits > 2 then return nil end
	for _, digit in ipairs(digits) do
		if type(digit) ~= "number" or digit < 0 or digit > 9 or digit % 1 ~= 0 then return nil end
	end
	return tonumber(table.concat(digits))
end

return logic
