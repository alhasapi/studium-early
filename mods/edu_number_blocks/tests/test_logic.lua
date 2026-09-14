local root = (...)
local logic = dofile(root .. "/logic.lua")

local passed = 0
local function check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local values = {1, 7, 10}
local index = 0
local function scripted_random(_low, _high)
	index = index + 1
	return values[index]
end
local addition = logic.new_puzzle(scripted_random)
check(addition.left == 7 and addition.right == 10, "addition operands")
check(addition.op == "+" and addition.answer == 17, "addition answer")

values = {2, 10, 3}
index = 0
local subtraction = logic.new_puzzle(scripted_random)
check(subtraction.left == 10 and subtraction.right == 3, "subtraction operands")
check(subtraction.op == "-" and subtraction.answer == 7, "subtraction answer")
check(subtraction.left >= subtraction.right, "subtraction is non-negative")

check(logic.is_correct(addition, 17), "two-digit correct answer")
check(not logic.is_correct(addition, 16), "wrong answer rejected")
check(not logic.is_correct(addition, "17"), "text answer rejected")
check(logic.number_from_node("edu_number_blocks:number_17") == 17, "two-digit node parsed")
check(logic.number_from_node("edu_number_blocks:number_7") == 7, "single-digit node parsed")
check(logic.number_from_node("default:wood") == nil, "non-number node rejected")
check(logic.answer_from_digits({1, 7}) == 17, "adjacent digit blocks compose two-digit answer")
check(logic.answer_from_digits({0, 7}) == 7, "leading zero remains usable")
check(logic.answer_from_digits({17}) == nil, "multi-digit node is not treated as a digit")

math.randomseed(90210)
for _ = 1, 500 do
	local puzzle = logic.new_puzzle(math.random)
	check(puzzle.answer == (puzzle.op == "+" and puzzle.left + puzzle.right or puzzle.left - puzzle.right), "answer matches equation")
	if puzzle.op == "-" then
		check(puzzle.left >= puzzle.right, "random subtraction is non-negative")
	end
end

print("edu_number_blocks logic tests passed: " .. passed)
