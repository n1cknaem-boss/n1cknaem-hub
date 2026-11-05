-- language: Luau, file: IY_Fluent_Hub_vFinal.lua, target: Roblox (Executor), framework: Fluent
-- ==============================================================================
-- N1cknaem's Master Hub (v2.2) - Unbound Default Keybinds & Complete Feature Engine
-- ==============================================================================

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local SaveManagerOk, SaveManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)
local InterfaceManagerOk, InterfaceManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

-- ==============================================================================
-- SERVICES & REFERENCES
-- ==============================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local PlaceId, JobId = game.PlaceId, game.JobId

-- ==============================================================================
-- STATE MANAGER & CACHE REGISTRY
-- ==============================================================================
local HubState = {
    Connections = {},
    PartCollisionCache = {},
    HitboxCache = {},
    ESPObjects = {},
    LightingBackup = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Ambient = Lighting.Ambient,
    },
    DefaultGravity = Workspace.Gravity,
    Configs = {
        WalkSpeed = 16,
        JumpPower = 50,
        Gravity = Workspace.Gravity,
        CameraFOV = 70,
        LockStats = false,
        FlySpeed = 65,
        VerticalFlySpeed = 45,
        SelectedPlayer = nil,
        ESPFillColor = Color3.fromRGB(255, 65, 65),
        ESPOutlineColor = Color3.fromRGB(255, 255, 255),
        ESPFillTransparency = 0.65,
        ESPOutlineTransparency = 0.1,
        ESPUseTeamColor = true,
        ESPTeamCheck = false,
        ESPNameTags = true,
        AimbotFOV = 150,
        AimbotSmoothness = 0.25,
        AimbotTeamCheck = true,
        AimbotWallCheck = true,
        AimbotTargetPart = "Head",
        ShowFOVCircle = false,
        HitboxSize = 8,
        HitboxTransparency = 0.7,
        HitboxTeamCheck = true,
    },
    Enabled = {
        AntiAFK = false,
        Fly = false,
        Noclip = false,
        InfJump = false,
        ClickTP = false,
        Spectate = false,
        ESP = false,
        Aimbot = false,
        HitboxExpander = false,
        Fullbright = false,
        NoFog = false,
    }
}

-- ==============================================================================
-- UTILITY & CONNECTION HELPERS
-- ==============================================================================
local function SafeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        warn("[Hub Engine]: " .. tostring(result))
    end
    return ok, result
end

local function BindConnection(key, signal, callback)
    if HubState.Connections[key] then
        HubState.Connections[key]:Disconnect()
        HubState.Connections[key] = nil
    end
    HubState.Connections[key] = signal:Connect(callback)
    return HubState.Connections[key]
end

local function UnbindConnection(key)
    if HubState.Connections[key] then
        HubState.Connections[key]:Disconnect()
        HubState.Connections[key] = nil
    end
end

local function GetCharacterParts(player)
    player = player or LocalPlayer
    local char = player and player.Character
    if not char then return nil, nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, root, hum
end

local function IsAlive(player)
    local char, root, hum = GetCharacterParts(player)
    return char ~= nil and root ~= nil and hum ~= nil and hum.Health > 0
end

local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    if #names == 0 then
        table.insert(names, "No Other Players")
    end
    return names
end

