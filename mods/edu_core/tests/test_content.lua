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

local first = content.choose({domain = "logic"}, function() return 1 end)
local second = content.choose({domain = "logic"}, function() return 1 end, first.id)
check(first.id ~= second.id, "selector avoids immediate repeats when possible")

print("edu_core content tests passed: " .. passed)
