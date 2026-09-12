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
	register_chatcommand = function() end,
	get_node = function(p) return {name = nodes[key(p)] or "air"} end,
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
assert(board and board.on_rightclick, "board callback registered")
local pos = {x = 0, y = 0, z = 0}
local player = {
	get_player_name = function() return "tester" end,
	get_pos = function() return {x = 0, y = 0, z = 0} end,
	is_player = function() return true end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}
-- First interaction initializes the puzzle without destroying pre-existing blocks.
board.on_rightclick(pos, {}, player)
for index, letter in ipairs({"C", "A", "T"}) do
	nodes[key({x = pos.x + index, y = pos.y + 1, z = pos.z})] = "edu_english_blocks:letter_" .. letter
end
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_english_blocks_correct", "correct word feedback")
print("edu_english_blocks integration tests passed")