-- ==============================================================================
-- FLUENT WINDOW & TABS
-- ==============================================================================
local Window = Fluent:CreateWindow({
    Title = "N1cknaem's Master Hub",
    SubTitle = "v2.2 Complete Feature Suite",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 520),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Insert
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "navigation" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "target" }),
    World = Window:AddTab({ Title = "World", Icon = "globe" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ==============================================================================
-- [1] MAIN TAB: CHARACTER MODS & STATS
-- ==============================================================================
local function ApplyCharacterStats()
    local _, _, hum = GetCharacterParts(LocalPlayer)
    if not hum then return end
    hum.WalkSpeed = HubState.Configs.WalkSpeed
    if hum.UseJumpPower then
        hum.JumpPower = HubState.Configs.JumpPower
    else
        hum.JumpHeight = math.clamp(HubState.Configs.JumpPower * 0.144, 7.2, 150)
    end
end

Tabs.Main:AddSection("Character Attributes")

local LockStatsToggle = Tabs.Main:AddToggle("LockStats", {
    Title = "Lock & Persist Stats",
    Description = "Keeps custom WalkSpeed & JumpPower after respawning or game resets",
    Default = false
})
LockStatsToggle:OnChanged(function()
    HubState.Configs.LockStats = Options.LockStats.Value
    if HubState.Configs.LockStats then
        ApplyCharacterStats()
        BindConnection("StatEnforcer", RunService.RenderStepped, function()
            if HubState.Configs.LockStats then
                ApplyCharacterStats()
            end
        end)
    else
        UnbindConnection("StatEnforcer")
    end
end)

local WSSlider = Tabs.Main:AddSlider("WS", {
    Title = "WalkSpeed",
    Description = "Default is 16",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.WalkSpeed = tonumber(v) or 16
        ApplyCharacterStats()
    end
})

local JPSlider = Tabs.Main:AddSlider("JP", {
    Title = "JumpPower",
    Description = "Default is 50",
    Default = 50,
    Min = 50,
    Max = 350,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.JumpPower = tonumber(v) or 50
        ApplyCharacterStats()
    end
})

Tabs.Main:AddSlider("GravitySlider", {
    Title = "World Gravity",
    Description = "Default is 196.2",
    Default = math.floor(Workspace.Gravity),
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.Gravity = tonumber(v) or 196.2
        Workspace.Gravity = HubState.Configs.Gravity
    end
})

Tabs.Main:AddSlider("FOVSlider", {
    Title = "Camera Field of View",
    Description = "Default is 70",
    Default = 70,
    Min = 50,
    Max = 120,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.CameraFOV = tonumber(v) or 70
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = HubState.Configs.CameraFOV
        end
    end
})

Tabs.Main:AddSection("Character Utilities")

local AntiAFKToggle = Tabs.Main:AddToggle("AntiAFK", {
    Title = "Anti-AFK",
    Description = "Prevents 20-minute idle kick",
    Default = true
})
AntiAFKToggle:OnChanged(function()
    HubState.Enabled.AntiAFK = Options.AntiAFK.Value
    if HubState.Enabled.AntiAFK then
        BindConnection("AntiAFK", LocalPlayer.Idled, function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    else
        UnbindConnection("AntiAFK")
    end
end)

Tabs.Main:AddButton({
    Title = "Reset Stats to Default",
    Description = "Restores WalkSpeed (16), JumpPower (50), and Gravity (196.2)",
    Callback = function()
        WSSlider:SetValue(16)
        JPSlider:SetValue(50)
        Workspace.Gravity = HubState.DefaultGravity
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = 70
        end
    end
})

Tabs.Main:AddButton({
    Title = "Instant Respawn / Force Reset",
    Description = "Sets character health to 0 immediately",
    Callback = function()
        local _, _, hum = GetCharacterParts(LocalPlayer)
        if hum then hum.Health = 0 end
    end
})

-- ==============================================================================
-- [2] MOVEMENT TAB: 6-DOF FLIGHT, NOCLIP, INF JUMP & PLAYER TELEPORT
-- ==============================================================================
Tabs.Movement:AddSection("6-DOF Flight Engine")

local FlyBV = Instance.new("BodyVelocity")
FlyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
FlyBV.Velocity = Vector3.zero

local FlyBG = Instance.new("BodyGyro")
FlyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
FlyBG.P = 9e4

local function StopFly()
    FlyBV.Parent = nil
    FlyBG.Parent = nil
    UnbindConnection("FlyLoop")
    local _, _, hum = GetCharacterParts(LocalPlayer)
    if hum then
        hum.PlatformStand = false
    end
end

local function StartFly()
    local _, root, hum = GetCharacterParts(LocalPlayer)
    if not root or not hum then return end

    hum.PlatformStand = true
    FlyBV.Parent = root
    FlyBG.Parent = root

    BindConnection("FlyLoop", RunService.RenderStepped, function()
        if not HubState.Enabled.Fly or not IsAlive(LocalPlayer) then
            return
        end
        local _, currentRoot, currentHum = GetCharacterParts(LocalPlayer)
        if not currentRoot or not currentHum then return end

        if UserInputService:GetFocusedTextBox() then
            FlyBV.Velocity = Vector3.zero
            return
        end

        currentHum.PlatformStand = true
        if FlyBV.Parent ~= currentRoot then FlyBV.Parent = currentRoot end
        if FlyBG.Parent ~= currentRoot then FlyBG.Parent = currentRoot end

        local cam = Workspace.CurrentCamera
        local cf = cam.CFrame
        local moveDir = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cf.RightVector end

        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = vertical + 1 end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            vertical = vertical - 1
        end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * HubState.Configs.FlySpeed
        end

        FlyBG.CFrame = cf
        FlyBV.Velocity = moveDir + Vector3.new(0, vertical * HubState.Configs.VerticalFlySpeed, 0)
    end)
end

local FlyToggle = Tabs.Movement:AddToggle("Fly", {
    Title = "Enable Flight (WASD + Space/Ctrl)",
    Description = "Smooth camera-aligned directional flight",
    Default = false
})
FlyToggle:OnChanged(function()
    HubState.Enabled.Fly = Options.Fly.Value
    if HubState.Enabled.Fly then
        StartFly()
    else
        StopFly()
    end
end)

Tabs.Movement:AddKeybind("FlyBind", {
    Title = "Flight Keybind",
    Mode = "Toggle",
    Default = "None",
    Callback = function()
        if Options.FlyBind and Options.FlyBind.Value == "None" then return end
        if Options.Fly then
            Options.Fly:SetValue(not Options.Fly.Value)
        end
    end
})

Tabs.Movement:AddSlider("FlySpeed", {
    Title = "Horizontal Flight Speed",
    Default = 65,
    Min = 15,
    Max = 300,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.FlySpeed = tonumber(v) or 65
    end
})

Tabs.Movement:AddSlider("VerticalFlySpeed", {
    Title = "Vertical Flight Speed (Space / Ctrl)",
    Default = 45,
    Min = 15,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.VerticalFlySpeed = tonumber(v) or 45
    end
})

Tabs.Movement:AddSection("Collision & Mobility")

local function RestoreCollisions()
    for part, originalState in pairs(HubState.PartCollisionCache) do
        if part and part.Parent then
            part.CanCollide = originalState
        end
    end
    table.clear(HubState.PartCollisionCache)
end

local NoclipToggle = Tabs.Movement:AddToggle("Noclip", {
    Title = "Smart Noclip",
    Description = "Walk through walls and restore exact part collisions when disabled",
    Default = false
})
NoclipToggle:OnChanged(function()
    HubState.Enabled.Noclip = Options.Noclip.Value
    if HubState.Enabled.Noclip then
        BindConnection("Noclip", RunService.Stepped, function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if HubState.PartCollisionCache[part] == nil then
                        HubState.PartCollisionCache[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)
    else
        UnbindConnection("Noclip")
        RestoreCollisions()
    end
end)

Tabs.Movement:AddKeybind("NoclipBind", {
    Title = "Noclip Keybind",
    Mode = "Toggle",
    Default = "None",
    Callback = function()
        if Options.NoclipBind and Options.NoclipBind.Value == "None" then return end
        if Options.Noclip then
            Options.Noclip:SetValue(not Options.Noclip.Value)
        end
    end
})

local InfJumpToggle = Tabs.Movement:AddToggle("InfJump", {
    Title = "Infinite Jump",
    Description = "Jump repeatedly in mid-air",
    Default = false
})
InfJumpToggle:OnChanged(function()
    HubState.Enabled.InfJump = Options.InfJump.Value
    if HubState.Enabled.InfJump then
        BindConnection("InfJump", UserInputService.JumpRequest, function()
            if UserInputService:GetFocusedTextBox() then return end
            local _, _, hum = GetCharacterParts(LocalPlayer)
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        UnbindConnection("InfJump")
    end
end)

Tabs.Movement:AddKeybind("InfJumpBind", {
    Title = "Infinite Jump Keybind",
    Mode = "Toggle",
    Default = "None",
    Callback = function()
        if Options.InfJumpBind and Options.InfJumpBind.Value == "None" then return end
        if Options.InfJump then
            Options.InfJump:SetValue(not Options.InfJump.Value)
        end
    end
})

local ClickTPToggle = Tabs.Movement:AddToggle("ClickTP", {
    Title = "Ctrl + Click Teleport",
    Description = "Hold LeftCtrl and Left-Click anywhere to teleport",
    Default = false
})
ClickTPToggle:OnChanged(function()
    HubState.Enabled.ClickTP = Options.ClickTP.Value
    if HubState.Enabled.ClickTP then
        BindConnection("ClickTP", UserInputService.InputBegan, function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                local _, root = GetCharacterParts(LocalPlayer)
                if root and Mouse.Hit then
                    root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3.5, 0))
                end
            end
        end)
    else
        UnbindConnection("ClickTP")
    end
end)

Tabs.Movement:AddSection("Player Teleport & Spectate")

local PlayerDropdown = Tabs.Movement:AddDropdown("TargetPlayerDropdown", {
    Title = "Select Player",
    Values = GetPlayerNames(),
    Multi = false,
    Default = 1
})
PlayerDropdown:OnChanged(function(val)
    HubState.Configs.SelectedPlayer = val
end)

Tabs.Movement:AddButton({
    Title = "Refresh Player List",
    Callback = function()
        PlayerDropdown:SetValues(GetPlayerNames())
    end
})

Tabs.Movement:AddButton({
    Title = "Teleport to Selected Player",
    Callback = function()
        local targetName = HubState.Configs.SelectedPlayer
        local targetPlayer = targetName and Players:FindFirstChild(targetName)
        if targetPlayer and IsAlive(targetPlayer) then
            local _, myRoot = GetCharacterParts(LocalPlayer)
            local _, targetRoot = GetCharacterParts(targetPlayer)
            if myRoot and targetRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            end
        else
            Fluent:Notify({ Title = "Teleport", Content = "Selected player is not available.", Duration = 3 })
        end
    end
})

local SpectateToggle = Tabs.Movement:AddToggle("SpectatePlayer", {
    Title = "Spectate Selected Player",
    Default = false
})
SpectateToggle:OnChanged(function()
    HubState.Enabled.Spectate = Options.SpectatePlayer.Value
    if HubState.Enabled.Spectate then
        BindConnection("SpectateLoop", RunService.RenderStepped, function()
            local targetName = HubState.Configs.SelectedPlayer
            local targetPlayer = targetName and Players:FindFirstChild(targetName)
            local _, _, targetHum = GetCharacterParts(targetPlayer)
            if targetHum and Workspace.CurrentCamera then
                Workspace.CurrentCamera.CameraSubject = targetHum
            end
        end)
    else
        UnbindConnection("SpectateLoop")
        local _, _, myHum = GetCharacterParts(LocalPlayer)
        if myHum and Workspace.CurrentCamera then
            Workspace.CurrentCamera.CameraSubject = myHum
        end
    end
end)

-- ==============================================================================
-- [3] VISUALS TAB: HIGHLIGHT CHAMS & OVERHEAD NAMETAG ESP
-- ==============================================================================
Tabs.Visuals:AddSection("Player ESP Suite")

local function RemoveESPForPlayer(player)
    local espData = HubState.ESPObjects[player]
    if espData then
        if espData.Highlight then espData.Highlight:Destroy() end
        if espData.Billboard then espData.Billboard:Destroy() end
        if espData.CharConn then espData.CharConn:Disconnect() end
        HubState.ESPObjects[player] = nil
    end
end

local function CreateBillboardTag(player, char)
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return nil end

    local bb = Instance.new("BillboardGui")
    bb.Name = "Hub_ESP_Billboard"
    bb.Adornee = head
    bb.Size = UDim2.fromOffset(180, 40)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Name = "InfoLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.2
    label.Text = player.DisplayName
    label.Parent = bb

    bb.Parent = char
    return bb
end

local function UpdateESPForCharacter(player, char)
    if not HubState.Enabled.ESP or player == LocalPlayer or not char then return end

    local existing = HubState.ESPObjects[player]
    if existing then
        if existing.Highlight then existing.Highlight:Destroy() end
        if existing.Billboard then existing.Billboard:Destroy() end
    else
        HubState.ESPObjects[player] = {}
    end

    local isTeammate = HubState.Configs.ESPTeamCheck and (player.Team ~= nil and player.Team == LocalPlayer.Team)
    if isTeammate then return end

    local fillColor = HubState.Configs.ESPFillColor
    if HubState.Configs.ESPUseTeamColor and player.Team and player.TeamColor then
        fillColor = player.TeamColor.Color
    end

    local hl = Instance.new("Highlight")
    hl.Name = "Hub_ESP_Highlight"
    hl.FillColor = fillColor
    hl.OutlineColor = HubState.Configs.ESPOutlineColor
    hl.FillTransparency = HubState.Configs.ESPFillTransparency
    hl.OutlineTransparency = HubState.Configs.ESPOutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char
    hl.Parent = char
    HubState.ESPObjects[player].Highlight = hl

    if HubState.Configs.ESPNameTags then
        HubState.ESPObjects[player].Billboard = CreateBillboardTag(player, char)
    end
end

local function RefreshAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if HubState.Enabled.ESP then
                if not HubState.ESPObjects[player] then
                    HubState.ESPObjects[player] = {}
                end
                if not HubState.ESPObjects[player].CharConn then
                    HubState.ESPObjects[player].CharConn = player.CharacterAdded:Connect(function(newChar)
                        task.wait(0.25)
                        UpdateESPForCharacter(player, newChar)
                    end)
                end
                if player.Character then
                    UpdateESPForCharacter(player, player.Character)
                end
            else
                RemoveESPForPlayer(player)
            end
        end
    end
end

BindConnection("ESPUpdater", RunService.RenderStepped, function()
    if not HubState.Enabled.ESP or not HubState.Configs.ESPNameTags then return end
    local _, myRoot = GetCharacterParts(LocalPlayer)
    for player, data in pairs(HubState.ESPObjects) do
        if data.Billboard and data.Billboard.Parent then
            local label = data.Billboard:FindFirstChild("InfoLabel")
            local _, targetRoot, targetHum = GetCharacterParts(player)
            if label and targetRoot and targetHum then
                local dist = myRoot and math.floor((targetRoot.Position - myRoot.Position).Magnitude) or 0
                local hp = math.floor(targetHum.Health)
                label.Text = string.format("%s [%d HP] [%dm]", player.Name, hp, dist)
            end
        end
    end
end)

local ESPToggle = Tabs.Visuals:AddToggle("ESP", {
    Title = "Enable Player ESP",
    Description = "Through-wall Highlight Chams + Live Name/HP/Distance tags",
    Default = false
})
ESPToggle:OnChanged(function()
    HubState.Enabled.ESP = Options.ESP.Value
    RefreshAllESP()
end)

Tabs.Visuals:AddKeybind("ESPBind", {
    Title = "ESP Toggle Keybind",
    Mode = "Toggle",
    Default = "None",
    Callback = function()
        if Options.ESPBind and Options.ESPBind.Value == "None" then return end
        if Options.ESP then
            Options.ESP:SetValue(not Options.ESP.Value)
        end
    end
})

local ESPNameTagsToggle = Tabs.Visuals:AddToggle("ESPNameTags", {
    Title = "Show Overhead Name / HP / Distance",
    Default = true
})
ESPNameTagsToggle:OnChanged(function()
    HubState.Configs.ESPNameTags = Options.ESPNameTags.Value
    if HubState.Enabled.ESP then RefreshAllESP() end
end)

local ESPTeamColorToggle = Tabs.Visuals:AddToggle("ESPUseTeamColor", {
    Title = "Use Team Colors",
    Default = true
})
ESPTeamColorToggle:OnChanged(function()
    HubState.Configs.ESPUseTeamColor = Options.ESPUseTeamColor.Value
    if HubState.Enabled.ESP then RefreshAllESP() end
end)

local ESPTeamCheckToggle = Tabs.Visuals:AddToggle("ESPTeamCheck", {
    Title = "Team Check (Hide Teammates)",
    Default = false
})
ESPTeamCheckToggle:OnChanged(function()
    HubState.Configs.ESPTeamCheck = Options.ESPTeamCheck.Value
    if HubState.Enabled.ESP then RefreshAllESP() end
end)

local ESPColorpicker = Tabs.Visuals:AddColorpicker("ESPColor", {
    Title = "ESP Fill Color",
    Default = Color3.fromRGB(255, 65, 65)
})
ESPColorpicker:OnChanged(function()
    HubState.Configs.ESPFillColor = ESPColorpicker.Value
    if HubState.Enabled.ESP then RefreshAllESP() end
end)

Tabs.Visuals:AddSlider("ESPFillTrans", {
    Title = "Fill Transparency",
    Default = 0.65,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v)
        HubState.Configs.ESPFillTransparency = tonumber(v) or 0.65
        if HubState.Enabled.ESP then RefreshAllESP() end
    end
})

-- ==============================================================================
-- [4] COMBAT TAB: SMOOTHED FOV AIMBOT & HITBOX EXPANDER
-- ==============================================================================
Tabs.Combat:AddSection("Camera Aimbot (Hold Right-Click)")

local FOVScreenGui = Instance.new("ScreenGui")
FOVScreenGui.Name = "Hub_FOV_Overlay"
FOVScreenGui.ResetOnSpawn = false
FOVScreenGui.IgnoreGuiInset = true
pcall(function()
    FOVScreenGui.Parent = game:GetService("CoreGui")
end)
if not FOVScreenGui.Parent then
    FOVScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local FOVFrame = Instance.new("Frame")
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.BackgroundTransparency = 1
FOVFrame.Size = UDim2.fromOffset(300, 300)
FOVFrame.Visible = false
FOVFrame.Parent = FOVScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVFrame

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 90, 90)
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.25
FOVStroke.Parent = FOVFrame

local function HasLineOfSight(targetPart, targetCharacter)
    if not HubState.Configs.AimbotWallCheck then return true end
    local cam = Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local direction = targetPart.Position - origin

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character, cam }
    rayParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, rayParams)
    if not result then return true end
    return result.Instance:IsDescendantOf(targetCharacter)
