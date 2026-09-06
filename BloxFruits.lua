if game.PlaceId ~= 2753915549 and game.PlaceId ~= 4442272183 and game.PlaceId ~= 7449423635 then
    warn("MoonHub Blox Fruits: Wrong game")
end

local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and res ~= "" and #res > 100 then return res end
    ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res and res ~= "" and #res > 100 then return res end
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if req then
        ok, res = pcall(function() return req({Url=url, Method="GET"}).Body end)
        if ok and res and res ~= "" and #res > 100 then return res end
    end
    return nil
end
local function safeLoad(url)
    local src = httpGet(url)
    if not src then return nil end
    local fn, err = loadstring(src)
    if not fn then warn("Load failed "..url.." : "..tostring(err)) return nil end
    return fn
end
local FluentFn = safeLoad("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua")
if not FluentFn then FluentFn = safeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua") end
if not FluentFn then FluentFn = safeLoad("https://cdn.jsdelivr.net/gh/dawid-scripts/Fluent@master/main.lua") end
if not FluentFn then error("MoonHub: HttpGet blocked by executor. Use Delta/Wave") end
local Fluent = FluentFn()
if not Fluent or not Fluent.CreateWindow then error("MoonHub: Fluent load failed - try different executor") end
local smFn = safeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")
local imFn = safeLoad("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua")
local SaveManager = smFn and smFn() or nil
local InterfaceManager = imFn and imFn() or nil

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local winOk, Window = pcall(function()
    return Fluent:CreateWindow({
        Title = "MoonHub",
        SubTitle = "Blox Fruits  |  MAX",
        TabWidth = 165,
        Size = UDim2.fromOffset(640, 540),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })
end)
if not winOk or not Window then
    warn("MoonHub: Fluent CreateWindow failed, using fallback")
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title="MoonHub", Text="Fluent failed on this executor. Use Wave/Delta", Duration=6}) end)
    error("Fluent Window failed")
end

