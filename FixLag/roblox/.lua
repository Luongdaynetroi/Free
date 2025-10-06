--==============================================================
-- DucLuongg FixLag™ | Xi Măng Apocalypse™ v9.0
-- Full Anti Lag System | "Lag is Dead, FPS is God"
--==============================================================

if _G.ApocalypseFix then return end
_G.ApocalypseFix = true

-- ⚙️ SERVICES
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local MaterialService = game:GetService("MaterialService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

--==============================================================
-- 🧱 NOTIFY SYSTEM
--==============================================================
local function Notify(title, text, dur)
	pcall(function()
		game.StarterGui:SetCore("SendNotification", {
			Title = title;
			Text = text;
			Duration = dur or 3;
		})
	end)
end

--==============================================================
-- 💻 LOADING UI
--==============================================================
local function LoadingStep(step, total, text)
	local percent = math.floor((step / total) * 100)
	print(string.format("[Xi Măng Apocalypse™] [%d/%d] %s ... %d%%", step, total, text, percent))
	Notify("Xi Măng Apocalypse™", text.." ("..percent.."%)", 1.5)
	task.wait(0.3)
end

local totalSteps = 15
local step = 0

--==============================================================
-- 🌀 CLEANING FUNCTIONS
--==============================================================
local function DeepClean(inst)
	if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire")
	or inst:IsA("Sparkles") or inst:IsA("Beam") or inst:IsA("Explosion") then
		inst.Enabled = false
	elseif inst:IsA("Decal") or inst:IsA("Texture") or inst:IsA("SurfaceAppearance") then
		inst:Destroy()
	elseif inst:IsA("Clothing") or inst:IsA("Shirt") or inst:IsA("Pants") then
		inst:Destroy()
	elseif inst:IsA("BasePart") then
		inst.Material = Enum.Material.Plastic
		inst.CastShadow = false
		inst.Reflectance = 0
		inst.Anchored = inst.Anchored
	end
end

--==============================================================
-- 🌅 LIGHTING
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Tối ưu Lighting")
pcall(function()
	Lighting.GlobalShadows = false
	Lighting.ShadowSoftness = 0
	Lighting.Brightness = 2
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogEnd = 9e9
	Lighting.FogStart = 0
	Lighting.ExposureCompensation = 0
	for _, eff in ipairs(Lighting:GetChildren()) do
		if eff:IsA("PostEffect") or eff:IsA("SunRaysEffect") or eff:IsA("BloomEffect") 
		or eff:IsA("ColorCorrectionEffect") or eff:IsA("DepthOfFieldEffect") then
			eff.Enabled = false
		end
	end
end)

--==============================================================
-- 🌊 TERRAIN + WATER
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Làm phẳng nước và địa hình")
if Terrain then
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 0
end

--==============================================================
-- 🧱 MATERIAL SERVICE
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Xóa vật liệu 2022 nặng nề")
for _, v in pairs(MaterialService:GetChildren()) do
	v:Destroy()
end
MaterialService.Use2022Materials = false

--==============================================================
-- 🧠 PERFORMANCE SETTINGS
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Hạ cấu hình render xuống tối thiểu")
pcall(function()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Low
	settings().Rendering.EditQualityLevel = Enum.QualityLevel.Level01
	settings().Network.IncomingReplicationLag = 0
end)
--==============================================================
-- 🎮 CAMERA TUNING
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Điều chỉnh camera & zoom xa")
pcall(function()
	local cam = workspace.CurrentCamera
	cam.FieldOfView = 70
	cam.MaxZoomDistance = 600
end)

--==============================================================
-- 🚫 EFFECTS REMOVAL
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Xóa hiệu ứng skill, khói, lửa, tia")
for _, v in pairs(workspace:GetDescendants()) do
	DeepClean(v)
end
workspace.DescendantAdded:Connect(DeepClean)

--==============================================================
-- 🧩 UI CLEANUP
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Dọn rác UI, GUI ẩn")
for _, gui in pairs(StarterGui:GetChildren()) do
	if gui:IsA("ScreenGui") and not gui.Enabled then
		gui:Destroy()
	end
end

--==============================================================
-- 🧠 MEMORY CLEANUP LOOP
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Khởi tạo hệ thống dọn rác định kỳ")
task.spawn(function()
	while task.wait(15) do
		collectgarbage("collect")
	end
end)

--==============================================================
-- 💾 PHYSICS & SIMULATION
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Ổn định vật lý & tăng SimulationRadius")
RunService.Stepped:Connect(function()
	pcall(function()
		sethiddenproperty(Player, "SimulationRadius", math.huge)
	end)
end)

--==============================================================
-- 🧠 FPS MONITOR & AUTO-STABILIZER
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Tạo watchdog FPS")
if setfpscap then
	setfpscap(165)
end

local lastFPS = 60
task.spawn(function()
	while task.wait(5) do
		local currentFPS = math.floor(1 / RunService.RenderStepped:Wait())
		if currentFPS < 40 then
			setfpscap(60)
			print("[Xi Măng] FPS thấp, tự động giảm cap để ổn định.")
		elseif currentFPS > 100 then
			setfpscap(165)
		end
		lastFPS = currentFPS
	end
end)

--==============================================================
-- ♻️ AUTO RELOAD AFTER RESPAWN
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Bật lại hệ thống khi respawn")
Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(2)
	for _, v in pairs(workspace:GetDescendants()) do
		DeepClean(v)
	end
end)

--==============================================================
-- 🌐 NETWORK BOOST
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Tăng tốc mạng và giảm lag network")
pcall(function()
	game:GetService("NetworkSettings").PhysicsSendRate = 30
end)

--==============================================================
-- 🧩 ANTI-LAG HEARTBEAT
--==============================================================
step += 1; LoadingStep(step, totalSteps, "Kích hoạt AntiLag Heartbeat")
RunService.Heartbeat:Connect(function()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

--==============================================================
-- 🏁 FINALIZATION
--==============================================================
Notify("✅ Xi Măng Apocalypse™", "Tất cả hệ thống đã được tối ưu hoàn tất!", 5)
print("\n⚙️ Xi Măng Apocalypse™ v9.0 Loaded Successfully!\n")
print("Lag đã bị xóa khỏi vũ trụ. Chào mừng đến thế giới 120 FPS 🌈")
