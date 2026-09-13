local S = minetest.get_translator("edu_number_blocks")
local puzzles = {}
local logic = dofile(minetest.get_modpath("edu_number_blocks") .. "/logic.lua")

local function new_puzzle()
	return logic.new_puzzle(math.random)
end

local function build_equation(pos, puzzle)
	-- Remove an old answer block, including one placed slightly off-center.
	for _, x in ipairs({-2, -1, 0, 5, 6, 7, 8}) do
		for y = -1, 1 do
			for z = -1, 1 do
				local answer_pos = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
				local old_name = minetest.get_node(answer_pos).name
				if old_name:match("^edu_number_blocks:number_%d+$") then
					minetest.remove_node(answer_pos)
				end
			end
		end
	end
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
		puzzle = new_puzzle()
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

local function check_answer(player)
	local name = player:get_player_name()
	local puzzle = puzzles[name]
	if not puzzle or not puzzle.pos then
		minetest.chat_send_player(name, S("Right-click a puzzle board to create an equation first."))
		return
	end

	-- Accept a number block beside the answer space, regardless of which
	-- side the child is looking from. Do not inspect the four equation slots.
	local correct_block = false
	for _, x in ipairs({-2, -1, 0, 5, 6, 7, 8}) do
		for y = -1, 1 do
			for z = -1, 1 do
				local node = minetest.get_node({x = puzzle.pos.x + x, y = puzzle.pos.y + y, z = puzzle.pos.z + z}).name
				local value = logic.number_from_node(node)
				if logic.is_correct(puzzle, value) then
					correct_block = true
				end
			end
		end
	end
	if correct_block then
		minetest.sound_play("edu_number_blocks_correct", {to_player = name, gain = 1.3})
		visual_feedback(player, true)
		flash_message(player, "★  CORRECT!  ★", 0x66ff66)
		minetest.chat_send_player(name, "★ CORRECT! A new equation is ready.")
		local next_puzzle = new_puzzle()
		next_puzzle.pos = puzzle.pos
		puzzles[name] = next_puzzle
		build_equation(puzzle.pos, next_puzzle)
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
	on_rightclick = function(pos, _node, clicker)
		local name = clicker:get_player_name()
		local puzzle = puzzles[name]
		if not puzzle or not puzzle.pos or puzzle.pos.x ~= pos.x or puzzle.pos.y ~= pos.y or puzzle.pos.z ~= pos.z then
			puzzle = new_puzzle()
			puzzle.pos = vector.copy(pos)
			puzzles[name] = puzzle
			build_equation(pos, puzzle)
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
		local answer
		-- Use the same forgiving placement scan as the physical board check.
		for _, x in ipairs({-2, -1, 0, 5, 6, 7, 8}) do
			for y = -1, 1 do
				for z = -1, 1 do
					local node = minetest.get_node({x = pos.x + x, y = pos.y + y, z = pos.z + z}).name
					local value = logic.number_from_node(node)
					if value ~= nil then answer = value end
				end
			end
		end
		if answer == puzzle.answer then
			minetest.sound_play("edu_number_blocks_correct", {to_player = name, gain = 1.0})
			visual_feedback(player, true)
			local next_puzzle = new_puzzle()
			next_puzzle.pos = puzzle.pos
			puzzles[name] = next_puzzle
			build_equation(puzzle.pos, next_puzzle)
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
