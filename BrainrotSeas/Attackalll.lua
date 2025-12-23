local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatHit = ReplicatedStorage.Remotes.Combat.CombatHit
setsimulationradius(math.huge)

local KillAlive = function()
    local targets = {}
    for _, Alive in pairs(game.Workspace.World.Alive:GetChildren()) do
        local player = Players:GetPlayerFromCharacter(Alive)
        if not player then
            local anyPart = Alive:FindFirstChildOfClass("BasePart") or Alive.PrimaryPart
            if anyPart then
                anyPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
                table.insert(targets, Alive)
            end
        end
    end
    CombatHit:FireServer(targets, 1)
end

KillAlive()
