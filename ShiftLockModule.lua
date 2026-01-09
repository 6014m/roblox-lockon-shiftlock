-- ShiftLockModule - Bulletproof Custom Shiftlock
-- Forces CENTERED shiftlock by taking complete control every frame
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

    self.charConn = nil
    self.humConn = nil

    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    self:_updateCharacterRefs(char)
    self.charConn = localPlayer.CharacterAdded:Connect(function(c)
        self:_updateCharacterRefs(c)
        -- Re-apply lock if was locked before respawn
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

-- internal: build the V icon GUI
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

-- internal: refresh humanoid / root references
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

-- The actual shiftlock logic - called from multiple places to ensure override
function ShiftLock:_doShiftLockFrame()
    if not self.enabled or not self.shiftLocked then
        return
    end

    local char = self.player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    
    if not hum or not root then return end

    -- Skip during certain states
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

    -- FORCE mouse to center EVERY frame
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end)
    
    -- FORCE auto-rotate off every frame
    pcall(function()
        hum.AutoRotate = false
    end)
    
    -- FORCE camera offset to 0 (CENTERED, not over-shoulder)
    pcall(function()
        hum.CameraOffset = Vector3.new(0, 0, 0)
    end)
    
    -- FORCE mouse icon hidden
    pcall(function()
        UserInputService.MouseIconEnabled = false
    end)

    -- Rotate character to face camera direction
    local look = cam.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude > 0 then
        root.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)
    end
end

-- internal: main loop - TRIPLE BIND for maximum override
function ShiftLock:_bindLoop()
    pcall(function() RunService:UnbindFromRenderStep(self.bindName) end)
    pcall(function() RunService:UnbindFromRenderStep(self.bindName2) end)
    
    -- FIRST PASS: Run BEFORE camera scripts (high priority number = runs later, but we want early too)
    RunService:BindToRenderStep(self.bindName, Enum.RenderPriority.Camera.Value - 1, function()
        self:_doShiftLockFrame()
    end)
    
    -- SECOND PASS: Run AFTER camera scripts to override whatever they did
    RunService:BindToRenderStep(self.bindName2, Enum.RenderPriority.Camera.Value + 100, function()
        self:_doShiftLockFrame()
    end)
    
    -- THIRD PASS: Also use RenderStepped with task.defer for one more override after everything
    self.renderConn = RunService.RenderStepped:Connect(function()
        if self.enabled and self.shiftLocked then
            task.defer(function()
                self:_doShiftLockFrame()
            end)
        end
    end)
end

-- internal: apply lock visuals / mouse
function ShiftLock:_applyLock()
    self.shiftLocked = true

    if self.humanoid then
        self.humanoid.AutoRotate = false
        self.humanoid.CameraOffset = Vector3.new(0, 0, 0)
    end

    if self.vIcon then
        self.vIcon.Visible = true
    end

    UserInputService.MouseIconEnabled = false
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

-- public: fully unlock mouse, hide icon
function ShiftLock:ForceOff()
    self.shiftLocked = false

    if self.humanoid then
        pcall(function() self.humanoid.AutoRotate = true end)
    end

    if self.vIcon then
        self.vIcon.Visible = false
    end

    pcall(function() UserInputService.MouseIconEnabled = true end)
    pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
end

-- public: called once when you press "Center shift-lock" button
function ShiftLock:EnableCenterSystem()
    if self.enabled then return end

    self.enabled = true

    -- kill default Dev shiftlock
    pcall(function()
        self.player.DevEnableMouseLock = false
    end)
end

-- public: enable shiftlock directly (for auto-enable feature)
function ShiftLock:Enable()
    self:EnableCenterSystem()
    if not self.shiftLocked then
        self:_applyLock()
    end
end

-- public: disable shiftlock directly
function ShiftLock:Disable()
    self:ForceOff()
end

-- public: check if currently locked
function ShiftLock:IsEnabled()
    return self.shiftLocked
end

-- public: toggle on key press
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

-- public: clean up everything
function ShiftLock:Destroy()
    self:ForceOff()

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
