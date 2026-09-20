local root = (...)
local nodes, metas, definitions, sounds = {}, {}, {}, {}
local function key(p) return p.x .. "," .. p.y .. "," .. p.z end
local function meta(p)
	local k = key(p)
	metas[k] = metas[k] or {}
	return {
		set_string = function(_, name, value) metas[k][name] = value end,
		get_string = function(_, name) return metas[k][name] or "" end,
	}
end
_G.vector = {
	copy = function(p) return {x = p.x, y = p.y, z = p.z} end,
	subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
}
_G.minetest = {
	get_translator = function() return function(text) return text end end,
	get_modpath = function() return root end,
	register_node = function(name, definition) definitions[name] = definition end,
	registered_nodes = definitions,
	register_chatcommand = function() end,
	get_node = function(p) return {name = nodes[key(p)] or "air"} end,
	chat_send_player = function() end,
	set_node = function(p, node) nodes[key(p)] = node.name end,
	remove_node = function(p) nodes[key(p)] = "air" end,
	get_meta = meta,
	sound_play = function(sound) sounds[#sounds + 1] = sound end,
	after = function() end,
	add_particlespawner = function() end,
}
math.random = function() return 1 end

dofile(root .. "/init.lua")
local board = definitions["edu_english_blocks:board"]
assert(board and board.on_rightclick and board.after_place_node, "board callbacks registered")
assert(definitions["edu_english_blocks:letter_T"].after_place_node, "automatic word callback registered")
local pos = {x = 0, y = 0, z = 0}
local player = {
	get_player_name = function() return "tester" end,
	get_pos = function() return {x = 0, y = 0, z = 0} end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}
-- Board placement initializes the puzzle without requiring a right-click.
board.on_construct(pos)
nodes[key(pos)] = "edu_english_blocks:board"
board.after_place_node(pos, player)
for index, letter in ipairs({"C", "A", "T"}) do
	nodes[key({x = pos.x + index, y = pos.y + 1, z = pos.z})] = "edu_english_blocks:letter_" .. letter
end
definitions["edu_english_blocks:letter_T"].after_place_node({x = pos.x + 3, y = pos.y + 1, z = pos.z}, player)
assert(sounds[#sounds] == "edu_english_blocks_correct", "automatic correct word feedback")

-- Regression: the previous attempt used to survive into the next word, because
-- the clearing loop walked six rays from the board instead of the windows the
-- board actually reads letters from.
for index = 1, 3 do
	assert(nodes[key({x = pos.x + index, y = pos.y + 1, z = pos.z})] == "air",
		"previous word's letter " .. index .. " cleared for the new word")
end
-- Digging the board must not strand the letters and picture it placed.
assert(board.on_destruct, "board cleans up when dug")
for index = 1, 3 do
	nodes[key({x = pos.x + index, y = pos.y + 1, z = pos.z})] = "edu_english_blocks:letter_X"
end
assert(nodes[key({x = pos.x - 1, y = pos.y + 1, z = pos.z + 1})]:match("^edu_english_blocks:picture_"),
	"board placed a picture to clean up")
board.on_destruct(pos)
for index = 1, 3 do
	assert(nodes[key({x = pos.x + index, y = pos.y + 1, z = pos.z})] == "air",
		"letter " .. index .. " removed with the board")
end
assert(nodes[key({x = pos.x - 1, y = pos.y + 1, z = pos.z + 1})] == "air", "picture removed with the board")

print("edu_english_blocks integration tests passed")
