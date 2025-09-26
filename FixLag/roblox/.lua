--[[
  DucLuongg | free fixlag — FULL EDITION (UltraLow mặc định, FORCE)
  - Mặc định: UltraLow (siêu mượt)
  - FORCE_PRESET = true => luôn áp UltraLow, bỏ auto-detect
  - No UI by default, optional FPS label available via config
  - Notifications title = "free fixlag"
--]]

-- =========================
-- CONFIG (SỬA Ở ĐẦU FILE)
-- =========================
local CHOSEN_PRESET = "UltraLow"   -- "Default" / "Low" / "Medium" / "UltraLow"
local FORCE_PRESET = true          -- true = always apply CHOSEN_PRESET (skip auto-detect)
local CUSTOM_FPS = nil             -- number to force FPS (overrides preset FPS). nil = use preset
local AUTO_THRESHOLD = 40          -- if avg FPS < this -> auto apply UltraLow (ignored if FORCE_PRESET = true)
local SILENT_MODE = false          -- true = suppress notifications
local CONSOLE_LOGS = false         -- true = warn() logs for debugging
local SHOW_FPS_LABEL = false       -- true = display small FPS label on screen
local FPS_UPDATE_INTERVAL = 0.5    -- seconds for FPS label updates
-- =========================

-- ===== GLOBAL DEFAULTS & SAFETY
if not _G.Ignore then _G.Ignore = {} end
if _G.SendNotifications == nil then _G.SendNotifications = (not SILENT_MODE) end
if _G.ConsoleLogs == nil then _G.ConsoleLogs = CONSOLE_LOGS end

-- ===== SERVICES
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ME = Players.LocalPlayer
local CanBeEnabled = {"ParticleEmitter","Trail","Smoke","Fire","Sparkles"}

-- ===== HELPERS
local function safe_pcall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and _G.ConsoleLogs then warn("free fixlag | pcall error: ".. tostring(err)) end
    return ok, err
end

local function IsDescendantInIgnore(inst)
    for _,v in pairs(_G.Ignore or {}) do
        if v and inst:IsDescendantOf(v) then return true end
    end
    return false
end

local function IsPartOfAnyCharacter(inst)
    for _,plr in pairs(Players:GetPlayers()) do
        if plr.Character and inst:IsDescendantOf(plr.Character) then return true end
    end
    return false
end

