--========================================================
-- DucLuongg Ultra-Optimized FixLag™ (Keep Islands/NPC/UI)
-- - Mục tiêu: tối ưu CPU/GPU client-side mà KHÔNG xóa đảo/quái/UI
-- - Kỹ thuật: giảm particle/trail/sparkle world-wide, hạ fidelity mesh, tắt post-effects nặng,
--   giảm âm thanh nền, set materials nhẹ (không chạm vào character parts),
--   clear nil instances (nếu exploit hỗ trợ), FPS lock tùy chọn.
--========================================================

-- ========== CONPhing ==========
local CONFIG = {
    MODE_NAME = "UltraOptimized",
    LOCK_FPS = 120,                   -- số để setfpscap (nil để bỏ)
    SHOW_NOTIFY = true,               -- thông báo khi load
    INTRO_TIME = 10,                  -- giây cho noti đầu
    APPLY_MATERIAL_LIGHT = true,      -- chuyển material world -> Plastic (nhẹ)
    WORLD_MATERIAL_EXCEPT = {         -- tên hoặc keyword model sẽ không bị đổi material
        "Island", "Spawn", "Base", "NPC", "Enemy", "Boss", "Map", "IslandPart"
    },
    PRESERVE_UI = true,               -- không chạm PlayerGui/CoreGui
    REDUCE_WORLD_PARTICLES = true,    -- giảm/disable particle không dính char
    ENHANCE_PLAYER_PARTICLES = true,  -- giữ/boost particle gắn nhân vật (để skill vẫn rõ)
    DISABLE_POST_EFFECTS = true,      -- tắt Blur/DepthOfField/ColorCorrection gốc (giữ Bloom nhẹ của script)
    BREADCRUMB_LOG = false,           -- warn logs
    CLEAR_NIL_INSTANCES = true,       -- nếu exploit hỗ trợ getnilinstances
    SOUND_REDUCTION = 0.35,           -- tỉ lệ volume (0..1) cho ambient sounds
    SKIP_NAMES_CONTAIN = {"PlayerGui","CoreGui","Backpack"}, -- skip paths
    FPS_LABEL = false,                -- hiển thị fps label
    FPS_LABEL_UPDATE = 0.6,
}
-- ============================

-- Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")

local LocalPlayer = Players.LocalPlayer

-- Helpers
local function log(...)
    if CONFIG.BREADCRUMB_LOG then warn(...) end
end

local function safe_pcall(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then log("FixLag error:", tostring(err)) end
    return ok, err
end

local function Notify(text, duration)
    if not CONFIG.SHOW_NOTIFY then return end
    safe_pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "DucLuongg FixLag™",
            Text = text or "",
            Duration = duration or 4
        })
    end)
end

-- Utility: check if inst is under a preserved name / UI
local function isPreservedPath(inst)
    if not inst then return false end
    for _,k in ipairs(CONFIG.SKIP_NAMES_CONTAIN) do
        if inst:IsDescendantOf(game:GetService(k)) then return true end
    end
    return false
end

local function nameContainsAny(name, tbl)
    if not name then return false end
    local lname = tostring(name)
    for _,kw in ipairs(tbl) do
        if string.find(lname, kw) then return true end
    end
    return false
end

local function isPartOfCharacter(inst)
    if not inst then return false end
    for _,p in pairs(Players:GetPlayers()) do
        if p.Character and inst:IsDescendantOf(p.Character) then return true end
    end
    return false
end

local function isWorldImportantModel(inst)
    if not inst or not inst.Name then return false end
    return nameContainsAny(inst.Name, CONFIG.WORLD_MATERIAL_EXCEPT)
end

-- =========================
-- Create lightweight post-effects (we control these)
-- =========================
-- remove old ones from previous runs
safe_pcall(function()
    for _,v in pairs(Lighting:GetChildren()) do
        if v.Name:match("^DucLuongg_Ultra") then
            if v:IsA("PostEffect") then pcall(function() v:Destroy() end) end
        end
    end
end)

-- Bloom
local Bloom = Instance.new("BloomEffect")
Bloom.Name = "DucLuongg_Ultra_Bloom"
Bloom.Parent = Lighting
Bloom.Intensity = 0.7
Bloom.Size = 32
Bloom.Threshold = 0.82

