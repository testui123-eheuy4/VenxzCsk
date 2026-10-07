--============================================================
-- SERVICES & VARIABLES
--============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Global State Control
_G.Steal  = false
_G.Place  = false
_G.Open   = false
_G.Equip  = false

local SelectedRarity = "==Select Rarity=="
local Rarities = {
    "Common", "Uncommon", "Rare", "Epic", 
    "Legendary", "Mythic", "Cosmic", "Secret", 
    "Eternal", "Divine"
}

-- Find Player Plot
local MyPlot = nil
local function FindMyPlot()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("Plot Building") then
            local plotSign = obj:FindFirstChild("floor") and obj.floor:FindFirstChild("PlotSign")
            local avatar = plotSign and plotSign:FindFirstChild("Avatar")
            if avatar and avatar.Image:find(tostring(LocalPlayer.UserId)) then
                MyPlot = obj
                break
            end
        end
    end
end
FindMyPlot()

--============================================================
-- RAYFIELD UI SETUP
--============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Venxz CSK | Steal From The Rich",
    Icon = 0,
    LoadingTitle = "Venxz CSK Loading...",
    LoadingSubtitle = "by Venxz CSK",
    Theme = "Default",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "VenxzCSKConfig",
        FileName = "StealFromRich"
    },

    Discord = {
        Enabled = true,
        Invite = "GC5M2tpbG9",
        RememberJoins = true
    },

    KeySystem = false
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local InfoTab = Window:CreateTab("Info", 4483362458)

--============================================================
-- MAIN TAB ELEMENTS
--============================================================
MainTab:CreateSection("Auto Steal Settings")

MainTab:CreateDropdown({
    Name = "Rarity Minimum",
    Options = Rarities,
    CurrentOption = {SelectedRarity},
    MultipleOptions = false,
    Flag = "RarityMinDrop",
    Callback = function(Option)
        SelectedRarity = Option[1]
    end,
})

MainTab:CreateToggle({
    Name = "Auto Steal",
    CurrentValue = _G.Steal,
    Flag = "AutoStealToggle",
    Callback = function(Value)
        _G.Steal = Value
    end,
})

MainTab:CreateSection("Plot Automation")

MainTab:CreateToggle({
    Name = "Auto Place",
    CurrentValue = _G.Place,
    Flag = "AutoPlaceToggle",
    Callback = function(Value)
        _G.Place = Value
    end,
})

MainTab:CreateToggle({
    Name = "Auto Open",
    CurrentValue = _G.Open,
    Flag = "AutoOpenToggle",
    Callback = function(Value)
        _G.Open = Value
    end,
})

MainTab:CreateToggle({
    Name = "Equip Best",
    CurrentValue = _G.Equip,
    Flag = "EquipBestToggle",
    Callback = function(Value)
        _G.Equip = Value
    end,
})

--============================================================
-- INFO TAB ELEMENTS
--============================================================
InfoTab:CreateSection("Credits & Community")
InfoTab:CreateLabel("Script Hub: Venxz CSK")
InfoTab:CreateLabel("Game: Steal From The Rich")

