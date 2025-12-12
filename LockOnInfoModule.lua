-- LockOnInfoModule.lua

local Info = {}
Info.__index = Info

function Info.new()
    local self = setmetatable({}, Info)
    self.icons = {}
    self.visible = false
    return self
end

function Info:IsVisible()
    return self.visible
end

function Info:SetVisible(enabled)
    self.visible = enabled
    for _, btn in ipairs(self.icons) do
        if btn and btn.Parent then
            btn.Visible = enabled
        end
    end
end

function Info:Add(targetGui, tooltipText)
    if not targetGui then return end

    targetGui.ClipsDescendants = false

    local infoBtn = Instance.new("TextButton")
    infoBtn.Size = UDim2.new(0, 12, 0, 12)
    infoBtn.AnchorPoint = Vector2.new(0, 0)
    infoBtn.Position = UDim2.new(0, 4, 0, 3)
    infoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    infoBtn.BackgroundTransparency = 0.1
    infoBtn.BorderSizePixel = 1
    infoBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
    infoBtn.Font = Enum.Font.SourceSansBold
    infoBtn.TextSize = 12
    infoBtn.TextColor3 = Color3.new(1, 1, 1)
    infoBtn.Text = "i"
    infoBtn.AutoButtonColor = true
    infoBtn.ZIndex = (targetGui.ZIndex or 1) + 1
    infoBtn.Visible = self.visible
    infoBtn.Parent = targetGui

    local tooltipWidth = 220
    local tooltipHeight = 60

    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(0, tooltipWidth, 0, tooltipHeight)
    tooltip.Position = UDim2.new(0, 0, 0, -tooltipHeight - 4)
    tooltip.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    tooltip.BorderSizePixel = 1
    tooltip.BorderColor3 = Color3.fromRGB(255, 255, 255)
    tooltip.Font = Enum.Font.SourceSans
    tooltip.TextSize = 14
    tooltip.TextColor3 = Color3.new(1, 1, 1)
    tooltip.TextWrapped = true
    tooltip.TextXAlignment = Enum.TextXAlignment.Left
    tooltip.TextYAlignment = Enum.TextYAlignment.Top
    tooltip.Visible = false
    tooltip.ZIndex = infoBtn.ZIndex + 1
    tooltip.Text = tooltipText
    tooltip.Parent = infoBtn

    table.insert(self.icons, infoBtn)

    infoBtn.MouseEnter:Connect(function()
        if self.visible then
            tooltip.Visible = true
        end
    end)
    infoBtn.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

return Info
