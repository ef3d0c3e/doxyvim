local M = {
	config = {
		fold = {
			enable = true,
			format_orphan = " 󰈙 %s: %s",
			format_child = " 󰈙 %s ❭ %s: %s",
		}
	}
}

function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})
	M.fold = require("doxyvim.fold")

	M.fold.setup(M.config.fold)
end

return M
