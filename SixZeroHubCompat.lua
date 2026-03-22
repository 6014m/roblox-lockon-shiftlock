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
local movedChildren = {} -- [child] = true, tracks what we've shifted

local function getLockOnGui()
    local data = getScriptData()
    if data and data.Gui then return data.Gui end
    -- fallback: search everywhere
    local function search(parent)
        local ok, result = pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name:find("LockOn") then
                    return child
                end
            end
        end)
        return ok and result or nil
    end
    local gui = search(Players.LocalPlayer:FindFirstChild("PlayerGui") or game)
    if not gui then pcall(function() gui = search(game:GetService("CoreGui")) end) end
    if not gui then pcall(function() if gethui then gui = search(gethui()) end end) end
    return gui
end

local function applyOffset()
    local gui = getLockOnGui()
    if not gui then return end
    pcall(function()
        for _, child in ipairs(gui:GetChildren()) do
            pcall(function()
                if child:IsA("GuiObject") and not movedChildren[child] then
                    child.Position = UDim2.new(
                        child.Position.X.Scale,
                        child.Position.X.Offset + OFFSET,
                        child.Position.Y.Scale,
                        child.Position.Y.Offset
                    )
                    movedChildren[child] = true
                end
            end)
        end
    end)
end

local function removeOffset()
    for child, _ in pairs(movedChildren) do
        pcall(function()
            if child and child.Parent then
                child.Position = UDim2.new(
                    child.Position.X.Scale,
                    child.Position.X.Offset - OFFSET,
                    child.Position.Y.Scale,
                    child.Position.Y.Offset
                )
            end
        end)
    end
    movedChildren = {}
end

---------- DEACTIVATION ----------

local alive = true

local function fullDeactivate()
    alive = false
    local data, genv = getScriptData()

    removeOffset()

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

---------- MAIN LOOP ----------

task.spawn(function()
    -- register with hub
    for _ = 1, 30 do
        local data = getScriptData()
        if _G.SixZeroHubRegister and data then
            _G.SixZeroHubRegister("Lock-On Shiftlock", fileKey, fullDeactivate)
            break
        end
        task.wait(1)
    end

    -- poll visibility and keep offset in sync
    local wasVisible = nil
    while alive do
        task.wait(0.3)

        local hubVisible = _G.SixZeroHubVisible
        if hubVisible ~= wasVisible then
            if hubVisible then
                applyOffset()
            else
                removeOffset()
            end
            wasVisible = hubVisible
        elseif hubVisible then
            -- re-apply to catch newly created children (theme changes etc)
            applyOffset()
        end
    end
end)
