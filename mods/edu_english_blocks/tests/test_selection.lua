-- Regression: the anti-repeat fallback used an index expression that could never
-- select the first word and, with exactly two words, always selected the second.
-- The same puzzle could therefore be served twice in a row.
local root = (...)
local core = root .. "/../edu_core"
local definitions, nodes, metas = {}, {}, {}
local function key(p) return p.x .. "," .. p.y .. "," .. p.z end

_G.vector = {
	copy = function(p) return {x = p.x, y = p.y, z = p.z} end,
	subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
}

local content = dofile(core .. "/content.lua")
assert(content.register_pack({
	id = "two_words", version = 1, locale = "en",
	items = {
		{
			id = "english:spell-cat", domain = "english", skill = "cvc_spelling", band = 1,
			type = "word_spelling", prompt = {kind = "picture_to_word", cue = "cat"},
			word = "CAT", answer = "CAT", picture = "cat",
			provenance = {source = "original", topic = "CVC word", status = "reviewed"},
		},
		{
			id = "english:spell-dog", domain = "english", skill = "cvc_spelling", band = 1,
			type = "word_spelling", prompt = {kind = "picture_to_word", cue = "dog"},
			word = "DOG", answer = "DOG", picture = "dog",
			provenance = {source = "original", topic = "CVC word", status = "reviewed"},
		},
	},
}), "two-word pack registers")
_G.edu = {content = content}

local function meta(p)
	local k = key(p)
	metas[k] = metas[k] or {}
	return {
		set_string = function(_, name, value) metas[k][name] = value end,
		get_string = function(_, name) return metas[k][name] or "" end,
	}
end

_G.minetest = {
	get_translator = function() return function(text) return text end end,
	get_modpath = function() return root end,
	register_node = function(name, definition) definitions[name] = definition end,
	registered_nodes = definitions,
	register_chatcommand = function() end,
	get_node = function(p) return {name = nodes[key(p)] or "air"} end,
	set_node = function(p, node)
		assert(definitions[node.name], "set_node on unregistered node " .. node.name)
		nodes[key(p)] = node.name
	end,
	remove_node = function(p) nodes[key(p)] = "air" end,
	get_meta = meta,
	sound_play = function() end,
	after = function() end,
	add_particlespawner = function() end,
	log = function() end,
}

-- Scripted draws. With two words the old code took the two-word path where the
-- fallback index always resolved to the second word, so drawing the second word
-- twice in a row repeated the puzzle. The new code excludes the previous word,
-- so the second draw only has one candidate left.
local scripted = {2, 2, 1}
local draw = 0
math.random = function(low, high)
	draw = draw + 1
	local value = scripted[draw] or low
	if value > high then value = high end
	if value < low then value = low end
	return value
end

dofile(root .. "/init.lua")
local board = definitions["edu_english_blocks:board"]
local pos = {x = 0, y = 0, z = 0}

board.on_construct(pos)
local first = metas[key(pos)].word
assert(first == "DOG", "first puzzle is the drawn word, got " .. tostring(first))
board.on_construct(pos)
local second = metas[key(pos)].word
assert(second == "CAT", "second puzzle must differ from the first, got " .. tostring(second))

-- Over a longer run every consecutive pair of puzzles must differ.
local minstd = 20260911
math.random = function(low, high)
	minstd = (minstd * 48271) % 2147483647
	if high <= low then return low end
	return low + (minstd % (high - low + 1))
end
local seen, previous = {}, nil
for _ = 1, 200 do
	board.on_construct(pos)
	local word = metas[key(pos)].word
	assert(word, "board records a word")
	assert(word ~= previous, "puzzle repeated immediately: " .. tostring(word))
	seen[word] = true
	previous = word
end
assert(seen.CAT and seen.DOG, "both words are offered across puzzles")

print("edu_english_blocks selection tests passed")
