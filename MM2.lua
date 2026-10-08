--[[============================================================================
    VENXZ CSK  |  MM2 (Murder Mystery 2)
    Menu    : Rayfield  (https://sirius.menu/rayfield)
    Discord : https://discord.gg/GC5M2tpbG9

    File order
      1. Services, branding and state
      2. Window Rayfield
      3. Element features
      4. Helpers and the main feature functions
      5. Boot

    Ported from the Rayfield build. Every feature is carried over; the UI layer is
    the only thing that changed.
============================================================================]]--

--[[==============================================================================
    1.  SERVICES, BRANDING AND STATE
==============================================================================]]--
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

---Everything that carries the watermark lives in this one table.
local Brand = {
    Name = "Venxz CSK",
    Title = "Venxz CSK | MM2",
    Author = "by Venxz",
    Tag = "MM2",
    Discord = "https://discord.gg/GC5M2tpbG9",
    DiscordInvite = "GC5M2tpbG9",
    Logo = 106073659711836,
    ConfigFolder = "Venxz CSK",
    ConfigFile = "MM2",
    ---Paste your own Discord webhook here. Left empty, nothing is ever sent.
    Webhook = "",
}

---Execution report, the way the old build did it. Silent while Webhook is empty,
---and it no longer dies when the executor has no request function.
local function ReportExecution()
    if Brand.Webhook == "" then return end

    local send = (type(request) == "function" and request) or (type(http_request) == "function" and http_request)
        or (type(syn) == "table" and syn.request)
    if type(send) ~= "function" then return end

    local gameName = "Unknown"
    pcall(function() gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)

    local payload = {
        embeds = {{
            title = "New Script Execute",
            color = 3447003,
            fields = {
                { name = "User", value = player.Name, inline = false },
                { name = "Hub", value = Brand.Name, inline = false },
                { name = "Game", value = gameName .. " (" .. game.PlaceId .. ")", inline = false },
                { name = "Time", value = os.date("%A %d %B %Y %X"), inline = false },
            },
            footer = { text = Brand.Name },
        }},
    }

    pcall(function()
        send({
            Url = Brand.Webhook,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload),
        })
    end)
end

ReportExecution()

--[[--------------------------------------------------------------------------
    runtime state
--------------------------------------------------------------------------]]--
-- ESP
local espPlayerEnabled = false      -- Enable ESP Player
local gunDropEnabled = false        -- Enable ESP Sheriff Gun
local roleESP = { murder = false, sheriff = false, innocent = false }
local espObjects = {}

-- teleport
local autoGunDrop = false
local teleporting = false
local selectedPlayer = nil          -- Visuals > Player Select
local selectedPlayerTP = nil        -- Teleport > Select Player

-- sheriff
local lockEnabled = false
local circleRadius = 200
local autoShoot = false

-- fling
local touchKick = false
local flingAll = false

-- movement
local walkSpeed = 16
local jumpPower = 50
local infJump = false
local walkThrough = false

-- hitbox and mass kill
local hitboxEnabled = false
local hitboxSize = 12
local circlePart = nil
local killAll = false
local autoKill = false

-- auto win
local autoWin = false
local undergroundPos = nil

-- coin farm
local flying = false
local autoReset = false
local flyMode = "normal"
local flySpeed = 16
local collectedCoins = {}
local startedCollecting = false

-- anti afk
local AntiAFKConnection = nil

-- floating mini buttons
local floatingGunButton = nil
local floatingShootButton = nil

-- instances built further down
local fovGui, fovCircle, fovStroke, fovCorner       -- aim lock circle
local playerDropdown, playerDropdownTP              -- dropdown handles
local antiAfkToggle                                 -- switched on at the boot

---Rayfield hands a dropdown selection back as a table handed a string.
local function Pick(value)
    if type(value) == "table" then return value[1] end
    return value
end

--[[--------------------------------------------------------------------------
    feature functions, defined in section 4
--------------------------------------------------------------------------]]--
local applyStrokeEffect
local hasItem, getRole, getColor, getText, findSheriff, findMurderer, findKnifePlayer
local getPlayerNames, getPlayerByName, getCharacter
local removeESP, createESP, updatePlayers, findGunDrop, updateGunDrop
local clearESPObjects, createESPRole, updateESPRole
local teleportTo, tpToSheriff, tpToMurderer, tpToGunDrop, tpToLobby, tpToMap, tpToSelectedPlayer
local getMurdererFrontCFrame, getClosestPlayerFrontCFrame
local createKnifeButton, createGunButton
local getMurdererTarget, shootMurderer, isInCircle
local createFloatingGunButton, removeFloatingGunButton, createFloatingShootButton
local walkFling, flingPlayer, flingSheriff, flingMurderer, flingSelected
local createCirclePart, pullPlayers
local hasGun, hasKnife
local noclipLoop, restoreChar, getNearestCoin, flyToCoin
local refreshPlayerDropdowns

-- setters the controls in section 3 call
local setEspPlayers, setEspGunDrop, setRoleESP, setNoclipFriends
local setAutoGunDrop, setMiniGunButton, setAutoShoot, setAimLock, setFov
local setTouchFling, setFlingAll
local setWalkSpeed, setJumpPower, setInfJump
local setHitbox, setHitboxSize, setKillAll, setAutoKill
local setAutoWin, setCoinFarm, setAutoReset, setFlySpeed, setFlyMode
local setAntiAfk, copyDiscordInvite

--[[==============================================================================
    2.  WINDOW RAYFIELD
        Library load, the window itself, the floating watermark and the tabs.
==============================================================================]]--
local Rayfield
do
    local lastErr
    for attempt = 1, 4 do
        local ok, lib = pcall(function()
            return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
        end)
        if ok and type(lib) == "table" and type(lib.CreateWindow) == "function" then
            Rayfield = lib
            break
        end
        lastErr = lib
        if attempt < 4 then task.wait(2) end
    end
    if not Rayfield then
        error("[" .. Brand.Name .. "] Rayfield failed to load after 4 tries. Re-execute. Last error: " .. tostring(lastErr), 0)
    end
