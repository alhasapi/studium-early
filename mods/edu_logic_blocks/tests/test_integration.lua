local root = (...)
local nodes, metas, definitions, sounds = {}, {}, {}, {}
local function key(p) return p.x .. "," .. p.y .. "," .. p.z end
local function meta(p)
	local k = key(p)
	metas[k] = metas[k] or {values = {}}
	return {
		set_string = function(_, name, value) metas[k].values[name] = value end,
		get_string = function(_, name) return metas[k].values[name] or "" end,
	}
end
_G.vector = {copy = function(p) return {x = p.x, y = p.y, z = p.z} end}
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
	after = function(_, callback) callback() end,
}
math.random = function() return 1 end

dofile(root .. "/init.lua")
local board = definitions["edu_logic_blocks:board"]
assert(board and board.on_construct and board.on_rightclick, "board callbacks registered")
local pos = {x = 0, y = 0, z = 0}
board.on_construct(pos)
assert(nodes["1,1,0"] == "edu_logic_blocks:red", "first pattern block created")
assert(nodes["2,1,0"] == "edu_logic_blocks:blue", "second pattern block created")
assert(nodes["4,1,0"] == "edu_logic_blocks:question", "missing block created")
local player = {
	get_player_name = function() return "tester" end,
	is_player = function() return true end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}
nodes["4,1,0"] = "edu_logic_blocks:blue"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_logic_blocks_correct", "correct answer feedback")
nodes["4,1,0"] = "edu_logic_blocks:red"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_logic_blocks_incorrect", "incorrect answer feedback")
print("edu_logic_blocks integration tests passed")
