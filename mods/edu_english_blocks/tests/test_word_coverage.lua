-- Regression: loading a content pack replaced the built-in A-Z word list, so the
-- 26 shipped picture nodes existed only when no pack was loaded. With the starter
-- pack active the activity silently dropped to its three words and retired
-- twenty-three finished textures.
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
assert(content.register_pack(dofile(core .. "/content/early_en.lua")), "starter pack registers")

-- Stand in for edu_core's task-block palette and record what the board publishes.
local published
_G.edu = {
	content = content,
	set_task_blocks = function(name, nodes) published = {name = name, nodes = nodes} end,
}

local function meta(p)
	local k = key(p)
	metas[k] = metas[k] or {}
	return {
		set_string = function(_, name, value) metas[k][name] = value end,
		get_string = function(_, name) return metas[k][name] or "" end,
	}
end

local warnings = {}
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
	log = function(level, message) warnings[#warnings + 1] = level .. ": " .. message end,
}

local minstd = 20260911
math.random = function(low, high)
	minstd = (minstd * 48271) % 2147483647
	if high <= low then return low end
	return low + (minstd % (high - low + 1))
end

dofile(root .. "/init.lua")

-- Every built-in word keeps its picture node and texture while a pack is loaded.
local base = dofile(root .. "/logic.lua").words
assert(#base == 26, "built-in list still holds 26 words, got " .. #base)
for _, word in ipairs(base) do
	local picture = word:lower()
	assert(definitions["edu_english_blocks:picture_" .. picture],
		"picture node for built-in word " .. word .. " must survive a content pack")
	local file = io.open(root .. "/textures/edu_english_blocks_picture_" .. picture .. ".png", "rb")
	assert(file, "missing texture for built-in word " .. word)
	file:close()
end
assert(#warnings == 0, "no missing textures expected: " .. table.concat(warnings, " "))

-- The board places the picture, so digging one must not hand the child a block.
for _, word in ipairs(base) do
	local node = definitions["edu_english_blocks:picture_" .. word:lower()]
	assert(node.drop == "", "picture " .. word:lower() .. " must not drop an item")
end

-- And the activity actually deals those words, not only the three in the pack.
local content_words = {}
for _, item in ipairs(content.find({domain = "english", type = "word_spelling"})) do
	content_words[item.word] = true
end
local board = definitions["edu_english_blocks:board"]
local pos = {x = 0, y = 0, z = 0}
local saw_beyond_pack, previous = false, nil
for _ = 1, 300 do
	board.on_construct(pos)
	local word = metas[key(pos)].word
	assert(word, "board records a word")
	assert(word ~= previous, "puzzle repeated immediately: " .. tostring(word))
	if not content_words[word] then saw_beyond_pack = true end
	previous = word
end
assert(saw_beyond_pack, "words outside the content pack must still be dealt")

-- The palette must offer the current word's own letters plus any pack
-- distractors, rather than the whole alphabet.
local player = {
	get_player_name = function() return "tester" end,
	get_pos = function() return {x = 0, y = 0, z = 0} end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}
board.on_construct(pos)
board.after_place_node(pos, player)
local word = metas[key(pos)].word
assert(published and published.name == "tester", "task blocks published for the player")
local source
for _, item in ipairs(content.find({domain = "english", type = "word_spelling"})) do
	if item.word == word then source = item end
end
local expected = source and content.task_blocks(source) or {}
assert(#published.nodes == #expected,
	"published " .. #published.nodes .. " blocks for " .. word .. ", expected " .. #expected)
for index = 1, #expected do
	assert(published.nodes[index] == expected[index], "published block " .. index .. " matches")
end

print("edu_english_blocks word coverage tests passed")
