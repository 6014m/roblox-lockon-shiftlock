-- SixZeroHub Compatibility Module for Lock-On Camera
-- Registers the lock-on script with SixZeroHub's active scripts system
-- so it can be deactivated from the hub

local SCRIPT_KEY = "LOCKON_CAMERA_V3"

local function register()
    if not _G.SixZeroHubRegister then return end

    local genv = getgenv and getgenv() or _G
    local data = genv[SCRIPT_KEY]

    if not data then
        -- script might still be loading, retry
        task.delay(2, register)
        return
    end

    local fileKey = "https://raw.githubusercontent.com/6014m/roblox-lockon-shiftlock/main/The%20Actual%20Script"

    _G.SixZeroHubRegister("Lock-On Shiftlock", fileKey, function()
        -- call the script's own cleanup
        if data.Cleanup then
            pcall(data.Cleanup)
        end

        -- disconnect all tracked connections
        if data.Connections then
            for _, conn in ipairs(data.Connections) do
                pcall(function() conn:Disconnect() end)
            end
        end

        -- unbind render step
        if data.BindName then
            pcall(function()
                game:GetService("RunService"):UnbindFromRenderStep(data.BindName)
            end)
        end

        -- destroy any lingering GUIs
        if data.Gui then
            pcall(function() data.Gui:Destroy() end)
        end

        pcall(function()
            for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:find("LockOn") then
                    gui:Destroy()
                end
            end
        end)

        pcall(function()
            local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                for _, gui in ipairs(pg:GetChildren()) do
                    if gui:IsA("ScreenGui") and gui.Name:find("LockOn") then
                        gui:Destroy()
                    end
                end
            end
        end)

        -- clear from genv
        genv[SCRIPT_KEY] = nil
    end)
end

register()