end

local function GetClosestScreenTarget()
    local cam = Workspace.CurrentCamera
    local mousePos = UserInputService:GetMouseLocation()
    local bestPart = nil
    local shortestDist = HubState.Configs.AimbotFOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            local skipTeam = HubState.Configs.AimbotTeamCheck and (player.Team ~= nil and player.Team == LocalPlayer.Team)
            if not skipTeam then
                local char = player.Character
                local targetPart = char:FindFirstChild(HubState.Configs.AimbotTargetPart) or char:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local screenPoint, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
                        if screenDist < shortestDist and HasLineOfSight(targetPart, char) then
                            shortestDist = screenDist
                            bestPart = targetPart
                        end
                    end
                end
            end
        end
    end

    return bestPart
end

BindConnection("CombatRenderLoop", RunService.RenderStepped, function()
    if HubState.Configs.ShowFOVCircle then
        local mousePos = UserInputService:GetMouseLocation()
        local radius = HubState.Configs.AimbotFOV
        FOVFrame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
        FOVFrame.Size = UDim2.fromOffset(radius * 2, radius * 2)
        FOVFrame.Visible = true
    else
        FOVFrame.Visible = false
    end

    if HubState.Enabled.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local targetPart = GetClosestScreenTarget()
        if targetPart and Workspace.CurrentCamera then
            local cam = Workspace.CurrentCamera
            local goalCFrame = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
            cam.CFrame = cam.CFrame:Lerp(goalCFrame, math.clamp(HubState.Configs.AimbotSmoothness, 0.05, 1))
        end
    end
end)

