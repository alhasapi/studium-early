local S = minetest.get_translator("edu_number_blocks")
local puzzles = {}
local logic = dofile(minetest.get_modpath("edu_number_blocks") .. "/logic.lua")
local edu_api = rawget(_G, "edu") or nil
local content = edu_api and edu_api.content or nil
local arithmetic_items = content and content.find({domain = "math", type = "arithmetic_equation"}) or {}
local last_item_by_player = {}

local function new_puzzle(player_name)
	local item = content and content.pick(arithmetic_items, math.random, last_item_by_player[player_name])
	if item then
		last_item_by_player[player_name] = item.id
		return logic.puzzle_from_item(item)
	end
	-- No content pack for this domain: fall back to generated equations.
	last_item_by_player[player_name] = nil
	return logic.new_puzzle(math.random)
end

-- Offer the child the blocks this equation calls for, plus the pack's deliberate
-- wrong answers, instead of every number from 0 to 20.
local function publish_task_blocks(player_name, puzzle)
	if not player_name or not (edu_api and edu_api.set_task_blocks) then return end
	edu_api.set_task_blocks(player_name, content and content.task_blocks(puzzle) or {})
end

-- The board owns the equation row and whatever the child built beside it.
-- Clearing is shared by building a new equation and digging the board, so a
-- removed board does not leave blocks stranded in the world.
local EQUATION_NODES = {
	["edu_number_blocks:plus"] = true,
	["edu_number_blocks:minus"] = true,
	["edu_number_blocks:equals"] = true,
}

local function is_board_node(name)
	return EQUATION_NODES[name] or name:match("^edu_number_blocks:number_%d+$") ~= nil
end

local function clear_equation(pos)
	-- The answer can sit anywhere in the wide, forgiving area beside the board.
	for _, x in ipairs({-2, -1, 0, 5, 6, 7, 8}) do
		for y = -1, 1 do
			for z = -1, 1 do
				local answer_pos = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
				if minetest.get_node(answer_pos).name:match("^edu_number_blocks:number_%d+$") then
					minetest.remove_node(answer_pos)
				end
			end
		end
	end
	for index = 1, 4 do
		local p = {x = pos.x + index, y = pos.y, z = pos.z}
		if is_board_node(minetest.get_node(p).name) then minetest.remove_node(p) end
	end
end

local function build_equation(pos, puzzle, player_name)
	publish_task_blocks(player_name, puzzle)
	clear_equation(pos)
	local nodes = {
		{x = pos.x + 1, name = "edu_number_blocks:number_" .. puzzle.left},
		{x = pos.x + 2, name = puzzle.op == "+" and "edu_number_blocks:plus" or "edu_number_blocks:minus"},
		{x = pos.x + 3, name = "edu_number_blocks:number_" .. puzzle.right},
		{x = pos.x + 4, name = "edu_number_blocks:equals"},
	}
	for _, item in ipairs(nodes) do
		minetest.set_node({x = item.x, y = pos.y, z = pos.z}, {name = item.name})
	end
	-- Leave the fifth position empty for the child to complete.
	minetest.set_node({x = pos.x + 5, y = pos.y, z = pos.z}, {name = "air"})
end

local function show_board(player, message)
	local name = player:get_player_name()
	local puzzle = puzzles[name]
	if not puzzle then
		puzzle = new_puzzle(name)
		puzzles[name] = puzzle
	end
	local text = string.format("%d %s %d = ?", puzzle.left, puzzle.op, puzzle.right)
	if puzzle.pos then
		minetest.get_meta(puzzle.pos):set_string("infotext", S("Equation: @1", text))
	end
	local feedback = message and ("label[1,3.8;" .. minetest.formspec_escape(message) .. "]") or ""
	minetest.show_formspec(name, "edu_number_blocks:board",
		table.concat({
			"formspec_version[4]", "size[8,5]",
			"style_type[label;font_size=20]",
			"label[1,0.7;Complete the equation with a number block:]",
			"label[1,1.7;", text, "]",
			"label[1,2.6;Place your answer in the empty space beside the equation, then check.]", 
			feedback,
			"button[1,4.1;2.5,0.8;check;Check answer]",
			"button[4,4.1;2.5,0.8;close;Done]",
		}, ""))
