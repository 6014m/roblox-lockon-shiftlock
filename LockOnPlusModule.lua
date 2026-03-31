-- LockOnPlusModule.lua
-- Rotates character to face lock-on target while camera stays free
-- Uses CFrame override + AlignOrientation constraint for physics-safe rotation

local RunService = game:GetService("RunService")

local LockOnPlus = {}
LockOnPlus.__index = LockOnPlus

-- getStateFn() should return: enabled, held, lockedOn, target, targetType
function LockOnPlus.new(localPlayer, getRootPartFn, getStateFn)
    local self = setmetatable({}, LockOnPlus)

    self._player = localPlayer
    self._getRootPart = getRootPartFn
    self._getState = getStateFn

    self._align = nil
    self._attachment = nil
    self._binds = {}
    self._connections = {}

    self:_setup()
    return self
end

function LockOnPlus:_getTargetRoot()
    local _, _, _, target, targetType = self._getState()
    local targetChar = (targetType == "player")
        and (target and target.Character)
        or target
    return self._getRootPart(targetChar)
end

function LockOnPlus:_shouldRun()
    local enabled, held, lockedOn, target = self._getState()
    return enabled and held and lockedOn and target
end

-- CFrame-based rotation (immediate, overrides shiftlock)
function LockOnPlus:_updateRotation()
    if not self:_shouldRun() then return end

    local myChar = self._player.Character
    if not myChar then return end
    local myRoot = self._getRootPart(myChar)
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum then return end

    local targetRoot = self:_getTargetRoot()
    if not targetRoot then return end

    local dir = targetRoot.Position - myRoot.Position
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude < 0.1 then return end

    myHum.AutoRotate = false
    local cf = CFrame.lookAt(myRoot.Position, myRoot.Position + flat)
    local _, yAngle, _ = cf:ToEulerAnglesYXZ()
    myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, yAngle, 0)
end

-- AlignOrientation constraint (physics-safe, handles fast dashes)
function LockOnPlus:_ensureConstraint()
    local myChar = self._player.Character
    if not myChar then return end
    local myRoot = self._getRootPart(myChar)
    if not myRoot then return end

    if not self._attachment or not self._attachment.Parent then
        self._attachment = Instance.new("Attachment")
        self._attachment.Name = "LockOnPlusAttachment"
        self._attachment.Parent = myRoot
    end

    if not self._align or not self._align.Parent then
        self._align = Instance.new("AlignOrientation")
        self._align.Name = "LockOnPlusAlign"
        self._align.Mode = Enum.OrientationAlignmentMode.OneAttachment
        self._align.Attachment0 = self._attachment
        self._align.RigidityEnabled = true
        self._align.Responsiveness = 200
        self._align.MaxTorque = math.huge
        self._align.Parent = myRoot
    end
end

function LockOnPlus:_updateAlignOrientation()
    if not self:_shouldRun() then
        if self._align then self._align.Enabled = false end
        return
    end

    local myChar = self._player.Character
    if not myChar then return end
    local myRoot = self._getRootPart(myChar)
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHum then return end

    local targetRoot = self:_getTargetRoot()
    if not targetRoot then return end

    local dir = targetRoot.Position - myRoot.Position
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude < 0.1 then return end

    myHum.AutoRotate = false
    self:_ensureConstraint()

    if self._align then
        self._align.Enabled = true
        self._align.CFrame = CFrame.lookAt(Vector3.zero, flat)
    end
end

function LockOnPlus:_runAll()
    self:_updateRotation()
    self:_updateAlignOrientation()
end

function LockOnPlus:_setup()
    local BIND = "LockOnPlusCharRotation"

    -- Single bind after shiftlock + camera to override rotation
    RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value + 150, function()
        self:_runAll()
    end)
    self._binds = { BIND }
    self._connections = {}
end

function LockOnPlus:Destroy()
    for _, bind in ipairs(self._binds) do
        pcall(function() RunService:UnbindFromRenderStep(bind) end)
    end
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._binds = {}
    self._connections = {}
    if self._align then pcall(function() self._align:Destroy() end); self._align = nil end
    if self._attachment then pcall(function() self._attachment:Destroy() end); self._attachment = nil end
end

return LockOnPlus
