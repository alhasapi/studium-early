-- The progress helpers had no test, so nothing caught that only the kiosk ever
-- wrote to them and that storage was limited to one overall counter.
local root = ...
local store = {}
local passed = 0
local function check(value, message)
	assert(value, message)
	passed = passed + 1
end

_G.minetest = {
	get_mod_storage = function()
		return {
			get_string = function(_, key) return store[key] or "" end,
			set_string = function(_, key, value) store[key] = value end,
		}
	end,
	get_modpath = function() return root end,
	get_translator = function() return function(text) return text end end,
	formspec_escape = function(text) return tostring(text) end,
	register_node = function() end,
	register_chatcommand = function() end,
	register_on_joinplayer = function() end,
	register_on_player_receive_fields = function() end,
	log = function() end,
}

dofile(root .. "/init.lua")

check(edu.get_progress("ana").solved == 0, "a new player starts at zero")
check(edu.get_progress("ana").attempts == 0, "a new player has no attempts")
check(edu.get_skill_progress("ana", "addition_within_5").solved == 0, "a new skill starts at zero")

edu.record_result("ana", "addition_within_5", true)
local overall = edu.get_progress("ana")
check(overall.solved == 1 and overall.attempts == 1, "a solved task counts once overall")
local skill = edu.get_skill_progress("ana", "addition_within_5")
check(skill.solved == 1 and skill.attempts == 1, "a solved task counts for its skill")

edu.record_result("ana", "addition_within_5", false)
check(edu.get_skill_progress("ana", "addition_within_5").attempts == 2, "a failed task counts as an attempt")
check(edu.get_skill_progress("ana", "addition_within_5").solved == 1, "a failed task does not score")
check(edu.get_progress("ana").solved == 1, "a failed task does not score overall")

edu.record_result("ana", "cvc_spelling", true)
check(edu.get_skill_progress("ana", "cvc_spelling").solved == 1, "a second skill is tracked separately")
check(edu.get_skill_progress("ana", "addition_within_5").solved == 1, "the first skill is unchanged")
check(edu.get_progress("ana").solved == 2, "the overall total spans skills")

check(edu.get_progress("bo").solved == 0, "players do not share counters")
check(edu.get_skill_progress("ana", "never_attempted").attempts == 0, "an untouched skill is empty")

-- Attempts with no skill still move the overall counter.
edu.record_result("ana", nil, true)
check(edu.get_progress("ana").solved == 3, "an unskilled task still counts overall")
edu.record_result("ana", "", true)
check(edu.get_progress("ana").solved == 4, "an empty skill name is treated as no skill")

-- Punctuation in a skill name must not break the storage key, and must not
-- collide with a differently punctuated skill.
edu.record_result("ana", "counting: 1-10", true)
edu.record_result("ana", "counting_ 1-10", true)
check(edu.get_skill_progress("ana", "counting: 1-10").solved == 2,
	"skill names that sanitise alike share one counter")

-- A save written before per-skill tracking must still load.
store["progress_legacy"] = "7:11"
local legacy = edu.get_progress("legacy")
check(legacy.solved == 7 and legacy.attempts == 11, "an older overall counter still loads")
check(edu.get_skill_progress("legacy", "addition_within_5").attempts == 0, "legacy saves have no skills")
edu.record_result("legacy", "addition_within_5", false)
check(edu.get_progress("legacy").attempts == 12, "an older counter keeps counting forward")
check(store["progress_legacy"] == "7:12", "an older counter is rewritten in place")

-- Corrupt values must not crash or be read as progress.
store["progress_broken"] = "not a counter"
check(edu.get_progress("broken").solved == 0, "an unreadable counter reads as zero")
store["skill_broken_x"] = "9"
check(edu.get_skill_progress("broken", "x").attempts == 0, "an unreadable skill counter reads as zero")

print("edu_core progress tests passed: " .. passed)
