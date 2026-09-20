-- Shared content registry and validator for Studium.
-- Kept independent from the Luanti API so content packs can be checked in CI.
local content = {
	packs = {},
	items = {},
	by_domain = {},
	by_skill = {},
}

local ID_PATTERN = "^[a-z][a-z0-9_]*:[a-z][a-z0-9_%-]*$"
local DOMAINS = {math = true, english = true, logic = true}
local SUPPORTED_TYPES = {
	arithmetic_equation = true,
	word_spelling = true,
	visual_pattern = true,
}

-- A pattern board draws the sequence on one row with the answer slot after it,
-- so this bounds how far a pattern may run. Shared with edu_logic_blocks.
content.MAX_PATTERN_SEQUENCE = 6

local function fail(errors, id, message)
	errors[#errors + 1] = (id or "<pack>") .. ": " .. message
end

local function is_list(value)
	if type(value) ~= "table" then return false end
	local count = 0
	for key, _ in pairs(value) do
		if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
		if key > count then count = key end
	end
	for index = 1, count do
		if value[index] == nil then return false end
	end
	return true
end

local function validate_node_list(item, nodes, errors)
	if nodes == nil then return end
	if not is_list(nodes) then fail(errors, item.id, "nodes must be a list"); return end
	for _, node in ipairs(nodes) do
		if type(node) ~= "string" or not node:match("^[a-z0-9_]+:[a-zA-Z0-9_]+$") then
			fail(errors, item.id, "unsupported node name " .. tostring(node))
		end
	end
end

local function validate_answer(item, errors)
	local answer = item.answer
	if item.type == "arithmetic_equation" then
		if type(item.left) ~= "number" or type(item.right) ~= "number" then
			fail(errors, item.id, "arithmetic operands must be numbers")
			return
		end
		if item.left < 0 or item.right < 0 or item.left % 1 ~= 0 or item.right % 1 ~= 0 then
			fail(errors, item.id, "arithmetic operands must be non-negative integers")
		end
		if item.op ~= "+" and item.op ~= "-" then fail(errors, item.id, "unsupported arithmetic op") end
		local expected = item.op == "+" and (item.left + item.right) or (item.left - item.right)
		if expected < 0 then fail(errors, item.id, "subtraction result cannot be negative") end
		if answer ~= expected then fail(errors, item.id, "answer does not match arithmetic equation") end
	elseif item.type == "word_spelling" then
		if type(item.word) ~= "string" or not item.word:match("^[A-Z]+$") then
			fail(errors, item.id, "word must be uppercase A-Z")
		end
		if answer ~= item.word then fail(errors, item.id, "answer must match spelling word") end
		if type(item.picture) ~= "string" or item.picture == "" then fail(errors, item.id, "missing picture cue") end
	elseif item.type == "visual_pattern" then
		if not is_list(item.sequence) then
			fail(errors, item.id, "sequence must be a list")
		else
			if #item.sequence < 2 then fail(errors, item.id, "sequence must contain at least two items") end
			-- Unbounded sequences used to be accepted while the board assumed
			-- exactly three: a short one left a gap and a long one overwrote the
			-- question marker.
			if #item.sequence > content.MAX_PATTERN_SEQUENCE then
				fail(errors, item.id, "sequence must contain at most " .. content.MAX_PATTERN_SEQUENCE .. " items")
			end
			for index, entry in ipairs(item.sequence) do
				if type(entry) ~= "string" or entry == "" then
					fail(errors, item.id, "sequence entry " .. index .. " must be a non-empty string")
				end
			end
		end
		if type(answer) ~= "string" or answer == "" then fail(errors, item.id, "missing visual pattern answer") end
	else
		fail(errors, item.id, "unsupported type " .. tostring(item.type))
	end
end

function content.validate_pack(pack)
	local errors = {}
	if type(pack) ~= "table" then return false, {"<pack>: pack must be a table"} end
	if type(pack.id) ~= "string" or not pack.id:match("^[a-z][a-z0-9_%-]*$") then fail(errors, nil, "invalid pack id") end
	if type(pack.version) ~= "number" or pack.version < 1 then fail(errors, nil, "invalid pack version") end
	if type(pack.locale) ~= "string" or pack.locale == "" then fail(errors, nil, "missing locale") end
	if not is_list(pack.items) then fail(errors, nil, "items must be a list"); return false, errors end

	local seen = {}
	for _, item in ipairs(pack.items) do
		if type(item) ~= "table" then
			fail(errors, nil, "item must be a table")
		else
			if type(item.id) ~= "string" or not item.id:match(ID_PATTERN) then fail(errors, item.id, "invalid id") end
			if seen[item.id] then fail(errors, item.id, "duplicate item id") end
			seen[item.id] = true
			if not DOMAINS[item.domain] then fail(errors, item.id, "invalid domain") end
			if type(item.skill) ~= "string" or item.skill == "" then fail(errors, item.id, "missing skill") end
			if type(item.band) ~= "number" or item.band < 1 or item.band % 1 ~= 0 then fail(errors, item.id, "invalid progression band") end
			if not SUPPORTED_TYPES[item.type] then fail(errors, item.id, "unsupported task type") end
			if type(item.prompt) ~= "table" or type(item.prompt.kind) ~= "string" then fail(errors, item.id, "missing prompt metadata") end
			if type(item.provenance) ~= "table" or type(item.provenance.status) ~= "string" then fail(errors, item.id, "missing provenance review status") end
			validate_node_list(item, item.accepted_nodes, errors)
			validate_node_list(item, item.distractor_nodes, errors)
			validate_answer(item, errors)
		end
	end
	return #errors == 0, errors
end

function content.register_pack(pack)
	local ok, errors = content.validate_pack(pack)
	if not ok then return false, errors end
	content.packs[pack.id] = pack
	for _, item in ipairs(pack.items) do
		content.items[item.id] = item
		content.by_domain[item.domain] = content.by_domain[item.domain] or {}
		content.by_domain[item.domain][#content.by_domain[item.domain] + 1] = item
		content.by_skill[item.skill] = content.by_skill[item.skill] or {}
		content.by_skill[item.skill][#content.by_skill[item.skill] + 1] = item
	end
	return true
end

function content.find(filter)
	filter = filter or {}
	local result = {}
	for _, item in pairs(content.items) do
		local match = true
		for key, value in pairs(filter) do
			if item[key] ~= value then match = false; break end
		end
		if match then result[#result + 1] = item end
	end
	table.sort(result, function(a, b) return a.id < b.id end)
	return result
end

-- Choose one record, avoiding the one used last whenever there is a choice.
-- Every activity selects its next task through this, so the no-repeat rule is
-- implemented and tested once instead of once per module.
function content.pick(items, random, last_id)
	if type(items) ~= "table" or #items == 0 then return nil end
	if #items == 1 then return items[1] end
	local eligible = {}
	for _, item in ipairs(items) do
		if item.id ~= last_id then eligible[#eligible + 1] = item end
	end
	if #eligible == 0 then eligible = items end
	return eligible[random(1, #eligible)]
end

function content.choose(filter, random, last_id)
	return content.pick(content.find(filter), random, last_id)
end

return content
