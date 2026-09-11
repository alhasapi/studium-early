local logic = dofile((...) .. "/logic.lua")
local function ok(v, m) assert(v, m) end
for _, pattern in ipairs(logic.patterns) do
 ok(logic.is_correct(pattern, pattern.answer), "answer accepted")
 ok(not logic.is_correct(pattern, "wrong"), "wrong answer rejected")
end
print("edu_logic_blocks logic tests passed: " .. #logic.patterns)
