local M = require("lualine.component"):extend()

function M:update_status()
	local register = vim.fn.reg_recording()
	if register == "" then
		return ""
	end

	return "recording @" .. register
end

return M
