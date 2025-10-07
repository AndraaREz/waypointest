-- // Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- // Local Player
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- // GUI Setup
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "WaypointGUI"
MainGui.ResetOnSpawn = false
MainGui.Parent = StarterGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 300)
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = MainGui
MainFrame.Draggable = true

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
MinimizeButton.Position = UDim2.new(0.9, 0, 0, 0)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Parent = MainFrame
MinimizeButton.MouseButton1Click:Connect(function()
    MainFrame.Size = UDim2.new(0, 200, 0, 20)
end)

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(0.8, 0, 0, 0)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Parent = MainFrame
CloseButton.MouseButton1Click:Connect(function()
    MainGui:Destroy()
end)

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1, 0, 0, 30)
Tabs.Position = UDim2.new(0, 0, 0, 20)
Tabs.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Tabs.BorderSizePixel = 0
Tabs.Parent = MainFrame

local WaypointTabButton = Instance.new("TextButton")
WaypointTabButton.Size = UDim2.new(0.5, 0, 1, 0)
WaypointTabButton.Position = UDim2.new(0, 0, 0, 0)
WaypointTabButton.Text = "Waypoint"
WaypointTabButton.TextColor3 = Color3.new(1, 1, 1)
WaypointTabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
WaypointTabButton.BorderSizePixel = 0
WaypointTabButton.Parent = Tabs

local MiscTabButton = Instance.new("TextButton")
MiscTabButton.Size = UDim2.new(0.5, 0, 1, 0)
MiscTabButton.Position = UDim2.new(0.5, 0, 0, 0)
MiscTabButton.Text = "Misc"
MiscTabButton.TextColor3 = Color3.new(1, 1, 1)
MiscTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MiscTabButton.BorderSizePixel = 0
MiscTabButton.Parent = Tabs

local WaypointFrame = Instance.new("Frame")
WaypointFrame.Size = UDim2.new(1, 0, 0.8, 0)
WaypointFrame.Position = UDim2.new(0, 0, 0, 50)
WaypointFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
WaypointFrame.BorderSizePixel = 0
WaypointFrame.Parent = MainFrame
WaypointFrame.Visible = true

local MiscFrame = Instance.new("Frame")
MiscFrame.Size = UDim2.new(1, 0, 0.8, 0)
MiscFrame.Position = UDim2.new(0, 0, 0, 50)
MiscFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MiscFrame.BorderSizePixel = 0
MiscFrame.Parent = MainFrame
MiscFrame.Visible = false

WaypointTabButton.MouseButton1Click:Connect(function()
    WaypointFrame.Visible = true
    MiscFrame.Visible = false
    WaypointTabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    MiscTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    MainFrame.Size = UDim2.new(0, 200, 0, 300)
end)

MiscTabButton.MouseButton1Click:Connect(function()
    WaypointFrame.Visible = false
    MiscFrame.Visible = true
    MiscTabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    WaypointTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    MainFrame.Size = UDim2.new(0, 200, 0, 300)
end)

-- // Waypoint Variables
local waypoints = {}
local currentGameId = game.PlaceId
local saveKey = "Waypoints_" .. currentGameId
local selectedWaypoint = nil
local looping = false

-- // Waypoint Functions
local function saveWaypoints()
    local data = {}
    for name, pos in pairs(waypoints) do
        data[name] = {pos.X, pos.Y, pos.Z}
    end
    local success, err = pcall(function()
        StarterGui:SetCore("LocalStorage", {
            [saveKey] = data
        })
    end)
    if not success then
        warn("Failed to save waypoints: " .. err)
    end
end

local function loadWaypoints()
    local data = StarterGui:GetCore("LocalStorage")[saveKey]
    if data then
        for name, posData in pairs(data) do
            if type(posData) == "table" and #posData == 3 then
                local pos = Vector3.new(posData[1], posData[2], posData[3])
                waypoints[name] = pos
                updateWaypointList()
            end
        end
    end
end

local function setWaypoint(name)
    waypoints[name] = RootPart.Position
    saveWaypoints()
    updateWaypointList()
end