InfoTab:CreateButton({
    Name = "Copy Discord Official Venxz CSK",
    Callback = function()
        setclipboard("https://discord.gg/GC5M2tpbG9")
        Rayfield:Notify({
            Title = "Venxz CSK",
            Content = "Link Discord berhasil disalin ke clipboard!",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

--============================================================
-- AUTOMATION LOOPS
--============================================================

-- Auto Steal Loop
task.spawn(function()
    while true do
        task.wait(0.2)
        if _G.Steal and SelectedRarity ~= "==Select Rarity==" then
            pcall(function()
                local targetIdx = table.find(Rarities, SelectedRarity)
                if not targetIdx then return end

                local highestTierIdx = 0
                local targetPrompt = nil

                local cratesFolder = Workspace:FindFirstChild("Crates")
                if cratesFolder then
                    for _, desc in ipairs(cratesFolder:GetDescendants()) do
                        if desc.Name == "ProximityPrompt" and desc.Parent and desc.Parent.Parent then
                            local crateModel = desc.Parent.Parent
                            local tier = crateModel:GetAttribute("CrateTier")
                            local tierIdx = table.find(Rarities, tier)

                            if tierIdx and tierIdx >= targetIdx then
                                if tierIdx > highestTierIdx then
                                    highestTierIdx = tierIdx
                                    targetPrompt = desc
                                end
                            end
                        end
                    end
                end

                if targetPrompt and LocalPlayer.Character then
                    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and targetPrompt.Parent then
                        -- Teleport Ke Crate
                        hrp.CFrame = targetPrompt.Parent.CFrame
                        task.wait(1.2)
                        fireproximityprompt(targetPrompt)
                        task.wait(0.2)

                        -- Teleport Kembali ke Safe Zone
                        local safeZone = Workspace:FindFirstChild("Steal Map") and Workspace["Steal Map"].Lobby:FindFirstChild("safe zone")
                        if safeZone then
                            hrp.CFrame = safeZone.CFrame * CFrame.new(0, 20, 0)
                        end
                        task.wait(1)
                    end
                end
            end)
        end
    end
end)

-- Auto Place Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.Place then
            pcall(function()
                if not MyPlot then FindMyPlot() end
                if not MyPlot or not MyPlot:FindFirstChild("floor") then return end

                local char = LocalPlayer.Character
                if not char then return end

                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp then return end

                -- Cari Crate di Character/Backpack
                local crateTool = nil
                for _, item in ipairs(char:GetChildren()) do
                    if item:IsA("Tool") and item.Name:find("Crate") then
                        crateTool = item
                        break
                    end
                end

                if not crateTool then
                    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
                        if item:IsA("Tool") and item.Name:find("Crate") then
                            crateTool = item
                            break
                        end
                    end
                end

                if crateTool then
                    if crateTool.Parent == LocalPlayer.Backpack then
                        hum:EquipTool(crateTool)
                        task.wait(0.2)
                    end

                    -- Teleport Ke Atas Floor Plot
                    local floor = MyPlot.floor
                    hrp.CFrame = CFrame.new(floor.Position) * CFrame.new(0, 5, 0)
                    task.wait(0.2)

                    -- Hitung Posisi Acak Di Floor
                    local size = floor.Size
                    local randomX = (math.random() * size.X) - (size.X / 2)
                    local randomZ = (math.random() * size.Z) - (size.Z / 2)
                    local worldPos = floor.CFrame:PointToWorldSpace(Vector3.new(randomX, 0, randomZ))
                    local placePos = Vector3.new(worldPos.X, 2.7, worldPos.Z)

                    -- Trigger Remote Place
                    local rePlace = ReplicatedStorage:FindFirstChild("re_PLACE_AT")
                    if rePlace then
                        rePlace:FireServer(placePos, 0)
                    end
                    task.wait(0.2)
                end
            end)
        end
    end
end)

-- Auto Open Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.Open then
            pcall(function()
                if not MyPlot then FindMyPlot() end
                if not MyPlot or not MyPlot:FindFirstChild("floor") then return end

                for _, desc in ipairs(MyPlot.floor:GetDescendants()) do
                    if desc.Name == "ProximityPrompt" and desc.Enabled then
                        if desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name == "AppraisingCrate" then
                            local char = LocalPlayer.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hrp.CFrame = desc.Parent.CFrame
                                fireproximityprompt(desc)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Equip Best Loop
task.spawn(function()
    while true do
        task.wait(2)
        if _G.Equip then
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                local equipBestBtn = playerGui and playerGui.Gui.Main.Frames.Items:FindFirstChild("EquipBest")
                
                if equipBestBtn and getconnections then
                    for _, conn in ipairs(getconnections(equipBestBtn.Activated)) do
                        conn:Fire()
                        task.wait(0.2)
                    end
                end
            end)
        end
    end
end)
