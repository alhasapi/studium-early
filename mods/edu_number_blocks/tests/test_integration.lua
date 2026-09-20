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
local random_values = {1, 2, 3, 2, 10, 10, 1, 1, 0}
math.random = function() return table.remove(random_values, 1) or 1 end

dofile(root .. "/init.lua")
local board = definitions["edu_number_blocks:board"]
assert(board and board.on_rightclick and board.after_place_node, "arithmetic board callbacks registered")
assert(definitions["edu_number_blocks:number_5"].after_place_node, "automatic answer callback registered")
local pos = {x = 0, y = 0, z = 0}
local player = {
	get_player_name = function() return "tester" end,
	get_pos = function() return {x = 0, y = 0, z = 0} end,
	is_player = function() return true end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}
board.after_place_node(pos, player)
assert(nodes["1,0,0"] == "edu_number_blocks:number_2", "left operand created")
assert(nodes["5,0,0"] == "air", "answer slot is empty")
nodes["5,0,0"] = "edu_number_blocks:number_5"
local previous_sound = sounds[#sounds]
definitions["edu_number_blocks:number_5"].after_place_node({x = 5, y = 0, z = 0}, player)
assert(sounds[#sounds] == "edu_number_blocks_correct" and sounds[#sounds] ~= previous_sound, "automatic correct arithmetic feedback")
nodes["5,0,0"] = "edu_number_blocks:number_1"
definitions["edu_number_blocks:number_1"].after_place_node({x = 5, y = 0, z = 0}, player)
nodes["6,0,0"] = "edu_number_blocks:number_0"
definitions["edu_number_blocks:number_0"].after_place_node({x = 6, y = 0, z = 0}, player)
assert(sounds[#sounds] == "edu_number_blocks_correct", "automatic two-digit arithmetic feedback")
nodes["5,0,0"] = "edu_number_blocks:number_0"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_number_blocks_incorrect", "incorrect arithmetic feedback")
-- Digging the board must not strand the equation or the answer beside it.
assert(board.on_destruct, "board cleans up when dug")
board.on_destruct(pos)
for index = 1, 4 do
	assert(nodes[index .. ",0,0"] == "air", "equation node " .. index .. " removed with the board")
end
assert(nodes["5,0,0"] == "air", "answer block removed with the board")
assert(nodes["6,0,0"] == "air", "second answer block removed with the board")

print("edu_number_blocks integration tests passed")
