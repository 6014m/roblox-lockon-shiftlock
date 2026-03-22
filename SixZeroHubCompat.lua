-- SixZeroHub Compatibility Module for Lock-On Camera
-- Registers the lock-on script with SixZeroHub's active scripts system

local SCRIPT_KEY = "LOCKON_CAMERA_V3"
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local fileKey = "https://raw.githubusercontent.com/6014m/roblox-lockon-shiftlock/main/The%20Actual%20Script"

local function getScriptData()
    local genv = getgenv and getgenv() or _G
    return genv[SCRIPT_KEY], genv
end

local function fullDeactivate()
    local data, genv = getScriptData()

    -- call the script's own cleanup first (disconnects, unbinds, destroys)
    if data and data.Cleanup then
        pcall(data.Cleanup)
    end

    -- disconnect all tracked connections
    if data and data.Connections then
        for _, conn in ipairs(data.Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    -- unbind all possible render step names
    if data and data.BindName then
        pcall(function() RunService:UnbindFromRenderStep(data.BindName) end)
    end
    pcall(function() RunService:UnbindFromRenderStep("LockOnForceCamera") end)

    -- destroy the GUI stored in script data
    if data and data.Gui then
        pcall(function() data.Gui:Destroy() end)
    end

    -- hunt down and destroy ALL lock-on GUIs everywhere
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

    local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if pg then destroyLockOnGuis(pg) end

    pcall(function()
        if gethui then destroyLockOnGuis(gethui()) end
    end)

    -- destroy any highlights on characters (lock-on target highlights)
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                for _, child in ipairs(p.Character:GetChildren()) do
                    if child:IsA("Highlight") then
                        child:Destroy()
                    end
                end
            end
        end
    end)

    -- restore camera
    pcall(function()
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end)

    -- clear script data from genv
    genv[SCRIPT_KEY] = nil
end

-- wait for both SixZeroHub and the lock-on script to be ready
local function tryRegister()
    if not _G.SixZeroHubRegister then return false end

    local data = getScriptData()
    if not data then return false end

    _G.SixZeroHubRegister("Lock-On Shiftlock", fileKey, fullDeactivate)
    return true
end

-- retry until both systems are ready
task.spawn(function()
    for _ = 1, 30 do
        if tryRegister() then return end
        task.wait(1)
    end
end)
