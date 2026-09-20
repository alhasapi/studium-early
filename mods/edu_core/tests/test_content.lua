local root = (...)
local content = dofile(root .. "/content.lua")
local pack = dofile(root .. "/content/early_en.lua")

local passed = 0
local function check(condition, message)
	assert(condition, message)
	passed = passed + 1
end

local ok, errors = content.validate_pack(pack)
check(ok, "starter content pack validates: " .. table.concat(errors, "; "))
check(content.register_pack(pack), "starter content pack registers")
check(#content.find({domain = "math", type = "arithmetic_equation"}) >= 3, "math arithmetic items loaded")
check(#content.find({domain = "english", type = "word_spelling"}) >= 3, "english spelling items loaded")
check(#content.find({domain = "logic", type = "visual_pattern"}) >= 3, "logic pattern items loaded")

local duplicate = {
	id = "bad_pack", version = 1, locale = "en",
	items = {
		{id = "math:dup", domain = "math", skill = "addition", band = 1, type = "arithmetic_equation", prompt = {kind = "equation"}, left = 1, op = "+", right = 1, answer = 2, provenance = {status = "reviewed"}},
		{id = "math:dup", domain = "math", skill = "addition", band = 1, type = "arithmetic_equation", prompt = {kind = "equation"}, left = 1, op = "+", right = 2, answer = 3, provenance = {status = "reviewed"}},
	},
}
ok, errors = content.validate_pack(duplicate)
check(not ok and table.concat(errors, " "):match("duplicate item id"), "duplicate item IDs rejected")

local impossible = {
	id = "bad_math", version = 1, locale = "en",
	items = {
		{id = "math:bad-answer", domain = "math", skill = "addition", band = 1, type = "arithmetic_equation", prompt = {kind = "equation"}, left = 2, op = "+", right = 2, answer = 5, provenance = {status = "reviewed"}},
	},
}
ok, errors = content.validate_pack(impossible)
check(not ok and table.concat(errors, " "):match("answer does not match"), "impossible arithmetic rejected")

local bad_node = {
	id = "bad_node", version = 1, locale = "en",
	items = {
		{id = "english:bad-node", domain = "english", skill = "spelling", band = 1, type = "word_spelling", prompt = {kind = "picture_to_word"}, word = "CAT", answer = "CAT", picture = "cat", accepted_nodes = {"not a node"}, provenance = {status = "reviewed"}},
	},
}
ok, errors = content.validate_pack(bad_node)
check(not ok and table.concat(errors, " "):match("unsupported node name"), "unsupported node names rejected")

local function pattern_pack(sequence)
	return {
		id = "bad_pattern", version = 1, locale = "en",
		items = {
			{id = "logic:bad-sequence", domain = "logic", skill = "repeating_patterns", band = 1,
				type = "visual_pattern", prompt = {kind = "missing_item"}, sequence = sequence, answer = "red",
				provenance = {status = "reviewed"}},
		},
	}
end

ok, errors = content.validate_pack(pattern_pack({"red"}))
check(not ok and table.concat(errors, " "):match("at least two items"), "one-item pattern rejected")

local too_long = {}
for index = 1, content.MAX_PATTERN_SEQUENCE + 1 do too_long[index] = "red" end
ok, errors = content.validate_pack(pattern_pack(too_long))
check(not ok and table.concat(errors, " "):match("at most"), "over-long pattern rejected")

ok, errors = content.validate_pack(pattern_pack({"red", 3}))
check(not ok and table.concat(errors, " "):match("sequence entry 2"), "non-string pattern entry rejected")

ok = content.validate_pack(pattern_pack({"red", "blue"}))
check(ok, "two-item pattern accepted")
local at_max = {}
for index = 1, content.MAX_PATTERN_SEQUENCE do at_max[index] = "red" end
check(content.validate_pack(pattern_pack(at_max)), "pattern at the maximum length accepted")

local first = content.choose({domain = "logic"}, function() return 1 end)
local second = content.choose({domain = "logic"}, function() return 1 end, first.id)
check(first.id ~= second.id, "selector avoids immediate repeats when possible")

-- content.pick is the selector every activity uses. With exactly two records the
-- old English fallback could only ever reach the second one, so a draw matching
-- the previous record repeated it.
local pair = {{id = "a"}, {id = "b"}}
local draws = {2, 2, 1}
local index = 0
local function scripted(low, high)
	index = index + 1
	local value = draws[index] or low
	if value > high then value = high end
	if value < low then value = low end
	return value
end
local picked = content.pick(pair, scripted, nil)
check(picked.id == "b", "first draw takes the drawn record")
check(content.pick(pair, scripted, picked.id).id == "a", "two-record draw never repeats")

check(content.pick({}, math.random, nil) == nil, "empty list has no record")
check(content.pick({{id = "only"}}, math.random, "only").id == "only", "single record is chosen as is")

-- A record without an id cannot be excluded, so the list is used unchanged
-- rather than returning nothing.
local anonymous = {{}, {}}
check(content.pick(anonymous, function() return 1 end, nil) ~= nil, "records without ids still selected")

local seed = 20260911
local function minstd(low, high)
	seed = (seed * 48271) % 2147483647
	if high <= low then return low end
	return low + (seed % (high - low + 1))
end
local five = {{id = "a"}, {id = "b"}, {id = "c"}, {id = "d"}, {id = "e"}}
local previous
for _ = 1, 500 do
	local item = content.pick(five, minstd, previous)
	check(item.id ~= previous, "no immediate repeat across a five-record list")
	previous = item.id
end

print("edu_core content tests passed: " .. passed)
