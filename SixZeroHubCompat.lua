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

local lockonGuiMoved = false
local originalPositions = {}

local function findLockOnGui()
    local data = getScriptData()
    if data and data.Gui and data.Gui.Parent then
        return data.Gui
    end
    -- search by name pattern
    local function searchIn(parent)
        local ok, result = pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name:find("LockOn") then
                    return child
                end
            end
        end)
        return ok and result or nil
    end
    local gui = searchIn(Players.LocalPlayer:WaitForChild("PlayerGui"))
    if not gui then pcall(function() gui = searchIn(game:GetService("CoreGui")) end) end
    if not gui then pcall(function() if gethui then gui = searchIn(gethui()) end end) end
    return gui
end

local function moveLockOnGui()
    local gui = findLockOnGui()
    if not gui then return end

    -- offset bottom-left elements so they don't overlap sixzerohub buttons
    -- the lock-on open button sits at (12, bottom-48), move it right
    for _, child in ipairs(gui:GetDescendants()) do
        if child:IsA("GuiObject") then
            local pos = child.AbsolutePosition
            -- catch anything in the bottom-left corner area (where Active/Uni buttons are)
            if pos.X < 80 and pos.Y > (workspace.CurrentCamera.ViewportSize.Y - 100) then
                if not originalPositions[child] then
                    originalPositions[child] = child.Position
                end
                child.Position = UDim2.new(
                    child.Position.X.Scale, child.Position.X.Offset + 70,
                    child.Position.Y.Scale, child.Position.Y.Offset
                )
            end
            -- catch anything in the top-left corner area (where the slant is)
            if pos.X < 150 and pos.Y < 150 then
                if not originalPositions[child] then
                    originalPositions[child] = child.Position
                end
                child.Position = UDim2.new(
                    child.Position.X.Scale, child.Position.X.Offset + 150,
                    child.Position.Y.Scale, child.Position.Y.Offset
                )
            end
        end
    end
    lockonGuiMoved = true
end

local function restoreLockOnGui()
    for child, origPos in pairs(originalPositions) do
        if child and child.Parent then
            pcall(function() child.Position = origPos end)
        end
    end
    originalPositions = {}
    lockonGuiMoved = false
end

---------- DEACTIVATION ----------

local function fullDeactivate()
    local data, genv = getScriptData()

    -- restore positions first
    restoreLockOnGui()

    -- call the script's own cleanup
    if data and data.Cleanup then
        pcall(data.Cleanup)
    end

    -- disconnect all tracked connections
    if data and data.Connections then
        for _, conn in ipairs(data.Connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    -- unbind all render step names
    if data and data.BindName then
        pcall(function() RunService:UnbindFromRenderStep(data.BindName) end)
    end
    pcall(function() RunService:UnbindFromRenderStep("LockOnForceCamera") end)

    -- destroy GUI
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

    -- remove highlights
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
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)

    genv[SCRIPT_KEY] = nil
end

---------- REGISTRATION ----------

local function tryRegister()
    if not _G.SixZeroHubRegister then return false end
    local data = getScriptData()
    if not data then return false end

    _G.SixZeroHubRegister("Lock-On Shiftlock", fileKey, fullDeactivate)
    return true
end

task.spawn(function()
    -- wait for both systems to be ready
    for _ = 1, 30 do
        if tryRegister() then break end
        task.wait(1)
    end

    -- wait a bit for the lock-on GUI to finish building, then move it
    task.wait(2)
    moveLockOnGui()

    -- also re-check periodically in case the GUI rebuilds (theme change etc)
    task.spawn(function()
        while true do
            task.wait(5)
            local data = getScriptData()
            if not data then break end -- script was deactivated
            if not lockonGuiMoved then
                moveLockOnGui()
            end
        end
    end)
end)