-- ColorCorrection (subtle)
local CC = Instance.new("ColorCorrectionEffect")
CC.Name = "DucLuongg_Ultra_CC"
CC.Parent = Lighting
CC.Saturation = 0.06
CC.Contrast = 0.12
CC.Brightness = 0.02
CC.TintColor = Color3.fromRGB(245,245,240)

-- gentle sunray (subtle)
local Sun = Instance.new("SunRaysEffect")
Sun.Name = "DucLuongg_Ultra_Sun"
Sun.Parent = Lighting
Sun.Intensity = 0.18
Sun.Spread = 0.8

-- disable heavy built-in post effects (non-destructive: only disable if script created them OR by type)
if CONFIG.DISABLE_POST_EFFECTS then
    safe_pcall(function()
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
                pcall(function() v.Enabled = false end)
            end
        end
    end)
end

-- Fog / ambient tuning (cement-ish, but keep contrast)
local originalFogStart, originalFogEnd = Lighting.FogStart, Lighting.FogEnd
Lighting.FogStart = 180
Lighting.FogEnd = 1600
Lighting.FogColor = Color3.fromRGB(220,220,220)
local origAmbient = Lighting.Ambient
Lighting.Ambient = Color3.fromRGB(200,200,200)
Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)

-- =========================
-- FPS label (optional)
-- =========================
local fpsLabel = nil
if CONFIG.FPS_LABEL then
    local parent = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    local screen = Instance.new("ScreenGui", parent)
    screen.Name = "DucLuonggUltraFPSGui"
    screen.ResetOnSpawn = false
    fpsLabel = Instance.new("TextLabel", screen)
    fpsLabel.Size = UDim2.new(0,120,0,28)
    fpsLabel.Position = UDim2.new(0,8,0,8)
    fpsLabel.BackgroundTransparency = 0.4
    fpsLabel.TextColor3 = Color3.new(1,1,1)
    fpsLabel.Font = Enum.Font.Code
    fpsLabel.TextSize = 15
    fpsLabel.Text = "FPS: ..."
    fpsLabel.BorderSizePixel = 0
    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - last >= CONFIG.FPS_LABEL_UPDATE then
            local avg = math.floor(frames / (now - last) + 0.5)
            frames = 0; last = now
            fpsLabel.Text = "FPS: "..tostring(avg)
        end
    end)
end

-- =========================
-- CLEAR NIL INSTANCES (if supported)
-- =========================
if CONFIG.CLEAR_NIL_INSTANCES and type(getnilinstances) == "function" then
    safe_pcall(function()
        for _,v in pairs(getnilinstances()) do
            pcall(function() v:Destroy() end)
        end
        log("Cleared nil instances")
    end)
end

-- =========================
-- Reduce world particle/trail/sparkle load (non-destructive)
-- - KEEP particles attached to characters (so skills still show)
-- - For world particles: set Rate=0, Lifetime tiny, Enabled=false
-- =========================
local function reduceParticle(inst)
    if not inst or not inst.Parent then return end
    if isPreservedPath(inst) then return end
    if isPartOfCharacter(inst) then
        -- enhance or keep player particles crisp, but avoid crazy rates
        if CONFIG.ENHANCE_PLAYER_PARTICLES and inst:IsA("ParticleEmitter") then
            safe_pcall(function()
                if pcall(function() return inst.Rate end) then inst.Rate = math.min(inst.Rate, 80) end
                if pcall(function() return inst.Lifetime end) then inst.Lifetime = NumberRange.new(0.1, 0.45) end
                if pcall(function() return inst.Speed end) then inst.Speed = NumberRange.new(0) end
            end)
        end
        return
    end

    -- world particle => reduce aggressively
    if inst:IsA("ParticleEmitter") then
        safe_pcall(function()
            if pcall(function() return inst.Rate end) then inst.Rate = 0 end
            if pcall(function() return inst.Lifetime end) then inst.Lifetime = NumberRange.new(0.02) end
            pcall(function() inst.Enabled = false end)
        end)
    elseif inst:IsA("Trail") or inst:IsA("Sparkles") or inst:IsA("Fire") or inst:IsA("Smoke") then
        safe_pcall(function() if inst.Enabled ~= nil then inst.Enabled = false end end)
    end
end

