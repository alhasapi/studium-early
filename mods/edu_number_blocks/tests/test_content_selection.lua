-- The board must deal equations from a content pack, and rotate away from the one
-- it just used instead of serving the same equation twice.
local root = (...)
local core = root .. "/../edu_core"
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

local content = dofile(core .. "/content.lua")
assert(content.register_pack(dofile(core .. "/content/early_en.lua")), "starter pack registers")

-- Stand in for edu_core's task-block palette and record what the board publishes.
local published
_G.edu = {
	content = content,
	set_task_blocks = function(name, nodes) published = {name = name, nodes = nodes} end,
}

local seed = 20260911
math.random = function(low, high)
	seed = (seed * 48271) % 2147483647
	if high <= low then return low end
	return low + (seed % (high - low + 1))
end

dofile(root .. "/init.lua")
local board = definitions["edu_number_blocks:board"]
local pos = {x = 0, y = 0, z = 0}
local player = {
	get_player_name = function() return "tester" end,
	get_pos = function() return {x = 0, y = 0, z = 0} end,
	is_player = function() return true end,
	hud_add = function() return 1 end,
	hud_remove = function() end,
}

local items = content.find({domain = "math", type = "arithmetic_equation"})
assert(#items > 1, "starter pack has more than one equation")
local function current_item()
	local left = tonumber(tostring(nodes["1,0,0"]):match("number_(%d+)"))
	local op = nodes["2,0,0"] == "edu_number_blocks:plus" and "+" or "-"
	local right = tonumber(tostring(nodes["3,0,0"]):match("number_(%d+)"))
	for _, item in ipairs(items) do
		if item.left == left and item.op == op and item.right == right then return item end
	end
end

local previous, used = nil, {}
for _ = 1, 40 do
	published = nil
	board.after_place_node(pos, player)
	local item = current_item()
	assert(item, "board must deal an equation from the content pack")
	assert(item.id ~= previous, "equation must rotate, repeated " .. item.id)
	-- The palette must offer this equation's own blocks, not all of 0 to 20.
	local expected = content.task_blocks(item)
	assert(published and published.name == "tester", "task blocks published for the player")
	assert(#published.nodes == #expected,
		"published " .. #published.nodes .. " blocks, expected " .. #expected)
	for index = 1, #expected do
		assert(published.nodes[index] == expected[index], "published block " .. index .. " matches")
	end
	used[item.id] = true
	previous = item.id
end
local distinct = 0
for _ in pairs(used) do distinct = distinct + 1 end
assert(distinct == #items, "every pack equation is reachable, saw " .. distinct .. " of " .. #items)

print("edu_number_blocks content selection tests passed")
