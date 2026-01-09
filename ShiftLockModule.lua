-- ShiftLockModule - Bulletproof CENTERED Shiftlock
-- Forces camera to stay CENTERED (no side offset)
-- Overrides ANY other shiftlock (default or custom game scripts)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ShiftLock = {}
ShiftLock.__index = ShiftLock

function ShiftLock.new(localPlayer)
    local self = setmetatable({}, ShiftLock)

    self.player = localPlayer
    self.character = nil
    self.humanoid = nil
    self.root = nil

    self.enabled = false      -- center system enabled
    self.shiftLocked = false  -- currently locked
    self.gui = nil
    self.vIcon = nil
    self.bindName = "CustomShiftLock_" .. localPlayer.UserId
    self.bindName2 = "CustomShiftLockPost_" .. localPlayer.UserId
    self.renderConn = nil

    self.charConn = nil
    self.humConn = nil

    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    self:_updateCharacterRefs(char)
    self.charConn = localPlayer.CharacterAdded:Connect(function(c)
        self:_updateCharacterRefs(c)
        if self.shiftLocked then
            task.delay(0.5, function()
                self:_applyLock()
            end)
        end
    end)

    self:_buildGui()
    self:_bindLoop()

    return self
end

function ShiftLock:_buildGui()
    local playerGui = self.player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "ShiftLockVGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui
    self.gui = gui

    local vIcon = Instance.new("ImageLabel")
    vIcon.Name = "VIcon"
    vIcon.BackgroundTransparency = 1
    vIcon.Size = UDim2.new(0, 150, 0, 150)
    vIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    vIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    vIcon.Visible = false
    vIcon.Image = "rbxassetid://18913450789"
    vIcon.ScaleType = Enum.ScaleType.Fit
    vIcon.BorderSizePixel = 5
    vIcon.BorderColor3 = Color3.new(1, 1, 1)
    vIcon.Parent = gui

    self.vIcon = vIcon
end

function ShiftLock:_updateCharacterRefs(char)
    self.character = char
    self.humanoid = char:WaitForChild("Humanoid")
    self.root = char:WaitForChild("HumanoidRootPart")

    if self.humConn then
        self.humConn:Disconnect()
        self.humConn = nil
    end

    self.humConn = self.humanoid.Died:Connect(function()
        if self.vIcon then
            self.vIcon.Visible = false
        end
    end)
end

function ShiftLock:_doShiftLockFrame()
    local char = self.player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    
    if not hum then return end

    -- ALWAYS force CameraOffset to 0 when enabled (even if not locked yet)
    -- This prevents the camera from shifting
    if self.enabled then
        pcall(function()
            hum.CameraOffset = Vector3.new(0, 0, 0)
        end)
    end

    if not self.shiftLocked or not root then
        return
    end

    if hum.Health <= 0 then return end
    
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Dead then
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    -- FORCE everything every frame
    pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
    pcall(function() hum.AutoRotate = false end)
    pcall(function() UserInputService.MouseIconEnabled = false end)

    -- Rotate character to face camera direction
    local look = cam.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude > 0 then
        root.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)
    end
end

function ShiftLock:_bindLoop()
    pcall(function() RunService:UnbindFromRenderStep(self.bindName) end)
    pcall(function() RunService:UnbindFromRenderStep(self.bindName2) end)
    if self.renderConn then pcall(function() self.renderConn:Disconnect() end) end
    
    -- Run BEFORE game camera scripts
    RunService:BindToRenderStep(self.bindName, Enum.RenderPriority.Camera.Value - 1, function()
        self:_doShiftLockFrame()
    end)
    
    -- Run AFTER game camera scripts
    RunService:BindToRenderStep(self.bindName2, Enum.RenderPriority.Camera.Value + 100, function()
        self:_doShiftLockFrame()
    end)
    
    -- Also run with task.defer after everything
    self.renderConn = RunService.RenderStepped:Connect(function()
        if self.enabled then
            task.defer(function()
                self:_doShiftLockFrame()
            end)
        end
    end)
end

function ShiftLock:_applyLock()
    self.shiftLocked = true

    local hum = self.humanoid
    if hum then
        hum.AutoRotate = false
        hum.CameraOffset = Vector3.new(0, 0, 0)
    end

    if self.vIcon then
        self.vIcon.Visible = true
    end

    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function ShiftLock:ForceOff()
    self.shiftLocked = false

    local char = self.player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if hum then
        pcall(function() hum.AutoRotate = true end)
    end

    if self.vIcon then
        self.vIcon.Visible = false
    end

    pcall(function() UserInputService.MouseIconEnabled = true end)
    pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
end

function ShiftLock:EnableCenterSystem()
    if self.enabled then return end
    self.enabled = true
    pcall(function() self.player.DevEnableMouseLock = false end)
end

function ShiftLock:Enable()
    self:EnableCenterSystem()
    if not self.shiftLocked then
        self:_applyLock()
    end
end

function ShiftLock:Disable()
    self:ForceOff()
end

function ShiftLock:IsEnabled()
    return self.shiftLocked
end

function ShiftLock:Toggle()
    if not self.enabled then
        self:EnableCenterSystem()
    end

    if self.shiftLocked then
        self:ForceOff()
    else
        self:_applyLock()
    end
end

function ShiftLock:Destroy()
    self:ForceOff()
    self.enabled = false

    pcall(function() RunService:UnbindFromRenderStep(self.bindName) end)
    pcall(function() RunService:UnbindFromRenderStep(self.bindName2) end)
    
    if self.renderConn then
        self.renderConn:Disconnect()
        self.renderConn = nil
    end
    
    if self.charConn then
        self.charConn:Disconnect()
        self.charConn = nil
    end
    if self.humConn then
        self.humConn:Disconnect()
        self.humConn = nil
    end

    if self.gui then
        self.gui:Destroy()
        self.gui = nil
        self.vIcon = nil
    end
end

return ShiftLock
