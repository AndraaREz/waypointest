-- Roblox Waypoint System with GUI
-- Save this as a .lua file and load it via executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Variables
local waypoints = {}
local currentWaypointSlot = 1
local flying = false
local noclipping = false
local looping = false
local loopConnection
local antiAfkEnabled = false
local infJumpEnabled = false

-- Get game ID for separate waypoint storage
local gameId = tostring(game.PlaceId)

-- Load saved waypoints
local function loadWaypoints()
    local success, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile("waypoints_"..gameId.."_slot"..currentWaypointSlot..".json"))
    end)
    if success then
        waypoints = data
    end
end

-- Save waypoints
local function saveWaypoints()
    pcall(function()
        writefile("waypoints_"..gameId.."_slot"..currentWaypointSlot..".json", game:GetService("HttpService"):JSONEncode(waypoints))
    end)
end

-- Load initial waypoints
pcall(loadWaypoints)

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WaypointGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Waypoint System"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TopBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar

-- Tab Buttons Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 35)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

-- Waypoint Tab Button
local WaypointTab = Instance.new("TextButton")
WaypointTab.Name = "WaypointTab"
WaypointTab.Size = UDim2.new(0.5, -2, 1, 0)
WaypointTab.Position = UDim2.new(0, 0, 0, 0)
WaypointTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
WaypointTab.BorderSizePixel = 0
WaypointTab.Text = "Waypoints"
WaypointTab.TextColor3 = Color3.fromRGB(255, 255, 255)
WaypointTab.TextSize = 14
WaypointTab.Font = Enum.Font.GothamBold
WaypointTab.Parent = TabContainer

-- Misc Tab Button
local MiscTab = Instance.new("TextButton")
MiscTab.Name = "MiscTab"
MiscTab.Size = UDim2.new(0.5, -2, 1, 0)
MiscTab.Position = UDim2.new(0.5, 2, 0, 0)
MiscTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MiscTab.BorderSizePixel = 0
MiscTab.Text = "Misc"
MiscTab.TextColor3 = Color3.fromRGB(255, 255, 255)
MiscTab.TextSize = 14
MiscTab.Font = Enum.Font.GothamBold
MiscTab.Parent = TabContainer

-- Content Frame (Waypoint)
local WaypointContent = Instance.new("Frame")
WaypointContent.Name = "WaypointContent"
WaypointContent.Size = UDim2.new(1, 0, 1, -70)
WaypointContent.Position = UDim2.new(0, 0, 0, 70)
WaypointContent.BackgroundTransparency = 1
WaypointContent.Visible = true
WaypointContent.Parent = MainFrame

-- Content Frame (Misc)
local MiscContent = Instance.new("Frame")
MiscContent.Name = "MiscContent"
MiscContent.Size = UDim2.new(1, 0, 1, -70)
MiscContent.Position = UDim2.new(0, 0, 0, 70)
MiscContent.BackgroundTransparency = 1
MiscContent.Visible = false
MiscContent.Parent = MainFrame

-- Waypoint Slot Selector
local SlotLabel = Instance.new("TextLabel")
SlotLabel.Size = UDim2.new(0, 100, 0, 25)
SlotLabel.Position = UDim2.new(0, 10, 0, 5)
SlotLabel.BackgroundTransparency = 1
SlotLabel.Text = "Slot:"
SlotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SlotLabel.TextSize = 12
SlotLabel.Font = Enum.Font.Gotham
SlotLabel.TextXAlignment = Enum.TextXAlignment.Left
SlotLabel.Parent = WaypointContent

local SlotDropdown = Instance.new("TextButton")
SlotDropdown.Size = UDim2.new(0, 80, 0, 25)
SlotDropdown.Position = UDim2.new(0, 50, 0, 5)
SlotDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SlotDropdown.BorderSizePixel = 0
SlotDropdown.Text = "Slot "..currentWaypointSlot
SlotDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
SlotDropdown.TextSize = 12
SlotDropdown.Font = Enum.Font.Gotham
SlotDropdown.Parent = WaypointContent

-- Waypoint Name Input
local NameInput = Instance.new("TextBox")
NameInput.Name = "NameInput"
NameInput.Size = UDim2.new(1, -20, 0, 30)
NameInput.Position = UDim2.new(0, 10, 0, 35)
NameInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NameInput.BorderSizePixel = 0
NameInput.PlaceholderText = "Waypoint Name"
NameInput.Text = ""
NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
NameInput.TextSize = 12
NameInput.Font = Enum.Font.Gotham
NameInput.Parent = WaypointContent

