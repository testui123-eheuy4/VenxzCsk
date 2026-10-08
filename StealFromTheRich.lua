--!nonstrict
--[[
    ============================================================
     Steal From The Rich!  |  Rayfield Gen2 Edition
     Hub     : Venxz CSK
     Discord : https://discord.gg/GC5M2tpbG9
     UI      : Rayfield Gen2 (https://sirius.menu/gen2)
    ============================================================
]]

--// ============================================================
--//  Branding
--// ============================================================
local HUB_NAME   = "Venxz CSK"
local SCRIPT_NAME = "Steal From The Rich!"
local SCRIPT_VER  = "v2.0"
local DISCORD_URL = "https://discord.gg/GC5M2tpbG9"
local DISCORD_TAG = "discord.gg/GC5M2tpbG9"

--// ============================================================
--//  Services & player
--// ============================================================
local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local VirtualUser          = game:GetService("VirtualUser")
local HttpService          = game:GetService("HttpService")
local TeleportService      = game:GetService("TeleportService")
local Workspace            = game:GetService("Workspace")
local Lighting             = game:GetService("Lighting")
local Stats                = game:GetService("Stats")
local CoreGui              = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Heartbeat   = RunService.Heartbeat

if not game:IsLoaded() then
    game.Loaded:Wait()
end

--// ============================================================
--//  Small helpers
--// ============================================================
local function IsFunction(value)
    return type(value) == "function"
end

local function SafeCloneRef(instance)
    if IsFunction(cloneref) and typeof(instance) == "Instance" then
        return cloneref(instance)
    end
    return instance
end

-- Convert a UI multi-selection (array of strings, or set-style table) to a set.
local function ToTrueSet(selection)
    local set = {}
    if type(selection) == "table" then
        for key, value in pairs(selection) do
            if value == true and type(key) == "string" then
                set[key] = true
            elseif type(value) == "string" then
                set[value] = true
            end
        end
    end
    return set
end

local function HasAnyTrue(set)
    if type(set) ~= "table" then
        return false
    end
    for _, value in pairs(set) do
        if value then
            return true
        end
    end
    return false
end

--// ============================================================
--//  Hub namespace  (single-instance + unload tracking)
--// ============================================================
local function CreateNamespace(name)
    assert(type(name) == "string" and name ~= "", "Namespace is required")
    local env = (IsFunction(getgenv) and getgenv()) or _G
    assert(type(env) == "table", "getgenv did not return a table")

    local previous = env[name]
    if previous ~= nil then
        assert(type(previous) == "table" and type(previous.Unload) == "function", "Namespace is occupied")
        previous.Unload()
        assert(env[name] == nil, "Previous instance did not release its namespace")
    end

    local cleanups = {}
    local hub = { State = {}, Unloaded = false }

    hub.Track = function(fn)
        assert(type(fn) == "function", "Cleanup must be callable")
        if hub.Unloaded then
            fn()
        else
            table.insert(cleanups, fn)
        end
        return fn
    end

    hub.Unload = function()
        if hub.Unloaded then
            return
        end
        hub.Unloaded = true
        local failures = {}
        for i = #cleanups, 1, -1 do
            local fn = table.remove(cleanups, i)
            local ok, err = pcall(fn)
            if not ok then
                table.insert(failures, tostring(err))
            end
        end
        table.clear(hub.State)
        if #failures > 0 then
            error("Cleanup incomplete: " .. table.concat(failures, "; "), 0)
        end
        if env[name] == hub then
            env[name] = nil
        end
    end

    env[name] = hub
    return hub
end

local Hub = CreateNamespace("VenxzCSK_StealFromTheRich")
local State = Hub.State

local function IsLoaded()
    return not Hub.Unloaded
end

--// ============================================================
--//  Game modules & remotes
--// ============================================================
local RS   = SafeCloneRef(ReplicatedStorage)
local Map  = SafeCloneRef(Workspace)

local Network          = require(RS:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network"))
local AreaData         = require(RS.Shared.Data.AreaData)
local TrailData        = require(RS.Shared.Data.TrailData)
local ItemData         = require(RS.Shared.Data.ItemData)
local InfiniteMath     = require(RS.Shared.Utility.InfiniteMath)

local ClientBalanceService
do
    local function findBalanceModule()
        local roots = { RS }
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if ps then
            table.insert(roots, ps)
        end
        for _, root in ipairs(roots) do
            local ok, found = pcall(function()
                return root:FindFirstChild("ClientBalanceService", true)
            end)
            if ok and found and found:IsA("ModuleScript") then
                return found
            end
        end
        return nil
    end

    local module
    for _ = 1, 20 do
        module = findBalanceModule()
        if module then
            break
        end
        task.wait(0.5)
    end

    local ok, service = false, nil
    if module then
        ok, service = pcall(require, module)
    end
    if ok and service then
        ClientBalanceService = service
    else
        warn("[Venxz CSK] ClientBalanceService not found, using fallback (Balance = 0).")
        ClientBalanceService = { Balance = nil }
    end
end

local REMOTE_PLACE_AT         = RS:WaitForChild("re_PLACE_AT", 30)
local REMOTE_SELL_DO          = RS:WaitForChild("re_SELL_DO", 30)
local RF_SELL_QUOTE           = RS:WaitForChild("rf_SELL_QUOTE", 30)
local REMOTE_PLOT_UPGRADE     = RS:WaitForChild("re_PLOT_UPGRADE", 30)
local REMOTE_TREADMILL_UPGRADE = RS:WaitForChild("re_TREADMILL_UPGRADE", 30)
local RF_ITEM_LOADOUT         = RS:WaitForChild("rf_ITEM_LOADOUT", 30)

assert(REMOTE_PLACE_AT and REMOTE_SELL_DO and RF_SELL_QUOTE and REMOTE_PLOT_UPGRADE
    and REMOTE_TREADMILL_UPGRADE and RF_ITEM_LOADOUT, "Core remotes missing")

--// ============================================================
--//  Data lists  (zones, rarities, trails, constants)
--// ============================================================
local ZoneDisplayNames = {}  -- "Id - DisplayName"
local ZoneNameToId     = {}  -- "Id - DisplayName" -> Id
local ZoneIdToName     = {}  -- Id -> "Id - DisplayName"
local ZoneAreaPart     = {}  -- Id -> AreaPart name
local Rarities         = {}
local Trails           = {}

local SELL_MODES   = { "Held", "All" }
local SELL_MODE_ARG = { Held = "held", All = "all" }
local DEPOSIT_POS   = Vector3.new(2437, 4, -928)
local FALLBACK_SELL_POS = Vector3.new(2437.8, 5, -860)

do
    local areas = {}
    for _, area in ipairs(AreaData.Areas) do
        if type(area) == "table" and type(area.Id) == "string" then
            table.insert(areas, area)
        end
    end
    table.sort(areas, function(a, b)
        return (a.Order or 0) < (b.Order or 0)
    end)

    for _, area in ipairs(areas) do
        local label = area.Id .. " - " .. tostring(area.DisplayName or area.Id)
        table.insert(ZoneDisplayNames, label)
        ZoneNameToId[label] = area.Id
        ZoneIdToName[area.Id] = label
        if type(area.AreaPart) == "string" then
            ZoneAreaPart[area.Id] = area.AreaPart
        end
    end

    for index = 1, 20 do
        local tier = ItemData:GetTierByIndex(index)
        if type(tier) == "table" and type(tier.Name) == "string" then
            table.insert(Rarities, tier.Name)
        else
            break
        end
    end
    if #Rarities == 0 then
        Rarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine" }
    end

    if type(TrailData.Trails) == "table" then
        for _, trail in ipairs(TrailData.Trails) do
            if type(trail) == "table" and type(trail.Id) == "string" then
                table.insert(Trails, trail)
            end
        end
    end
end

--// ============================================================
--//  State
--// ============================================================
State.Enabled = {
    Steal = false,
    Place = false,
    Open = false,
    EquipBest = false,
    BuyEquipSlot = false,
    Treadmill = false,
    UpgradeTreadmill = false,
    UpgradePlot = false,
    ClaimIndex = false,
    BuyTrails = false,
    Sell = false,
}
State.RarityFilter = {}
State.ZoneFilter = {}
State.SellMode = "All"
State.TeleportToSellerWhileSelling = false
State.Gens = {
    Steal = 0,
    Place = 0,
    Open = 0,
    EquipBest = 0,
    BuyEquipSlot = 0,
    Treadmill = 0,
    UpgradeTreadmill = 0,
    UpgradePlot = 0,
    ClaimIndex = 0,
    BuyTrails = 0,
    Sell = 0,
}
State.TrailOwned = {}
State.StealBurst = 3
State.StealBlocked = {}
State.StealStatus = "Idle"
State.StealCount = 0
State.LastStealAt = 0
State.LastPlaceAt = 0
State.LastOpenAt = 0
State.LastEquipBestAt = 0
State.LastBuySlotAt = 0
State.LastTreadmillAt = 0
State.LastUpgradeTreadmillAt = 0
State.LastUpgradePlotAt = 0
State.LastClaimIndexAt = 0
State.LastBuyTrailsAt = 0
State.LastSellAt = 0

for _, rarity in ipairs(Rarities) do
    State.RarityFilter[rarity] = true
end
for _, zone in ipairs(ZoneDisplayNames) do
    State.ZoneFilter[zone] = true
end

--// ============================================================
--//  Notify  (bound to the Rayfield window later)
--// ============================================================
local Window
local function Notify(text, duration, icon)
    pcall(function()
        if Window then
            Window:Notify({
                title = HUB_NAME,
                content = tostring(text),
                icon = icon,
                duration = duration or 3,
            })
        end
    end)
end

--// ============================================================
--//  Character helpers
--// ============================================================
local function GetRoot()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    return nil
end

local function GetHumanoid()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function TeleportTo(cf)
    local root = GetRoot()
    if not root then
        return false
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = cf
    return true
end

local function RequestStream(position)
    if typeof(position) ~= "Vector3" then
        return
    end
    pcall(function()
        if IsFunction(LocalPlayer.RequestStreamAroundAsync) then
            task.defer(function()
                pcall(function()
                    LocalPlayer:RequestStreamAroundAsync(position)
                end)
            end)
        end
    end)
end

local function FirePrompt(prompt)
    if not (prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled) then
        return false
    end
    if not IsFunction(fireproximityprompt) then
        return false
    end
    local ok = pcall(fireproximityprompt, prompt)
    return ok
end

local function CopyToClipboard(text, message)
    local ok = false
    if IsFunction(setclipboard) then
        ok = pcall(setclipboard, text)
    elseif IsFunction(toclipboard) then
        ok = pcall(toclipboard, text)
    end
    if ok and message then
        Notify(message, 3)
    elseif not ok then
        Notify("Clipboard unavailable", 3)
    end
    return ok
end

--// ============================================================
--//  Economy helpers
--// ============================================================
local function GetBalance()
    local balance = ClientBalanceService.Balance
    if balance == nil then
        return InfiniteMath.new(0)
    end
    return balance
end

local function CanAfford(amount)
    local value = tonumber(amount)
    if not value or value <= 0 then
        return true
    end
    local ok, result = pcall(function()
        return GetBalance() >= InfiniteMath.new(value)
    end)
    return ok and result == true
end

--// ============================================================
--//  Plot / area helpers
--// ============================================================
local function GetOwnPlot()
    for _, child in ipairs(Map:GetChildren()) do
        if child.Name:match("^Plot Building %d+$") then
            local floor = child:FindFirstChild("floor")
            if floor and floor:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                return child, floor
            end
        end
    end
    return nil, nil
end

local function GetOwnPlotFloor()
    local _, floor = GetOwnPlot()
    return floor
end

local function GetBaseCFrame()
    local _, floor = GetOwnPlot()
    if floor then
        local spawn = floor:FindFirstChild("PlayerSpawn")
        if spawn and spawn:IsA("BasePart") then
            return spawn.CFrame * CFrame.new(0, 3, 0)
        end
        return CFrame.new(floor.Position + Vector3.new(0, floor.Size.Y / 2 + 3, 0))
    end
    return nil
end

local function FindAreaPart(areaId)
    local partName = ZoneAreaPart[areaId]
    if type(partName) ~= "string" or partName == "" then
        return nil
    end
    local map = Map:FindFirstChild("Map")
    local roots = { map, Map }
    for _, root in ipairs(roots) do
        if root then
            local found = root:FindFirstChild(partName, true)
            if found and found:IsA("BasePart") then
                return found
            end
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant.Name == partName and descendant:IsA("BasePart") then
                    return descendant
                end
            end
        end
    end
    return nil
end

local function GetAreaPosition(areaId)
    local part = FindAreaPart(areaId)
    if part then
        return Vector3.new(part.Position.X, part.Position.Y + part.Size.Y / 2 + 3, part.Position.Z)
    end
    local crates = Map:FindFirstChild("Crates")
    if crates then
        for _, child in ipairs(crates:GetChildren()) do
            if child:GetAttribute("AreaId") == areaId then
                local position = child:GetPivot().Position
                return Vector3.new(position.X, position.Y + 3, position.Z)
            end
        end
    end
    return nil
end

--// ============================================================
--//  Filters
--// ============================================================
local function RarityAllowed(rarity)
    if type(rarity) ~= "string" or rarity == "" then
        return false
    end
    if not HasAnyTrue(State.RarityFilter) then
        return true
    end
    return State.RarityFilter[rarity] == true
end

local function ZoneAllowed(areaId)
    if type(areaId) ~= "string" or areaId == "" then
        return false
    end
    if not HasAnyTrue(State.ZoneFilter) then
        return true
    end
    local label = ZoneIdToName[areaId]
    if label and State.ZoneFilter[label] == true then
        return true
    end
    return State.ZoneFilter[areaId] == true
end

--// ============================================================
--//  Tools & crates
--// ============================================================
local function IsCrateTool(tool)
    if not (tool and tool:IsA("Tool")) then
        return false
    end
    if tool:GetAttribute("IsBatTool") or tool:GetAttribute("IsBearTrapTool") or tool:GetAttribute("IsTreadmill") then
        return false
    end
    return tool:GetAttribute("CrateUid") ~= nil
end

local function IsCarryingStolen()
    return LocalPlayer:GetAttribute("CarryingStolen") == true
end

local function GetHeldCrateTool()
    if IsCarryingStolen() then
        return nil
    end
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    local tool = character:FindFirstChildOfClass("Tool")
    if IsCrateTool(tool) then
        return tool
    end
    return nil
end

local function GetCrateTools()
    local list = {}
    if IsCarryingStolen() then
        return list
    end
    local character = LocalPlayer.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if IsCrateTool(child) then
                table.insert(list, child)
            end
        end
    end
    for _, child in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if IsCrateTool(child) then
            table.insert(list, child)
        end
    end
    return list
end

local function EquipTool(tool)
    if not (tool and tool.Parent) then
        return false
    end
    local humanoid = GetHumanoid()
    if not humanoid then
        return false
    elseif tool.Parent == LocalPlayer.Character then
        return true
    else
        local ok = pcall(function()
            humanoid:EquipTool(tool)
        end)
        return ok
    end
end

local PromptCache = setmetatable({}, { __mode = "k" })

local function FastPrompt(prompt)
    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        if prompt.MaxActivationDistance < 40 then
            prompt.MaxActivationDistance = 40
        end
    end)
end

local function FindStealPrompt(model)
    local cached = PromptCache[model]
    if not (cached and cached.Parent and cached:IsDescendantOf(model)) then
        cached = nil
        for _, descendant in ipairs(model:GetDescendants()) do
            if descendant:IsA("ProximityPrompt") and descendant.ActionText == "Steal" then
                cached = descendant
                break
            end
        end
        PromptCache[model] = cached
        if cached then
            FastPrompt(cached)
        end
    end
    if cached and cached.Enabled then
        return cached
    end
    return nil
end

local function CollectCrates()
    local crates = Map:FindFirstChild("Crates")
    if not crates then
        return {}
    end
    local list = {}
    for _, child in ipairs(crates:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("IsCrate") == true then
            local areaId = child:GetAttribute("AreaId")
            local tier = child:GetAttribute("CrateTier")
            if ZoneAllowed(areaId) and RarityAllowed(tier) then
                local prompt = FindStealPrompt(child)
                if prompt then
                    table.insert(list, {
                        model = child,
                        areaId = areaId,
                        tier = tier,
                        prompt = prompt,
                        position = child:GetPivot().Position,
                    })
                end
            end
        end
    end
    return list
end

local function StealAnchor(crate)
    local prompt = crate.prompt
    local holder = prompt and prompt.Parent
    if holder then
        if holder:IsA("BasePart") then
            return holder.Position
        elseif holder:IsA("Attachment") then
            return holder.WorldPosition
        end
    end
    local ok, pivot = pcall(function()
        return crate.model:GetPivot().Position
    end)
    return ok and pivot or crate.position
end

--// ============================================================
--//  Placement helpers
--// ============================================================
local function IsBlockedByFurniture(floor, position)
    for _, child in ipairs(floor:GetChildren()) do
        if child.Name == "AppraisingCrate" or child.Name == "ItemStand" then
            local other = child:GetPivot().Position
            local dx = other.X - position.X
            local dz = other.Z - position.Z
            if dx * dx + dz * dz < 9 then
                return true
            end
        end
    end
    return false
end

local function IsSpotOnPlot(floor, position)
    if not floor then
        return false
    end
    local localPos = floor.CFrame:PointToObjectSpace(position)
    if math.abs(localPos.X) > floor.Size.X / 2 - 2 or math.abs(localPos.Z) > floor.Size.Z / 2 - 2 then
        return false
    end
    local topY = floor.Position.Y + floor.Size.Y / 2
    if math.abs(position.Y - topY) > 2.5 then
        return false
    end
    if IsBlockedByFurniture(floor, position) then
        return false
    end
    return true
end

local function FindPlacementSpot(floor)
    if not floor then
        return nil
    end
    local topY = floor.Position.Y + floor.Size.Y / 2
    local halfX = math.max(1, floor.Size.X / 2 - 2.5)
    local halfZ = math.max(1, floor.Size.Z / 2 - 2.5)
    local step = 3.2

    for x = -halfX, halfX, step do
        for z = -halfZ, halfZ, step do
            local raw = (floor.CFrame * CFrame.new(x, floor.Size.Y / 2, z)).Position
            local candidate = Vector3.new(raw.X, topY, raw.Z)
            if IsSpotOnPlot(floor, candidate) then
                return candidate
            end
        end
    end

    local center = Vector3.new(floor.Position.X, topY, floor.Position.Z)
    if IsSpotOnPlot(floor, center) then
        return center
    end
    return nil
end

local function GetPlaceYaw(tool)
    if tool and tool:GetAttribute("CrateAreaId") == "Angelic" then
        local root = GetRoot()
        if root then
            local look = root.CFrame.LookVector
            return math.atan2(-look.X, -look.Z)
        end
    end
    return 0
end

--// ============================================================
--//  Treadmill helpers
--// ============================================================
local function FindMyTreadmill()
    local treadmills = Map:FindFirstChild("Treadmills")
    if not treadmills then
        return nil, nil
    end

    local function beltOf(model)
        local belt = model:FindFirstChild("Belt", true)
        if belt and belt:IsA("BasePart") then
            return belt
        end
        return nil
    end

    local mine = treadmills:FindFirstChild("PersonalTreadmill_" .. tostring(LocalPlayer.UserId))
    if mine then
        local belt = beltOf(mine)
        if belt then
            return belt, mine
        end
        for _, child in ipairs(treadmills:GetChildren()) do
            if child:GetAttribute("RiderUserId") == LocalPlayer.UserId
                or child:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                local found = beltOf(child)
                if found then
                    return found, child
                end
            end
        end
        return nil, nil
    end

    for _, child in ipairs(treadmills:GetChildren()) do
        if child:GetAttribute("RiderUserId") == LocalPlayer.UserId
            or child:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            local found = beltOf(child)
            if found then
                return found, child
            end
        end
    end
    return nil, nil
end

local function TreadmillMountCFrame(belt, model)
    if not (belt and belt:IsA("BasePart")) then
        return nil
    end
    local yaw = model and tonumber(model:GetAttribute("MountYaw")) or 0
    return belt.CFrame
        * CFrame.new(0, belt.Size.Y / 2 + 3, 0)
        * CFrame.Angles(0, math.rad(yaw), 0)
end

--// ============================================================
--//  Seller helpers
--// ============================================================
local function GetSellerCFrame()
    local node = Map:FindFirstChild("Map")
    node = node and node:FindFirstChild("Vendors")
    node = node and node:FindFirstChild("SellPlaces")
    local sell1 = node and node:FindFirstChild("Sell1")
    local npc = sell1 and sell1:FindFirstChild("sellnpc NEW")

    if npc and npc:IsA("Model") then
        return npc:GetPivot() * CFrame.new(0, 2, 5)
    elseif sell1 then
        local prompt = sell1:FindFirstChildWhichIsA("ProximityPrompt", true)
        local holder = prompt and prompt.Parent
        if holder and holder:IsA("BasePart") then
            return CFrame.new(holder.Position + Vector3.new(0, 3, 4))
        end
        return CFrame.new(FALLBACK_SELL_POS)
    else
        return CFrame.new(FALLBACK_SELL_POS)
    end
end

local function GoToSellerIfNeeded()
    if not State.TeleportToSellerWhileSelling then
        return true
    end
    local sellerCf = GetSellerCFrame()
    local root = GetRoot()
    if root and (root.Position - sellerCf.Position).Magnitude <= 12 then
        return true
    end
    RequestStream(sellerCf.Position)
    return TeleportTo(sellerCf)
end

--// ============================================================
--//  Feature loop runner
--// ============================================================
local function StartLoop(name, interval, fn)
    State.Gens[name] = State.Gens[name] + 1
    local generation = State.Gens[name]
    task.spawn(function()
        while IsLoaded() and State.Enabled[name] and State.Gens[name] == generation do
            local ok, err = pcall(fn)
            if not ok then
                warn("[Venxz CSK][" .. SCRIPT_NAME .. "]", name, err)
            end
            task.wait(type(interval) == "function" and interval() or interval)
        end
    end)
end

local function ToggleFeature(name, enabled, interval, fn)
    State.Enabled[name] = enabled and true or false
    if State.Enabled[name] then
        StartLoop(name, interval, fn)
    else
        State.Gens[name] = State.Gens[name] + 1
    end
end

--// ============================================================
--//  Features
--// ============================================================
local DepositStolen

local function DoStealOnce()
    if not IsLoaded() or not State.Enabled.Steal then
        return false
    end

    if IsCarryingStolen() then
        State.StealStatus = "Depositing"
        DepositStolen()
        return false
    end

    local root = GetRoot()
    if not root then
        State.StealStatus = "Waiting for character"
        return false
    end

    local crates = CollectCrates()
    if #crates == 0 then
        State.StealStatus = "Searching for crates"
        return false
    end

    local blocked = State.StealBlocked
    local now = os.clock()
    local target, bestDist
    for _, crate in ipairs(crates) do
        local untilAt = blocked[crate.model]
        if not (untilAt and untilAt > now) then
            blocked[crate.model] = nil
            local dist = (crate.position - root.Position).Magnitude
            if not bestDist or dist < bestDist then
                target, bestDist = crate, dist
            end
        end
    end

    if not target then
        State.StealStatus = "Searching for crates"
        return false
    end

    State.StealStatus = "Grabbing"
    local prompt = target.prompt
    FastPrompt(prompt)
    local spot = StealAnchor(target)
    RequestStream(spot)
    TeleportTo(CFrame.new(spot + Vector3.new(0, 3, 0)))
    if not IsLoaded() or not State.Enabled.Steal then
        return false
    end

    local burst = math.clamp(State.StealBurst or 3, 1, 10)
    local deadline = os.clock() + 1.0
    local fired = false
    while IsLoaded() and State.Enabled.Steal and os.clock() < deadline do
        if IsCarryingStolen() or not (prompt.Parent and prompt.Enabled) then
            break
        end
        for _ = 1, burst do
            if FirePrompt(prompt) then
                fired = true
            end
        end
        Heartbeat:Wait()
        if IsCarryingStolen() then
            break
        end
        local me = GetRoot()
        local nowSpot = StealAnchor(target)
        if me and (me.Position - nowSpot).Magnitude > 8 then
            TeleportTo(CFrame.new(nowSpot + Vector3.new(0, 3, 0)))
        end
    end

    if not IsLoaded() or not State.Enabled.Steal then
        return false
    end

    if IsCarryingStolen() then
        State.StealCount = State.StealCount + 1
        State.LastStealAt = os.clock()
        State.StealStatus = "Depositing"
        DepositStolen()
    else
        blocked[target.model] = os.clock() + (fired and 0.6 or 0.3)
    end

    return IsLoaded() and State.Enabled.Steal
end

DepositStolen = function()
    if not IsCarryingStolen() then
        return true
    end
    RequestStream(DEPOSIT_POS)
    if not TeleportTo(CFrame.new(DEPOSIT_POS + Vector3.new(0, 3, 0))) then
        return false
    end
    local deadline = os.clock() + 4
    while IsLoaded() and IsCarryingStolen() and os.clock() < deadline do
        TeleportTo(CFrame.new(DEPOSIT_POS + Vector3.new(0, 3, 0)))
        Heartbeat:Wait()
        if not IsLoaded() then
            return false
        end
    end
    return not IsCarryingStolen()
end

local function DoSteal()
    while DoStealOnce() do
    end
end

local function DoPlace()
    if not IsLoaded() or not State.Enabled.Place then
        return
    end
    if IsCarryingStolen() then
        DepositStolen()
        return
    end
    if os.clock() - State.LastPlaceAt < 0.55 then
        return
    end

    local floor = GetOwnPlotFloor()
    if not floor then
        return
    end

    local tool = GetHeldCrateTool()
    if not tool then
        local tools = GetCrateTools()
        if #tools == 0 then
            return
        end
        EquipTool(tools[1])
        task.wait(0.15)
        if IsCarryingStolen() then
            return
        end
        tool = GetHeldCrateTool()
        if not tool then
            return
        end
    end

    local spot = FindPlacementSpot(floor)
    if not spot then
        return
    end
    RequestStream(spot)
    TeleportTo(CFrame.new(spot + Vector3.new(0, 4, 0)))
    task.wait(0.1)
    if not IsLoaded() or not State.Enabled.Place then
        return
    end
    if not IsSpotOnPlot(floor, spot) then
        return
    end

    local yaw = GetPlaceYaw(tool)
    local ok = pcall(function()
        REMOTE_PLACE_AT:FireServer(spot, yaw)
    end)
    if ok then
        State.LastPlaceAt = os.clock()
    end
end

local function DoOpen()
    if not IsLoaded() or not State.Enabled.Open then
        return
    end
    if os.clock() - State.LastOpenAt < 0.35 then
        return
    end

    local plot = GetOwnPlot()
    if not plot then
        return
    end
    local root = GetRoot()
    if not root then
        return
    end

    local bestPrompt, bestPos, bestDist = nil, nil, nil
    for _, descendant in ipairs(plot:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.ActionText == "Open Crate" then
            local parent = descendant.Parent
            local pos
            if parent and parent:IsA("BasePart") then
                pos = parent.Position
            else
                local model = descendant:FindFirstAncestorWhichIsA("Model")
                if model then
                    pos = model:GetPivot().Position
                end
            end
            if pos then
                local dist = (pos - root.Position).Magnitude
                if not bestDist or dist < bestDist then
                    bestDist = dist
                    bestPrompt = descendant
                    bestPos = pos
                end
            end
        end
    end

    if not (bestPrompt and bestPos) then
        return
    end

    RequestStream(bestPos)
    TeleportTo(CFrame.new(bestPos + Vector3.new(0, 3, 0)))
    task.wait(0.1)
    if not IsLoaded() or not State.Enabled.Open then
        return
    end
    if FirePrompt(bestPrompt) then
        State.LastOpenAt = os.clock()
    end
end

local function DoEquipBest()
    if not IsLoaded() or not State.Enabled.EquipBest then
        return
    end
    if os.clock() - State.LastEquipBestAt < 2 then
        return
    end
    local ok = pcall(function()
        RF_ITEM_LOADOUT:InvokeServer("placebest")
    end)
    if ok then
        State.LastEquipBestAt = os.clock()
    end
end

local function DoBuyEquipSlot()
    if not IsLoaded() or not State.Enabled.BuyEquipSlot then
        return
    end
    if os.clock() - State.LastBuySlotAt < 1.5 then
        return
    end

    local _, floor = GetOwnPlot()
    if not floor then
        return
    end

    local ok, data = pcall(function()
        return RF_ITEM_LOADOUT:InvokeServer("list")
    end)
    if ok and type(data) == "table" then
        local nextPrice = tonumber(data.NextPrice)
        if nextPrice and nextPrice > 0 and not CanAfford(nextPrice) then
            return
        end
        if type(data.Slots) == "number" and type(data.NextSlots) == "number" and data.NextSlots <= data.Slots then
            return
        end
    end

    local fired = pcall(function()
        REMOTE_PLOT_UPGRADE:FireServer(floor, true)
    end)
    if fired then
        State.LastBuySlotAt = os.clock()
    end
end

local function DoTreadmill()
    if not IsLoaded() or not State.Enabled.Treadmill then
        return
    end
    if LocalPlayer:GetAttribute("OnTreadmill") == true then
        return
    end
    if os.clock() - State.LastTreadmillAt < 0.8 then
        return
    end

    local belt, model = FindMyTreadmill()
    if not belt then
        return
    end
    local cf = TreadmillMountCFrame(belt, model)
    if not cf then
        return
    end
    RequestStream(cf.Position)
    TeleportTo(cf)
    State.LastTreadmillAt = os.clock()
end

local function TryUpgrade(remote, signName, lastKey, interval)
    if not IsLoaded() then
        return
    end
    if os.clock() - (State[lastKey] or 0) < (interval or 1.5) then
        return
    end

    local plot = GetOwnPlot()
    if not plot then
        return
    end

    local sign = plot:FindFirstChild(signName, true)
    if sign then
        if sign:GetAttribute("CanAfford") == false then
            return
        end
        local price = tonumber(sign:GetAttribute("UpgradePrice"))
        if price and price > 0 and not CanAfford(price) then
            return
        end
    end

    local ok = pcall(function()
        remote:FireServer(plot)
    end)
    if ok then
        State[lastKey] = os.clock()
    end
end

local function DoUpgradeTreadmill()
    if not State.Enabled.UpgradeTreadmill then
        return
    end
    TryUpgrade(REMOTE_TREADMILL_UPGRADE, "TreadmillSignBoard", "LastUpgradeTreadmillAt", 1.5)
end

local function DoUpgradePlot()
    if not State.Enabled.UpgradePlot then
        return
    end
    TryUpgrade(REMOTE_PLOT_UPGRADE, "UpgradeSignBoard", "LastUpgradePlotAt", 1.5)
end

local function DoClaimIndex()
    if not IsLoaded() or not State.Enabled.ClaimIndex then
        return
    end
    if os.clock() - State.LastClaimIndexAt < 2 then
        return
    end
    local ok = pcall(function()
        Network.FireServer("INDEX_CLAIM_ALL")
    end)
    if ok then
        State.LastClaimIndexAt = os.clock()
    end
end

local function DoBuyTrails()
    if not IsLoaded() or not State.Enabled.BuyTrails then
        return
    end
    if os.clock() - State.LastBuyTrailsAt < 1.2 then
        return
    end

    local bought = false
    for _, trail in ipairs(Trails) do
        if not IsLoaded() or not State.Enabled.BuyTrails then
            break
        end
        if State.TrailOwned[trail.Id] ~= true then
            local price = tonumber(trail.Price) or 0
            if CanAfford(price) then
                local ok = pcall(function()
                    Network.FireServer("TRAIL_BUY", trail.Id)
                end)
                if ok then
                    bought = true
                    task.wait(0.2)
                end
            end
        end
    end

    if bought then
        State.LastBuyTrailsAt = os.clock()
        pcall(function()
            Network.FireServer("TRAIL_STATE")
        end)
    end
end

local function DoSell()
    if not IsLoaded() or not State.Enabled.Sell then
        return
    end
    if os.clock() - State.LastSellAt < 1.2 then
        return
    end

    local mode = SELL_MODE_ARG[State.SellMode] or "all"
    if mode == "held" then
        local ok, quote = pcall(function()
            return RF_SELL_QUOTE:InvokeServer()
        end)
        if not (ok and type(quote) == "table" and quote.HeldLabel and quote.HeldPrice) then
            return
        end
    elseif mode == "all" then
        local ok, quote = pcall(function()
            return RF_SELL_QUOTE:InvokeServer()
        end)
        if ok and type(quote) == "table" then
            local count = tonumber(quote.AllCount) or 0
            if count <= 0 then
                return
            end
        end
    end

    if not GoToSellerIfNeeded() then
        return
    end
    if State.TeleportToSellerWhileSelling then
        task.wait(0.08)
        if not IsLoaded() or not State.Enabled.Sell then
            return
        end
    end

    local ok = pcall(function()
        REMOTE_SELL_DO:FireServer(mode)
    end)
    if ok then
        State.LastSellAt = os.clock()
    end
end

--// ============================================================
--//  Hub API
--// ============================================================
Hub.SetSteal = function(enabled) ToggleFeature("Steal", enabled, 0, DoSteal) end
Hub.SetPlace = function(enabled) ToggleFeature("Place", enabled, 0.35, DoPlace) end
Hub.SetOpen = function(enabled) ToggleFeature("Open", enabled, 0.3, DoOpen) end
Hub.SetEquipBest = function(enabled) ToggleFeature("EquipBest", enabled, 1.5, DoEquipBest) end
Hub.SetBuyEquipSlot = function(enabled) ToggleFeature("BuyEquipSlot", enabled, 1.2, DoBuyEquipSlot) end
Hub.SetTreadmill = function(enabled) ToggleFeature("Treadmill", enabled, 0.5, DoTreadmill) end
Hub.SetUpgradeTreadmill = function(enabled) ToggleFeature("UpgradeTreadmill", enabled, 1.2, DoUpgradeTreadmill) end
Hub.SetUpgradePlot = function(enabled) ToggleFeature("UpgradePlot", enabled, 1.2, DoUpgradePlot) end
Hub.SetClaimIndex = function(enabled) ToggleFeature("ClaimIndex", enabled, 2, DoClaimIndex) end
Hub.SetBuyTrails = function(enabled) ToggleFeature("BuyTrails", enabled, 1, DoBuyTrails) end
Hub.SetSell = function(enabled) ToggleFeature("Sell", enabled, 1, DoSell) end

Hub.SetStealBurst = function(value)
    State.StealBurst = math.clamp(math.floor(tonumber(value) or 3), 1, 10)
end

Hub.SetZoneFilter = function(selection)
    State.ZoneFilter = ToTrueSet(selection)
    if not HasAnyTrue(State.ZoneFilter) then
        for _, zone in ipairs(ZoneDisplayNames) do
            State.ZoneFilter[zone] = true
        end
    end
end

Hub.SetRarityFilter = function(selection)
    State.RarityFilter = ToTrueSet(selection)
    if not HasAnyTrue(State.RarityFilter) then
        for _, rarity in ipairs(Rarities) do
            State.RarityFilter[rarity] = true
        end
    end
end

Hub.SetSellMode = function(mode)
    if mode == "Held" or mode == "All" then
        State.SellMode = mode
    end
end

Hub.SetTeleportToSellerWhileSelling = function(enabled)
    State.TeleportToSellerWhileSelling = enabled and true or false
end

Hub.TeleportToBase = function()
    if not IsLoaded() then
        return false
    end
    local cf = GetBaseCFrame()
    if not cf then
        return false
    end
    RequestStream(cf.Position)
    return TeleportTo(cf)
end

Hub.TeleportToZone = function(target)
    if not IsLoaded() then
        return false
    end

    local name = target
    if type(target) == "table" then
        name = nil
        for key, value in pairs(target) do
            if value == true and type(key) == "string" then
                name = key
                break
            elseif type(value) == "string" then
                name = value
                break
            end
        end
    end
    if type(name) ~= "string" or name == "" then
        return false
    end

    local areaId = ZoneNameToId[name] or name
    local position = GetAreaPosition(areaId)
    if not position then
        return false
    end
    RequestStream(position)
    return TeleportTo(CFrame.new(position))
end

--// ============================================================
--//  Trail state sync
--// ============================================================
do
    local connection
    local ok = pcall(function()
        connection = Network.OnClientEvent("TRAIL_STATE"):Connect(function(data)
            if type(data) == "table" and type(data.Owned) == "table" then
                State.TrailOwned = data.Owned
            end
        end)
        Network.FireServer("TRAIL_STATE")
    end)
    if ok and connection then
        Hub.Track(function()
            pcall(function()
                connection:Disconnect()
            end)
        end)
    end
end

Hub.Track(function()
    for name in pairs(State.Gens) do
        State.Gens[name] = State.Gens[name] + 1
        State.Enabled[name] = false
    end
end)

--// ============================================================
--//  Executor status
--// ============================================================
local ExecutorStatus
local executorName = "Unknown"
pcall(function()
    if IsFunction(identifyexecutor) then
        local name, version = identifyexecutor()
        if type(name) == "string" and name ~= "" then
            executorName = (type(version) == "string" and version ~= "")
                and (name .. " " .. version)
                or name
        end
    end
end)

do
    local missing = {}
    if not IsFunction(fireproximityprompt) then
        table.insert(missing, "fireproximityprompt")
    end
    if not (IsFunction(setclipboard) or IsFunction(toclipboard)) then
        table.insert(missing, "clipboard")
    end
    if #missing == 0 then
        ExecutorStatus = "(ready)"
    else
        ExecutorStatus = "(missing " .. table.concat(missing, ", ") .. ")"
    end
end

--// ============================================================
--//  Player tweaks
--// ============================================================
local PlayerTweaks = {
    WalkSpeedEnabled = false,
    WalkSpeed = 32,
    InfJump = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 60,
    InstantPP = false,
    WalkSnapshots = {},
    NoClipSnapshots = {},
    FlyPlatformStand = nil,
    InfJumpConn = nil,
    NoClipConn = nil,
    FlyConn = nil,
    InstantConn = nil,
    InstantSnapshots = {},
}

do
    local function ApplyWalkSpeed(humanoid)
        if not humanoid then
            return
        end
        if PlayerTweaks.WalkSnapshots[humanoid] == nil then
            PlayerTweaks.WalkSnapshots[humanoid] = humanoid.WalkSpeed
        end
        if PlayerTweaks.WalkSpeedEnabled then
            humanoid.WalkSpeed = PlayerTweaks.WalkSpeed
        end
    end

    Hub.SetWalkSpeedEnabled = function(enabled)
        PlayerTweaks.WalkSpeedEnabled = enabled and true or false
        local humanoid = GetHumanoid()
        if not humanoid then
            return
        end
        if PlayerTweaks.WalkSpeedEnabled then
            ApplyWalkSpeed(humanoid)
        elseif PlayerTweaks.WalkSnapshots[humanoid] ~= nil then
            humanoid.WalkSpeed = PlayerTweaks.WalkSnapshots[humanoid]
        end
    end

    Hub.SetWalkSpeedValue = function(value)
        PlayerTweaks.WalkSpeed = value
        if PlayerTweaks.WalkSpeedEnabled then
            local humanoid = GetHumanoid()
            if humanoid then
                humanoid.WalkSpeed = value
            end
        end
    end

    Hub.SetInfJump = function(enabled)
        PlayerTweaks.InfJump = enabled and true or false
        if PlayerTweaks.InfJumpConn then
            PlayerTweaks.InfJumpConn:Disconnect()
            PlayerTweaks.InfJumpConn = nil
        end
        if not PlayerTweaks.InfJump then
            return
        end
        PlayerTweaks.InfJumpConn = UserInputService.JumpRequest:Connect(function()
            if not IsLoaded() or not PlayerTweaks.InfJump then
                return
            end
            local humanoid = GetHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end

    Hub.SetNoClip = function(enabled)
        PlayerTweaks.NoClip = enabled and true or false
        if PlayerTweaks.NoClipConn then
            PlayerTweaks.NoClipConn:Disconnect()
            PlayerTweaks.NoClipConn = nil
        end

        local character = LocalPlayer.Character
        if not PlayerTweaks.NoClip then
            for part, canCollide in pairs(PlayerTweaks.NoClipSnapshots) do
                if part and part.Parent then
                    part.CanCollide = canCollide
                end
            end
            table.clear(PlayerTweaks.NoClipSnapshots)
            return
        end

        local function disableCollision(part)
            if part:IsA("BasePart") and PlayerTweaks.NoClipSnapshots[part] == nil then
                PlayerTweaks.NoClipSnapshots[part] = part.CanCollide
                part.CanCollide = false
            end
        end

        if character then
            for _, descendant in ipairs(character:GetDescendants()) do
                disableCollision(descendant)
            end
            PlayerTweaks.NoClipConn = character.DescendantAdded:Connect(function(descendant)
                if PlayerTweaks.NoClip then
                    disableCollision(descendant)
                end
            end)
        end
    end

    Hub.SetFly = function(enabled)
        PlayerTweaks.Fly = enabled and true or false
        if PlayerTweaks.FlyConn then
            PlayerTweaks.FlyConn:Disconnect()
            PlayerTweaks.FlyConn = nil
        end

        local humanoid = GetHumanoid()
        if not PlayerTweaks.Fly then
            if humanoid and PlayerTweaks.FlyPlatformStand ~= nil then
                humanoid.PlatformStand = PlayerTweaks.FlyPlatformStand
            end
            PlayerTweaks.FlyPlatformStand = nil
            return
        end

        if humanoid then
            PlayerTweaks.FlyPlatformStand = humanoid.PlatformStand
            humanoid.PlatformStand = true
        end

        PlayerTweaks.FlyConn = RunService.RenderStepped:Connect(function()
            if not IsLoaded() or not PlayerTweaks.Fly then
                return
            end
            if UserInputService:GetFocusedTextBox() then
                return
            end

            local root = GetRoot()
            local camera = Map.CurrentCamera
            if not (root and camera) then
                return
            end

            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                direction = direction + Vector3.yAxis
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                direction = direction - Vector3.yAxis
            end

            if direction.Magnitude > 0 then
                root.AssemblyLinearVelocity = direction.Unit * PlayerTweaks.FlySpeed
            else
                root.AssemblyLinearVelocity = Vector3.zero
            end
        end)
    end

    Hub.SetFlySpeed = function(value)
        PlayerTweaks.FlySpeed = value
    end

    Hub.SetInstantProximityPrompt = function(enabled)
        PlayerTweaks.InstantPP = enabled and true or false
        if PlayerTweaks.InstantConn then
            PlayerTweaks.InstantConn:Disconnect()
            PlayerTweaks.InstantConn = nil
        end

        local function restoreAll()
            for prompt, snapshot in pairs(PlayerTweaks.InstantSnapshots) do
                if prompt and prompt.Parent then
                    prompt.HoldDuration = snapshot.HoldDuration
                    prompt.MaxActivationDistance = snapshot.MaxActivationDistance
                    prompt.RequiresLineOfSight = snapshot.RequiresLineOfSight
                end
            end
            table.clear(PlayerTweaks.InstantSnapshots)
        end

        if not PlayerTweaks.InstantPP then
            restoreAll()
            return
        end

        local function patchPrompt(prompt)
            if not prompt:IsA("ProximityPrompt") then
                return
            end
            if PlayerTweaks.InstantSnapshots[prompt] == nil then
                PlayerTweaks.InstantSnapshots[prompt] = {
                    HoldDuration = prompt.HoldDuration,
                    MaxActivationDistance = prompt.MaxActivationDistance,
                    RequiresLineOfSight = prompt.RequiresLineOfSight,
                }
            end
            prompt.HoldDuration = 0
            prompt.MaxActivationDistance = 50
            prompt.RequiresLineOfSight = false
        end

        for _, descendant in ipairs(Map:GetDescendants()) do
            patchPrompt(descendant)
        end
        PlayerTweaks.InstantConn = Map.DescendantAdded:Connect(function(descendant)
            if PlayerTweaks.InstantPP then
                patchPrompt(descendant)
            end
        end)
    end

    local function OnCharacterAdded(character)
        task.defer(function()
            if not IsLoaded() then
                return
            end
            local humanoid = character:WaitForChild("Humanoid", 10)
            if not humanoid then
                return
            end
            if PlayerTweaks.WalkSpeedEnabled then
                ApplyWalkSpeed(humanoid)
            end
            if PlayerTweaks.NoClip then
                Hub.SetNoClip(true)
            end
            if PlayerTweaks.Fly then
                Hub.SetFly(true)
            end
        end)
    end

    if LocalPlayer.Character then
        OnCharacterAdded(LocalPlayer.Character)
    end
    local characterConn = LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
    Hub.Track(function()
        characterConn:Disconnect()
    end)

    Hub.Track(function()
        Hub.SetWalkSpeedEnabled(false)
        Hub.SetInfJump(false)
        Hub.SetNoClip(false)
        Hub.SetFly(false)
        Hub.SetInstantProximityPrompt(false)
    end)
end

--// ============================================================
--//  Misc tweaks  (anti-afk, reconnect, fps)
--// ============================================================
local MiscTweaks = {
    AntiAfk = true,
    NoGameplayPaused = true,
    AutoReconnect = false,
    Disable3D = false,
    FpsBoost = false,
    AfkConn = nil,
    AfkTask = nil,
    AfkCount = 0,
    ReconnectConns = {},
    FpsSnapshots = {},
    FpsConn = nil,
}

do
    local function SimulateAfkInput()
        if not Map.CurrentCamera then
            return false
        end
        if not (IsFunction(VirtualUser.CaptureController) and IsFunction(VirtualUser.ClickButton2)) then
            return false
        end
        local ok = pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        if ok then
            MiscTweaks.AfkCount = MiscTweaks.AfkCount + 1
        end
        return ok
    end

    Hub.SetAntiAfk = function(enabled)
        MiscTweaks.AntiAfk = enabled and true or false
        if MiscTweaks.AfkConn then
            MiscTweaks.AfkConn:Disconnect()
            MiscTweaks.AfkConn = nil
        end
        if MiscTweaks.AfkTask then
            pcall(task.cancel, MiscTweaks.AfkTask)
            MiscTweaks.AfkTask = nil
        end
        if not MiscTweaks.AntiAfk then
            return
        end

        MiscTweaks.AfkConn = LocalPlayer.Idled:Connect(function()
            if IsLoaded() and MiscTweaks.AntiAfk then
                SimulateAfkInput()
            end
        end)
        MiscTweaks.AfkTask = task.spawn(function()
            local last = os.clock()
            while IsLoaded() and MiscTweaks.AntiAfk do
                task.wait(1)
                if not IsLoaded() or not MiscTweaks.AntiAfk then
                    break
                end
                if os.clock() - last >= 60 then
                    last = os.clock()
                    SimulateAfkInput()
                end
            end
        end)
    end

    Hub.SetNoGameplayPaused = function(enabled)
        MiscTweaks.NoGameplayPaused = enabled and true or false
    end

    Hub.SetAutoReconnect = function(enabled)
        MiscTweaks.AutoReconnect = enabled and true or false
        for _, conn in ipairs(MiscTweaks.ReconnectConns) do
            conn:Disconnect()
        end
        table.clear(MiscTweaks.ReconnectConns)
        if not MiscTweaks.AutoReconnect then
            return
        end
        table.insert(MiscTweaks.ReconnectConns, TeleportService.TeleportInitFailed:Connect(function()
            if not IsLoaded() or not MiscTweaks.AutoReconnect then
                return
            end
            task.wait(1)
            if IsLoaded() and MiscTweaks.AutoReconnect then
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
            end
        end))
    end

    Hub.SetDisable3D = function(enabled)
        MiscTweaks.Disable3D = enabled and true or false
        pcall(function()
            RunService:Set3dRenderingEnabled(not MiscTweaks.Disable3D)
        end)
    end

    Hub.SetFpsBoost = function(enabled)
        MiscTweaks.FpsBoost = enabled and true or false
        if MiscTweaks.FpsConn then
            MiscTweaks.FpsConn:Disconnect()
            MiscTweaks.FpsConn = nil
        end

        local function restoreAll()
            for instance, snapshot in pairs(MiscTweaks.FpsSnapshots) do
                if instance and instance.Parent then
                    for key, value in pairs(snapshot) do
                        pcall(function()
                            instance[key] = value
                        end)
                    end
                end
            end
            table.clear(MiscTweaks.FpsSnapshots)
        end

        if not MiscTweaks.FpsBoost then
            restoreAll()
            return
        end

        local function disableEffects(instance)
            if MiscTweaks.FpsSnapshots[instance] then
                return
            end
            local isEffect = instance:IsA("ParticleEmitter")
                or instance:IsA("Trail")
                or instance:IsA("Beam")
                or instance:IsA("Fire")
                or instance:IsA("Smoke")
                or instance:IsA("Sparkles")
            if isEffect then
                MiscTweaks.FpsSnapshots[instance] = { Enabled = instance.Enabled }
                instance.Enabled = false
            end
        end

        for _, descendant in ipairs(Map:GetDescendants()) do
            disableEffects(descendant)
        end
        if MiscTweaks.FpsSnapshots[Lighting] == nil then
            MiscTweaks.FpsSnapshots[Lighting] = {
                GlobalShadows = Lighting.GlobalShadows,
                FogEnd = Lighting.FogEnd,
            }
            Lighting.GlobalShadows = false
        end
        MiscTweaks.FpsConn = Map.DescendantAdded:Connect(function(descendant)
            if MiscTweaks.FpsBoost then
                disableEffects(descendant)
            end
        end)
    end

    Hub.Track(function()
        Hub.SetAntiAfk(false)
        Hub.SetAutoReconnect(false)
        Hub.SetDisable3D(false)
        Hub.SetFpsBoost(false)
    end)
end

--// ============================================================
--//  UI  |  Rayfield Gen2
--// ============================================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
if not (type(Rayfield) == "table" and IsFunction(Rayfield.CreateWindow)) then
    pcall(Hub.Unload)
    error("[" .. SCRIPT_NAME .. "] Could not load Rayfield Gen2 - check your connection / executor HttpGet.", 0)
end

local GOLD    = Color3.fromHex("#F5C542")
local EMERALD = Color3.fromHex("#2ECC71")

Window = Rayfield:CreateWindow({
    name = SCRIPT_NAME,
    subtitle = "by " .. HUB_NAME .. "  ·  " .. DISCORD_TAG,
    profile = HUB_NAME,
    showName = SCRIPT_NAME,
    sidebarLayout = true,
    theme = {
        WindowColor = Color3.fromHex("#08150D"),
        TabColor = GOLD,
        TabBackground = ColorSequence.new(Color3.fromHex("#12301F"), Color3.fromHex("#1E5A37")),
        AccentColor = EMERALD,
        AccentStroke = EMERALD,
        ContentColor = Color3.fromHex("#EAFFF1"),
    },
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "VenxzCSK_StealFromTheRich",
    },
})

Hub.Track(function()
    pcall(function()
        Window:Unload()
    end)
end)

Window:CreateTag({ text = SCRIPT_VER, color = Color3.fromHex("#1E5A37") })
Window:CreateTag({ text = "Venxz CSK", color = GOLD })

--// Tabs -------------------------------------------------------
local TabInfo      = Window:CreateTab({ name = "Info" })
local TabFarm      = Window:CreateTab({ name = "Auto Farm" })
local TabBase      = Window:CreateTab({ name = "Base" })
local TabTeleport  = Window:CreateTab({ name = "Teleport" })
local TabPlayer    = Window:CreateTab({ name = "Player" })
local TabSettings  = Window:CreateTab({ name = "Settings" })

--// Info tab ---------------------------------------------------
TabInfo:CreateSection({ name = "About" })
TabInfo:CreateText({
    name = SCRIPT_NAME .. "  " .. SCRIPT_VER,
    text = "Rayfield Gen2 Edition  ·  by " .. HUB_NAME
        .. "\nDiscord: " .. DISCORD_URL,
})

TabInfo:CreateSection({ name = "Discord" })
TabInfo:CreateText({
    name = "Join the community",
    text = DISCORD_URL,
})
TabInfo:CreateButton({
    name = "Copy Discord Link",
    description = DISCORD_TAG,
    callback = function()
        CopyToClipboard(DISCORD_URL, "Discord link copied")
    end,
})

TabInfo:CreateSection({ name = "User" })
TabInfo:CreateText({
    name = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")",
    text = "UserId: " .. tostring(LocalPlayer.UserId),
})
TabInfo:CreateText({
    name = "Executor",
    text = executorName .. "  " .. ExecutorStatus,
})
TabInfo:CreateButton({
    name = "Copy Username",
    callback = function()
        CopyToClipboard(LocalPlayer.Name, "Copied username")
    end,
})
TabInfo:CreateButton({
    name = "Copy Profile Link",
    callback = function()
        CopyToClipboard("https://www.roblox.com/users/" .. tostring(LocalPlayer.UserId) .. "/profile", "Copied profile link")
    end,
})

TabInfo:CreateSection({ name = "Session" })
local SessionText = TabInfo:CreateText({ name = "Live", text = "Loading..." })
local jobId = tostring(game.JobId)
local jobShort = (#jobId > 18) and (string.sub(jobId, 1, 18) .. "...") or jobId
TabInfo:CreateText({
    name = "Game",
    text = SCRIPT_NAME .. "\nJob: " .. jobShort,
})
TabInfo:CreateButton({
    name = "Rejoin Place",
    callback = function()
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end,
})
TabInfo:CreateButton({
    name = "Copy Job ID",
    callback = function()
        CopyToClipboard(jobId, "Copied Job ID")
    end,
})

local startedAt = os.clock()
local function SessionUptime()
    local s = math.floor(os.clock() - startedAt)
    if s < 60 then
        return s .. "s"
    elseif s < 3600 then
        return string.format("%dm %ds", s // 60, s % 60)
    end
    return string.format("%dh %dm", s // 3600, s % 3600 // 60)
end

local sessionWorker = task.spawn(function()
    while IsLoaded() do
        task.wait(1)
        if not IsLoaded() then
            break
        end
        local okPing, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        local pingText = okPing and (ping .. " ms") or "n/a"
        local players = #Players:GetPlayers() .. "/" .. tostring(Players.MaxPlayers)
        pcall(function()
            SessionText:Set(string.format(
                "Uptime: %s\nPlayers: %s\nPing: %s\nSteal: %s (x%d)",
                SessionUptime(), players, pingText, tostring(State.StealStatus), State.StealCount
            ))
        end)
    end
end)
Hub.Track(function()
    pcall(task.cancel, sessionWorker)
end)

--// Auto Farm tab ----------------------------------------------
TabFarm:CreateSection({ name = "Steal" })
TabFarm:CreateToggle({
    name = "Auto Steal",
    description = "Teleport + fire prompts instantly and chain crates",
    flag = "AutoSteal",
    callback = function(value)
        Hub.SetSteal(value)
    end,
})
TabFarm:CreateSlider({
    name = "Fire Burst",
    description = "Prompt fires per frame while grabbing",
    flag = "StealBurst",
    range = { 1, 5 },
    increment = 1,
    value = 3,
    callback = function(value)
        Hub.SetStealBurst(value)
    end,
})
TabFarm:CreateDropdown({
    name = "Zone Filter",
    description = "Zones to steal from",
    flag = "StealZoneFilter",
    multiSelect = true,
    options = ZoneDisplayNames,
    value = table.clone(ZoneDisplayNames),
    callback = function(selected)
        Hub.SetZoneFilter(selected)
    end,
})
TabFarm:CreateDropdown({
    name = "Rarity Filter",
    description = "Crate rarities to steal",
    flag = "StealRarityFilter",
    multiSelect = true,
    options = Rarities,
    value = table.clone(Rarities),
    callback = function(selected)
        Hub.SetRarityFilter(selected)
    end,
})

TabFarm:CreateSection({ name = "Sell" })
TabFarm:CreateToggle({
    name = "Auto Sell",
    description = "Sell items automatically",
    flag = "AutoSell",
    callback = function(value)
        Hub.SetSell(value)
    end,
})
TabFarm:CreateToggle({
    name = "Teleport to Seller while Selling",
    description = "Walk to the seller NPC for each sale",
    flag = "TeleportToSellerWhileSelling",
    callback = function(value)
        Hub.SetTeleportToSellerWhileSelling(value)
    end,
})
TabFarm:CreateDropdown({
    name = "Sell Mode",
    description = "Held = current item, All = whole inventory",
    flag = "SellMode",
    options = SELL_MODES,
    value = "All",
    callback = function(mode)
        Hub.SetSellMode(mode)
    end,
})

--// Base tab ---------------------------------------------------
TabBase:CreateSection({ name = "Plot" })
TabBase:CreateToggle({
    name = "Auto Place",
    description = "Place items on your plot",
    flag = "AutoPlace",
    callback = function(value)
        Hub.SetPlace(value)
    end,
})
TabBase:CreateToggle({
    name = "Auto Open",
    description = "Open crates automatically",
    flag = "AutoOpen",
    callback = function(value)
        Hub.SetOpen(value)
    end,
})
TabBase:CreateToggle({
    name = "Auto Equip Best",
    description = "Keep your best items equipped",
    flag = "AutoEquipBest",
    callback = function(value)
        Hub.SetEquipBest(value)
    end,
})
TabBase:CreateToggle({
    name = "Auto Buy +1 Equip Slot",
    description = "Buy extra equip slots",
    flag = "AutoBuyEquipSlot",
    callback = function(value)
        Hub.SetBuyEquipSlot(value)
    end,
})
TabBase:CreateToggle({
    name = "Auto Upgrade Plot",
    description = "Upgrade your plot",
    flag = "AutoUpgradePlot",
    callback = function(value)
        Hub.SetUpgradePlot(value)
    end,
})

TabBase:CreateSection({ name = "Treadmill" })
TabBase:CreateToggle({
    name = "Auto Go On Treadmill",
    description = "Hop on your treadmill",
    flag = "AutoTreadmill",
    callback = function(value)
        Hub.SetTreadmill(value)
    end,
})
TabBase:CreateToggle({
    name = "Auto Upgrade Treadmill",
    description = "Upgrade the treadmill",
    flag = "AutoUpgradeTreadmill",
    callback = function(value)
        Hub.SetUpgradeTreadmill(value)
    end,
})

TabBase:CreateSection({ name = "Collection" })
TabBase:CreateToggle({
    name = "Auto Claim Index",
    description = "Claim index rewards",
    flag = "AutoClaimIndex",
    callback = function(value)
        Hub.SetClaimIndex(value)
    end,
})
TabBase:CreateToggle({
    name = "Auto Buy Trails",
    description = "Buy new trails",
    flag = "AutoBuyTrails",
    callback = function(value)
        Hub.SetBuyTrails(value)
    end,
})

--// Teleport tab -----------------------------------------------
TabTeleport:CreateSection({ name = "Base" })
TabTeleport:CreateButton({
    name = "Teleport to Base",
    callback = function()
        if not Hub.TeleportToBase() then
            Notify("Base not found", 3)
        end
    end,
})

TabTeleport:CreateSection({ name = "Zones" })
local selectedZone = ZoneDisplayNames[1]
TabTeleport:CreateDropdown({
    name = "Zone",
    description = "Pick a destination",
    flag = "TeleportZone",
    options = ZoneDisplayNames,
    value = selectedZone,
    callback = function(zone)
        selectedZone = zone
    end,
})
TabTeleport:CreateButton({
    name = "Teleport to Zone",
    callback = function()
        if not Hub.TeleportToZone(selectedZone) then
            Notify("Zone not found", 3)
        end
    end,
})

--// Player tab -------------------------------------------------
TabPlayer:CreateSection({ name = "Movement" })
TabPlayer:CreateToggle({
    name = "WalkSpeed",
    description = "Override your walk speed",
    flag = "WalkSpeedEnabled",
    callback = function(value)
        Hub.SetWalkSpeedEnabled(value)
    end,
})
TabPlayer:CreateSlider({
    name = "WalkSpeed Amount",
    flag = "WalkSpeed",
    range = { 16, 250 },
    increment = 1,
    value = 32,
    callback = function(value)
        Hub.SetWalkSpeedValue(value)
    end,
})
TabPlayer:CreateToggle({
    name = "Infinite Jump",
    description = "Jump again in mid-air",
    flag = "InfJump",
    callback = function(value)
        Hub.SetInfJump(value)
    end,
})
TabPlayer:CreateToggle({
    name = "Noclip",
    description = "Walk through walls",
    flag = "NoClip",
    callback = function(value)
        Hub.SetNoClip(value)
    end,
})
TabPlayer:CreateToggle({
    name = "Instant ProximityPrompt",
    description = "No hold time, longer reach",
    flag = "InstantProximityPrompt",
    callback = function(value)
        Hub.SetInstantProximityPrompt(value)
    end,
})

TabPlayer:CreateSection({ name = "Fly" })
TabPlayer:CreateToggle({
    name = "Fly",
    description = "WASD + Space / Left Ctrl",
    flag = "Fly",
    callback = function(value)
        Hub.SetFly(value)
    end,
})
TabPlayer:CreateSlider({
    name = "Fly Speed",
    flag = "FlySpeed",
    range = { 10, 400 },
    increment = 1,
    value = 60,
    callback = function(value)
        Hub.SetFlySpeed(value)
    end,
})

--// Settings tab -----------------------------------------------
TabSettings:CreateSection({ name = "Utilities" })
TabSettings:CreateToggle({
    name = "Anti-AFK",
    description = "Prevents the idle kick",
    flag = "AntiAfk",
    value = true,
    callback = function(value)
        Hub.SetAntiAfk(value)
    end,
})
TabSettings:CreateToggle({
    name = "No Gameplay Paused",
    flag = "NoGameplayPaused",
    value = true,
    callback = function(value)
        Hub.SetNoGameplayPaused(value)
    end,
})
TabSettings:CreateToggle({
    name = "Auto Reconnect on Kick",
    description = "Rejoin when a teleport fails",
    flag = "AutoReconnect",
    callback = function(value)
        Hub.SetAutoReconnect(value)
    end,
})
TabSettings:CreateToggle({
    name = "Disable 3D Rendering",
    description = "Saves GPU while AFK farming",
    flag = "Disable3DRendering",
    callback = function(value)
        Hub.SetDisable3D(value)
    end,
})
TabSettings:CreateToggle({
    name = "FPS Boost",
    description = "Turns off particles, trails and shadows",
    flag = "FpsBoost",
    callback = function(value)
        Hub.SetFpsBoost(value)
    end,
})

TabSettings:CreateSection({ name = "Interface" })
TabSettings:CreateKeybind({
    name = "Menu Keybind",
    description = "Show / hide the window",
    value = Enum.KeyCode.RightShift,
    forgetState = true,
    callback = function()
        pcall(function()
            Window:ToggleHide()
        end)
    end,
})

TabSettings:CreateSection({ name = "Discord" })
TabSettings:CreateButton({
    name = "Copy Discord Link",
    description = DISCORD_TAG,
    callback = function()
        CopyToClipboard(DISCORD_URL, "Discord link copied")
    end,
})

TabSettings:CreateSection({ name = "Config" })
TabSettings:CreateButton({
    name = "Save Config",
    callback = function()
        local ok, saved = pcall(function()
            return Window:Save()
        end)
        Notify(ok and saved and "Config saved" or "Could not save config", 3)
    end,
})
TabSettings:CreateButton({
    name = "Load Config",
    callback = function()
        local ok, loaded = pcall(function()
            return Window:Load()
        end)
        Notify(ok and loaded and "Config loaded" or "Could not load config", 3)
    end,
})

TabSettings:CreateSection({ name = "Script" })
TabSettings:CreateButton({
    name = "Unload Script",
    description = "Turn everything off and remove the menu",
    callback = function()
        pcall(Hub.Unload)
    end,
})

--// ============================================================
--//  Defaults & start-up
--// ============================================================
Hub.SetAntiAfk(true)
Hub.SetNoGameplayPaused(true)
Hub.SetZoneFilter(table.clone(ZoneDisplayNames))
Hub.SetRarityFilter(table.clone(Rarities))
Hub.SetSellMode("All")
Hub.SetStealBurst(3)
Hub.SetTeleportToSellerWhileSelling(false)

pcall(function()
    TabFarm:Select()
end)

Notify(SCRIPT_NAME .. " " .. SCRIPT_VER .. " loaded  ·  by " .. HUB_NAME .. "  ·  " .. DISCORD_TAG, 5)
