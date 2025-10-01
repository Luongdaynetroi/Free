--========================================================
-- DucLuongg FixLag™ | Xi Măng Edition + AntiSkillEffect Optimized
-- Full FPS Booster + Giảm rung skill + giữ đảo/quái/UI
--========================================================

if not _G.Ignore then _G.Ignore = {} end
if _G.SendNotifications == nil then _G.SendNotifications = true end
if _G.ConsoleLogs == nil then _G.ConsoleLogs = false end

-- Default Settings
if not _G.Settings then
    _G.Settings = {
        Players = {["Ignore Me"] = true, ["Ignore Others"] = true, ["Ignore Tools"] = true},
        Meshes = {NoMesh = false, NoTexture = false, Destroy = false},
        Images = {Invisible = true, Destroy = false},
        Explosions = {Smaller = true, Invisible = false, Destroy = false},
        Particles = {Invisible = true, Destroy = false},
        TextLabels = {LowerQuality = false, Invisible = false, Destroy = false},
        MeshParts = {LowerQuality = true, Invisible = false, NoTexture = false, NoMesh = false, Destroy = false},
        Other = {
            ["FPS Cap"] = 120,
            ["No Camera Effects"] = true,
            ["No Clothes"] = true,
            ["Low Water Graphics"] = true,
            ["No Shadows"] = true,
            ["Low Rendering"] = true,
            ["Low Quality Parts"] = true,
            ["Low Quality Models"] = true,
            ["Reset Materials"] = true,
            ["Lower Quality MeshParts"] = true,
            ClearNilInstances = false,
            ["Skill Effect Reduction"] = true
        }
    }
end

-- Services
local Players, Lighting, StarterGui, MaterialService =
    game:GetService("Players"),
    game:GetService("Lighting"),
    game:GetService("StarterGui"),
    game:GetService("MaterialService")
local ME = Players.LocalPlayer
local CanBeEnabled = {"ParticleEmitter","Trail","Smoke","Fire","Sparkles"}

-- Helpers
local function Notify(title, text, duration)
    if _G.SendNotifications then
        pcall(function()
            StarterGui:SetCore("SendNotification", {Title = "DucLuongg FixLag™", Text = text or "", Duration = duration or 5})
        end)
    end
    if _G.ConsoleLogs then warn(text) end
end

-- Main check logic
local function CheckIfBad(Inst)
    if Inst:IsA("DataModelMesh") then
        if Inst:IsA("SpecialMesh") then
            if _G.Settings.Meshes.NoMesh then Inst.MeshId = "" end
            if _G.Settings.Meshes.NoTexture then Inst.TextureId = "" end
        end
        if _G.Settings.Meshes.Destroy then Inst:Destroy()
        end
    elseif Inst:IsA("FaceInstance") then
        if _G.Settings.Images.Invisible then Inst.Transparency = 1 end
        if _G.Settings.Images.Destroy then Inst:Destroy()
        end
    elseif table.find(CanBeEnabled, Inst.ClassName) then
        if _G.Settings.Particles.Invisible then Inst.Enabled = false end
        if _G.Settings.Particles.Destroy then Inst:Destroy() end
    elseif Inst:IsA("PostEffect") and _G.Settings.Other["No Camera Effects"] then
        Inst.Enabled = false
    elseif Inst:IsA("Explosion") then
        if _G.Settings.Explosions.Smaller then Inst.BlastPressure = 1; Inst.BlastRadius = 1 end
        if _G.Settings.Explosions.Invisible then Inst.Visible = false end
        if _G.Settings.Explosions.Destroy then Inst:Destroy() end
    elseif Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") then
        if _G.Settings.Other["No Clothes"] then Inst:Destroy() end
    elseif Inst:IsA("BasePart") and not Inst:IsA("MeshPart") then
        if _G.Settings.Other["Low Quality Parts"] then
            Inst.Material = Enum.Material.Plastic
            Inst.Reflectance = 0
        end
    elseif Inst:IsA("MeshPart") then
        if _G.Settings.MeshParts.LowerQuality then Inst.RenderFidelity = Enum.RenderFidelity.Performance; Inst.Material = Enum.Material.Plastic end
        if _G.Settings.MeshParts.Invisible then Inst.Transparency = 1 end
        if _G.Settings.MeshParts.NoTexture then Inst.TextureID = "" end
        if _G.Settings.MeshParts.NoMesh then Inst.MeshId = "" end
        if _G.Settings.MeshParts.Destroy then Inst:Destroy() end
    end
end

-- Water
coroutine.wrap(function()
    if _G.Settings.Other["Low Water Graphics"] then
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        end
        Notify("DucLuongg FixLag™", "Keocon")
    end
end)()

-- Shadows
coroutine.wrap(function()
    if _G.Settings.Other["No Shadows"] then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        Notify("tôi bị ngu™", "tôi không ngu")
    end
end)()

-- Rendering
coroutine.wrap(function()
    if _G.Settings.Other["Low Rendering"] then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Notify("một cái chết truyền thông™", "các bạn có thấy rất phiền không")
    end
end)()

-- Materials
coroutine.wrap(function()
    if _G.Settings.Other["Reset Materials"] then
        for _, v in pairs(MaterialService:GetChildren()) do v:Destroy() end
        MaterialService.Use2022Materials = false
        Notify("xin lỗi vì quá dz™", "cảm ơn")
    end
end)()

-- FPS Cap
coroutine.wrap(function()
    if _G.Settings.Other["FPS Cap"] and setfpscap then
        setfpscap(_G.Settings.Other["FPS Cap"])
        Notify("DucLuong™", "FPS".._G.Settings.Other["FPS Cap"])
    end
end)()

-- Skill effect reduction (Optimized)
if _G.Settings.Other["Skill Effect Reduction"] then
    local function DisableSkillEffects(inst)
        if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Fire") or inst:IsA("Smoke") then
            inst.Enabled = false
        elseif inst:IsA("Explosion") then
            inst.BlastPressure = 0
            inst.BlastRadius = 0
            inst.Visible = false
        end
    end
    -- Apply to existing and future instances
    for _, v in pairs(workspace:GetDescendants()) do DisableSkillEffects(v) end
    workspace.DescendantAdded:Connect(DisableSkillEffects)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "ThangNgot",
    Text = "HoanHoBanNhacThuDo",
    Duration = math.huge
})
end

-- Apply to all existing instances
for _, v in pairs(game:GetDescendants()) do CheckIfBad(v) end
game.DescendantAdded:Connect(function(v)
    task.wait(0.1)
    CheckIfBad(v)
end)

Notify("DucLuongg FixLag™", "Xi Măng Edition + AntiSkillEffect Loaded!", 45)
