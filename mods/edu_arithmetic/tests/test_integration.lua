-- The kiosk was the only Studium activity with no test, which is why its
-- progress counters were the only ones ever exercised.
local root = (...)
local definitions, formspecs, sounds, crafts = {}, {}, {}, {}

local function player_object(name)
	return {
		get_player_name = function() return name end,
		get_inventory = function()
			return {
				add_item = function(_, stack) return ItemStack("") end,
			}
		end,
	}
end

_G.ItemStack = function(_) return {is_empty = function() return true end} end

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


local progress = {solved = 0, attempts = 0}
local skills = {}
_G.edu = {
	get_progress = function()
		return {solved = progress.solved, attempts = progress.attempts}
	end,
	save_progress = function(_, value)
		progress.solved, progress.attempts = value.solved, value.attempts
	end,
	record_result = function(_, skill, correct)
		progress.attempts = progress.attempts + 1
		if correct then progress.solved = progress.solved + 1 end
		skills[skill] = (skills[skill] or 0) + 1
	end,
	escape = function(text) return tostring(text) end,
}

_G.minetest = {
	get_translator = translator,
	get_modpath = function() return root end,
	register_node = function(name, definition) definitions[name] = definition end,
	register_craft = function(recipe) crafts[#crafts + 1] = recipe end,
	register_chatcommand = function(name, definition) definitions["command:" .. name] = definition end,
	register_on_player_receive_fields = function(callback) definitions.receive_fields = callback end,
	get_player_by_name = function(name) return player_object(name) end,
	show_formspec = function(name, formname, formspec)
		formspecs[#formspecs + 1] = {name = name, formname = formname, formspec = formspec}
	end,
	formspec_escape = function(text) return tostring(text) end,
	sound_play = function(sound) sounds[#sounds + 1] = sound end,
}

dofile(root .. "/init.lua")

local kiosk = definitions["edu_arithmetic:kiosk"]
assert(kiosk and kiosk.on_rightclick, "kiosk node registered")
assert(#crafts == 1, "kiosk craft registered")
assert(definitions["command:edu_kiosk"], "kiosk command registered")
assert(definitions.receive_fields, "formspec handler registered")

local function answer_from(formspec)
	local text = formspec:match("label%[1,2%.6;([^%]]+)%]")
	assert(text, "question label present")
	local left, op, right = text:match("^(%d+) ([%+%-]) (%d+) = %?$")
	assert(left, "question parses: " .. text)
	left, right = tonumber(left), tonumber(right)
	return op == "+" and left + right or left - right, text
end

local player = player_object("tester")
local pos = {x = 0, y = 0, z = 0}

-- Opening the kiosk starts a question.
kiosk.on_rightclick(pos, {}, player)
assert(#formspecs == 1, "opening the kiosk shows a quiz")
assert(formspecs[1].formname == "edu_arithmetic:quiz", "quiz formspec name")
assert(formspecs[1].formspec:match("Solved: 0"), "progress shown before any attempt")
local answer = answer_from(formspecs[1].formspec)

-- A correct answer scores and saves.
assert(definitions.receive_fields(player, "edu_arithmetic:quiz", {submit = true, answer = tostring(answer)}))
assert(progress.solved == 1, "correct answer counted as solved, got " .. progress.solved)
assert(progress.attempts == 1, "correct answer counted as an attempt, got " .. progress.attempts)
assert(sounds[#sounds] == "default_place_node", "correct answer plays the success sound")
assert(formspecs[#formspecs].formspec:match("Solved: 1"), "updated progress shown")

-- A wrong answer only counts the attempt.
local next_answer = answer_from(formspecs[#formspecs].formspec)
definitions.receive_fields(player, "edu_arithmetic:quiz", {submit = true, answer = tostring(next_answer + 1)})
assert(progress.solved == 1, "wrong answer does not score, got " .. progress.solved)
assert(progress.attempts == 2, "wrong answer counted as an attempt, got " .. progress.attempts)
assert(sounds[#sounds] == "default_dig_crumbly", "wrong answer plays the retry sound")

-- Non-numeric input must not crash or score.
definitions.receive_fields(player, "edu_arithmetic:quiz", {submit = true, answer = "seven"})
assert(progress.attempts == 3, "unparseable answer still counts an attempt, got " .. progress.attempts)
assert(progress.solved == 1, "unparseable answer does not score")

-- Closing forgets the question, and submitting afterwards re-opens safely.
definitions.receive_fields(player, "edu_arithmetic:quiz", {close = true})
local before = #formspecs
definitions.receive_fields(player, "edu_arithmetic:quiz", {submit = true, answer = "1"})
assert(#formspecs == before + 1, "submitting without a question re-opens the quiz")
assert(progress.attempts == 3, "a questionless submit is not counted")

-- Unrelated formspecs are left to other mods.
assert(definitions.receive_fields(player, "some_other_mod:form", {}) == false, "other formspecs ignored")

-- Every attempt is counted against the kiosk's own skill, not just the total.
assert(skills.kiosk_arithmetic == 3, "attempts recorded per skill, got " .. tostring(skills.kiosk_arithmetic))


-- Regression: these strings used to be written straight into a formspec or chat
-- message, so no translator could ever reach them.
local function assert_translated(expected)
	for _, text in ipairs(translated) do
		if text == expected then return end
	end
	assert(false, "string never passed through S(): " .. expected)
end

for _, expected in ipairs({
	"Arithmetic Adventure", "Solve this puzzle:", "Your answer", "Check", "Done",
	"Please try this question again.", "Great job! Try the next one.", "Not quite. Try again!",
	"Solved: @1   Attempts: @2",
}) do
	assert_translated(expected)
end

print("edu_arithmetic integration tests passed")
