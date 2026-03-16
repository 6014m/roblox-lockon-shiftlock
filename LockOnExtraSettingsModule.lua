-- LockOnExtraSettingsModule.lua
-- Extra Settings panel, Game Functions, Teams Mode
-- Loaded via HttpGet, receives a shared state table from main script

local module = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Game-specific functions data
local AVAILABLE_GAMES = {
    {
        name = "JJS",
        ids = {"3508322461"},
        functions = {
            {
                name = "Nanami Perfect Special",
                description = "Auto-time R special based on target HP (27 stud range)",
                enabled = false,
                execute = function(target)
                    if not target then return end
                    local targetChar = target.Character
                    if not targetChar then return end
                    local myChar = game.Players.LocalPlayer.Character
                    if not myChar then return end
                    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot or not targetRoot then return end
                    local distance = (myRoot.Position - targetRoot.Position).Magnitude
                    if distance > 27 then return end
                    local hum = targetChar:FindFirstChildOfClass("Humanoid")
                    if not hum then return end
                    local hpPercent = (hum.Health / hum.MaxHealth) * 100
                    local waitTime = hpPercent < 80 and 0.55 or 0.63
                    task.delay(waitTime, function()
                        pcall(function()
                            game:GetService("ReplicatedStorage").Knit.Knit.Services.NanamiService.RE.RightActivated:FireServer(targetChar)
                        end)
                    end)
                end
            }
        }
    },
}

local selectedGame = nil
local gameFunctionStates = {}
local gameFunctionButtons = {}

local function getGameNames()
    local names = {}
    for _, g in ipairs(AVAILABLE_GAMES) do table.insert(names, g.name) end
    return names
end

local function findGameByName(name)
    for _, g in ipairs(AVAILABLE_GAMES) do
        if g.name:lower() == name:lower() then return g end
    end
    return nil
end

