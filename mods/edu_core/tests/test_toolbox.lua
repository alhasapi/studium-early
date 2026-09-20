-- The toolbox and block picker are the child's entry point, and none of their
-- labels went through S(), so no translator could ever have reached them.
local root = ...
local passed = 0
local function check(value, message)
	assert(value, message)
	passed = passed + 1
end

local translated = {}
local function translator()
	return function(text, ...)
		translated[#translated + 1] = text
		local args = {...}
		return (tostring(text):gsub("@(%d+)", function(index)
			return tostring(args[tonumber(index)] or "")
		end))
	end
end

local function assert_translated(expected)
	for _, text in ipairs(translated) do
		if text == expected then return end
	end
	assert(false, "string never passed through S(): " .. expected)
end

local store, formspecs, nodes, commands = {}, {}, {}, {}
local stacks = {}
local receive_fields
local player = {
	get_player_name = function() return "tester" end,
	get_inventory = function()
		return {
			set_stack = function(_, list, slot, item) stacks[list .. ":" .. slot] = item end,
			add_item = function() return ItemStack("") end,
			remove_item = function() end,
			contains_item = function() return false end,
		}
	end,
	get_meta = function() return {set_string = function() end} end,
	set_wield_index = function() end,
}

_G.ItemStack = function(_) return {is_empty = function() return true end} end
_G.minetest = {
	get_mod_storage = function()
		return {
			get_string = function(_, key) return store[key] or "" end,
			set_string = function(_, key, value) store[key] = value end,
		}
	end,
	get_modpath = function() return root end,
	get_translator = translator,
	formspec_escape = function(text) return tostring(text) end,
	register_node = function(name, definition) nodes[name] = definition end,
	register_chatcommand = function(name, definition) commands[name] = definition end,
	register_on_joinplayer = function() end,
	register_on_player_receive_fields = function(callback) receive_fields = callback end,
	show_formspec = function(name, formname, formspec)
		formspecs[#formspecs + 1] = {name = name, formname = formname, formspec = formspec}
	end,
	close_formspec = function() end,
	chat_send_player = function() end,
	get_player_by_name = function(name) return player end,
	log = function() end,
	registered_chatcommands = {
		edu_english = {func = function() return true, "English word puzzle kit added." end},
	},
}

dofile(root .. "/init.lua")

check(nodes["edu_core:toolbox"] ~= nil, "toolbox node registered")
check(commands.edu_menu ~= nil, "toolbox command registered")
check(receive_fields ~= nil, "formspec handler registered")

-- Opening the toolbox lists the three activities.
commands.edu_menu.func("tester")
check(#formspecs == 1, "toolbox shown once")
check(formspecs[1].formname == "edu_core:toolbox", "toolbox formspec name")
for _, expected in ipairs({"Studium", "Arithmetic", "English", "Logic", "Studium Toolbox",
	"Open the Studium activity toolbox"}) do
	assert_translated(expected)
end
check(nodes["edu_core:toolbox"].description == "Studium Toolbox", "toolbox description translated")

-- Choosing an activity fills the hotbar and closes the toolbox.
receive_fields(player, "edu_core:toolbox", {english = true})
check(stacks["main:1"] == "edu_english_blocks:board", "board placed in the first hotbar slot")
check(stacks["main:2"] == "edu_english_blocks:letter_A", "palette mirrored into the hotbar")

-- Re-opening the toolbox now offers the current task's blocks.
commands.edu_menu.func("tester")
assert_translated("Current task blocks")

-- The task-blocks button opens the block picker.
receive_fields(player, "edu_core:toolbox", {current_task = true})
local palette = formspecs[#formspecs]
check(palette.formname == "edu_core:palette", "picker formspec name")
check(palette.formspec:match("Choose a block"), "picker heading rendered")
for _, expected in ipairs({"Choose a block", "More"}) do
	assert_translated(expected)
end

-- Picking a block puts it in the second hotbar slot.
receive_fields(player, "edu_core:palette", {pick_1 = true})
check(stacks["main:2"] == "edu_english_blocks:letter_A", "picked block lands in slot 2")
assert_translated("Block ready in hotbar slot 2.")

-- Task blocks published by an activity replace the whole category palette.
edu.set_task_blocks("tester", {"edu_number_blocks:number_3", "edu_number_blocks:number_4"})
check(edu.get_task_blocks("tester")[1] == "edu_number_blocks:number_3", "task blocks stored")
check(stacks["main:2"] == "edu_number_blocks:number_3", "hotbar refreshed from the task blocks")
check(stacks["main:3"] == "edu_number_blocks:number_4", "second task block mirrored")
check(stacks["main:4"] == "", "slots beyond the task blocks are cleared")

edu.set_task_blocks("tester", {})
check(edu.get_task_blocks("tester") == nil, "clearing task blocks restores the category palette")
check(stacks["main:3"] == "edu_english_blocks:letter_B", "category palette restored")

print("edu_core toolbox tests passed: " .. passed)
