-- ======================================================
-- DucLuongg FixLag™ — Cement Mode (Full edition)
-- - UltraLow mặc định (xi măng)
-- - Giữ đảo / quái / UI — chỉ giảm hiệu ứng nặng + đồ họa
-- - Toggle bằng phím (mặc định F)
-- - Watermark notify: "DucLuongg FixLag™"
-- ======================================================

-- ======= CONFIG (SỬA Ở ĐẦU NẾU CẦN) =======
local CONFIG = {
    MODE = "UltraLow",           -- "UltraLow" / "Medium" / "High"
    LOCK_FPS = 120,              -- setfpscap nếu exploit hỗ trợ
    TOGGLE_KEY = Enum.KeyCode.F, -- phím bật/tắt
    SHOW_NOTIFICATION = true,    -- Set false để tắt noti
    KEEP_UI = true,              -- không động tới GUI
    CEMENT_TRANSPARENCY = 0.45,  -- decal/texture transparency (xi măng look)
    IGNORE_LIST = {},            -- places to ignore (workspace.Map, etc)
    SPAWN_DELAY = 0.6,           -- delay khi xử lý descendant mới
    LOGS = false                 -- bật warn() debug
}
-- ==========================================

-- Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local MaterialService = game:GetService("MaterialService")
local Workspace = game:GetService("Workspace")

local LOCAL = Players.LocalPlayer

-- Internal state
local STATE = {
    enabled = true,
    presets = {},
    canDisableClasses = {
        ParticleEmitter = true, Trail = true, Smoke = true, Fire = true, Sparkles = true
    }
}

-- Helper: notify
local function notify(text, dur)
    if not CONFIG.SHOW_NOTIFICATION then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "DucLuongg FixLag™",
            Text = tostring(text or ""),
            Duration = dur or 4,
            Button1 = "Okay"
        })
    end)
    if CONFIG.LOGS then warn("[DucLuongg] " .. tostring(text)) end
end

-- Helper safe pcall wrapper
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and CONFIG.LOGS then warn("[DucLuongg] err:", err) end
    return ok, err
end

-- Presets (đầy đủ nhưng khác tên/structure)
STATE.presets.UltraLow = {
    name = "UltraLow",
    fps = 999,
    meshes = { noMesh = true, noTexture = true, destroy = true },
    images = { invisible = true, destroy = true, lowDetail = true },
    particles = { invisible = true, destroy = true },
    explosions = { smaller = true, invisible = true, destroy = true },
    meshparts = { lowerQuality = true, invisible = true, noTexture = true, noMesh = true, destroy = true },
    other = {
        fpsCap = true, fpsValue = CONFIG.LOCK_FPS,
        noCameraFx = true, noClothes = true, lowWater = true,
        noShadows = true, lowRender = true, resetMaterials = true,
        lowerQualityMeshparts = true, clearNil = true
    }
}

STATE.presets.Medium = {
    name = "Medium",
    fps = 180,
    meshes = { noMesh = false, noTexture = true, destroy = false },
    images = { invisible = false, destroy = false, lowDetail = false },
    particles = { invisible = true, destroy = false },
    explosions = { smaller = true, invisible = false, destroy = false },
    meshparts = { lowerQuality = true, invisible = false, noTexture = true, noMesh = false, destroy = false },
    other = {
        fpsCap = true, fpsValue = 120,
        noCameraFx = true, noClothes = false, lowWater = false,
        noShadows = false, lowRender = false, resetMaterials = false,
        lowerQualityMeshparts = true, clearNil = false
    }
}

STATE.presets.High = {
    name = "High",
    fps = 240,
    meshes = { noMesh = false, noTexture = false, destroy = false },
    images = { invisible = false, destroy = false, lowDetail = false },
    particles = { invisible = false, destroy = false },
    explosions = { smaller = false, invisible = false, destroy = false },
    meshparts = { lowerQuality = false, invisible = false, noTexture = false, noMesh = false, destroy = false },
    other = {
        fpsCap = true, fpsValue = 240,
        noCameraFx = false, noClothes = false, lowWater = false,
        noShadows = false, lowRender = false, resetMaterials = false,
        lowerQualityMeshparts = false, clearNil = false
    }
}

-- Choose active preset
local function choosePreset(name)
    local p = STATE.presets[name]
    if not p then
        if CONFIG.LOGS then warn("preset not found", name) end
        return STATE.presets.UltraLow
    end
    return p
end
local ACTIVE = choosePreset(CONFIG.MODE)

