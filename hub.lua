local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function createHub()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "N1cknaemHub"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 400, 0, 300)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui

    local Resizer = Instance.new("Frame")
    Resizer.Name = "Resizer"
    Resizer.Size = UDim2.new(0, 10, 0, 10)
    Resizer.Position = UDim2.new(1, -10, 1, -10)
    Resizer.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Resizer.Parent = MainFrame

    local function makeResizable(frame, resizer)
        local resizing = false
        resizer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
        RunService.RenderStepped:Connect(function()
            if resizing then
                local mousePos = UserInputService:GetMouseLocation()
                frame.Size = UDim2.new(0, mousePos.X - frame.AbsolutePosition.X, 0, mousePos.Y - frame.AbsolutePosition.Y)
            end
        end)
    end

    makeResizable(MainFrame, Resizer)

    local OpenKey = Enum.KeyCode.RightShift
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == OpenKey then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    local function createToggle(name, callback)
        local Toggle = Instance.new("TextButton")
        Toggle.Name = name
        Toggle.Text = name
        Toggle.Size = UDim2.new(1, 0, 0, 30)
        Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Toggle.Parent = MainFrame
        local enabled = false
        Toggle.MouseButton1Click:Connect(function()
            enabled = not enabled
            Toggle.BackgroundColor3 = enabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
            callback(enabled)
        end)
    end

    createToggle("Anti-AFK", function(enabled)
        if enabled then
            LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end)

    createToggle("Infinite Jump", function(enabled)
        if enabled then
            UserInputService.JumpRequest:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid:ChangeState("Jumping")
                end
            end)
        end
    end)

    createToggle("Noclip", function(enabled)
        RunService.Stepped:Connect(function()
            if enabled and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end)

    createToggle("Fullbright", function(enabled)
        if enabled then
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 2
            Lighting.ClockTime = 12
        end
    end)
    
    local function createSlider(name, min, max, callback)
        local Slider = Instance.new("Frame")
        Slider.Name = name
        Slider.Size = UDim2.new(1, 0, 0, 30)
        Slider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Slider.Parent = MainFrame
        local Knob = Instance.new("TextButton")
        Knob.Size = UDim2.new(0, 20, 1, 0)
        Knob.Parent = Slider
        Knob.MouseButton1Down:Connect(function()
            local connection
            connection = RunService.RenderStepped:Connect(function()
                local mousePos = UserInputService:GetMouseLocation()
                local relativeX = math.clamp((mousePos.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
                Knob.Position = UDim2.new(relativeX, -10, 0, 0)
                callback(min + (max - min) * relativeX)
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection:Disconnect()
                end
            end)
        end)
    end

    createSlider("Speed", 16, 200, function(value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = value
        end
    end)

end

createHub()
