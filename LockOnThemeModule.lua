-- LockOnThemeModule.lua

local Theme = {}
Theme.__index = Theme

local function styleButton(btn, buttonBg, borderColor)
    if not btn then return end
    btn.BackgroundColor3 = buttonBg
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BorderSizePixel = 2
    btn.BorderColor3 = borderColor
end

function Theme.new()
    local self = setmetatable({}, Theme)
    self.current = "Slayer"
    self.frameGradient = nil
    return self
end

function Theme:SetTheme(name)
    if name == "Sunset" then
        self.current = "Sunset"
    else
        self.current = "Slayer"
    end
end

-- uiRefs is a table with all UI objects you pass in
function Theme:Apply(ui)
    local mainFrame          = ui.mainFrame
    local openBtn            = ui.openBtn
    local closeBtn           = ui.closeBtn
    local infoToggleButton   = ui.infoToggleButton
    local tabMainButton      = ui.tabMainButton
    local tabVisualButton    = ui.tabVisualButton
    local tabTargetButton    = ui.tabTargetButton
    local hardLockButton     = ui.hardLockButton
    local highlightButton    = ui.highlightButton
    local highlightSecondBtn = ui.highlightSecondButton
    local selfFadeButton     = ui.selfFadeButton
    local autoswapButton     = ui.autoswapButton
    local closeSwapButton    = ui.closeSwapButton
    local checkVisibilityBtn = ui.checkVisibilityButton
    local checkHealthButton  = ui.checkHealthButton
    local autoRelockButton   = ui.autoRelockButton
    local realisticButton    = ui.realisticButton
    local centerShiftButton  = ui.centerShiftlockButton
    local lockOnKeyButton    = ui.lockOnKeyButton
    local swapKeyButton      = ui.swapKeyButton
    local hardLockKeyButton  = ui.hardLockKeyButton
    local hardLockKeyToggle  = ui.hardLockKeyToggleButton
    local themeSlayerButton  = ui.themeSlayerButton
    local themeSunsetButton  = ui.themeSunsetButton
    local friendsList        = ui.friendsList
    local heightSliderBar    = ui.heightSliderBar
    local heightSliderKnob   = ui.heightSliderKnob
    local rangeInput         = ui.rangeInput
    local headerLabel        = ui.headerLabel
    local extraSettingsFrame = ui.extraSettingsFrame
    local extraSettingsButton= ui.extraSettingsButton
    local reverseLockButton  = ui.reverseLockButton
    local reverseKeyButton   = ui.reverseKeyButton

    if not mainFrame then return end

    local frameBg
    local borderColor
    local openBg
    local closeBg
    local headerColor
    local buttonBg
    local friendsBg
    local sliderBg
    local knobBg

    if self.current == "Sunset" then
        frameBg      = Color3.fromRGB(25, 15, 35)
        borderColor  = Color3.fromRGB(255, 140, 80)
        openBg       = Color3.fromRGB(255, 140, 80)
        closeBg      = Color3.fromRGB(200, 60, 120)
        headerColor  = Color3.new(1, 1, 1)
        buttonBg     = Color3.fromRGB(80, 40, 110)
        friendsBg    = Color3.fromRGB(35, 20, 55)
        sliderBg     = Color3.fromRGB(60, 30, 90)
        knobBg       = Color3.fromRGB(255, 200, 120)

        if not self.frameGradient then
            local g = Instance.new("UIGradient")
            g.Name = "ThemeGradient"
            g.Rotation = 90
            g.Parent = mainFrame
            self.frameGradient = g
        end

        self.frameGradient.Enabled = true
        self.frameGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 150, 50)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 40, 80)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 60, 180)),
        })
    else
        frameBg      = Color3.fromRGB(10, 10, 12)
        borderColor  = Color3.fromRGB(180, 30, 30)
        openBg       = Color3.fromRGB(60, 0, 0)
        closeBg      = Color3.fromRGB(100, 0, 0)
        headerColor  = Color3.fromRGB(255, 60, 60)
        buttonBg     = Color3.fromRGB(40, 0, 0)
        friendsBg    = Color3.fromRGB(20, 0, 0)
        sliderBg     = Color3.fromRGB(30, 10, 10)
        knobBg       = Color3.fromRGB(200, 60, 60)

        if self.frameGradient then
            self.frameGradient.Enabled = false
        end
    end

    mainFrame.BackgroundColor3 = frameBg
    mainFrame.BorderSizePixel  = 2
    mainFrame.BorderColor3     = borderColor

    if openBtn then
        openBtn.BackgroundColor3 = openBg
        openBtn.BorderSizePixel  = 2
        openBtn.BorderColor3     = borderColor
    end

    if closeBtn then
        closeBtn.BackgroundColor3 = closeBg
        closeBtn.BorderSizePixel  = 2
        closeBtn.BorderColor3     = borderColor
    end

    if infoToggleButton then
        infoToggleButton.BackgroundColor3 = closeBg
        infoToggleButton.BorderSizePixel  = 2
        infoToggleButton.BorderColor3     = borderColor
    end

    if headerLabel then
        headerLabel.TextColor3 = headerColor
    end

    styleButton(tabMainButton,      buttonBg, borderColor)
    styleButton(tabVisualButton,    buttonBg, borderColor)
    styleButton(tabTargetButton,    buttonBg, borderColor)

    styleButton(hardLockButton,     buttonBg, borderColor)
    styleButton(highlightButton,    buttonBg, borderColor)
    styleButton(highlightSecondBtn, buttonBg, borderColor)
    styleButton(selfFadeButton,     buttonBg, borderColor)
    styleButton(autoswapButton,     buttonBg, borderColor)
    styleButton(closeSwapButton,    buttonBg, borderColor)
    styleButton(checkVisibilityBtn, buttonBg, borderColor)
    styleButton(checkHealthButton,  buttonBg, borderColor)
    styleButton(autoRelockButton,   buttonBg, borderColor)
    styleButton(realisticButton,    buttonBg, borderColor)
    styleButton(centerShiftButton,  buttonBg, borderColor)

    styleButton(lockOnKeyButton,    buttonBg, borderColor)
    styleButton(swapKeyButton,      buttonBg, borderColor)
    styleButton(hardLockKeyButton,  buttonBg, borderColor)
    styleButton(hardLockKeyToggle,  buttonBg, borderColor)

    styleButton(themeSlayerButton,  buttonBg, borderColor)
    styleButton(themeSunsetButton,  buttonBg, borderColor)

    styleButton(reverseLockButton,  buttonBg, borderColor)
    styleButton(reverseKeyButton,   buttonBg, borderColor)

    if friendsList then
        friendsList.BackgroundColor3 = friendsBg
        friendsList.BorderSizePixel  = 2
        friendsList.BorderColor3     = borderColor
    end

    if heightSliderBar then
        heightSliderBar.BackgroundColor3 = sliderBg
        heightSliderBar.BorderSizePixel  = 2
        heightSliderBar.BorderColor3     = borderColor
    end

    if heightSliderKnob then
        heightSliderKnob.BackgroundColor3 = knobBg
        heightSliderKnob.BorderSizePixel  = 1
        heightSliderKnob.BorderColor3     = Color3.fromRGB(255, 255, 255)
    end

    if rangeInput then
        styleButton(rangeInput, buttonBg, borderColor)
    end

    if extraSettingsFrame then
        extraSettingsFrame.BackgroundColor3 = frameBg
        extraSettingsFrame.BorderSizePixel  = 2
        extraSettingsFrame.BorderColor3     = borderColor
    end

    if extraSettingsButton then
        styleButton(extraSettingsButton, buttonBg, borderColor)
    end
end

return Theme