local NameCorner = Instance.new("UICorner")
NameCorner.CornerRadius = UDim.new(0, 4)
NameCorner.Parent = NameInput

-- Set Waypoint Button
local SetBtn = Instance.new("TextButton")
SetBtn.Name = "SetBtn"
SetBtn.Size = UDim2.new(0.32, -5, 0, 30)
SetBtn.Position = UDim2.new(0, 10, 0, 70)
SetBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
SetBtn.BorderSizePixel = 0
SetBtn.Text = "Set"
SetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetBtn.TextSize = 12
SetBtn.Font = Enum.Font.GothamBold
SetBtn.Parent = WaypointContent

local SetCorner = Instance.new("UICorner")
SetCorner.CornerRadius = UDim.new(0, 4)
SetCorner.Parent = SetBtn

-- Goto Button
local GotoBtn = Instance.new("TextButton")
GotoBtn.Name = "GotoBtn"
GotoBtn.Size = UDim2.new(0.32, -5, 0, 30)
GotoBtn.Position = UDim2.new(0.34, 0, 0, 70)
GotoBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
GotoBtn.BorderSizePixel = 0
GotoBtn.Text = "Goto"
GotoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GotoBtn.TextSize = 12
GotoBtn.Font = Enum.Font.GothamBold
GotoBtn.Parent = WaypointContent

local GotoCorner = Instance.new("UICorner")
GotoCorner.CornerRadius = UDim.new(0, 4)
GotoCorner.Parent = GotoBtn

-- Delete Button
local DeleteBtn = Instance.new("TextButton")
DeleteBtn.Name = "DeleteBtn"
DeleteBtn.Size = UDim2.new(0.32, -5, 0, 30)
DeleteBtn.Position = UDim2.new(0.68, 0, 0, 70)
DeleteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
DeleteBtn.BorderSizePixel = 0
DeleteBtn.Text = "Delete"
DeleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteBtn.TextSize = 12
DeleteBtn.Font = Enum.Font.GothamBold
DeleteBtn.Parent = WaypointContent

local DeleteCorner = Instance.new("UICorner")
DeleteCorner.CornerRadius = UDim.new(0, 4)
DeleteCorner.Parent = DeleteBtn

-- Loop Waypoint Toggle
local LoopLabel = Instance.new("TextLabel")
LoopLabel.Size = UDim2.new(0, 100, 0, 25)
LoopLabel.Position = UDim2.new(0, 10, 0, 110)
LoopLabel.BackgroundTransparency = 1
LoopLabel.Text = "Loop (10s delay):"
LoopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopLabel.TextSize = 11
LoopLabel.Font = Enum.Font.Gotham
LoopLabel.TextXAlignment = Enum.TextXAlignment.Left
LoopLabel.Parent = WaypointContent

local LoopToggle = Instance.new("TextButton")
LoopToggle.Size = UDim2.new(0, 60, 0, 25)
LoopToggle.Position = UDim2.new(0, 130, 0, 110)
LoopToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
LoopToggle.BorderSizePixel = 0
LoopToggle.Text = "OFF"
LoopToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopToggle.TextSize = 11
LoopToggle.Font = Enum.Font.GothamBold
LoopToggle.Parent = WaypointContent

-- Waypoint List ScrollFrame
local WaypointList = Instance.new("ScrollingFrame")
WaypointList.Name = "WaypointList"
WaypointList.Size = UDim2.new(1, -20, 1, -150)
WaypointList.Position = UDim2.new(0, 10, 0, 140)
WaypointList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
WaypointList.BorderSizePixel = 0
WaypointList.ScrollBarThickness = 4
WaypointList.Parent = WaypointContent

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 4)
ListCorner.Parent = WaypointList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 5)
ListLayout.Parent = WaypointList

-- MISC CONTENT
local yPos = 10

-- Speed Control
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 80, 0, 25)
SpeedLabel.Position = UDim2.new(0, 10, 0, yPos)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed (1-100):"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 11
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = MiscContent

local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0, 80, 0, 25)
SpeedInput.Position = UDim2.new(0, 110, 0, yPos)
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedInput.BorderSizePixel = 0
SpeedInput.Text = "16"
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.TextSize = 11
SpeedInput.Font = Enum.Font.Gotham
SpeedInput.Parent = MiscContent

local SpeedApply = Instance.new("TextButton")
SpeedApply.Size = UDim2.new(0, 60, 0, 25)
SpeedApply.Position = UDim2.new(0, 200, 0, yPos)
SpeedApply.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
SpeedApply.BorderSizePixel = 0
SpeedApply.Text = "Apply"
SpeedApply.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedApply.TextSize = 11
SpeedApply.Font = Enum.Font.GothamBold
SpeedApply.Parent = MiscContent

