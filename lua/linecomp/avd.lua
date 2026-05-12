local M = {}

local cached_label = ""
local last_project_check = 0
local is_project_cached = false

local adb_running = false
local last_adb_refresh = 0

local PROJECT_CHECK_INTERVAL_MS = 5000
local ADB_REFRESH_INTERVAL_MS = 3000

local function now_ms()
	return vim.uv.hrtime() / 1e6
end

local function is_android_or_flutter_project()
	local now = now_ms()

	if now - last_project_check < PROJECT_CHECK_INTERVAL_MS then
		return is_project_cached
	end

	last_project_check = now

	local flutter = vim.fs.find("pubspec.yaml", { upward = true })[1]
	if flutter then
		is_project_cached = true
		return true
	end

	local gradle = vim.fs.find({ "build.gradle", "build.gradle.kts" }, { upward = true })[1]
	is_project_cached = gradle ~= nil

	return is_project_cached
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

local function parse_adb_output(output)
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

local function refresh_adb_async()
	if adb_running then
		return
	end

	local now = now_ms()

	if now - last_adb_refresh < ADB_REFRESH_INTERVAL_MS then
		return
	end

	last_adb_refresh = now
	adb_running = true

	vim.system({ "adb", "devices", "-l" }, { text = true }, function(completed)
		adb_running = false

		local next_label

		if completed.code ~= 0 then
			next_label = "󰥐 ADB unavailable"
		else
			next_label = parse_adb_output(completed.stdout or "")
		end

		vim.schedule(function()
			cached_label = next_label

			-- Ask Neovim/statusline to redraw, but do not block input.
			vim.cmd("redrawstatus")
		end)
	end)
end

function M.get_attached_device()
	if not is_android_or_flutter_project() then
		return ""
	end

	refresh_adb_async()

	return cached_label
end

function M.android_model()
	return M.get_attached_device()
end

return M
