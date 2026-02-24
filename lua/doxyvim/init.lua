local M = {
	config = {
		filetypes = { "*.c", "*.cpp", "*.h", "*.hpp" },
		fold = {
			enable = true,
			format_orphan = " 󰈙 %s: %s",
			format_child = " 󰈙 %s ❭ %s: %s",
			inlay_hints = {
				enable = true,
				style = { fg = "#5fafaf", bold = true },
				format = "󰭸 %s",
			}
		},
		highlight = {
			enable = true,
			hl = function(tag)
				local regular = {
					["brief"] = true,
					["file"] = true,
					["author"] = true,
					["version"] = true,
					["see"] = true,
					["since"] = true,
					["details"] = true,
					["throws"] = true,
					["exception"] = true,
					["deprecated"] = true,
					["example"] = true,
					["test"] = true,
					["def"] = true,
					["typedef"] = true,
					["var"] = true,
					["struct"] = true,
					["class"] = true,
					["enum"] = true,
					["interface"] = true,
					["package"] = true,
					["namespace"] = true,
					["fn"] = true,
					["name"] = true,
					["code"] = true,
					["endcode"] = true,
					["sa"] = true,
					["ref"] = true,
					["link"] = true,
					["endlink"] = true,
					["copydoc"] = true,
					["docRoot"] = true,
					["inheritDoc"] = true,
					["internal"] = true,
					["invariant"] = true,
					["mainpage"] = true,
					["page"] = true,
					["section"] = true,
					["subsection"] = true,
					["threadsafe"] = true,
					["nosubgrouping"] = true,
					["p"] = true,
				}
				if regular[tag] then
					return { fg = "#5f8fbf" }
				end

				local group = {
					["{"] = true,
					["}"] = true,
					["ingroup"] = true,
					["defgroup"] = true,
					["addtogroup"] = true,
				}
				if group[tag] then
					return { fg = "#da5f9a", bold = true }
				end

				-- Functions
				if tag == "param" then
					return { fg = "#7faf9f", bold = true, italic = true }
				elseif tag == "return" then
					return { fg = "#dfaf9f", bold = true, italic = true }
					-- Special
				elseif tag == "note" then
					return { fg = "#5fafff", underline = true }
				elseif tag == "todo" then
					return { fg = "#5fafff", bold = true, underline = true }
				elseif tag == "warning" then
					return { fg = "#dfaf6f", bold = true, underline = true }
				elseif tag == "bug" then
					return { fg = "#ff7f6f", bold = true, underline = true }
				end
				return nil
			end
		}
	}
}

function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	M.fold = require("doxyvim.fold")
	M.fold.setup(M.config.filetypes, M.config.fold)

	M.hl = require("doxyvim.highlight")
	M.hl.setup(M.config.filetypes, M.config.highlight)
end

return M
