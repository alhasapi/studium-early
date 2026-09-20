local logic = {}
logic.words = {
	"CAT", "APPLE", "BALL", "DOG", "EGG", "FISH", "GOAT", "HOUSE", "ICE",
	"JAR", "KITE", "LION", "MOON", "NEST", "OWL", "PIG", "QUEEN", "RABBIT",
	"SUN", "TREE", "UMBRELLA", "VAN", "WOLF", "XYLOPHONE", "YOYO", "ZEBRA",
}

function logic.is_correct(word, letters)
	if #letters ~= #word then return false end
	for i = 1, #letters do
		if letters[i] ~= word:sub(i, i) then return false end
	end
	return true
end

-- Draw a word, avoiding the previous one whenever there is a choice. Kept here
-- rather than in the mod so the selection rule is testable against any list.
function logic.choose_word(words, random, last_word)
	if type(words) ~= "table" or #words == 0 then return nil end
	if #words == 1 then return words[1] end
	local choices = {}
	for _, word in ipairs(words) do
		if word ~= last_word then choices[#choices + 1] = word end
	end
	if #choices == 0 then choices = words end
	return choices[random(1, #choices)]
end

return logic
