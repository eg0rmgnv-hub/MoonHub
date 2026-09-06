-- MoonHub Blox Fruits XENO LITE - no Fluent, native UI
if game.PlaceId ~= 2753915549 and game.PlaceId ~= 4442272183 and game.PlaceId ~= 7449423635 then warn("Wrong game") end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local function getChar() return LocalPlayer.Character end
local function getRoot() local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function fireRemote(...) pcall(function() local comm=ReplicatedStorage:FindFirstChild("CommF_") if comm then comm:InvokeServer(...) end end) end
local function tweenTo(pos, speed)
    local root=getRoot() if not root then return end
    local dist=(root.Position-pos).Magnitude
    local t=TweenService:Create(root, TweenInfo.new(dist/(speed or 320), Enum.EasingStyle.Linear), {CFrame=CFrame.new(pos)})
    t:Play() return t
end

-- STATE
local farmEnabled=false
local farmMode="Level"
local farmSpeed=320
local fastAttack=true
local bringMob=true
local autoQuest=true
local farmNoClip=true
local espFruit=false

-- UI
local gui=Instance.new("ScreenGui")
gui.Name="MoonHubXeno"
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent=gethui and gethui() or game.CoreGui end)
if not gui.Parent then gui.Parent=LocalPlayer:WaitForChild("PlayerGui") end

local main=Instance.new("Frame", gui)
main.Size=UDim2.fromOffset(520, 340)
main.Position=UDim2.fromOffset(60, 80)
main.BackgroundColor3=Color3.fromRGB(14,14,20)
main.BorderSizePixel=0
Instance.new("UICorner", main).CornerRadius=UDim.new(0,12)
local stroke=Instance.new("UIStroke", main) stroke.Color=Color3.fromRGB(124,58,237) stroke.Thickness=1.2 stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

local title=Instance.new("TextLabel", main)
title.Size=UDim2.new(1,0,0,42) title.BackgroundColor3=Color3.fromRGB(18,18,28) title.BorderSizePixel=0 title.Text="  MoonHub  —  Blox Fruits  [XENO LITE]" title.Font=Enum.Font.GothamBold title.TextSize=14 title.TextColor3=Color3.fromRGB(235,235,255) title.TextXAlignment=Enum.TextXAlignment.Left
Instance.new("UICorner", title).CornerRadius=UDim.new(0,12)
local grad=Instance.new("UIGradient", title) grad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(124,58,237)), ColorSequenceKeypoint.new(1,Color3.fromRGB(59,130,246))} grad.Rotation=90

local close=Instance.new("TextButton", main)
close.Size=UDim2.fromOffset(32,28) close.Position=UDim2.new(1,-38,0,7) close.Text="X" close.Font=Enum.Font.GothamBold close.TextSize=14 close.TextColor3=Color3.fromRGB(200,200,220) close.BackgroundColor3=Color3.fromRGB(35,35,50) close.BorderSizePixel=0
Instance.new("UICorner", close).CornerRadius=UDim.new(0,8)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local drag, dragStart, startPos
title.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true dragStart=i.Position startPos=main.Position end end)
UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-dragStart main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)

local function makeBtn(parent, text, y, color)
    local b=Instance.new("TextButton", parent)
    b.Size=UDim2.new(1,-12,0,32) b.Position=UDim2.fromOffset(6,y) b.Text=text b.Font=Enum.Font.GothamMedium b.TextSize=12 b.TextColor3=Color3.fromRGB(240,240,255) b.BackgroundColor3=color or Color3.fromRGB(36,36,48) b.BorderSizePixel=0
    Instance.new("UICorner", b).CornerRadius=UDim.new(0,8)
    local s=Instance.new("UIStroke", b) s.Color=Color3.fromRGB(70,70,90) s.Thickness=1
    return b
end

local function notify(txt)
    pcall(function() game.StarterGui:SetCore("SendNotification", {Title="MoonHub", Text=txt, Duration=3}) end)
end

