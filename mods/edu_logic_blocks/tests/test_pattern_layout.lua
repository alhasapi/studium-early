-- A visual_pattern of any accepted length must put its answer slot after the
-- sequence. The board used to hardcode slot 4, so a two-item pattern left a gap
-- and a four-item pattern overwrote the question marker.
local root = (...)
local core = root .. "/../edu_core"
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

local content = dofile(core .. "/content.lua")
assert(content.register_pack({
	id = "pattern_layout", version = 1, locale = "en",
	items = {
		{
			id = "logic:ab-two-item", domain = "logic", skill = "repeating_patterns", band = 1,
			type = "visual_pattern", prompt = {kind = "missing_item", visual = "AB pattern"},
			sequence = {"red", "blue"}, answer = "red",
			provenance = {source = "original", topic = "AB pattern", status = "reviewed"},
		},
		{
			id = "logic:abcd-four-item", domain = "logic", skill = "repeating_patterns", band = 2,
			type = "visual_pattern", prompt = {kind = "missing_item", visual = "ABCD pattern"},
			sequence = {"blue", "green", "yellow", "red"}, answer = "blue",
			provenance = {source = "original", topic = "ABCD pattern", status = "reviewed"},
		},
	},
}), "pattern pack registers")
_G.edu = {content = content}

dofile(root .. "/init.lua")
local board = definitions["edu_logic_blocks:board"]
local pos = {x = 0, y = 0, z = 0}
local player = {
	get_player_name = function() return "tester" end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}

-- Content selection sorts by id, so the two-item pattern is built first.
board.on_construct(pos)
nodes[key(pos)] = "edu_logic_blocks:board"
assert(nodes["1,1,0"] == "edu_logic_blocks:red", "first sequence block placed")
assert(nodes["2,1,0"] == "edu_logic_blocks:blue", "second sequence block placed")
assert(nodes["3,1,0"] == "edu_logic_blocks:question", "slot follows a two-item pattern")
assert(metas["0,0,0"].values.slot == "3", "two-item slot recorded")
assert(metas["0,0,0"].values.answer == "red", "two-item answer recorded")

board.after_place_node(pos, player)
nodes["3,1,0"] = "edu_logic_blocks:red"
definitions["edu_logic_blocks:red"].after_place_node({x = 3, y = 1, z = 0}, player)
assert(sounds[#sounds] == "edu_logic_blocks_correct", "answer at the two-item slot is accepted")

-- Solving rotates to the other pattern, so the four-item one is built next.
assert(nodes["4,1,0"] == "edu_logic_blocks:red", "fourth sequence block placed")
assert(nodes["5,1,0"] == "edu_logic_blocks:question", "slot follows a four-item pattern")
assert(metas["0,0,0"].values.slot == "5", "four-item slot recorded")

nodes["5,1,0"] = "edu_logic_blocks:blue"
definitions["edu_logic_blocks:blue"].after_place_node({x = 5, y = 1, z = 0}, player)
assert(sounds[#sounds] == "edu_logic_blocks_correct", "answer at the four-item slot is accepted")

-- Back to the two-item pattern: the longer row must not leave stale blocks.
assert(nodes["3,1,0"] == "edu_logic_blocks:question", "slot returns to the two-item position")
assert(nodes["4,1,0"] == "air", "stale four-item block cleared, got " .. tostring(nodes["4,1,0"]))
assert(nodes["5,1,0"] == "air", "stale question marker cleared, got " .. tostring(nodes["5,1,0"]))

print("edu_logic_blocks pattern layout tests passed")
