-- Guards the content-authoring path: picture nodes used to be registered from
-- word:lower() but placed from the content item's picture field, so any cue that
-- did not match exactly made set_node raise "Unknown node" and left the board
-- without a word.
local root = (...)
local core = root .. "/../edu_core"
local definitions, nodes = {}, {}
local function key(p) return p.x .. "," .. p.y .. "," .. p.z end

_G.vector = {
	copy = function(p) return {x = p.x, y = p.y, z = p.z} end,
	subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
}

local content = dofile(core .. "/content.lua")
local pack = dofile(core .. "/content/early_en.lua")

-- Every cue in the shipped pack must have a matching texture on disk.
local texture_dir = root .. "/textures/edu_english_blocks_picture_"
for _, item in ipairs(pack.items) do
	if item.type == "word_spelling" then
		local cue = item.picture:lower():gsub("%.png$", "")
		local file = io.open(texture_dir .. cue .. ".png", "rb")
		assert(file, "shipped pack cue '" .. item.picture .. "' has no texture")
		file:close()
	end
end

-- Register a pack whose cue is written with a file extension and different case,
-- which is the mistake an author is most likely to make. Content words are added
-- ahead of the built-in list, so drawing index 1 selects the new word.
assert(content.register_pack({
	id = "author_pack", version = 1, locale = "en",
	items = {
		{
			id = "english:spell-kitten", domain = "english", skill = "cvc_spelling", band = 1,
			type = "word_spelling", prompt = {kind = "picture_to_word", cue = "kitten"},
			word = "KITTEN", answer = "KITTEN", picture = "Kitten.PNG",
			provenance = {source = "original", topic = "animal", status = "reviewed"},
		},
	},
}), "author pack registers")
_G.edu = {content = content}

local warnings = {}
_G.minetest = {
	get_translator = function() return function(text) return text end end,
	get_modpath = function() return root end,
	register_node = function(name, definition) definitions[name] = definition end,
	registered_nodes = definitions,
	register_chatcommand = function() end,
	get_node = function(p) return {name = nodes[key(p)] or "air"} end,
	set_node = function(p, node)
		-- Luanti raises for an unregistered node name.
		assert(definitions[node.name], "set_node on unregistered node " .. node.name)
		nodes[key(p)] = node.name
	end,
	remove_node = function(p) nodes[key(p)] = "air" end,
	get_meta = function() return {set_string = function() end, get_string = function() return "" end} end,
	sound_play = function() end,
	after = function() end,
	add_particlespawner = function() end,
	log = function(level, message) warnings[#warnings + 1] = level .. ": " .. message end,
}

-- Deterministic draw so the board builds the word added by the author pack.
math.random = function() return 1 end

dofile(root .. "/init.lua")

assert(definitions["edu_english_blocks:picture_kitten"], "cue 'Kitten.PNG' registered a picture node")
assert(not definitions["edu_english_blocks:picture_kitten.png"], "cue must not become a node name")

local board = definitions["edu_english_blocks:board"]
local ok, err = pcall(board.on_construct, {x = 0, y = 0, z = 0})
assert(ok, "board construction must not raise: " .. tostring(err))
assert(nodes["-1,1,1"] == "edu_english_blocks:picture_kitten",
	"picture block placed for the content cue, got " .. tostring(nodes["-1,1,1"]))

local missing = table.concat(warnings, " ")
assert(missing:match("missing texture edu_english_blocks_picture_kitten%.png"),
	"missing texture is reported to the author: " .. missing)

print("edu_english_blocks picture asset tests passed")
