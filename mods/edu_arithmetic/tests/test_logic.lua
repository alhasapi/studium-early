local root = ...
local logic = dofile(root .. "/logic.lua")
local passed = 0
local function check(value, message)
	assert(value, message)
	passed = passed + 1
end

local values, index
local function scripted()
	index = index + 1
	return values[index]
end

values, index = {3, 4, 1}, 0
local addition = logic.make_question(scripted)
check(addition.text == "3 + 4 = ?", "addition text: " .. addition.text)
check(addition.answer == 7, "addition answer")
check(logic.is_correct(addition, 7), "correct answer accepted")
check(not logic.is_correct(addition, 8), "wrong answer rejected")
check(not logic.is_correct(addition, "7"), "text answer rejected")
check(not logic.is_correct(nil, 7), "missing question rejected")

values, index = {9, 4, 2}, 0
local subtraction = logic.make_question(scripted)
check(subtraction.text == "9 - 4 = ?", "subtraction text: " .. subtraction.text)
check(subtraction.answer == 5, "subtraction answer")

values, index = {4, 9, 2}, 0
local swapped = logic.make_question(scripted)
check(swapped.text == "9 - 4 = ?", "operands swap to keep the result non-negative: " .. swapped.text)
check(swapped.answer == 5, "swapped subtraction answer")

check(logic.make_question(function() return 0 end).answer == 0, "zero operands are allowed")

math.randomseed(4242)
for _ = 1, 400 do
	local question = logic.make_question(math.random)
	check(question.answer >= 0, "answer is never negative")
	local left, op, right = question.text:match("^(%d+) ([%+%-]) (%d+) = %?$")
	check(left ~= nil, "question text parses: " .. question.text)
	left, right = tonumber(left), tonumber(right)
	check(question.answer == (op == "+" and left + right or left - right), "answer matches text")
	if op == "-" then check(left >= right, "subtraction operands stay ordered") end
	check(logic.is_correct(question, question.answer), "generated answer accepted")
end

print("edu_arithmetic logic tests passed: " .. passed)
