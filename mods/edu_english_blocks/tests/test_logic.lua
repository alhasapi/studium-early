local root = ...
local logic = dofile(root .. "/logic.lua")
local passed = 0
local function check(value, message)
	assert(value, message)
	passed = passed + 1
end

check(logic.is_correct("CAT", {"C", "A", "T"}), "CAT accepted")
check(logic.is_correct("FISH", {"F", "I", "S", "H"}), "FISH accepted")
check(not logic.is_correct("CAT", {"C", "A", "R"}), "wrong letter rejected")
check(not logic.is_correct("CAT", {"C", "A"}), "short word rejected")
check(not logic.is_correct("CAT", {"C", "A", "T", "S"}), "long word rejected")
local initials = {}
for _, word in ipairs(logic.words) do initials[word:sub(1, 1)] = true end
for code = string.byte("A"), string.byte("Z") do
	check(initials[string.char(code)], "alphabet coverage for " .. string.char(code))
end
print("edu_english_blocks logic tests passed: " .. passed)