-- LEFT PANEL
local left=Instance.new("Frame", main) left.Size=UDim2.new(1,0,1,-42) left.Position=UDim2.fromOffset(0,42) left.BackgroundTransparency=1
local tab1=makeBtn(left, "Auto Farm: OFF", 8, Color3.fromRGB(32,32,44))
local tab2=makeBtn(left, "FarmMode: Level", 44, Color3.fromRGB(32,32,44))
local tab3=makeBtn(left, "Fast Attack: ON", 80, Color3.fromRGB(36,36,48))
local tab4=makeBtn(left, "Bring Mob: ON", 116, Color3.fromRGB(36,36,48))
local tab5=makeBtn(left, "NoClip: ON", 152, Color3.fromRGB(36,36,48))
local tab6=makeBtn(left, "Fruit ESP: OFF", 188, Color3.fromRGB(32,32,44))
local tab7=makeBtn(left, "Walk on Water", 232, Color3.fromRGB(28,42,70))
local tab8=makeBtn(left, "TP to Starter Island", 268, Color3.fromRGB(28,42,70))

local status=Instance.new("TextLabel", left)
status.Size=UDim2.new(1,-12,0,24) status.Position=UDim2.fromOffset(6,306) status.BackgroundTransparency=1 status.Text="Status: Idle  |  Xeno Lite  |  LeftCtrl hide" status.Font=Enum.Font.Gotham status.TextSize=11 status.TextColor3=Color3.fromRGB(160,160,180) status.TextXAlignment=Enum.TextXAlignment.Left

tab1.MouseButton1Click:Connect(function()
    farmEnabled=not farmEnabled
    tab1.Text=farmEnabled and "Auto Farm: ON" or "Auto Farm: OFF"
    tab1.BackgroundColor3=farmEnabled and Color3.fromRGB(124,58,237) or Color3.fromRGB(32,32,44)
    status.Text=farmEnabled and "Status: Farming "..farmMode or "Status: Idle"
    notify(tab1.Text)
end)
tab2.MouseButton1Click:Connect(function()
    farmMode=farmMode=="Level" and "Chest" or "Level"
    tab2.Text="FarmMode: "..farmMode
    status.Text="Status: "..farmMode
end)
tab3.MouseButton1Click:Connect(function() fastAttack=not fastAttack tab3.Text="Fast Attack: "..(fastAttack and "ON" or "OFF") end)
tab4.MouseButton1Click:Connect(function() bringMob=not bringMob tab4.Text="Bring Mob: "..(bringMob and "ON" or "OFF") end)
tab5.MouseButton1Click:Connect(function() farmNoClip=not farmNoClip tab5.Text="NoClip: "..(farmNoClip and "ON" or "OFF") end)

local fruitFolder=Instance.new("Folder", gui) fruitFolder.Name="MoonESP"
tab6.MouseButton1Click:Connect(function()
    espFruit=not espFruit
    tab6.Text="Fruit ESP: "..(espFruit and "ON" or "OFF")
    tab6.BackgroundColor3=espFruit and Color3.fromRGB(124,58,237) or Color3.fromRGB(32,32,44)
    if not espFruit then fruitFolder:ClearAllChildren() end
end)

tab7.MouseButton1Click:Connect(function()
    local w=Workspace:FindFirstChild("WaterBase") or Instance.new("Part", Workspace)
    w.Name="WaterBase" w.Size=Vector3.new(10000,1,10000) w.Position=Vector3.new(0,-5,0) w.Anchored=true w.Transparency=0.6 w.Material=Enum.Material.ForceField w.Color=Color3.fromRGB(124,58,237)
    notify("Water platform created")
end)

local islands={["Starter Island"]=Vector3.new(1071,16,1426), ["Jungle"]=Vector3.new(-1249,11,-344), ["Desert"]=Vector3.new(1094,6,4229), ["Frozen"]=Vector3.new(1180,27,-1211), ["Sea Castle"]=Vector3.new(-5073,314,-3150)}
tab8.MouseButton1Click:Connect(function()
    local r=getRoot() if r then r.CFrame=CFrame.new(islands["Starter Island"]+Vector3.new(0,5,0)) end
end)

UserInputService.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.LeftControl then gui.Enabled=not gui.Enabled end end)