local function findMatchingGames(partial)
    local matches = {}
    partial = partial:lower()
    for _, g in ipairs(AVAILABLE_GAMES) do
        if g.name:lower():sub(1, #partial) == partial then table.insert(matches, g.name) end
    end
    return matches
end

function module.getSelectedGame() return selectedGame end
function module.getGameFunctionStates() return gameFunctionStates end

-- Teams mode
local teamsModeConnection = nil
local teamsPlayerConnections = {}
local S = nil -- shared state reference

local function isTeamsModeEnabled()
    return S and S.getTeamsMode and S.getTeamsMode() or false
end

local function setTeamsModeEnabled(v)
    if S and S.setTeamsMode then S.setTeamsMode(v) end
end

local function syncTeamFriendlies()
    if not S or not isTeamsModeEnabled() then return end
    pcall(function()
        local lp = S.localPlayer
        local myTeam = lp.Team
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= lp then
                if myTeam and plr.Team == myTeam then
                    S.friendlies[plr.UserId] = true
                else
                    S.friendlies[plr.UserId] = nil
                end
            end
        end
        if S.currentTarget and S.friendlies[S.currentTarget.UserId] then
            S.lockedOn = false
            S.currentTarget = nil
        end
        pcall(function() S.rebuildFriendsList() end)
    end)
end

function module.stopTeamsMode()
    if teamsModeConnection then pcall(function() teamsModeConnection:Disconnect() end); teamsModeConnection = nil end
    for _, c in ipairs(teamsPlayerConnections) do pcall(function() c:Disconnect() end) end
    teamsPlayerConnections = {}
end

function module.startTeamsMode()
    module.stopTeamsMode()
    if not S then return end
    syncTeamFriendlies()
    pcall(function()
        teamsModeConnection = S.connect(S.localPlayer:GetPropertyChangedSignal("Team"), function() syncTeamFriendlies() end)
    end)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= S.localPlayer then
            pcall(function()
                local c = S.connect(plr:GetPropertyChangedSignal("Team"), function() syncTeamFriendlies() end)
                table.insert(teamsPlayerConnections, c)
            end)
        end
    end
    table.insert(teamsPlayerConnections, S.connect(Players.PlayerAdded, function(plr)
        pcall(function()
            local c = S.connect(plr:GetPropertyChangedSignal("Team"), function() syncTeamFriendlies() end)
            table.insert(teamsPlayerConnections, c)
        end)
        syncTeamFriendlies()
    end))
    table.insert(teamsPlayerConnections, S.connect(Players.PlayerRemoving, function() syncTeamFriendlies() end))
end

function module.toggleTeamsMode()
    if not S then return end
    setTeamsModeEnabled(not isTeamsModeEnabled())
    if isTeamsModeEnabled() then module.startTeamsMode() else module.stopTeamsMode() end
    S.refreshAllUI()
end

--[[
    module.init(shared)

    shared is a table with these fields:
    - gui: ScreenGui parent
    - connect(signal, callback): connection helper
    - createButton(parent, y, text, tip): button factory
    - playClickSound(): sound
    - refreshAllUI(): refresh
    - currentTheme: theme table
    - animatedElements: table
    - State setters (closures that write to main script locals):
      - setReverseLock(v), setPerfectOffset(v), setNpcMode(v), setPrediction(v)
      - setForceCamera(v), setMouseResistance(v), setMouseResistanceScale(v)
      - setLockOnPlus(v), setWaitingForKeybind(v)
      - setLockCamToggle(v), setLockCamToggleMode(v), setLockCamToggleActive(v)
      - setupForceCameraHooks()
      - getMouseResistanceScale(): number

    Returns table of UI element references.
]]
function module.init(shared)
    S = shared
    local connect = shared.connect
    local createButton = shared.createButton
    local playClickSound = shared.playClickSound
    local ct = shared.currentTheme
    local ae = shared.animatedElements

    local ui = {}

    -- EXTRA SETTINGS FRAME
    local esf = Instance.new("Frame")
    esf.Size = UDim2.new(0, 320, 0, 420)
    esf.Position = UDim2.new(0, 340, 1, -440)
    esf.BackgroundColor3 = ct.background
    esf.BorderSizePixel = 0
    esf.Visible = false
    esf.ClipsDescendants = true
    esf.Parent = shared.gui
    Instance.new("UICorner", esf).CornerRadius = UDim.new(0, 12)
    local es = Instance.new("UIStroke", esf); es.Thickness = 2; ae[es] = "stroke"

    local eh = Instance.new("TextLabel")
    eh.Size = UDim2.new(1, -50, 0, 26); eh.Position = UDim2.new(0, 12, 0, 8)
    eh.BackgroundTransparency = 1; eh.Font = Enum.Font.GothamBold; eh.TextSize = 14
    eh.TextXAlignment = Enum.TextXAlignment.Left; eh.TextColor3 = ct.text
    eh.Text = "⚙ Extra Settings"; eh.Parent = esf

    local escb = Instance.new("TextButton")
    escb.Size = UDim2.new(0, 26, 0, 26); escb.Position = UDim2.new(1, -34, 0, 8)
    escb.BackgroundColor3 = ct.secondary; escb.Font = Enum.Font.GothamBold; escb.TextSize = 14
    escb.TextColor3 = Color3.new(1,1,1); escb.Text = "×"; escb.BorderSizePixel = 0; escb.Parent = esf
    Instance.new("UICorner", escb).CornerRadius = UDim.new(0, 6)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -45); scroll.Position = UDim2.new(0, 5, 0, 40)
    scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = ct.primary1; scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 460); scroll.Parent = esf

    local function btn(y, text, tip)
        local b = createButton(scroll, y, text, tip)
        b.Position = UDim2.new(0, 5, 0, y); b.Size = UDim2.new(1, -10, 0, 28)
        return b
    end

    local rlb = btn(0, "Reverse lock: OFF", "Flips the camera 180 degrees so you face AWAY from your target.")
    local rkb = btn(32, "Reverse: B", "Hold this key to temporarily activate reverse lock. Click to rebind.")
    local pob = btn(64, "Perfect offset: OFF", "Offsets aim slightly to the side for cinematic angle.")
    local nmb = btn(96, "NPC Mode: OFF", "Allows locking onto NPCs in addition to players.")
    local prb = btn(128, "Prediction: OFF", "Leads aim ahead of moving target based on velocity.")
    local fcb = btn(160, "Force Camera: OFF", "Overrides game camera scripts entirely.")
    local mrb = btn(192, "Mouse Resist: OFF", "Controls camera resistance to being pulled from target.")

    local mrl = Instance.new("TextLabel")
    mrl.Size = UDim2.new(1, -10, 0, 16); mrl.Position = UDim2.new(0, 5, 0, 224)
    mrl.BackgroundTransparency = 1; mrl.Font = Enum.Font.Gotham; mrl.TextSize = 11
    mrl.TextColor3 = ct.text; mrl.TextXAlignment = Enum.TextXAlignment.Left
    mrl.Text = string.format("Resistance: %.0f%%", shared.getMouseResistanceScale() * 100)
    mrl.Parent = scroll

    local mrsb = Instance.new("Frame")
    mrsb.Size = UDim2.new(1, -10, 0, 8); mrsb.Position = UDim2.new(0, 5, 0, 242)
    mrsb.BackgroundColor3 = ct.secondary; mrsb.BorderSizePixel = 0; mrsb.Parent = scroll
    Instance.new("UICorner", mrsb).CornerRadius = UDim.new(0, 4)

    local mrsk = Instance.new("Frame")
    mrsk.Size = UDim2.new(0, 16, 0, 16)
    mrsk.Position = UDim2.new((shared.getMouseResistanceScale() + 1) / 2, 0, 0.5, 0)
    mrsk.AnchorPoint = Vector2.new(0.5, 0.5)
    mrsk.BackgroundColor3 = ct.primary1; mrsk.BorderSizePixel = 0; mrsk.Parent = mrsb
    Instance.new("UICorner", mrsk).CornerRadius = UDim.new(1, 0)

    local lpb = btn(260, "LockOn+: OFF", "Rotates character body to face locked target while camera stays free.")
    local lpkb = btn(292, "LockOn+ Key: Q", "Hold to activate body rotation toward target. Click to rebind.")
    local lctb = btn(324, "LockCamToggle: OFF", "Keeps target selected but camera moves freely.")
    local lctmb = btn(356, "Mode: Hold", "Hold: active while held. Toggle: press to toggle.")
    local lctkb = btn(388, "LockCam Key: F", "Key for LockCamToggle. Click to rebind.")

    -- LockCamToggle events
    connect(lctb.MouseButton1Click, function() playClickSound(); shared.setLockCamToggle(not shared.getLockCamToggle()); if not shared.getLockCamToggle() then shared.setLockCamToggleActive(false) end; shared.refreshAllUI() end)
    connect(lctmb.MouseButton1Click, function() playClickSound(); shared.setLockCamToggleMode(shared.getLockCamToggleMode() == "Hold" and "Toggle" or "Hold"); shared.setLockCamToggleActive(false); shared.refreshAllUI() end)
    connect(lctkb.MouseButton1Click, function() playClickSound(); shared.setWaitingForKeybind("_LockCamToggle"); lctkb.Text = "..." end)

    -- Extra settings button events
    connect(rlb.MouseButton1Click, function() playClickSound(); shared.setReverseLock(not shared.getReverseLock()); shared.refreshAllUI() end)
    connect(rkb.MouseButton1Click, function() playClickSound(); shared.setWaitingForKeybind("ReverseLock"); rkb.Text = "..." end)
    connect(pob.MouseButton1Click, function() playClickSound(); shared.setPerfectOffset(not shared.getPerfectOffset()); shared.refreshAllUI() end)
    connect(nmb.MouseButton1Click, function() playClickSound(); shared.setNpcMode(not shared.getNpcMode()); shared.refreshAllUI() end)
    connect(prb.MouseButton1Click, function() playClickSound(); shared.setPrediction(not shared.getPrediction()); shared.refreshAllUI() end)
    connect(fcb.MouseButton1Click, function() playClickSound(); shared.setForceCamera(not shared.getForceCamera()); shared.setupForceCameraHooks(); shared.refreshAllUI() end)
    connect(mrb.MouseButton1Click, function() playClickSound(); shared.setMouseResistance(not shared.getMouseResistance()); shared.refreshAllUI() end)
    connect(lpb.MouseButton1Click, function() playClickSound(); shared.setLockOnPlus(not shared.getLockOnPlus()); shared.refreshAllUI() end)
    connect(lpkb.MouseButton1Click, function() playClickSound(); shared.setWaitingForKeybind("LockOnPlus"); lpkb.Text = "..." end)

    -- Mouse resistance slider
    local dragging = false
    connect(mrsb.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    connect(mrsb.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    connect(UserInputService.InputChanged, function(i)
        if dragging and mrsb.Parent and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local a = math.clamp((UserInputService:GetMouseLocation().X - mrsb.AbsolutePosition.X) / mrsb.AbsoluteSize.X, 0, 1)
            if mrsk.Parent then mrsk.Position = UDim2.new(a, 0, 0.5, 0) end
            shared.setMouseResistanceScale((a * 2) - 1)
            if mrl and mrl.Parent then mrl.Text = string.format("Resistance: %.0f%%", shared.getMouseResistanceScale() * 100) end
        end
    end)

    -- GAME FUNCTIONS
    local gfb = createButton(scroll, 420, "🎮 Game Functions", "Opens game-specific functions panel.")
    gfb.Position = UDim2.new(0, 5, 0, 420); gfb.Size = UDim2.new(1, -10, 0, 28)
    gfb.BackgroundColor3 = Color3.fromRGB(80, 40, 100)
    esf.Size = UDim2.new(0, 320, 0, 420)

    local gff = Instance.new("Frame")
    gff.Size = UDim2.new(0, 220, 0, 200); gff.Position = UDim2.new(0, 668, 1, -440)
    gff.BackgroundColor3 = ct.background; gff.BorderSizePixel = 0; gff.Visible = false
    gff.Parent = shared.gui
    Instance.new("UICorner", gff).CornerRadius = UDim.new(0, 12)
    local gfs = Instance.new("UIStroke", gff); gfs.Thickness = 2; ae[gfs] = "stroke"

    local gfh = Instance.new("TextLabel")
    gfh.Name = "Header"; gfh.Size = UDim2.new(1, -50, 0, 26); gfh.Position = UDim2.new(0, 12, 0, 8)
    gfh.BackgroundTransparency = 1; gfh.Font = Enum.Font.GothamBold; gfh.TextSize = 14
    gfh.TextXAlignment = Enum.TextXAlignment.Left; gfh.TextColor3 = ct.text
    gfh.Text = "🎮 Game Functions"; gfh.Parent = gff

    local gfcb = Instance.new("TextButton")
    gfcb.Size = UDim2.new(0, 24, 0, 24); gfcb.Position = UDim2.new(1, -32, 0, 8)
    gfcb.BackgroundColor3 = ct.secondary; gfcb.Font = Enum.Font.GothamBold; gfcb.TextSize = 14
    gfcb.TextColor3 = Color3.new(1,1,1); gfcb.Text = "×"; gfcb.BorderSizePixel = 0; gfcb.Parent = gff
    Instance.new("UICorner", gfcb).CornerRadius = UDim.new(0, 6)

    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1, -20, 0, 18); sl.Position = UDim2.new(0, 10, 0, 38)
    sl.BackgroundTransparency = 1; sl.Font = Enum.Font.GothamMedium; sl.TextSize = 11
    sl.TextXAlignment = Enum.TextXAlignment.Left; sl.TextColor3 = ct.text; sl.Text = "Select Game:"; sl.Parent = gff

    local gsi = Instance.new("TextBox")
    gsi.Size = UDim2.new(1, -20, 0, 28); gsi.Position = UDim2.new(0, 10, 0, 58)
    gsi.BackgroundColor3 = ct.secondary; gsi.BorderSizePixel = 0; gsi.Font = Enum.Font.GothamMedium
    gsi.TextSize = 12; gsi.TextColor3 = Color3.new(1,1,1); gsi.PlaceholderText = "Type game name..."
    gsi.PlaceholderColor3 = Color3.fromRGB(150,150,150); gsi.Text = ""; gsi.ClearTextOnFocus = false; gsi.Parent = gff
    Instance.new("UICorner", gsi).CornerRadius = UDim.new(0, 6)

    local gsl = Instance.new("Frame")
    gsl.Size = UDim2.new(1, -20, 0, 0); gsl.Position = UDim2.new(0, 10, 0, 88)
    gsl.BackgroundColor3 = ct.secondary; gsl.BorderSizePixel = 0; gsl.Visible = false; gsl.ClipsDescendants = true
    gsl.Parent = gff
    Instance.new("UICorner", gsl).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", gsl).SortOrder = Enum.SortOrder.LayoutOrder

    local fc = Instance.new("Frame")
    fc.Name = "FuncContainer"; fc.Size = UDim2.new(1, -20, 0, 0)
    fc.Position = UDim2.new(0, 10, 0, 95); fc.BackgroundTransparency = 1; fc.Parent = gff

    local function rebuildGameFunctions()
        for _, ch in ipairs(fc:GetChildren()) do ch:Destroy() end
        gameFunctionButtons = {}
        if not selectedGame then
            fc.Size = UDim2.new(1, -20, 0, 0); gff.Size = UDim2.new(0, 220, 0, 130); return
        end
        gfh.Text = "🎮 " .. selectedGame.name
        local fy = 0
        for _, func in ipairs(selectedGame.functions) do
            gameFunctionStates[func.name] = gameFunctionStates[func.name] or false
            local fb = Instance.new("TextButton")
            fb.Size = UDim2.new(1, 0, 0, 28); fb.Position = UDim2.new(0, 0, 0, fy)
            fb.BackgroundColor3 = ct.secondary; fb.BorderSizePixel = 0; fb.Font = Enum.Font.GothamMedium
            fb.TextSize = 11; fb.TextColor3 = Color3.new(1,1,1)
            fb.Text = func.name .. ": " .. (gameFunctionStates[func.name] and "ON" or "OFF")
            fb.Parent = fc; Instance.new("UICorner", fb).CornerRadius = UDim.new(0, 6)
            gameFunctionButtons[func.name] = fb
            connect(fb.MouseButton1Click, function()
                playClickSound(); gameFunctionStates[func.name] = not gameFunctionStates[func.name]
                fb.Text = func.name .. ": " .. (gameFunctionStates[func.name] and "ON" or "OFF")
            end)
            fy = fy + 32
        end
        fc.Size = UDim2.new(1, -20, 0, fy); gff.Size = UDim2.new(0, 220, 0, 95 + fy + 15)
    end

    local function updateAutofillList(text)
        for _, ch in ipairs(gsl:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        local matches = text == "" and getGameNames() or findMatchingGames(text)
        gsl.Size = UDim2.new(1, -20, 0, math.min(#matches * 24, 96))
        gsl.Visible = #matches > 0
        for i, name in ipairs(matches) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 24); item.BackgroundColor3 = ct.secondary
            item.BackgroundTransparency = 0.3; item.BorderSizePixel = 0; item.Font = Enum.Font.GothamMedium
            item.TextSize = 11; item.TextColor3 = Color3.new(1,1,1); item.Text = name
            item.LayoutOrder = i; item.Parent = gsl
            connect(item.MouseButton1Click, function()
                playClickSound(); gsi.Text = name; selectedGame = findGameByName(name)
                gsl.Visible = false; rebuildGameFunctions()
            end)
        end
    end

    connect(gsi.Focused, function() updateAutofillList(gsi.Text) end)
    connect(gsi:GetPropertyChangedSignal("Text"), function() updateAutofillList(gsi.Text) end)
    connect(gsi.FocusLost, function(enter)
        task.delay(0.1, function() if not gsi:IsFocused() then gsl.Visible = false end end)
        if enter then local g = findGameByName(gsi.Text); if g then selectedGame = g; rebuildGameFunctions() end end
    end)

    connect(gfb.MouseButton1Click, function() playClickSound(); gff.Visible = not gff.Visible end)
    connect(gfcb.MouseButton1Click, function() playClickSound(); gff.Visible = false end)

    -- Return UI refs
    ui.extraSettingsFrame = esf
    ui.extraSettingsCloseButton = escb
    ui.extraScrollFrame = scroll
    ui.reverseLockButton = rlb
    ui.reverseKeyButton = rkb
    ui.perfectOffsetButton = pob
    ui.npcModeButton = nmb
    ui.predictionButton = prb
    ui.forceCameraButton = fcb
    ui.mouseResistanceButton = mrb
    ui.mouseResistanceSliderBar = mrsb
    ui.mouseResistanceSliderKnob = mrsk
    ui.mouseResistanceLabel = mrl
    ui.lockOnPlusButton = lpb
    ui.lockOnPlusKeyButton = lpkb
    ui.lockCamToggleBtn = lctb
    ui.lockCamToggleModeBtn = lctmb
    ui.lockCamToggleKeyBtn = lctkb
    ui.gameFunctionsButton = gfb
    ui.gameFunctionsFrame = gff
    ui.gameFunctionsCloseButton = gfcb
    return ui
end

return module
