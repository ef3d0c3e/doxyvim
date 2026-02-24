local M = {

}

-- returns list of completions for the current filter
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
	local ts = vim.treesitter

	-- Get the current buffer parser
	local parser = ts.get_parser(0)
	if not parser then return end

	local tree = parser:parse()[1]
	local root = tree:root()

	-- Get cursor position
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1 -- Lua index starts at 0

	-- Find the named node at cursor
	local node = root:named_descendant_for_range(row, col, row, col)
	while node do
		if node:type() == "comment" then
			return true
		end
		node = node:parent()
	end
	return false
end

function M.setup(ft_pattern, config)
	if config.enable ~= true then return end
	M.config = config
end

return M