end

local Window = Rayfield:CreateWindow({
    Name = Brand.Title,
    Icon = Brand.Logo,
    LoadingTitle = Brand.Name,
    LoadingSubtitle = Brand.Tag .. "  " .. Brand.Author,
    Theme = "Default",

    DisableRayfieldPrompts = true,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = Brand.ConfigFolder,
        FileName = Brand.ConfigFile,
    },

    ---Rayfield opens the invite in the desktop Discord client once per player.
    Discord = {
        Enabled = true,
        Invite = Brand.DiscordInvite, -- the code only, no discord.gg/
        RememberJoins = true,
    },

    KeySystem = false,
})

---The Tag("MM2"); Rayfield has no window tag, so it rides in the title.
local function BuildWatermark()
    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "VenxzLogoContainer"
    logoContainer.Size = UDim2.new(0, 50, 0, 50)
    logoContainer.Position = UDim2.new(0, 10, 0, 10)
    logoContainer.BackgroundTransparency = 1
    logoContainer.ZIndex = 999
    logoContainer.Parent = game:GetService("CoreGui")

    local logoImage = Instance.new("ImageLabel")
    logoImage.Name = "VenxzLogo"
    logoImage.Size = UDim2.new(1, 0, 1, 0)
    logoImage.BackgroundTransparency = 1
    logoImage.Image = "rbxassetid://" .. Brand.Logo
    logoImage.ScaleType = Enum.ScaleType.Fit
    logoImage.Parent = logoContainer

    local logoStroke = Instance.new("UIStroke")
    logoStroke.Color = Color3.fromRGB(255, 255, 255)
    logoStroke.Thickness = 2
    logoStroke.Transparency = 0.5
    logoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    logoStroke.Parent = logoImage

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 12)
    logoCorner.Parent = logoImage

    task.spawn(function()
        while logoImage and logoImage.Parent do
            TweenService:Create(logoStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.2 }):Play()
            task.wait(1.5)
            TweenService:Create(logoStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.8 }):Play()
            task.wait(1.5)
        end
    end)
end

BuildWatermark()

---Shared parent of the draggable knife / ammo mini buttons.
local FloatingGui = game:GetService("CoreGui"):FindFirstChild("WeaponTeleportGui")
if not FloatingGui then
    FloatingGui = Instance.new("ScreenGui")
    FloatingGui.Name = "WeaponTeleportGui"
    FloatingGui.ResetOnSpawn = false
    FloatingGui.Parent = game:GetService("CoreGui")
end

local GeneralTab = Window:CreateTab("General", "settings")
local EspTab = Window:CreateTab("ESP", "eye")
local TeleportTab = Window:CreateTab("Teleport", "navigation")
local VisualsTab = Window:CreateTab("Visuals", "skull")
local MurdererTab = Window:CreateTab("Murderer", "sword")
local CoinsTab = Window:CreateTab("Coins", "coins")
local SheriffTab = Window:CreateTab("Sheriff", "sword")

--[[==============================================================================
    3.  ELEMENT FEATURES
        Every control, grouped per tab. Callbacks are one liners: the work itself
        lives in section 4.
==============================================================================]]--

