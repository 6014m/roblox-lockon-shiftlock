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

local originalGuiPos = nil
local movedGui = nil

local function findAndMoveLockOnGui()
    local data = getScriptData()
    if not data then return end

    local gui = data.Gui
    if not gui or not gui.Parent then return end
    if movedGui == gui then return end -- already moved this one

    -- store original position
    originalGuiPos = gui.Position

    -- offset the entire ScreenGui so nothing overlaps the sixzerohub corner/buttons
    gui.Position = UDim2.new(0, 70, 0, 0)
    movedGui = gui
end

local function restoreLockOnGui()
    if movedGui and movedGui.Parent and originalGuiPos then
        pcall(function() movedGui.Position = originalGuiPos end)
    end
    movedGui = nil
    originalGuiPos = nil
end

---------- DEACTIVATION ----------

local function fullDeactivate()
    local data, genv = getScriptData()

    restoreLockOnGui()

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

---------- REGISTRATION ----------

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

    -- wait for lock-on GUI to exist then move it
    for _ = 1, 20 do
        local data = getScriptData()
        if data and data.Gui and data.Gui.Parent then
            findAndMoveLockOnGui()
            break
        end
        task.wait(1)
    end

    -- keep checking in case GUI gets recreated (theme changes etc)
    while true do
        task.wait(3)
        local data = getScriptData()
        if not data then break end
        if data.Gui and data.Gui.Parent and data.Gui ~= movedGui then
            findAndMoveLockOnGui()
        end
    end
end)
