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
	registered_nodes = definitions,
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
assert(board and board.on_construct and board.on_rightclick and board.after_place_node, "board callbacks registered")
assert(definitions["edu_logic_blocks:blue"].after_place_node, "automatic answer callback registered")
local pos = {x = 0, y = 0, z = 0}
board.on_construct(pos)
nodes[key(pos)] = "edu_logic_blocks:board"
assert(nodes["1,1,0"] == "edu_logic_blocks:red", "first pattern block created")
assert(nodes["2,1,0"] == "edu_logic_blocks:blue", "second pattern block created")
assert(nodes["4,1,0"] == "edu_logic_blocks:question", "missing block created")
local player = {
	get_player_name = function() return "tester" end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}
board.after_place_node(pos, player)
nodes["4,1,0"] = "edu_logic_blocks:blue"
definitions["edu_logic_blocks:blue"].after_place_node({x = 4, y = 1, z = 0}, player)
assert(sounds[#sounds] == "edu_logic_blocks_correct", "automatic correct answer feedback")
nodes["4,1,0"] = "edu_logic_blocks:red"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_logic_blocks_incorrect", "incorrect answer feedback")

-- Regression: a correct block placed one node below the slot leaves the question
-- marker inside the tolerance box. The marker used to be read as the answer, so
-- a correctly placed block was reported as wrong.
nodes["4,1,0"] = "edu_logic_blocks:question"
nodes["4,0,0"] = "edu_logic_blocks:blue"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_logic_blocks_correct", "correct block below the slot is accepted")

nodes["4,0,0"] = "air"
nodes["4,2,0"] = "edu_logic_blocks:blue"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_logic_blocks_correct", "correct block above the slot is accepted")

-- The question marker on its own must never count as an answer.
nodes["4,2,0"] = "air"
nodes["4,1,0"] = "edu_logic_blocks:question"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_logic_blocks_incorrect", "question marker is not an answer")

nodes["4,1,0"] = "edu_logic_blocks:blue"
nodes["3,1,0"] = "edu_logic_blocks:red"
board.on_rightclick(pos, {}, player)
assert(sounds[#sounds] == "edu_logic_blocks_correct", "block in the slot wins over a stray block")

-- Digging the board must not strand the pattern row.
assert(board.on_destruct, "board cleans up when dug")
board.on_destruct(pos)
for index = 1, 4 do
	assert(nodes[index .. ",1,0"] == "air", "pattern slot " .. index .. " removed with the board")
end

print("edu_logic_blocks integration tests passed")