--- Built as one function on purpose: the callbacks below point at the feature
--- functions in section 4, and those do not exist yet while this block is read.
--- The boot calls BuildElements() once, after section 4 has run.
local function BuildElements()
    --[[-- General --]]--
    GeneralTab:CreateSection("Information")
    GeneralTab:CreateParagraph({
        Title = Brand.Title,
        Content = "Murder Mystery 2 hub, " .. Brand.Author .. ".\nSettings save themselves, so the next execute starts where you left off.",
    })

    GeneralTab:CreateSection("Discord")
    GeneralTab:CreateLabel(Brand.Discord)
    GeneralTab:CreateButton({ Name = "Copy Discord Invite", Callback = copyDiscordInvite })

    GeneralTab:CreateSection("Sheriff Gun")
    GeneralTab:CreateToggle({
        Name = "Auto TP To Gun",
        CurrentValue = false,
        Flag = "AutoTpToGun",
        Callback = setAutoGunDrop,
    })
    GeneralTab:CreateToggle({
        Name = "Enable TP To Sheriff Gun (Mini Button)",
        CurrentValue = false,
        Flag = "MiniGunButton",
        Callback = setMiniGunButton,
    })
    GeneralTab:CreateToggle({
        Name = "Enable Auto Shoot Murderer",
        CurrentValue = false,
        Flag = "AutoShootMurderer",
        Callback = setAutoShoot,
    })

    GeneralTab:CreateSection("Movement")
    GeneralTab:CreateSlider({
        Name = "Walk Speed",
        Range = { 16, 200 },
        Increment = 1,
        CurrentValue = 16,
        Flag = "WalkSpeed",
        Callback = setWalkSpeed,
    })
    GeneralTab:CreateSlider({
        Name = "Jump Power",
        Range = { 50, 200 },
        Increment = 1,
        CurrentValue = 50,
        Flag = "JumpPower",
        Callback = setJumpPower,
    })
    GeneralTab:CreateToggle({
        Name = "Infinite Jump",
        CurrentValue = false,
        Flag = "InfiniteJump",
        Callback = setInfJump,
    })

    --[[-- ESP --]]--
    EspTab:CreateSection("Role ESP")
    EspTab:CreateToggle({
        Name = "Enable ESP Murderer",
        CurrentValue = false,
        Flag = "EspMurderer",
        Callback = function(value) setRoleESP("murder", value) end,
    })
    EspTab:CreateToggle({
        Name = "Enable ESP Sheriff",
        CurrentValue = false,
        Flag = "EspSheriff",
        Callback = function(value) setRoleESP("sheriff", value) end,
    })
    EspTab:CreateToggle({
        Name = "Enable ESP Innocents",
        CurrentValue = false,
        Flag = "EspInnocents",
        Callback = function(value) setRoleESP("innocent", value) end,
    })

    EspTab:CreateSection("Player And Drop ESP")
    EspTab:CreateToggle({
        Name = "Enable ESP Player",
        CurrentValue = false,
        Flag = "EspPlayer",
        Callback = setEspPlayers,
    })
    EspTab:CreateToggle({
        Name = "Enable ESP Sheriff Gun",
        CurrentValue = false,
        Flag = "EspSheriffGun",
        Callback = setEspGunDrop,
    })

    EspTab:CreateSection("Collision")
    EspTab:CreateToggle({
        Name = "Noclip Friends",
        CurrentValue = false,
        Flag = "NoclipFriends",
        Callback = setNoclipFriends,
    })

    --[[-- Teleport --]]--
    TeleportTab:CreateSection("Roles")
    TeleportTab:CreateButton({ Name = "TP To Sheriff", Callback = tpToSheriff })
    TeleportTab:CreateButton({ Name = "TP To Murderer", Callback = tpToMurderer })

    TeleportTab:CreateSection("World")
    TeleportTab:CreateButton({ Name = "TP To Sheriff Gun", Callback = tpToGunDrop })
    TeleportTab:CreateButton({ Name = "TP To Lobby", Callback = tpToLobby })
    TeleportTab:CreateButton({ Name = "TP To Map", Callback = tpToMap })

    TeleportTab:CreateSection("Players")
    playerDropdownTP = TeleportTab:CreateDropdown({
        Name = "Select Player",
        Options = getPlayerNames(),
        CurrentOption = {},
        MultipleOptions = false,
        Callback = function(value) selectedPlayerTP = Pick(value) end,
    })
    TeleportTab:CreateButton({ Name = "TP To Selected Player", Callback = tpToSelectedPlayer })

    --[[-- Visuals --]]--
    VisualsTab:CreateSection("Target")
    playerDropdown = VisualsTab:CreateDropdown({
        Name = "Player Select",
        Options = getPlayerNames(),
        CurrentOption = {},
        MultipleOptions = false,
        Callback = function(value) selectedPlayer = getPlayerByName(Pick(value)) end,
    })

    VisualsTab:CreateSection("Fling")
    VisualsTab:CreateButton({ Name = "Sheriff Fling", Callback = flingSheriff })
    VisualsTab:CreateButton({ Name = "Murderer Fling", Callback = flingMurderer })
    VisualsTab:CreateButton({ Name = "Selected Fling Player", Callback = flingSelected })
    VisualsTab:CreateToggle({
        Name = "Fling Player",
        CurrentValue = false,
        Flag = "FlingPlayer",
        Callback = setTouchFling,
    })
    VisualsTab:CreateToggle({
        Name = "Fling All Player",
        CurrentValue = false,
        Flag = "FlingAllPlayer",
        Callback = setFlingAll,
    })

    --[[-- Murderer --]]--
    MurdererTab:CreateSection("Knife")
    MurdererTab:CreateParagraph({
        Title = "TP Knife",
        Content = "Spawns a draggable Throwing Knife button that fires the knife at the closest player in front of you.",
    })
    MurdererTab:CreateButton({ Name = "TP Knife To Player", Callback = createKnifeButton })

    MurdererTab:CreateSection("Hitbox")
    MurdererTab:CreateToggle({
        Name = "Enable Hitbox",
        CurrentValue = false,
        Flag = "EnableHitbox",
        Callback = setHitbox,
    })
    MurdererTab:CreateSlider({
        Name = "Hitbox Size",
        Range = { 6, 150 },
        Increment = 1,
        CurrentValue = 12,
        Flag = "HitboxSize",
        Callback = setHitboxSize,
    })

    MurdererTab:CreateSection("Mass Kill")
    MurdererTab:CreateToggle({
        Name = "Kill All Player",
        CurrentValue = false,
        Flag = "KillAllPlayer",
        Callback = setKillAll,
    })
    MurdererTab:CreateToggle({
        Name = "Enable Auto Kill All Player",
        CurrentValue = false,
        Flag = "AutoKillAllPlayer",
        Callback = setAutoKill,
    })

    --[[-- Coins --]]--
    CoinsTab:CreateSection("Auto Win")
    CoinsTab:CreateToggle({
        Name = "Enable Auto Win",
        CurrentValue = false,
        Flag = "AutoWin",
        Callback = setAutoWin,
    })

    CoinsTab:CreateSection("Coin Farm")
    CoinsTab:CreateParagraph({
        Title = "Warning",
        Content = "We recommend setting it to 19. Exceeding this risks a ban.",
    })
    CoinsTab:CreateSlider({
        Name = "Speed",
        Range = { 1, 26 },
        Increment = 1,
        CurrentValue = 16,
        Flag = "CoinFarmSpeed",
        Callback = setFlySpeed,
    })
    CoinsTab:CreateDropdown({
        Name = "Fly Mode",
        Options = { "normal", "down" },
        CurrentOption = "normal",
        MultipleOptions = false,
        Flag = "FlyMode",
        Callback = setFlyMode,
    })
    CoinsTab:CreateToggle({
        Name = "Reset When Coins Run Out",
        CurrentValue = false,
        Flag = "ResetWhenCoinsRunOut",
        Callback = setAutoReset,
    })
    CoinsTab:CreateToggle({
        Name = "Enable Auto Farm Coins",
        CurrentValue = false,
        Flag = "AutoFarmCoins",
        Callback = setCoinFarm,
    })

    CoinsTab:CreateSection("Session")
    antiAfkToggle = CoinsTab:CreateToggle({
        Name = "Enable Anti AFK",
        CurrentValue = true,
        Flag = "AntiAfk",
        Callback = setAntiAfk,
    })

    --[[-- Sheriff --]]--
    SheriffTab:CreateSection("Ammunition")
    SheriffTab:CreateParagraph({
        Title = "TP Ammunition",
        Content = "Spawns a draggable Shooting button that fires your gun at the murderer.",
    })
    SheriffTab:CreateButton({ Name = "TP Ammo To Murderer", Callback = createGunButton })

    SheriffTab:CreateSection("Aim")
    SheriffTab:CreateToggle({
        Name = "Enable Aim Lock Murderer",
        CurrentValue = false,
        Flag = "AimLockMurderer",
        Callback = setAimLock,
    })
    SheriffTab:CreateSlider({
        Name = "FOV Circle",
        Range = { 100, 600 },
        Increment = 1,
        CurrentValue = 200,
        Flag = "FovCircle",
        Callback = setFov,
    })

    SheriffTab:CreateSection("Shoot")
    SheriffTab:CreateButton({ Name = "Shoot Murderer", Callback = shootMurderer })
    SheriffTab:CreateButton({ Name = "Shoot Murderer (Mini Button)", Callback = createFloatingShootButton })
