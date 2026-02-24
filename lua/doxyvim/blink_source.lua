-- blink_source.lua
local comp = require("doxyvim.completion")

local M = {
	trigger_characters = { "@" }
}

local defaults = {
	max_entries = 30,
	preselect_current_word = true,
	keep_all_entries = true,
	use_cmp_spell_sorting = false,
	enable_in_context = function()
		return true
	end,
}

function M:get_trigger_characters()
	return { "@", "\\" }
end

function M.new(opts)
	local config = vim.tbl_deep_extend('keep', opts or {}, defaults)
	if vim.fn.has('nvim-0.11') == 1 then
		vim.validate('max_entries', config.max_entries, 'number')
		vim.validate('enable_in_context', config.enable_in_context, 'function')
		vim.validate('preselect_current_word', config.preselect_current_word, 'boolean')
		vim.validate('keep_all_entries', config.keep_all_entries, 'boolean')
		vim.validate('use_cmp_spell_sorting', config.use_cmp_spell_sorting, 'boolean')
	else
		vim.validate {
			max_entries = { config.max_entries, 'number' },
			enable_in_context = { config.enable_in_context, 'function' },
			preselect_current_word = { config.preselect_current_word, 'boolean' },
			keep_all_entries = { config.keep_all_entries, 'boolean' },
			use_cmp_spell_sorting = { config.use_cmp_spell_sorting, 'boolean' },
		}
	end

	return setmetatable(config, { __index = M })
end

local function candidates(input)
	local text_kind = vim.lsp.protocol.CompletionItemKind.Keyword

	local trigger = input:sub(1, 1)
	if trigger ~= "@" and trigger ~= "\\" then
		return {}
	end

	local cands = {}
	-- FIXME: Off by one bug when placing the cursor
	for i, entry in ipairs(comp.doxyvim_completions(#input > 1 and input:sub(2) or nil)) do
		cands[i] = {
			label = trigger .. entry,
			filterText = entry,
			insertText = trigger .. entry .. " ",
			kind = text_kind,
			preselect = false,
		}
	end
	return cands
end

function M:get_completions(context, callback)
	vim.schedule(function()
		local start_col = context.bounds.start_col
		local length = context.bounds.length
		if context.bounds.start_col > 0 and context.trigger then
			start_col = context.bounds.start_col - 1
			length = context.bounds.length + 1
		end
		local input = string.sub(
			context.line,
			start_col,
			start_col + length - 1
		)

		if comp.in_comment() == true then
			callback {
				items = candidates(input),
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