-- =========================
-- PRESETS (DETAILED)
-- =========================
_G.Presets = {
    Default = {
        Name = "Default",
        FPS = 144,
        Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true },
        Meshes = { NoMesh = false, NoTexture = false, Destroy = false },
        Images = { Invisible = true, Destroy = false, LowDetail = false },
        Explosions = { Smaller = true, Invisible = false, Destroy = false },
        Particles = { Invisible = true, Destroy = false },
        TextLabels = { LowerQuality = false, Invisible = false, Destroy = false },
        MeshParts = { LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false },
        Other = {
            ["FPS Cap"] = true, ["FPS Value"] = 144,
            ["No Camera Effects"] = true, ["No Clothes"] = false,
            ["Low Water Graphics"] = true, ["No Shadows"] = true,
            ["Low Rendering"] = true, ["Low Quality Parts"] = true,
            ["Low Quality Models"] = true, ["Reset Materials"] = true,
            ["Lower Quality MeshParts"] = true, ClearNilInstances = false
        }
    },

    Low = {
        Name = "Low",
        FPS = 120,
        Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true },
        Meshes = { NoMesh = true, NoTexture = true, Destroy = false },
        Images = { Invisible = true, Destroy = false, LowDetail = true },
        Explosions = { Smaller = true, Invisible = true, Destroy = false },
        Particles = { Invisible = true, Destroy = true },
        TextLabels = { LowerQuality = true, Invisible = true, Destroy = false },
        MeshParts = { LowerQuality = true, Invisible = true, NoTexture = true, NoMesh = false, Destroy = false },
        Other = {
            ["FPS Cap"] = true, ["FPS Value"] = 120,
            ["No Camera Effects"] = true, ["No Clothes"] = true,
            ["Low Water Graphics"] = true, ["No Shadows"] = true,
            ["Low Rendering"] = true, ["Low Quality Parts"] = true,
            ["Low Quality Models"] = true, ["Reset Materials"] = true,
            ["Lower Quality MeshParts"] = true, ClearNilInstances = false
        }
    },

    Medium = {
        Name = "Medium",
        FPS = 180,
        Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true },
        Meshes = { NoMesh = false, NoTexture = true, Destroy = false },
        Images = { Invisible = false, Destroy = false, LowDetail = false },
        Explosions = { Smaller = true, Invisible = false, Destroy = false },
        Particles = { Invisible = true, Destroy = false },
        TextLabels = { LowerQuality = false, Invisible = false, Destroy = false },
        MeshParts = { LowerQuality = true, Invisible = false, NoTexture = true, NoMesh = false, Destroy = false },
        Other = {
            ["FPS Cap"] = true, ["FPS Value"] = 180,
            ["No Camera Effects"] = true, ["No Clothes"] = false,
            ["Low Water Graphics"] = false, ["No Shadows"] = false,
            ["Low Rendering"] = false, ["Low Quality Parts"] = true,
            ["Low Quality Models"] = false, ["Reset Materials"] = false,
            ["Lower Quality MeshParts"] = true, ClearNilInstances = false
        }
    },

    UltraLow = {
        Name = "UltraLow",
        FPS = 999,
        Players = { ["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true },
        Meshes = { NoMesh = true, NoTexture = true, Destroy = true },
        Images = { Invisible = true, Destroy = true, LowDetail = true },
        Explosions = { Smaller = true, Invisible = true, Destroy = true },
        Particles = { Invisible = true, Destroy = true },
        TextLabels = { LowerQuality = true, Invisible = true, Destroy = true },
        MeshParts = { LowerQuality = true, Invisible = true, NoTexture = true, NoMesh = true, Destroy = true },
        Other = {
            ["FPS Cap"] = true, ["FPS Value"] = 999,
            ["No Camera Effects"] = true, ["No Clothes"] = true,
            ["Low Water Graphics"] = true, ["No Shadows"] = true,
            ["Low Rendering"] = true, ["Low Quality Parts"] = true,
            ["Low Quality Models"] = true, ["Reset Materials"] = true,
            ["Lower Quality MeshParts"] = true, ClearNilInstances = true
        }
    }
}

-- Apply preset to _G.Settings
local function ApplyPresetByName(name)
    local p = _G.Presets and _G.Presets[name]
    if not p then
        if _G.ConsoleLogs then warn("free fixlag | preset not found: ".. tostring(name)) end
        return false
    end
    _G.Settings = _G.Settings or {}
    _G.Settings.Players = p.Players
    _G.Settings.Meshes = p.Meshes
    _G.Settings.Images = p.Images
    _G.Settings.Explosions = p.Explosions
    _G.Settings.Particles = p.Particles
    _G.Settings.TextLabels = p.TextLabels
    _G.Settings.MeshParts = p.MeshParts
    _G.Settings.FPS = p.FPS
    _G.Settings.Other = p.Other
    if _G.ConsoleLogs then warn("free fixlag | applied preset: ".. tostring(name)) end
    return true
end

-- =========================
-- INSTANCE HANDLER (VERY DETAILED)
-- =========================
local function HandleInstance(inst)
    if not inst or not inst.Parent then return end
    if inst:IsDescendantOf(Players) then return end
    if IsDescendantInIgnore(inst) then return end

    -- if configured to ignore other players' characters
    if _G.Settings and _G.Settings.Players and _G.Settings.Players["Ignore Others"] then
        if IsPartOfAnyCharacter(inst) then return end
    end

    -- DataModelMesh / SpecialMesh
    if inst:IsA("DataModelMesh") then
        if inst:IsA("SpecialMesh") then
            if _G.Settings.Meshes and _G.Settings.Meshes.NoMesh then safe_pcall(function() inst.MeshId = "" end) end
            if _G.Settings.Meshes and _G.Settings.Meshes.NoTexture then safe_pcall(function() inst.TextureId = "" end) end
        end
        if _G.Settings.Meshes and _G.Settings.Meshes.Destroy then safe_pcall(function() inst:Destroy() end) end

    -- FaceInstance
    elseif inst:IsA("FaceInstance") then
        if _G.Settings.Images and _G.Settings.Images.Invisible then safe_pcall(function() inst.Transparency = 1; inst.Shiny = 1 end) end
        if _G.Settings.Images and _G.Settings.Images.LowDetail then safe_pcall(function() inst.Shiny = 1 end) end
        if _G.Settings.Images and _G.Settings.Images.Destroy then safe_pcall(function() inst:Destroy() end) end

    -- ShirtGraphic
    elseif inst:IsA("ShirtGraphic") then
        if _G.Settings.Images and _G.Settings.Images.Invisible then safe_pcall(function() inst.Graphic = "" end) end
        if _G.Settings.Images and _G.Settings.Images.Destroy then safe_pcall(function() inst:Destroy() end) end

    -- Particles / Trails / Smoke / Fire / Sparkles
    elseif table.find(CanBeEnabled, inst.ClassName) then
        if (_G.Settings.Particles and _G.Settings.Particles.Invisible) or (_G.Settings.Other and _G.Settings.Other["Invisible Particles"]) then
            safe_pcall(function() inst.Enabled = false end)
        end
        if (_G.Settings.Particles and _G.Settings.Particles.Destroy) or (_G.Settings.Other and _G.Settings.Other["No Particles"]) then
            safe_pcall(function() inst:Destroy() end)
        end

    -- PostEffect (bloom/blur/color correction)
    elseif inst:IsA("PostEffect") then
        if _G.Settings.Other and _G.Settings.Other["No Camera Effects"] then safe_pcall(function() inst.Enabled = false end) end

    -- Explosion
    elseif inst:IsA("Explosion") then
        if _G.Settings.Explosions and _G.Settings.Explosions.Smaller then
            safe_pcall(function() inst.BlastPressure = 1; inst.BlastRadius = 1 end)
        end
        if _G.Settings.Explosions and _G.Settings.Explosions.Invisible then safe_pcall(function() inst.Visible = false end) end
        if _G.Settings.Explosions and _G.Settings.Explosions.Destroy then safe_pcall(function() inst:Destroy() end) end

    -- Clothing / SurfaceAppearance / BaseWrap
    elseif inst:IsA("Clothing") or inst:IsA("SurfaceAppearance") or inst:IsA("BaseWrap") then
        if _G.Settings.Other and _G.Settings.Other["No Clothes"] then safe_pcall(function() inst:Destroy() end) end

    -- BasePart (non MeshPart)
    elseif inst:IsA("BasePart") and not inst:IsA("MeshPart") then
        if _G.Settings.Other and _G.Settings.Other["Low Quality Parts"] then
            safe_pcall(function() inst.Material = Enum.Material.Plastic; inst.Reflectance = 0 end)
        end

    -- TextLabel in workspace
    elseif inst:IsA("TextLabel") and inst:IsDescendantOf(Workspace) then
        if _G.Settings.TextLabels and _G.Settings.TextLabels.LowerQuality then
            safe_pcall(function() inst.Font = Enum.Font.SourceSans; inst.TextScaled = false; inst.RichText = false; inst.TextSize = 14 end)
        end
        if _G.Settings.TextLabels and _G.Settings.TextLabels.Invisible then safe_pcall(function() inst.Visible = false end) end
        if _G.Settings.TextLabels and _G.Settings.TextLabels.Destroy then safe_pcall(function() inst:Destroy() end) end

    -- Model LOD
    elseif inst:IsA("Model") then
        if _G.Settings.Other and _G.Settings.Other["Low Quality Models"] then
            safe_pcall(function() pcall(function() inst.LevelOfDetail = 1 end) end)
        end

    -- MeshPart tweaks
    elseif inst:IsA("MeshPart") then
        if _G.Settings.MeshParts and _G.Settings.MeshParts.LowerQuality then
            safe_pcall(function() inst.RenderFidelity = 2; inst.Reflectance = 0; inst.Material = Enum.Material.Plastic end)
        end
        if _G.Settings.MeshParts and _G.Settings.MeshParts.Invisible then
            safe_pcall(function() inst.Transparency = 1; inst.RenderFidelity = 2; inst.Reflectance = 0 end)
        end
        if _G.Settings.MeshParts and _G.Settings.MeshParts.NoTexture then safe_pcall(function() inst.TextureID = "" end) end
        if _G.Settings.MeshParts and _G.Settings.MeshParts.NoMesh then safe_pcall(function() inst.MeshId = "" end) end
        if _G.Settings.MeshParts and _G.Settings.MeshParts.Destroy then safe_pcall(function() inst:Destroy() end) end
    end
end

-- =========================
-- WORLD / RENDER TWEAKS
-- =========================
local function ApplyWorldTweaks()
    -- Low Water Graphics
    if _G.Settings.Other and _G.Settings.Other["Low Water Graphics"] then
        safe_pcall(function()
            local terrain = Workspace:FindFirstChildOfClass("Terrain")
            if not terrain then
                repeat task.wait() until Workspace:FindFirstChildOfClass("Terrain") or not workspace
                terrain = Workspace:FindFirstChildOfClass("Terrain")
            end
            if terrain then
                pcall(function()
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 0
                end)
                if sethiddenproperty then
                    pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
                end
                if _G.SendNotifications then
                    safe_pcall(function()
                        StarterGui:SetCore("SendNotification", {
                            Title = "free fixlag",
                            Text = "Low Water Graphics Enabled",
                            Duration = 4,
                            Button1 = "Okay"
                        })
                    end)
                end
                if _G.ConsoleLogs then warn("free fixlag | Low Water Graphics Enabled") end
            end
        end)
    end

    -- No Shadows
    if _G.Settings.Other and _G.Settings.Other["No Shadows"] then
        safe_pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.ShadowSoftness = 0
            if sethiddenproperty then
                pcall(function() sethiddenproperty(Lighting, "Technology", 2) end)
            end
            if _G.SendNotifications then
                StarterGui:SetCore("SendNotification", {
                    Title = "free fixlag",
                    Text = "No Shadows Enabled",
                    Duration = 3,
                    Button1 = "Okay"
                })
            end
            if _G.ConsoleLogs then warn("free fixlag | No Shadows Enabled") end
        end)
    end

    -- Low Rendering
    if _G.Settings.Other and _G.Settings.Other["Low Rendering"] then
        safe_pcall(function()
            pcall(function()
                settings().Rendering.QualityLevel = 1
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
            end)
            if _G.SendNotifications then
                StarterGui:SetCore("SendNotification", {
                    Title = "free fixlag",
                    Text = "Low Rendering Enabled",
                    Duration = 3,
                    Button1 = "Okay"
                })
            end
            if _G.ConsoleLogs then warn("free fixlag | Low Rendering Enabled") end
        end)
    end

    -- Reset Materials
    if _G.Settings.Other and _G.Settings.Other["Reset Materials"] then
        safe_pcall(function()
            for _, v in pairs(MaterialService:GetChildren()) do
                pcall(function() v:Destroy() end)
            end
            pcall(function() MaterialService.Use2022Materials = false end)
            if _G.SendNotifications then
                StarterGui:SetCore("SendNotification", {
                    Title = "free fixlag",
                    Text = "Reset Materials Applied",
                    Duration = 3,
                    Button1 = "Okay"
                })
            end
            if _G.ConsoleLogs then warn("free fixlag | Reset Materials Applied") end
        end)
    end
