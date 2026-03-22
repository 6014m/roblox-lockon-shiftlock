-- SixZeroHub Compatibility Module for Lock-On Camera
-- Handles deactivation only — GUI offsetting is done by the hub itself

local SCRIPT_KEY = "LOCKON_CAMERA_V3"
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local fileKey = "https://raw.githubusercontent.com/6014m/roblox-lockon-shiftlock/main/The%20Actual%20Script"

local function fullDeactivate()
    local genv = getgenv and getgenv() or _G
    local data = genv[SCRIPT_KEY]

    if data and data.Cleanup then pcall(data.Cleanup) end

    if data and data.Connections then
        for _, conn in ipairs(data.Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    if data and data.BindName then
        pcall(function() RunService:UnbindFromRenderStep(data.BindName) end)
    end
    pcall(function() RunService:UnbindFromRenderStep("LockOnForceCamera") end)

    if data and data.Gui then pcall(function() data.Gui:Destroy() end) end

    local function destroyLockOnGuis(parent)
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name:find("LockOn") then
                    child:Destroy()
                end
            end
        end)
    end
    pcall(function() destroyLockOnGuis(game:GetService("CoreGui")) end)
    pcall(function() destroyLockOnGuis(Players.LocalPlayer:FindFirstChild("PlayerGui")) end)
    pcall(function() if gethui then destroyLockOnGuis(gethui()) end end)

    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, child in ipairs(p.Character:GetChildren()) do
                    if child:IsA("Highlight") then child:Destroy() end
                end
            end
        end
    end)

    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
    genv[SCRIPT_KEY] = nil
end

task.spawn(function()
    for _ = 1, 30 do
        local genv = getgenv and getgenv() or _G
        if _G.SixZeroHubRegister and genv[SCRIPT_KEY] then
            _G.SixZeroHubRegister("Lock-On Shiftlock", fileKey, fullDeactivate)
            return
        end
        task.wait(1)
    end
end)
