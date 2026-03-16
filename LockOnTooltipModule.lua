-- LockOnTooltipModule.lua
-- Stores all tooltip/description text for Lock-On settings
-- Used by the "?" toggle button in the main UI

local Tooltips = {}

--==================================================
-- MAIN PAGE TOOLTIPS
--==================================================

Tooltips.Main = {
    Autoswap = "Automatically switches to the nearest valid target when your current target dies, resets, or leaves the game. Prevents you from being left without a lock after a kill.",

    CloseSwap = "When swapping targets (with the swap key), always picks the closest player to you instead of cycling through all available targets. Useful in group fights where you want fast reactions to whoever is nearest.",

    VisibilityCheck = "Checks if your current target is visible (not behind a wall or object). If they become fully hidden for a short time, the lock automatically swaps to a visible target. Uses raycasting from your camera to the target's torso.",

    CheckHealth = "Skips targets that are already dead (0 HP) or have a ForceField active (spawn protection). Prevents you from wasting lock-on on players who can't be damaged.",

    AutoRelock = "After your current target dies or becomes invalid, automatically locks onto the next closest valid target without needing to press the lock-on key again. Works well with Autoswap for seamless target transitions.",

    Realistic = "Only allows locking onto targets that are in front of your character (within a ~120 degree cone). Prevents locking onto players behind you, making targeting feel more natural and preventing sudden 180-degree camera snaps.",

    Height = "Adjusts the vertical aim offset of the camera lock. Positive values aim higher above the target (good for headshots or overhead angles), negative values aim lower. Range: -5 to +5 studs. Default is 0 (center mass).",

    Range = "Sets the maximum distance (in studs) at which you can lock onto targets. Players further than this distance are ignored. Set to 0 for unlimited range. Useful for close-range combat games where you don't want to lock onto faraway players.",
}

--==================================================
-- VISUAL PAGE TOOLTIPS
--==================================================

Tooltips.Visual = {
    Highlight = "Adds a glowing highlight effect around your locked target, making them easier to see through visual clutter, particles, and dark environments. The highlight color matches your current theme.",

    HighlightSecond = "Also highlights the second-closest target with a dimmer glow. Lets you see who you'll swap to next if you press the swap key, giving you better awareness in multi-player fights.",

    SelfFade = "Makes your own character semi-transparent while locked on. Reduces visual obstruction from your own model, especially useful in third-person when your character blocks the view of your target.",

    CustomShiftlock = "Replaces the default Roblox shift lock with a custom implementation. Your character always faces the direction your camera is pointing, giving you full 360-degree movement while staying aimed at your target. Works in games that disable the built-in shift lock.",

    ShiftlockKey = "Change which key activates/deactivates the custom shiftlock. Click the button, then press any key to rebind it. Default: LeftShift.",

    ShiftlockKeyToggle = "Enable or disable the shiftlock keybind entirely. When disabled, you can still toggle shiftlock through the UI button, but the keyboard shortcut won't work. Useful if the keybind conflicts with game controls.",

    ShiftlockAutoEnable = "Automatically enables custom shiftlock as soon as the script loads, without needing to press the key or click the button. Saves a step if you always want shiftlock active.",
}

--==================================================
-- TARGET PAGE TOOLTIPS
--==================================================

Tooltips.Target = {
    LockOnKey = "The key that toggles lock-on. Press once to lock onto the nearest target, press again to unlock. Click this button then press any key to rebind. Default: X.",

    SwapKey = "The key that cycles to the next target while locked on. Each press picks the next closest valid target. Click this button then press any key to rebind. Default: C.",

    MouseTarget = "Instead of locking onto the closest player to your character, locks onto the player closest to your mouse cursor on screen. Better for crowded situations where you need to pick a specific target out of a group.",

    FriendlyAll = "Toggle ALL players in the server as friendly at once. When ON, every player is marked as friendly and cannot be locked onto. Press again to remove everyone from the friendlies list so they become targetable again. New players who join will not be automatically added.",
}

--==================================================
-- EXTRA SETTINGS TOOLTIPS
--==================================================

Tooltips.Extra = {
    ReverseLock = "Flips the camera lock 180 degrees so you face AWAY from your target instead of toward them. Useful for retreating while keeping track of an enemy, or for specific combat techs that require backpedaling.",

    ReverseKey = "The key you hold to temporarily activate reverse lock. Only works while held down — releasing snaps back to normal lock. Click to rebind. Default: B.",

    PerfectOffset = "Offsets your character's position slightly to the side of the target instead of directly facing them. Creates a more cinematic third-person angle and can help with visibility in close-range fights. Offset distance: 2.5 studs.",

    NPCMode = "Allows locking onto NPCs (non-player characters) in addition to players. The script will search for Humanoid models in the workspace that aren't controlled by any player. Required for PvE games or boss fights.",

    Prediction = "Leads your aim slightly ahead of a moving target based on their current velocity. Compensates for target movement so your camera points where they're going, not where they are. Strength: 15% of target velocity.",

    ForceCamera = "Overrides the game's camera scripts entirely and takes full control of camera rotation. Use this in games that have custom camera systems that fight with the lock-on (e.g., tower defense games, cutscene-heavy games). May cause camera jitter in some games if their scripts constantly reset the camera.",

    MouseResistance = "Controls how much the camera resists being pulled away from the target by your mouse. At 100%, the lock is rigid and your mouse can't move the camera at all. At 0%, you have full mouse freedom while locked. Negative values actually push the camera away from the target. Slider range: -100% to +100%.",

    LockOnPlus = "Rotates your character's body to face the locked target while keeping your camera free to look around. Your movement direction aligns toward the target. Useful in fighting games where your character needs to face the opponent for attacks to connect, even if your camera is angled differently.",

    LockOnPlusKey = "The key you hold to activate LockOn+ rotation. Only rotates your character while this key is held. Release to return to normal movement direction. Click to rebind. Default: Q.",

    LockCamToggle = "Keeps track of your locked target (maintains the lock indicator and targeting) but does NOT force your camera to follow them. Lets you look around freely while still having a target selected. Good for situational awareness — you know who you're targeting without the camera being pulled.",

    LockCamToggleMode = "Switch between Hold and Toggle modes for LockCamToggle. Hold: only active while the key is held down. Toggle: press once to activate, press again to deactivate. Choose based on your play style.",

    LockCamToggleKey = "The key for activating LockCamToggle. Click to rebind. Default: F.",

    GameFunctions = "Opens the game-specific functions panel. Some games have special features (like auto-timing abilities based on target HP). Select your game from the dropdown to see available functions. Currently supported: JJS (Nanami Perfect Special).",
}

--==================================================
-- INFO TOGGLE TOOLTIP
--==================================================

Tooltips.InfoToggle = "Toggle detailed tooltips on/off. When enabled, hover over any setting to see a full explanation of what it does, how it works, and when to use it."

--==================================================
-- LOOKUP FUNCTION
--==================================================

-- Get tooltip by category and key, e.g. Tooltips:Get("Main", "Autoswap")
function Tooltips:Get(category, key)
    if self[category] and self[category][key] then
        return self[category][key]
    end
    return nil
end

-- Get all tooltips as a flat table (for migration)
function Tooltips:GetFlat()
    local flat = {}
    for cat, entries in pairs(self) do
        if type(entries) == "table" and cat ~= "__index" then
            for key, text in pairs(entries) do
                if type(text) == "string" then
                    flat[key] = text
                end
            end
        end
    end
    flat["InfoToggle"] = self.InfoToggle
    return flat
end

return Tooltips
