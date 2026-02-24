-- blink_source.lua
local comp = require("doxyvim.completion")

local M = {
}

function M:get_trigger_characters()
	return { "@", "\\" }
end

function M.new(opts)
	local config = vim.tbl_deep_extend('keep', opts or {}, {})

	return setmetatable(config, { __index = M })
end

local function candidates(trigger, input)
	local text_kind = vim.lsp.protocol.CompletionItemKind.Text

	local cands = {}
	for i, entry in ipairs(comp.doxyvim_completions(input)) do
		cands[i] = {
			label = trigger .. entry,
			filterText = entry,
			insertText = trigger .. entry,
			detail = "Doxygen",
			kind = text_kind,
			preselect = true,
		}
	end
	return cands
end

function M:get_completions(context, callback)
	vim.schedule(function()
		local trigger = ""
		if context.trigger then
			trigger = context.trigger.initial_character or ""
		end
		local input = string.sub(
			context.line,
			context.bounds.start_col,
			context.bounds.start_col + context.bounds.length - 1
		)


		if comp.in_comment() == true then
			callback {
				items = candidates(trigger, input),
				is_incomplete_forward = true,
				is_incomplete_backward = true,
			}
		else
			callback {
				items = {},
				is_incomplete_forward = true,
				is_incomplete_backward = true,
			}
		end
	end)
end

return M
