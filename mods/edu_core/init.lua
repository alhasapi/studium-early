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
