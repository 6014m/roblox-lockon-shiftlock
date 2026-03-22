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

local function getLockOnGui()
    local data = getScriptData()
    if data and data.Gui and data.Gui.Parent then return data.Gui end
    local function search(parent)
        if not parent then return nil end
        local ok, result = pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and child.Name:find("LockOn") then
                    return child
                end
            end
        end)
        return ok and result or nil
    end
    local gui = search(Players.LocalPlayer:FindFirstChild("PlayerGui"))
    if not gui then pcall(function() gui = search(game:GetService("CoreGui")) end) end
    if not gui then pcall(function() if gethui then gui = search(gethui()) end end) end
    return gui
end

-- no state tracking — just look at where elements are and fix them
local function ensureOffset()
    local gui = getLockOnGui()
    if not gui then return end
    pcall(function()
        for _, child in ipairs(gui:GetChildren()) do
            pcall(function()
                if child:IsA("GuiObject") then
                    -- if element's X offset is below threshold, it needs shifting
                    if child.Position.X.Offset < OFFSET then
                        child.Position = UDim2.new(
                            child.Position.X.Scale,
                            child.Position.X.Offset + OFFSET,
                            child.Position.Y.Scale,
                            child.Position.Y.Offset
                        )
                    end
                end
            end)
        end
    end)
end

local function ensureNoOffset()
    local gui = getLockOnGui()
    if not gui then return end
    pcall(function()
        for _, child in ipairs(gui:GetChildren()) do
            pcall(function()
                if child:IsA("GuiObject") then
                    -- if element's X offset is at or above threshold, it was shifted by us
                    if child.Position.X.Offset >= OFFSET then
                        child.Position = UDim2.new(
                            child.Position.X.Scale,
                            child.Position.X.Offset - OFFSET,
                            child.Position.Y.Scale,
                            child.Position.Y.Offset
                        )
                    end
                end
            end)
        end
    end)
end

---------- DEACTIVATION ----------

local alive = true

local function fullDeactivate()
    alive = false
    local data, genv = getScriptData()

    ensureNoOffset()

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

    -- continuously enforce correct offset state
    while alive do
        task.wait(0.3)
        pcall(function()
            if _G.SixZeroHubVisible then
                ensureOffset()
            else
                ensureNoOffset()
            end
        end)
    end
end)