-- Utility: is descendant of ignored
local function isDescendantIgnored(obj)
    for _, ig in ipairs(CONFIG.IGNORE_LIST) do
        if ig and obj:IsDescendantOf(ig) then return true end
    end
    return false
end

-- Core: Apply tweaks to a single instance (preserve gameplay)
local function processInstance(inst)
    if not inst or not inst.Parent then return end
    if inst:IsDescendantOf(Players) then return end
    if isDescendantIgnored(inst) then return end

    -- avoid deleting UI stuff: if it's under PlayerGui and KEEP_UI true, skip
    if CONFIG.KEEP_UI and inst:IsDescendantOf(LOCAL:FindFirstChild("PlayerGui") or {}) then
        return
    end

    -- Mesh handling
    if inst:IsA("DataModelMesh") then
        if inst:IsA("SpecialMesh") then
            if ACTIVE.meshes.noMesh then safe(function() inst.MeshId = "" end) end
            if ACTIVE.meshes.noTexture then safe(function() inst.TextureId = "" end) end
        end
        if ACTIVE.meshes.destroy then safe(function() inst:Destroy() end) end
        return
    end

    -- Faces / ShirtGraphic / Decals
    if inst:IsA("FaceInstance") then
        if ACTIVE.images.invisible then safe(function() inst.Transparency = 1; inst.Shiny = 1 end) end
        if ACTIVE.images.destroy then safe(function() inst:Destroy() end) end
        return
    end
    if inst:IsA("ShirtGraphic") then
        if ACTIVE.images.invisible then safe(function() inst.Graphic = "" end) end
        if ACTIVE.images.destroy then safe(function() inst:Destroy() end) end
        return
    end

    -- Particles & trails
    if STATE.canDisableClasses[inst.ClassName] then
        if ACTIVE.particles.invisible then safe(function() inst.Enabled = false end) end
        if ACTIVE.particles.destroy then safe(function() inst:Destroy() end) end
        return
    end

    -- Post effects (bloom/blur)
    if inst:IsA("PostEffect") and ACTIVE.other.noCameraFx then
        safe(function() inst.Enabled = false end)
        return
    end

    -- Explosions
    if inst:IsA("Explosion") then
        if ACTIVE.explosions.smaller then safe(function() inst.BlastPressure = 1; inst.BlastRadius = 1 end) end
        if ACTIVE.explosions.invisible then safe(function() inst.Visible = false end) end
        if ACTIVE.explosions.destroy then safe(function() inst:Destroy() end) end
        return
    end

    -- Clothing, SurfaceAppearance
    if (inst:IsA("Clothing") or inst:IsA("SurfaceAppearance") or inst:IsA("BaseWrap")) and ACTIVE.other.noClothes then
        safe(function() inst:Destroy() end)
        return
    end

    -- BasePart tweaks (non MeshPart)
    if inst:IsA("BasePart") and not inst:IsA("MeshPart") then
        if ACTIVE.meshparts.lowerQuality or ACTIVE.other["Low Quality Parts"] then
            safe(function() inst.Material = Enum.Material.Plastic; inst.Reflectance = 0 end)
        end
        return
    end

    -- TextLabel in workspace
    if inst:IsA("TextLabel") and inst:IsDescendantOf(Workspace) then
        if ACTIVE.textLabels and ACTIVE.textLabels.LowerQuality then
            safe(function()
                inst.Font = Enum.Font.SourceSans
                inst.TextScaled = false
                inst.RichText = false
                inst.TextSize = 14
            end)
        end
        if ACTIVE.textLabels and ACTIVE.textLabels.Invisible then safe(function() inst.Visible = false end) end
        if ACTIVE.textLabels and ACTIVE.textLabels.Destroy then safe(function() inst:Destroy() end) end
        return
    end

    -- Model LOD
    if inst:IsA("Model") then
        if ACTIVE.other["Low Quality Models"] then
            safe(function() inst.LevelOfDetail = 1 end)
        end
        return
    end

    -- MeshPart tweaks
    if inst:IsA("MeshPart") then
        if ACTIVE.meshparts.lowerQuality then
            safe(function() inst.RenderFidelity = 2; inst.Reflectance = 0; inst.Material = Enum.Material.Plastic end)
        end
        if ACTIVE.meshparts.invisible then safe(function() inst.Transparency = 1; inst.RenderFidelity = 2 end) end
        if ACTIVE.meshparts.noTexture then safe(function() inst.TextureID = "" end) end
        if ACTIVE.meshparts.noMesh then safe(function() inst.MeshId = "" end) end
        if ACTIVE.meshparts.destroy then safe(function() inst:Destroy() end) end
        return
    end
