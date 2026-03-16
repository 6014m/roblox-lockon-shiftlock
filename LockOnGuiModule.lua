--// LockOnGuiModule.lua
--// Extracted GUI building code from lockon_script.lua
--// Returns a module with buildGui(env) that creates all UI and wires events.
--// env is a table the main script populates with all state, services, and callbacks.

local Module = {}

local function createButton(env, parent, yPos, text, tipText)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.BorderSizePixel = 0
    btn.BackgroundColor3 = env.currentTheme.secondary
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    env.connect(btn.MouseEnter, function()
        if btn.Parent then
            env.TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = env.currentTheme.primary1}):Play()
        end
    end)
    env.connect(btn.MouseLeave, function()
        if btn.Parent then
            env.TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = env.currentTheme.secondary}):Play()
        end
    end)

    if tipText then env.addTooltip(btn, tipText) end
    return btn
end

--[[
    buildGui(env) -> table of UI references

    env fields read/written by this module:
      Services: TweenService, UserInputService, RunService, Players, CoreGui
      State (read/write directly):
        currentTheme, currentThemeName, THEMES
        autoSwapEnabled, closeSwapEnabled, visibilityCheckEnabled, checkHealthEnabled
        autoRelockEnabled, realisticEnabled, reverseLockEnabled, perfectOffsetEnabled
        mouseTargetMode, npcModeEnabled, predictionEnabled, forceCameraMode
        customShiftlockEnabled, shiftlockAutoEnable, shiftlockKeyEnabled
        mouseResistanceEnabled, mouseResistanceScale
        lockOnPlusEnabled
        lockCamToggleEnabled, lockCamToggleActive, lockCamToggleMode, lockCamToggleKeybind
        lockHeightOffset, SLIDER_MIN, SLIDER_MAX, rangeLimit
        keybinds, waitingForKeybind
        selectedGame, gameFunctionStates, gameFunctionButtons
        animatedElements, tooltipsEnabled
        lockedOn, currentTarget, currentTargetType
      Callbacks:
        connect, playClickSound, addTooltip, setupTooltip, toggleTooltips, tip
        refreshAllUI, applyThemeToUI, rebuildFriendsList, syncTargetingOptions
        toggleCustomShiftlock, setupForceCameraHooks
        saveSettings, loadSettingsData, applySettingsData
        updateNPCHighlight, setTheme
        getGameNames, findGameByName, findMatchingGames
      Module refs:
        visuals, localPlayer, PARENT, GUI_NAME, ScriptData
      Friendlies:
        friendlies, isFriendly
]]
function Module.buildGui(env)
    local saved = env.loadSettingsData()
    if saved then env.applySettingsData(saved) end

    -- Setup force camera hooks if enabled from saved settings
    env.setupForceCameraHooks()

    local gui = Instance.new("ScreenGui")
    gui.Name = env.GUI_NAME
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.DisplayOrder = 999999
    gui.IgnoreGuiInset = false
    env.ScriptData.Gui = gui

    if env.PARENT then
        gui.Parent = env.PARENT
    else
        pcall(function() gui.Parent = env.CoreGui end)
        if not gui.Parent then gui.Parent = env.localPlayer:WaitForChild("PlayerGui") end
    end

    env.setupTooltip(gui)

    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 36, 0, 36)
    openBtn.Position = UDim2.new(0, 12, 1, -48)
    openBtn.BackgroundColor3 = env.currentTheme.secondary
    openBtn.TextColor3 = Color3.new(1, 1, 1)
    openBtn.Font = Enum.Font.GothamBold
    openBtn.TextSize = 20
    openBtn.Text = "\226\151\142"
    openBtn.BorderSizePixel = 0
    openBtn.AutoButtonColor = false
    openBtn.Parent = gui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)
    local openStroke = Instance.new("UIStroke", openBtn)
    openStroke.Thickness = 2
    env.animatedElements[openStroke] = "stroke"

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 420)
    mainFrame.Position = UDim2.new(0, 12, 1, -440)
    mainFrame.BackgroundColor3 = env.currentTheme.background
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = gui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Thickness = 2
    env.animatedElements[mainStroke] = "stroke"

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -70, 0, 32)
    headerLabel.Position = UDim2.new(0, 12, 0, 6)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 16
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.TextColor3 = env.currentTheme.text
    headerLabel.Text = "\240\159\142\175 Lock-On v3.2"
    headerLabel.Parent = mainFrame
    env.animatedElements[headerLabel] = "text"

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.BackgroundColor3 = env.currentTheme.secondary
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Text = "\195\151"
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = mainFrame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

    local infoToggleButton = Instance.new("TextButton")
    infoToggleButton.Size = UDim2.new(0, 28, 0, 28)
    infoToggleButton.Position = UDim2.new(1, -68, 0, 8)
    infoToggleButton.BackgroundColor3 = env.currentTheme.secondary
    infoToggleButton.Font = Enum.Font.GothamBold
    infoToggleButton.TextSize = 14
    infoToggleButton.TextColor3 = Color3.new(1, 1, 1)
    infoToggleButton.Text = "?"
    infoToggleButton.BorderSizePixel = 0
    infoToggleButton.Parent = mainFrame
    Instance.new("UICorner", infoToggleButton).CornerRadius = UDim.new(0, 8)
    env.addTooltip(infoToggleButton, env.TooltipModule and env.TooltipModule.InfoToggle or "Toggle tooltips")

    local extraSettingsButton = Instance.new("TextButton")
    extraSettingsButton.Size = UDim2.new(0, 70, 0, 24)
    extraSettingsButton.Position = UDim2.new(0, 10, 1, -32)
    extraSettingsButton.BackgroundColor3 = env.currentTheme.secondary
    extraSettingsButton.Font = Enum.Font.GothamMedium
    extraSettingsButton.TextSize = 10
    extraSettingsButton.TextColor3 = Color3.new(1, 1, 1)
    extraSettingsButton.Text = "\226\154\153 Extra"
    extraSettingsButton.BorderSizePixel = 0
    extraSettingsButton.Parent = mainFrame
    Instance.new("UICorner", extraSettingsButton).CornerRadius = UDim.new(0, 6)

    local saveButton = Instance.new("TextButton")
    saveButton.Size = UDim2.new(0, 70, 0, 24)
    saveButton.Position = UDim2.new(0.5, -35, 1, -32)
    saveButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    saveButton.Font = Enum.Font.GothamMedium
    saveButton.TextSize = 10
    saveButton.TextColor3 = Color3.new(1, 1, 1)
    saveButton.Text = "\240\159\146\190 Save"
    saveButton.BorderSizePixel = 0
    saveButton.Parent = mainFrame
    Instance.new("UICorner", saveButton).CornerRadius = UDim.new(0, 6)

    local loadButton = Instance.new("TextButton")
    loadButton.Size = UDim2.new(0, 70, 0, 24)
    loadButton.Position = UDim2.new(1, -80, 1, -32)
    loadButton.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
    loadButton.Font = Enum.Font.GothamMedium
    loadButton.TextSize = 10
    loadButton.TextColor3 = Color3.new(1, 1, 1)
    loadButton.Text = "\240\159\147\130 Load"
    loadButton.BorderSizePixel = 0
    loadButton.Parent = mainFrame
    Instance.new("UICorner", loadButton).CornerRadius = UDim.new(0, 6)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -20, 0, 30)
    tabBar.Position = UDim2.new(0, 10, 0, 42)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    local function createTab(txt, x)
        local t = Instance.new("TextButton")
        t.Size = UDim2.new(0.333, -4, 1, 0)
        t.Position = UDim2.new(x, 0, 0, 0)
        t.Font = Enum.Font.GothamMedium
        t.TextSize = 11
        t.TextColor3 = Color3.new(1, 1, 1)
        t.Text = txt
        t.BorderSizePixel = 0
        t.BackgroundColor3 = env.currentTheme.secondary
        t.Parent = tabBar
        Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
        return t
    end

    local tabMainButton = createTab("Main", 0)
    local tabVisualButton = createTab("Visual", 0.335)
    local tabTargetButton = createTab("Target", 0.67)

    local pageSize = UDim2.new(1, -20, 1, -115)
    local pagePos = UDim2.new(0, 10, 0, 76)

    local mainPage = Instance.new("ScrollingFrame")
    mainPage.Size = pageSize
    mainPage.Position = pagePos
    mainPage.BackgroundTransparency = 1
    mainPage.ScrollBarThickness = 4
    mainPage.CanvasSize = UDim2.new(0, 0, 0, 295)
    mainPage.Parent = mainFrame

    local visualPage = Instance.new("ScrollingFrame")
    visualPage.Size = pageSize
    visualPage.Position = pagePos
    visualPage.BackgroundTransparency = 1
    visualPage.ScrollBarThickness = 4
    visualPage.CanvasSize = UDim2.new(0, 0, 0, 320)
    visualPage.Visible = false
    visualPage.Parent = mainFrame

    local targetPage = Instance.new("ScrollingFrame")
    targetPage.Size = pageSize
    targetPage.Position = pagePos
    targetPage.BackgroundTransparency = 1
    targetPage.ScrollBarThickness = 4
    targetPage.CanvasSize = UDim2.new(0, 0, 0, 320)
    targetPage.Visible = false
    targetPage.Parent = mainFrame

    -- MAIN PAGE
    local autoswapButton = createButton(env, mainPage, 0, "Autoswap: OFF", env.tip("Main", "Autoswap", "Auto-swap on death"))
    local closeSwapButton = createButton(env, mainPage, 32, "CloseSwap: OFF", env.tip("Main", "CloseSwap", "Target closest"))
    local checkVisibilityButton = createButton(env, mainPage, 64, "Visibility check: OFF", env.tip("Main", "VisibilityCheck", "Swap if hidden"))
    local checkHealthButton = createButton(env, mainPage, 96, "Check health/FF: OFF", env.tip("Main", "CheckHealth", "Skip dead targets"))
    local autoRelockButton = createButton(env, mainPage, 128, "Auto relock: OFF", env.tip("Main", "AutoRelock", "Re-lock auto"))
    local realisticButton = createButton(env, mainPage, 160, "Realistic (front): OFF", env.tip("Main", "Realistic", "Front only"))

    local heightLabel = Instance.new("TextLabel")
    heightLabel.Size = UDim2.new(1, -10, 0, 20)
    heightLabel.Position = UDim2.new(0, 0, 0, 196)
    heightLabel.BackgroundTransparency = 1
    heightLabel.Font = Enum.Font.GothamBold
    heightLabel.TextSize = 11
    heightLabel.TextColor3 = env.currentTheme.text
    heightLabel.TextXAlignment = Enum.TextXAlignment.Left
    heightLabel.Text = string.format("Height: %.1f", env.lockHeightOffset)
    heightLabel.Parent = mainPage

    local heightSliderBar = Instance.new("Frame")
    heightSliderBar.Size = UDim2.new(1, -10, 0, 18)
    heightSliderBar.Position = UDim2.new(0, 0, 0, 216)
    heightSliderBar.BackgroundColor3 = env.currentTheme.secondary
    heightSliderBar.BorderSizePixel = 0
    heightSliderBar.Parent = mainPage
    Instance.new("UICorner", heightSliderBar).CornerRadius = UDim.new(0, 6)

    local heightSliderKnob = Instance.new("Frame")
    heightSliderKnob.Size = UDim2.new(0, 16, 1, -4)
    heightSliderKnob.Position = UDim2.new((env.lockHeightOffset - env.SLIDER_MIN) / (env.SLIDER_MAX - env.SLIDER_MIN), 0, 0.5, 0)
    heightSliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    heightSliderKnob.BackgroundColor3 = env.currentTheme.primary1
    heightSliderKnob.BorderSizePixel = 0
    heightSliderKnob.Parent = heightSliderBar
    Instance.new("UICorner", heightSliderKnob).CornerRadius = UDim.new(0, 4)
    env.animatedElements[heightSliderKnob] = "background"

    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.Size = UDim2.new(0.5, 0, 0, 20)
    rangeLabel.Position = UDim2.new(0, 0, 0, 270)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Font = Enum.Font.GothamBold
    rangeLabel.TextSize = 11
    rangeLabel.TextColor3 = env.currentTheme.text
    rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    rangeLabel.Text = "Range (0=\226\136\158):"
    rangeLabel.Parent = mainPage

    local rangeInput = Instance.new("TextBox")
    rangeInput.Size = UDim2.new(0.45, 0, 0, 22)
    rangeInput.Position = UDim2.new(0.5, 4, 0, 268)
    rangeInput.Font = Enum.Font.Gotham
    rangeInput.TextSize = 12
    rangeInput.TextColor3 = env.currentTheme.text
    rangeInput.Text = tostring(env.rangeLimit)
    rangeInput.BackgroundColor3 = env.currentTheme.secondary
    rangeInput.BorderSizePixel = 0
    rangeInput.ClearTextOnFocus = false
    rangeInput.Parent = mainPage
    Instance.new("UICorner", rangeInput).CornerRadius = UDim.new(0, 6)

    -- VISUAL PAGE
    local highlightButton = createButton(env, visualPage, 0, "Highlight: OFF", env.tip("Visual", "Highlight", "Glow target"))
    local highlightSecondButton = createButton(env, visualPage, 32, "2nd closest: OFF", env.tip("Visual", "HighlightSecond", "Highlight #2"))
    local selfFadeButton = createButton(env, visualPage, 64, "Self fade: OFF", env.tip("Visual", "SelfFade", "Fade self"))

    local themeLabel = Instance.new("TextLabel")
    themeLabel.Size = UDim2.new(1, -10, 0, 20)
    themeLabel.Position = UDim2.new(0, 0, 0, 100)
    themeLabel.BackgroundTransparency = 1
    themeLabel.Font = Enum.Font.GothamBold
    themeLabel.TextSize = 12
    themeLabel.TextColor3 = env.currentTheme.text
    themeLabel.TextXAlignment = Enum.TextXAlignment.Left
    themeLabel.Text = "\240\159\142\168 Themes:"
    themeLabel.Parent = visualPage

    local themeButtons = {}
    local ti = 0
    for name in pairs(env.THEMES) do
        local row, col = math.floor(ti / 2), ti % 2
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.48, 0, 0, 26)
        b.Position = UDim2.new(col * 0.52, 0, 0, 124 + row * 30)
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 11
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Text = name
        b.BorderSizePixel = 0
        b.BackgroundColor3 = env.currentTheme.secondary
        b.Parent = visualPage
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        themeButtons[name] = b
        env.connect(b.MouseButton1Click, function() env.playClickSound(); env.setTheme(name) end)
        ti += 1
    end

    local afterThemes = 124 + math.ceil(ti / 2) * 30 + 10
    local centerShiftlockButton = createButton(env, visualPage, afterThemes, "Custom Shiftlock: OFF", env.tip("Visual", "CustomShiftlock", "Override all shiftlocks"))

    -- Shiftlock key with On/Off toggle
    local shiftlockKeyButton = Instance.new("TextButton")
    shiftlockKeyButton.Size = UDim2.new(0.68, 0, 0, 28)
    shiftlockKeyButton.Position = UDim2.new(0, 0, 0, afterThemes + 32)
    shiftlockKeyButton.Font = Enum.Font.GothamMedium
    shiftlockKeyButton.TextSize = 12
    shiftlockKeyButton.TextColor3 = Color3.new(1, 1, 1)
    shiftlockKeyButton.Text = "Shiftlock Key: LeftShift"
    shiftlockKeyButton.BorderSizePixel = 0
    shiftlockKeyButton.BackgroundColor3 = env.currentTheme.secondary
    shiftlockKeyButton.Parent = visualPage
    Instance.new("UICorner", shiftlockKeyButton).CornerRadius = UDim.new(0, 6)
    env.addTooltip(shiftlockKeyButton, env.tip("Visual", "ShiftlockKey", "Change key"))

    local shiftlockKeyToggleButton = Instance.new("TextButton")
    shiftlockKeyToggleButton.Size = UDim2.new(0.28, 0, 0, 28)
    shiftlockKeyToggleButton.Position = UDim2.new(0.7, 4, 0, afterThemes + 32)
    shiftlockKeyToggleButton.Font = Enum.Font.GothamMedium
    shiftlockKeyToggleButton.TextSize = 11
    shiftlockKeyToggleButton.TextColor3 = Color3.new(1, 1, 1)
    shiftlockKeyToggleButton.Text = env.shiftlockKeyEnabled and "On" or "Off"
    shiftlockKeyToggleButton.BorderSizePixel = 0
    shiftlockKeyToggleButton.BackgroundColor3 = env.currentTheme.secondary
    shiftlockKeyToggleButton.Parent = visualPage
    Instance.new("UICorner", shiftlockKeyToggleButton).CornerRadius = UDim.new(0, 6)
    env.addTooltip(shiftlockKeyToggleButton, env.tip("Visual", "ShiftlockKeyToggle", "Enable/disable keybind"))

    local shiftlockAutoEnableButton = createButton(env, visualPage, afterThemes + 64, "Auto-Enable: OFF", env.tip("Visual", "ShiftlockAutoEnable", "Enable on load"))

    visualPage.CanvasSize = UDim2.new(0, 0, 0, afterThemes + 100)

    -- TARGET PAGE
    local keysLabel = Instance.new("TextLabel")
    keysLabel.Size = UDim2.new(1, -10, 0, 20)
    keysLabel.Position = UDim2.new(0, 0, 0, 0)
    keysLabel.BackgroundTransparency = 1
    keysLabel.Font = Enum.Font.GothamBold
    keysLabel.TextSize = 11
    keysLabel.TextColor3 = env.currentTheme.text
    keysLabel.TextXAlignment = Enum.TextXAlignment.Left
    keysLabel.Text = "\226\140\168 Keybinds:"
    keysLabel.Parent = targetPage

    local lockOnKeyButton = createButton(env, targetPage, 24, "Lock-on: X", env.tip("Target", "LockOnKey", "Toggle lock"))
    local swapKeyButton = createButton(env, targetPage, 56, "Swap: C", env.tip("Target", "SwapKey", "Next target"))

    local mouseTargetButton = createButton(env, targetPage, 88, "Mouse target: OFF", env.tip("Target", "MouseTarget", "Cursor target"))

    local friendsLabel = Instance.new("TextLabel")
    friendsLabel.Size = UDim2.new(1, -10, 0, 20)
    friendsLabel.Position = UDim2.new(0, 0, 0, 124)
    friendsLabel.BackgroundTransparency = 1
    friendsLabel.Font = Enum.Font.GothamBold
    friendsLabel.TextSize = 11
    friendsLabel.TextColor3 = env.currentTheme.text
    friendsLabel.TextXAlignment = Enum.TextXAlignment.Left
    friendsLabel.Text = "\240\159\145\165 Friendlies:"
    friendsLabel.Parent = targetPage

    local friendsList = Instance.new("ScrollingFrame")
    friendsList.Size = UDim2.new(1, -10, 0, 130)
    friendsList.Position = UDim2.new(0, 0, 0, 146)
    friendsList.BackgroundColor3 = env.currentTheme.secondary
    friendsList.BorderSizePixel = 0
    friendsList.ScrollBarThickness = 4
    friendsList.Parent = targetPage
    Instance.new("UICorner", friendsList).CornerRadius = UDim.new(0, 6)

    -- EXTRA SETTINGS
    local extraSettingsFrame = Instance.new("Frame")
    extraSettingsFrame.Size = UDim2.new(0, 320, 0, 420)
    extraSettingsFrame.Position = UDim2.new(0, 340, 1, -440)
    extraSettingsFrame.BackgroundColor3 = env.currentTheme.background
    extraSettingsFrame.BorderSizePixel = 0
    extraSettingsFrame.Visible = false
    extraSettingsFrame.ClipsDescendants = true
    extraSettingsFrame.Parent = gui
    Instance.new("UICorner", extraSettingsFrame).CornerRadius = UDim.new(0, 12)
    local extraStroke = Instance.new("UIStroke", extraSettingsFrame)
    extraStroke.Thickness = 2
    env.animatedElements[extraStroke] = "stroke"

    local extraHeader = Instance.new("TextLabel")
    extraHeader.Size = UDim2.new(1, -50, 0, 26)
    extraHeader.Position = UDim2.new(0, 12, 0, 8)
    extraHeader.BackgroundTransparency = 1
    extraHeader.Font = Enum.Font.GothamBold
    extraHeader.TextSize = 14
    extraHeader.TextXAlignment = Enum.TextXAlignment.Left
    extraHeader.TextColor3 = env.currentTheme.text
    extraHeader.Text = "\226\154\153 Extra Settings"
    extraHeader.Parent = extraSettingsFrame

    local extraSettingsCloseButton = Instance.new("TextButton")
    extraSettingsCloseButton.Size = UDim2.new(0, 26, 0, 26)
    extraSettingsCloseButton.Position = UDim2.new(1, -34, 0, 8)
    extraSettingsCloseButton.BackgroundColor3 = env.currentTheme.secondary
    extraSettingsCloseButton.Font = Enum.Font.GothamBold
    extraSettingsCloseButton.TextSize = 14
    extraSettingsCloseButton.TextColor3 = Color3.new(1, 1, 1)
    extraSettingsCloseButton.Text = "\195\151"
    extraSettingsCloseButton.BorderSizePixel = 0
    extraSettingsCloseButton.Parent = extraSettingsFrame
    Instance.new("UICorner", extraSettingsCloseButton).CornerRadius = UDim.new(0, 6)

    -- Scrollable content area
    local extraScrollFrame = Instance.new("ScrollingFrame")
    extraScrollFrame.Size = UDim2.new(1, -10, 1, -45)
    extraScrollFrame.Position = UDim2.new(0, 5, 0, 40)
    extraScrollFrame.BackgroundTransparency = 1
    extraScrollFrame.ScrollBarThickness = 4
    extraScrollFrame.ScrollBarImageColor3 = env.currentTheme.primary1
    extraScrollFrame.BorderSizePixel = 0
    extraScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 460)
    extraScrollFrame.Parent = extraSettingsFrame

    local reverseLockButton = createButton(env, extraScrollFrame, 0, "Reverse lock: OFF", env.tip("Extra", "ReverseLock", "Face away"))
    reverseLockButton.Position = UDim2.new(0, 5, 0, 0); reverseLockButton.Size = UDim2.new(1, -10, 0, 28)

    local reverseKeyButton = createButton(env, extraScrollFrame, 32, "Reverse: B", env.tip("Extra", "ReverseKey", "Hold reverse"))
    reverseKeyButton.Position = UDim2.new(0, 5, 0, 32); reverseKeyButton.Size = UDim2.new(1, -10, 0, 28)

    local perfectOffsetButton = createButton(env, extraScrollFrame, 64, "Perfect offset: OFF", env.tip("Extra", "PerfectOffset", "Aim offset"))
    perfectOffsetButton.Position = UDim2.new(0, 5, 0, 64); perfectOffsetButton.Size = UDim2.new(1, -10, 0, 28)

    local npcModeButton = createButton(env, extraScrollFrame, 96, "NPC Mode: OFF", env.tip("Extra", "NPCMode", "Target NPCs"))
    npcModeButton.Position = UDim2.new(0, 5, 0, 96); npcModeButton.Size = UDim2.new(1, -10, 0, 28)

    local predictionButton = createButton(env, extraScrollFrame, 128, "Prediction: OFF", env.tip("Extra", "Prediction", "Aim ahead"))
    predictionButton.Position = UDim2.new(0, 5, 0, 128); predictionButton.Size = UDim2.new(1, -10, 0, 28)

    local forceCameraButton = createButton(env, extraScrollFrame, 160, "Force Camera: OFF", env.tip("Extra", "ForceCamera", "Override game camera"))
    forceCameraButton.Position = UDim2.new(0, 5, 0, 160); forceCameraButton.Size = UDim2.new(1, -10, 0, 28)

    -- Mouse Resistance toggle and slider
    local mouseResistanceButton = createButton(env, extraScrollFrame, 192, "Mouse Resist: OFF", env.tip("Extra", "MouseResistance", "Allow pulling away"))
    mouseResistanceButton.Position = UDim2.new(0, 5, 0, 192); mouseResistanceButton.Size = UDim2.new(1, -10, 0, 28)

    local mouseResistanceLabel = Instance.new("TextLabel")
    mouseResistanceLabel.Size = UDim2.new(1, -10, 0, 16)
    mouseResistanceLabel.Position = UDim2.new(0, 5, 0, 224)
    mouseResistanceLabel.BackgroundTransparency = 1
    mouseResistanceLabel.Font = Enum.Font.Gotham
    mouseResistanceLabel.TextSize = 11
    mouseResistanceLabel.TextColor3 = env.currentTheme.text
    mouseResistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    mouseResistanceLabel.Text = string.format("Resistance: %.0f%%", env.mouseResistanceScale * 100)
    mouseResistanceLabel.Parent = extraScrollFrame

    local mouseResistanceSliderBar = Instance.new("Frame")
    mouseResistanceSliderBar.Size = UDim2.new(1, -10, 0, 8)
    mouseResistanceSliderBar.Position = UDim2.new(0, 5, 0, 242)
    mouseResistanceSliderBar.BackgroundColor3 = env.currentTheme.secondary
    mouseResistanceSliderBar.BorderSizePixel = 0
    mouseResistanceSliderBar.Parent = extraScrollFrame
    Instance.new("UICorner", mouseResistanceSliderBar).CornerRadius = UDim.new(0, 4)

    local mouseResistanceSliderKnob = Instance.new("Frame")
    mouseResistanceSliderKnob.Size = UDim2.new(0, 16, 0, 16)
    -- Convert -1 to 1 range to 0 to 1 for position
    mouseResistanceSliderKnob.Position = UDim2.new((env.mouseResistanceScale + 1) / 2, 0, 0.5, 0)
    mouseResistanceSliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    mouseResistanceSliderKnob.BackgroundColor3 = env.currentTheme.primary1
    mouseResistanceSliderKnob.BorderSizePixel = 0
    mouseResistanceSliderKnob.Parent = mouseResistanceSliderBar
    Instance.new("UICorner", mouseResistanceSliderKnob).CornerRadius = UDim.new(1, 0)

    -- LockOn+ toggle and keybind
    local lockOnPlusButton = createButton(env, extraScrollFrame, 260, "LockOn+: OFF", env.tip("Extra", "LockOnPlus", "Rotate body to target"))
    lockOnPlusButton.Position = UDim2.new(0, 5, 0, 260); lockOnPlusButton.Size = UDim2.new(1, -10, 0, 28)

    local lockOnPlusKeyButton = createButton(env, extraScrollFrame, 292, "LockOn+ Key: Q", env.tip("Extra", "LockOnPlusKey", "Hold to activate"))
    lockOnPlusKeyButton.Position = UDim2.new(0, 5, 0, 292); lockOnPlusKeyButton.Size = UDim2.new(1, -10, 0, 28)

    -- LockCamToggle
    local lockCamToggleBtn = createButton(env, extraScrollFrame, 324, "LockCamToggle: OFF", env.tip("Extra", "LockCamToggle", "Lock target without forcing camera"))
    lockCamToggleBtn.Position = UDim2.new(0, 5, 0, 324); lockCamToggleBtn.Size = UDim2.new(1, -10, 0, 28)
    local lockCamToggleModeBtn = createButton(env, extraScrollFrame, 356, "Mode: Hold", env.tip("Extra", "LockCamToggleMode", "Hold or Toggle"))
    lockCamToggleModeBtn.Position = UDim2.new(0, 5, 0, 356); lockCamToggleModeBtn.Size = UDim2.new(1, -10, 0, 28)
    local lockCamToggleKeyBtn = createButton(env, extraScrollFrame, 388, "LockCam Key: F", env.tip("Extra", "LockCamToggleKey", "Set keybind"))
    lockCamToggleKeyBtn.Position = UDim2.new(0, 5, 0, 388); lockCamToggleKeyBtn.Size = UDim2.new(1, -10, 0, 28)
    env.connect(lockCamToggleBtn.MouseButton1Click, function() env.playClickSound(); env.lockCamToggleEnabled = not env.lockCamToggleEnabled; if not env.lockCamToggleEnabled then env.lockCamToggleActive = false end; env.refreshAllUI() end)
    env.connect(lockCamToggleModeBtn.MouseButton1Click, function() env.playClickSound(); env.lockCamToggleMode = env.lockCamToggleMode == "Hold" and "Toggle" or "Hold"; env.lockCamToggleActive = false; env.refreshAllUI() end)
    env.connect(lockCamToggleKeyBtn.MouseButton1Click, function() env.playClickSound(); env.waitingForKeybind = "_LockCamToggle"; lockCamToggleKeyBtn.Text = "..." end)

    -- GAME-SPECIFIC FUNCTIONS - Always show selector
    -- Game selector button
    local gameFunctionsButton = createButton(env, extraScrollFrame, 420, "\240\159\142\174 Game Functions", env.tip("Extra", "GameFunctions", "Select game for special features"))
    gameFunctionsButton.Position = UDim2.new(0, 5, 0, 420); gameFunctionsButton.Size = UDim2.new(1, -10, 0, 28)
    gameFunctionsButton.BackgroundColor3 = Color3.fromRGB(80, 40, 100)

    extraSettingsFrame.Size = UDim2.new(0, 320, 0, 420)

    -- Game functions frame (game selector + functions)
    local gameFunctionsFrame = Instance.new("Frame")
    gameFunctionsFrame.Size = UDim2.new(0, 220, 0, 200)
    gameFunctionsFrame.Position = UDim2.new(0, 668, 1, -440)
    gameFunctionsFrame.BackgroundColor3 = env.currentTheme.background
    gameFunctionsFrame.BorderSizePixel = 0
    gameFunctionsFrame.Visible = false
    gameFunctionsFrame.Parent = gui
    Instance.new("UICorner", gameFunctionsFrame).CornerRadius = UDim.new(0, 12)
    local gameFuncStroke = Instance.new("UIStroke", gameFunctionsFrame)
    gameFuncStroke.Thickness = 2
    env.animatedElements[gameFuncStroke] = "stroke"

    -- Header
    local gameFuncHeader = Instance.new("TextLabel")
    gameFuncHeader.Name = "Header"
    gameFuncHeader.Size = UDim2.new(1, -50, 0, 26)
    gameFuncHeader.Position = UDim2.new(0, 12, 0, 8)
    gameFuncHeader.BackgroundTransparency = 1
    gameFuncHeader.Font = Enum.Font.GothamBold
    gameFuncHeader.TextSize = 14
    gameFuncHeader.TextXAlignment = Enum.TextXAlignment.Left
    gameFuncHeader.TextColor3 = env.currentTheme.text
    gameFuncHeader.Text = "\240\159\142\174 Game Functions"
    gameFuncHeader.Parent = gameFunctionsFrame

    -- Close button
    local gameFunctionsCloseButton = Instance.new("TextButton")
    gameFunctionsCloseButton.Size = UDim2.new(0, 24, 0, 24)
    gameFunctionsCloseButton.Position = UDim2.new(1, -32, 0, 8)
    gameFunctionsCloseButton.BackgroundColor3 = env.currentTheme.secondary
    gameFunctionsCloseButton.Font = Enum.Font.GothamBold
    gameFunctionsCloseButton.TextSize = 14
    gameFunctionsCloseButton.TextColor3 = Color3.new(1, 1, 1)
    gameFunctionsCloseButton.Text = "\195\151"
    gameFunctionsCloseButton.BorderSizePixel = 0
    gameFunctionsCloseButton.Parent = gameFunctionsFrame
    Instance.new("UICorner", gameFunctionsCloseButton).CornerRadius = UDim.new(0, 6)

    -- Game selector label
    local selectLabel = Instance.new("TextLabel")
    selectLabel.Size = UDim2.new(1, -20, 0, 18)
    selectLabel.Position = UDim2.new(0, 10, 0, 38)
    selectLabel.BackgroundTransparency = 1
    selectLabel.Font = Enum.Font.GothamMedium
    selectLabel.TextSize = 11
    selectLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectLabel.TextColor3 = env.currentTheme.text
    selectLabel.Text = "Select Game:"
    selectLabel.Parent = gameFunctionsFrame

    -- Game selector input
    local gameSelectInput = Instance.new("TextBox")
    gameSelectInput.Size = UDim2.new(1, -20, 0, 28)
    gameSelectInput.Position = UDim2.new(0, 10, 0, 58)
    gameSelectInput.BackgroundColor3 = env.currentTheme.secondary
    gameSelectInput.BorderSizePixel = 0
    gameSelectInput.Font = Enum.Font.GothamMedium
    gameSelectInput.TextSize = 12
    gameSelectInput.TextColor3 = Color3.new(1, 1, 1)
    gameSelectInput.PlaceholderText = "Type game name..."
    gameSelectInput.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    gameSelectInput.Text = ""
    gameSelectInput.ClearTextOnFocus = false
    gameSelectInput.Parent = gameFunctionsFrame
    Instance.new("UICorner", gameSelectInput).CornerRadius = UDim.new(0, 6)

    -- Autofill dropdown list
    local gameSelectList = Instance.new("Frame")
    gameSelectList.Size = UDim2.new(1, -20, 0, 0)
    gameSelectList.Position = UDim2.new(0, 10, 0, 88)
    gameSelectList.BackgroundColor3 = env.currentTheme.secondary
    gameSelectList.BorderSizePixel = 0
    gameSelectList.Visible = false
    gameSelectList.ClipsDescendants = true
    gameSelectList.Parent = gameFunctionsFrame
    Instance.new("UICorner", gameSelectList).CornerRadius = UDim.new(0, 6)

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = gameSelectList

    -- Container for function buttons (below selector)
    local funcContainer = Instance.new("Frame")
    funcContainer.Name = "FuncContainer"
    funcContainer.Size = UDim2.new(1, -20, 0, 0)
    funcContainer.Position = UDim2.new(0, 10, 0, 95)
    funcContainer.BackgroundTransparency = 1
    funcContainer.Parent = gameFunctionsFrame

    -- Function to rebuild the functions list
    local function rebuildGameFunctions()
        -- Clear old buttons
        for _, child in ipairs(funcContainer:GetChildren()) do
            child:Destroy()
        end
        env.gameFunctionButtons = {}

        if not env.selectedGame then
            funcContainer.Size = UDim2.new(1, -20, 0, 0)
            gameFunctionsFrame.Size = UDim2.new(0, 220, 0, 130)
            return
        end

        -- Update header
        gameFuncHeader.Text = "\240\159\142\174 " .. env.selectedGame.name

        -- Create function buttons
        local funcY = 0
        for i, func in ipairs(env.selectedGame.functions) do
            env.gameFunctionStates[func.name] = env.gameFunctionStates[func.name] or false

            local funcBtn = Instance.new("TextButton")
            funcBtn.Size = UDim2.new(1, 0, 0, 28)
            funcBtn.Position = UDim2.new(0, 0, 0, funcY)
            funcBtn.BackgroundColor3 = env.currentTheme.secondary
            funcBtn.BorderSizePixel = 0
            funcBtn.Font = Enum.Font.GothamMedium
            funcBtn.TextSize = 11
            funcBtn.TextColor3 = Color3.new(1, 1, 1)
            funcBtn.Text = func.name .. ": " .. (env.gameFunctionStates[func.name] and "ON" or "OFF")
            funcBtn.Parent = funcContainer
            Instance.new("UICorner", funcBtn).CornerRadius = UDim.new(0, 6)

            env.gameFunctionButtons[func.name] = funcBtn

            env.connect(funcBtn.MouseButton1Click, function()
                env.playClickSound()
                env.gameFunctionStates[func.name] = not env.gameFunctionStates[func.name]
                funcBtn.Text = func.name .. ": " .. (env.gameFunctionStates[func.name] and "ON" or "OFF")
            end)

            funcY = funcY + 32
        end

        funcContainer.Size = UDim2.new(1, -20, 0, funcY)
        gameFunctionsFrame.Size = UDim2.new(0, 220, 0, 95 + funcY + 15)
    end

    -- Function to update autofill list
    local function updateAutofillList(text)
        -- Clear old items
        for _, child in ipairs(gameSelectList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        if text == "" then
            -- Show all games
            local matches = env.getGameNames()
            local height = math.min(#matches * 24, 96)
            gameSelectList.Size = UDim2.new(1, -20, 0, height)
            gameSelectList.Visible = #matches > 0

            for i, name in ipairs(matches) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 24)
                item.BackgroundColor3 = env.currentTheme.secondary
                item.BackgroundTransparency = 0.3
                item.BorderSizePixel = 0
                item.Font = Enum.Font.GothamMedium
                item.TextSize = 11
                item.TextColor3 = Color3.new(1, 1, 1)
                item.Text = name
                item.LayoutOrder = i
                item.Parent = gameSelectList

                env.connect(item.MouseButton1Click, function()
                    env.playClickSound()
                    gameSelectInput.Text = name
                    env.selectedGame = env.findGameByName(name)
                    gameSelectList.Visible = false
                    rebuildGameFunctions()
                end)
            end
        else
            -- Show matching games
            local matches = env.findMatchingGames(text)
            local height = math.min(#matches * 24, 96)
            gameSelectList.Size = UDim2.new(1, -20, 0, height)
            gameSelectList.Visible = #matches > 0

            for i, name in ipairs(matches) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 24)
                item.BackgroundColor3 = env.currentTheme.secondary
                item.BackgroundTransparency = 0.3
                item.BorderSizePixel = 0
                item.Font = Enum.Font.GothamMedium
                item.TextSize = 11
                item.TextColor3 = Color3.new(1, 1, 1)
                item.Text = name
                item.LayoutOrder = i
                item.Parent = gameSelectList

                env.connect(item.MouseButton1Click, function()
                    env.playClickSound()
                    gameSelectInput.Text = name
                    env.selectedGame = env.findGameByName(name)
                    gameSelectList.Visible = false
                    rebuildGameFunctions()
                end)
            end
        end
    end

    -- Input events
    env.connect(gameSelectInput.Focused, function()
        updateAutofillList(gameSelectInput.Text)
    end)

    env.connect(gameSelectInput:GetPropertyChangedSignal("Text"), function()
        updateAutofillList(gameSelectInput.Text)
    end)

    env.connect(gameSelectInput.FocusLost, function(enterPressed)
        task.delay(0.1, function() -- Small delay to allow clicking on list items
            if not gameSelectInput:IsFocused() then
                gameSelectList.Visible = false
            end
        end)

        if enterPressed then
            local game = env.findGameByName(gameSelectInput.Text)
            if game then
                env.selectedGame = game
                rebuildGameFunctions()
            end
        end
    end)

    -- EVENTS
    env.connect(openBtn.MouseButton1Click, function() env.playClickSound(); mainFrame.Visible = true; openBtn.Visible = false end)
    env.connect(closeBtn.MouseButton1Click, function() env.playClickSound(); mainFrame.Visible = false; openBtn.Visible = true; extraSettingsFrame.Visible = false; if gameFunctionsFrame then gameFunctionsFrame.Visible = false end end)
    env.connect(infoToggleButton.MouseButton1Click, function()
        env.playClickSound()
        env.toggleTooltips()
        if env.tooltipsEnabled then env.animatedElements[infoToggleButton] = "background"
        else env.animatedElements[infoToggleButton] = nil; infoToggleButton.BackgroundColor3 = env.currentTheme.secondary end
    end)
    env.connect(extraSettingsButton.MouseButton1Click, function() env.playClickSound(); extraSettingsFrame.Visible = not extraSettingsFrame.Visible end)
    env.connect(extraSettingsCloseButton.MouseButton1Click, function() env.playClickSound(); extraSettingsFrame.Visible = false end)

    -- Game functions button events
    env.connect(gameFunctionsButton.MouseButton1Click, function()
        env.playClickSound()
        gameFunctionsFrame.Visible = not gameFunctionsFrame.Visible
    end)
    env.connect(gameFunctionsCloseButton.MouseButton1Click, function()
        env.playClickSound()
        gameFunctionsFrame.Visible = false
    end)

    env.connect(saveButton.MouseButton1Click, function()
        env.playClickSound()
        saveButton.Text = env.saveSettings() and "\226\156\147 Saved!" or "\226\156\151 Error"
        task.delay(1.5, function() if saveButton and saveButton.Parent then saveButton.Text = "\240\159\146\190 Save" end end)
    end)

    env.connect(loadButton.MouseButton1Click, function()
        env.playClickSound()
        local data = env.loadSettingsData()
        if data and env.applySettingsData(data) then
            loadButton.Text = "\226\156\147 Loaded!"
            env.refreshAllUI(); env.applyThemeToUI(); env.rebuildFriendsList(); env.syncTargetingOptions()
        else loadButton.Text = "\226\156\151 None" end
        task.delay(1.5, function() if loadButton and loadButton.Parent then loadButton.Text = "\240\159\147\130 Load" end end)
    end)

    local function setTab(n)
        mainPage.Visible = n == "Main"
        visualPage.Visible = n == "Visual"
        targetPage.Visible = n == "Target"
        for _, tab in ipairs({tabMainButton, tabVisualButton, tabTargetButton}) do
            env.animatedElements[tab] = nil
            if tab.Parent then tab.BackgroundColor3 = env.currentTheme.secondary end
        end
        local active = n == "Main" and tabMainButton or n == "Visual" and tabVisualButton or tabTargetButton
        env.animatedElements[active] = "background"
    end

    env.connect(tabMainButton.MouseButton1Click, function() env.playClickSound(); setTab("Main") end)
    env.connect(tabVisualButton.MouseButton1Click, function() env.playClickSound(); setTab("Visual") end)
    env.connect(tabTargetButton.MouseButton1Click, function() env.playClickSound(); setTab("Target") end)

    env.connect(autoswapButton.MouseButton1Click, function() env.playClickSound(); env.autoSwapEnabled = not env.autoSwapEnabled; env.refreshAllUI() end)
    env.connect(closeSwapButton.MouseButton1Click, function() env.playClickSound(); env.closeSwapEnabled = not env.closeSwapEnabled; env.refreshAllUI() end)
    env.connect(checkVisibilityButton.MouseButton1Click, function() env.playClickSound(); env.visibilityCheckEnabled = not env.visibilityCheckEnabled; env.syncTargetingOptions(); env.refreshAllUI() end)
    env.connect(checkHealthButton.MouseButton1Click, function() env.playClickSound(); env.checkHealthEnabled = not env.checkHealthEnabled; env.syncTargetingOptions(); env.refreshAllUI() end)
    env.connect(autoRelockButton.MouseButton1Click, function() env.playClickSound(); env.autoRelockEnabled = not env.autoRelockEnabled; env.refreshAllUI() end)
    env.connect(realisticButton.MouseButton1Click, function() env.playClickSound(); env.realisticEnabled = not env.realisticEnabled; env.syncTargetingOptions(); env.refreshAllUI() end)

    env.connect(highlightButton.MouseButton1Click, function() env.playClickSound(); if env.visuals then pcall(function() env.visuals:SetHighlightEnabled(not env.visuals:IsHighlightEnabled()) end); env.updateNPCHighlight() end; env.refreshAllUI() end)
    env.connect(highlightSecondButton.MouseButton1Click, function() env.playClickSound(); if env.visuals then pcall(function() env.visuals:SetHighlightSecondEnabled(not env.visuals:IsHighlightSecondEnabled()) end) end; env.refreshAllUI() end)
    env.connect(selfFadeButton.MouseButton1Click, function() env.playClickSound(); if env.visuals then pcall(function() env.visuals:SetSelfFadeEnabled(not env.visuals:IsSelfFadeEnabled()) end) end; env.refreshAllUI() end)

    -- Custom Shiftlock controls
    env.connect(centerShiftlockButton.MouseButton1Click, function()
        env.playClickSound()
        env.toggleCustomShiftlock()
        env.refreshAllUI()
    end)
    env.connect(shiftlockKeyButton.MouseButton1Click, function()
        env.playClickSound()
        env.waitingForKeybind = "ShiftLock"
        shiftlockKeyButton.Text = "..."
    end)
    env.connect(shiftlockKeyToggleButton.MouseButton1Click, function()
        env.playClickSound()
        env.shiftlockKeyEnabled = not env.shiftlockKeyEnabled
        env.refreshAllUI()
    end)
    env.connect(shiftlockAutoEnableButton.MouseButton1Click, function()
        env.playClickSound()
        env.shiftlockAutoEnable = not env.shiftlockAutoEnable
        env.refreshAllUI()
    end)

    env.connect(mouseTargetButton.MouseButton1Click, function() env.playClickSound(); env.mouseTargetMode = not env.mouseTargetMode; env.refreshAllUI() end)

    env.connect(lockOnKeyButton.MouseButton1Click, function() env.playClickSound(); env.waitingForKeybind = "LockOn"; lockOnKeyButton.Text = "..." end)
    env.connect(swapKeyButton.MouseButton1Click, function() env.playClickSound(); env.waitingForKeybind = "SwapTarget"; swapKeyButton.Text = "..." end)

    env.connect(reverseKeyButton.MouseButton1Click, function() env.playClickSound(); env.waitingForKeybind = "ReverseLock"; reverseKeyButton.Text = "..." end)

    env.connect(reverseLockButton.MouseButton1Click, function() env.playClickSound(); env.reverseLockEnabled = not env.reverseLockEnabled; env.refreshAllUI() end)
    env.connect(perfectOffsetButton.MouseButton1Click, function() env.playClickSound(); env.perfectOffsetEnabled = not env.perfectOffsetEnabled; env.refreshAllUI() end)
    env.connect(npcModeButton.MouseButton1Click, function() env.playClickSound(); env.npcModeEnabled = not env.npcModeEnabled; env.refreshAllUI() end)
    env.connect(predictionButton.MouseButton1Click, function() env.playClickSound(); env.predictionEnabled = not env.predictionEnabled; env.refreshAllUI() end)
    env.connect(forceCameraButton.MouseButton1Click, function()
        env.playClickSound()
        env.forceCameraMode = not env.forceCameraMode
        env.setupForceCameraHooks()
        env.refreshAllUI()
    end)

    env.connect(mouseResistanceButton.MouseButton1Click, function()
        env.playClickSound()
        env.mouseResistanceEnabled = not env.mouseResistanceEnabled
        env.refreshAllUI()
    end)

    env.connect(rangeInput.FocusLost, function() env.rangeLimit = math.max(0, tonumber(rangeInput.Text) or 0); rangeInput.Text = tostring(env.rangeLimit); env.syncTargetingOptions() end)

    local dragging = false
    env.connect(heightSliderBar.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    env.connect(heightSliderBar.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    env.connect(env.UserInputService.InputChanged, function(i)
        if dragging and heightSliderBar.Parent and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local a = math.clamp((env.UserInputService:GetMouseLocation().X - heightSliderBar.AbsolutePosition.X) / heightSliderBar.AbsoluteSize.X, 0, 1)
            if heightSliderKnob.Parent then heightSliderKnob.Position = UDim2.new(a, 0, 0.5, 0) end
            env.lockHeightOffset = env.SLIDER_MIN + (env.SLIDER_MAX - env.SLIDER_MIN) * a
            if heightLabel and heightLabel.Parent then heightLabel.Text = string.format("Height: %.1f", env.lockHeightOffset) end
        end
    end)

    -- Mouse resistance slider
    local draggingResistance = false
    env.connect(mouseResistanceSliderBar.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingResistance = true end end)
    env.connect(mouseResistanceSliderBar.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then draggingResistance = false end end)
    env.connect(env.UserInputService.InputChanged, function(i)
        if draggingResistance and mouseResistanceSliderBar.Parent and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local a = math.clamp((env.UserInputService:GetMouseLocation().X - mouseResistanceSliderBar.AbsolutePosition.X) / mouseResistanceSliderBar.AbsoluteSize.X, 0, 1)
            if mouseResistanceSliderKnob.Parent then mouseResistanceSliderKnob.Position = UDim2.new(a, 0, 0.5, 0) end
            -- Convert 0-1 slider position to -1 to 1 scale
            env.mouseResistanceScale = (a * 2) - 1
            if mouseResistanceLabel and mouseResistanceLabel.Parent then mouseResistanceLabel.Text = string.format("Resistance: %.0f%%", env.mouseResistanceScale * 100) end
        end
    end)

    -- LockOn+ controls
    env.connect(lockOnPlusButton.MouseButton1Click, function()
        env.playClickSound()
        env.lockOnPlusEnabled = not env.lockOnPlusEnabled
        env.refreshAllUI()
    end)
    env.connect(lockOnPlusKeyButton.MouseButton1Click, function()
        env.playClickSound()
        env.waitingForKeybind = "LockOnPlus"
        lockOnPlusKeyButton.Text = "..."
    end)

    setTab("Main")
    env.refreshAllUI()
    env.applyThemeToUI()
    env.rebuildFriendsList()
    env.syncTargetingOptions()

    local indicator = Instance.new("TextLabel")
    indicator.Size = UDim2.new(0, 160, 0, 28)
    indicator.Position = UDim2.new(0.5, -80, 0, 10)
    indicator.BackgroundColor3 = env.currentTheme.background
    indicator.BackgroundTransparency = 0.1
    indicator.TextColor3 = Color3.new(1, 1, 1)
    indicator.Font = Enum.Font.GothamBold
    indicator.TextSize = 13
    indicator.Visible = false
    indicator.Parent = gui
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 10)
    local indicatorStroke = Instance.new("UIStroke", indicator)
    indicatorStroke.Thickness = 2
    env.animatedElements[indicatorStroke] = "stroke"

    -- Health bar container
    local healthContainer = Instance.new("Frame")
    healthContainer.Size = UDim2.new(0, 160, 0, 20)
    healthContainer.Position = UDim2.new(0.5, -80, 0, 42)
    healthContainer.BackgroundColor3 = env.currentTheme.background
    healthContainer.BackgroundTransparency = 0.1
    healthContainer.Visible = false
    healthContainer.Parent = gui
    Instance.new("UICorner", healthContainer).CornerRadius = UDim.new(0, 10)
    local healthContainerStroke = Instance.new("UIStroke", healthContainer)
    healthContainerStroke.Thickness = 2
    env.animatedElements[healthContainerStroke] = "stroke"

    -- Health bar fill
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, -8, 1, -8)
    healthBar.Position = UDim2.new(0, 4, 0, 4)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthContainer
    Instance.new("UICorner", healthBar).CornerRadius = UDim.new(0, 6)

    -- Health text
    local healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.new(1, 1, 1)
    healthText.Font = Enum.Font.GothamBold
    healthText.TextSize = 11
    healthText.Text = "100/100"
    healthText.Parent = healthContainer

    env.connect(env.RunService.Heartbeat, function()
        if indicator.Parent then
            if env.lockedOn and env.currentTarget then
                indicator.Visible = true
                healthContainer.Visible = true
                indicator.Text = (env.currentTargetType == "npc" and "\240\159\145\190 " or "\240\159\142\175 ") .. tostring(env.currentTarget.Name or "Unknown")

                -- Get target health
                local targetChar = (env.currentTargetType == "player") and (env.currentTarget and env.currentTarget.Character) or env.currentTarget
                if targetChar then
                    local hum = targetChar:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local hp = math.floor(hum.Health)
                        local maxHp = math.floor(hum.MaxHealth)
                        local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

                        -- Update health bar size
                        healthBar.Size = UDim2.new(ratio * (1 - 8/160), 0, 1, -8)

                        -- Update health bar color (green -> yellow -> red)
                        if ratio > 0.5 then
                            healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                        elseif ratio > 0.25 then
                            healthBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                        else
                            healthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                        end

                        healthText.Text = hp .. "/" .. maxHp
                    else
                        healthText.Text = "???"
                        healthBar.Size = UDim2.new(0, 0, 1, -8)
                    end
                end
            else
                indicator.Visible = false
                healthContainer.Visible = false
            end
        end
    end)

    -- Return all UI element references the main script needs
    return {
        gui = gui,
        mainFrame = mainFrame,
        openBtn = openBtn,
        closeBtn = closeBtn,
        infoToggleButton = infoToggleButton,
        headerLabel = headerLabel,
        tabMainButton = tabMainButton,
        tabVisualButton = tabVisualButton,
        tabTargetButton = tabTargetButton,
        mainPage = mainPage,
        visualPage = visualPage,
        targetPage = targetPage,
        highlightButton = highlightButton,
        highlightSecondButton = highlightSecondButton,
        selfFadeButton = selfFadeButton,
        autoswapButton = autoswapButton,
        closeSwapButton = closeSwapButton,
        checkVisibilityButton = checkVisibilityButton,
        checkHealthButton = checkHealthButton,
        autoRelockButton = autoRelockButton,
        realisticButton = realisticButton,
        centerShiftlockButton = centerShiftlockButton,
        lockOnKeyButton = lockOnKeyButton,
        swapKeyButton = swapKeyButton,
        mouseTargetButton = mouseTargetButton,
        friendsList = friendsList,
        heightLabel = heightLabel,
        heightSliderBar = heightSliderBar,
        heightSliderKnob = heightSliderKnob,
        rangeInput = rangeInput,
        extraSettingsFrame = extraSettingsFrame,
        extraSettingsButton = extraSettingsButton,
        extraSettingsCloseButton = extraSettingsCloseButton,
        reverseLockButton = reverseLockButton,
        reverseKeyButton = reverseKeyButton,
        perfectOffsetButton = perfectOffsetButton,
        npcModeButton = npcModeButton,
        predictionButton = predictionButton,
        forceCameraButton = forceCameraButton,
        shiftlockKeyButton = shiftlockKeyButton,
        shiftlockAutoEnableButton = shiftlockAutoEnableButton,
        shiftlockKeyToggleButton = shiftlockKeyToggleButton,
        mouseResistanceButton = mouseResistanceButton,
        mouseResistanceSliderBar = mouseResistanceSliderBar,
        mouseResistanceSliderKnob = mouseResistanceSliderKnob,
        mouseResistanceLabel = mouseResistanceLabel,
        lockOnPlusButton = lockOnPlusButton,
        lockOnPlusKeyButton = lockOnPlusKeyButton,
        gameFunctionsButton = gameFunctionsButton,
        gameFunctionsFrame = gameFunctionsFrame,
        gameFunctionsCloseButton = gameFunctionsCloseButton,
        gameSelectInput = gameSelectInput,
        gameSelectList = gameSelectList,
        gameFunctionButtons = env.gameFunctionButtons,
        themeButtons = themeButtons,
        indicator = indicator,
        healthContainer = healthContainer,
        healthBar = healthBar,
        healthText = healthText,
        saveButton = saveButton,
        loadButton = loadButton,
        lockCamToggleBtn = lockCamToggleBtn,
        lockCamToggleModeBtn = lockCamToggleModeBtn,
        lockCamToggleKeyBtn = lockCamToggleKeyBtn,
    }
end

return Module
