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
print("edu_english_blocks logic tests passed: " .. passed)
