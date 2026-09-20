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

-- Regression: with two words the old fallback could never select the first word
-- and always selected the second, so a draw matching the previous word repeated
-- the puzzle. Drawing the second word twice must yield the first word.
local draws = {2, 2, 1}
local index = 0
local function scripted(low, high)
	index = index + 1
	local value = draws[index] or low
	if value > high then value = high end
	if value < low then value = low end
	return value
end
local pair = {"CAT", "DOG"}
local first = logic.choose_word(pair, scripted, nil)
check(first == "DOG", "first draw takes the drawn word")
check(logic.choose_word(pair, scripted, first) == "CAT", "two-word draw never repeats")
check(logic.choose_word({}, math.random, nil) == nil, "empty list has no word")
check(logic.choose_word({"CAT"}, math.random, "CAT") == "CAT", "single word is always chosen")
check(logic.choose_word({"CAT"}, math.random, nil) == "CAT", "single word needs no random draw")

-- The same rule must hold for any list length.
local list = {"A", "B", "C", "D", "E"}
local seed = 20260911
local function minstd(low, high)
	seed = (seed * 48271) % 2147483647
	if high <= low then return low end
	return low + (seed % (high - low + 1))
end
local previous
for _ = 1, 500 do
	local word = logic.choose_word(list, minstd, previous)
	check(word ~= previous, "no immediate repeat in a five-word list")
	previous = word
end

print("edu_english_blocks logic tests passed: " .. passed)
