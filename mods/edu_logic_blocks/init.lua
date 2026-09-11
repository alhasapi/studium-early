local S = minetest.get_translator("edu_logic_blocks")
local logic = dofile(minetest.get_modpath("edu_logic_blocks") .. "/logic.lua")
local puzzles = {}
local colors = {"red", "blue", "yellow", "green"}

local function choose_pattern()
	return logic.patterns[math.random(1, #logic.patterns)]
end

local function color_from_node(name)
	return name:match("^edu_logic_blocks:(%a+)$")
end

local function clear_slots(pos)
	for x = 1, 4 do
		local p = {x = pos.x + x, y = pos.y + 1, z = pos.z}
		if color_from_node(minetest.get_node(p).name) then minetest.remove_node(p) end
	end
end

local function build_pattern(pos, pattern)
	clear_slots(pos)
	for index, color in ipairs(pattern.sequence) do
		minetest.set_node({x = pos.x + index, y = pos.y + 1, z = pos.z}, {
			name = "edu_logic_blocks:" .. color,
		})
	end
	minetest.set_node({x = pos.x + 4, y = pos.y + 1, z = pos.z}, {
		name = "edu_logic_blocks:question",
	})
	minetest.get_meta(pos):set_string("answer", pattern.answer)
end

local function feedback(player, correct)
	minetest.sound_play(correct and "edu_logic_blocks_correct" or "edu_logic_blocks_incorrect", {
		to_player = player:get_player_name(), gain = 1.0,
	})
	local hud = player:hud_add({
		type = "image", position = {x = 0.5, y = 0.35},
		text = correct and "edu_logic_blocks_correct.png" or "edu_logic_blocks_incorrect.png",
		scale = {x = 2, y = 2},
	})
	minetest.after(2, function()
		if player:is_player() then player:hud_remove(hud) end
	end)
end

minetest.register_node("edu_logic_blocks:board", {
	description = S("Pattern Board"),
	inventory_image = "default_wood.png", tiles = {"default_wood.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	on_construct = function(pos)
		build_pattern(pos, choose_pattern())
	end,
	on_rightclick = function(pos, _node, player)
		local name = player:get_player_name()
		local answer = color_from_node(minetest.get_node({x = pos.x + 4, y = pos.y + 1, z = pos.z}).name)
		local target = minetest.get_meta(pos):get_string("answer")
		if logic.is_correct({answer = target}, answer) then
			feedback(player, true)
			build_pattern(pos, choose_pattern())
		else
			feedback(player, false)
		end
		puzzles[name] = true
	end,
})

for _, color in ipairs(colors) do
	minetest.register_node("edu_logic_blocks:" .. color, {
		description = S("@1 pattern block", color),
		inventory_image = "edu_logic_blocks_" .. color .. ".png",
		tiles = {"edu_logic_blocks_" .. color .. ".png"},
		groups = {choppy = 2, oddly_breakable_by_hand = 2},
	})
end

minetest.register_node("edu_logic_blocks:question", {
	description = S("Missing pattern block"),
	inventory_image = "edu_logic_blocks_question.png",
	tiles = {"edu_logic_blocks_question.png"},
	groups = {not_in_creative_inventory = 1},
})

minetest.register_chatcommand("edu_logic", {
	description = S("Give yourself the pattern puzzle kit"), privs = {server = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return false, S("Player is not online.") end
		local inv = player:get_inventory()
		inv:add_item("main", "edu_logic_blocks:board")
		for _, color in ipairs(colors) do inv:add_item("main", "edu_logic_blocks:" .. color) end
		return true, S("Pattern puzzle kit added.")
	end,
})