local function goToWaypoint(name)
    if waypoints[name] then
        local targetPosition = waypoints[name]
        local tweenInfo = TweenInfo.new(
            (RootPart.Position - targetPosition).Magnitude / Humanoid.WalkSpeed,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.Out,
            0,
            false,
            0
        )
        local tween = TweenService:Create(RootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
        tween:Play()
    else
        warn("Waypoint '" .. name .. "' not found.")
    end
end

local function deleteWaypoint(name)
    waypoints[name] = nil
    saveWaypoints()
    updateWaypointList()
end

-- // Waypoint GUI Elements
local SetWaypointButton = Instance.new("TextButton")
SetWaypointButton.Size = UDim2.new(0.9, 0, 0, 25)
SetWaypointButton.Position = UDim2.new(0.05, 0, 0.1, 0)
SetWaypointButton.Text = "Set Waypoint"
SetWaypointButton.TextColor3 = Color3.new(1, 1, 1)
SetWaypointButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SetWaypointButton.BorderSizePixel = 0
SetWaypointButton.Parent = WaypointFrame
SetWaypointButton.MouseButton1Click:Connect(function()
    local name = SetWaypointName.Text
    if name ~= "" then
        setWaypoint(name)
        SetWaypointName.Text = ""
    end
end)

local SetWaypointName = Instance.new("TextBox")
SetWaypointName.Size = UDim2.new(0.9, 0, 0, 25)
SetWaypointName.Position = UDim2.new(0.05, 0, 0.05, 0)
SetWaypointName.PlaceholderText = "Waypoint Name"
SetWaypointName.TextColor3 = Color3.new(1, 1, 1)
SetWaypointName.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SetWaypointName.BorderSizePixel = 0
SetWaypointName.Parent = WaypointFrame

local GoToWaypointButton = Instance.new("TextButton")
GoToWaypointButton.Size = UDim2.new(0.44, 0, 0, 25)
GoToWaypointButton.Position = UDim2.new(0.05, 0, 0.2, 0)
GoToWaypointButton.Text = "Go To"
GoToWaypointButton.TextColor3 = Color3.new(1, 1, 1)
GoToWaypointButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
GoToWaypointButton.BorderSizePixel = 0
GoToWaypointButton.Parent = WaypointFrame
GoToWaypointButton.MouseButton1Click:Connect(function()
    if selectedWaypoint then
        goToWaypoint(selectedWaypoint)
    end
end)

local DeleteWaypointButton = Instance.new("TextButton")
DeleteWaypointButton.Size = UDim2.new(0.44, 0, 0, 25)
DeleteWaypointButton.Position = UDim2.new(0.51, 0, 0.2, 0)
DeleteWaypointButton.Text = "Delete"
DeleteWaypointButton.TextColor3 = Color3.new(1, 1, 1)
DeleteWaypointButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
DeleteWaypointButton.BorderSizePixel = 0
DeleteWaypointButton.Parent = WaypointFrame
DeleteWaypointButton.MouseButton1Click:Connect(function()
    if selectedWaypoint then
        deleteWaypoint(selectedWaypoint)
        selectedWaypoint = nil
    end
end)

local WaypointList = Instance.new("ScrollingFrame")
WaypointList.Size = UDim2.new(0.9, 0, 0.5, 0)
WaypointList.Position = UDim2.new(0.05, 0, 0.3, 0)
WaypointList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
WaypointList.BorderSizePixel = 0
WaypointList.ScrollBarThickness = 5
WaypointList.Parent = WaypointFrame

local function updateWaypointList()
    for _, obj in ipairs(WaypointList:GetChildren()) do
        if obj:IsA("TextButton") then
            obj:Destroy()
        end
    end

    local i = 0
    for name, _ in pairs(waypoints) do
        local WaypointButton = Instance.new("TextButton")
        WaypointButton.Size = UDim2.new(1, 0, 0, 20)
        WaypointButton.Position = UDim2.new(0, 0, i * 0.07, 0)
        WaypointButton.Text = name
        WaypointButton.TextColor3 = Color3.new(1, 1, 1)
        WaypointButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        WaypointButton.BorderSizePixel = 0
        WaypointButton.Parent = WaypointList
        WaypointButton.MouseButton1Click:Connect(function()
            selectedWaypoint = name
            for _, btn in ipairs(WaypointList:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                end
            end
            WaypointButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        end)
        i = i + 1
    end
end

-- // Loop Waypoint
local LoopWaypointToggle = Instance.new("TextButton")
LoopWaypointToggle.Size = UDim2.new(0.9, 0, 0, 25)
LoopWaypointToggle.Position = UDim2.new(0.05, 0, 0.85, 0)
LoopWaypointToggle.Text = "Loop Waypoint: Off"
LoopWaypointToggle.TextColor3 = Color3.new(1, 1, 1)
LoopWaypointToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
LoopWaypointToggle.BorderSizePixel = 0
LoopWaypointToggle.Parent = WaypointFrame

local function loopWaypoints()
    if looping then
        looping = false
        LoopWaypointToggle.Text = "Loop Waypoint: Off"
        return
    end

    looping = true
    LoopWaypointToggle.Text = "Loop Waypoint: On"

    local waypointNames = {}
    for name, _ in pairs(waypoints) do
        table.insert(waypointNames, name)
    end

    local currentIndex = 1
    while looping do
        local waypointName = waypointNames[currentIndex]
        if waypointName then
            goToWaypoint(waypointName)
            wait(10) -- Minimal kecepatan 10 detik
            currentIndex = (currentIndex % #waypointNames) + 1
        else
            looping = false
            LoopWaypointToggle.Text = "Loop Waypoint: Off"
        end
    end
end

LoopWaypointToggle.MouseButton1Click:Connect(loopWaypoints)

-- // Misc Tab
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0.45, 0, 0, 20)
SpeedLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
SpeedLabel.Text = "Speed (1-100):"
SpeedLabel.TextColor3 = Color3.new(1, 1, 1)
SpeedLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedLabel.BorderSizePixel = 0
SpeedLabel.Parent = MiscFrame

local SpeedTextBox = Instance.new("TextBox")
SpeedTextBox.Size = UDim2.new(0.45, 0, 0, 20)
SpeedTextBox.Position = UDim2.new(0.5, 0, 0.05, 0)
SpeedTextBox.Text = "16"
SpeedTextBox.TextColor3 = Color3.new(1, 1, 1)
SpeedTextBox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SpeedTextBox.BorderSizePixel = 0
SpeedTextBox.Parent = MiscFrame
SpeedTextBox.FocusLost:Connect(function()
    local speed = tonumber(SpeedTextBox.Text)
    if speed and speed >= 1 and speed <= 100 then
        Humanoid.WalkSpeed = speed
    else
        SpeedTextBox.Text = tostring(Humanoid.WalkSpeed)
    end
end)

local JumpPowerLabel = Instance.new("TextLabel")
JumpPowerLabel.Size = UDim2.new(0.45, 0, 0, 20)
JumpPowerLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
JumpPowerLabel.Text = "Jump Power (1-150):"
JumpPowerLabel.TextColor3 = Color3.new(1, 1, 1)
JumpPowerLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
JumpPowerLabel.BorderSizePixel = 0
JumpPowerLabel.Parent = MiscFrame

local JumpPowerTextBox = Instance.new("TextBox")
JumpPowerTextBox.Size = UDim2.new(0.45, 0, 0, 20)
JumpPowerTextBox.Position = UDim2.new(0.5, 0, 0.15, 0)
JumpPowerTextBox.Text = "50"
JumpPowerTextBox.TextColor3 = Color3.new(1, 1, 1)
JumpPowerTextBox.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
JumpPowerTextBox.BorderSizePixel = 0
JumpPowerTextBox.Parent = MiscFrame
JumpPowerTextBox.FocusLost:Connect(function()
    local jumpPower = tonumber(JumpPowerTextBox.Text)
    if jumpPower and jumpPower >= 1 and jumpPower <= 150 then
        Humanoid.JumpPower = jumpPower
    else
        JumpPowerTextBox.Text = tostring(Humanoid.JumpPower)
    end
end)

-- // Infinite Jump
local InfiniteJumpToggle = Instance.new("TextButton")
InfiniteJumpToggle.Size = UDim2.new(0.9, 0, 0, 25)
InfiniteJumpToggle.Position = UDim2.new(0.05, 0, 0.25, 0)
InfiniteJumpToggle.Text = "Infinite Jump: Off"
InfiniteJumpToggle.TextColor3 = Color3.new(1, 1, 1)
InfiniteJumpToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
InfiniteJumpToggle.BorderSizePixel = 0
InfiniteJumpToggle.Parent = MiscFrame

local infiniteJumpEnabled = false
local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled
    if infiniteJumpEnabled then
        InfiniteJumpToggle.Text = "Infinite Jump: On"
    else
        InfiniteJumpToggle.Text = "Infinite Jump: Off"
    end
end

InfiniteJumpToggle.MouseButton1Click:Connect(toggleInfiniteJump)

Humanoid.Died:Connect(function()
    infiniteJumpEnabled = false
    InfiniteJumpToggle.Text = "Infinite Jump: Off"
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- // Anti AFK
local AntiAFKToggle = Instance.new("TextButton")
AntiAFKToggle.Size = UDim2.new(0.9, 0, 0, 25)
AntiAFKToggle.Position = UDim2.new(0.05, 0, 0.35, 0)
AntiAFKToggle.Text = "Anti AFK: Off"
AntiAFKToggle.TextColor3 = Color3.new(1, 1, 1)
AntiAFKToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AntiAFKToggle.BorderSizePixel = 0
AntiAFKToggle.Parent = MiscFrame

local antiAFKEnabled = false
local antiAFKConnection = nil

local function toggleAntiAFK()
    antiAFKEnabled = not antiAFKEnabled
    if antiAFKEnabled then
        AntiAFKToggle.Text = "Anti AFK: On"
        antiAFKConnection = game:GetService("RunService").Heartbeat:Connect(function()
            Humanoid:MoveTo(RootPart.Position + Vector3.new(0, 0.1, 0))
        end)
    else
        AntiAFKToggle.Text = "Anti AFK: Off"
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
            antiAFKConnection = nil
        end
    end
end

AntiAFKToggle.MouseButton1Click:Connect(toggleAntiAFK)

-- // Fly
local FlyToggle = Instance.new("TextButton")
FlyToggle.Size = UDim2.new(0.9, 0, 0, 25)
FlyToggle.Position = UDim2.new(0.05, 0, 0.45, 0)
FlyToggle.Text = "Fly: Off"
FlyToggle.TextColor3 = Color3.new(1, 1, 1)
FlyToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FlyToggle.BorderSizePixel = 0
FlyToggle.Parent = MiscFrame

local flying = false
local flySpeed = 25
local canCollideOriginal = true

local function toggleFly()
    flying = not flying
    if flying then
        FlyToggle.Text = "Fly: On"
        canCollideOriginal = RootPart.CanCollide
        RootPart.CanCollide = false
        Humanoid.PlatformStand = true
    else
        FlyToggle.Text = "Fly: Off"
        RootPart.CanCollide = canCollideOriginal
        Humanoid.PlatformStand = false
    end
end

FlyToggle.MouseButton1Click:Connect(toggleFly)

game:GetService("RunService").Heartbeat:Connect(function()
    if flying then
        RootPart.Velocity = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 0, -flySpeed * 0.01)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            RootPart.CFrame = RootPart.CFrame * CFrame.new(0, 0, flySpeed * 0.01)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            RootPart.CFrame = RootPart.CFrame * CFrame.new(-flySpeed * 0.01, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            RootPart.CFrame = RootPart.CFrame * CFrame.new(flySpeed * 0.01, 0, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            RootPart.CFrame = RootPart.CFrame * CFrame.new(0, flySpeed * 0.01, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            RootPart.CFrame = RootPart.CFrame * CFrame.new(0, -flySpeed * 0.01, 0)
        end
    end
end)

-- // Noclip
local NoclipToggle = Instance.new("TextButton")
NoclipToggle.Size = UDim2.new(0.9, 0, 0, 25)
NoclipToggle.Position = UDim2.new(0.05, 0, 0.55, 0)
NoclipToggle.Text = "Noclip: Off"
NoclipToggle.TextColor3 = Color3.new(1, 1, 1)
NoclipToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
NoclipToggle.BorderSizePixel = 0
NoclipToggle.Parent = MiscFrame

local noclipEnabled = false

local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if noclipEnabled then
        NoclipToggle.Text = "Noclip: On"
        Character.CollisionGroup = "NoCollision"
    else
        NoclipToggle.Text = "Noclip: Off"
        Character.CollisionGroup = "Default"
    end
end

NoclipToggle.MouseButton1Click:Connect(toggleNoclip)

-- // Collision Groups Setup
local PhysicsService = game:GetService("PhysicsService")
PhysicsService:CreateCollisionGroup("NoCollision")
PhysicsService:CollisionGroupSetCollidable("NoCollision", "Default", false)
PhysicsService:CollisionGroupSetCollidable("NoCollision", "NoCollision", false)

Character:SetAttribute("CollisionGroup", "Default")

Character.Changed:Connect(function(property)
    if property == "Parent" then
        Character = LocalPlayer.Character
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        Character:SetAttribute("CollisionGroup", "Default")
    end
end)

-- // Load Waypoints on Start
loadWaypoints()