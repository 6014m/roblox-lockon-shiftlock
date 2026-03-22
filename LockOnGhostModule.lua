-- LockOnGhostModule.lua
-- Stealth lock-on: no GUI, no highlights, no prints, no HttpGet
-- Two modes:
--   1) External load: getgenv().ghostmode = true then load main script
--   2) Self-contained: getgenv().ghost_inline = true then load this file directly
--      (no HttpGet calls at all - targeting logic is baked in)
--
-- Settings (set via getgenv() BEFORE loading):
--   ghost_lockonplus    = false
--   ghost_reverse       = false
--   ghost_prediction    = false
--   ghost_prediction_strength = 0.15
--   ghost_perfect_offset = false
--   ghost_mouse_resistance = false
--   ghost_mouse_resistance_scale = 0.5
--   ghost_force_camera  = false
--   ghost_autoswap      = true
--   ghost_closeswap     = false
--   ghost_visibility    = false
--   ghost_check_health  = true
--   ghost_auto_relock   = false
--   ghost_realistic     = false
--   ghost_height        = 0
--   ghost_range         = 0
--   ghost_shiftlock     = false
--   ghost_lockcam       = false
--   ghost_lockcam_mode  = "Hold"
--   ghost_key_lockon    = "X"
--   ghost_key_swap      = "C"
--   ghost_key_reverse   = "B"
--   ghost_key_lockonplus = "Q"
--   ghost_key_shiftlock = "LeftShift"
--   ghost_key_lockcam   = "F"

local GhostModule = {}

