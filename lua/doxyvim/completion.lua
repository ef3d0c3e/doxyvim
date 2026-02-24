local M = {

}

-- return list of completions for the current filter
function M.doxyvim_completions(filter)
	if filter and filter ~= "" then
		local filtered = {}
		for _, v in ipairs(M.config.keywords) do
			if v:sub(1, #filter) == filter then
				table.insert(filtered, v)
			end
		end
		return filtered
	else
		return M.config.keywords
	end
end

-- Detect if cursor is in a comment
function M.in_comment()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	if row > 0 then
		row = row - 1
	end
	local line = vim.api.nvim_get_current_line()
	for c = 0, #line - 1 do
		local captures = vim.treesitter.get_captures_at_pos(0, row, c)
		for _, capture in ipairs(captures) do
			if capture.capture:find("comment") then
				return true
			end
		end
	end
	return false
end

function M.setup(ft_pattern, config)
	if config.enable ~= true then return end
	M.config = config
end

return M