local AimbotToggle = Tabs.Combat:AddToggle("Aimbot", {
    Title = "Enable Camera Aimbot (Hold RMB)",
    Description = "Locks smoothly onto targets inside your FOV circle",
    Default = false
})
AimbotToggle:OnChanged(function()
    HubState.Enabled.Aimbot = Options.Aimbot.Value
end)

Tabs.Combat:AddKeybind("AimbotBind", {
    Title = "Aimbot Toggle Keybind",
    Mode = "Toggle",
    Default = "None",
    Callback = function()
        if Options.AimbotBind and Options.AimbotBind.Value == "None" then return end
        if Options.Aimbot then
            Options.Aimbot:SetValue(not Options.Aimbot.Value)
        end
    end
})

local ShowFOVToggle = Tabs.Combat:AddToggle("ShowFOVCircle", {
    Title = "Draw FOV Circle",
    Default = false
})
ShowFOVToggle:OnChanged(function()
    HubState.Configs.ShowFOVCircle = Options.ShowFOVCircle.Value
end)

local AimbotPartDropdown = Tabs.Combat:AddDropdown("AimbotPart", {
    Title = "Target Bone",
    Values = { "Head", "HumanoidRootPart", "UpperTorso" },
    Multi = false,
    Default = 1
})
AimbotPartDropdown:OnChanged(function(v)
    HubState.Configs.AimbotTargetPart = v
end)

