-- ReplicatedStorage.LockOnTargetingModule

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Targeting = {}
Targeting.__index = Targeting

local function getRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

function Targeting.new(localPlayer, camera)
    local self = setmetatable({}, Targeting)

    self.localPlayer = localPlayer
    self.camera = camera or Workspace.CurrentCamera

    -- external table you can share from your main script (friendlies[userId] = true)
    self.friendlies = {}

    self.realisticEnabled = false
    self.checkHealthEnabled = false
    self.visibilityCheckEnabled = false
    self.rangeLimit = 0 -- 0 = infinite

    return self
end

function Targeting:SetFriendliesTable(tbl)
    self.friendlies = tbl or self.friendlies
end

function Targeting:SetOptions(options)
    if not options then return end

    if options.realisticEnabled ~= nil then
        self.realisticEnabled = options.realisticEnabled
    end
    if options.checkHealthEnabled ~= nil then
        self.checkHealthEnabled = options.checkHealthEnabled
    end
    if options.visibilityCheckEnabled ~= nil then
        self.visibilityCheckEnabled = options.visibilityCheckEnabled
    end
    if options.rangeLimit ~= nil then
        self.rangeLimit = options.rangeLimit
    end
end

function Targeting:IsFriendly(plr)
    return self.friendlies and self.friendlies[plr.UserId] == true
end

function Targeting:IsInFront(root)
    if not self.realisticEnabled then
        return true
    end

    local cam = self.camera or Workspace.CurrentCamera
    if not cam then return true end

    local camCF = cam.CFrame
    local toTarget = root.Position - camCF.Position
    local mag = toTarget.Magnitude
    if mag <= 0.01 then
        return false
    end

    local dir = toTarget / mag
    local dot = dir:Dot(camCF.LookVector)
    local realisticFOVCos = math.cos(math.rad(60))
    return dot >= realisticFOVCos
end

function Targeting:IsAliveAndUnshielded(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    if self.checkHealthEnabled then
        if hum.Health <= 0 then
            return false
        end
        if char:FindFirstChildOfClass("ForceField") then
            return false
        end
    end

    return true
end

function Targeting:IsPlayerVisible(plr)
    if not plr then return false end
    local char = plr.Character
    local root = getRootPart(char)
    if not root then return false end

    local cam = self.camera or Workspace.CurrentCamera
    if not cam then return true end

    local origin = cam.CFrame.Position
    local direction = root.Position - origin
    if direction.Magnitude <= 0.01 then
        return true
    end

    local ignoreList = { self.localPlayer.Character }
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignoreList

    while true do
        local result = Workspace:Raycast(origin, direction, params)
        if not result then
            return true
        end

        local hit = result.Instance
        if hit:IsDescendantOf(char) then
            return true
        end

        if hit:IsA("BasePart") then
            local transparency = hit.Transparency or 0
            local canCollide = hit.CanCollide
            if transparency > 0.4 and not canCollide then
                table.insert(ignoreList, hit)
                params.FilterDescendantsInstances = ignoreList

                local dirUnit = direction.Unit
                origin = result.Position + dirUnit * 0.05
                direction = root.Position - origin
                if direction.Magnitude <= 0.01 then
                    return true
                end
            else
                return false
            end
        else
            return false
        end
    end
end

function Targeting:GetNearestPlayer(excludePlayer)
    local myChar = self.localPlayer.Character
    local myRoot = getRootPart(myChar)
    if not myRoot then return nil end

    local closestPlr = nil
    local closestDist = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= self.localPlayer and plr ~= excludePlayer and not self:IsFriendly(plr) then
            local char = plr.Character
            local root = getRootPart(char)
            if root and self:IsInFront(root) and self:IsAliveAndUnshielded(char) then
                local dist = (root.Position - myRoot.Position).Magnitude
                if (self.rangeLimit <= 0 or dist <= self.rangeLimit) and dist < closestDist then
                    closestDist = dist
                    closestPlr = plr
                end
            end
        end
    end

    return closestPlr
end

function Targeting:GetNearestVisiblePlayer(excludePlayer)
    local myChar = self.localPlayer.Character
    local myRoot = getRootPart(myChar)
    if not myRoot then return nil end

    local closestPlr = nil
    local closestDist = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= self.localPlayer and plr ~= excludePlayer and not self:IsFriendly(plr) then
            local char = plr.Character
            local root = getRootPart(char)
            if root and self:IsInFront(root) and self:IsAliveAndUnshielded(char) and self:IsPlayerVisible(plr) then
                local dist = (root.Position - myRoot.Position).Magnitude
                if (self.rangeLimit <= 0 or dist <= self.rangeLimit) and dist < closestDist then
                    closestDist = dist
                    closestPlr = plr
                end
            end
        end
    end

    return closestPlr
end

function Targeting:GetBestTarget(excludePlayer)
    if self.visibilityCheckEnabled then
        return self:GetNearestVisiblePlayer(excludePlayer)
    else
        return self:GetNearestPlayer(excludePlayer)
    end
end

return Targeting
