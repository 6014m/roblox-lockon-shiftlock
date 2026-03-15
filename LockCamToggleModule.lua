--// LockCamToggle Module for Lock-On Camera v3.2
--// Stays locked onto target but frees camera movement

local LockCamToggle = {}
LockCamToggle.__index = LockCamToggle

function LockCamToggle.new(scriptData)
    local self = setmetatable({}, LockCamToggle)

    self.enabled = false
    self.active = false
    self.held = false
    self.mode = "Hold" -- "Hold" or "Toggle"
    self.keybind = Enum.KeyCode.F

    self._scriptData = scriptData
    self._connections = {}
    self._buttons = {}

    return self
end

function LockCamToggle:IsActive()
    return self.enabled and self.active
end

function LockCamToggle:SetEnabled(val)
    self.enabled = val
    if not val then self.active = false end
end

function LockCamToggle:SetMode(mode)
    if mode == "Hold" or mode == "Toggle" then
        self.mode = mode
        self.active = false
    end
end

function LockCamToggle:ToggleMode()
    if self.mode == "Hold" then
        self.mode = "Toggle"
    else
        self.mode = "Hold"
    end
    self.active = false
end

function LockCamToggle:SetKeybind(keyCode)
    self.keybind = keyCode
end

function LockCamToggle:OnInputBegan(keyCode)
    if not self.enabled then return end
    if keyCode ~= self.keybind then return end

    if self.mode == "Hold" then
        self.active = true
        self.held = true
    else
        self.active = not self.active
    end
end

function LockCamToggle:OnInputEnded(keyCode)
    if not self.enabled then return end
    if keyCode ~= self.keybind then return end

    if self.mode == "Hold" then
        self.active = false
        self.held = false
    end
end

function LockCamToggle:OnUnlock()
    self.active = false
end

function LockCamToggle:GetSaveData()
    return {
        lockCamToggleEnabled = self.enabled,
        lockCamToggleMode = self.mode,
        kb_LockCamToggle = self.keybind.Name,
    }
end

function LockCamToggle:LoadSaveData(data)
    if data.lockCamToggleEnabled ~= nil then
        self.enabled = (data.lockCamToggleEnabled == true)
    end
    if data.lockCamToggleMode == "Hold" or data.lockCamToggleMode == "Toggle" then
        self.mode = data.lockCamToggleMode
    end
    if data.kb_LockCamToggle and Enum.KeyCode[data.kb_LockCamToggle] then
        self.keybind = Enum.KeyCode[data.kb_LockCamToggle]
    end
end

-- Build UI buttons into the extra settings panel
function LockCamToggle:BuildUI(parent, theme, yStart, createButtonFn, connectFn, playClickFn, refreshFn, keybindFn)
    local y = yStart

    -- Toggle button
    local toggleBtn = createButtonFn(parent, y, "LockCamToggle: OFF", "Lock target without forcing camera")
    toggleBtn.Position = UDim2.new(0, 10, 0, y); toggleBtn.Size = UDim2.new(1, -20, 0, 28)
    self._buttons.toggle = toggleBtn
    connectFn(toggleBtn.MouseButton1Click, function()
        playClickFn()
        self:SetEnabled(not self.enabled)
        refreshFn()
    end)
    y = y + 32

    -- Mode button
    local modeBtn = createButtonFn(parent, y, "Mode: Hold", "Hold or Toggle")
    modeBtn.Position = UDim2.new(0, 10, 0, y); modeBtn.Size = UDim2.new(1, -20, 0, 28)
    self._buttons.mode = modeBtn
    connectFn(modeBtn.MouseButton1Click, function()
        playClickFn()
        self:ToggleMode()
        refreshFn()
    end)
    y = y + 32

    -- Keybind button
    local keyBtn = createButtonFn(parent, y, "LockCam Key: F", "Set keybind")
    keyBtn.Position = UDim2.new(0, 10, 0, y); keyBtn.Size = UDim2.new(1, -20, 0, 28)
    self._buttons.key = keyBtn
    connectFn(keyBtn.MouseButton1Click, function()
        playClickFn()
        keybindFn(self, keyBtn)
    end)
    y = y + 32

    return y
end

function LockCamToggle:RefreshUI()
    if self._buttons.toggle then
        self._buttons.toggle.Text = "LockCamToggle: " .. (self.enabled and "ON" or "OFF")
    end
    if self._buttons.mode then
        self._buttons.mode.Text = "Mode: " .. self.mode
    end
    if self._buttons.key then
        self._buttons.key.Text = "LockCam Key: " .. self.keybind.Name
    end
end

function LockCamToggle:ApplyTheme(theme)
    for _, btn in pairs(self._buttons) do
        if btn and btn.Parent then
            btn.BackgroundColor3 = theme.secondary
            btn.TextColor3 = theme.text
        end
    end
end

function LockCamToggle:GetButtons()
    return self._buttons
end

function LockCamToggle:Destroy()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}
    for _, btn in pairs(self._buttons) do
        pcall(function() btn:Destroy() end)
    end
    self._buttons = {}
end

return LockCamToggle