end

-- World tweaks (water, lighting, materials)
local function applyWorldTweaks()
    -- Water
    if ACTIVE.other.lowWater then
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            safe(function()
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 0
            end)
            notify("Low Water Graphics Enabled")
        end
    end

    -- Shadows & Lighting
    if ACTIVE.other.noShadows then
        safe(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.ShadowSoftness = 0
        end)
        notify("No Shadows Enabled")
    end

    -- Reset Materials
    if ACTIVE.other.resetMaterials then
        safe(function()
            for _, mat in ipairs(MaterialService:GetChildren()) do
                pcall(function() mat:Destroy() end)
            end
            MaterialService.Use2022Materials = false
        end)
        notify("Materials Reset")
    end

    -- Disable posteffects
    if ACTIVE.other.noCameraFx then
        for _, ch in ipairs(Lighting:GetChildren()) do
            if ch:IsA("PostEffect") then
                safe(function() ch.Enabled = false end)
            end
        end
    end
end

-- FPS cap / setfpscap
local function applyFPSCap()
    if ACTIVE.other.fpsCap and type(ACTIVE.other.fpsValue) ~= "nil" then
        local v = ACTIVE.other.fpsValue or CONFIG.LOCK_FPS
        if setfpscap then
            pcall(function() setfpscap(tonumber(v)) end)
            notify("FPS cap set: " .. tostring(v))
        else
            -- fallback: try to uncap if true
            if CONFIG.LOGS then warn("setfpscap not available") end
        end
    end
end

-- Boot: initial full pass
local function initialScan()
    notify("Starting full optimization check...")
    local all = Workspace:GetDescendants()
    for i = 1, #all do
        local inst = all[i]
        safe(function() processInstance(inst) end)
    end
    notify("Full pass complete.")
end

-- Hook: auto process newly spawned stuff
Workspace.DescendantAdded:Connect(function(inst)
    task.wait(CONFIG.SPAWN_DELAY)
    if STATE.enabled then
        safe(function() processInstance(inst) end)
    end
end)

-- Toggle handler (key)
local function bindToggle()
    local mouse = LOCAL:GetMouse()
    mouse.KeyDown:Connect(function(key)
        -- allow uppercase/lowercase key matching
        if string.lower(key) == string.lower(CONFIG.TOGGLE_KEY.Name) then
            STATE.enabled = not STATE.enabled
            if STATE.enabled then
                notify("DucLuongg FixLag™ ENABLED")
                safe(function()
                    initialScan()
                    applyWorldTweaks()
                    applyFPSCap()
                end)
            else
                notify("DucLuongg FixLag™ DISABLED (restart to reapply)")
            end
        end
    end)
end

-- Cement-ify look (optional visual touch while preserving game objects)
local function cementifyAppearance()
    -- set simple ambient / color
    safe(function()
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(140,140,140)
    end)
    -- slightly mute decals/textures (so map looks cement-y)
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") then
            safe(function() v.Transparency = CONFIG.CEMENT_TRANSPARENCY end)
        elseif v:IsA("BasePart") and not v:IsDescendantOf(Players) then
            -- don't clobber players
            safe(function()
                v.Material = Enum.Material.Concrete
                v.Reflectance = 0
            end)
        end
    end
end

-- Apply selected preset to ACTIVE table structure (map names)
local function applySelectedPreset()
    local name = CONFIG.MODE or "UltraLow"
    local p = STATE.presets[name]
    if not p then p = STATE.presets.UltraLow end
    ACTIVE = {}
    -- copy fields (simple shallow copy)
    for k,v in pairs(p) do ACTIVE[k] = v end
    -- normalize other names
    if ACTIVE.other then
        ACTIVE.other.fpsValue = (ACTIVE.other.fpsValue or ACTIVE.other["FPS Value"] or CONFIG.LOCK_FPS)
    end
end

-- Boot sequence
safe(function()
    applySelectedPreset()
    notify("DucLuongg FixLag™ initializing...")
    cementifyAppearance()
    initialScan()
    applyWorldTweaks()
    applyFPSCap()
    bindToggle()
    notify("DucLuongg FixLag™ loaded | Mode: " .. tostring(CONFIG.MODE))
end)

-- keep FPS cap enforced loop (best-effort)
RunService.Heartbeat:Connect(function()
    if STATE.enabled and CONFIG.LOCK_FPS and setfpscap then
        pcall(function() setfpscap(CONFIG.LOCK_FPS) end)
    end
end)

-- end of file
