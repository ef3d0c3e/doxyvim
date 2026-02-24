local ts = vim.treesitter
local M = {
	groups = {}
}

local function parse_groups(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lang = vim.bo[bufnr].filetype
	local parser = ts.get_parser(bufnr, lang)
	if not parser then return end
	local tree = parser:parse()[1]
	local root = tree:root()
	local query = ts.query.parse(lang, [[ (comment) @c ]])

	local stack = {} -- stack of { start, name, desc, ingroup }
	local pending = nil -- a @defgroup comment not yet paired with @{
	local groups = {}

	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local text      = ts.get_node_text(node, bufnr)
		local start_row = node:range() + 1 -- 1-based
		local end_row   = select(3, node:range()) + 1

		local defgroup  = text:match("@defgroup")
		local has_open  = text:match("@{")
		local has_close = text:match("@}")

		if defgroup and has_open then
			-- contained: /** @defgroup Foo @{ */
			local name    = text:match("@defgroup%s+(%S+)")
			local desc    = text:match("@defgroup%s+%S+[ \t]+([^\n]+)")
			local ingroup = text:match("@ingroup%s+(%S+)")
			table.insert(stack, { start = start_row, name = name, desc = desc or "", ingroup = ingroup })
			pending = nil
		elseif defgroup then
			-- split style: first comment has @defgroup, next has @{
			local name    = text:match("@defgroup%s+(%S+)")
			local desc    = text:match("@defgroup%s+%S+%s+([^%s\n]+)")
			local ingroup = text:match("@ingroup%s+(%S+)")
			pending       = { start = start_row, name = name, desc = desc or "", ingroup = ingroup }
		elseif has_open then
			if pending then
				table.insert(stack, pending)
				pending = nil
			end
			-- bare @{ without a pending defgroup: ignore
		end

		if has_close then
			local top = table.remove(stack)
			if top then
				table.insert(groups, {
					start   = top.start,
					["end"] = end_row,
					name    = top.name,
					desc    = top.desc,
					ingroup = top.ingroup,
				})
			end
		end
	end

	M.groups[bufnr] = groups
end

-- Return the innermost group containing lnum (1-based)
local function find_innermost(groups, lnum)
	local best = nil
	for _, g in ipairs(groups) do
		if lnum >= g.start and lnum <= g["end"] then
			if not best or g.start > best.start then
				best = g
			end
		end
	end
	return best
end

function _G.DoxyvimFoldExpr()
	local bufnr = vim.api.nvim_get_current_buf()
	local lnum  = vim.v.lnum
	local gs    = M.groups[bufnr]
	if not gs then return 0 end
	local level = 0
	for _, g in ipairs(gs) do
		if lnum >= g.start and lnum <= g["end"] then
			level = level + 1
		end
	end
	return level
end

function _G.DoxyvimFoldText()
	local bufnr = vim.api.nvim_get_current_buf()
	local lnum  = vim.v.foldstart
	local gs    = M.groups[bufnr]
	if not gs then return "[Doxygen Group]" end
	local g = find_innermost(gs, lnum)
	if not g then return "[Doxygen Group]" end
	if g.ingroup then
		return string.format(M.config.format_child, g.ingroup, g.name, g.desc)
	else
		return string.format(M.config.format_orphan, g.name, g.desc)
	end
end

local function refresh(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	parse_groups(bufnr)
	-- force neovim to re-evaluate fold expressions
	vim.api.nvim_buf_call(bufnr, function()
		vim.cmd("normal! zx")
	end)
end

function M.setup(ft_pattern, config)
	config = config or {}
	if config.enable ~= true then return end
	M.config = config

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
		pattern = ft_pattern,
		callback = function(ev)
			local bufnr       = ev.buf
			vim.wo.foldmethod = "expr" -- use opt_local equivalents
			vim.wo.foldexpr   = "v:lua.DoxyvimFoldExpr()"
			vim.wo.foldtext   = "v:lua.DoxyvimFoldText()"
			vim.wo.foldlevel  = 0
			parse_groups(bufnr)
		end,
	})

	-- Only refresh when leaving insert mode or after a normal-mode change
	local mode_changed_pattern = { "i:n", "i:v", "i:*" }
	vim.tbl_extend("force", mode_changed_pattern, ft_pattern)
	vim.api.nvim_create_autocmd("ModeChanged", {
		pattern = mode_changed_pattern,
		callback = function(ev)
			refresh(ev.buf)
		end,
	})

	-- Also refresh on file write, in case the user saves from command mode
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = ft_pattern,
		callback = function(ev)
			refresh(ev.buf)
		end,
	})
end

return M