end

local function flash_message(player, text, color)
	local hud_id = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.5, y = 0.28},
		scale = {x = 10, y = 10},
		alignment = {x = 0, y = 0},
		offset = {x = 0, y = 0},
		text = text,
		number = color,
	})
	minetest.after(2.5, function()
		if player and player:is_player() then
			player:hud_remove(hud_id)
		end
	end)
end

local function visual_feedback(player, correct)
	local name = player:get_player_name()
	local icon = correct and "edu_number_blocks_correct.png" or "edu_number_blocks_incorrect.png"
	local hud_id = player:hud_add({
		type = "image", position = {x = 0.5, y = 0.35}, text = icon,
		scale = {x = 2, y = 2},
	})
	minetest.after(2, function()
		if player and player:is_player() then player:hud_remove(hud_id) end
	end)
	minetest.add_particlespawner({
		amount = correct and 28 or 12, time = 0.5,
		minpos = vector.subtract(player:get_pos(), {x = 0.7, y = 0, z = 0.7}),
		maxpos = vector.add(player:get_pos(), {x = 0.7, y = 1.8, z = 0.7}),
		minvel = {x = -1, y = 1, z = -1}, maxvel = {x = 1, y = 3, z = 1},
		texture = icon,
	})
end

local function answer_matches(pos, puzzle)
	for _, x in ipairs({-2, -1, 0, 5, 6, 7, 8}) do
		for y = -1, 1 do
			for z = -1, 1 do
				local digits = {}
				for length = 0, 1 do
					local node = minetest.get_node({x = pos.x + x + length, y = pos.y + y, z = pos.z + z}).name
					local value = logic.number_from_node(node)
					if value == nil then break end
					if value >= 10 then
						if length == 0 and logic.is_correct(puzzle, value) then return true end
						break
					end
					digits[#digits + 1] = value
					local answer = logic.answer_from_digits(digits)
					if logic.is_correct(puzzle, answer) then return true end
				end
			end
		end
	end
	return false
end

local function check_answer(player)
	local name = player:get_player_name()
	local puzzle = puzzles[name]
	if not puzzle or not puzzle.pos then
		minetest.chat_send_player(name, S("Right-click a puzzle board to create an equation first."))
		return
	end

	-- Accept a single number block or adjacent digit blocks beside the answer.
	if answer_matches(puzzle.pos, puzzle) then
		minetest.sound_play("edu_number_blocks_correct", {to_player = name, gain = 1.3})
		visual_feedback(player, true)
		flash_message(player, "★  CORRECT!  ★", 0x66ff66)
		minetest.chat_send_player(name, "★ CORRECT! A new equation is ready.")
		local next_puzzle = new_puzzle(name)
		next_puzzle.pos = puzzle.pos
		puzzles[name] = next_puzzle
		build_equation(puzzle.pos, next_puzzle, name)
		minetest.chat_send_player(name, S("Wonderful! A new equation is ready."))
	else
		minetest.sound_play("edu_number_blocks_incorrect", {to_player = name, gain = 0.9})
		visual_feedback(player, false)
		flash_message(player, "✦  TRY AGAIN!  ✦", 0xffcc66)
		minetest.chat_send_player(name, S("Not yet. Try a different number block."))
	end
end

minetest.register_node("edu_number_blocks:board", {
	description = S("Arithmetic Puzzle Board (?)"),
	inventory_image = "edu_number_blocks_board.png",
	tiles = {"edu_number_blocks_board.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	after_place_node = function(pos, placer)
		if placer then
			local puzzle = new_puzzle(placer:get_player_name())
			puzzle.pos = vector.copy(pos)
			puzzles[placer:get_player_name()] = puzzle
			build_equation(pos, puzzle, placer:get_player_name())
		end
	end,
	on_destruct = function(pos)
		clear_equation(pos)
	end,
	on_rightclick = function(pos, _node, clicker)
		local name = clicker:get_player_name()
		local puzzle = puzzles[name]
		if not puzzle or not puzzle.pos or puzzle.pos.x ~= pos.x or puzzle.pos.y ~= pos.y or puzzle.pos.z ~= pos.z then
			puzzle = new_puzzle(name)
			puzzle.pos = vector.copy(pos)
			puzzles[name] = puzzle
			build_equation(pos, puzzle, name)
			minetest.chat_send_player(name, S("Build the missing number block, then right-click the board to check it."))
		else
			check_answer(clicker)
		end
	end,
})

for number = 0, 20 do
	local name = "edu_number_blocks:number_" .. number
	minetest.register_node(name, {
		description = S("Number @1", number),
		short_description = S("Number @1", number),
		inventory_image = "edu_number_blocks_number_" .. number .. ".png",
		tiles = {"edu_number_blocks_number_" .. number .. ".png"},
		groups = {choppy = 2, oddly_breakable_by_hand = 2},
		after_place_node = function(_pos, placer)
			local puzzle = placer and puzzles[placer:get_player_name()]
			if puzzle and puzzle.pos then check_answer(placer) end
		end,
		on_construct = function(pos)
			minetest.get_meta(pos):set_string("infotext", S("Number @1", number))
		end,
	})
end

for _, operation in ipairs({"plus", "minus", "equals"}) do
	local symbol = ({plus = "+", minus = "-", equals = "="})[operation]
	minetest.register_node("edu_number_blocks:" .. operation, {
		description = S("Operation @1", symbol),
		short_description = S("Operation @1", symbol),
		inventory_image = "edu_number_blocks_" .. operation .. ".png",
		tiles = {"edu_number_blocks_" .. operation .. ".png"},
		groups = {choppy = 2, oddly_breakable_by_hand = 2},
		on_construct = function(pos)
			minetest.get_meta(pos):set_string("infotext", S("Operation @1", symbol))
		end,
	})
end

minetest.register_chatcommand("edu_blocks", {
	description = S("Give yourself the physical arithmetic puzzle kit"),
	privs = {server = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then return false, S("Player is not online.") end
		local inv = player:get_inventory()
		inv:add_item("main", "edu_number_blocks:board")
		for number = 0, 20 do
			inv:add_item("main", "edu_number_blocks:number_" .. number)
		end
		for _, operation in ipairs({"plus", "minus", "equals"}) do
			inv:add_item("main", "edu_number_blocks:" .. operation)
		end
		return true, S("Puzzle kit added. Place the board and build with blocks.")
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "edu_number_blocks:board" then return false end
	local name = player:get_player_name()
	if fields.close or fields.quit then return true end
	if fields.check then
		local puzzle = puzzles[name]
		if not puzzle then show_board(player, S("Open a board first.")); return true end
		local pos = puzzle.pos
		if not pos then
			show_board(player, S("Open a board first."))
			return true
		end
		if answer_matches(pos, puzzle) then
			minetest.sound_play("edu_number_blocks_correct", {to_player = name, gain = 1.0})
			visual_feedback(player, true)
			local next_puzzle = new_puzzle(name)
			next_puzzle.pos = puzzle.pos
			puzzles[name] = next_puzzle
			build_equation(puzzle.pos, next_puzzle, name)
			show_board(player, S("Wonderful! Build the next answer."))
		else
			minetest.sound_play("edu_number_blocks_incorrect", {to_player = name, gain = 0.8})
			visual_feedback(player, false)
			show_board(player, S("Not yet. Try a different number block."))
		end
		return true
	end
	return true
end)
