-- LockOnGameFunctionsModule.lua
-- Stores all game-specific function definitions and handles game lookup/matching

local GameFunctions = {}
GameFunctions.__index = GameFunctions

--==================================================
-- AVAILABLE GAMES DATABASE
--==================================================

local AVAILABLE_GAMES = {
    {
        name = "JJS",
        ids = {"3508322461"},
        functions = {
            {
                name = "Nanami Perfect Special",
                description = "Automatically times Nanami's R special ability based on the target's current HP percentage. Only activates when within 27 studs of the locked target. Adjusts timing window depending on HP threshold: 0.63s delay at 80-100% HP, 0.55s delay below 80% HP. Fires through ReplicatedStorage Knit service.",
                enabled = false,
                execute = function(target)
                    if not target then return end
                    local targetChar = target.Character
                    if not targetChar then return end

                    -- Check distance (must be within 27 studs)
                    local myChar = game.Players.LocalPlayer.Character
                    if not myChar then return end
                    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if not myRoot or not targetRoot then return end

                    local distance = (myRoot.Position - targetRoot.Position).Magnitude
                    if distance > 27 then return end -- Too far away

                    local hum = targetChar:FindFirstChildOfClass("Humanoid")
                    if not hum then return end

                    local hp = hum.Health
                    local maxHp = hum.MaxHealth
                    local hpPercent = (hp / maxHp) * 100

                    -- Determine wait time based on health
                    local waitTime = 0.63 -- Default for 100-80%
                    if hpPercent < 80 then
                        waitTime = 0.55 -- 80-0%
                    end

                    task.delay(waitTime, function()
                        pcall(function()
                            local args = { targetChar }
                            game:GetService("ReplicatedStorage").Knit.Knit.Services.NanamiService.RE.RightActivated:FireServer(unpack(args))
                        end)
                    end)
                end
            }
        }
    },
    -- Add more games here:
    -- {
    --     name = "Game Name",
    --     ids = {"id1", "id2"},
    --     functions = {
    --         {
    --             name = "Function Name",
    --             description = "What this function does",
    --             enabled = false,
    --             execute = function(target) ... end
    --         }
    --     }
    -- },
}

--==================================================
-- CONSTRUCTOR
--==================================================

function GameFunctions.new()
    local self = setmetatable({}, GameFunctions)
    self.selectedGame = nil
    self.functionStates = {} -- Track enabled/disabled state of each function
    return self
end

--==================================================
-- GAME LOOKUP
--==================================================

-- Get list of all game names (for autofill dropdown)
function GameFunctions:GetGameNames()
    local names = {}
    for _, game in ipairs(AVAILABLE_GAMES) do
        table.insert(names, game.name)
    end
    return names
end

-- Find a game by exact name (case-insensitive)
function GameFunctions:FindGameByName(name)
    for _, game in ipairs(AVAILABLE_GAMES) do
        if game.name:lower() == name:lower() then
            return game
        end
    end
    return nil
end

-- Find games matching a partial name (for autofill search)
function GameFunctions:FindMatchingGames(partial)
    local matches = {}
    partial = partial:lower()
    for _, game in ipairs(AVAILABLE_GAMES) do
        if game.name:lower():sub(1, #partial) == partial then
            table.insert(matches, game.name)
        end
    end
    return matches
end

-- Auto-detect game by place ID
function GameFunctions:DetectGame()
    local placeId = tostring(game.PlaceId)
    for _, g in ipairs(AVAILABLE_GAMES) do
        for _, id in ipairs(g.ids) do
            if id == placeId then
                return g
            end
        end
    end
    return nil
end

--==================================================
-- GAME SELECTION
--==================================================

function GameFunctions:SelectGame(name)
    self.selectedGame = self:FindGameByName(name)
    return self.selectedGame
end

function GameFunctions:GetSelectedGame()
    return self.selectedGame
end

--==================================================
-- FUNCTION STATE MANAGEMENT
--==================================================

function GameFunctions:GetFunctionState(funcName)
    return self.functionStates[funcName] or false
end

function GameFunctions:SetFunctionState(funcName, enabled)
    self.functionStates[funcName] = enabled
end

function GameFunctions:ToggleFunctionState(funcName)
    self.functionStates[funcName] = not self.functionStates[funcName]
    return self.functionStates[funcName]
end

--==================================================
-- EXECUTION
--==================================================

-- Execute all enabled functions for the selected game against a target
function GameFunctions:ExecuteEnabled(target)
    if not self.selectedGame or not target then return end
    for _, func in ipairs(self.selectedGame.functions) do
        if self.functionStates[func.name] then
            pcall(func.execute, target)
        end
    end
end

-- Get the raw AVAILABLE_GAMES table (for external use)
function GameFunctions:GetAllGames()
    return AVAILABLE_GAMES
end

return GameFunctions