Tabs.Combat:AddSlider("AimbotFOV", {
    Title = "FOV Radius (px)",
    Default = 150,
    Min = 40,
    Max = 500,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.AimbotFOV = tonumber(v) or 150
    end
})

Tabs.Combat:AddSlider("AimbotSmooth", {
    Title = "Aimbot Smoothness (1 = Instant)",
    Default = 0.25,
    Min = 0.05,
    Max = 1.0,
    Rounding = 2,
    Callback = function(v)
        HubState.Configs.AimbotSmoothness = tonumber(v) or 0.25
    end
})

local AimbotTeamToggle = Tabs.Combat:AddToggle("AimbotTeamCheck", {
    Title = "Team Check",
    Default = true
})
AimbotTeamToggle:OnChanged(function()
    HubState.Configs.AimbotTeamCheck = Options.AimbotTeamCheck.Value
end)

local AimbotWallToggle = Tabs.Combat:AddToggle("AimbotWallCheck", {
    Title = "Wall Check (Visible Targets Only)",
    Default = true
})
AimbotWallToggle:OnChanged(function()
    HubState.Configs.AimbotWallCheck = Options.AimbotWallCheck.Value
end)

Tabs.Combat:AddSection("Hitbox Expander")

local function RestoreHitboxes()
    for part, data in pairs(HubState.HitboxCache) do
        if part and part.Parent then
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
        end
    end
    table.clear(HubState.HitboxCache)