end

--[[==============================================================================
    4.  HELPERS AND THE MAIN FEATURE FUNCTIONS
        Grouped per feature: helpers first, then the setter the control calls,
        then the loop or connection that does the repeating work.
==============================================================================]]--

--[[-- shared chrome --]]--
function applyStrokeEffect(target)
    task.spawn(function()
        while target and target.Parent do
            TweenService:Create(target, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Color = Color3.fromRGB(255, 255, 255) }):Play()
            task.wait(0.8)
            if not target.Parent then break end
            TweenService:Create(target, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Color = Color3.fromRGB(200, 200, 200) }):Play()
            task.wait(0.8)
        end
    end)
end

function copyDiscordInvite()
    local copy = setclipboard or toclipboard
    if type(copy) ~= "function" then
        Rayfield:Notify({ Title = Brand.Name, Content = Brand.Discord, Duration = 8 })
        return
    end
    pcall(copy, Brand.Discord)
    Rayfield:Notify({ Title = Brand.Name, Content = "Discord invite copied: " .. Brand.Discord, Duration = 5 })
end

--[[-- roles, players and items --]]--
function hasItem(plr, item)
    local backpack = plr:FindFirstChild("Backpack")
    local char = plr.Character
    if backpack and backpack:FindFirstChild(item) then return true end
    if char and char:FindFirstChild(item) then return true end
    return false
end

function getRole(plr)
    if hasItem(plr, "Gun") then return "Gun" end
    if hasItem(plr, "Knife") then return "Knife" end
    return "Good"
end

function getColor(role)
    if role == "Gun" then return Color3.fromRGB(0, 150, 255)
    elseif role == "Knife" then return Color3.fromRGB(255, 0, 0)
    elseif role == "Good" then return Color3.fromRGB(0, 255, 0) end
end

function getText(role)
    if role == "Gun" then return "Sheriff"
    elseif role == "Knife" then return "Murderer"
    elseif role == "Good" then return "Innocents" end
end

function findSheriff()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and hasItem(plr, "Gun") then return plr end
    end
end

function findMurderer()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and hasItem(plr, "Knife") then return plr end
    end
end

---Auto Win only trusts a knife that is already in the hand, not one in the backpack.
function findKnifePlayer()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char and char:FindFirstChild("Knife") then return plr end
        end
    end
end

function getPlayerNames()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(list, plr.Name) end
    end
    return list
end

function getPlayerByName(name)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Name == name then return plr end
    end
end

function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

function hasGun()
    local char = getCharacter()
    if char:FindFirstChild("Gun") then return true end
    if player.Backpack:FindFirstChild("Gun") then return true end
    return false
end

function hasKnife()
    local char = getCharacter()
    if char:FindFirstChild("Knife") then return true end
    if player.Backpack:FindFirstChild("Knife") then return true end
    return false
end

--[[-- ESP: highlight and name tag on every player --]]--
function removeESP(char)
    local esp = char:FindFirstChild("RoleESP")
    if esp then esp:Destroy() end
    local tag = char:FindFirstChild("RoleTag")
    if tag then tag:Destroy() end
end

function createESP(plr)
    local char = plr.Character
    if not char then return end
    removeESP(char)
    local role = getRole(plr)
    local color = getColor(role)
    local text = getText(role)

    local highlight = Instance.new("Highlight")
    highlight.Name = "RoleESP"
    highlight.FillTransparency = 1
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RoleTag"
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = char:FindFirstChild("Head")
    billboard.Parent = char

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Text = text
    label.TextColor3 = color
    label.Parent = billboard
end

function updatePlayers()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            if espPlayerEnabled then createESP(plr) else removeESP(plr.Character) end
        end
    end
end

function setEspPlayers(state)
    espPlayerEnabled = state
    updatePlayers()
end

--[[-- ESP: the dropped sheriff gun --]]--
function findGunDrop()
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "GunDrop" and v:IsA("BasePart") then
            return v
        end
    end
end

function updateGunDrop()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            if gunDropEnabled then
                if not obj:FindFirstChild("GunDropESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "GunDropESP"
                    hl.FillTransparency = 1
                    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = obj

                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "GunDropText"
                    billboard.Size = UDim2.new(0, 200, 0, 40)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = obj
                    billboard.Parent = obj

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextScaled = true
                    label.Text = "Sheriff Gun"
                    label.TextColor3 = Color3.fromRGB(255, 255, 0)
                    label.Parent = billboard
                end
            else
                local hl = obj:FindFirstChild("GunDropESP")
                if hl then hl:Destroy() end
                local text = obj:FindFirstChild("GunDropText")
                if text then text:Destroy() end
            end
        end
    end
end

function setEspGunDrop(state)
    gunDropEnabled = state
    updateGunDrop()
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if espPlayerEnabled then updatePlayers() end
        if gunDropEnabled then updateGunDrop() end
    end
end)

