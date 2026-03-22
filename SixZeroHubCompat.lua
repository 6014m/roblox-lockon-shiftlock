-- SixZeroHub Compatibility Module for Lock-On Camera
-- Registers with SixZeroHub for deactivation and moves GUI to avoid overlap

local SCRIPT_KEY = "LOCKON_CAMERA_V3"
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local fileKey = "https://raw.githubusercontent.com/6014m/roblox-lockon-shiftlock/main/The%20Actual%20Script"

local function getScriptData()
    local genv = getgenv and getgenv() or _G
    return genv[SCRIPT_KEY], genv
end

---------- GUI OFFSET ----------

local OFFSET_X = 70
local originalPositions = {}
local movedGuiRef = nil

local function moveChildren(gui)
    if not gui or not gui.Parent then return end
    if movedGuiRef == gui then return end

    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("GuiObject") then
            originalPositions[child] = child.Position
            child.Position = UDim2.new(
                child.Position.X.Scale,
                child.Position.X.Offset + OFFSET_X,
                child.Position.Y.Scale,
                child.Position.Y.Offset
            )
        end
    end
    movedGuiRef = gui
end

local function restoreChildren()
    for child, pos in pairs(originalPositions) do
        pcall(function()
            if child and child.Parent then
                child.Position = pos
            end
        end)
    end
    originalPositions = {}
    movedGuiRef = nil
end

---------- DEACTIVATION ----------

local function fullDeactivate()
    local data, genv = getScriptData()

    restoreChildren()

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

---------- TOGGLE LISTENER ----------

-- when SixZeroHub is hidden, restore lock-on GUI; when shown, offset it again
_G.SixZeroHubOnToggle = function(visible)
    local data = getScriptData()
    if not data or not data.Gui or not data.Gui.Parent then return end

    if visible then
        moveChildren(data.Gui)
    else
        restoreChildren()
    end
end

---------- REGISTRATION ----------

task.spawn(function()
    for _ = 1, 30 do
        local data = getScriptData()
        if _G.SixZeroHubRegister and data then
            _G.SixZeroHubRegister("Lock-On Shiftlock", fileKey, fullDeactivate)
            break
        end
        task.wait(1)
    end

    -- wait for lock-on GUI to be fully built then move its children
    for _ = 1, 30 do
        local data = getScriptData()
        if data and data.Gui and data.Gui.Parent and #data.Gui:GetChildren() > 0 then
            moveChildren(data.Gui)
            break
        end
        task.wait(1)
    end

    -- watch for GUI recreation (theme changes rebuild it)
    while true do
        task.wait(3)
        local data = getScriptData()
        if not data then break end
        if data.Gui and data.Gui.Parent and data.Gui ~= movedGuiRef and #data.Gui:GetChildren() > 0 then
            originalPositions = {}
            moveChildren(data.Gui)
        end
    end
end)