end

local HitboxToggle = Tabs.Combat:AddToggle("HitboxExpander", {
    Title = "Enable Hitbox Expander",
    Description = "Expands enemy HumanoidRootPart hitboxes",
    Default = false
})
HitboxToggle:OnChanged(function()
    HubState.Enabled.HitboxExpander = Options.HitboxExpander.Value
    if HubState.Enabled.HitboxExpander then
        BindConnection("HitboxLoop", RunService.RenderStepped, function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and IsAlive(player) then
                    local isTeammate = HubState.Configs.HitboxTeamCheck and (player.Team ~= nil and player.Team == LocalPlayer.Team)
                    local _, root = GetCharacterParts(player)
                    if root then
                        if not isTeammate then
                            if not HubState.HitboxCache[root] then
                                HubState.HitboxCache[root] = {
                                    Size = root.Size,
                                    Transparency = root.Transparency,
                                    CanCollide = root.CanCollide
                                }
                            end
                            local sz = HubState.Configs.HitboxSize
                            root.Size = Vector3.new(sz, sz, sz)
                            root.Transparency = HubState.Configs.HitboxTransparency
                            root.CanCollide = false
                        elseif HubState.HitboxCache[root] then
                            local d = HubState.HitboxCache[root]
                            root.Size = d.Size
                            root.Transparency = d.Transparency
                            root.CanCollide = d.CanCollide
                            HubState.HitboxCache[root] = nil
                        end
                    end
                end
            end
        end)
    else
        UnbindConnection("HitboxLoop")
        RestoreHitboxes()
    end
end)