--[[-- ESP: role highlights kept in one list so they can all be cleared --]]--
function clearESPObjects()
    for _, v in pairs(espObjects) do
        if v then v:Destroy() end
    end
    espObjects = {}
end

function createESPRole(plr, color, text)
    if not plr.Character then return end
    local char = plr.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0
    highlight.Parent = char

    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 120, 0, 40)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Parent = root

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Text = text
    label.Parent = bill

    table.insert(espObjects, highlight)
    table.insert(espObjects, bill)
end

function updateESPRole()
    clearESPObjects()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            local backpack = plr:FindFirstChild("Backpack")
            if char then
                local holdsKnife = char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife"))
                local holdsGun = char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))
                if roleESP.murder and holdsKnife then
                    createESPRole(plr, Color3.fromRGB(255, 0, 0), "Murderer")
                end
                if roleESP.sheriff and holdsGun then
                    createESPRole(plr, Color3.fromRGB(0, 120, 255), "Sheriff")
                end
                if roleESP.innocent and not holdsKnife and not holdsGun then
                    createESPRole(plr, Color3.fromRGB(0, 255, 120), "Innocents")
                end
            end
        end
    end
end

function setRoleESP(which, state)
    roleESP[which] = state
    updateESPRole()
end

task.spawn(function()
    while true do
        task.wait(1)
        if roleESP.murder or roleESP.sheriff or roleESP.innocent then
            updateESPRole()
        end
    end
end)

--[[-- teleport --]]--
function teleportTo(plr)
    if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = player.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            myChar.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end
end

function tpToSheriff()
    teleportTo(findSheriff())
end

function tpToMurderer()
    teleportTo(findMurderer())
end

---Touches the drop so the gun is picked up, then steps back to where you were.
function tpToGunDrop()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local gunDrop = workspace:FindFirstChild("GunDrop", true)
    if gunDrop then
        local oldPos = root.CFrame
        root.CFrame = gunDrop.CFrame * CFrame.new(0, 0, 0)
        task.wait(0.5)
        if root then root.CFrame = oldPos end
    end
end

function tpToLobby()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local lobby = workspace:FindFirstChild("Lobby")
    if lobby then
        local part
        if lobby:IsA("Model") then
            part = lobby.PrimaryPart or lobby:FindFirstChildWhichIsA("BasePart")
        elseif lobby:IsA("BasePart") then
            part = lobby
        end
        if part then root.CFrame = part.CFrame + Vector3.new(0, 3, 0) end
    end
end

function tpToMap()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local spawnPart = workspace:FindFirstChild("Spawn", true)
    if spawnPart and spawnPart:IsA("BasePart") then
        root.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
    end
end

function tpToSelectedPlayer()
    if not selectedPlayerTP then return end
    local target = Players:FindFirstChild(selectedPlayerTP)
    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = player.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            myChar.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(2, 0, 0)
        end
    end
end

function setAutoGunDrop(state)
    autoGunDrop = state
end

RunService.Heartbeat:Connect(function()
    if not autoGunDrop then return end
    if teleporting then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local gunDrop = findGunDrop()
    if gunDrop then
        teleporting = true
        local oldPos = root.CFrame
        root.CFrame = gunDrop.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.5)
        if root then root.CFrame = oldPos end
        task.wait(0.3)
        teleporting = false
    end
end)

--[[-- knife and ammo mini buttons --]]--
function getMurdererFrontCFrame()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local knife = p:FindFirstChild("Backpack") and p.Backpack:FindFirstChild("Knife") or p.Character and p.Character:FindFirstChild("Knife")
            if knife and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                return hrp.CFrame + (hrp.CFrame.LookVector * 2)
            end
        end
    end
    return nil
end

function getClosestPlayerFrontCFrame()
    local closestCharacter = nil
    local shortestDistance = math.huge
    local myChar = player.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil, nil end
    local myHRP = myChar.HumanoidRootPart
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            if p.Character.Humanoid.Health > 0 then
                local targetHRP = p.Character.HumanoidRootPart
                local distance = (myHRP.Position - targetHRP.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestCharacter = p.Character
                end
            end
        end
    end
    if closestCharacter then
        local hrp = closestCharacter.HumanoidRootPart
        return hrp.CFrame + (hrp.CFrame.LookVector * 2), hrp.CFrame
    end
    return nil, nil
end

---Shared build for the two draggable mini buttons.
local function makeMiniButton(name, text, position, strokeColor, onClick)
    if FloatingGui:FindFirstChild(name) then return FloatingGui:FindFirstChild(name) end

    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 140, 0, 52)
    btn.Position = position
    btn.AnchorPoint = Vector2.new(0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
    btn.BackgroundTransparency = 0.35
    btn.TextColor3 = Color3.fromRGB(0, 70, 150)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = FloatingGui
    btn.Active = true
    btn.Draggable = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 18)

    local miniStroke = Instance.new("UIStroke", btn)
    miniStroke.Thickness = 2.5
    miniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    miniStroke.Color = strokeColor
    applyStrokeEffect(miniStroke)

    btn.MouseButton1Click:Connect(function() onClick(btn, text) end)
    return btn
end

