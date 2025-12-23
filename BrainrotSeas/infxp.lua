for uuid, inventory_data in (require(game:GetService("ReplicatedStorage").Modules.DataController):GetPlayerDataAsync().Inventory.InventoryData) do
    if (inventory_data.ItemName == "Fist") then
        game:GetService("ReplicatedStorage").Remotes.MasteryProgressionService.Upgrade:FireServer(uuid, { ["Intermediate Book"] = -1/0 });
    end
end
