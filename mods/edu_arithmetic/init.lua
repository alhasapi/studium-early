local S = minetest.get_translator("edu_arithmetic")
local logic = dofile(minetest.get_modpath("edu_arithmetic") .. "/logic.lua")
local quiz = {}

local function make_question()
	return logic.make_question(math.random)
end

local function show_quiz(player, message)
	local name = player:get_player_name()
	local question = quiz[name]
	if not question then
		question = make_question()
		quiz[name] = question
	end

	local progress = edu.get_progress(name)
	local feedback = message and ("label[1,6.05;" .. edu.escape(message) .. "]") or ""
	local formspec = table.concat({
			"formspec_version[4]",
			"size[12,8]",
			"style_type[label;font_size=20]",
			"style[submit,close;font_size=18]",
			"label[1,0.8;Arithmetic Adventure]",
			"label[1,1.8;Solve this puzzle:]",
			"label[1,2.6;", edu.escape(question.text), "]",
			"field[1,3.45;5,1;answer;Your answer;]",
			"button[1,4.65;3,1;submit;Check]",
			"button[4.3,4.65;3,1;close;Done]",
			feedback,
			"label[1,7.1;Solved: ", tostring(progress.solved), "   Attempts: ",
				tostring(progress.attempts), "]",
		}, "")
	minetest.show_formspec(name, "edu_arithmetic:quiz", formspec)
end

minetest.register_node("edu_arithmetic:kiosk", {
	description = S("Arithmetic Learning Kiosk"),
	tiles = {"default_wood.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	on_rightclick = function(pos, _node, clicker)
		show_quiz(clicker)
	end,
})

minetest.register_craft({
	output = "edu_arithmetic:kiosk",
	recipe = {
		{"default:wood", "default:wood", "default:wood"},
		{"default:wood", "default:book", "default:wood"},
		{"default:wood", "default:wood", "default:wood"},
	},
})

-- Development convenience: singleplayer/server operators can obtain a kiosk
-- without gathering materials while testing lessons.
minetest.register_chatcommand("edu_kiosk", {
	description = S("Give yourself an Arithmetic Learning Kiosk"),
	privs = {server = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, S("Player is not online.")
		end
		local stack = ItemStack("edu_arithmetic:kiosk")
		local leftover = player:get_inventory():add_item("main", stack)
		if not leftover:is_empty() then
			return false, S("Your inventory is full.")
		end
		return true, S("Arithmetic Learning Kiosk added to your inventory.")
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "edu_arithmetic:quiz" then
		return false
	end

	local name = player:get_player_name()
	if fields.close or fields.quit then
		quiz[name] = nil
		return true
	end
	if not fields.submit then
		return true
	end

	local question = quiz[name]
	if not question then
		-- The formspec may outlive its in-memory question after a reload or
		-- reconnect. Re-open it safely instead of crashing the server callback.
		show_quiz(player, "Please try this question again.")
		return true
	end

	local answer = tonumber(fields.answer)
	-- The kiosk has its own generated questions, so it counts against its own
	-- skill rather than one of the curated arithmetic skills.
	edu.record_result(name, "kiosk_arithmetic", answer ~= nil and answer == question.answer)
	if answer and answer == question.answer then
		quiz[name] = make_question()
		minetest.sound_play("default_place_node", {to_player = name, gain = 0.8})
		show_quiz(player, "Great job! Try the next one.")
	else
		minetest.sound_play("default_dig_crumbly", {to_player = name, gain = 0.6})
		show_quiz(player, "Not quite. Try again!")
	end
	return true
end)
