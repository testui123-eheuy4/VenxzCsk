--[[============================================================================
    VENXZ CSK  |  Open Sea For Animals
    Menu: Rayfield Gen2 (https://sirius.menu/gen2)
    Discord: https://discord.gg/GC5M2tpbG9

    File order
      1. Guards and branding
      2. Services, config and state
      3. Window Rayfield
      4. Element features
      5. Helpers and the main feature functions
      6. Boot
============================================================================]]--

--[[==============================================================================
    1.  GUARDS AND BRANDING
==============================================================================]]--
if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.GameId ~= 10765091041 then
    game:GetService("Players").LocalPlayer:Kick("Venxz CSK : this script is for Open Sea For Animals only")
    return
end

local VenxzBanner = {
    Print = print,
    Started = os.clock(),
    Last = os.clock(),
    Done = 0,
    Total = 4,
}

function VenxzBanner.Show()
    local ok, executor = pcall(identifyexecutor)
    if not ok or type(executor) ~= "string" then executor = "Unknown" end
    local rule = string.rep("=", 71)
    VenxzBanner.Print(table.concat({
        "",
        [[
@@=   @@=@@@@@@@=@@@=   @@=@@=  @@=@@@@@@@=     @@@@@@=@@@@@@@=@@=  @@=
@@=   @@=@@======@@@@=  @@==@@=@@=====@@@==    @@======@@======@@= @@==
@@=   @@=@@@@@=  @@=@@= @@= =@@@==   @@@==     @@=     @@@@@@@=@@@@@==
=@@= @@==@@====  @@==@@=@@= @@=@@=  @@@==      @@=     =====@@=@@==@@=
 =@@@@== @@@@@@@=@@= =@@@@=@@== @@=@@@@@@@=    =@@@@@@=@@@@@@@=@@=  @@=
  =====  ===========  ========  ===========     ==================  ===
]],
        rule,
        "   OPEN SEA FOR ANIMALS  |  by Venxz CSK  |  discord.gg/GC5M2tpbG9",
        "   executor: " .. executor .. "   |   player: " .. game:GetService("Players").LocalPlayer.Name,
        rule,
    }, "\n"))
end

---@param label string  what just finished loading
function VenxzBanner.Step(label)
    local now = os.clock()
    VenxzBanner.Done = math.min(VenxzBanner.Done + 1, VenxzBanner.Total)
    local filled = math.floor(VenxzBanner.Done / VenxzBanner.Total * 20 + 0.5)
    VenxzBanner.Print(string.format("[Venxz CSK] [%s] %3d%%  %-24s +%dms",
        string.rep("#", filled) .. string.rep(".", 20 - filled),
        math.floor(VenxzBanner.Done / VenxzBanner.Total * 100), label, math.floor((now - VenxzBanner.Last) * 1000)))
    VenxzBanner.Last = now
end

function VenxzBanner.Ready()
    local rule = string.rep("=", 71)
    VenxzBanner.Print(table.concat({
        rule,
        string.format("   >> READY in %dms", math.floor((os.clock() - VenxzBanner.Started) * 1000)),
        rule,
    }, "\n"))
end

do
    local ok, renv = pcall(getrenv)
    if ok and type(renv) == "table" and type(renv.print) == "function" then
        VenxzBanner.Print = renv.print
    end
end

pcall(VenxzBanner.Show)
pcall(VenxzBanner.Step, "Core")

if not LPH_OBFUSCATED then
    local function Passthrough(fn) return fn end
    LPH_JIT, LPH_JIT_MAX, LPH_NO_VIRTUALIZE = Passthrough, Passthrough, Passthrough
end

--[[==============================================================================
    2.  SERVICES, CONFIG AND STATE
==============================================================================]]--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Venxz = setmetatable({}, {
    __newindex = function(self, key, value)
        rawset(self, key, type(value) == "function" and LPH_JIT(value) or value)
    end,
})

Venxz.GameLib = {}
local GameLib = Venxz.GameLib

Venxz.Config = {
    Discord = "https://discord.gg/GC5M2tpbG9",
    DiscordInvite = "GC5M2tpbG9",
    RememberJoins = true,
    MenuKey = Enum.KeyCode.LeftControl,
    Theme = "cobalt",
    UpdateLog = {
        { "2026-10-08", "Rebuilt on the Rayfield Gen2 menu\nNew Venxz CSK Discord: discord.gg/GC5M2tpbG9\nEvery feature carried over, nothing dropped" },
        { "2026-10-05", "Auto Pickaxe, Auto Potion, Spin Wheel and Season Pass\nEvent pickups, Fullbright, Teleport and Server Hop\nAuto Sell Brainrots fixed, bigger status panel" },
        { "2026-10-03", "Venxz CSK UI is back\nBetter executor support\nAuto Loot stops when full\nAuto-detect Upgrades" },
    },
    UiSource = "https://sirius.menu/gen2",
    LoadTries = 4,
    LoadRetry = 2,
    ServerList = "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100",
    SaveFolder = "Venxz CSK",
    SaveName = "Open Sea For Animals",
    LoadTimeout = 10,
    AlertTries = 20,
    AlertRetry = 0.5,
    JobFailLimit = 5,
    JobFailWindow = 10,
    TickDelay = 0.25,
    LootWorkers = 3,
    WaveExtension = 5,
    LootIdle = 1,
    ResumeInterval = 0.5,
    ResumeBackoff = 30,
    InventoryLimit = 200,
    PlotRecheck = 30,
    ClaimInterval = 30,
    UpgradeInterval = 3,
    SellInterval = 2,
    PotionInterval = 5,
    PickupInterval = 1,
    PickupHop = 0.15,
    PickupsPerTick = 12,
    FullbrightInterval = 1,
    SpinCost = 25,
    Codes = { "Release", "SORRYFORRESTARTGUYSTPBUG3", "MASTERY", "GHOULUPDATE" },
    PlaytimeSlots = 12,
    DailyDays = 7,
    PlaceEggTries = 3,
    FallbackUpgrades = { "Carry", "MovementSpeed", "PlotUpgrade" },
    NoclipParts = { "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" },
    Fullbright = { Brightness = 2, ClockTime = 14, FogEnd = 1e5, GlobalShadows = false, Ambient = Color3.fromRGB(178, 178, 178) },
    KaitunKeys = {
        "AutoLoot", "AutoSellEggs", "AutoTrain", "AutoHatch", "AutoBuyTool", "AutoPickaxe", "AutoUpgrade",
        "AutoRebirth", "AutoClaim", "AutoSpin", "AutoPass", "AutoEquipBest",
    },
}

Venxz.State = {
    Alive = true,
    Busy = false,
    Conns = {},
    Requests = {},
    Messages = {},
    Halted = {},
    Summary = "Loading...",
    StartCash = nil,
    StartPower = nil,
    Looted = 0,
    Picked = 0,
    LootFull = nil,
    LootReserved = 0,
    Resume = { last = 0, fails = 0, retryAt = 0 },
    SpeedBase = nil,
    PlotFull = nil,
    Trained = false,
    SpeedPinned = false,
    LightingSaved = nil,
    UpgradeNames = {},
    UpgradesChanged = false,
    PotionNames = {},
    Opt = {
        AutoLoot = false,
        LootKeep = {},
        AutoSellEggs = false,
        SellKeep = {},
        AutoSellBrainrots = false,
        AutoEquipBest = false,
        AutoUpgrade = false,
        UpgradePick = {},
        CashReserve = 0,
        AutoRebirth = false,
        AutoTrain = false,
        AutoHatch = false,
        AutoBuyTool = false,
        AutoPickaxe = false,
        AutoPotion = false,
        PotionPick = {},
        AutoClaim = false,
        AutoSpin = false,
        AutoPass = false,
        AutoPickups = false,
        Speed = false,
        SpeedValue = 60,
        InfJump = false,
        Noclip = false,
        Fullbright = false,
        AntiAfk = false,
        CodeInput = "",
        TeleportTarget = nil,
    },
}

local Config, State = Venxz.Config, Venxz.State
State.UpgradeNames = table.clone(Config.FallbackUpgrades)

--[[============================================================================
    3.  WINDOW RAYFIELD
        Rayfield Gen2 shell: the library load, the window itself, the Discord
        invite prompt and the LeftControl menu hotkey. Definitions only, nothing
        here runs until BuildInterface() at the boot below.
============================================================================]]--

Venxz.UI = {}

local Window = nil      ---@type table?  the Gen2 window handle
local Rayfield = nil    ---@type table?  the Gen2 library

local NOTIFY_TITLES = {
    Info = "Venxz CSK",
    Success = "Venxz CSK  |  Success",
    Warning = "Venxz CSK  |  Warning",
    Error = "Venxz CSK  |  Error",
}

---@param text string
---@param kind string?  Info (default), Success, Warning or Error
function Venxz.UI.Notify(text, kind)
    if not Window then return end
    Window:Notify({
        title = NOTIFY_TITLES[kind] or NOTIFY_TITLES.Info,
        content = text,
        duration = 4,
    })
end

---Asks the desktop Discord client to open the invite, the way Rayfield does.
---RememberJoins keeps a marker file so a player is only ever asked once.
function Venxz.UI.PromptDiscord()
    local invite = Config.DiscordInvite
    if not invite or invite == "" then return end

    local send = (type(request) == "function" and request) or (type(http_request) == "function" and http_request)
        or (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request)
    if type(send) ~= "function" then
        Venxz.UI.Notify("Join the Venxz CSK Discord: " .. Config.Discord, "Warning")
        return
    end

    local folder = Config.SaveFolder .. "/Discord Invites"
    local marker = folder .. "/" .. invite .. ".txt"
    pcall(function()
        if type(makefolder) ~= "function" then return end
        if type(isfolder) == "function" and not isfolder(Config.SaveFolder) then makefolder(Config.SaveFolder) end
        if type(isfolder) == "function" and not isfolder(folder) then makefolder(folder) end
    end)

    local asked = false
    pcall(function()
        if type(isfile) == "function" and isfile(marker) then asked = true end
    end)
    if asked then return end

    local opened = pcall(function()
        send({
            Url = "http://127.0.0.1:6463/rpc?v=1",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
            Body = HttpService:JSONEncode({
                cmd = "INVITE_BROWSER",
                nonce = HttpService:GenerateGUID(false),
                args = { code = invite },
            }),
        })
    end)

    if Config.RememberJoins then
        pcall(function()
            if type(writefile) == "function" then
                writefile(marker, "Venxz CSK: RememberJoins is on for this invite, you will not be asked again.")
            end
        end)
    end

    if opened then
        Venxz.UI.Notify("Opening the Venxz CSK Discord invite...")
    else
        Venxz.UI.Notify("Discord is not running. Join us: " .. Config.Discord, "Warning")
    end
end

---LeftControl hides and shows the menu, the old MenuKey behaviour. Gen2 has no
---window hotkey of its own, so the binding is ours and dies with Scheduler.Stop.
function Venxz.UI.BindMenuKey()
    if not Config.MenuKey then return end
    local conn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or input.KeyCode ~= Config.MenuKey then return end
        if Window and not Window.unloaded then Window:ToggleHide() end
    end)
    State.Conns[#State.Conns + 1] = conn
end

---@return table?  window handle, nil when Rayfield would not load
function Venxz.UI.CreateWindow()
    Rayfield = Venxz.Util.LoadLibrary()
    if not Rayfield then return nil end
    pcall(VenxzBanner.Step, "UI library")

    Window = Rayfield:CreateWindow({
        name = "Venxz CSK",
        subtitle = "Open Sea For Animals",
        sidebarLayout = true,
        theme = Config.Theme,
        profile = "Open Sea For Animals",
        showName = "Venxz CSK",
        configuration = {
            autoSave = true,
            autoLoad = true,
            fileName = Config.SaveName,
            customFolder = Config.SaveFolder,
        },
    })

    Venxz.UI.PromptDiscord()
    Venxz.UI.BindMenuKey()
    return Window
end

--[[============================================================================
    4.  ELEMENT FEATURES
        Every tab, group and control of the menu. This is a definition: it runs
        from the boot at the bottom, once the feature functions below exist.

        Gen2 layout notes
          * a tab holds a CreateGroup() row, and the row holds the two column
            groups that used to be AddLeftGroupbox / AddRightGroupbox
          * a column starts each groupbox with CreateSection, the old title
          * input and keybind are full width, so they are created on the tab
            itself and land underneath the two columns
          * Compat.Block became Lock(): the control greys out, refuses input and
            cannot fire its callback, and Blocked[] refuses it from code too
============================================================================]]--

local Options = {}      ---@type table<string, table>  every value element, by feature key
local Toggles = {}      ---@type table<string, table>  toggles only, by feature key
local Blocked = {}      ---@type table<string, string>  feature key -> why it may not turn on
local widgets = {}      ---@type table<string, table>  handles the pump drives

---@param selected string[]?  Gen2 hands a multi select back as a list
---@return table  { [name] = true }, the shape every feature reads
local function ToSet(selected)
    local set = {}
    for _, name in ipairs(selected or {}) do set[name] = true end
    return set
end

---@return boolean  false when the menu could not load
local function BuildInterface()
    local window = Venxz.UI.CreateWindow()
    if not window then return false end

    local opt = State.Opt
    local Notify = Venxz.UI.Notify

    local keepValues = {}
    Venxz.Util.Try(function()
        for _, name in ipairs(Venxz.Util.RarityNames()) do keepValues[#keepValues + 1] = name end
        for _, name in ipairs(Venxz.Util.MutationNames()) do table.insert(keepValues, name) end
    end)

    --[[--------------------------------------------------------------------------
        element factories
    --------------------------------------------------------------------------]]--

    ---@param idx string?  feature whose game modules the request needs
    local function Request(name, idx)
        return function()
            if idx and GameLib.Missing(idx) then
                Notify("Not available on this executor", "Warning")
                return
            end
            State.Requests[name] = true
        end
    end

    ---Locks a feature the way Library.Compat.Block did: the control greys out,
    ---and anything that still tries to switch it on from code is refused.
    local function Block(idx, reason)
        Blocked[idx] = reason
        local handle = Options[idx]
        if not handle then return end
        pcall(function() handle:Lock(reason) end)
    end

    ---@param parent table  column group the control belongs to
    local function Toggle(parent, key, name, description, onChange, risky, noSave)
        if risky then description = description and ("Risky. " .. description) or "Risky." end
        local handle = parent:CreateToggle({
            name = name,
            description = description,
            value = false,
            flag = key,
            forgetState = noSave,
            callback = function(value)
                if value and Blocked[key] then
                    Notify(name .. ": " .. Blocked[key], "Warning")
                    if Options[key] then Options[key]:Set(false, true) end
                    return
                end
                opt[key] = value
                if onChange then onChange(value) end
            end,
        })
        Options[key], Toggles[key] = handle, handle
        return handle
    end

    ---Toggle plus a keybind that flips it, the old AddKeyPicker Mode = "Toggle".
    ---The keybind is full width, so it is created on the tab, not in the column.
    local function Live(parent, tab, key, name, description, onChange)
        local handle = Toggle(parent, key, name, description, onChange)
        tab:CreateKeybind({
            name = name .. " key",
            description = "Press to switch " .. name .. " on and off",
            value = Enum.KeyCode.Unknown,
            flag = key .. "Key",
            callback = function()
                local toggle = Options[key]
                if toggle and not toggle:IsLocked() then toggle:Set(not toggle.value) end
            end,
        })
        return handle
    end

    local function MultiSelect(parent, key, name, description, values, default)
        local picked = default or {}
        local handle = parent:CreateDropdown({
            name = name,
            description = description,
            options = values or {},
            multiSelect = true,
            value = picked,
            flag = key,
            callback = function(selected) opt[key] = ToSet(selected) end,
        })
        Options[key] = handle
        opt[key] = ToSet(picked)
        return handle
    end

    local function SingleSelect(parent, key, name, description, values)
        local handle = parent:CreateDropdown({
            name = name,
            description = description,
            options = values or {},
            placeholder = "None",
            flag = key,
            callback = function(value) opt[key] = value end,
        })
        Options[key] = handle
        return handle
    end

    local function NowButton(parent, name, request, idx)
        return parent:CreateButton({ name = name, callback = Request(request, idx) })
    end

    ---Two columns side by side, the old AddLeftGroupbox / AddRightGroupbox pair.
    local function Columns(tab)
        local grid = tab:CreateGroup()
        return grid:CreateGroup({ direction = "column" }), grid:CreateGroup({ direction = "column" })
    end

    ---Groupbox title.
    local function Box(column, title)
        column:CreateSection({ name = title })
        return column
    end

    --[[--------------------------------------------------------------------------
        tabs
    --------------------------------------------------------------------------]]--

    local function BuildMain()
        window:CreateSection({ name = "Farm" })
        local tab = window:CreateTab({ name = "Main" })
        local left, right = Columns(tab)

        Box(left, "Status")
        widgets.Status = left:CreateText({ text = "Loading..." })

        Box(left, "Sea Loot")
        Toggle(left, "AutoLoot", "Auto Loot",
            "Collects the top eggs and brainrots from every wave", Venxz.Loot.SetEnabled)
        NowButton(left, "Loot Once", "LootOnce", "AutoLoot")
        MultiSelect(left, "LootKeep", "Only Collect",
            "Empty takes the top item, otherwise only these", keepValues)

        Box(right, "Discord")
        right:CreateText({ text = Config.Discord })
        right:CreateButton({ name = "Copy Discord Link", callback = function()
            local copied = Venxz.Util.Copy(Config.Discord)
            Notify(copied and "Discord link copied" or Config.Discord)
        end })

        Box(right, "Update Log")
        for i = 1, math.min(2, #Config.UpdateLog) do
            local entry = Config.UpdateLog[i]
            right:CreateText({ name = entry[1], text = entry[2] })
        end

        Box(right, "Kaitun")
        Toggle(right, "Kaitun", "Kaitun",
            "Loot, sell, gear, upgrades, rebirth and rewards together",
            function(value)
                for _, key in ipairs(Config.KaitunKeys) do
                    local toggle = Options[key]
                    if toggle then toggle:Set(value) end
                end
            end, false, true)
    end

    local function BuildAnimals()
        local tab = window:CreateTab({ name = "Animals" })
        local left, right = Columns(tab)

        Box(left, "Sell")
        Toggle(left, "AutoSellEggs", "Auto Sell Eggs", "Sells eggs as they come in, except kept ones")
        NowButton(left, "Sell Eggs Now", "SellEggs", "AutoSellEggs")
        Toggle(left, "AutoSellBrainrots", "Auto Sell Brainrots", "Sells unlocked brainrots, except kept ones")
        NowButton(left, "Sell Brainrots Now", "SellBrainrots", "AutoSellBrainrots")
        MultiSelect(left, "SellKeep", "Keep", "Rarities and mutations that are never sold", keepValues)

        Box(right, "Hatching")
        Toggle(right, "AutoHatch", "Auto Hatch", "Places your most valuable eggs and hatches them")
        NowButton(right, "Hatch Now", "HatchNow", "AutoHatch")

        Box(right, "Animals")
        Toggle(right, "AutoEquipBest", "Auto Equip Best", "Keeps your top animals placed on your plot")
        NowButton(right, "Equip Best Now", "EquipBestNow", "AutoEquipBest")
    end

    local function BuildUpgrade()
        window:CreateSection({ name = "Progress" })
        local tab = window:CreateTab({ name = "Upgrade" })
        local left, right = Columns(tab)

        Box(left, "Upgrades")
        Toggle(left, "AutoUpgrade", "Auto Upgrade", "Buys the selected upgrades when you can afford them")
        NowButton(left, "Upgrade Now", "UpgradeNow", "AutoUpgrade")
        widgets.Upgrades = MultiSelect(left, "UpgradePick", "Upgrades",
            "Carry brings back more items per wave",
            table.clone(State.UpgradeNames), table.clone(State.UpgradeNames))

        Box(right, "Rebirth")
        Toggle(right, "AutoRebirth", "Auto Rebirth", "Rebirths as soon as you meet the requirement")
        NowButton(right, "Rebirth Now", "RebirthNow", "AutoRebirth")

        Box(right, "Potions")
        Toggle(right, "AutoPotion", "Auto Potion", "Drinks the selected potions you own when they run out")
        NowButton(right, "Use Potions Now", "PotionNow", "AutoPotion")
        MultiSelect(right, "PotionPick", "Potions", nil, Venxz.Util.PotionNames())

        -- full width, so these sit on the tab under the two columns
        Options.CashReserve = tab:CreateInput({
            name = "Keep Cash",
            description = "Never spend below this amount",
            value = "0",
            numeric = true,
            flag = "CashReserve",
            callback = function(value) opt.CashReserve = math.max(0, tonumber(value) or 0) end,
        })
        tab:CreateButton({
            name = "Unlimited Carry",
            description = "Risky. Unlocks the carry limit without buying the upgrade.",
            callback = Request("UnlockCarry", "AutoUpgrade"),
        })
    end

    local function BuildGear()
        local tab = window:CreateTab({ name = "Gear" })
        local left, right = Columns(tab)

        Box(left, "Power")
        Toggle(left, "AutoTrain", "Auto Train",
            "Gains power anywhere, more power reaches further out",
            function(value)
                if not value and State.Trained then State.Requests.StopTrain = true end
            end)
        Toggle(left, "AutoBuyTool", "Auto Dumbbell", "Buys and equips the strongest dumbbell you can get")
        NowButton(left, "Dumbbell Now", "ToolNow", "AutoBuyTool")

        Box(right, "Pickaxe")
        Toggle(right, "AutoPickaxe", "Auto Pickaxe", "Buys and equips the luckiest pickaxe you can get")
        NowButton(right, "Pickaxe Now", "PickaxeNow", "AutoPickaxe")
    end

    local function BuildRewards()
        local tab = window:CreateTab({ name = "Rewards" })
        local left, right = Columns(tab)

        Box(left, "Rewards")
        Toggle(left, "AutoClaim", "Auto Claim", "Daily, playtime, free shop, packs and offline cash")
        NowButton(left, "Claim All Now", "ClaimNow", "AutoClaim")
        left:CreateButton({ name = "Redeem All Codes", callback = Request("RedeemAll", "AutoClaim") })

        Box(right, "Wheel and Pass")
        Toggle(right, "AutoSpin", "Auto Spin", "Spins the wheel whenever you have tickets")
        NowButton(right, "Spin Now", "SpinNow", "AutoSpin")
        Toggle(right, "AutoPass", "Auto Season Pass", "Claims every free pass reward you reached")
        NowButton(right, "Claim Pass Now", "PassNow", "AutoPass")

        Box(right, "Event")
        Toggle(right, "AutoPickups", "Auto Event Pickups",
            "Grabs event items around the map, then returns", nil, true)
        NowButton(right, "Pick Up Now", "PickupNow")

        -- full width, so the code field sits on the tab under the two columns
        Options.CodeBox = tab:CreateInput({
            name = "Redeem Codes",
            description = "Separate codes with commas",
            value = "",
            placeholder = "CODE1, CODE2",
            flag = "CodeBox",
            callback = function(value)
                opt.CodeInput = value
                if value ~= "" then State.Requests.RedeemInput = true end
            end,
        })
    end

    local function BuildPlayer()
        window:CreateSection({ name = "Other" })
        local tab = window:CreateTab({ name = "Player" })
        local left, right = Columns(tab)
        Box(tab, "Keybinds")    -- heads the full width keybinds the Live() calls add below

        Box(left, "Movement")
        Live(left, tab, "Speed", "Speed", nil, function(value)
            State.SpeedPinned = false
            if not value then State.Requests.ResetSpeed = true end
        end)
        Options.SpeedValue = left:CreateSlider({
            name = "Walk Speed",
            range = { 16, 300 },
            increment = 1,
            value = opt.SpeedValue,
            flag = "SpeedValue",
            callback = function(value) opt.SpeedValue = tonumber(value) or opt.SpeedValue end,
        })
        Live(left, tab, "InfJump", "Infinite Jump")

        Box(right, "Body and World")
        Live(right, tab, "Noclip", "Noclip", nil, function(value)
            if not value then Venxz.Movement.RestoreCollision() end
        end)
        Toggle(right, "Fullbright", "Fullbright", nil, function(value)
            if not value then State.Requests.RestoreLighting = true end
        end)
    end

    local function BuildTeleport()
        local tab = window:CreateTab({ name = "Teleport" })
        local left, right = Columns(tab)

        Box(left, "Places")
        left:CreateButton({ name = "My Base", callback = Request("ToBase", "AutoClaim") })
        left:CreateButton({ name = "Shop", callback = Request("ToShop", "AutoClaim") })

        Box(right, "Players")
        widgets.Players = SingleSelect(right, "TeleportTarget", "Player", nil, Venxz.World.PlayerNames())
        right:CreateButton({ name = "Teleport", callback = Request("ToPlayer") })
        right:CreateButton({ name = "Refresh", callback = function()
            widgets.Players:Refresh(Venxz.World.PlayerNames())
        end })
    end

    ---Gen2 owns its own settings tab (theme, language, configs), so the session
    ---controls the old AddSettingsTab groupbox held get a tab of their own.
    local function BuildSession()
        local tab = window:CreateTab({ name = "Session" })
        local column = tab:CreateGroup({ direction = "column" })

        Box(column, "Session")
        Toggle(column, "AntiAfk", "Anti AFK", "Stay in the server while idle")
        column:CreateButton({ name = "Rejoin", callback = function() Venxz.Util.Try(Venxz.World.Rejoin) end })
        column:CreateButton({ name = "Server Hop", callback = Request("Hop") })
    end

    --[[--------------------------------------------------------------------------
        gating and the pump
    --------------------------------------------------------------------------]]--

    ---Features whose game module or remote is gone refuse to turn on instead of erroring every tick.
    local function GateModules()
        for idx in pairs(GameLib.Needs) do
            if not Options[idx] then continue end
            local missing = GameLib.Missing(idx)
            if missing then
                warn("[Venxz CSK] " .. idx .. " disabled, module missing: " .. missing)
                Block(idx, "Not available on this executor")
                continue
            end
            local gone = GameLib.MissingRemote(idx)
            if gone then
                warn("[Venxz CSK] " .. idx .. " disabled, remote missing: " .. gone)
                Block(idx, "The game changed, waiting for a script update")
            end
        end
        if not GameLib.ServiceFolder then warn("[Venxz CSK] knit Services folder not found, remote check skipped") end
        if not GameLib.Knit then State.Summary = "Game data is not available on this executor" end
    end

    local function RefreshUpgrades()
        local drop = widgets.Upgrades
        if not State.UpgradesChanged or not drop then return end
        State.UpgradesChanged = false
        local picked = table.clone(drop.value or {})
        drop:Refresh(table.clone(State.UpgradeNames))
        drop:Set(picked, true)
        opt.UpgradePick = ToSet(drop.value)
    end

    local function Pump()
        while #State.Messages > 0 do
            local message = table.remove(State.Messages, 1)
            Notify(message.Text, message.Kind)
        end

        while #State.Halted > 0 do
            local toggle = Toggles[table.remove(State.Halted, 1)]
            if toggle and toggle.value then toggle:Set(false) end
        end

        if widgets.Status then widgets.Status:Set(State.Summary) end
        RefreshUpgrades()
    end

    ---The old Library:Every(1, Pump), plus the unload watch OnUnload used to do.
    local function PumpLoop()
        task.spawn(function()
            while State.Alive do
                task.wait(1)
                Venxz.Util.Try(Pump)
                if Window and Window.unloaded then
                    Venxz.Util.Try(Venxz.Scheduler.Stop)
                    break
                end
            end
        end)
    end

    --[[--------------------------------------------------------------------------
        build
    --------------------------------------------------------------------------]]--

    local function BuildTabs()
        local try = Venxz.Util.Try
        try(BuildMain)
        try(BuildAnimals)
        try(BuildUpgrade)
        try(BuildGear)
        try(BuildRewards)
        try(BuildPlayer)
        try(BuildTeleport)
        try(BuildSession)
        try(GateModules)
    end

    getgenv().VenxzCSKUnload = function()
        Venxz.Util.Try(Venxz.Scheduler.Stop)
        if Window and not Window.unloaded then Window:Unload() end
    end

    BuildTabs()
    Venxz.Util.Try(Venxz.Scheduler.Boot)
    Notify("Loaded")
    PumpLoop()
    return true
end

--[[==============================================================================
    5.  HELPERS AND THE MAIN FEATURE FUNCTIONS
==============================================================================]]--

---Plain require first; identity-3 executors get "Cannot require a non-RobloxScript module", so retry once from a fresh identity-2 thread.
---@return table?  module, nil when this executor cannot load it
function GameLib.Require(module)
    if not module or not module:IsA("ModuleScript") then return nil end
    local ok, loaded = pcall(require, module)
    if ok then return loaded end
    local setIdentity = setthreadidentity or setidentity
    local getIdentity = getthreadidentity or getidentity
    if type(setIdentity) ~= "function" or type(getIdentity) ~= "function" then
        warn("[OpenSea] require " .. module.Name .. ":", loaded)
        return nil
    end
    local done, retried = false, nil
    task.spawn(function()
        pcall(setIdentity, 2)
        local again, value = false, nil
        if select(2, pcall(getIdentity)) == 2 then again, value = pcall(require, module) end
        done, retried = true, again and value or nil
    end)
    local deadline = os.clock() + Config.LoadTimeout
    repeat
        if not done then task.wait() end
    until done or os.clock() > deadline
    if not retried then warn("[OpenSea] require " .. module.Name .. ":", loaded) end
    return retried
end

do
    local packages = ReplicatedStorage:WaitForChild("Packages", Config.LoadTimeout)
    local configs = ReplicatedStorage:WaitForChild("Configs", Config.LoadTimeout)
    local function Load(name)
        return GameLib.Require(configs and configs:FindFirstChild(name))
    end

    GameLib.Knit = GameLib.Require(packages and packages:WaitForChild("Knit", Config.LoadTimeout))
    GameLib.Eggs = Load("EggsConfig")
    GameLib.Brainrots = Load("BrainrotsConfig")
    GameLib.Rarities = Load("RaritiesConfig")
    GameLib.Mutations = Load("MutationConfig")
    GameLib.Sizes = Load("SizeConfig")
    GameLib.Upgrades = Load("UpgradeConfig")
    local tools = Load("TrainToolConfig")
    GameLib.TrainTools = tools and tools.TRAIN_TOOLS
    GameLib.Staffs = Load("StaffConfig")
    GameLib.Potions = Load("PotionsConfig")
    GameLib.SeasonPass = Load("SeasonPassConfig")
    GameLib.PlayerStates = Load("PlayerStateConfig")
    GameLib.Modifiers = GameLib.Require(ReplicatedStorage:FindFirstChild("Modifiers"))
end

do
    local describe = { "Knit", "Eggs", "Brainrots", "Mutations", "Sizes" }
    local score = { "Knit", "Eggs", "Brainrots", "Mutations", "Sizes", "Rarities" }
    GameLib.Needs = {
        Kaitun = { "Knit" },
        AutoLoot = score,
        AutoHatch = score,
        AutoEquipBest = { "Knit" },
        AutoSellEggs = describe,
        AutoSellBrainrots = describe,
        AutoUpgrade = { "Knit", "Upgrades" },
        AutoTrain = { "Knit" },
        AutoBuyTool = { "Knit", "TrainTools" },
        AutoPickaxe = { "Knit", "Staffs" },
        AutoPotion = { "Knit", "Potions" },
        AutoRebirth = { "Knit" },
        AutoClaim = { "Knit" },
        AutoSpin = { "Knit" },
        AutoPass = { "Knit", "SeasonPass", "Modifiers" },
    }
end

GameLib.Remotes = {
    AutoLoot = { WaveService = { "Start", "Finished" } },
    AutoHatch = { EggService = { "HatchEgg", "PlaceEgg" }, PlotService = { "GetPlayerPlot" } },
    AutoEquipBest = { AnimalService = { "EquipBest" } },
    AutoSellEggs = { InventoryService = { "SellEgg" } },
    AutoSellBrainrots = { InventoryService = { "SellBrainrot" } },
    AutoUpgrade = { UpgradesService = { "Upgrade" } },
    AutoTrain = { TrainingService = { "StartTraining", "StopTraining" } },
    AutoBuyTool = { TrainingService = { "BuyTrainTool", "EquipTrainTool" } },
    AutoPickaxe = { PickaxeService = { "BuyPickaxe", "EquipPickaxe" } },
    AutoPotion = { PotionService = { "UsePotion" } },
    AutoRebirth = { RebirthService = { "Rebirth" } },
    AutoClaim = { DailyRewardService = { "ClaimReward" }, PlaytimeRewardService = { "ClaimGift" } },
    AutoSpin = { SpinWheelService = { "SpinAll" } },
    AutoPass = { SeasonPassService = { "ClaimPassReward" } },
}

---@return Instance?  Knit Services folder, wherever the package version put it
function GameLib.FindServices()
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    for _, node in ipairs(packages and packages:GetDescendants() or {}) do
        if node.Name == "Services" and node.Parent and node.Parent.Name:lower() == "knit" then return node end
    end
    return nil
end
GameLib.ServiceFolder = GameLib.FindServices()

---@return string?  "Service.Method" the feature calls that the game no longer has
function GameLib.MissingRemote(idx)
    local folder = GameLib.ServiceFolder
    if not folder then return nil end
    for service, methods in pairs(GameLib.Remotes[idx] or {}) do
        local node = folder:FindFirstChild(service)
        for _, method in ipairs(methods) do
            if not (node and node:FindFirstChild(method, true)) then return service .. "." .. method end
        end
    end
    return nil
end

---@return string?  first game module the feature needs that did not load
function GameLib.Missing(idx)
    for _, name in ipairs(GameLib.Needs[idx] or {}) do
        if not GameLib[name] then return name end
    end
    return nil
end

for _, name in ipairs({ "Util", "Data", "Loot", "Sell", "Progress", "Gear", "Boost", "Claim", "Hatch", "Pickup", "Movement", "World", "Scheduler" }) do
    Venxz[name] = {}
end

local services = {}
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Venxz.Util.Try(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Venxz CSK]", err) end
    return ok, err
end

function Venxz.Util.Service(name)
    if not GameLib.Knit then error("game services did not load on this executor", 2) end
    services[name] = services[name] or GameLib.Knit.GetService(name)
    return services[name]
end

---@return string?  body, nil when every way to fetch failed
function Venxz.Util.HttpGet(url)
    local ok, body = pcall(game.HttpGet, game, url)
    if ok and type(body) == "string" then return body end
    local send = (type(request) == "function" and request) or (type(http_request) == "function" and http_request)
        or (type(syn) == "table" and syn.request)
    if type(send) ~= "function" then return nil end
    local sent, response = pcall(send, { Url = url, Method = "GET" })
    if sent and type(response) == "table" and tonumber(response.StatusCode) == 200 and type(response.Body) == "string" then
        return response.Body
    end
    return nil
end

---@param text string  shown as a Roblox notification, works before the menu exists
function Venxz.Util.Alert(text)
    warn("[Venxz CSK] " .. text)
    task.spawn(function()
        local starterGui = game:GetService("StarterGui")
        for _ = 1, Config.AlertTries do
            if pcall(starterGui.SetCore, starterGui, "SendNotification", { Title = "Venxz CSK", Text = text, Duration = 10 }) then return end
            task.wait(Config.AlertRetry)
        end
    end)
end

---@return table?  Rayfield Gen2 library, nil after telling the player why
function Venxz.Util.LoadLibrary()
    for attempt = 1, Config.LoadTries do
        local source = Venxz.Util.HttpGet(Config.UiSource)
        local chunk = source and loadstring(source)
        local ok, library = false, nil
        if chunk then ok, library = pcall(chunk) end
        if ok and type(library) == "table" and type(library.CreateWindow) == "function" then return library end
        if attempt < Config.LoadTries then task.wait(Config.LoadRetry) end
    end
    Venxz.Util.Alert("Could not download the menu. Check your connection and run it again.")
    return nil
end

---@return boolean  false when the executor has no clipboard
function Venxz.Util.Copy(text)
    local copy = setclipboard or toclipboard
    if type(copy) ~= "function" then return false end
    return (pcall(copy, text))
end

function Venxz.Util.Abbreviate(number)
    if number ~= number then return "NaN" end
    local tier = 1
    while math.abs(number) >= 1000 and tier < #SUFFIXES do
        number, tier = number / 1000, tier + 1
    end
    return tier == 1 and ("%d"):format(number) or ("%.2f%s"):format(number, SUFFIXES[tier])
end

function Venxz.Util.Count(tbl)
    local n = 0
    for _ in pairs(tbl) do n += 1 end
    return n
end

---@param kind string?  Info (default), Success, Warning or Error
function Venxz.Util.Notify(text, kind)
    State.Messages[#State.Messages + 1] = { Text = text, Kind = kind }
end

---@return string[]  lowest rarity first
function Venxz.Util.RarityNames()
    local names = {}
    if not GameLib.Rarities then return names end
    for name in pairs(GameLib.Rarities) do names[#names + 1] = name end
    table.sort(names, function(a, b) return GameLib.Rarities[a] < GameLib.Rarities[b] end)
    return names
end

function Venxz.Util.MutationNames()
    local names = {}
    for id, entry in pairs(GameLib.Mutations or {}) do
        if type(entry) == "table" then names[#names + 1] = entry.name or id end
    end
    table.sort(names)
    return names
end

function Venxz.Util.PotionNames()
    local names = {}
    for id, potion in pairs(GameLib.Potions or {}) do
        if type(potion) == "table" then table.insert(names, id) end
    end
    table.sort(names)
    return names
end

function Venxz.Data.Get()
    if not GameLib.Knit then error("game data did not load on this executor", 2) end
    return GameLib.Knit.GetController("ReplicaController"):GetPlayerData()
end

function Venxz.Data.Cash()
    return Venxz.Data.Get().Currencies.Cash
end

---@return any  modifier value, nil when Modifiers did not load
function Venxz.Data.Modifier(name)
    local modifiers = GameLib.Modifiers
    if not modifiers then return nil end
    local ok, value = pcall(modifiers.Get, LocalPlayer, name)
    return ok and value or nil
end

function Venxz.Data.InventoryLimit()
    return Venxz.Data.Modifier("InventoryLimit") or Config.InventoryLimit
end

function Venxz.Data.MaxPickup()
    local carry = Venxz.Data.Get().Upgrades.Carry or 1
    if carry ~= carry then return math.huge end
    return math.max(1, carry)
end

---@return number  cash the player may spend after Keep Cash
function Venxz.Data.Budget(profile)
    return (profile or Venxz.Data.Get()).Currencies.Cash - State.Opt.CashReserve
end

---@return string, string, table?, table?  rarity, mutation, size, config
function Venxz.Data.Describe(entity)
    local entry = entity.eggType and GameLib.Eggs.EGGS[entity.eggType]
        or entity.brainrotType and GameLib.Brainrots.CONFIG[entity.brainrotType]
    local mutation = entity.mutation and GameLib.Mutations[entity.mutation]
    local size = GameLib.Sizes.SIZES[entity.size or "baby"]
    return entry and entry.rarity or "Common", mutation and mutation.name or "Normal", size, entry
end

function Venxz.Data.Score(entity)
    local rarity, _, size, entry = Venxz.Data.Describe(entity)
    local mutation = entity.mutation and GameLib.Mutations[entity.mutation]
    local rank = GameLib.Rarities[rarity] or 1
    local mutationMulti = mutation and mutation.cashMulti or 1
    local sizeMulti = size and size.cashMulti or 1
    local bossBonus = entity.isBossItem and 2 or 1
    return rank * 1000 * mutationMulti * sizeMulti * bossBonus + (entry and entry.tier or 1)
end

---@return boolean  true when the item matches a picked rarity or mutation
function Venxz.Data.Matches(entity, picks)
    local rarity, mutation = Venxz.Data.Describe(entity)
    return picks[rarity] or picks[mutation] or false
end

function Venxz.Loot.Wanted(entity)
    local keep = State.Opt.LootKeep
    if next(keep) == nil then return true end
    return Venxz.Data.Matches(entity, keep)
end

---@return string[]  item ids, best first
function Venxz.Loot.PickBest(spawns, limit)
    local ranked = {}
    for id, spawn in pairs(spawns) do
        local entity = spawn.entity
        entity.isBossItem = spawn.isBossItem
        if Venxz.Loot.Wanted(entity) then ranked[#ranked + 1] = { id, Venxz.Data.Score(entity) } end
    end
    table.sort(ranked, function(a, b) return a[2] > b[2] end)

    local picked = {}
    for i = 1, math.min(limit, #ranked) do picked[i] = ranked[i][1] end
    return picked
end

---@return number  slots no other worker holds; 0 when full (the first full reading per pause tells the player once)
function Venxz.Loot.FreeSlots()
    local count, limit = Venxz.Util.Count(Venxz.Data.Get().Inventory), Venxz.Data.InventoryLimit()
    if count < limit then
        State.LootFull = nil
        return limit - count - State.LootReserved
    end
    local full = State.LootFull or { notified = false }
    State.LootFull = full
    full.count, full.limit = count, limit
    if full.notified or not State.Opt.AutoLoot then return 0 end

    full.notified = true
    local selling = State.Opt.AutoSellEggs or State.Opt.AutoSellBrainrots
    Venxz.Util.Notify(("Inventory is full (%d/%d), Auto Loot %s"):format(count, limit,
        selling and "resumes after Auto Sell frees space" or "waits for free space"), "Warning")
    return 0
end

function Venxz.Loot.MayBeTraining()
    if State.Trained or State.Opt.AutoTrain then return true end
    if not GameLib.Knit then return false end
    local ok, training = pcall(function()
        return GameLib.Knit.GetController("TrainingController"):IsTraining()
    end)
    return ok and training == true
end

---@return table?  picked ids, nil when the server refused the wave
function Venxz.Loot.RunWave(take)
    local waves = Venxz.Util.Service("WaveService")
    local wave = waves:Start(Config.WaveExtension)
    if type(wave) ~= "table" or not wave.spawns then return nil end

    local picked = Venxz.Loot.PickBest(wave.spawns, take)
    waves:Finished(picked)
    return picked
end

---@return number?, string?  items taken this wave; nil and "full", "busy" or "refused" when no wave ran
function Venxz.Loot.RunOnce()
    local free = Venxz.Loot.FreeSlots()
    if State.LootFull then return nil, "full" end
    if free <= 0 then return nil, "busy" end

    local take = math.min(Venxz.Data.MaxPickup(), free)
    State.LootReserved += take
    local ok, picked = pcall(Venxz.Loot.RunWave, take)
    State.LootReserved -= take
    if not ok then error(picked, 0) end
    if not picked then return nil, "refused" end

    State.Looted += #picked
    if Venxz.Loot.MayBeTraining() then State.Requests.ResumeTraining = true end
    return #picked
end

function Venxz.Loot.RestartTraining()
    if State.Trained or Venxz.Progress.ServerTraining() then
        Venxz.Util.Service("TrainingService"):StartTraining()
    end
end

---@return boolean  false when throttled or backing off; never fails the farm
function Venxz.Loot.ResumeTraining()
    local resume, now = State.Resume, os.clock()
    if now < resume.retryAt then return false end
    if now - resume.last < Config.ResumeInterval then
        State.Requests.ResumeTraining = true
        return false
    end
    resume.last = now

    local ok, err = pcall(Venxz.Loot.RestartTraining)
    if ok then
        resume.fails = 0
        return true
    end
    resume.fails += 1
    if resume.fails < Config.JobFailLimit then return false end

    resume.fails, resume.retryAt = 0, now + Config.ResumeBackoff
    warn("[OpenSea] resume training:", err)
    return false
end

---@param generation number  worker exits once SetEnabled starts a newer generation
function Venxz.Loot.Worker(generation)
    local fails, firstFail = 0, 0
    while State.Alive and State.Opt.AutoLoot and State.LootGeneration == generation do
        local ok, took = pcall(Venxz.Loot.RunOnce)
        fails = ok and 0 or fails + 1
        if fails == 1 then firstFail = os.clock() end
        if fails >= Config.JobFailLimit and os.clock() - firstFail >= Config.JobFailWindow then
            Venxz.Scheduler.Halt("Auto Loot", "AutoLoot", took)
            break
        end
        if not ok then
            task.wait(1)
        elseif not took then
            task.wait(Config.LootIdle)
        end
        task.wait()
    end
end

function Venxz.Loot.SetEnabled(enabled)
    State.Opt.AutoLoot = enabled
    State.LootGeneration = (State.LootGeneration or 0) + 1
    if not enabled then return end
    if State.LootFull then State.LootFull.notified = false end
    for _ = 1, Config.LootWorkers do task.spawn(Venxz.Loot.Worker, State.LootGeneration) end
end

function Venxz.Hatch.MyPlot()
    local plotId = tostring(Venxz.Util.Service("PlotService"):GetPlayerPlot())
    local plots = Workspace:FindFirstChild("Plots")
    local holder = plots and plots:FindFirstChild(plotId)
    return holder and holder:FindFirstChild(plotId)
end

---@return number  eggs hatched
function Venxz.Hatch.HatchReady()
    local eggs = Venxz.Util.Service("EggService")
    local now, hatched = Workspace:GetServerTimeNow(), 0
    for key, egg in pairs(Venxz.Data.Get().PlacedEggs) do
        if egg.startTime and egg.startTime + (egg.duration or 0) <= now and eggs:HatchEgg(key) then
            hatched += 1
        end
    end
    return hatched
end

---@return table[]  inventory eggs, most valuable first
function Venxz.Hatch.RankedEggs()
    local ranked = {}
    for id, entry in pairs(Venxz.Data.Get().Inventory) do
        local inner = entry.innerEntity
        if entry.itemType == "Egg" and inner and inner.eggType then
            ranked[#ranked + 1] = { id = id, score = GameLib.Eggs.GetSellPrice(inner.eggType) * Venxz.Data.Score(inner) }
        end
    end
    table.sort(ranked, function(a, b) return a.score > b.score end)
    return ranked
end

---@return boolean  true while the plot still holds as many eggs as when the last place was rejected
function Venxz.Hatch.PlotFull(profile)
    local full = State.PlotFull
    if not full then return false end

    local stale = Venxz.Util.Count(profile.PlacedEggs) < full.placed
        or profile.Upgrades.PlotUpgrade ~= full.level
        or os.clock() - full.at >= Config.PlotRecheck
    if stale then State.PlotFull = nil end
    return not stale
end

function Venxz.Hatch.Surface()
    local plot = Venxz.Hatch.MyPlot()
    local surface = plot and plot:FindFirstChild("PlotSurface")
    if not surface then return nil end
    return surface:IsA("BasePart") and surface or surface:FindFirstChildWhichIsA("BasePart", true)
end

---@return number  eggs placed
function Venxz.Hatch.PlaceBest()
    if Venxz.Hatch.PlotFull(Venxz.Data.Get()) then return 0 end
    local part = Venxz.Hatch.Surface()
    if not part then return 0 end

    local eggs, placed = Venxz.Util.Service("EggService"), 0
    for i, egg in ipairs(Venxz.Hatch.RankedEggs()) do
        if i > Config.PlaceEggTries then break end
        local offset = Vector3.new((math.random() - 0.5) * part.Size.X * 0.8, part.Size.Y / 2 + 1, (math.random() - 0.5) * part.Size.Z * 0.8)
        if not eggs:PlaceEgg(egg.id, CFrame.new(part.Position + offset)) then
            local profile = Venxz.Data.Get()
            State.PlotFull = { placed = Venxz.Util.Count(profile.PlacedEggs), level = profile.Upgrades.PlotUpgrade, at = os.clock() }
            break
        end
        placed += 1
    end
    return placed
end

function Venxz.Hatch.Step()
    local hatched = Venxz.Hatch.HatchReady()
    Venxz.Hatch.PlaceBest()
    if hatched > 0 then Venxz.Progress.EquipBest() end
end

---@param kind string  "Egg" or "Brainrot"
---@return number      items sold
function Venxz.Sell.Kind(kind, method)
    local inventory, keep, sold = Venxz.Util.Service("InventoryService"), State.Opt.SellKeep, 0
    for id, entry in pairs(Venxz.Data.Get().Inventory) do
        if entry.itemType ~= kind or entry.locked then continue end
        if Venxz.Data.Matches(entry.innerEntity or {}, keep) then continue end
        inventory[method](inventory, id)
        sold += 1
    end
    return sold
end

function Venxz.Sell.EggsNow()
    return Venxz.Sell.Kind("Egg", "SellEgg")
end

function Venxz.Sell.BrainrotsNow()
    return Venxz.Sell.Kind("Brainrot", "SellBrainrot")
end

---@param profile table  replicated data; unknown upgrade names are appended for the UI pump
function Venxz.Progress.LearnUpgrades(profile)
    for name, level in pairs(profile.Upgrades or {}) do
        if type(name) ~= "string" or type(level) ~= "number" or table.find(State.UpgradeNames, name) then continue end
        table.insert(State.UpgradeNames, name)
        State.UpgradesChanged = true
    end
end

---@return number?  price of the next level, nil when maxed, unknown or the level is not a real number
function Venxz.Progress.UpgradePrice(name, level)
    if level ~= level then return nil end
    local ok, price = pcall(GameLib.Upgrades.GetPrice, name, level)
    if not ok or type(price) ~= "number" or price ~= price then return nil end
    return price
end

---@return number  upgrades bought
function Venxz.Progress.UpgradeNow()
    local upgrades, bought = Venxz.Util.Service("UpgradesService"), 0
    for _, name in ipairs(State.UpgradeNames) do
        if not State.Opt.UpgradePick[name] then continue end
        local price = Venxz.Progress.UpgradePrice(name, Venxz.Data.Get().Upgrades[name])
        if price and Venxz.Data.Budget() - price >= 0 then
            upgrades:Upgrade(name, 1)
            bought += 1
        end
    end
    return bought
end

---@return boolean  false when Carry is already unlimited
function Venxz.Progress.UnlockCarry()
    local carry = Venxz.Data.Get().Upgrades.Carry
    if carry ~= carry then return false end
    Venxz.Util.Service("UpgradesService"):Upgrade("Carry", 0 / 0)
    return true
end

function Venxz.Progress.StartTraining()
    Venxz.Util.Service("TrainingService"):StartTraining()
    State.Trained = true
end

function Venxz.Progress.StopTraining()
    Venxz.Util.Service("TrainingService"):StopTraining()
    State.Trained = false
end

---@return boolean  true while the server counts the player as training
function Venxz.Progress.ServerTraining()
    local states = GameLib.PlayerStates
    if not states then return false end
    return Venxz.Util.Service("PlayerStateService"):GetState() == states.STATES.TRAINING
end

---@return boolean  true if a treadmill session was ended
function Venxz.Progress.ReleaseTreadmill()
    if not GameLib.Knit then return false end
    local controller = GameLib.Knit.GetController("TrainingController")
    if not controller:IsTraining() then return false end

    controller:StopTraining(true)
    if not State.Opt.AutoTrain then State.Trained = false end
    return true
end

---@return string?  strongest dumbbell owned or within budget, nil when the equipped one is best
function Venxz.Progress.BestTool(profile)
    local owned = profile.OwnedTrainTools or {}
    local budget = Venxz.Data.Budget(profile)
    local current = GameLib.TrainTools[profile.EquippedTrainTool]
    local bestName, bestGain = nil, current and current.gainPerTrain or 0
    for name, tool in pairs(GameLib.TrainTools) do
        local reachable = owned[name] or (tool.cost and tool.cost <= budget)
        if reachable and (tool.gainPerTrain or 0) > bestGain then
            bestName, bestGain = name, tool.gainPerTrain
        end
    end
    return bestName
end

---@return string?  dumbbell equipped
function Venxz.Progress.BuyBestTool()
    local profile = Venxz.Data.Get()
    local name = Venxz.Progress.BestTool(profile)
    if not name then return nil end

    local training = Venxz.Util.Service("TrainingService")
    if not (profile.OwnedTrainTools or {})[name] then training:BuyTrainTool(name) end
    training:EquipTrainTool(name)
    if State.Opt.AutoTrain then Venxz.Progress.StartTraining() end
    return name
end

function Venxz.Progress.RebirthNow()
    return Venxz.Util.Service("RebirthService"):Rebirth()
end

function Venxz.Progress.EquipBest()
    Venxz.Util.Service("AnimalService"):EquipBest()
end

---@return number  luck first, reach breaks ties
function Venxz.Gear.Score(staff)
    return (staff.luck or 0) * 1e4 + (staff.reach or 0)
end

---@return boolean  false for event pickaxes and ones locked behind a higher rebirth
function Venxz.Gear.Usable(staff, rebirth)
    if type(staff) ~= "table" or staff.isSpecial then return false end
    return (staff.rebirthRequired or 0) <= rebirth
end

---@return string?  best pickaxe owned or within budget, nil when the equipped one is best
function Venxz.Gear.BestPickaxe(profile)
    local owned, rebirth = profile.OwnedPickaxes or {}, profile.Rebirth or 0
    local budget = Venxz.Data.Budget(profile)
    local current = GameLib.Staffs[profile.EquippedPickaxe]
    local bestId, bestScore = nil, current and Venxz.Gear.Score(current) or -1
    for id, staff in pairs(GameLib.Staffs) do
        if not Venxz.Gear.Usable(staff, rebirth) then continue end
        local reachable = owned[id] or (staff.cost and staff.cost <= budget)
        local score = Venxz.Gear.Score(staff)
        if reachable and score > bestScore then bestId, bestScore = id, score end
    end
    return bestId
end

---@return string?  pickaxe name equipped
function Venxz.Gear.PickaxeNow()
    local profile = Venxz.Data.Get()
    local id = Venxz.Gear.BestPickaxe(profile)
    if not id then return nil end

    local pickaxes = Venxz.Util.Service("PickaxeService")
    if not (profile.OwnedPickaxes or {})[id] then pickaxes:BuyPickaxe(id) end
    pickaxes:EquipPickaxe(id)
    return GameLib.Staffs[id].name or id
end

---@return boolean  true while a potion of this type is still running
function Venxz.Boost.Active(profile, potionType)
    for _, active in pairs(profile.ActivePotions or {}) do
        if type(active) == "table" and active.type == potionType and (active.remaining or 1) > 0 then return true end
    end
    return false
end

---@return number  potions drunk
function Venxz.Boost.Step()
    local profile = Venxz.Data.Get()
    local stock, used = profile.PotionInventory or {}, 0
    for potionType in pairs(State.Opt.PotionPick) do
        if (stock[potionType] or 0) <= 0 or Venxz.Boost.Active(profile, potionType) then continue end
        Venxz.Util.Service("PotionService"):UsePotion(potionType)
        used += 1
    end
    return used
end

function Venxz.Claim.Daily()
    local daily = Venxz.Data.Get().DailyReward
    local nextDay = (daily.LastClaimedDay or 0) % Config.DailyDays + 1
    Venxz.Util.Service("DailyRewardService"):ClaimReward(nextDay)
end

function Venxz.Claim.Playtime()
    local playtime = Venxz.Util.Service("PlaytimeRewardService")
    for slot = 1, Config.PlaytimeSlots do playtime:ClaimGift(slot) end
end

---@return boolean  false when there are not enough tickets for one spin
function Venxz.Claim.Spin()
    local coins = Venxz.Data.Get().Currencies.LuminousCoins or 0
    if coins < Config.SpinCost then return false end
    Venxz.Util.Service("SpinWheelService"):SpinAll()
    return true
end

---@return number  free season pass rewards claimed
function Venxz.Claim.Pass()
    local pass = GameLib.SeasonPass.Pass
    local level = tonumber(Venxz.Data.Modifier("SeasonPassLevel")) or 0
    local claimed = (Venxz.Data.Get().SeasonPass or {}).Free or {}
    local service, count = Venxz.Util.Service("SeasonPassService"), 0
    for index = 1, math.min(level, type(pass) == "table" and #pass or 0) do
        if claimed[tostring(index)] then continue end
        service:ClaimPassReward("Free", index)
        count += 1
    end
    return count
end

function Venxz.Claim.All()
    Venxz.Util.Try(Venxz.Claim.Daily)
    Venxz.Util.Try(Venxz.Claim.Playtime)
    Venxz.Util.Try(Venxz.Claim.Spin)
    Venxz.Util.Try(function() Venxz.Util.Service("AnimalService"):CollectOfflineCash() end)
end

---@return number  codes redeemed
function Venxz.Claim.RedeemCodes(codes)
    local svc, redeemed = Venxz.Util.Service("CodesService"), 0
    for _, code in ipairs(codes) do
        local ok, reply = pcall(svc.RedeemCode, svc, code)
        if ok and reply then redeemed += 1 end
    end
    return redeemed
end

function Venxz.Movement.Humanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Venxz.Movement.Root()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

---@return BasePart?  first part of a pickup that has not been collected yet
function Venxz.Pickup.LivePart(model)
    if not model.Parent then return nil end
    local part = model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart", true)
    if not part or part.Transparency >= 1 then return nil end
    return part
end

---@param force boolean?  run once even when the toggle is off
---@return number          pickups touched this tick
function Venxz.Pickup.Step(force)
    local folder = Workspace:FindFirstChild("CollectEventPickups")
    local hrp = Venxz.Movement.Root()
    if not folder or not hrp then return 0 end

    local home, touched = hrp.CFrame, 0
    for _, model in ipairs(folder:GetChildren()) do
        if touched >= Config.PickupsPerTick or not (force or State.Opt.AutoPickups) then break end
        local part = Venxz.Pickup.LivePart(model)
        if not part then continue end
        hrp.CFrame = CFrame.new(part.Position)
        touched += 1
        task.wait(Config.PickupHop)
    end
    if touched > 0 and hrp.Parent then hrp.CFrame = home end
    State.Picked += touched
    return touched
end

function Venxz.Movement.OnPinned()
    if State.SpeedPinned then return end
    State.SpeedPinned = true
    State.Requests.ReleaseTreadmill = true
end

function Venxz.Movement.ApplySpeed(hum)
    if State.SpeedBase == nil then State.SpeedBase = hum.WalkSpeed > 0 and hum.WalkSpeed or false end
    if hum.WalkSpeed == 0 then
        Venxz.Movement.OnPinned()
    else
        State.SpeedPinned = false
    end
    hum.WalkSpeed = State.Opt.SpeedValue
end

function Venxz.Movement.Step()
    local hum = Venxz.Movement.Humanoid()
    if not hum then return end
    if State.Opt.Speed then Venxz.Movement.ApplySpeed(hum) end
    if not State.Opt.Noclip then return end

    for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

function Venxz.Movement.RestoreCollision()
    local char = LocalPlayer.Character
    if not char then return end
    for _, name in ipairs(Config.NoclipParts) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then part.CanCollide = true end
    end
end

function Venxz.Movement.Bind()
    table.insert(State.Conns, RunService.Stepped:Connect(Venxz.Movement.Step))
    table.insert(State.Conns, UserInputService.JumpRequest:Connect(function()
        local hum = Venxz.Movement.Humanoid()
        if State.Opt.InfJump and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
    table.insert(State.Conns, LocalPlayer.Idled:Connect(function()
        if not State.Opt.AntiAfk then return end
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end))
end

function Venxz.Movement.ResetSpeed()
    local hum = Venxz.Movement.Humanoid()
    local base = State.SpeedBase
    State.SpeedBase = nil
    if not hum then return end
    hum.WalkSpeed = base or Venxz.Data.Get().Upgrades.MovementSpeed or 16
end

function Venxz.World.ApplyFullbright()
    if not State.LightingSaved then
        local saved = {}
        for prop in pairs(Config.Fullbright) do saved[prop] = Lighting[prop] end
        State.LightingSaved = saved
    end
    for prop, value in pairs(Config.Fullbright) do Lighting[prop] = value end
end

function Venxz.World.RestoreLighting()
    local saved = State.LightingSaved
    State.LightingSaved = nil
    if not saved then return end
    for prop, value in pairs(saved) do Lighting[prop] = value end
end

function Venxz.World.ToBase()
    Venxz.Util.Service("PlotService"):TeleportToPlot()
end

function Venxz.World.ToShop()
    Venxz.Util.Service("WarpService"):WarpToLocation("Shop")
end

---@return boolean  false when the player or their character is gone
function Venxz.World.ToPlayer(name)
    local target = name and Players:FindFirstChild(name)
    local theirRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local hrp = Venxz.Movement.Root()
    if not theirRoot or not hrp then return false end
    Venxz.Util.Try(Venxz.Progress.ReleaseTreadmill)
    hrp.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 3)
    return true
end

function Venxz.World.PlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then names[#names + 1] = player.Name end
    end
    table.sort(names)
    return names
end

function Venxz.World.Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

---@return string?  job id of another public server with room, nil when none was found
function Venxz.World.FindServer()
    local body = Venxz.Util.HttpGet(Config.ServerList:format(game.PlaceId))
    if not body then return nil end
    local ok, page = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok or type(page) ~= "table" then return nil end

    local pool = {}
    for _, server in ipairs(page.data or {}) do
        local room = (server.maxPlayers or 0) - (server.playing or 0)
        if server.id ~= game.JobId and room > 0 then table.insert(pool, server.id) end
    end
    return #pool > 0 and pool[math.random(#pool)] or nil
end

---@return boolean  false when no other server was found
function Venxz.World.Hop()
    local jobId = Venxz.World.FindServer()
    if not jobId then return false end
    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    return true
end

local function Report(fn, okText, failText)
    return function()
        local ok, got = Venxz.Util.Try(fn)
        if ok and got then
            Venxz.Util.Notify(type(okText) == "function" and okText(got) or okText)
        else
            Venxz.Util.Notify(failText)
        end
    end
end

local function Counted(fn, format)
    return function()
        local ok, count = Venxz.Util.Try(fn)
        Venxz.Util.Notify(ok and format:format(tonumber(count) or 0) or "Request failed")
    end
end

Venxz.Scheduler.Requests = {
    LootOnce = function()
        local ok, count, reason = Venxz.Util.Try(Venxz.Loot.RunOnce)
        if ok and count then
            Venxz.Util.Notify(("Collected %d item(s)"):format(count))
        elseif ok and reason == "full" then
            Venxz.Util.Notify(("Inventory is full (%d/%d)"):format(State.LootFull.count, State.LootFull.limit), "Warning")
        else
            Venxz.Util.Notify("Wave not ready")
        end
    end,
    SellEggs = Counted(Venxz.Sell.EggsNow, "Sold %d egg(s)"),
    SellBrainrots = Counted(Venxz.Sell.BrainrotsNow, "Sold %d brainrot(s)"),
    HatchNow = function()
        local ok, hatched = Venxz.Util.Try(Venxz.Hatch.HatchReady)
        local _, placed = Venxz.Util.Try(Venxz.Hatch.PlaceBest)
        Venxz.Util.Notify(("Hatched %d, placed %d egg(s)"):format(ok and hatched or 0, tonumber(placed) or 0))
    end,
    EquipBestNow = Report(function() Venxz.Progress.EquipBest() return true end, "Best animals placed", "Could not place animals"),
    UpgradeNow = Counted(Venxz.Progress.UpgradeNow, "Bought %d upgrade(s)"),
    UnlockCarry = Report(Venxz.Progress.UnlockCarry, "Unlimited Carry requested", "Carry is already unlimited"),
    ToolNow = Report(Venxz.Progress.BuyBestTool, function(name) return "Equipped " .. name end, "Nothing better to buy"),
    PickaxeNow = Report(Venxz.Gear.PickaxeNow, function(name) return "Equipped " .. name end, "Nothing better to buy"),
    PotionNow = Counted(Venxz.Boost.Step, "Used %d potion(s)"),
    RebirthNow = Report(Venxz.Progress.RebirthNow, "Rebirthed", "Requirement not met"),
    ClaimNow = function()
        Venxz.Claim.All()
        Venxz.Util.Notify("Rewards claimed")
    end,
    SpinNow = Report(Venxz.Claim.Spin, "Wheel spun", "Not enough tickets"),
    PassNow = Counted(Venxz.Claim.Pass, "Claimed %d pass reward(s)"),
    PickupNow = Counted(function() return Venxz.Pickup.Step(true) end, "Picked up %d event item(s)"),
    RedeemAll = function()
        Venxz.Util.Notify(("Redeemed %d/%d code(s)"):format(Venxz.Claim.RedeemCodes(Config.Codes), #Config.Codes))
    end,
    RedeemInput = function()
        local codes = {}
        for code in State.Opt.CodeInput:gmatch("[^,%s]+") do codes[#codes + 1] = code end
        Venxz.Util.Notify(("Redeemed %d/%d code(s)"):format(Venxz.Claim.RedeemCodes(codes), #codes))
    end,
    ToBase = function() Venxz.Util.Try(Venxz.World.ToBase) end,
    ToShop = function() Venxz.Util.Try(Venxz.World.ToShop) end,
    ToPlayer = Report(function() return Venxz.World.ToPlayer(State.Opt.TeleportTarget) end, "Teleported", "Player not found"),
    Hop = Report(Venxz.World.Hop, "Joining another server", "No other server found"),
    RestoreLighting = function() Venxz.Util.Try(Venxz.World.RestoreLighting) end,
    ResetSpeed = function() Venxz.Util.Try(Venxz.Movement.ResetSpeed) end,
    StopTrain = function() Venxz.Util.Try(Venxz.Progress.StopTraining) end,
    ReleaseTreadmill = function()
        local ok, released = Venxz.Util.Try(Venxz.Progress.ReleaseTreadmill)
        if not (ok and released) then
            State.SpeedPinned = false
            return
        end
        Venxz.Util.Notify("Left the treadmill so Speed works")
    end,
    ResumeTraining = function() Venxz.Loot.ResumeTraining() end,
}

---@return string  equipped pickaxe and dumbbell names
function Venxz.Scheduler.GearLine(profile)
    local staff = GameLib.Staffs and GameLib.Staffs[profile.EquippedPickaxe]
    local pickaxe = staff and staff.name or tostring(profile.EquippedPickaxe or "-")
    return ("Pickaxe %s · Dumbbell %s"):format(pickaxe, tostring(profile.EquippedTrainTool or "-"))
end

function Venxz.Scheduler.Summarize()
    local profile = Venxz.Data.Get()
    local cash, power = profile.Currencies.Cash, profile.Power or 0
    Venxz.Progress.LearnUpgrades(profile)
    State.StartCash = State.StartCash or cash
    State.StartPower = State.StartPower or power

    local abbr = Venxz.Util.Abbreviate
    local lines = {
        ("Cash %s (+%s)"):format(abbr(cash), abbr(cash - State.StartCash)),
        ("Power %s (+%s)"):format(abbr(power), abbr(power - State.StartPower)),
        ("Rebirth %d · Carry %s"):format(profile.Rebirth or 0, abbr(profile.Upgrades.Carry or 1)),
        Venxz.Scheduler.GearLine(profile),
        ("Inventory %d/%d · Looted %d"):format(Venxz.Util.Count(profile.Inventory), Venxz.Data.InventoryLimit(), State.Looted),
    }
    if State.Picked > 0 then lines[#lines + 1] = ("Event pickups %d"):format(State.Picked) end
    if State.Opt.AutoLoot and State.LootFull then lines[#lines + 1] = "WARNING: inventory full, Auto Loot paused" end
    State.Summary = table.concat(lines, "\n")
end

Venxz.Scheduler.Jobs = {
    { "Status", nil, Venxz.Scheduler.Summarize, 0 },
    { "Fullbright", "Fullbright", Venxz.World.ApplyFullbright, Config.FullbrightInterval },
    { "Auto Hatch", "AutoHatch", Venxz.Hatch.Step, Config.SellInterval },
    { "Auto Sell Eggs", "AutoSellEggs", Venxz.Sell.EggsNow, Config.SellInterval },
    { "Auto Sell Brainrots", "AutoSellBrainrots", Venxz.Sell.BrainrotsNow, Config.SellInterval },
    { "Auto Place Best", "AutoEquipBest", Venxz.Progress.EquipBest, Config.SellInterval },
    { "Auto Upgrade", "AutoUpgrade", Venxz.Progress.UpgradeNow, Config.UpgradeInterval },
    { "Auto Rebirth", "AutoRebirth", Venxz.Progress.RebirthNow, Config.UpgradeInterval },
    { "Auto Buy Dumbbell", "AutoBuyTool", Venxz.Progress.BuyBestTool, Config.UpgradeInterval },
    { "Auto Pickaxe", "AutoPickaxe", Venxz.Gear.PickaxeNow, Config.UpgradeInterval },
    { "Auto Train", "AutoTrain", Venxz.Progress.StartTraining, Config.UpgradeInterval },
    { "Auto Potion", "AutoPotion", Venxz.Boost.Step, Config.PotionInterval },
    { "Event Pickups", "AutoPickups", Venxz.Pickup.Step, Config.PickupInterval },
    { "Auto Spin", "AutoSpin", Venxz.Claim.Spin, Config.ClaimInterval },
    { "Season Pass", "AutoPass", Venxz.Claim.Pass, Config.ClaimInterval },
    { "Auto Claim", "AutoClaim", Venxz.Claim.All, Config.ClaimInterval },
}

---Switches a failing feature off from the scheduler thread; the UI pump flips the toggle (this thread has touched game modules).
function Venxz.Scheduler.Halt(label, idx, err)
    if idx and not State.Opt[idx] then return end
    local reason = tostring(err):match("^[^\n]*")
    if idx then
        State.Opt[idx] = false
        State.Halted[#State.Halted + 1] = idx
    end
    warn("[Venxz CSK] " .. label .. " stopped:", reason)
    Venxz.Util.Notify(label .. " stopped: " .. reason)
end

---@param job table  { label, toggle idx, step, interval }; a feature halts after Config.JobFailLimit errors spanning Config.JobFailWindow seconds, the status job only goes quiet
function Venxz.Scheduler.Run(job, now)
    if job[2] and not State.Opt[job[2]] then
        job.Streak = nil
        return
    end
    if now - (job.Last or 0) < job[4] then return end
    job.Last = now

    local ok, err = pcall(job[3])
    if ok then
        job.Streak = nil
        return
    end
    local streak = job.Streak
    if not streak then
        streak = { count = 0, since = now }
        job.Streak = streak
        warn("[Venxz CSK] " .. job[1] .. ":", err)
    end
    streak.count += 1
    if not job[2] or streak.count < Config.JobFailLimit or now - streak.since < Config.JobFailWindow then return end
    job.Streak = nil
    Venxz.Scheduler.Halt(job[1], job[2], err)
end

function Venxz.Scheduler.Step()
    for name, handler in pairs(Venxz.Scheduler.Requests) do
        if State.Requests[name] then
            State.Requests[name] = nil
            Venxz.Util.Try(handler)
        end
    end

    local now = os.clock()
    for _, job in ipairs(Venxz.Scheduler.Jobs) do
        Venxz.Scheduler.Run(job, now)
    end
end

function Venxz.Scheduler.Boot()
    Venxz.Movement.Bind()
    task.spawn(function()
        while State.Alive do
            if not State.Busy then
                State.Busy = true
                Venxz.Util.Try(Venxz.Scheduler.Step)
                State.Busy = false
            end
            task.wait(Config.TickDelay)
        end
    end)
end

function Venxz.Scheduler.Stop()
    State.Alive = false
    getgenv().VenxzCSKUnload = nil
    State.Opt.AutoLoot = false
    State.Opt.AutoPickups = false
    for _, conn in ipairs(State.Conns) do conn:Disconnect() end
    table.clear(State.Conns)
    if State.Opt.Noclip then Venxz.Movement.RestoreCollision() end
    if State.Opt.Speed then Venxz.Util.Try(Venxz.Movement.ResetSpeed) end
    Venxz.Util.Try(Venxz.World.RestoreLighting)
    if State.Trained then task.spawn(Venxz.Util.Try, Venxz.Progress.StopTraining) end
end

--[[==============================================================================
    6.  BOOT
==============================================================================]]--
if getgenv().VenxzCSKUnload then
    pcall(getgenv().VenxzCSKUnload)
end

pcall(VenxzBanner.Step, "Systems")
if BuildInterface() then
    pcall(VenxzBanner.Step, "Interface")
    pcall(VenxzBanner.Ready)
end