end

-- =========================
-- FPS CAP HANDLER
-- =========================
local function ApplyFPSCap()
    safe_pcall(function()
        local target = (_G.Settings and _G.Settings.FPS) or ((_G.Settings and _G.Settings.Other) and _G.Settings.Other["FPS Value"])
        if CUSTOM_FPS and type(CUSTOM_FPS) == "number" then
            target = CUSTOM_FPS
        end
        if type(target) == "number" and setfpscap then
            pcall(function() setfpscap(tonumber(target)) end)
            if _G.SendNotifications then
                StarterGui:SetCore("SendNotification", {
                    Title = "free fixlag",
                    Text = "FPS capped to " .. tostring(target),
                    Duration = 3,
                    Button1 = "Okay"
                })
            end
            if _G.ConsoleLogs then warn("free fixlag | FPS capped to " .. tostring(target)) end
        elseif setfpscap and ((_G.Settings and _G.Settings.Other and _G.Settings.Other["FPS Cap"]) == true) then
            pcall(function() setfpscap(1e6) end)
            if _G.SendNotifications then
                StarterGui:SetCore("SendNotification", {
                    Title = "free fixlag",
                    Text = "FPS Uncapped",
                    Duration = 3,
                    Button1 = "Okay"
                })
            end
            if _G.ConsoleLogs then warn("free fixlag | FPS Uncapped") end
        else
            if _G.ConsoleLogs then warn("free fixlag | setfpscap unavailable or target invalid") end
        end
    end)
