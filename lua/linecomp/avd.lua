local M = {}

local function is_android_or_flutter_project()
	local flutter = vim.fs.find("pubspec.yaml", { upward = true })[1]
	if flutter then
		return true
	end

	local gradle = vim.fs.find({ "build.gradle", "build.gradle.kts" }, { upward = true })[1]

	return gradle ~= nil
end

local function get_adb_output()
	local completed = vim.system({ "adb", "devices", "-l" }, { text = true }):wait()
	if completed.code ~= 0 then
		return ""
	end

	return completed.stdout or ""
end

local function parse_device_label(line)
	local serial, state = line:match("^(%S+)%s+(%S+)")
	if not serial or state ~= "device" then
		return nil
	end

	local model = line:match("model:([^%s]+)")
	if model and model ~= "" then
		return "󰄜 " .. model:gsub("_", " ")
	end

	return "󰄜 " .. serial
end

function M.get_attached_device()
	if not is_android_or_flutter_project() then
		return ""
	end

	local output = get_adb_output()
	for line in output:gmatch("[^\r\n]+") do
		if not line:match("^List of devices") then
			local device_label = parse_device_label(line)
			if device_label then
				return device_label
			end
		end
	end

	return "󰥐 No device connected"
end

function M.android_model()
	return M.get_attached_device()
end

return M