function createKnifeButton()
    makeMiniButton("BtnKnifeTeleport", "Throwing Knife", UDim2.new(0.5, 10, 0.87, 0), Color3.fromRGB(255, 50, 50), function(btn, idleText)
        local knife = player.Character and player.Character:FindFirstChild("Knife") or player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Knife")
        if knife and knife:FindFirstChild("Events") and knife.Events:FindFirstChild("KnifeThrown") then
            local frontTarget, exactTarget = getClosestPlayerFrontCFrame()
            if frontTarget and exactTarget then
                local args = { frontTarget, exactTarget }
                knife.Events.KnifeThrown:FireServer(unpack(args))
            else
                btn.Text = "Target Not Found"
                task.wait(1)
                btn.Text = idleText
            end
        else
            btn.Text = "No Knife"
            task.wait(1)
            btn.Text = idleText
        end
    end)
end

function createGunButton()
    makeMiniButton("BtnGunTeleport", "Shooting", UDim2.new(0.5, -150, 0.87, 0), Color3.fromRGB(0, 120, 255), function(btn, idleText)
        local gun = player.Character and player.Character:FindFirstChild("Gun") or player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("Gun")
        if gun and gun:FindFirstChild("Shoot") then
            local targetCFrame = getMurdererFrontCFrame()
            if targetCFrame then
                local myCFrame = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.CFrame or CFrame.new()
                local args = { targetCFrame, myCFrame }
                gun.Shoot:FireServer(unpack(args))
            else
                btn.Text = "Murderer Not Found"
                task.wait(1)
                btn.Text = idleText
            end
        else
            btn.Text = "No Gun"
            task.wait(1)
            btn.Text = idleText
        end
    end)
end

--[[-- aim lock --]]--
fovGui = Instance.new("ScreenGui")
fovGui.ResetOnSpawn = false
fovGui.Parent = player.PlayerGui

fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, circleRadius, 0, circleRadius)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = fovGui

fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 0, 0)
fovStroke.Thickness = 2
fovStroke.Parent = fovCircle

fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

function isInCircle(pos)
    local screenPos, visible = camera:WorldToViewportPoint(pos)
    if not visible then return false end
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
    return dist <= circleRadius / 2
end

function setAimLock(state)
    lockEnabled = state
    fovCircle.Visible = state
end

function setFov(value)
    circleRadius = value
    fovCircle.Size = UDim2.new(0, value, 0, value)
end

RunService.RenderStepped:Connect(function()
    if not lockEnabled then return end
    local murderer = findMurderer()
    if murderer and murderer.Character and murderer.Character:FindFirstChild("Head") then
        local head = murderer.Character.Head
        if isInCircle(head.Position) then
            camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
        end
    end
end)

--[[-- shooting --]]--
---Closest murderer to the middle of the screen.
function getMurdererTarget()
    local closest = nil
    local distance = math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if hasItem(plr, "Knife") then
                local pos, visible = camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).Magnitude
                    if dist < distance then
                        distance = dist
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

---One shot with a little lead on the target.
function shootMurderer()
    local char = player.Character
    if not char then return end
    local gun = char:FindFirstChild("Gun") or player.Backpack:FindFirstChild("Gun")
    if not gun then return end
    if gun.Parent ~= char then gun.Parent = char end
    local remote = gun:FindFirstChild("Shoot")
    if not remote then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local attachment = root:FindFirstChild("GunRaycastAttachment")
    if not attachment then return end
    local murderer = findMurderer()
    if not murderer then return end
    local mchar = murderer.Character
    if not mchar then return end
    local mroot = mchar:FindFirstChild("HumanoidRootPart")
    if not mroot then return end
    local velocity = mroot.AssemblyLinearVelocity
    local predictedPosition = mroot.Position + velocity * 0.15
    remote:FireServer(attachment.WorldCFrame, CFrame.new(predictedPosition))
end

function setAutoShoot(state)
    autoShoot = state
end

---Fires every frame while enabled; no lead, the aim lock keeps the target centred.
RunService.RenderStepped:Connect(function()
    if not autoShoot then return end
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChild("Gun")
    if not tool then return end
    local remote = tool:FindFirstChild("Shoot")
    if not remote then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local attachment = root:FindFirstChild("GunRaycastAttachment")
    if not attachment then return end
    local target = getMurdererTarget()
    if not target then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    remote:FireServer(attachment.WorldCFrame, CFrame.new(targetHRP.Position))
end)

--[[-- floating mini buttons that live in their own ScreenGui --]]--
local function makeFloatingButton(text, onClick)
    local buttonGui = Instance.new("ScreenGui")
    buttonGui.ResetOnSpawn = false
    buttonGui.Parent = player.PlayerGui

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 52)
    btn.Position = UDim2.new(0.5, -70, 0.87, 0)
    btn.AnchorPoint = Vector2.new(0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
    btn.BackgroundTransparency = 0.35
    btn.TextColor3 = Color3.fromRGB(0, 70, 150)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = buttonGui
    btn.Active = true
    btn.Draggable = true

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 18)
    local miniStroke = Instance.new("UIStroke", btn)
    miniStroke.Thickness = 2.5
    miniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    miniStroke.Color = Color3.fromRGB(0, 120, 255)

    task.spawn(function()
        while btn.Parent do
            TweenService:Create(miniStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Color = Color3.fromRGB(0, 80, 255) }):Play()
            task.wait(0.8)
            TweenService:Create(miniStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Color = Color3.fromRGB(160, 230, 255) }):Play()
            task.wait(0.8)
        end
    end)

    btn.MouseButton1Click:Connect(onClick)
    return buttonGui
end

function createFloatingGunButton()
    if floatingGunButton then return end
    floatingGunButton = makeFloatingButton("TP To Sheriff Gun", function()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local gun = findGunDrop()
        if not gun then return end
        local oldPos = root.CFrame
        root.CFrame = gun.CFrame + Vector3.new(0, 2, 0)
        task.wait(0.3)
        root.CFrame = oldPos
    end)
end

function removeFloatingGunButton()
    if floatingGunButton then
        floatingGunButton:Destroy()
        floatingGunButton = nil
    end
end