Tabs.Combat:AddKeybind("HitboxBind", {
    Title = "Hitbox Expander Keybind",
    Mode = "Toggle",
    Default = "None",
    Callback = function()
        if Options.HitboxBind and Options.HitboxBind.Value == "None" then return end
        if Options.HitboxExpander then
            Options.HitboxExpander:SetValue(not Options.HitboxExpander.Value)
        end
    end
})

Tabs.Combat:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Default = 8,
    Min = 2,
    Max = 25,
    Rounding = 0,
    Callback = function(v)
        HubState.Configs.HitboxSize = tonumber(v) or 8
    end
})

Tabs.Combat:AddSlider("HitboxTrans", {
    Title = "Hitbox Transparency",
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(v)
        HubState.Configs.HitboxTransparency = tonumber(v) or 0.7
    end
})

-- ==============================================================================
-- [5] WORLD TAB: LIGHTING, FULLBRIGHT & ATMOSPHERE
-- ==============================================================================
Tabs.World:AddSection("Lighting & Visibility")

local FullbrightToggle = Tabs.World:AddToggle("Fullbright", {
    Title = "Fullbright",
    Description = "Maximum visibility in dark maps; restores original lighting on disable",
    Default = false
})
FullbrightToggle:OnChanged(function()
    HubState.Enabled.Fullbright = Options.Fullbright.Value
    if HubState.Enabled.Fullbright then
        BindConnection("Fullbright", RunService.RenderStepped, function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 140)
            Lighting.Ambient = Color3.fromRGB(140, 140, 140)
        end)
    else
        UnbindConnection("Fullbright")
        for prop, val in pairs(HubState.LightingBackup) do
            pcall(function() Lighting[prop] = val end)
        end
    end
end)

Tabs.World:AddKeybind("FullbrightBind", {
    Title = "Fullbright Keybind",
    Mode = "Toggle",
    Default = "None",
    Callback = function()
        if Options.FullbrightBind and Options.FullbrightBind.Value == "None" then return end
        if Options.Fullbright then
            Options.Fullbright:SetValue(not Options.Fullbright.Value)
        end
    end
})

local NoFogToggle = Tabs.World:AddToggle("NoFog", {
    Title = "Remove Fog & Atmosphere",
    Default = false
})
NoFogToggle:OnChanged(function()
    HubState.Enabled.NoFog = Options.NoFog.Value
    if HubState.Enabled.NoFog then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        for _, v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then
                v.Density = 0
            end
        end
    else
        Lighting.FogEnd = HubState.LightingBackup.FogEnd
        Lighting.FogStart = HubState.LightingBackup.FogStart
    end
end)

Tabs.World:AddSlider("ClockTimeSlider", {
    Title = "Time of Day (ClockTime)",
    Default = 14,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(v)
        Lighting.ClockTime = tonumber(v) or 14
    end
})

Tabs.World:AddButton({
    Title = "Remove Blur / DepthOfField Effects",
    Callback = function()
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
        Fluent:Notify({ Title = "World", Content = "Disabled post-processing blur effects.", Duration = 3 })
    end
})

-- ==============================================================================
-- [6] UTILITY TAB: SERVERHOP, REJOIN & FPS BOOST
-- ==============================================================================
Tabs.Utility:AddSection("Server Management")

