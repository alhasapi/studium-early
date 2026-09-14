-- Educational game foundation.
-- This mod intentionally stays small: content modules own their lessons,
-- while this module provides shared player progress storage.

edu = rawget(_G, "edu") or {}
edu.storage = minetest.get_mod_storage()

function edu.get_progress(player_name)
	local raw = edu.storage:get_string("progress_" .. player_name)
	if raw == "" then
		return {solved = 0, attempts = 0}
	end

	local solved, attempts = raw:match("^(%d+):(%d+)$")
	return {
		solved = tonumber(solved) or 0,
		attempts = tonumber(attempts) or 0,
	}
end

function edu.save_progress(player_name, progress)
	edu.storage:set_string("progress_" .. player_name,
		string.format("%d:%d", progress.solved, progress.attempts))
end

function edu.escape(text)
	return minetest.formspec_escape(tostring(text))
end

local function arrange_hotbar(player, command)
	local items = {
		edu_blocks = {"edu_number_blocks:board", "edu_number_blocks:number_0", "edu_number_blocks:number_1", "edu_number_blocks:number_2", "edu_number_blocks:number_3", "edu_number_blocks:number_4", "edu_number_blocks:number_5", "edu_number_blocks:number_6"},
		edu_english = {"edu_english_blocks:board", "edu_english_blocks:letter_A", "edu_english_blocks:letter_B", "edu_english_blocks:letter_C", "edu_english_blocks:letter_D", "edu_english_blocks:letter_E", "edu_english_blocks:letter_F", "edu_english_blocks:letter_G"},
		edu_logic = {"edu_logic_blocks:board", "edu_logic_blocks:red", "edu_logic_blocks:blue", "edu_logic_blocks:yellow", "edu_logic_blocks:green"},
	}
	local inv = player:get_inventory()
	for slot, item in ipairs(items[command] or {}) do
		-- The hotbar is the child-facing activity palette. Replace it so
		-- stale blocks from another activity cannot hide the new selection.
		inv:set_stack("main", slot, item)
	end
end

