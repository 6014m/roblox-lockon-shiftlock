-- LockOnSaveLoadModule.lua
-- Handles saving and loading all Lock-On settings to/from file

local SaveLoad = {}
SaveLoad.__index = SaveLoad

local HttpService = game:GetService("HttpService")

local SAVE_KEY = "LockOnCameraSettings_v4"
local LEGACY_KEYS = {"LockOnCameraSettings_v3", "LockOnCameraSettings_v2"}

function SaveLoad.new()
    local self = setmetatable({}, SaveLoad)
    return self
end

--==================================================
-- SAVE
--==================================================

function SaveLoad:Save(state)
    local success = pcall(function()
        local data = {
            -- Theme
            theme = state.currentThemeName,

            -- Main page
            autoSwapEnabled = state.autoSwapEnabled,
            closeSwapEnabled = state.closeSwapEnabled,
            visibilityCheckEnabled = state.visibilityCheckEnabled,
            checkHealthEnabled = state.checkHealthEnabled,
            autoRelockEnabled = state.autoRelockEnabled,
            realisticEnabled = state.realisticEnabled,
            rangeLimit = state.rangeLimit,
            lockHeightOffset = state.lockHeightOffset,

            -- Visual page
            highlightEnabled = state.highlightEnabled,
            highlightSecondEnabled = state.highlightSecondEnabled,
            selfFadeEnabled = state.selfFadeEnabled,
            customShiftlockEnabled = state.customShiftlockEnabled,
            shiftlockAutoEnable = state.shiftlockAutoEnable,
            shiftlockKeyEnabled = state.shiftlockKeyEnabled,

            -- Target page
            mouseTargetMode = state.mouseTargetMode,

            -- Extra settings
            reverseLockEnabled = state.reverseLockEnabled,
            perfectOffsetEnabled = state.perfectOffsetEnabled,
            npcModeEnabled = state.npcModeEnabled,
            predictionEnabled = state.predictionEnabled,
            forceCameraMode = state.forceCameraMode,
            mouseResistanceEnabled = state.mouseResistanceEnabled,
            mouseResistanceScale = state.mouseResistanceScale,
            lockOnPlusEnabled = state.lockOnPlusEnabled,
            lockCamToggleEnabled = state.lockCamToggleEnabled,
            lockCamToggleMode = state.lockCamToggleMode,

            -- Keybinds (stored as enum name strings)
            kb_LockOn = state.keybinds.LockOn and state.keybinds.LockOn.Name,
            kb_SwapTarget = state.keybinds.SwapTarget and state.keybinds.SwapTarget.Name,
            kb_ReverseLock = state.keybinds.ReverseLock and state.keybinds.ReverseLock.Name,
            kb_ShiftLock = state.keybinds.ShiftLock and state.keybinds.ShiftLock.Name,
            kb_LockOnPlus = state.keybinds.LockOnPlus and state.keybinds.LockOnPlus.Name,
            kb_LockCamToggle = state.lockCamToggleKeybind and state.lockCamToggleKeybind.Name,
        }

        if writefile then
            writefile(SAVE_KEY .. ".json", HttpService:JSONEncode(data))
        end
    end)
    return success
end

--==================================================
-- LOAD
--==================================================

function SaveLoad:Load()
    local success, data = pcall(function()
        if not readfile or not isfile then return nil end
        -- Try current version first, then fall back to legacy
        for _, key in ipairs({SAVE_KEY, unpack(LEGACY_KEYS)}) do
            if isfile(key .. ".json") then
                return HttpService:JSONDecode(readfile(key .. ".json"))
            end
        end
        return nil
    end)
    return success and data or nil
end

--==================================================
-- APPLY
--==================================================

-- Apply loaded data to a state table. Returns the modified state.
-- `state` should be a table with all the setting fields + keybinds sub-table.
-- `THEMES` is the themes table to validate theme name against.
function SaveLoad:Apply(data, state, THEMES)
    if not data then return false end

    -- Theme
    if data.theme and THEMES[data.theme] then
        state.currentThemeName = data.theme
        state.currentTheme = THEMES[data.theme]
    end

    -- Booleans (default to false if missing)
    local boolFields = {
        "autoSwapEnabled", "closeSwapEnabled", "visibilityCheckEnabled",
        "checkHealthEnabled", "autoRelockEnabled", "realisticEnabled",
        "reverseLockEnabled", "perfectOffsetEnabled", "mouseTargetMode",
        "npcModeEnabled", "predictionEnabled", "forceCameraMode",
        "customShiftlockEnabled", "shiftlockAutoEnable",
        "mouseResistanceEnabled", "lockOnPlusEnabled", "lockCamToggleEnabled",
        "highlightEnabled", "highlightSecondEnabled", "selfFadeEnabled",
    }
    for _, field in ipairs(boolFields) do
        state[field] = (data[field] == true)
    end

    -- Special case: shiftlockKeyEnabled defaults to true
    state.shiftlockKeyEnabled = (data.shiftlockKeyEnabled ~= false)

    -- Numbers
    state.rangeLimit = tonumber(data.rangeLimit) or 0
    state.lockHeightOffset = tonumber(data.lockHeightOffset) or 0
    state.mouseResistanceScale = tonumber(data.mouseResistanceScale) or 0.3

    -- LockCamToggle mode
    if data.lockCamToggleMode == "Hold" or data.lockCamToggleMode == "Toggle" then
        state.lockCamToggleMode = data.lockCamToggleMode
    end

    -- Keybinds (new format: kb_*)
    local keybindMap = {
        kb_LockOn = "LockOn",
        kb_SwapTarget = "SwapTarget",
        kb_ReverseLock = "ReverseLock",
        kb_ShiftLock = "ShiftLock",
        kb_LockOnPlus = "LockOnPlus",
    }
    for dataKey, bindName in pairs(keybindMap) do
        if data[dataKey] and Enum.KeyCode[data[dataKey]] then
            state.keybinds[bindName] = Enum.KeyCode[data[dataKey]]
        end
    end
    if data.kb_LockCamToggle and Enum.KeyCode[data.kb_LockCamToggle] then
        state.lockCamToggleKeybind = Enum.KeyCode[data.kb_LockCamToggle]
    end

    -- Legacy keybind formats
    if data.keybindLockOn and Enum.KeyCode[data.keybindLockOn] then
        state.keybinds.LockOn = Enum.KeyCode[data.keybindLockOn]
    end
    if data.keybindSwapTarget and Enum.KeyCode[data.keybindSwapTarget] then
        state.keybinds.SwapTarget = Enum.KeyCode[data.keybindSwapTarget]
    end
    if data.keybindReverseLock and Enum.KeyCode[data.keybindReverseLock] then
        state.keybinds.ReverseLock = Enum.KeyCode[data.keybindReverseLock]
    end
    if data.keybinds then
        for k, v in pairs(data.keybinds) do
            if Enum.KeyCode[v] then state.keybinds[k] = Enum.KeyCode[v] end
        end
    end

    return true
end

return SaveLoad
