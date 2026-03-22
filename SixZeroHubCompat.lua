-- SixZeroHub Compatibility Module for Lock-On Camera

local SCRIPT_KEY = "LOCKON_CAMERA_V3"
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local fileKey = "https://raw.githubusercontent.com/6014m/roblox-lockon-shiftlock/main/The%20Actual%20Script"

local function getScriptData()
    local genv = getgenv and getgenv() or _G
    return genv[SCRIPT_KEY], genv
end

---------- GUI OFFSET ----------

local OFFSET = 70
local isOffset = false

local function shiftLockOnGui(direction)
    pcall(function()
        local data = getScriptData()
        if not data or not data.Gui or not data.Gui.Parent then return end

        local dx = direction * OFFSET
        for _, child in ipairs(data.Gui:GetChildren()) do
            pcall(function()
                if child:IsA("GuiObject") then
                    child.Position = UDim2.new(
                        child.Position.X.Scale,
                        child.Position.X.Offset + dx,
                        child.Position.Y.Scale,
                        child.Position.Y.Offset
                    )
                end
            end)
        end
    end)
end

local function applyOffset()
    if not isOffset then
        shiftLockOnGui(1)
        isOffset = true
    end
end

local function removeOffset()
    if isOffset then
        shiftLockOnGui(-1)
        isOffset = false
    end
end

---------- DEACTIVATION ----------

local alive = true

local function fullDeactivate()
    alive = false
    local data, genv = getScriptData()

    removeOffset()

    if data and data.Cleanup then
        pcall(data.Cleanup)
    end

    if data and data.Connections then
        for _, conn in ipairs(data.Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    if data and data.BindName then
        pcall(function() RunService:UnbindFromRenderStep(data.BindName) end)
    end
    pcall(function() RunService:UnbindFromRenderStep("LockOnForceCamera") end)

    if data and data.Gui then
        pcall(function() data.Gui:Destroy() end)
    end

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

---------- REGISTRATION + POLLING ----------

task.spawn(function()
    -- wait for both systems
    for _ = 1, 30 do
        local data = getScriptData()
        if _G.SixZeroHubRegister and data then
            _G.SixZeroHubRegister("Lock-On Shiftlock", fileKey, fullDeactivate)
            break
        end
        task.wait(1)
    end

    -- wait for GUI to exist
    for _ = 1, 30 do
        local data = getScriptData()
        if data and data.Gui and data.Gui.Parent and #data.Gui:GetChildren() > 0 then
            if _G.SixZeroHubVisible then
                applyOffset()
            end
            break
        end
        task.wait(1)
    end

    -- poll _G.SixZeroHubVisible every 0.2s to react to toggle
    local lastState = _G.SixZeroHubVisible
    while alive do
        task.wait(0.2)
        local currentState = _G.SixZeroHubVisible
        if currentState ~= lastState then
            if currentState then
                applyOffset()
            else
                removeOffset()
            end
            lastState = currentState
        end
    end
end)
