-- ShiftLockModule - Custom shiftlock with proper death/respawn handling

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

    self.enabled = false      -- center system enabled (after pressing the button)
    self.shiftLocked = false  -- currently locked
    self.gui = nil
    self.vIcon = nil

    self.charConn = nil
    self.humConn = nil
    self.loopConn = nil
    self.focusConn = nil

    local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    self:_updateCharacterRefs(char)
    self.charConn = localPlayer.CharacterAdded:Connect(function(c)
        self:_updateCharacterRefs(c)
        self:ForceOff()
    end)

    self:_buildGui()
    self:_bindLoop()
    self:_bindWindowFocus()

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
        self.shiftLocked = false
        self:ForceOff()
    end)
end

-- Disable the game's built-in shiftlock so it doesn't conflict
function ShiftLock:_disableGameShiftLock()
    pcall(function()
        self.player.DevEnableMouseLock = false
    end)
end

-- internal: main loop (same structure as original)
function ShiftLock:_bindLoop()
    if self.loopConn then
        self.loopConn:Disconnect()
        self.loopConn = nil
    end

    self.loopConn = RunService.RenderStepped:Connect(function()
        if not self.enabled then
            return
        end

        local char = self.player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.CameraOffset = Vector3.new(0, 0, 0)
        end

        if not self.shiftLocked or not self.root or not self.humanoid then
            return
        end

        -- Check health/state BEFORE forcing mouse lock
        if self.humanoid.PlatformStand or self.humanoid.Health <= 0 then
            return
        end

        local state = self.humanoid:GetState()
        if state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Dead then
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then return end

        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end

        -- Rotate character to face camera (Y axis only)
        local look = cam.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude > 0 then
            self.root.CFrame = CFrame.lookAt(self.root.Position, self.root.Position + flatLook)
        end
    end)
end

-- internal: unlock when window loses focus (alt-tab etc)
function ShiftLock:_bindWindowFocus()
    if self.focusConn then
        self.focusConn:Disconnect()
        self.focusConn = nil
    end

    self.focusConn = UserInputService.WindowFocusReleased:Connect(function()
        if self.shiftLocked then
            self:ForceOff()
        end
    end)
end

-- internal: apply lock visuals / mouse
function ShiftLock:_applyLock()
    self.shiftLocked = true
    
    -- Disable game's shiftlock
    self:_disableGameShiftLock()

    if self.humanoid then
        self.humanoid.AutoRotate = false
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
        self.humanoid.AutoRotate = true
    end

    if self.vIcon then
        self.vIcon.Visible = false
    end

    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

-- public: called once when you press "Center shift-lock" button
function ShiftLock:EnableCenterSystem()
    if self.enabled then return end

    self.enabled = true
    
    -- Disable game's shiftlock
    self:_disableGameShiftLock()

    self:ForceOff()
end

-- public: enable shiftlock directly (for auto-enable feature)
function ShiftLock:Enable()
    if not self.enabled then
        self.enabled = true
        self:_disableGameShiftLock()
    end
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

-- public: toggle on LeftShift
function ShiftLock:Toggle()
    if not self.enabled then
        self.enabled = true
        self:_disableGameShiftLock()
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

    if self.loopConn then
        self.loopConn:Disconnect()
        self.loopConn = nil
    end
    if self.charConn then
        self.charConn:Disconnect()
        self.charConn = nil
    end
    if self.humConn then
        self.humConn:Disconnect()
        self.humConn = nil
    end
    if self.focusConn then
        self.focusConn:Disconnect()
        self.focusConn = nil
    end

    if self.gui then
        self.gui:Destroy()
        self.gui = nil
        self.vIcon = nil
    end
end

return ShiftLock