function setMiniGunButton(state)
    if state then createFloatingGunButton() else removeFloatingGunButton() end
end

function createFloatingShootButton()
    if floatingShootButton then floatingShootButton:Destroy() end
    floatingShootButton = makeFloatingButton("Shoot Murderer", shootMurderer)
end

--[[-- fling --]]--
---Spin fling: camera hops onto the target, then you are put back where you stood.
function walkFling(target)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not root or not hum then return end
    if not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local oldPos = root.CFrame
    local cam = workspace.CurrentCamera
    local oldSubject = cam.CameraSubject
    local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
    if targetHum then cam.CameraSubject = targetHum end

    local enabledFling = true
    local spin = Instance.new("BodyAngularVelocity")
    spin.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    spin.AngularVelocity = Vector3.new(0, 99999, 0)
    spin.P = math.huge
    spin.Parent = root

    task.spawn(function()
        while enabledFling do
            RunService.Heartbeat:Wait()
            local vel = root.Velocity
            root.Velocity = vel * 8000 + Vector3.new(0, 8000, 0)
            RunService.RenderStepped:Wait()
            root.Velocity = vel
        end
    end)

    local start = tick()
    while tick() - start < 2 do
        if targetRoot then
            local offset = Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
            root.CFrame = targetRoot.CFrame * CFrame.new(offset)
            root.Velocity = (targetRoot.Position - root.Position).Unit * 120
        end
        RunService.Heartbeat:Wait()
    end

    enabledFling = false
    spin:Destroy()
    root.Velocity = Vector3.zero
    root.RotVelocity = Vector3.zero
    RunService.Heartbeat:Wait()
    cam.CameraSubject = oldSubject
    root.CFrame = oldPos
end

---Touch fling: no spin instance, just velocity and a hard shove.
function flingPlayer(target)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local oldPos = root.CFrame
    local enabledFling = true
    task.spawn(function()
        while enabledFling do
            RunService.Heartbeat:Wait()
            local vel = root.Velocity
            root.Velocity = vel * 8000 + Vector3.new(0, 8000, 0)
            RunService.RenderStepped:Wait()
            root.Velocity = vel
        end
    end)

    local start = tick()
    while tick() - start < 2 do
        if targetRoot then
            root.CFrame = targetRoot.CFrame
            root.Velocity = (targetRoot.Position - root.Position).Unit * 150
        end
        RunService.Heartbeat:Wait()
    end

    enabledFling = false
    root.CFrame = oldPos
end

function flingSheriff()
    local sheriff = findSheriff()
    if sheriff then walkFling(sheriff) end
end

function flingMurderer()
    local murderer = findMurderer()
    if murderer then walkFling(murderer) end
end

function flingSelected()
    if selectedPlayer then walkFling(selectedPlayer) end
end

function setTouchFling(state)
    touchKick = state
end

