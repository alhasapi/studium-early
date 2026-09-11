local logic = {}
logic.words = {"CAT", "DOG", "SUN", "FISH", "TREE"}

function logic.is_correct(word, letters)
	if #letters ~= #word then return false end
	for i = 1, #letters do
		if letters[i] ~= word:sub(i, i) then return false end
	end
	return true
end

return logic
