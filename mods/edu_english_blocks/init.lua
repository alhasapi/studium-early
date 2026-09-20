local S = minetest.get_translator("edu_english_blocks")
local logic = dofile(minetest.get_modpath("edu_english_blocks") .. "/logic.lua")
local edu_api = rawget(_G, "edu") or nil
local content = edu_api and edu_api.content or nil
local spelling_items = content and content.find({domain = "english", type = "word_spelling"}) or {}
local puzzles = {}
local pictures = {}

-- Picture cues come from content packs but the nodes that show them are
-- registered here. Derive the node name and the texture name from one
-- normalised key so a cue can never reference a node that was not registered.
local function picture_key(cue)
	local key = tostring(cue):lower():gsub("%.png$", "")
	return (key:gsub("[^a-z0-9_]", "_"))
end

-- The mod ships a picture and a texture for every built-in word. Content packs
-- extend that vocabulary instead of replacing it: emptying the list here meant a
-- pack holding three words silently retired the other twenty-three, along with
-- their finished textures. Built-in words get synthetic ids so the shared
-- selector can avoid repeating them too.
local base_words = logic.words
local word_items, word_item_by_word, seen_words = {}, {}, {}
local function add_word(item)
	local word = item.word
	if type(word) ~= "string" or word == "" or seen_words[word] then return end
	seen_words[word] = true
	word_items[#word_items + 1] = item
	word_item_by_word[word] = item
end

-- Content words come first so a pack can override the picture cue for a word.
for _, item in ipairs(spelling_items) do
	add_word({
		id = item.id, word = item.word, picture = item.picture,
		accepted_nodes = item.accepted_nodes, distractor_nodes = item.distractor_nodes,
	})
end
for _, word in ipairs(base_words) do
	add_word({id = "english:builtin-" .. word:lower(), word = word})
end

logic.words = {}
for _, item in ipairs(word_items) do
	logic.words[#logic.words + 1] = item.word
	if item.picture then pictures[item.word] = picture_key(item.picture) end
end
for _, word in ipairs(logic.words) do
	pictures[word] = pictures[word] or picture_key(word)
end

local sorted_picture_keys = {}
do
	local seen = {}
	for _, word in ipairs(logic.words) do
		local key = pictures[word]
		if key and key ~= "" and not seen[key] then
			seen[key] = true
			sorted_picture_keys[#sorted_picture_keys + 1] = key
		end
	end
	table.sort(sorted_picture_keys)
end

-- Tell a content author exactly which asset is missing instead of leaving them
-- with a blank block and no explanation.
if io and io.open then
	local texture_dir = minetest.get_modpath("edu_english_blocks") .. "/textures/"
	for _, key in ipairs(sorted_picture_keys) do
		local texture = "edu_english_blocks_picture_" .. key .. ".png"
		local file = io.open(texture_dir .. texture, "rb")
		if file then
			file:close()
		else
			minetest.log("warning", "[edu_english_blocks] missing texture " .. texture ..
				" for picture cue '" .. key .. "'")
		end
	end
end

local directions = {
	{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0},
	{x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1},
	{x = 0, y = 1, z = 0}, {x = 0, y = -1, z = 0},
}

local last_word_id
local function choose_word()
	local item = content and content.pick(word_items, math.random, last_word_id)
	if not item and #word_items > 0 then item = word_items[math.random(1, #word_items)] end
	if not item then return "CAT" end
	last_word_id = item.id
	return item.word
end

local function letter_from_node(name)
	return name:match("^edu_english_blocks:letter_([A-Z])$")
end

-- Offer the letters this word needs, plus any the pack marks as deliberate
-- confusions, instead of the whole alphabet.
local function publish_task_blocks(player_name, word)
	if not player_name or not (edu_api and edu_api.set_task_blocks) then return end
	local item = word_item_by_word[word]
	edu_api.set_task_blocks(player_name, item and content and content.task_blocks(item) or {})
end

local function build_word(pos, word, player_name)
	publish_task_blocks(player_name, word)
	-- Clear the previous attempt and leave blank slots for the child.
	for _, direction in ipairs(directions) do
		for distance = 1, 8 do
			local p = {x = pos.x + direction.x * distance, y = pos.y + direction.y * distance, z = pos.z + direction.z * distance}
			if minetest.get_node(p).name:match("^edu_english_blocks:letter_[A-Z]$") then
				minetest.remove_node(p)
			end
		end
	end
	local picture = pictures[word] or picture_key(word)
	-- Record the word before placing the picture, so a failure here cannot leave
	-- the board permanently answerless.
	minetest.get_meta(pos):set_string("word", word)
	minetest.get_meta(pos):set_string("infotext", S("Look at the picture and build the word"))
	minetest.set_node({x = pos.x - 1, y = pos.y + 1, z = pos.z + 1}, {
		name = "edu_english_blocks:picture_" .. picture,
	})
end

local function feedback(player, text, sound, correct)
	local name = player:get_player_name()
	minetest.chat_send_player(name, text)
	minetest.sound_play(sound, {to_player = name, gain = 1.0})
	local feedback_hud = player:hud_add({
		type = "image",
		position = {x = 0.5, y = 0.35},
		text = correct and "edu_english_blocks_correct.png" or "edu_english_blocks_incorrect.png",
		scale = {x = 2, y = 2},
	})
	minetest.after(2, function()
		if player and player:is_player() then player:hud_remove(feedback_hud) end
	end)
	minetest.add_particlespawner({
		amount = correct and 28 or 12,
		time = 0.5,
		minpos = vector.subtract(player:get_pos(), {x = 0.7, y = 0, z = 0.7}),
		maxpos = vector.add(player:get_pos(), {x = 0.7, y = 1.8, z = 0.7}),
		minvel = {x = -1, y = 1, z = -1},
		maxvel = {x = 1, y = 3, z = 1},
		texture = correct and "edu_english_blocks_correct.png" or "edu_english_blocks_incorrect.png",
	})
end

minetest.register_node("edu_english_blocks:board", {
	description = S("English Word Board"),
	inventory_image = "edu_english_blocks_board.png",
	tiles = {"edu_english_blocks_board.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	after_place_node = function(pos, placer)
		if placer then
			local word = minetest.get_meta(pos):get_string("word")
			puzzles[placer:get_player_name()] = {word = word, pos = vector.copy(pos)}
			publish_task_blocks(placer:get_player_name(), word)
		end
	end,
	on_construct = function(pos)
		local word = choose_word()
		minetest.get_meta(pos):set_string("word", word)
		build_word(pos, word)
	end,
	on_rightclick = function(pos, _node, player)
		local name = player:get_player_name()
		local puzzle = puzzles[name]
		if not puzzle or not puzzle.pos or puzzle.pos.x ~= pos.x or puzzle.pos.y ~= pos.y or puzzle.pos.z ~= pos.z then
			local word = minetest.get_meta(pos):get_string("word")
			if word == "" then
				word = choose_word()
				build_word(pos, word, name)
			end
			puzzle = {word = word, pos = vector.copy(pos)}
			puzzles[name] = puzzle
		end
		-- Covers a board whose word was chosen before this player arrived.
		publish_task_blocks(name, puzzle.word)
		local function read_letters(direction)
			local letters = {}
			for index = 1, #puzzle.word do
				-- Accept small placement offsets around each slot. This is deliberately
				-- forgiving for children placing blocks by hand.
				for a = -4, 4 do
					for b = -4, 4 do
						local p
						if direction.x ~= 0 then
							p = {x = pos.x + direction.x * index, y = pos.y + 1 + a, z = pos.z + b}
						elseif direction.z ~= 0 then
							p = {x = pos.x + a, y = pos.y + 1 + b, z = pos.z + direction.z * index}
						else
							p = {x = pos.x + a, y = pos.y + direction.y * index, z = pos.z + b}
						end
						local letter = letter_from_node(minetest.get_node(p).name)
						if letter then letters[index] = letter end
					end
				end
				letters[index] = letters[index] or ""
			end
			return letters
		end
		local correct = false
		for _, direction in ipairs(directions) do
			if logic.is_correct(puzzle.word, read_letters(direction)) then
				correct = true
				break
			end
		end
		if correct then
			feedback(player, "★ GREAT SPELLING! ★", "edu_english_blocks_correct", true)
			puzzles[name] = {word = choose_word(), pos = vector.copy(pos)}
			build_word(pos, puzzles[name].word, name)

		else
			feedback(player, "Try the letters again!", "edu_english_blocks_incorrect", false)
		end
	end,
})

local auto_check_word
for code = string.byte("A"), string.byte("Z") do
	local letter = string.char(code)
	minetest.register_node("edu_english_blocks:letter_" .. letter, {
		description = S("Letter @1", letter),
		short_description = S("Letter @1", letter),
		inventory_image = "edu_english_blocks_letter_" .. letter .. ".png",
		tiles = {"edu_english_blocks_letter_" .. letter .. ".png"},
		groups = {choppy = 2, oddly_breakable_by_hand = 2},
		after_place_node = function(pos, placer)
			if auto_check_word then auto_check_word(pos, placer) end
		end,
		on_construct = function(pos)
			minetest.get_meta(pos):set_string("infotext", S("Letter @1", letter))
		end,
	})
end

for _, key in ipairs(sorted_picture_keys) do
	minetest.register_node("edu_english_blocks:picture_" .. key, {
		description = S("Picture"),
		tiles = {"edu_english_blocks_picture_" .. key .. ".png"},
		groups = {not_in_creative_inventory = 1},
	})
end

local function give_english_kit(name)
	local player = minetest.get_player_by_name(name)
	if not player then return false, S("Player is not online.") end
	local inv = player:get_inventory()
	inv:add_item("main", "edu_english_blocks:board")
	for code = string.byte("A"), string.byte("Z") do
		inv:add_item("main", "edu_english_blocks:letter_" .. string.char(code))
	end
	return true, S("English word puzzle kit added.")
end

local command = {
	description = S("Give yourself the English word puzzle kit"),
	privs = {server = true},
	func = give_english_kit,
}
minetest.register_chatcommand("edu_english", command)
minetest.register_chatcommand("edu_english_blocks", command)

-- Once all letter slots are filled, placing the final block checks the word
-- automatically. The board remains usable for starting a puzzle and retrying.
local function word_matches_nearby(board_pos, word)
	for ox = -4, 4 do
		for oy = -2, 2 do
			for oz = -4, 4 do
				for _, direction in ipairs(directions) do
					local matches = true
					for index = 1, #word do
						local p = {
							x = board_pos.x + ox + direction.x * (index - 1),
							y = board_pos.y + oy + direction.y * (index - 1),
							z = board_pos.z + oz + direction.z * (index - 1),
						}
						if letter_from_node(minetest.get_node(p).name) ~= word:sub(index, index) then
							matches = false
							break
						end
					end
					if matches then return true end
				end
			end
		end
	end
	return false
end

auto_check_word = function(pos, placer)
	if not placer or not placer.get_player_name or not letter_from_node(minetest.get_node(pos).name) then return end
	local puzzle = puzzles[placer:get_player_name()]
	if not puzzle or not puzzle.pos then return end
	local board_pos = puzzle.pos
	if math.abs(pos.x - board_pos.x) > 8 or math.abs(pos.y - board_pos.y) > 2 or math.abs(pos.z - board_pos.z) > 8 then return end
	if word_matches_nearby(board_pos, puzzle.word) then
		local board = minetest.get_node(board_pos)
		if board.name == "edu_english_blocks:board" then
			minetest.registered_nodes[board.name].on_rightclick(board_pos, board, placer)
		end
		return
	end
	for _, direction in ipairs(directions) do
		local complete = true
		for index = 1, #puzzle.word do
			local found = false
			for a = -4, 4 do
				for b = -4, 4 do
					local p
					if direction.x ~= 0 then
						p = {x = board_pos.x + direction.x * index, y = board_pos.y + 1 + a, z = board_pos.z + b}
					elseif direction.z ~= 0 then
						p = {x = board_pos.x + a, y = board_pos.y + 1 + b, z = board_pos.z + direction.z * index}
					else
						p = {x = board_pos.x + a, y = board_pos.y + direction.y * index, z = board_pos.z + b}
					end
					if letter_from_node(minetest.get_node(p).name) then found = true end
				end
			end
			if not found then complete = false break end
		end
		if complete then
			local board = minetest.get_node(board_pos)
			if board.name == "edu_english_blocks:board" then
				minetest.registered_nodes[board.name].on_rightclick(board_pos, board, placer)
			end
			return
		end
	end
end