yPos = yPos + 35

-- Jump Power Control
local JumpLabel = Instance.new("TextLabel")
JumpLabel.Size = UDim2.new(0, 100, 0, 25)
JumpLabel.Position = UDim2.new(0, 10, 0, yPos)
JumpLabel.BackgroundTransparency = 1
JumpLabel.Text = "Jump (1-150):"
JumpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpLabel.TextSize = 11
JumpLabel.Font = Enum.Font.Gotham
JumpLabel.TextXAlignment = Enum.TextXAlignment.Left
JumpLabel.Parent = MiscContent

local JumpInput = Instance.new("TextBox")
JumpInput.Size = UDim2.new(0, 80, 0, 25)
JumpInput.Position = UDim2.new(0, 110, 0, yPos)
JumpInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
JumpInput.BorderSizePixel = 0
JumpInput.Text = "50"
JumpInput.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpInput.TextSize = 11
JumpInput.Font = Enum.Font.Gotham
JumpInput.Parent = MiscContent

local JumpApply = Instance.new("TextButton")
JumpApply.Size = UDim2.new(0, 60, 0, 25)
JumpApply.Position = UDim2.new(0, 200, 0, yPos)
JumpApply.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
JumpApply.BorderSizePixel = 0
JumpApply.Text = "Apply"
JumpApply.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpApply.TextSize = 11
JumpApply.Font = Enum.Font.GothamBold
JumpApply.Parent = MiscContent

yPos = yPos + 35

-- Toggle Buttons
local function createToggle(name, pos)
    local toggle = Instance.new("TextButton")
    toggle.Name = name.."Toggle"
    toggle.Size = UDim2.new(0.48, -5, 0, 30)
    toggle.Position = pos
    toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = name.." OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextSize = 11
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = MiscContent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = toggle
    
    return toggle
end

local FlyToggle = createToggle("Fly", UDim2.new(0, 10, 0, yPos))
local NoclipToggle = createToggle("Noclip", UDim2.new(0.52, 0, 0, yPos))
yPos = yPos + 40
local InfJumpToggle = createToggle("Inf Jump", UDim2.new(0, 10, 0, yPos))
local AntiAFKToggle = createToggle("Anti AFK", UDim2.new(0.52, 0, 0, yPos))

-- Functions
local function updateWaypointList()
    for _, child in pairs(WaypointList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local index = 0
    for name, pos in pairs(waypoints) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, index * 35)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.BorderSizePixel = 0
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.Parent = WaypointList
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            NameInput.Text = name
        end)
        
        index = index + 1
    end
    
    WaypointList.CanvasSize = UDim2.new(0, 0, 0, index * 35)
end

-- Set Waypoint
SetBtn.MouseButton1Click:Connect(function()
    local name = NameInput.Text
    if name ~= "" then
        waypoints[name] = rootPart.CFrame.Position
        saveWaypoints()
        updateWaypointList()
        NameInput.Text = ""
    end
end)

-- Goto Waypoint
GotoBtn.MouseButton1Click:Connect(function()
    local name = NameInput.Text
    if waypoints[name] then
        rootPart.CFrame = CFrame.new(waypoints[name])
    end
end)

-- Delete Waypoint
DeleteBtn.MouseButton1Click:Connect(function()
    local name = NameInput.Text
    if waypoints[name] then
        waypoints[name] = nil
        saveWaypoints()
        updateWaypointList()
        NameInput.Text = ""
    end
end)

-- Loop Waypoint
LoopToggle.MouseButton1Click:Connect(function()
    looping = not looping
    if looping then
        LoopToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        LoopToggle.Text = "ON"
        
        task.spawn(function()
            while looping do
                for name, pos in pairs(waypoints) do
                    if not looping then break end
                    rootPart.CFrame = CFrame.new(pos)
                    wait(10)
                end
            end
        end)
    else
        LoopToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        LoopToggle.Text = "OFF"
    end
end)

-- Slot Dropdown
SlotDropdown.MouseButton1Click:Connect(function()
    currentWaypointSlot = currentWaypointSlot % 10 + 1
    SlotDropdown.Text = "Slot "..currentWaypointSlot
    loadWaypoints()
    updateWaypointList()
end)

-- Speed Apply
SpeedApply.MouseButton1Click:Connect(function()
    local speed = tonumber(SpeedInput.Text)
    if speed and speed >= 1 and speed <= 100 then
        humanoid.WalkSpeed = speed
    end
end)

