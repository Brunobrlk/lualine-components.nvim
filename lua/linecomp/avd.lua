local M = {}

local function is_android_or_flutter_project()
	local flutter = vim.fs.find("pubspec.yaml", { upward = true })[1]
	if flutter then
		return true
	end

	local gradle = vim.fs.find({ "build.gradle", "build.gradle.kts" }, { upward = true })[1]

	return gradle ~= nil
end

function M.get_attached_device()
    print("debug1")
    if not is_android_or_flutter_project() then
        return ""
    end

    print("debug2")
    local handle = io.popen("adb devices -l")
    if not handle then
        return ""
    end

    print("debug3")
    local result = handle:read("*a")
    handle:close()

    print("debug4" .. result)
    for line in result:gmatch("[^\r\n]+") do
        if not line:match("^List of devices") and line:match("device") then
            local model = line:match("model:([^%s]+)")
            if model then
                return "󰄜 " .. model:gsub("_", " ")
            end
        end
    end

    return "󰥐 No device connected"
end

function M.android_model()
	return M.get_attached_device()
end

return M