local palette_pages = {}
local active_commands = {}
local palette_items = {
	edu_blocks = {},
	edu_english = {},
	edu_logic = {"edu_logic_blocks:red", "edu_logic_blocks:blue", "edu_logic_blocks:yellow", "edu_logic_blocks:green"},
}
for number = 0, 20 do palette_items.edu_blocks[#palette_items.edu_blocks + 1] = "edu_number_blocks:number_" .. number end
for code = string.byte("A"), string.byte("Z") do palette_items.edu_english[#palette_items.edu_english + 1] = "edu_english_blocks:letter_" .. string.char(code) end

local function update_palette_inventory(name, command, page)
	local player = minetest.get_player_by_name(name)
	if not player then return end
	local items = palette_items[command] or {}
	local per_page = 9
	local first = (page - 1) * per_page + 1
	local inv = player:get_inventory()
	-- Keep the activity board in slot 1 and mirror the current page into
	-- the next nine hotbar slots, so More immediately changes what is usable.
	inv:set_stack("main", 1, command == "edu_blocks" and "edu_number_blocks:board"
		or command == "edu_english" and "edu_english_blocks:board"
		or "edu_logic_blocks:board")
	for slot = 2, 10 do
		local item = items[first + slot - 2]
		inv:set_stack("main", slot, item or "")
	end
end

local function open_palette(name, command, page)
	local items = palette_items[command] or {}
	local per_page = 9
	local first = (page - 1) * per_page + 1
	local last = math.min(first + per_page - 1, #items)
	palette_pages[name] = {command = command, page = page}
	update_palette_inventory(name, command, page)
	local form = {"formspec_version[4]", "size[9,5]", "label[3.2,0.3;Choose a block]"}
	for index = first, last do
		local slot = index - first
		local x = 0.5 + (slot % 5) * 1.7
		local y = 0.8 + math.floor(slot / 5) * 1.7
		form[#form + 1] = string.format("item_image_button[%g,%g;1.4,1.4;%s;pick_%d;]", x, y, items[index], index)
	end
	if page > 1 then form[#form + 1] = "button[0.5,4.1;2,0.7;previous;Back]" end
	if last < #items then form[#form + 1] = "button[6.5,4.1;2,0.7;next;More]" end
	form[#form + 1] = "button_exit[3.2,4.1;2,0.7;done;Done]"
	minetest.show_formspec(name, "edu_core:palette", table.concat(form, ""))
end

local function open_toolbox(name)
	local current = active_commands[name]
	local current_button = current and "button[1.5,3.55;5,0.65;current_task;Current task blocks]" or ""
	minetest.show_formspec(name, "edu_core:toolbox", table.concat({
		"formspec_version[4]", "size[8,5]",
		"label[2.2,0.35;Studium]",
		"item_image_button[0.5,1;2,2;edu_number_blocks:board;arithmetic;]",
		"item_image_button[3,1;2,2;edu_english_blocks:board;english;]",
		"item_image_button[5.5,1;2,2;edu_logic_blocks:board;logic;]",
		"label[0.65,3.2;Arithmetic]", "label[3.25,3.2;English]", "label[5.85,3.2;Logic]",
		current_button,
		"button_exit[2.5,4.35;3,0.65;close;Done]",
	}, ""))
end

minetest.register_node("edu_core:toolbox", {
	description = "Studium Toolbox",
	inventory_image = "edu_core_toolbox.png",
	tiles = {"edu_core_toolbox.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	on_rightclick = function(_pos, _node, player)
		open_toolbox(player:get_player_name())
	end,
})

minetest.register_chatcommand("edu_menu", {
	description = "Open the Studium activity toolbox",
	func = function(name)
		open_toolbox(name)
		return true
	end,
})

minetest.register_on_joinplayer(function(player)
	local meta = player:get_meta()
	local inventory = player:get_inventory()
	local toolbox = "edu_core:toolbox"
	local held = inventory:get_stack("main", 1)

	-- The toolbox is always the first thing a child holds after joining.
	-- Preserve whatever was previously in slot 1 by moving it into the inventory.
	if held:get_name() ~= toolbox then
		local old_item = held:to_string()
		if inventory:contains_item("main", toolbox) then
			inventory:remove_item("main", toolbox)
		else
			inventory:add_item("main", toolbox)
		end
		if old_item ~= "" then inventory:add_item("main", old_item) end
		inventory:set_stack("main", 1, toolbox)
	end
	-- Some Luanti versions select slot 1 by default but do not expose a
	-- set_wield_index method. Use it when available without breaking older APIs.
	if player.set_wield_index then player:set_wield_index(1) end
	meta:set_string("edu_toolbox_given", "1")
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if formname == "edu_core:palette" then
		local state = palette_pages[name]
		if not state then return true end
		local items = palette_items[state.command]
		if fields.next then
			open_palette(name, state.command, state.page + 1)
		elseif fields.previous then
			open_palette(name, state.command, state.page - 1)
		else
			for index, item in ipairs(items) do
				if fields["pick_" .. index] ~= nil then
					player:get_inventory():set_stack("main", 2, item)
					minetest.chat_send_player(name, "Block ready in hotbar slot 2.")
					break
				end
			end
		end
		return true
	end
	if formname ~= "edu_core:toolbox" then return false end
	if fields.current_task ~= nil and active_commands[name] then
		open_palette(name, active_commands[name], 1)
		return true
	end
	local command
	if fields.arithmetic ~= nil then command = "edu_blocks"
	elseif fields.english ~= nil then command = "edu_english"
	elseif fields.logic ~= nil then command = "edu_logic" end
	if command and minetest.registered_chatcommands[command] then
		active_commands[name] = command
		local success, message = minetest.registered_chatcommands[command].func(name)
		arrange_hotbar(player, command)
		if message then minetest.chat_send_player(name, message) end
		minetest.log("action", "Studium toolbox selected " .. command .. " for " .. name .. " (" .. tostring(success) .. ")")
		open_palette(name, command, 1)
	end
	return true
end)