local Tabs = {
    Main = Window:AddTab({ Title = "Auto Farm", Icon = "swords" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart-3" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    World = Window:AddTab({ Title = "World", Icon = "map" }),
    Sea = Window:AddTab({ Title = "Sea Events", Icon = "waves" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Fluent:Notify({ Title = "MoonHub", Content = "Blox Fruits loaded", Duration = 4 })

local function getChar() return LocalPlayer.Character end
local function getRoot() local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end

local function tweenTo(pos, speed)
    local root = getRoot()
    if not root then return end
    local dist = (root.Position - pos).Magnitude
    local time = dist / (speed or 320)
    local tween = TweenService:Create(root, TweenInfo.new(time, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
    return tween
end

local function fireRemote(...)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local comm = ReplicatedStorage:FindFirstChild("CommF_")
        if comm then comm:InvokeServer(...) end
    end)
end

------------------------------------------------
-- MAIN TAB
------------------------------------------------
local farmEnabled = false
local farmMode = "Level"
local fastAttack = true
local bringMob = true
local farmTweenSpeed = 320
local selectedWeapon = "Melee"

Tabs.Main:AddSection("Farming")

Tabs.Main:AddToggle("AutoFarm", { Title = "Enable Auto Farm", Default = false, Callback = function(v) farmEnabled = v end })
Tabs.Main:AddDropdown("FarmMode", { Title = "Farm Mode", Values = {"Level", "Mastery", "Bone", "Chest", "Nearest"}, Default = 1, Callback = function(v) farmMode = v end })
Tabs.Main:AddDropdown("Weapon", { Title = "Weapon", Values = {"Melee","Sword","Gun","Fruit"}, Default = 1, Callback = function(v) selectedWeapon = v end })
Tabs.Main:AddSlider("TweenSpeed", { Title = "Tween Speed", Default = 320, Min = 150, Max = 600, Rounding = 0, Callback = function(v) farmTweenSpeed = v end })
Tabs.Main:AddToggle("FastAttack", { Title = "Fast Attack", Default = true, Callback = function(v) fastAttack = v end })
Tabs.Main:AddToggle("BringMob", { Title = "Bring Mob", Default = true, Callback = function(v) bringMob = v end })
Tabs.Main:AddToggle("AutoQuest", { Title = "Auto Take Quest", Default = true, Callback = function(v) _G.AutoQuest = v end })

Tabs.Main:AddSection("Safety")
Tabs.Main:AddToggle("NoClipFarm", { Title = "NoClip During Farm", Default = true, Callback = function(v) _G.FarmNoClip = v end })
Tabs.Main:AddButton({ Title = "Stop All Tweens", Callback = function() farmEnabled=false Fluent:Notify({Title="Farm", Content="Stopped", Duration=2}) end })

local function getQuestMob()
    local questMobs = {
        ["Bandit"] = {Level=0, Quest="BanditQuest1", Pos=Vector3.new(1060, 16, 1547)},
        ["Monkey"] = {Level=10, Quest="JungleQuest", Pos=Vector3.new(-1602, 36, 153)},
        ["Gorilla"] = {Level=20, Quest="JungleQuest", Pos=Vector3.new(-1230, 6, -508)},
        ["Pirate"] = {Level=35, Quest="BuggyQuest1", Pos=Vector3.new(-1140, 4, 3832)},
        ["Brute"] = {Level=45, Quest="BuggyQuest1", Pos=Vector3.new(-1140, 4, 3832)},
        ["Desert Bandit"] = {Level=60, Quest="DesertQuest", Pos=Vector3.new(932, 6, 4485)},
    }
    local lvl = LocalPlayer.Data and LocalPlayer.Data.Level and LocalPlayer.Data.Level.Value or 0
    local best = "Bandit"
    for name, data in pairs(questMobs) do
        if lvl >= data.Level then best = name end
    end
    return best, questMobs[best]
end

task.spawn(function()
    while task.wait(0.15) do
        if not farmEnabled then continue end
        pcall(function()
            local root = getRoot()
            local hum = getHum()
            if not root or not hum then return end

            if _G.FarmNoClip then
                local c=getChar()
                for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
            end

            if farmMode == "Level" then
                local mobName, qData = getQuestMob()
                if _G.AutoQuest then
                    local hasQuest = LocalPlayer.PlayerGui.Main.Quest.Visible
                    if not hasQuest then
                        fireRemote("StartQuest", qData.Quest, 1)
                        task.wait(0.3)
                    end
                end
                local mob = nil
                local minDist = math.huge
                for _,v in ipairs(Workspace.Enemies:GetChildren()) do
                    if v.Name:find(mobName) and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health>0 then
                        local d = (root.Position - v.HumanoidRootPart.Position).Magnitude
                        if d < minDist then minDist=d mob=v end
                    end
                end
                if mob and mob:FindFirstChild("HumanoidRootPart") then
                    if bringMob then
                        for _,e in ipairs(Workspace.Enemies:GetChildren()) do
                            if e.Name==mob.Name and e~=mob and e:FindFirstChild("HumanoidRootPart") and (e.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude < 60 then
                                e.HumanoidRootPart.CFrame = mob.HumanoidRootPart.CFrame
                                e.Humanoid.WalkSpeed=0
                                e.Humanoid.JumpPower=0
                            end
                        end
                        mob.HumanoidRootPart.CanCollide=false
                        mob.HumanoidRootPart.Size=Vector3.new(60,60,60)
                    end
                    if minDist > 70 then
                        tweenTo(mob.HumanoidRootPart.Position + Vector3.new(0,10,8), farmTweenSpeed)
                    else
                        root.CFrame = mob.HumanoidRootPart.CFrame * CFrame.new(0,10,8)
                        if fastAttack then
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(0,0))
                            fireRemote("Attack", mob)
                        end
                    end
                else
                    tweenTo(qData.Pos, farmTweenSpeed)
                end

            elseif farmMode == "Chest" then
                local chest=nil local md=math.huge
                for _,v in ipairs(Workspace:GetDescendants()) do
                    if v.Name:find("Chest") and v:IsA("BasePart") then
                        local d=(root.Position - v.Position).Magnitude
                        if d<md then md=d chest=v end
                    end
                end
                if chest then
                    if md>25 then tweenTo(chest.Position, farmTweenSpeed) else root.CFrame=chest.CFrame end
                end
            end
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if farmEnabled and fastAttack then
        pcall(function()
            local c=getChar()
            local tool=c and c:FindFirstChildOfClass("Tool")
            if tool then
                local cd = tool:FindFirstChild("Cooldown")
                if cd then cd.Value=0 end
            end
        end)
    end
end)

------------------------------------------------
-- STATS
------------------------------------------------
Tabs.Stats:AddSection("Auto Stats")
local autoStats = false
local statMelee, statDefense, statSword, statGun, statFruit = 50, 25, 10, 10, 10

Tabs.Stats:AddToggle("AutoStats", { Title = "Enable Auto Stats", Default = false, Callback = function(v) autoStats=v end })
Tabs.Stats:AddSlider("Melee", { Title = "Melee %", Default = 50, Min = 0, Max = 100, Rounding = 0, Callback = function(v) statMelee=v end })
Tabs.Stats:AddSlider("Defense", { Title = "Defense %", Default = 25, Min = 0, Max = 100, Rounding = 0, Callback = function(v) statDefense=v end })
Tabs.Stats:AddSlider("Sword", { Title = "Sword %", Default = 10, Min = 0, Max = 100, Rounding = 0, Callback = function(v) statSword=v end })
Tabs.Stats:AddSlider("Gun", { Title = "Gun %", Default = 10, Min = 0, Max = 100, Rounding = 0, Callback = function(v) statGun=v end })
Tabs.Stats:AddSlider("Fruit", { Title = "Blox Fruit %", Default = 10, Min = 0, Max = 100, Rounding = 0, Callback = function(v) statFruit=v end })

Tabs.Stats:AddButton({ Title = "Refund Stats ( 2500 Fragments )", Callback = function() fireRemote("BlackbeardReward","Refund","1") fireRemote("BlackbeardReward","Refund","2") end })

task.spawn(function()
    while task.wait(0.8) do
        if not autoStats then continue end
        pcall(function()
            local points = LocalPlayer.Data.Points.Value
            if points <= 0 then return end
            local total = statMelee + statDefense + statSword + statGun + statFruit
            if total==0 then return end
            local function add(stat, pct)
                local addPoints = math.floor(points * (pct/total))
                if addPoints>0 then fireRemote("AddPoint", stat, addPoints) end
            end
            add("Melee", statMelee)
            add("Defense", statDefense)
            add("Sword", statSword)
            add("Gun", statGun)
            add("Demon Fruit", statFruit)
        end)
    end
end)

------------------------------------------------
-- COMBAT
------------------------------------------------
Tabs.Combat:AddSection("Mastery & Haki")
Tabs.Combat:AddToggle("AutoHaki", { Title = "Auto Ken Haki", Default = false, Callback = function(v) _G.AutoHaki=v end })
Tabs.Combat:AddToggle("AutoBuso", { Title = "Auto Buso Haki", Default = false, Callback = function(v) _G.AutoBuso=v end })
Tabs.Combat:AddToggle("AutoMastery", { Title = "Auto Mastery Farm", Default = false, Callback = function(v) _G.AutoMastery=v end })

task.spawn(function()
    while task.wait(1) do
        if _G.AutoHaki and not LocalPlayer.Character:FindFirstChild("HasBuso") then fireRemote("Ken", true) end
        if _G.AutoBuso then fireRemote("Buso") end
    end
end)

Tabs.Combat:AddButton({ Title = "Get Superhuman", Callback = function() fireRemote("BuySuperhuman") end })
Tabs.Combat:AddButton({ Title = "Get Godhuman", Callback = function() fireRemote("BuyGodhuman") end })

------------------------------------------------
-- WORLD
------------------------------------------------
Tabs.World:AddSection("Teleports")
local islands = {
    ["Starter Island"]=Vector3.new(1071,16,1426),
    ["Jungle"]=Vector3.new(-1249,11,-344),
    ["Pirate Village"]=Vector3.new(-1122,4,3855),
    ["Desert"]=Vector3.new(1094,6,4229),
    ["Frozen Village"]=Vector3.new(1180,27,-1211),
    ["Marine Fortress"]=Vector3.new(-484,20,3536),
    ["Sky Island 1"]=Vector3.new(-4656,873,-1754),
    ["Colosseum"]=Vector3.new(-1428,7,-3014),
    ["Magma Village"]=Vector3.new(-524,12,8519),
    ["Underwater City"]=Vector3.new(61163,11,1819),
    ["Fountain City"]=Vector3.new(5132,4,4035),
    ["Hot/Cold"]=Vector3.new(5948,75,-4811),
    ["Sea Castle"]=Vector3.new(-5073,314,-3150),
    ["Haunted Castle"]=Vector3.new(-9517,142,-121),
    ["Turtle Mansion"]=Vector3.new(-12462,375,-7550),
}

Tabs.World:AddDropdown("IslandTP", { Title = "Select Island", Values = {"Starter Island","Jungle","Pirate Village","Desert","Frozen Village","Marine Fortress","Sky Island 1","Colosseum","Magma Village","Underwater City","Fountain City","Hot/Cold","Sea Castle","Haunted Castle","Turtle Mansion"}, Default = 1, Callback = function(v) _G.SelectedIsland=v end })
Tabs.World:AddButton({ Title = "Teleport", Callback = function()
    local pos = islands[_G.SelectedIsland or "Starter Island"]
    if pos and getRoot() then getRoot().CFrame = CFrame.new(pos + Vector3.new(0,5,0)) end
end })
Tabs.World:AddButton({ Title = "Walk on Water", Callback = function()
    local water = Workspace:FindFirstChild("WaterBase") or Instance.new("Part", Workspace)
    water.Name="WaterBase" water.Size=Vector3.new(10000,1,10000) water.Position=Vector3.new(0,-5,0) water.Anchored=true water.Transparency=0.6 water.Material=Enum.Material.ForceField water.Color=Color3.fromRGB(124,58,237)
    Fluent:Notify({Title="World", Content="Water platform created", Duration=3})
end })

Tabs.World:AddSection("ESP")
local espFruit=false
local fruitESPFolder=Instance.new("Folder", game.CoreGui) fruitESPFolder.Name="MoonHub_FruitESP"
local function fruitESP()
    while task.wait(0.6) do
        if not espFruit then continue end
        for _,v in ipairs(Workspace:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("Handle") then
                if not fruitESPFolder:FindFirstChild(v.Name) then
                    local bb=Instance.new("BillboardGui", fruitESPFolder) bb.Name=v.Name bb.Adornee=v.Handle bb.Size=UDim2.fromOffset(180,50) bb.AlwaysOnTop=true bb.StudsOffset=Vector3.new(0,2,0)
                    local tl=Instance.new("TextLabel", bb) tl.Size=UDim2.fromScale(1,1) tl.BackgroundTransparency=1 tl.Text=v.Name tl.TextColor3=Color3.fromRGB(168,123,255) tl.TextStrokeTransparency=0.3 tl.Font=Enum.Font.GothamBold tl.TextSize=14
                    local hl=Instance.new("Highlight", v) hl.FillColor=Color3.fromRGB(124,58,237) hl.OutlineColor=Color3.fromRGB(255,255,255) hl.FillTransparency=0.5
                end
            end
        end
    end
end
task.spawn(fruitESP)

Tabs.World:AddToggle("FruitESP", { Title = "Fruit ESP", Default = false, Callback = function(v) espFruit=v if not v then fruitESPFolder:ClearAllChildren() end end })
Tabs.World:AddToggle("ChestESP", { Title = "Chest ESP", Default = false, Callback = function(v)
    _G.ChestESP=v
    if v then
        for _,ch in ipairs(Workspace:GetDescendants()) do if ch.Name:find("Chest") and ch:IsA("BasePart") and not ch:FindFirstChild("MoonESP") then local bb=Instance.new("BillboardGui", ch) bb.Name="MoonESP" bb.Size=UDim2.fromOffset(100,40) bb.Adornee=ch bb.AlwaysOnTop=true local tl=Instance.new("TextLabel", bb) tl.Size=UDim2.fromScale(1,1) tl.BackgroundTransparency=1 tl.Text="CHEST" tl.TextColor3=Color3.fromRGB(255,230,100) tl.TextSize=12 tl.Font=Enum.Font.GothamBold end end
    else
        for _,ch in ipairs(Workspace:GetDescendants()) do if ch:FindFirstChild("MoonESP") then ch.MoonESP:Destroy() end end
    end
end })
Tabs.World:AddButton({ Title = "Fruit Notifier (Chat)", Callback = function()
    Workspace.ChildAdded:Connect(function(c) if c:IsA("Tool") then Fluent:Notify({Title="FRUIT SPAWNED", Content=c.Name.." spawned!", Duration=10}) end end)
    Fluent:Notify({Title="Notifier", Content="Enabled", Duration=3})
end })
Tabs.World:AddButton({ Title = "Store Fruit", Callback = function() fireRemote("StoreFruit", getChar():FindFirstChildOfClass("Tool") and getChar():FindFirstChildOfClass("Tool").Name or "") end })
Tabs.World:AddButton({ Title = "Random Fruit (Gacha)", Callback = function() fireRemote("Cousin","Buy") end })

------------------------------------------------
-- SEA EVENTS
------------------------------------------------
Tabs.Sea:AddSection("Sea Events")
Tabs.Sea:AddToggle("AutoSeaBeast", { Title = "Auto Sea Beast", Default = false, Callback = function(v) _G.AutoSeaBeast=v end })
Tabs.Sea:AddToggle("AutoShip", { Title = "Auto Ghost Ship", Default = false, Callback = function(v) _G.AutoShip=v end })
Tabs.Sea:AddToggle("AutoMirage", { Title = "Auto Mirage Island Finder", Default = false, Callback = function(v) _G.AutoMirage=v end })
Tabs.Sea:AddToggle("AutoKitsune", { Title = "Auto Kitsune Island", Default = false, Callback = function(v) _G.AutoKitsune=v end })
Tabs.Sea:AddToggle("AutoPrehistoric", { Title = "Auto Prehistoric Island", Default = false, Callback = function(v) _G.AutoPrehistoric=v end })

Tabs.Sea:AddButton({ Title = "Teleport to Mirage (if spawned)", Callback = function()
    local mirage=Workspace:FindFirstChild("Mirage Island")
    if mirage and mirage:FindFirstChild("Island") then getRoot().CFrame=mirage.Island.CFrame+Vector3.new(0,120,0)
    else Fluent:Notify({Title="Mirage", Content="Not spawned", Duration=3}) end
end })
Tabs.Sea:AddButton({ Title = "Teleport to Kitsune Shrine", Callback = function()
    local shrine=Workspace:FindFirstChild("KitsuneShrine")
    if shrine then getRoot().CFrame=shrine:GetPivot()+Vector3.new(0,10,0)
    else Fluent:Notify({Title="Kitsune", Content="Island not found", Duration=3}) end
end })

task.spawn(function()
    while task.wait(1.2) do
        if _G.AutoSeaBeast then
            for _,v in ipairs(Workspace.SeaBeasts:GetChildren()) do if v:FindFirstChild("HumanoidRootPart") then getRoot().CFrame=v.HumanoidRootPart.CFrame*CFrame.new(0,40,20) VirtualUser:CaptureController() VirtualUser:ClickButton1(Vector2.new()) end end
        end
        if _G.AutoMirage then fireRemote("CheckMirage") end
    end
end)

------------------------------------------------
-- SETTINGS
------------------------------------------------
if SaveManager and InterfaceManager then
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("MoonHubBF")
    SaveManager:SetFolder("MoonHubBF/config")
    SaveManager:BuildConfigSection(Tabs.Settings)
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    Window:SelectTab(1)
    pcall(function() SaveManager:LoadAutoloadConfig() end)
else
    Window:SelectTab(1)
end

Fluent:Notify({Title="MoonHub", Content="Press LeftControl to hide", Duration=5})
