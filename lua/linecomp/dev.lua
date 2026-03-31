local M = {}

function M.dev_indicator()
	if vim.env.NVIM_APPNAME == "nvim-dev" then
		return " DEV"
	end
	return ""
end

return M
