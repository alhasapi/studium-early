local root = (...)
local nodes, metas, definitions, sounds = {}, {}, {}, {}
local function key(p) return p.x .. "," .. p.y .. "," .. p.z end
local function meta(p)
	local k = key(p); metas[k] = metas[k] or {}
	return {set_string = function(_, n, v) metas[k][n] = v end, get_string = function(_, n) return metas[k][n] or "" end}
end
_G.vector = {
	copy = function(p) return {x = p.x, y = p.y, z = p.z} end,
	subtract = function(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end,
	add = function(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end,
}
_G.minetest = {
	get_translator = function() return function(s) return s end end,
	get_modpath = function() return root end,
	register_node = function(n, d) definitions[n] = d end,
	register_chatcommand = function() end,
	register_on_player_receive_fields = function() end,
	get_node = function(p) return {name = nodes[key(p)] or "air"} end,
	set_node = function(p, n) nodes[key(p)] = n.name end,
	remove_node = function(p) nodes[key(p)] = "air" end,
	get_meta = meta,
	show_formspec = function() end,
	formspec_escape = function(s) return s end,
	chat_send_player = function() end,
	sound_play = function(s) sounds[#sounds + 1] = s end,
	after = function() end,
	add_particlespawner = function() end,
}
local random_values = {1, 2, 3, 1, 1, 0}
math.random = function() return table.remove(random_values, 1) or 1 end

dofile(root .. "/init.lua")
local board = definitions["edu_number_blocks:board"]
assert(board and board.on_rightclick, "arithmetic board callback registered")
local pos = {x = 0, y = 0, z = 0}
local player = {
	get_player_name = function() return "tester" end,
	get_pos = function() return {x = 0, y = 0, z = 0} end,
	is_player = function() return true end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}
board.on_rightclick(pos, {}, player)
assert(nodes["1,0,0"] == "edu_number_blocks:number_2", "left operand created")
assert(nodes["5,0,0"] == "air", "answer slot is empty")
nodes["5,0,0"] = "edu_number_blocks:number_5"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_number_blocks_correct", "correct arithmetic feedback")
nodes["5,0,0"] = "edu_number_blocks:number_0"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_number_blocks_incorrect", "incorrect arithmetic feedback")
print("edu_number_blocks integration tests passed")