RunService.Heartbeat:Connect(function()
    if not touchKick then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (root.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if dist < 3 then flingPlayer(plr) end
        end
    end
end)

function setFlingAll(state)
    flingAll = state
    if not state then return end
    task.spawn(function()
        while flingAll do
            for _, plr in pairs(Players:GetPlayers()) do
                if not flingAll then break end
                if plr ~= player then
                    flingPlayer(plr)
                    task.wait(1)
                end
            end
        end
    end)
end

--[[-- movement --]]--
function setWalkSpeed(value)
    walkSpeed = value
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.WalkSpeed = walkSpeed
    end
end

function setJumpPower(value)
    jumpPower = value
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.JumpPower = jumpPower
    end
end

function setInfJump(state)
    infJump = state
end

UserInputService.JumpRequest:Connect(function()
    if not infJump then return end
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:ChangeState("Jumping")
    end
end)

function setNoclipFriends(state)
    walkThrough = state
    if state then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then
            for _, part in pairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

RunService.Stepped:Connect(function()
    if not walkThrough then return end
    local char = player.Character
    if not char then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            for _, part in pairs(plr.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

--[[-- hitbox --]]--
function createCirclePart()
    if circlePart then circlePart:Destroy() end
    circlePart = Instance.new("Part")
    circlePart.Name = "RedCircle"
    circlePart.Shape = Enum.PartType.Cylinder
    circlePart.Size = Vector3.new(0.2, hitboxSize, hitboxSize)
    circlePart.Color = Color3.fromRGB(255, 0, 0)
    circlePart.Material = Enum.Material.Neon
    circlePart.Anchored = true
    circlePart.CanCollide = false
    circlePart.Parent = workspace
    circlePart.Orientation = Vector3.new(0, 0, 90)
end

function setHitbox(state)
    hitboxEnabled = state
    if state then
        createCirclePart()
    elseif circlePart then
        circlePart:Destroy()
        circlePart = nil
    end
end

function setHitboxSize(value)
    hitboxSize = value
    if circlePart then circlePart.Size = Vector3.new(0.2, hitboxSize, hitboxSize) end
end

RunService.RenderStepped:Connect(function()
    if not hitboxEnabled then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if circlePart then
        circlePart.Position = Vector3.new(root.Position.X, root.Position.Y - 3, root.Position.Z)
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local enemyRoot = plr.Character.HumanoidRootPart
            local dist = (enemyRoot.Position - root.Position).Magnitude
            if dist < (hitboxSize / 2) then
                enemyRoot.CFrame = root.CFrame * CFrame.new(0, 0, -4)
            end
        end
    end
end)

--[[-- mass kill --]]--
function pullPlayers()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local knife = char:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife")
    if knife and knife.Parent ~= char then knife.Parent = char end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -3)
        end
    end
end

function setKillAll(state)
    killAll = state
    if state then pullPlayers() end
end

function setAutoKill(state)
    autoKill = state
end

RunService.RenderStepped:Connect(function()
    if not autoKill then return end
    local char = player.Character
    if not char then return end
    local knife = char:FindFirstChild("Knife") or player.Backpack:FindFirstChild("Knife")
    if knife then pullPlayers() end
end)

--[[-- auto win --]]--
---One connection, armed by the toggle, instead of a new one per enable.
RunService.Heartbeat:Connect(function()
    if not autoWin then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root or not undergroundPos then return end

    root.CFrame = CFrame.new(undergroundPos)
    if hasGun() then
        local murderer = findKnifePlayer()
        if murderer and murderer.Character then
            local mroot = murderer.Character:FindFirstChild("HumanoidRootPart")
            if mroot then
                root.CFrame = mroot.CFrame * CFrame.new(0, 5, 0)
            end
        end
    end
    if hasKnife() then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -5)
                end
            end
        end
    end
end)

function setAutoWin(state)
    autoWin = state
    if not state then
        undergroundPos = nil
        return
    end
    task.spawn(function()
        local char = getCharacter()
        local root = char:WaitForChild("HumanoidRootPart")
        undergroundPos = root.Position - Vector3.new(0, 15, 0)
        root.CFrame = CFrame.new(undergroundPos)
    end)
end

--[[-- coin farm --]]--
function noclipLoop(char)
    task.spawn(function()
        while flying and char.Parent do
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
            RunService.Stepped:Wait()
        end
    end)
end

function restoreChar()
    local char = getCharacter()
    local hum = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    hum.PlatformStand = false
    hrp.AssemblyLinearVelocity = Vector3.zero
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = true
        end
    end
end

function getNearestCoin(root)
    local nearest
    local dist = math.huge
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "Coin_Server" and v:IsA("BasePart") and v:FindFirstChild("TouchInterest") and v:FindFirstChild("CoinVisual") and not collectedCoins[v] and not v:GetAttribute("Collected") then
            local d = (root.Position - v.Position).Magnitude
            if d < dist then
                dist = d
                nearest = v
            end
        end
    end
    return nearest
end

function flyToCoin(targetPart)
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")
    hum.PlatformStand = true
    local timeout = tick() + 10
    while flying and char.Parent and targetPart.Parent do
        if tick() > timeout then break end
        if targetPart:GetAttribute("Collected") then break end
        local targetPos = targetPart.Position
        if flyMode == "down" then
            targetPos = targetPos - Vector3.new(0, 3, 0)
        end
        local dir = (targetPos - hrp.Position).Unit
        hrp.AssemblyLinearVelocity = dir * flySpeed
        if flyMode == "down" then
            hrp.CFrame = CFrame.new(hrp.Position, targetPart.Position) * CFrame.Angles(math.rad(90), 0, 0)
        else
            hrp.CFrame = CFrame.new(hrp.Position, targetPart.Position)
        end
        if (hrp.Position - targetPos).Magnitude < 2 then
            hrp.CFrame = CFrame.new(targetPos)
            break
        end
        RunService.RenderStepped:Wait()
    end
    hrp.AssemblyLinearVelocity = Vector3.zero
    collectedCoins[targetPart] = true
    startedCollecting = true
end

function setFlySpeed(value)
    flySpeed = value
end

function setFlyMode(value)
    flyMode = Pick(value) or "normal"
end

function setAutoReset(state)
    autoReset = state
end

function setCoinFarm(state)
    flying = state
    collectedCoins = {}
    startedCollecting = false

    local char = getCharacter()
    if not state then
        restoreChar()
        return
    end

    noclipLoop(char)
    task.spawn(function()
        while flying do
            local ok, err = pcall(function()
                local farmChar = getCharacter()
                local root = farmChar:WaitForChild("HumanoidRootPart", 5)
                if not root then return end
                local coin = getNearestCoin(root)
                if coin then
                    flyToCoin(coin)
                else
                    if autoReset and startedCollecting then
                        if farmChar then farmChar:BreakJoints() end
                        task.wait(2)
                        startedCollecting = false
                    end
                    task.wait(0.1)
                end
            end)
            if not ok then
                warn("[" .. Brand.Name .. "] CoinFarm error: " .. tostring(err))
                task.wait(0.5)
            end
        end
    end)
end

---A respawn mid flight keeps the noclip going.
player.CharacterAdded:Connect(function(char)
    if not flying then return end
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    local lastPos = hrp.Position
    repeat
        task.wait(0.2)
        local newPos = hrp.Position
        if (newPos - lastPos).Magnitude > 1 then
            lastPos = newPos
        else
            break
        end
    until not flying
    task.wait(0.3)
    if flying then
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
        noclipLoop(char)
    end
end)

--[[-- anti afk --]]--
function setAntiAfk(state)
    if state then
        if AntiAFKConnection then return end
        AntiAFKConnection = player.Idled:Connect(function()
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end)
    elseif AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

--[[-- player lists --]]--
function refreshPlayerDropdowns()
    local names = getPlayerNames()
    if playerDropdown and playerDropdown.Refresh then pcall(function() playerDropdown:Refresh(names) end) end
    if playerDropdownTP and playerDropdownTP.Refresh then pcall(function() playerDropdownTP:Refresh(names) end) end
end

--[[==============================================================================
    5.  BOOT
==============================================================================]]--
BuildElements()

Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    refreshPlayerDropdowns()
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if espPlayerEnabled then updatePlayers() end
    end)
end)

Players.PlayerRemoving:Connect(function()
    task.wait(1)
    refreshPlayerDropdowns()
end)

---Saved settings come back here, and Rayfield loads them once more on its own
---four seconds in; values that already match are skipped, so nothing fires twice.
Rayfield:LoadConfiguration()
if antiAfkToggle.CurrentValue and not AntiAFKConnection then
    antiAfkToggle:Set(true)
end

Rayfield:Notify({
    Title = Brand.Name,
    Content = "Loaded. " .. Brand.Discord,
    Duration = 6,
})
