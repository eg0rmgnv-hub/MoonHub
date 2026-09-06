local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Window = Fluent:CreateWindow({
    Title = "MoonHub",
    SubTitle = "Universal  v1.0",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 520),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Movement = Window:AddTab({ Title = "Movement", Icon = "move" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "crosshair" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "compass" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    Fluent:Notify({ Title = "MoonHub", Content = "Loaded successfully", Duration = 4 })
end

local function getCharacter()
    return LocalPlayer.Character
end
local function getHumanoid()
    local c = getCharacter()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getCharacter()
    return c and c:FindFirstChild("HumanoidRootPart")
end

------------------------------------------------
-- MOVEMENT
------------------------------------------------
local MovementSection = Tabs.Movement:AddSection("Locomotion")

local speedEnabled = false
local speedValue = 32
local jumpValue = 50
local flyEnabled = false
local flySpeed = 50
local noclipEnabled = false
local infJumpEnabled = false

Tabs.Movement:AddToggle("SpeedEnabled", { Title = "Enable Speed", Default = false, Callback = function(v) speedEnabled = v end })
Tabs.Movement:AddSlider("SpeedValue", { Title = "WalkSpeed", Default = 32, Min = 16, Max = 200, Rounding = 0, Callback = function(v) speedValue = v end })

Tabs.Movement:AddToggle("JumpEnabled", { Title = "Enable JumpPower", Default = false, Callback = function(v)
    local h = getHumanoid()
    if h then h.UseJumpPower = v end
end })
Tabs.Movement:AddSlider("JumpValue", { Title = "JumpPower", Default = 50, Min = 50, Max = 350, Rounding = 0, Callback = function(v)
    jumpValue = v
    local h = getHumanoid()
    if h and h.UseJumpPower then h.JumpPower = v end
    if h and not h.UseJumpPower then h.JumpHeight = v/4 end
end })

local flyConn, flyGyro, flyVel
local function startFly()
    local root = getRoot()
    if not root then return end
    flyGyro = Instance.new("BodyGyro")
    flyGyro.P = 9e4
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.CFrame = root.CFrame
    flyGyro.Parent = root
    flyVel = Instance.new("BodyVelocity")
    flyVel.Velocity = Vector3.new(0,0,0)
    flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVel.Parent = root
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyEnabled then return end
        local c = getCharacter()
        local r = getRoot()
        local h = getHumanoid()
        if not c or not r or not h then return end
        h.PlatformStand = true
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit * flySpeed else dir = Vector3.new(0,0,0) end
        flyVel.Velocity = dir
        flyGyro.CFrame = Camera.CFrame
    end)
end
local function stopFly()
    if flyConn then flyConn:Disconnect() flyConn=nil end
    if flyGyro then flyGyro:Destroy() flyGyro=nil end
    if flyVel then flyVel:Destroy() flyVel=nil end
    local h = getHumanoid()
    if h then h.PlatformStand = false end
end

Tabs.Movement:AddToggle("FlyToggle", { Title = "Fly", Default = false, Callback = function(v)
    flyEnabled = v
    if v then startFly() else stopFly() end
end })
Tabs.Movement:AddSlider("FlySpeed", { Title = "Fly Speed", Default = 50, Min = 10, Max = 300, Rounding = 0, Callback = function(v) flySpeed = v end })
Tabs.Movement:AddToggle("Noclip", { Title = "Noclip", Default = false, Callback = function(v) noclipEnabled = v end })
Tabs.Movement:AddToggle("InfJump", { Title = "Infinite Jump", Default = false, Callback = function(v) infJumpEnabled = v end })

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.7)
    local h = getHumanoid()
    if h then
        h.UseJumpPower = Options.JumpEnabled and Options.JumpEnabled.Value or false
        if h.UseJumpPower then h.JumpPower = jumpValue else h.JumpHeight = jumpValue/4 end
    end
    if flyEnabled then stopFly() task.wait(0.2) startFly() end
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled and getHumanoid() then
        pcall(function() getHumanoid():ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

------------------------------------------------
-- VISUALS
------------------------------------------------
local VisualsSection = Tabs.Visuals:AddSection("ESP")
local espEnabled = false
local espBoxes = false
local espNames = true
local espHealth = true
local espDistance = false
local tracerEnabled = false
local espFolder = Instance.new("Folder")
espFolder.Name = "MoonHub_ESP"
espFolder.Parent = game.CoreGui

local highlights = {}
local billboards = {}
local tracerLines = {}

local function clearESP(plr)
    if highlights[plr] then highlights[plr]:Destroy() highlights[plr]=nil end
    if billboards[plr] then billboards[plr]:Destroy() billboards[plr]=nil end
    if tracerLines[plr] then pcall(function() tracerLines[plr]:Remove() end) tracerLines[plr]=nil end
end

local function createESP(plr)
    if plr == LocalPlayer then return end
    pcall(clearESP, plr)
    local char = plr.Character
    if not char then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.FillTransparency = 0.6
    hl.FillColor = Color3.fromRGB(124, 58, 237)
    hl.OutlineColor = Color3.fromRGB(168, 123, 255)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = espEnabled and espBoxes
    hl.Parent = espFolder
    highlights[plr] = hl

    local bb = Instance.new("BillboardGui")
    bb.Adornee = char:WaitForChild("Head", 3) or char:FindFirstChildWhichIsA("BasePart")
    bb.Size = UDim2.fromOffset(200, 50)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = espFolder
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1,1)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextStrokeTransparency = 0.4
    label.TextColor3 = Color3.fromRGB(235,235,255)
    label.Text = plr.Name
    label.Parent = bb
    billboards[plr] = bb

    if tracerEnabled and Drawing then
        local line = Drawing.new("Line")
        line.Visible = true
        line.Thickness = 1.2
        line.Transparency = 0.85
        line.Color = Color3.fromRGB(124, 58, 237)
        tracerLines[plr] = line
    end

    char.AncestryChanged:Connect(function()
        if not char.Parent then clearESP(plr) end
    end)
end

local function updateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local bb = billboards[plr]
            local hl = highlights[plr]
            if bb and hl then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head")
                if char and hum and root and head and hum.Health > 0 then
                    hl.Enabled = espEnabled and espBoxes
                    bb.Enabled = espEnabled
                    local dist = LocalPlayer:DistanceFromCharacter(root.Position)
                    local txt = ""
                    if espNames then txt ..= plr.Name end
                    if espHealth and hum then txt ..= string.format("  [%d/%d]", math.floor(hum.Health), hum.MaxHealth) end
                    if espDistance then txt ..= string.format("  %dm", math.floor(dist)) end
                    bb:FindFirstChildOfClass("TextLabel").Text = txt
                    bb.Adornee = head
                    local col = Color3.fromRGB(124, 58, 237)
                    if hum.Health/hum.MaxHealth < 0.5 then col = Color3.fromRGB(239,68,68) end
                    hl.FillColor = col
                    hl.OutlineColor = col
                    if tracerLines[plr] then
                        local line = tracerLines[plr]
                        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                        line.Visible = onScreen and espEnabled and tracerEnabled
                        if onScreen then
                            line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                            line.To = Vector2.new(pos.X, pos.Y)
                        end
                    end
                else
                    hl.Enabled = false
                    bb.Enabled = false
                    if tracerLines[plr] then tracerLines[plr].Visible = false end
                end
            elseif espEnabled and plr.Character then
                createESP(plr)
            end
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then createESP(p) end end
Players.PlayerAdded:Connect(function(p) task.wait(1) if espEnabled then createESP(p) end p.CharacterAdded:Connect(function() task.wait(1) if espEnabled then createESP(p) end end) end)
Players.PlayerRemoving:Connect(clearESP)

Tabs.Visuals:AddToggle("ESP", { Title = "Enable ESP", Default = false, Callback = function(v)
    espEnabled = v
    if not v then
        for _,plr in ipairs(Players:GetPlayers()) do
            if highlights[plr] then highlights[plr].Enabled=false end
            if billboards[plr] then billboards[plr].Enabled=false end
            if tracerLines[plr] then tracerLines[plr].Visible=false end
        end
    else
        for _,plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer then createESP(plr) end end
    end
end })
Tabs.Visuals:AddToggle("ESPBox", { Title = "Highlight Box", Default = true, Callback = function(v) espBoxes=v end })
Tabs.Visuals:AddToggle("ESPName", { Title = "Show Name", Default = true, Callback = function(v) espNames=v end })
Tabs.Visuals:AddToggle("ESPHealth", { Title = "Show Health", Default = true, Callback = function(v) espHealth=v end })
Tabs.Visuals:AddToggle("ESPDistance", { Title = "Show Distance", Default = false, Callback = function(v) espDistance=v end })
Tabs.Visuals:AddToggle("Tracers", { Title = "Tracers", Default = false, Callback = function(v)
    tracerEnabled=v
    if not v then for _,l in pairs(tracerLines) do pcall(function() l.Visible=false end) end end
    if v and Drawing then for _,plr in ipairs(Players:GetPlayers()) do if plr~=LocalPlayer and not tracerLines[plr] then createESP(plr) end end end
end })

local fullbrightEnabled = false
local oldBrightness, oldAmbient, oldOutdoorAmbient, oldFogEnd
Tabs.Visuals:AddToggle("Fullbright", { Title = "Fullbright", Default = false, Callback = function(v)
    fullbrightEnabled=v
    if v then
        oldBrightness = Lighting.Brightness
        oldAmbient = Lighting.Ambient
        oldOutdoorAmbient = Lighting.OutdoorAmbient
        oldFogEnd = Lighting.FogEnd
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        if oldBrightness then Lighting.Brightness = oldBrightness end
        if oldAmbient then Lighting.Ambient = oldAmbient end
        if oldOutdoorAmbient then Lighting.OutdoorAmbient = oldOutdoorAmbient end
        if oldFogEnd then Lighting.FogEnd = oldFogEnd end
        Lighting.GlobalShadows = true
    end
end })
Tabs.Visuals:AddSlider("FOVSlider", { Title = "Field of View", Default = 70, Min = 70, Max = 120, Rounding = 0, Callback = function(v) Camera.FieldOfView = v end })
Tabs.Visuals:AddButton({ Title = "Remove Fog", Callback = function() Lighting.FogEnd = 100000 Lighting.FogStart = 0 end })

------------------------------------------------
-- COMBAT
------------------------------------------------
local aimEnabled = false
local teamCheck = true
local wallCheck = true
local aimPart = "Head"
local fovRadius = 160
local showFOV = true
local fovCircle

if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(124, 58, 237)
    fovCircle.Thickness = 1.2
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Transparency = 0.9
    fovCircle.Visible = false
end

local function isVisible(part)
    if not wallCheck then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local result = Workspace:Raycast(origin, dir, rayParams)
    return result == nil or result.Instance:IsDescendantOf(part.Parent)
end

local function getClosest()
    local closest, dist = nil, fovRadius
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if teamCheck and plr.Team == LocalPlayer.Team then continue end
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local target = char and char:FindFirstChild(aimPart)
            if char and hum and target and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
                if onScreen and isVisible(target) then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < dist then
                        dist = mag
                        closest = target
                    end
                end
            end
        end
    end
    return closest
end

Tabs.Combat:AddToggle("Aimbot", { Title = "Aimbot (Hold RMB)", Default = false, Callback = function(v) aimEnabled=v end })
Tabs.Combat:AddToggle("TeamCheck", { Title = "Team Check", Default = true, Callback = function(v) teamCheck=v end })
Tabs.Combat:AddToggle("WallCheck", { Title = "Wall Check", Default = true, Callback = function(v) wallCheck=v end })
Tabs.Combat:AddToggle("ShowFOV", { Title = "Show FOV Circle", Default = true, Callback = function(v) showFOV=v end })
Tabs.Combat:AddSlider("FOVRadius", { Title = "FOV Radius", Default = 160, Min = 40, Max = 600, Rounding = 0, Callback = function(v) fovRadius=v if fovCircle then fovCircle.Radius=v end end })
Tabs.Combat:AddDropdown("AimPart", { Title = "Aim Part", Values = {"Head","HumanoidRootPart","Torso"}, Default = 1, Callback = function(v) aimPart=v end })

------------------------------------------------
-- PLAYER
------------------------------------------------
Tabs.Player:AddSection("Character")
local antiAFK = false
Tabs.Player:AddToggle("AntiAFK", { Title = "Anti AFK", Default = false, Callback = function(v)
    antiAFK=v
    if v then
        Fluent:Notify({ Title = "Anti AFK", Content = "Enabled", Duration = 3 })
    end
end })
Tabs.Player:AddButton({ Title = "Anti Ragdoll", Callback = function()
    local c = getCharacter()
    if c then
        for _,v in ipairs(c:GetDescendants()) do
            if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then v:Destroy() end
        end
        Fluent:Notify({ Title = "Player", Content = "Ragdoll constraints removed", Duration = 3 })
    end
end })
Tabs.Player:AddButton({ Title = "Invisible (Hold tool)", Callback = function()
    local c = getCharacter()
    if not c then return end
    for _,part in ipairs(c:GetDescendants()) do
        if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
            part.Transparency = part.Transparency==1 and 0 or 1
        end
    end
end })
Tabs.Player:AddButton({ Title = "Reset Character", Callback = function()
    local h = getHumanoid()
    if h then h.Health = 0 end
end })
Tabs.Player:AddButton({ Title = "Sit / Unsit", Callback = function()
    local h = getHumanoid()
    if h then h.Sit = not h.Sit end
end })

------------------------------------------------
-- UTILITY
------------------------------------------------
Tabs.Utility:AddSection("Teleport")
local clickTPEnabled = false
local clickTPTool = nil
Tabs.Utility:AddToggle("ClickTP", { Title = "Click TP Tool", Default = false, Callback = function(v)
    clickTPEnabled=v
    if v then
        clickTPTool = Instance.new("Tool")
        clickTPTool.Name = "Moon TP"
        clickTPTool.RequiresHandle = false
        clickTPTool.CanBeDropped = false
        clickTPTool.Parent = LocalPlayer.Backpack
        clickTPTool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local root = getRoot()
            if mouse.Hit and root then
                root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
            end
        end)
    else
        if clickTPTool then clickTPTool:Destroy() clickTPTool=nil end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then for _,t in ipairs(bp:GetChildren()) do if t.Name=="Moon TP" then t:Destroy() end end end
        local c = getCharacter()
        if c then for _,t in ipairs(c:GetChildren()) do if t.Name=="Moon TP" then t:Destroy() end end end
    end
end })
Tabs.Utility:AddButton({ Title = "Teleport to Spawn", Callback = function()
    local root = getRoot()
    if root then root.CFrame = CFrame.new(0, 10, 0) end
end })
Tabs.Utility:AddInput("TPPlayer", { Title = "Teleport to Player", Placeholder = "Username", Callback = function() end })
Tabs.Utility:AddButton({ Title = "Teleport", Callback = function()
    local name = Options.TPPlayer.Value
    local plr = Players:FindFirstChild(name)
    if not plr then
        for _,p in ipairs(Players:GetPlayers()) do if p.Name:lower():sub(1,#name)==name:lower() then plr=p break end end
    end
    local target = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if target and root then root.CFrame = target.CFrame + Vector3.new(0,2,0)
    else Fluent:Notify({ Title = "Teleport", Content = "Player not found", Duration = 3 }) end
end })

Tabs.Utility:AddSection("Server")
Tabs.Utility:AddButton({ Title = "Rejoin Server", Callback = function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end })
Tabs.Utility:AddButton({ Title = "Server Hop", Callback = function()
    local servers = game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
    local data = game:GetService("HttpService"):JSONDecode(servers)
    for _,s in ipairs(data.data) do if s.id ~= game.JobId and s.playing < s.maxPlayers then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) return end end
    Fluent:Notify({ Title = "Server Hop", Content = "No servers found", Duration = 3 })
end })
Tabs.Utility:AddButton({ Title = "Copy JobId", Callback = function()
    if setclipboard then setclipboard(game.JobId) Fluent:Notify({ Title = "Copied", Content = game.JobId, Duration = 3 }) end
end })
Tabs.Utility:AddButton({ Title = "FPS Boost", Callback = function()
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
    end
    Lighting.GlobalShadows = false
    Fluent:Notify({ Title = "Optimization", Content = "FPS Boost applied", Duration = 3 })
end })

------------------------------------------------
-- SETTINGS
------------------------------------------------
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("MoonHub")
SaveManager:SetFolder("MoonHub/config")
SaveManager:BuildConfigSection(Tabs.Settings)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

------------------------------------------------
-- LOOPS
------------------------------------------------
RunService.RenderStepped:Connect(function()
    if speedEnabled then
        local h = getHumanoid()
        if h then h.WalkSpeed = speedValue end
    end
    if noclipEnabled then
        local c = getCharacter()
        if c then for _,part in ipairs(c:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end end
    end

    if fovCircle then
        fovCircle.Visible = showFOV and aimEnabled
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Radius = fovRadius
    end
    if aimEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosest()
        if target then
            local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
            if onScreen then
                local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                local delta = Vector2.new(pos.X, pos.Y) - center
                if mousemoverel then mousemoverel(delta.X, delta.Y)
                else
                    local sens = 0.18
                    mousemoveabs(center.X + delta.X*sens, center.Y + delta.Y*sens)
                end
            end
        end
    end

    updateESP()
end)

LocalPlayer.Idled:Connect(function()
    if antiAFK then VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end
end)

Fluent:Notify({ Title = "MoonHub", Content = "Press LeftControl to hide", Duration = 5 })
