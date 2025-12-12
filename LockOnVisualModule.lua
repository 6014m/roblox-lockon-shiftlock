-- ReplicatedStorage.LockOnVisualModule

local Visual = {}
Visual.__index = Visual

function Visual.new(localPlayer)
    local self = setmetatable({}, Visual)

    self.localPlayer = localPlayer

    self.highlights = {} -- [Player] = Highlight
    self.highlightEnabled = false
    self.highlightSecondEnabled = false
    self.selfFadeEnabled = false

    self.charConn = nil

    self.charConn = localPlayer.CharacterAdded:Connect(function(char)
        if self.selfFadeEnabled then
            char:WaitForChild("HumanoidRootPart", 5)
            self:_applySelfFadeToCharacter(char)
        end
    end)

    return self
end

-- internal: self fade on char
function Visual:_applySelfFadeToCharacter(char)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = self.selfFadeEnabled and 0.6 or 0
        elseif d:IsA("Decal") then
            d.Transparency = self.selfFadeEnabled and 0.6 or 0
        end
    end
end

-- public: toggle self fade
function Visual:SetSelfFadeEnabled(enabled)
    self.selfFadeEnabled = enabled and true or false
    self:_applySelfFadeToCharacter(self.localPlayer.Character)
end

function Visual:IsSelfFadeEnabled()
    return self.selfFadeEnabled
end

-- internal: single highlight
function Visual:_setHighlight(plr, color, enabled)
    local h = self.highlights[plr]

    if enabled then
        if not h or not h.Parent then
            h = Instance.new("Highlight")
            h.Name = "LockOnHighlight"
            self.highlights[plr] = h
        end

        local char = plr.Character
        if not char then
            h:Destroy()
            self.highlights[plr] = nil
            return
        end

        h.Adornee = char
        h.FillColor = color
        h.FillTransparency = 0.5
        h.OutlineColor = color
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = char
    else
        if h then
            h:Destroy()
            self.highlights[plr] = nil
        end
    end
end

function Visual:SetHighlightEnabled(enabled)
    self.highlightEnabled = enabled and true or false
    if not self.highlightEnabled then
        self:ClearHighlights()
    end
end

function Visual:IsHighlightEnabled()
    return self.highlightEnabled
end

function Visual:SetHighlightSecondEnabled(enabled)
    self.highlightSecondEnabled = enabled and true or false
end

function Visual:IsHighlightSecondEnabled()
    return self.highlightSecondEnabled
end

function Visual:ClearHighlights()
    for plr, _ in pairs(self.highlights) do
        self:_setHighlight(plr, Color3.new(1, 0, 0), false)
    end
end

-- getBestTargetFn(excludePlayer) -> Player | nil
-- isFriendlyFn(plr) -> bool (optional)
function Visual:UpdateHighlights(currentTarget, lockedOn, getBestTargetFn, isFriendlyFn)
    self:ClearHighlights()

    if not self.highlightEnabled or not lockedOn then
        return
    end

    if currentTarget and (not isFriendlyFn or not isFriendlyFn(currentTarget)) then
        self:_setHighlight(currentTarget, Color3.new(1, 0, 0), true)
    end

    if self.highlightSecondEnabled and getBestTargetFn then
        local second = getBestTargetFn(currentTarget)
        if second and (not isFriendlyFn or not isFriendlyFn(second)) then
            self:_setHighlight(second, Color3.new(1, 1, 0), true)
        end
    end
end

function Visual:Destroy()
    self:SetSelfFadeEnabled(false)
    self:ClearHighlights()

    if self.charConn then
        self.charConn:Disconnect()
        self.charConn = nil
    end
end

return Visual
