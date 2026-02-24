local ts = vim.treesitter
local M = {}

M.hl = {}
local function get_hl(tag)
	local hl = M.hl[tag]
	if hl then return hl end
	hl = M.config.hl(tag)
	if hl then
		if tag == "{" then
			tag = "LBRACE"
		elseif tag == "}" then
			tag = "RBRACE"
		end
		local name = "DoxyvimTag_" .. tag
		vim.api.nvim_set_hl(0, name, hl)
		M.hl[tag] = name
		return name
	end
	return nil
end

local function highlight_tags()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, M.ns or 0, 0, -1)

	local lang = vim.bo[bufnr].filetype
	local parser = ts.get_parser(bufnr)


	if not parser then return end
	local tree = parser:parse()[1]
	local root = tree:root()
	local query = ts.query.parse(lang, [[ (comment) @c ]])


	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local text                 = ts.get_node_text(node, bufnr)
		local start_row, start_col = node:range()

		-- Split text into lines to handle multi-line comments
		local line_offset          = 0
		local col_offset           = start_col

		for line in text:gmatch("([^\n]*)\n?") do
			-- Search for all @tags in this line
			for s, tag, e in line:gmatch("()[@\\](%S+)()") do
				local tag_line      = start_row + line_offset
				local tag_start_col = (s - 1) + (line_offset == 0 and col_offset or 0)
				local tag_end_col   = (e - 1) + (line_offset == 0 and col_offset or 0)
				if tag:match("code") then
					tag = "code"
				end
				local hl = get_hl(tag)
				vim.api.nvim_buf_set_extmark(bufnr, M.ns, tag_line, tag_start_col, {
					end_row = tag_line,
					end_col = tag_end_col,
					hl_group = hl
				});
			end
			line_offset = line_offset + 1
		end
	end
end

function M.setup(ft_pattern, config)
	if config.enable ~= true then return end
	M.config = config
	M.ns = vim.api.nvim_create_namespace("doxyvim_tags")

	vim.api.nvim_create_augroup("DoxygenCommentTag", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave", "BufWinEnter" }, {
		group = "DoxygenCommentTag",
		callback = function(ev)
			local ft = vim.bo[ev.buf].filetype
			if not ft or not ft_pattern[ft] then
				return
			end
			highlight_tags()
		end
	})
end

return M
