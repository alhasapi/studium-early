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

return logic