-- Explosion handling: neutralize blast effects
local function neutralizeExplosion(expl)
    if not expl then return end
    safe_pcall(function()
        expl.BlastPressure = 0
        expl.BlastRadius = 0
        expl.Visible = false
    end)
end

-- initial pass for particles/explosions
for _,v in pairs(Workspace:GetDescendants()) do
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Sparkles") or v:IsA("Fire") or v:IsA("Smoke") then
        if CONFIG.REDUCE_WORLD_PARTICLES then reduceParticle(v) end
    elseif v:IsA("Explosion") then
        neutralizeExplosion(v)
    end
end

-- connect new ones
Workspace.DescendantAdded:Connect(function(v)
    task.wait(0.05)
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Sparkles") or v:IsA("Fire") or v:IsA("Smoke") then
        if CONFIG.REDUCE_WORLD_PARTICLES then reduceParticle(v) end
    elseif v:IsA("Explosion") then
        neutralizeExplosion(v)
    end
end)

-- =========================
-- Material & mesh fidelity tweaks (non-destructive where possible)
-- - Change world parts to Plastic (cement look) except preserved models
-- - Lower MeshPart.RenderFidelity to Performance
-- =========================
local function tweakMaterialAndFidelity(inst)
    if not inst or not inst.Parent then return end
    if isPreservedPath(inst) then return end
    if isPartOfCharacter(inst) then return end  -- don't touch characters

    -- if the inst is under a preserved model, skip
    local anc = inst
    while anc and anc.Parent do
        if isWorldImportantModel(anc) then return end
        anc = anc.Parent
    end

    if inst:IsA("MeshPart") then
        safe_pcall(function()
            inst.RenderFidelity = Enum.RenderFidelity.Performance
            if CONFIG.APPLY_MATERIAL_LIGHT then inst.Material = Enum.Material.Plastic end
            inst.Reflectance = 0
        end)
    elseif inst:IsA("BasePart") then
        safe_pcall(function()
            if CONFIG.APPLY_MATERIAL_LIGHT then inst.Material = Enum.Material.Plastic end
            inst.Reflectance = 0
        end)
    end
end

-- initial pass
for _,v in pairs(Workspace:GetDescendants()) do
    tweakMaterialAndFidelity(v)
end
Workspace.DescendantAdded:Connect(function(v)
    task.wait(0.05)
    tweakMaterialAndFidelity(v)
end)

-- =========================
-- Reduce ambient / long sounds (non-destructive)
-- - Scale down Sound.Volume for ambient-like sounds to reduce CPU
-- =========================
local function reduceSound(inst)
    if not inst or not inst.Parent then return end
    if inst:IsA("Sound") then
        -- prefer to only touch ambient / non-character sounds
        if not isPartOfCharacter(inst) and not isPreservedPath(inst) then
            safe_pcall(function()
                if type(inst.Volume) == "number" then
                    inst.Volume = math.clamp((inst.Volume or 1) * CONFIG.SOUND_REDUCTION, 0, 1)
                end
                -- shorten long-looping ambient sounds: lower Playing or Looped? we won't stop them, only reduce volume
            end)
        end
    end
end

for _,v in pairs(Workspace:GetDescendants()) do
    reduceSound(v)
end
Workspace.DescendantAdded:Connect(function(v)
    task.wait(0.05)
    reduceSound(v)
end)

-- =========================
-- Remove any previously created "soft shadow" parts from earlier scripts (we don't create)
-- =========================
safe_pcall(function()
    for _,v in pairs(Workspace:GetChildren()) do
        if v.Name == "DucLuongg_SoftShadow" then
            pcall(function() v:Destroy() end)
        end
    end
end)

-- =========================
-- Optional: setfpscap if available
-- =========================
if CONFIG.LOCK_FPS and type(CONFIG.LOCK_FPS) == "number" and setfpscap then
    pcall(function() setfpscap(CONFIG.LOCK_FPS) end)
    log("setfpscap to", CONFIG.LOCK_FPS)
end

-- =========================
-- Final notification
-- =========================
if CONFIG.SHOW_NOTIFY then
    Notify("⚙️ Lay con cu dai ngoang cua tao roi quang qua nguoi", CONFIG.INTRO_TIME)
end

print("✅ DucLuongg Ultra-Optimized FixLag loaded. Mode:", CONFIG.MODE_NAME)