local function HopServer(sortOrder)
    SafeCall(function()
        local url = string.format(
            "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100",
            PlaceId,
            sortOrder or "Asc"
        )
        local raw = game:HttpGet(url)
        local decoded = HttpService:JSONDecode(raw)
        local candidates = {}

        if decoded and decoded.data then
            for _, srv in ipairs(decoded.data) do
                if type(srv) == "table" and srv.id ~= JobId and tonumber(srv.playing) < tonumber(srv.maxPlayers) then
                    table.insert(candidates, srv.id)
                end
            end
        end

        if #candidates > 0 then
            local chosen = sortOrder == "Asc" and candidates[1] or candidates[math.random(1, #candidates)]
            Fluent:Notify({ Title = "ServerHop", Content = "Joining server " .. string.sub(chosen, 1, 8), Duration = 4 })
            TeleportService:TeleportToPlaceInstance(PlaceId, chosen, LocalPlayer)
        else
            Fluent:Notify({ Title = "ServerHop", Content = "No available servers found.", Duration = 4 })
        end
    end)
end

Tabs.Utility:AddButton({
    Title = "Smart ServerHop (Random Available Server)",
    Description = "Finds a public server with open slots different from your current server",
    Callback = function()
        HopServer("Desc")
    end
})

Tabs.Utility:AddButton({
    Title = "Hop to Lowest Population Server",
    Description = "Finds the quietest open server",
    Callback = function()
        HopServer("Asc")
    end
})

Tabs.Utility:AddButton({
    Title = "Rejoin Current Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end
})

Tabs.Utility:AddButton({
    Title = "Copy Current Server JobId",
    Callback = function()
        if type(setclipboard) == "function" then
            setclipboard(tostring(JobId))
            Fluent:Notify({ Title = "Clipboard", Content = "Copied JobId: " .. tostring(JobId), Duration = 3 })
        else
            Fluent:Notify({ Title = "Clipboard", Content = "JobId: " .. tostring(JobId), Duration = 5 })
        end
    end
})

Tabs.Utility:AddSection("Performance & Optimization")

Tabs.Utility:AddButton({
    Title = "FPS Boost / Anti-Lag",
    Description = "Lowers material quality and disables heavy particle/trail effects",
    Callback = function()
        SafeCall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    obj.Enabled = false
                end
            end
            Fluent:Notify({ Title = "Performance", Content = "Applied Anti-Lag optimizations.", Duration = 3 })
        end)
    end
})

-- ==============================================================================
-- [7] SETTINGS TAB: THEME, CONFIGS & SAFE UNLOAD
-- ==============================================================================
Tabs.Settings:AddSection("Hub Controls")

local ThemeDropdown = Tabs.Settings:AddDropdown("HubTheme", {
    Title = "UI Theme",
    Values = { "Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose" },
    Multi = false,
    Default = 1
})
ThemeDropdown:OnChanged(function(val)
    pcall(function()
        Fluent:SetTheme(val)
    end)
end)

Tabs.Settings:AddButton({
    Title = "Unload & Clean Up Hub",
    Description = "Disconnects all loops, restores character collisions/lighting, and closes UI",
    Callback = function()
        StopFly()
        RestoreCollisions()
        RestoreHitboxes()
        for _, player in ipairs(Players:GetPlayers()) do
            RemoveESPForPlayer(player)
        end
        for key, conn in pairs(HubState.Connections) do
            if conn then conn:Disconnect() end
            HubState.Connections[key] = nil
        end
        for prop, val in pairs(HubState.LightingBackup) do
            pcall(function() Lighting[prop] = val end)
        end
        Workspace.Gravity = HubState.DefaultGravity
        if FOVScreenGui then FOVScreenGui:Destroy() end
        Fluent:Destroy()
    end
})

if SaveManagerOk and InterfaceManagerOk and SaveManager and InterfaceManager then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        InterfaceManager:SetLibrary(Fluent)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({})
        InterfaceManager:SetFolder("N1cknaemHub")
        SaveManager:SetFolder("N1cknaemHub/configs")
        InterfaceManager:BuildInterfaceSection(Tabs.Settings)
        SaveManager:BuildConfigSection(Tabs.Settings)
        SaveManager:LoadAutoloadConfig()
    end)
end

-- ==============================================================================
-- CHARACTER LIFECYCLE & CLEANUP HOOKS
-- ==============================================================================
BindConnection("LocalCharacterAdded", LocalPlayer.CharacterAdded, function(newChar)
    table.clear(HubState.PartCollisionCache)
    local hum = newChar:WaitForChild("Humanoid", 10)
    local root = newChar:WaitForChild("HumanoidRootPart", 10)
    if not hum or not root then return end

    task.wait(0.2)
    if HubState.Configs.LockStats then
        ApplyCharacterStats()
    end
    if HubState.Enabled.Fly then
        StartFly()
    end
end)

BindConnection("PlayerAdded", Players.PlayerAdded, function()
    PlayerDropdown:SetValues(GetPlayerNames())
    if HubState.Enabled.ESP then
        RefreshAllESP()
    end
end)

BindConnection("PlayerRemoving", Players.PlayerRemoving, function(player)
    RemoveESPForPlayer(player)
    task.defer(function()
        PlayerDropdown:SetValues(GetPlayerNames())
    end)
end)

Window:SelectTab(1)
Fluent:Notify({
    Title = "N1cknaem's Hub v2.2",
    Content = "Loaded with no default keybinds. Set your own binds in each tab!",
    Duration = 5
})