function GhostModule.run()
    local genv = getgenv and getgenv() or _G

    local function gs(key, default)
        local v = genv["ghost_" .. key]
        if v == nil then return default end
        return v
    end

    local lockOnPlusEnabled     = gs("lockonplus", false)
    local reverseLockEnabled    = gs("reverse", false)
    local predictionEnabled     = gs("prediction", false)
    local predictionStrength    = tonumber(gs("prediction_strength", 0.15)) or 0.15
    local perfectOffsetEnabled  = gs("perfect_offset", false)
    local mouseResistanceEnabled = gs("mouse_resistance", false)
    local mouseResistanceScale  = tonumber(gs("mouse_resistance_scale", 0.5)) or 0.5
    local forceCameraMode       = gs("force_camera", false)
    local autoSwapEnabled       = gs("autoswap", true)
    local closeSwapEnabled      = gs("closeswap", false)
    local visibilityCheckEnabled = gs("visibility", false)
    local checkHealthEnabled    = gs("check_health", true)
    local autoRelockEnabled     = gs("auto_relock", false)
    local realisticEnabled      = gs("realistic", false)
    local lockHeightOffset      = tonumber(gs("height", 0)) or 0
    local rangeLimit            = tonumber(gs("range", 0)) or 0
    local ghostShiftlock        = gs("shiftlock", false)
    local lockCamToggleEnabled  = gs("lockcam", false)
    local lockCamToggleMode     = gs("lockcam_mode", "Hold")
    local PERFECT_OFFSET_STUDS  = 2.5

    local function getKey(name, default)
        local v = genv["ghost_key_" .. name]
        if v and Enum.KeyCode[v] then return Enum.KeyCode[v] end
        return Enum.KeyCode[default]
    end

    local keybinds = {
        LockOn     = getKey("lockon", "X"),
        SwapTarget = getKey("swap", "C"),
        ReverseLock = getKey("reverse", "B"),
        LockOnPlus = getKey("lockonplus", "Q"),
        ShiftLock  = getKey("shiftlock", "LeftShift"),
        LockCam    = getKey("lockcam", "F"),
    }

    --==================================================
    -- RANDOM NAMES (avoid identifiable strings)
    --==================================================
    local function rstr(len)
        local t = {}
        for i = 1, (len or math.random(10, 16)) do t[i] = string.char(math.random(97, 122)) end
        return table.concat(t)
    end

    --==================================================
    -- CLEANUP OLD INSTANCE
    --==================================================
    local SCRIPT_KEY = rstr(20)
    local allConnections = {}

    -- Clean any previous ghost instances
    for _, key in ipairs({"LOCKON_GHOST_V1", "LOCKON_CAMERA_V3"}) do
        if genv[key] then
            local old = genv[key]
            if old.Connections then
                for _, c in ipairs(old.Connections) do pcall(function() c:Disconnect() end) end
            end
            if old.Cleanup then pcall(old.Cleanup) end
            if old.Gui then pcall(function() old.Gui:Destroy() end) end
            if old.BindName then pcall(function() game:GetService("RunService"):UnbindFromRenderStep(old.BindName) end) end
            if old.BindNames then
                for _, bn in ipairs(old.BindNames) do
                    pcall(function() game:GetService("RunService"):UnbindFromRenderStep(bn) end)
                end
            end
            genv[key] = nil
        end
    end

    -- Also clean lingering GUIs from normal mode
    pcall(function()
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:find("LockOn") then gui:Destroy() end
        end
    end)
    pcall(function()
        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, gui in ipairs(pg:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:find("LockOn") then gui:Destroy() end
            end
        end
    end)
    pcall(function()
        if gethui then
            for _, gui in ipairs(gethui():GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name:find("LockOn") then gui:Destroy() end
            end
        end
    end)

    task.wait()

    --==================================================
    -- SERVICES
    --==================================================
    local cloneref = cloneref or function(o) return o end
    local Players = cloneref(game:GetService("Players"))
    local UserInputService = cloneref(game:GetService("UserInputService"))
    local RunService = cloneref(game:GetService("RunService"))
    local Workspace = cloneref(game:GetService("Workspace"))

    local localPlayer = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    -- All bind names are random
    local BIND_NAME = rstr()
    local FORCE_BIND = rstr()
    local LP_BIND1 = rstr()
    local LP_BIND2 = rstr()
    local LP_BIND3 = rstr()

    local ScriptData = {
        Connections = allConnections,
        BindName = BIND_NAME,
        BindNames = {FORCE_BIND, LP_BIND1, LP_BIND2, LP_BIND3},
    }
    genv[SCRIPT_KEY] = ScriptData

    if not game:IsLoaded() then game.Loaded:Wait() end

    local function connect(signal, callback)
        local conn = signal:Connect(callback)
        table.insert(allConnections, conn)
        return conn
    end

    connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        camera = workspace.CurrentCamera
    end)

    --==================================================
    -- INLINE TARGETING (no HttpGet)
    --==================================================
    local friendlies = {}

    local function getRootPart(char)
        return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
    end
    local function getHumanoid(char) return char and char:FindFirstChildOfClass("Humanoid") end
    local function isFriendly(plr) return friendlies[plr.UserId] == true end

    local function isInFront(root)
        if not realisticEnabled then return true end
        local cam = camera or workspace.CurrentCamera
        if not cam then return true end
        local toTarget = root.Position - cam.CFrame.Position
        local mag = toTarget.Magnitude
        if mag <= 0.01 then return false end
        local dot = (toTarget / mag):Dot(cam.CFrame.LookVector)
        return dot >= math.cos(math.rad(60))
    end

    local function isAliveAndUnshielded(char)
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        if checkHealthEnabled then
            if hum.Health <= 0 then return false end
            if char:FindFirstChildOfClass("ForceField") then return false end
        end
        return true
    end

    local function isPlayerVisible(plr)
        if not plr then return false end
        local char = plr.Character
        local root = getRootPart(char)
        if not root then return false end
        local cam = camera or workspace.CurrentCamera
        if not cam then return true end
        local origin = cam.CFrame.Position
        local direction = root.Position - origin
        if direction.Magnitude <= 0.01 then return true end
        local ignoreList = {localPlayer.Character}
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignoreList
        while true do
            local result = Workspace:Raycast(origin, direction, params)
            if not result then return true end
            local hit = result.Instance
            if hit:IsDescendantOf(char) then return true end
            if hit:IsA("BasePart") then
                local transparency = hit.Transparency or 0
                local canCollide = hit.CanCollide
                if transparency > 0.4 and not canCollide then
                    table.insert(ignoreList, hit)
                    params.FilterDescendantsInstances = ignoreList
                    local dirUnit = direction.Unit
                    origin = result.Position + dirUnit * 0.05
                    direction = root.Position - origin
                    if direction.Magnitude <= 0.01 then return true end
                else
                    return false
                end
            else
                return false
            end
        end
    end

    local function getBestTarget(excludePlayer)
        local myChar = localPlayer.Character
        local myRoot = getRootPart(myChar)
        if not myRoot then return nil end
        local closestPlr, closestDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer and plr ~= excludePlayer and not isFriendly(plr) then
                local char = plr.Character
                local root = getRootPart(char)
                if root and isInFront(root) and isAliveAndUnshielded(char) then
                    local passVis = true
                    if visibilityCheckEnabled then passVis = isPlayerVisible(plr) end
                    if passVis then
                        local dist = (root.Position - myRoot.Position).Magnitude
                        if (rangeLimit <= 0 or dist <= rangeLimit) and dist < closestDist then
                            closestDist = dist
                            closestPlr = plr
                        end
                    end
                end
            end
        end
        return closestPlr
    end

    --==================================================
    -- STATE
    --==================================================
    local lockedOn, currentTarget, currentTargetType = false, nil, "player"
    local autoRelockPending = false
    local invisibleTime = 0
    local prevCameraType = camera and camera.CameraType or Enum.CameraType.Custom
    local lastLookDir = Vector3.new(0, 0, -1)
    local lastTargetPos = nil
    local reverseLockHeld = false
    local lockOnPlusHeld = false
    local lockCamToggleActive = false
    local shiftLocked = false

    local function isValidTarget(char)
        if not char or not char.Parent then return false end
        local hum, root = getHumanoid(char), getRootPart(char)
        if not hum or not root then return false end
        if checkHealthEnabled then
            if hum.Health <= 0 then return false end
            if char:FindFirstChildOfClass("ForceField") then return false end
            pcall(function()
                if hum:GetState() == Enum.HumanoidStateType.Dead then return false end
            end)
            if hum.WalkSpeed == 0 and hum.Health < hum.MaxHealth * 0.1 then return false end
        end
        return true
    end

    local function findBestTargetCombined(exclude)
        local myRoot = getRootPart(localPlayer.Character)
        if not myRoot then return nil, nil end
        local best, bestType, bestDist = nil, nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer and plr ~= exclude and not isFriendly(plr) then
                local char, root = plr.Character, getRootPart(plr.Character)
                if root and isValidTarget(char) then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if (rangeLimit == 0 or dist <= rangeLimit) and dist < bestDist then
                        local valid = true
                        if realisticEnabled then
                            local dot = (root.Position - myRoot.Position).Unit:Dot(myRoot.CFrame.LookVector)
                            if dot < 0 then valid = false end
                        end
                        if valid then bestDist, best, bestType = dist, plr, "player" end
                    end
                end
            end
        end
        return best, bestType
    end

    --==================================================
    -- GHOST SHIFTLOCK (no GUI, no icon)
    --==================================================
    local function disableGameShiftLock()
        pcall(function() localPlayer.DevEnableMouseLock = false end)
        pcall(function()
            local ps = localPlayer:FindFirstChild("PlayerScripts")
            if ps then
                local pm = ps:FindFirstChild("PlayerModule")
                if pm then
                    local ok, cm = pcall(function() return require(pm:WaitForChild("CameraModule", 1)) end)
                    if ok and cm and cm.activeMouseLockController then
                        pcall(function() cm.activeMouseLockController:SetIsMouseLocked(false) end)
                        pcall(function() cm.activeMouseLockController:EnableMouseLock(false) end)
                    end
                end
            end
        end)
        pcall(function()
            UserSettings():GetService("UserGameSettings").ControlMode = Enum.ControlMode.Classic
        end)
    end

    local function applyShiftLock()
        shiftLocked = true
        disableGameShiftLock()
        local char = localPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = false end
        end
        UserInputService.MouseIconEnabled = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end

    local function releaseShiftLock()
        shiftLocked = false
        local char = localPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end

    local function toggleShiftLock()
        if shiftLocked then releaseShiftLock() else applyShiftLock() end
    end

    if ghostShiftlock then
        connect(RunService.RenderStepped, function()
            if not shiftLocked then return end
            local char = localPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = getRootPart(char)
            if not hum or not root then return end
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
            if hum.PlatformStand or hum.Health <= 0 then return end
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown
                or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Dead then
                return
            end
            local cam = workspace.CurrentCamera
            if not cam then return end
            local look = cam.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0 then
                root.CFrame = CFrame.lookAt(root.Position, root.Position + flat)
            end
        end)
    end

    --==================================================
    -- TARGETING
    --==================================================
    local targetCharConn = nil

    local function unlockCamera(manual)
        if targetCharConn then pcall(function() targetCharConn:Disconnect() end); targetCharConn = nil end
        lockedOn, currentTarget, currentTargetType = false, nil, "player"
        lockCamToggleActive = false
        pcall(function() camera.CameraType = prevCameraType end)
        invisibleTime = 0
        autoRelockPending = not manual and autoRelockEnabled
    end

    local function setNewTarget(target, tType)
        if targetCharConn then pcall(function() targetCharConn:Disconnect() end); targetCharConn = nil end
        currentTarget, currentTargetType, lockedOn, invisibleTime = target, tType or "player", true, 0
        local char = (currentTargetType == "player") and target.Character or target
        local root = getRootPart(char)
        if root and camera then
            local d = (root.Position - camera.CFrame.Position)
            if d.Magnitude > 0 then lastLookDir = d.Unit end
        end
        if currentTargetType == "player" and target then
            targetCharConn = target.CharacterAdded:Connect(function() end)
            table.insert(allConnections, targetCharConn)
        end
    end

    --==================================================
    -- FORCE CAMERA
    --==================================================
    local forceUpdateConnection = nil

    local function forceCameraUpdate()
        if not forceCameraMode or not lockedOn or not currentTarget then return end
        if lockCamToggleEnabled and lockCamToggleActive then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local myChar = localPlayer.Character
        if not myChar then return end
        local myRoot = getRootPart(myChar)
        local targetChar = (currentTargetType == "player") and (currentTarget and currentTarget.Character) or currentTarget
        local targetRoot = getRootPart(targetChar)
        if not myRoot or not targetRoot then return end
        local camPos = cam.CFrame.Position
        local lookPos = targetRoot.Position + Vector3.new(0, lockHeightOffset, 0)
        if predictionEnabled and lastTargetPos then
            lookPos = lookPos + (targetRoot.Position - lastTargetPos) * predictionStrength
        end
        local desiredDir = lookPos - camPos
        local dir = desiredDir.Magnitude > 0.5 and desiredDir.Unit or lastLookDir
        lastLookDir = dir
        if reverseLockEnabled and reverseLockHeld then
            local baseDir = (lookPos - myRoot.Position)
            if baseDir.Magnitude > 0.001 then
                local horiz = Vector3.new(-baseDir.Unit.X, 0, -baseDir.Unit.Z)
                if horiz.Magnitude > 0.001 then dir = (horiz.Unit + Vector3.new(0, baseDir.Unit.Y, 0)).Unit end
            end
        end
        if perfectOffsetEnabled then
            local horiz = Vector3.new(dir.X, 0, dir.Z)
            if horiz.Magnitude > 0.001 then
                local right = horiz.Unit:Cross(Vector3.new(0, 1, 0))
                local off = (lookPos + right * PERFECT_OFFSET_STUDS) - camPos
                if off.Magnitude > 0.5 then dir = off.Unit end
            end
        end
        if mouseResistanceEnabled then
            local currentLook = cam.CFrame.LookVector
            local alpha = (mouseResistanceScale + 1) / 2
            local blendedDir = currentLook:Lerp(dir, alpha)
            if blendedDir.Magnitude > 0.001 then dir = blendedDir.Unit end
        end
        cam.CFrame = CFrame.new(camPos, camPos + dir)
    end

    local function setupForceCameraHooks()
        if forceUpdateConnection then
            pcall(function() forceUpdateConnection:Disconnect() end)
            forceUpdateConnection = nil
        end
        if forceCameraMode then
            pcall(function() RunService:UnbindFromRenderStep(FORCE_BIND) end)
            RunService:BindToRenderStep(FORCE_BIND, Enum.RenderPriority.Camera.Value + 100, forceCameraUpdate)
            forceUpdateConnection = RunService.RenderStepped:Connect(function()
                if forceCameraMode and lockedOn then task.defer(forceCameraUpdate) end
            end)
            table.insert(allConnections, forceUpdateConnection)
        else
            pcall(function() RunService:UnbindFromRenderStep(FORCE_BIND) end)
        end
    end

    setupForceCameraHooks()

    --==================================================
    -- CAMERA UPDATE
    --==================================================
    local function updateCamera(dt)
        local cam = workspace.CurrentCamera
        if forceCameraMode then
            if not cam or not cam.Parent then cam = workspace.CurrentCamera; camera = cam end
            if cam then camera = cam end
        end
        if not cam then cam = workspace.CurrentCamera; camera = cam; return end

        if not lockedOn or not currentTarget then
            invisibleTime, lastTargetPos = 0, nil
            if autoRelockPending and autoRelockEnabled then
                local t, ty = findBestTargetCombined(nil)
                if t then setNewTarget(t, ty) else return end
            else return end
        end

        local myChar = localPlayer.Character
        if not myChar then return end
        local myHum = myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = getRootPart(myChar)
        local targetChar = (currentTargetType == "player") and (currentTarget and currentTarget.Character) or currentTarget
        local targetRoot = getRootPart(targetChar)
        local targetHum = getHumanoid(targetChar)

        if not (myHum and myRoot and targetRoot and targetHum) then
            if autoSwapEnabled then
                local t, ty = findBestTargetCombined(currentTarget)
                if t then setNewTarget(t, ty); return end
            end
            unlockCamera(false); return
        end

        if not isValidTarget(targetChar) then
            if autoSwapEnabled then
                local t, ty = findBestTargetCombined(currentTarget)
                if t then setNewTarget(t, ty); return end
            end
            unlockCamera(false); return
        end

        if visibilityCheckEnabled and currentTargetType == "player" then
            local visible = isPlayerVisible(currentTarget)
            if visible then invisibleTime = 0 else
                invisibleTime = invisibleTime + dt
                if invisibleTime >= 2.5 then
                    if autoSwapEnabled then
                        local t, ty = findBestTargetCombined(currentTarget)
                        if t then setNewTarget(t, ty); return end
                    end
                    unlockCamera(false); return
                end
            end
        end

        if autoSwapEnabled and closeSwapEnabled then
            local b, ty = findBestTargetCombined(nil)
            if b and b ~= currentTarget then setNewTarget(b, ty) end
        end

        if forceCameraMode then
            lastTargetPos = targetRoot.Position
            return
        end

        if lockCamToggleEnabled and lockCamToggleActive then
            lastTargetPos = targetRoot.Position
            pcall(function()
                if cam.CameraSubject ~= myHum then cam.CameraSubject = myHum end
                cam.CameraType = Enum.CameraType.Custom
            end)
            return
        end

        pcall(function()
            if cam.CameraSubject ~= myHum then cam.CameraSubject = myHum end
            cam.CameraType = Enum.CameraType.Custom
        end)

        local camPos = cam.CFrame.Position
        local lookPos = targetRoot.Position + Vector3.new(0, lockHeightOffset, 0)

        if predictionEnabled and lastTargetPos then
            local vel = (targetRoot.Position - lastTargetPos) / math.max(dt, 0.001)
            lookPos = lookPos + vel * predictionStrength
        end
        lastTargetPos = targetRoot.Position

        local desiredDir = lookPos - camPos
        local dir = desiredDir.Magnitude > 0.5 and desiredDir.Unit or lastLookDir
        lastLookDir = dir

        if reverseLockEnabled and reverseLockHeld then
            local baseDir = (lookPos - myRoot.Position)
            if baseDir.Magnitude > 0.001 then
                local horiz = Vector3.new(-baseDir.Unit.X, 0, -baseDir.Unit.Z)
                if horiz.Magnitude > 0.001 then dir = (horiz.Unit + Vector3.new(0, baseDir.Unit.Y, 0)).Unit end
            end
        end

        if perfectOffsetEnabled then
            local horiz = Vector3.new(dir.X, 0, dir.Z)
            if horiz.Magnitude > 0.001 then
                local right = horiz.Unit:Cross(Vector3.new(0, 1, 0))
                local off = (lookPos + right * PERFECT_OFFSET_STUDS) - camPos
                if off.Magnitude > 0.5 then dir = off.Unit end
            end
        end

        if mouseResistanceEnabled then
            local currentLook = cam.CFrame.LookVector
            local alpha = (mouseResistanceScale + 1) / 2
            local blendedDir = currentLook:Lerp(dir, alpha)
            if blendedDir.Magnitude > 0.001 then dir = blendedDir.Unit end
        end

        cam.CFrame = CFrame.new(camPos, camPos + dir)
    end

    RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, updateCamera)

    --==================================================
    -- LOCKON+ CHARACTER ROTATION
    --==================================================
    if lockOnPlusEnabled then
        local lockOnPlusAlign, lockOnPlusAttachment = nil, nil
        local attachName = rstr(12)
        local alignName = rstr(12)

        local function setupConstraint()
            local myChar = localPlayer.Character
            if not myChar then return end
            local myRoot = getRootPart(myChar)
            if not myRoot then return end
            if not lockOnPlusAttachment or not lockOnPlusAttachment.Parent then
                lockOnPlusAttachment = Instance.new("Attachment")
                lockOnPlusAttachment.Name = attachName
                lockOnPlusAttachment.Parent = myRoot
            end
            if not lockOnPlusAlign or not lockOnPlusAlign.Parent then
                lockOnPlusAlign = Instance.new("AlignOrientation")
                lockOnPlusAlign.Name = alignName
                lockOnPlusAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
                lockOnPlusAlign.Attachment0 = lockOnPlusAttachment
                lockOnPlusAlign.RigidityEnabled = true
                lockOnPlusAlign.Responsiveness = 200
                lockOnPlusAlign.MaxTorque = math.huge
                lockOnPlusAlign.Parent = myRoot
            end
        end

        local function updateRotation()
            if not lockOnPlusHeld or not lockedOn or not currentTarget then
                if lockOnPlusAlign then lockOnPlusAlign.Enabled = false end
                return
            end
            local myChar = localPlayer.Character
            if not myChar then return end
            local myRoot = getRootPart(myChar)
            local myHum = myChar:FindFirstChildOfClass("Humanoid")
            if not myRoot or not myHum then return end
            local targetChar = (currentTargetType == "player") and (currentTarget and currentTarget.Character) or currentTarget
            local targetRoot = getRootPart(targetChar)
            if not targetRoot then return end
            local dir = (targetRoot.Position - myRoot.Position)
            local flat = Vector3.new(dir.X, 0, dir.Z)
            if flat.Magnitude < 0.1 then return end
            myHum.AutoRotate = false
            local _, yAngle, _ = CFrame.lookAt(Vector3.zero, flat):ToEulerAnglesYXZ()
            myRoot.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, yAngle, 0)
            setupConstraint()
            if lockOnPlusAlign then
                lockOnPlusAlign.Enabled = true
                lockOnPlusAlign.CFrame = CFrame.lookAt(Vector3.zero, flat)
            end
        end

        RunService:BindToRenderStep(LP_BIND1, Enum.RenderPriority.Camera.Value - 1, updateRotation)
        RunService:BindToRenderStep(LP_BIND2, Enum.RenderPriority.Camera.Value + 200, updateRotation)
        RunService:BindToRenderStep(LP_BIND3, Enum.RenderPriority.Last.Value, updateRotation)

        connect(RunService.RenderStepped, function()
            if lockOnPlusHeld and lockedOn and currentTarget then task.defer(updateRotation) end
        end)
        connect(RunService.Heartbeat, function()
            if lockOnPlusHeld and lockedOn and currentTarget then updateRotation() end
        end)
        connect(RunService.Stepped, function()
            if lockOnPlusHeld and lockedOn and currentTarget then
                setupConstraint()
                if lockOnPlusAlign then
                    local myRoot2 = getRootPart(localPlayer.Character)
                    local tc = (currentTargetType == "player") and (currentTarget and currentTarget.Character) or currentTarget
                    local tr = getRootPart(tc)
                    if myRoot2 and tr then
                        local d = (tr.Position - myRoot2.Position)
                        local f = Vector3.new(d.X, 0, d.Z)
                        if f.Magnitude > 0.1 then
                            lockOnPlusAlign.Enabled = true
                            lockOnPlusAlign.CFrame = CFrame.lookAt(Vector3.zero, f)
                        end
                    end
                end
            end
        end)
    end

    --==================================================
    -- CLEANUP
    --==================================================
    local function fullCleanup()
        forceCameraMode = false
        for _, conn in ipairs(allConnections) do pcall(function() conn:Disconnect() end) end
        allConnections = {}
        pcall(function() RunService:UnbindFromRenderStep(FORCE_BIND) end)
        pcall(function() RunService:UnbindFromRenderStep(BIND_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(LP_BIND1) end)
        pcall(function() RunService:UnbindFromRenderStep(LP_BIND2) end)
        pcall(function() RunService:UnbindFromRenderStep(LP_BIND3) end)
        if forceUpdateConnection then pcall(function() forceUpdateConnection:Disconnect() end) end
        lockedOn, currentTarget = false, nil
        pcall(function() if camera then camera.CameraType = prevCameraType end end)
        if shiftLocked then releaseShiftLock() end
        for id in pairs(friendlies) do friendlies[id] = nil end
    end

    ScriptData.Cleanup = fullCleanup

    connect(localPlayer.Chatted, function(msg)
        if msg:lower() == "/e stop" then
            genv[SCRIPT_KEY] = nil
            fullCleanup()
        end
    end)

    --==================================================
    -- INPUT
    --==================================================
    connect(UserInputService.InputBegan, function(input, gpe)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local isTyping = UserInputService:GetFocusedTextBox() ~= nil
        local kc = input.KeyCode

        if ghostShiftlock and kc == keybinds.ShiftLock and not gpe and not isTyping then
            toggleShiftLock()
        end

        if gpe or isTyping then return end

        if kc == keybinds.ReverseLock and reverseLockEnabled then reverseLockHeld = true end
        if kc == keybinds.LockOnPlus and lockOnPlusEnabled then lockOnPlusHeld = true end
        if kc == keybinds.LockCam and lockCamToggleEnabled then
            if lockCamToggleMode == "Hold" then lockCamToggleActive = true
            else lockCamToggleActive = not lockCamToggleActive end
        end

        if kc == keybinds.LockOn then
            if lockedOn then
                if camera then lastLookDir = camera.CFrame.LookVector end
                unlockCamera(true)
            else
                local t, ty = findBestTargetCombined(nil)
                if t then setNewTarget(t, ty) end
            end
        end

        if kc == keybinds.SwapTarget and lockedOn and currentTarget then
            local t, ty = findBestTargetCombined(currentTarget)
            if t then setNewTarget(t, ty) end
        end
    end)

    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == keybinds.ReverseLock then reverseLockHeld = false end
            if input.KeyCode == keybinds.LockCam and lockCamToggleEnabled and lockCamToggleMode == "Hold" then
                lockCamToggleActive = false
            end
            if input.KeyCode == keybinds.LockOnPlus then
                lockOnPlusHeld = false
                local myChar = localPlayer.Character
                if myChar then
                    local myHum = myChar:FindFirstChildOfClass("Humanoid")
                    if myHum then myHum.AutoRotate = true end
                end
            end
        end
    end)

    --==================================================
    -- CHARACTER RESPAWN
    --==================================================
    local function onCharacterAdded(char)
        pcall(function()
            char:WaitForChild("Humanoid", 10)
            char:WaitForChild("HumanoidRootPart", 10)
        end)
        if lockedOn then lockedOn, currentTarget, currentTargetType = false, nil, "player" end
        camera = workspace.CurrentCamera
        task.delay(0.5, function()
            if shiftLocked then
                shiftLocked = false
                applyShiftLock()
            end
        end)
    end

    if localPlayer.Character then task.spawn(function() onCharacterAdded(localPlayer.Character) end) end
    connect(localPlayer.CharacterAdded, onCharacterAdded)
end

-- Self-contained mode: if this file is executed directly
if getgenv and getgenv().ghost_inline then
    GhostModule.run()
end

return GhostModule
