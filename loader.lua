-- Pastikan ini dijalankan sebagai LocalScript via executor

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local DataStoreService = game:GetService("DataStoreService")
local ws = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local playerGui = player:WaitForChild("PlayerGui")

-- --- Buat GUI kecil dan draggable ---
local gui = Instance.new("ScreenGui")
gui.Name = "AutoWaypointGUI"
gui.Parent = playerGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 280)
frame.Position = UDim2.new(0.5, -110, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 2
frame.Name = "MainFrame"

local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 30, 0, 20)
minimizeBtn.Position = UDim2.new(1, -60, 0, 0)
minimizeBtn.Text = "_"

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 30, 0, 20)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.Text = "X"

local contentFrame = Instance.new("Frame", frame)
contentFrame.Size = UDim2.new(1, 0, 1, -20)
contentFrame.Position = UDim2.new(0, 0, 0, 20)
contentFrame.BackgroundTransparency = 1

local waypointList = Instance.new("ScrollingFrame", contentFrame)
waypointList.Size = UDim2.new(1, 0, 1, 0)
waypointList.Position = UDim2.new(0, 0, 0, 0)
waypointList.CanvasSize = UDim2.new(0, 0, 0, 0)
waypointList.ScrollBarThickness = 6

local waypointButtons = {}
local waypointNames = {}
local waypointPos = {} -- menyimpan posisi waypoint

local function createWaypointButton(name)
    local btn = Instance.new("TextButton", waypointList)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, (#waypointButtons)*35)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    table.insert(waypointButtons, btn)
    waypointList.CanvasSize = UDim2.new(0, 0, 0, (#waypointButtons)*35)
    return btn
end

-- Load waypoints dari server (gunakan DataStore jika perlu, di sini kita pakai local)
local function loadWaypoints()
    -- Kalau mau pakai DataStore, bisa diaktifkan di sini
    -- tapi untuk executor biasanya pakai variabel lokal
    -- contoh: load dari file lokal, tapi di executor nggak bisa
    -- jadi kita simpan di variabel global
end

local function saveWaypoints()
    -- Kalau mau pakai DataStore, bisa di sini
end

-- Untuk keperluan executor, kita simpan di variabel global
local waypoints = {} -- {nama = posisi CFrame}

local function addWaypoint(name)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        waypoints[name] = hrp.CFrame
        if not table.find(waypointNames, name) then
            table.insert(waypointNames, name)
            createWaypointButton(name)
        end
    end
end

local function gotoWaypoint(name)
    if waypoints[name] then
        -- langsung set posisi player
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = waypoints[name]
        end
    end
end

local function deleteWaypoint(name)
    waypoints[name] = nil
    -- hapus dari GUI
    for i, btn in pairs(waypointButtons) do
        if btn.Text == name then
            btn:Destroy()
            table.remove(waypointButtons, i)
            break
        end
    end
end

-- GUI Control
local inputBox = Instance.new("TextBox", frame)
inputBox.Size = UDim2.new(1, -10, 0, 20)
inputBox.Position = UDim2.new(0, 5, 1, -50)
inputBox.PlaceholderText = "Waypoint name"

local btnSet = Instance.new("TextButton", frame)
btnSet.Size = UDim2.new(0.33, -10, 0, 20)
btnSet.Position = UDim2.new(0, 5, 1, -25)
btnSet.Text = "Set WP"

local btnGoto = Instance.new("TextButton", frame)
btnGoto.Size = UDim2.new(0.33, -10, 0, 20)
btnGoto.Position = UDim2.new(0.33, 0, 1, -25)
btnGoto.Text = "Goto WP"

local btnDel = Instance.new("TextButton", frame)
btnDel.Size = UDim2.new(0.33, -10, 0, 20)
btnDel.Position = UDim2.new(0.66, 0, 1, -25)
btnDel.Text = "Del WP"

-- Button actions
btnSet.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    addWaypoint(name)
end)

btnGoto.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    gotoWaypoint(name)
end)

btnDel.MouseButton1Click:Connect(function()
    local name = inputBox.Text
    deleteWaypoint(name)
end)

-- Minim, Close
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    contentFrame.Visible = not minimized
    minimizeBtn.Text = minimized and "+" or "_"
end)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Drag GUI
local dragging = false
local dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)
frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Loop mengikuti waypoint otomatis
local follow = false
local targetCFrame
local followConnection
local function startFollow()
    follow = true
    followConnection = RunService.Heartbeat:Connect(function()
        if targetCFrame then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = targetCFrame
            end
        end
    end)
end

local function stopFollow()
    if followConnection then
        followConnection:Disconnect()
        followConnection = nil
    end
    follow = false
end

local btnFollow = Instance.new("TextButton", frame)
btnFollow.Size = UDim2.new(1, -10, 0, 20)
btnFollow.Position = UDim2.new(0, 5, 1, -125)
btnFollow.Text = "Follow Waypoint"
btnFollow.MouseButton1Click:Connect(function()
    if not follow then
        local name = inputBox.Text
        if waypoints[name] then
            targetCFrame = waypoints[name]
            startFollow()
            btnFollow.Text = "Stop Following"
        end
    else
        stopFollow()
        btnFollow.Text = "Follow Waypoint"
    end
end)

-- Jika ingin otomatis mengikuti waypoint tertentu
RunService.Heartbeat:Connect(function()
    if follow and targetCFrame then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = targetCFrame
        end
    end
end)