end

-- =========================
-- NIL INSTANCES CLEANER
-- =========================
local function ClearNilInstancesIfSupported()
    safe_pcall(function()
        if _G.Settings.Other and _G.Settings.Other.ClearNilInstances then
            if getnilinstances then
                for _, v in pairs(getnilinstances()) do
                    pcall(function() v:Destroy() end)
                end
                if _G.SendNotifications then
                    StarterGui:SetCore("SendNotification", {
                        Title = "free fixlag",
                        Text = "Cleared nil instances",
                        Duration = 3,
                        Button1 = "Okay"
                    })
                end
                if _G.ConsoleLogs then warn("free fixlag | Cleared nil instances") end
            else
                if _G.SendNotifications then
                    StarterGui:SetCore("SendNotification", {
                        Title = "free fixlag",
                        Text = "getnilinstances not supported",
                        Duration = 3,
                        Button1 = "Okay"
                    })
                end
                if _G.ConsoleLogs then warn("free fixlag | getnilinstances not supported") end
            end
        end
    end)
end

-- =========================
-- FULL SCAN + CONNECT
-- =========================
local function FullScanAndConnect()
    local descendants = Workspace:GetDescendants()
    if _G.SendNotifications then
        safe_pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "free fixlag",
                Text = "Checking " .. tostring(#descendants) .. " Instances...",
                Duration = 6,
                Button1 = "Okay"
            })
        end)
    end
    if _G.ConsoleLogs then warn("free fixlag | Checking " .. tostring(#descendants) .. " Instances...") end

    for _, inst in pairs(descendants) do
        safe_pcall(HandleInstance, inst)
    end

    Workspace.DescendantAdded:Connect(function(newInst)
        task.wait(_G.LoadedWait or 0.6)
        safe_pcall(HandleInstance, newInst)
    end)
end

-- =========================
-- FPS MONITOR (Realtime + Boot sample)
-- =========================
-- FPS label (optional)
local fpsLabel = nil
if SHOW_FPS_LABEL then
    -- choose parent: CoreGui preferred for exploits
    local parentGui
    if game:GetService("CoreGui") then parentGui = game:GetService("CoreGui") else parentGui = ME:WaitForChild("PlayerGui") end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LV_FPS_Label"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = parentGui

    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(0,120,0,28)
    fpsLabel.Position = UDim2.new(0,8,0,8)
    fpsLabel.BackgroundTransparency = 0.45
    fpsLabel.BackgroundColor3 = Color3.fromRGB(14,14,14)
    fpsLabel.TextColor3 = Color3.fromRGB(255,255,255)
    fpsLabel.Font = Enum.Font.Code
    fpsLabel.TextSize = 16
    fpsLabel.Text = "FPS: ..."
    fpsLabel.BorderSizePixel = 0
    fpsLabel.Parent = screenGui
end

-- realtime counter
local frames = 0
local lastTime = tick()
local avgFPS = 0
RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastTime >= FPS_UPDATE_INTERVAL then
        avgFPS = math.floor(frames / (now - lastTime) + 0.5)
        frames = 0
        lastTime = now
        if fpsLabel then fpsLabel.Text = "FPS: " .. tostring(avgFPS) end
        _G.CurrentFPS = avgFPS
        if _G.ConsoleLogs then warn("free fixlag | Current FPS: " .. tostring(avgFPS)) end
    end
end)

-- helper sample (used at bootstrap)
local function GetAverageFPSSample(duration)
    duration = duration or 1
    local f = 0
    local s = tick()
    local con
    con = RunService.RenderStepped:Connect(function() f = f + 1 end)
    task.wait(duration)
    if con then con:Disconnect() end
    return math.floor(f / duration + 0.5)
end

-- =========================
-- AUTO-DETECT & APPLY LOGIC
-- =========================
local function AutoDetectAndApply()
    safe_pcall(function()
        -- small boot sample (1s)
        task.wait(0.2) -- let things settle a bit
        local sample = GetAverageFPSSample(1)
        _G.CurrentFPS = sample
        if _G.ConsoleLogs then warn("free fixlag | Boot sample FPS: " .. tostring(sample)) end

        if not FORCE_PRESET then
            if sample and sample < AUTO_THRESHOLD then
                -- auto switch to UltraLow
                if _G.Presets.UltraLow then
                    ApplyPresetByName("UltraLow")
                    if _G.SendNotifications then
                        StarterGui:SetCore("SendNotification", {
                            Title = "free fixlag",
                            Text = "Auto: Low FPS detected -> UltraLow preset applied",
                            Duration = 4,
                            Button1 = "Okay"
                        })
                    end
                    if _G.ConsoleLogs then warn("free fixlag | auto-applied UltraLow") end
                end
            else
                -- apply chosen preset
                ApplyPresetByName(CHOSEN_PRESET)
                if _G.ConsoleLogs then warn("free fixlag | applied chosen preset: ".. tostring(CHOSEN_PRESET)) end
            end
        else
            -- forced preset
            ApplyPresetByName(CHOSEN_PRESET)
            if _G.ConsoleLogs then warn("free fixlag | FORCE_PRESET enabled, applied: ".. tostring(CHOSEN_PRESET)) end
        end

        -- override FPS if CUSTOM_FPS specified
        if CUSTOM_FPS and type(CUSTOM_FPS) == "number" then
            _G.Settings.FPS = CUSTOM_FPS
            if _G.Settings.Other then _G.Settings.Other["FPS Value"] = CUSTOM_FPS end
            if _G.ConsoleLogs then warn("free fixlag | CUSTOM_FPS override: " .. tostring(CUSTOM_FPS)) end
        end
    end)
end

-- =========================
-- BOOTSTRAP / RUN
-- =========================
local function Bootstrap()
    if not game:IsLoaded() then repeat task.wait() until game:IsLoaded() end

    -- initial apply (AutoDetect will update/override if needed)
    ApplyPresetByName(CHOSEN_PRESET)

    -- apply world tweaks (water/shadows/materials)
    ApplyWorldTweaks()

    -- apply fps cap
    ApplyFPSCap()

    -- clear nil instances if supported & configured
    ClearNilInstancesIfSupported()

    -- scan map & hook descendant added
    FullScanAndConnect()

    -- auto detect & adjust (will still run but FORCE_PRESET=true makes script keep UltraLow)
    AutoDetectAndApply()

    -- final noti
    if _G.SendNotifications then
        safe_pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "free fixlag",
                Text = "Lâm Vĩ LagFix™ is active — FPS boosted!",
                Duration = 6,
                Button1 = "Okay"
            })
        end)
    end
    if _G.ConsoleLogs then warn("free fixlag | Lâm Vĩ LagFix™ is active") end
end

-- Run bootstrap safely
coroutine.wrap(function()
    local ok, err = pcall(Bootstrap)
    if not ok and _G.ConsoleLogs then warn("free fixlag | bootstrap failed: " .. tostring(err)) end
end)()