-- FARM LOGIC
local function getQuestMob()
    local m={["Bandit"]={Level=0, Quest="BanditQuest1", Pos=Vector3.new(1060,16,1547)}, ["Monkey"]={Level=10, Quest="JungleQuest", Pos=Vector3.new(-1602,36,153)}, ["Gorilla"]={Level=20, Quest="JungleQuest", Pos=Vector3.new(-1230,6,-508)}, ["Pirate"]={Level=35, Quest="BuggyQuest1", Pos=Vector3.new(-1140,4,3832)}, ["Desert Bandit"]={Level=60, Quest="DesertQuest", Pos=Vector3.new(932,6,4485)}}
    local lvl=LocalPlayer.Data and LocalPlayer.Data.Level and LocalPlayer.Data.Level.Value or 0
    local best="Bandit" for n,d in pairs(m) do if lvl>=d.Level then best=n end end
    return best, m[best]
end

task.spawn(function()
    while task.wait(0.14) do
        if not farmEnabled then continue end
        pcall(function()
            local root=getRoot() local hum=getHum() if not root or not hum then return end
            if farmNoClip then local c=getChar() for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end
            if farmMode=="Level" then
                local mobName, qData=getQuestMob()
                local hasQuest=false pcall(function() hasQuest=LocalPlayer.PlayerGui.Main.Quest.Visible end)
                if autoQuest and not hasQuest then fireRemote("StartQuest", qData.Quest, 1) task.wait(0.3) end
                local mob,nil,minD=nil,math.huge
                -- Enemies folder may be in Workspace.Enemies
                local enemies=Workspace:FindFirstChild("Enemies") or Workspace
                for _,v in ipairs(enemies:GetChildren()) do if v.Name:find(mobName) and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health>0 then local d=(root.Position-v.HumanoidRootPart.Position).Magnitude if d<minD then minD=d mob=v end end end
                if mob and mob:FindFirstChild("HumanoidRootPart") then
                    if bringMob and minD<400 then
                        for _,e in ipairs(enemies:GetChildren()) do if e.Name==mob.Name and e~=mob and e:FindFirstChild("HumanoidRootPart") and (e.HumanoidRootPart.Position-mob.HumanoidRootPart.Position).Magnitude<60 then pcall(function() e.HumanoidRootPart.CFrame=mob.HumanoidRootPart.CFrame e.Humanoid.WalkSpeed=0 end) end end
                        pcall(function() mob.HumanoidRootPart.Size=Vector3.new(60,60,60) mob.HumanoidRootPart.CanCollide=false end)
                    end
                    if minD>70 then tweenTo(mob.HumanoidRootPart.Position+Vector3.new(0,10,8), farmSpeed) else root.CFrame=mob.HumanoidRootPart.CFrame*CFrame.new(0,10,8) if fastAttack then VirtualUser:CaptureController() VirtualUser:ClickButton1(Vector2.new(0,0)) end end
                    status.Text="Farming: "..mob.Name.." ["..math.floor(mob.Humanoid.Health).."]"
                else tweenTo(qData.Pos, farmSpeed) status.Text="Going to quest: "..mobName end
            elseif farmMode=="Chest" then
                local chest,md=nil,math.huge
                for _,v in ipairs(Workspace:GetDescendants()) do if v.Name:find("Chest") and v:IsA("BasePart") then local d=(root.Position-v.Position).Magnitude if d<md then md=d chest=v end end end
                if chest then if md>22 then tweenTo(chest.Position, farmSpeed) else root.CFrame=chest.CFrame end status.Text="Chest farm" end
            end
        end)
    end
end)

-- FRUIT ESP
task.spawn(function()
    while task.wait(0.7) do
        if not espFruit then continue end
        for _,v in ipairs(Workspace:GetChildren()) do
            if v:IsA("Tool") and v:FindFirstChild("Handle") and not fruitFolder:FindFirstChild(v.Name..v:GetDebugId()) then
                local bb=Instance.new("BillboardGui", fruitFolder) bb.Name=v.Name..v:GetDebugId() bb.Adornee=v.Handle bb.Size=UDim2.fromOffset(160,40) bb.AlwaysOnTop=true bb.StudsOffset=Vector3.new(0,2,0)
                local tl=Instance.new("TextLabel", bb) tl.Size=UDim2.fromScale(1,1) tl.BackgroundTransparency=1 tl.Text=v.Name tl.TextColor3=Color3.fromRGB(168,123,255) tl.Font=Enum.Font.GothamBold tl.TextSize=13 tl.TextStrokeTransparency=0.4
            end
        end
    end
end)

notify("MoonHub Xeno Lite loaded - LeftCtrl hide")
