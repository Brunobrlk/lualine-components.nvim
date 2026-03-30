local M = {}

local status = {
	bufnr = nil,
	model = nil,
	tokens = 0,
}

local function get_chat_metadata(bufnr)
	if type(_G.codecompanion_chat_metadata) ~= "table" then
		return nil
	end

	if bufnr and _G.codecompanion_chat_metadata[bufnr] then
		return _G.codecompanion_chat_metadata[bufnr], bufnr
	end

	for chat_bufnr, metadata in pairs(_G.codecompanion_chat_metadata) do
		if type(metadata) == "table" then
			return metadata, chat_bufnr
		end
	end

	return nil
end

local function resolve_model(adapter)
	local model = adapter.model

	if type(model) == "function" then
		local ok, resolved_model = pcall(model, adapter)
		if ok and type(resolved_model) == "string" then
			return resolved_model
		end
		return nil
	end

	if type(model) == "table" then
		return model.default
	end

	if type(model) == "string" then
		return model
	end

	return nil
end

local function refresh(event_buf)
	local current_buf = vim.api.nvim_get_current_buf()
	local metadata, metadata_bufnr

	if vim.bo[current_buf].filetype == "codecompanion" then
		metadata, metadata_bufnr = get_chat_metadata(current_buf)
	end

	if not metadata and event_buf then
		metadata, metadata_bufnr = get_chat_metadata(event_buf)
	end

	if not metadata and status.bufnr then
		metadata, metadata_bufnr = get_chat_metadata(status.bufnr)
	end

	if not metadata then
		metadata, metadata_bufnr = get_chat_metadata(nil)
	end

	if not metadata then
		status.bufnr = nil
		status.model = nil
		status.tokens = 0
		return
	end

	local adapter = metadata.adapter or {}
	status.bufnr = metadata_bufnr
	status.model = resolve_model(adapter) or adapter.formatted_name or adapter.name
	status.tokens = tonumber(metadata.tokens) or 0
end

local function setup()
	local group = vim.api.nvim_create_augroup("LualineCodeCompanion", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = {
			"CodeCompanionChat*",
			"CodeCompanionRequest*",
			"CodeCompanionTool*",
			"CodeCompanionContextChanged",
		},
		callback = function(args)
			refresh(args.buf)
			vim.schedule(vim.cmd.redrawstatus)
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(args)
			refresh(args.buf)
		end,
	})

	refresh(nil)
end

function M.codecompanion_tokens()
	if not status.tokens or status.tokens <= 0 then
		return ""
	end

	return string.format("󰭻 %d", status.tokens)
end

function M.codecompanion_model()
	if not status.model or status.model == "" then
		return ""
	end

	return string.format("󰚩 %s", status.model)
end

setup()

return M