-- Save dan load (bisa pakai file lokal, misalnya JSON)
local function saveData()
    local json = HttpService:JSONEncode(waypoints)
    -- Simpan ke file lokal jika bisa, atau gunakan DataStore
    -- Di executor, bisa simpan ke file lokal dengan writefile
    -- Tapi di Roblox biasa nggak bisa, jadi ini contoh
    -- writefile("waypoints.json", json)
end

local function loadData()
    -- local json = readfile("waypoints.json")
    -- if json then
    --     waypoints = HttpService:JSONDecode(json)
    --     for name, cframe in pairs(waypoints) do
    --         createWaypointButton(name)
    --     end
    -- end
end

-- Sebelum keluar, save data
game:BindToClose(function()
    saveData()
end)

-- Fitur Fly dan Noclip
local flyActive = false
local noclipActive = false
local flySpeed = 50
local flyDirection = Vector3.new(0,0,0)

local function toggleFly()
    flyActive = not flyActive
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.Anchored = false
    end
end

local function toggleNoclip()
    noclipActive = not noclipActive
    for _, part in pairs(player.Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not noclipActive
        end
    end
end

local function setFlySpeed(val)
    flySpeed = tonumber(val) or 50
end

local function setJumpPower(val)
    local hr = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hr then
        hr.JumpPower = tonumber(val) or 50
    end
end

-- Keyboard controls (WASD, Space, Ctrl)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.W then
        flyDirection = flyDirection + Vector3.new(0,0,-1)
    elseif input.KeyCode == Enum.KeyCode.S then
        flyDirection = flyDirection + Vector3.new(0,0,1)
    elseif input.KeyCode == Enum.KeyCode.A then
        flyDirection = flyDirection + Vector3.new(-1,0,0)
    elseif input.KeyCode == Enum.KeyCode.D then
        flyDirection = flyDirection + Vector3.new(1,0,0)
    elseif input.KeyCode == Enum.KeyCode.Space then
        flyDirection = flyDirection + Vector3.new(0,1,0)
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        flyDirection = flyDirection + Vector3.new(0,-1,0)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then
        flyDirection = flyDirection - Vector3.new(0,0,-1)
    elseif input.KeyCode == Enum.KeyCode.S then
        flyDirection = flyDirection - Vector3.new(0,0,1)
    elseif input.KeyCode == Enum.KeyCode.A then
        flyDirection = flyDirection - Vector3.new(-1,0,0)
    elseif input.KeyCode == Enum.KeyCode.D then
        flyDirection = flyDirection - Vector3.new(1,0,0)
    elseif input.KeyCode == Enum.KeyCode.Space then
        flyDirection = flyDirection - Vector3.new(0,1,0)
    elseif input.KeyCode == Enum.KeyCode.LeftControl then
        flyDirection = flyDirection - Vector3.new(0,-1,0)
    end
end)

RunService.Heartbeat:Connect(function()
    -- Fly control
    if flyActive then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame * CFrame.new(flyDirection * (flySpeed/60))
        end
    end
    -- Noclip
    if noclipActive then
        for _, part in pairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Anti AFK
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- Toggle fly dan noclip dari GUI
local btnFly = Instance.new("TextButton", frame)
btnFly.Size = UDim2.new(0.5, -10, 0, 20)
btnFly.Position = UDim2.new(0, 5, 1, -150)
btnFly.Text = "Fly: OFF"
btnFly.MouseButton1Click: function()
    toggleFly()
    btnFly.Text = "Fly: " .. (flyActive and "ON" or "OFF")
end

local btnNoclip = Instance.new("TextButton", frame)
btnNoclip.Size = UDim2.new(0.5, -10, 0, 20)
btnNoclip.Position = UDim2.new(0.5, 0, 1, -150)
btnNoclip.Text = "Noclip: OFF"
btnNoclip.MouseButton1Click: function()
    toggleNoclip()
    btnNoclip.Text = "Noclip: " .. (noclipActive and "ON" or "OFF")
end)

local speedBox = Instance.new("TextBox", frame)
speedBox.Size = UDim2.new(0.5, -10, 0, 20)
speedBox.Position = UDim2.new(0, 5, 1, -180)
speedBox.PlaceholderText = "Speed (10-100)"
speedBox.Text = "50"
speedBox.FocusLost:Connect(function()
    setFlySpeed(speedBox.Text)
end)

local jumpBox = Instance.new("TextBox", frame)
jumpBox.Size = UDim2.new(0.5, -10, 0, 20)
jumpBox.Position = UDim2.new(0.5, 0, 1, -180)
jumpBox.PlaceholderText = "Jump Power (1-150)"
jumpBox.Text = "50"
jumpBox.FocusLost:Connect(function()
    setJumpPower(jumpBox.Text)
end)

-- Tombol follow waypoint
local btnFollow = Instance.new("TextButton", frame)
btnFollow.Size = UDim2.new(1, -10, 0, 20)
btnFollow.Position = UDim2.new(0, 5, 1, -210)
btnFollow.Text = "Follow Waypoint"
local following = false
local followTargetCFrame = nil
local followConn
btnFollow.MouseButton1Click:Connect(function()
    if not following then
        local name = inputBox.Text
        if waypoints[name] then
            followTargetCFrame = waypoints[name]
            following = true
            if followConn then followConn:Disconnect() end
            followConn = RunService.Heartbeat:Connect(function()
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = followTargetCFrame
                end
            end)
            btnFollow.Text = "Stop Follow"
        end
    else
        if followConn then followConn:Disconnect() end
        following = false
        btnFollow.Text = "Follow Waypoint"
    end
end)

-- Simpan data saat keluar
game:BindToClose(function()
    -- Save waypoints ke DataStore jika perlu
end)