-- Jump Apply
JumpApply.MouseButton1Click:Connect(function()
    local jump = tonumber(JumpInput.Text)
    if jump and jump >= 1 and jump <= 150 then
        humanoid.JumpPower = jump
    end
end)

-- Fly Toggle
local flySpeed = 50
local flyConnection
FlyToggle.MouseButton1Click:Connect(function()
    flying = not flying
    if flying then
        FlyToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        FlyToggle.Text = "Fly ON"
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.Parent = rootPart
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.Parent = rootPart
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not flying then return end
            
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.new()
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDir = moveDir + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDir = moveDir - Vector3.new(0, 1, 0)
            end
            
            -- Mobile support (Thumbstick)
            local moveVector = humanoid.MoveVector
            if moveVector.Magnitude > 0 then
                moveDir = moveDir + (cam.CFrame.LookVector * moveVector.Z)
                moveDir = moveDir + (cam.CFrame.RightVector * moveVector.X)
            end
            
            bodyVel.Velocity = moveDir.Unit * flySpeed
            bodyGyro.CFrame = cam.CFrame
        end)
    else
        FlyToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        FlyToggle.Text = "Fly OFF"
        if flyConnection then flyConnection:Disconnect() end
        for _, v in pairs(rootPart:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
                v:Destroy()
            end
        end
    end
end)

-- Noclip Toggle
local noclipConnection
NoclipToggle.MouseButton1Click:Connect(function()
    noclipping = not noclipping
    if noclipping then
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        NoclipToggle.Text = "Noclip ON"
        
        noclipConnection = RunService.Stepped:Connect(function()
            if not noclipping then return end
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        NoclipToggle.Text = "Noclip OFF"
        if noclipConnection then noclipConnection:Disconnect() end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end)

-- Infinite Jump
InfJumpToggle.MouseButton1Click:Connect(function()
    infJumpEnabled = not infJumpEnabled
    if infJumpEnabled then
        InfJumpToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        InfJumpToggle.Text = "Inf Jump ON"
    else
        InfJumpToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        InfJumpToggle.Text = "Inf Jump OFF"
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Anti AFK
local antiAfkConnection
AntiAFKToggle.MouseButton1Click:Connect(function()
    antiAfkEnabled = not antiAfkEnabled
    if antiAfkEnabled then
        AntiAFKToggle.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        AntiAFKToggle.Text = "Anti AFK ON"
        
        local vu = game:GetService("VirtualUser")
        antiAfkConnection = player.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    else
        AntiAFKToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        AntiAFKToggle.Text = "Anti AFK OFF"
        if antiAfkConnection then antiAfkConnection:Disconnect() end
    end
end)

-- Tab Switching
WaypointTab.MouseButton1Click:Connect(function()
    WaypointContent.Visible = true
    MiscContent.Visible = false
    WaypointTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    MiscTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
end)

MiscTab.MouseButton1Click:Connect(function()
    WaypointContent.Visible = false
    MiscContent.Visible = true
    WaypointTab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MiscTab.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
end)

-- Minimize Toggle
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
        MinimizeBtn.Text = "+"
        TabContainer.Visible = false
        WaypointContent.Visible = false
        MiscContent.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 320, 0, 400), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
        MinimizeBtn.Text = "-"
        TabContainer.Visible = true
        if WaypointTab.BackgroundColor3 == Color3.fromRGB(60, 120, 200) then
            WaypointContent.Visible = true
        else
            MiscContent.Visible = true
        end
    end
end)

-- Close Button
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    if flyConnection then flyConnection:Disconnect() end
    if noclipConnection then noclipConnection:Disconnect() end
    if antiAfkConnection then antiAfkConnection:Disconnect() end
    looping = false
    flying = false
    noclipping = false
end)

-- Character Respawn Handler
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    -- Reapply settings
    local speed = tonumber(SpeedInput.Text)
    if speed and speed >= 1 and speed <= 100 then
        humanoid.WalkSpeed = speed
    end
    
    local jump = tonumber(JumpInput.Text)
    if jump and jump >= 1 and jump <= 150 then
        humanoid.JumpPower = jump
    end
    
    -- Reconnect infinite jump
    UserInputService.JumpRequest:Connect(function()
        if infJumpEnabled then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end)

-- Initialize
updateWaypointList()

print("✅ Waypoint System Loaded Successfully!")
print("📍 Features: Set/Goto/Delete Waypoints, Fly, Noclip, Speed, Jump, Inf Jump, Anti AFK, Loop")
print("🎮 10 Separate Waypoint Slots Available")
print("💾 Auto-save enabled per game")