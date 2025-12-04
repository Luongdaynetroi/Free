local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Tạo Part đứng dưới chân
local function createWaterPlatform()
    local platform = Instance.new("Part")
    platform.Name = "WaterPlatform"
    platform.Size = Vector3.new(6, 1, 6)
    platform.Transparency = 1 -- 0 để thấy platform
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.ForceField
    platform.Color = Color3.fromRGB(0, 255, 255)
    platform.Parent = workspace
    return platform
end

-- Khởi tạo platform
local waterPlatform = createWaterPlatform()

-- Cập nhật vị trí platform theo nhân vật
RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        if pos.Y <= 5 then -- Kiểm tra nếu ở gần mặt nước
            waterPlatform.Position = Vector3.new(pos.X, pos.Y -9, pos.Z)
        else
            waterPlatform.Position = Vector3.new(9999, -500, 9999) -- Ẩn platform khi không cần
        end
    end
end)
