local S = minetest.get_translator("edu_logic_blocks")
local logic = dofile(minetest.get_modpath("edu_logic_blocks") .. "/logic.lua")
local edu_api = rawget(_G, "edu") or nil
local content = edu_api and edu_api.content or nil
local content_patterns = content and content.find({domain = "logic", type = "visual_pattern"}) or {}
-- A pack supplies its own curated patterns; otherwise the built-in set is used.
local pattern_items = #content_patterns > 0 and content_patterns or logic.patterns
local puzzles = {}
local colors = {"red", "blue", "yellow", "green"}
local last_pattern_id

local function choose_pattern()
	local pattern = content and content.pick(pattern_items, math.random, last_pattern_id)
	if not pattern and #pattern_items > 0 then pattern = pattern_items[math.random(1, #pattern_items)] end
	if not pattern then return {sequence = {"red", "blue", "red"}, answer = "blue"} end
	last_pattern_id = pattern.id
	return pattern
end

local color_set = {}
for _, color in ipairs(colors) do color_set[color] = true end

-- Only the four pattern colours are blocks a child can answer with. Restricting
-- this to known colours stops decorative board nodes, such as the question
-- marker, from being mistaken for a placed answer.
local function color_from_node(name)
	local color = name:match("^edu_logic_blocks:(%a+)$")
	if color and color_set[color] then return color end
	return nil
end

-- The pattern occupies the row to the left of the answer slot, so the whole row
-- can be cleared generously without touching blocks placed elsewhere.
local MAX_SEQUENCE = rawget(_G, "edu") and edu.content and edu.content.MAX_PATTERN_SEQUENCE or 6
local DEFAULT_SLOT = 4

local function clear_slots(pos)
	for x = 1, MAX_SEQUENCE + 1 do
		local p = {x = pos.x + x, y = pos.y + 1, z = pos.z}
		local name = minetest.get_node(p).name
		-- The question marker is cleared too: a shorter pattern must not leave
		-- the previous, longer pattern's marker behind further along the row.
		if color_from_node(name) or name == "edu_logic_blocks:question" then
			minetest.remove_node(p)
		end
	end
end

-- Where the child must place the answer. Recorded when the pattern is built so a
-- pattern of any accepted length gets a slot after its own last block.
local function answer_slot(pos)
	return tonumber(minetest.get_meta(pos):get_string("slot")) or DEFAULT_SLOT
end

-- Offer the colours this pattern calls for, plus the pack's deliberate
-- confusions, instead of every colour.
local function publish_task_blocks(player_name, pattern)
	if not player_name or not (edu_api and edu_api.set_task_blocks) then return end
	edu_api.set_task_blocks(player_name, content and content.task_blocks(pattern) or {})
end

-- The pattern currently laid out on each board, so the task's blocks can be
-- offered again when a player returns to a board they did not just build.
local board_patterns = {}
local function board_key(pos) return pos.x .. ":" .. pos.y .. ":" .. pos.z end

local function build_pattern(pos, pattern, player_name)
	board_patterns[board_key(pos)] = pattern
	publish_task_blocks(player_name, pattern)
	clear_slots(pos)
	for index, color in ipairs(pattern.sequence) do
		minetest.set_node({x = pos.x + index, y = pos.y + 1, z = pos.z}, {
			name = "edu_logic_blocks:" .. color,
		})
	end
	-- The answer slot follows the pattern rather than sitting at a fixed offset.
	local slot = #pattern.sequence + 1
	minetest.set_node({x = pos.x + slot, y = pos.y + 1, z = pos.z}, {
		name = "edu_logic_blocks:question",
	})
	local meta = minetest.get_meta(pos)
	meta:set_string("answer", pattern.answer)
	meta:set_string("slot", tostring(slot))
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
		if player and player.get_player_name then player:hud_remove(hud) end
	end)
end

minetest.register_node("edu_logic_blocks:board", {
	description = S("Pattern Board"),
	inventory_image = "edu_logic_blocks_board.png", tiles = {"edu_logic_blocks_board.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	after_place_node = function(pos, placer)
		if placer then
			puzzles[placer:get_player_name()] = {pos = vector.copy(pos)}
			publish_task_blocks(placer:get_player_name(), board_patterns[board_key(pos)])
		end
	end,
	on_construct = function(pos)
		build_pattern(pos, choose_pattern())
	end,
	on_destruct = function(pos)
		clear_slots(pos)
		board_patterns[board_key(pos)] = nil
	end,
	on_rightclick = function(pos, _node, player)
		local name = player:get_player_name()
		-- Accept blocks placed at the target slot even when the child misses the
		-- center by one node. Skip the pattern's own row: those blocks are part
		-- of the puzzle rather than an answer, and the final pattern block sits
		-- directly beside the slot. Of what remains, the block nearest the slot
		-- is the one the child meant.
		local slot = {x = pos.x + answer_slot(pos), y = pos.y + 1, z = pos.z}
		local answer, best_distance
		for x = -1, 1 do
			for y = -1, 1 do
				for z = -1, 1 do
					local on_pattern_row = y == 0 and z == 0 and x ~= 0
					if not on_pattern_row then
						local candidate = color_from_node(minetest.get_node({x = slot.x + x, y = slot.y + y, z = slot.z + z}).name)
						if candidate then
							local distance = x * x + y * y + z * z
							if best_distance == nil or distance < best_distance then
								answer, best_distance = candidate, distance
							end
						end
					end
				end
			end
		end
		local target = minetest.get_meta(pos):get_string("answer")
		if logic.is_correct({answer = target}, answer) then
			feedback(player, true)
			build_pattern(pos, choose_pattern(), name)
		else
			feedback(player, false)
			-- A returning player may not have this pattern's blocks yet.
			publish_task_blocks(name, board_patterns[board_key(pos)])
		end
		puzzles[name] = {pos = vector.copy(pos)}
	end,
})

for _, color in ipairs(colors) do
	minetest.register_node("edu_logic_blocks:" .. color, {
		description = S("@1 pattern block", color),
		inventory_image = "edu_logic_blocks_" .. color .. ".png",
		tiles = {"edu_logic_blocks_" .. color .. ".png"},
		groups = {choppy = 2, oddly_breakable_by_hand = 2},
		after_place_node = function(pos, placer)
			if not placer then return end
			local puzzle = puzzles[placer:get_player_name()]
			if not puzzle or not puzzle.pos then return end
			local slot = answer_slot(puzzle.pos)
			if math.abs(pos.x - (puzzle.pos.x + slot)) <= 1 and
				math.abs(pos.y - (puzzle.pos.y + 1)) <= 1 and math.abs(pos.z - puzzle.pos.z) <= 1 then
				local board = minetest.get_node(puzzle.pos)
				if board.name == "edu_logic_blocks:board" then
					minetest.registered_nodes[board.name].on_rightclick(puzzle.pos, board, placer)
				end
			end
		end,
	})
end

minetest.register_node("edu_logic_blocks:question", {
	description = S("Missing pattern block"),
	inventory_image = "edu_logic_blocks_question.png",
	tiles = {"edu_logic_blocks_question.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1},
	drop = "",
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
