local M = {}
M.name = "ui"
M.version = "1.0.0"

function M.init(api)
    local Services = api.Services
    local TweenService = Services.TweenService
    local Players = Services.Players
    local lp = Players.LocalPlayer
    local core
    if game:FindFirstChildOfClass("CoreGui") then
        if gethui then core = gethui() else core = game:GetService("CoreGui") end
    else
        core = lp:WaitForChild("PlayerGui")
    end

    local G2L = {}
    G2L["1"] = Instance.new("ScreenGui")
    G2L["1"].IgnoreGuiInset = true
    G2L["1"].DisplayOrder = 999
    G2L["1"].ResetOnSpawn = false

    G2L["2"] = Instance.new("Frame", G2L["1"])
    G2L["2"].BackgroundColor3 = Color3.fromRGB(35,35,35)
    G2L["2"].AnchorPoint = Vector2.new(0.5,0.5)
    G2L["2"].Size = UDim2.new(0.3,0,0.5,0)
    G2L["2"].Position = UDim2.new(0.5,0,0.5,0)
    G2L["2"].BorderSizePixel = 0

    Instance.new("UICorner", G2L["2"]).CornerRadius = UDim.new(0.02,0)

    local bar = Instance.new("Frame", G2L["2"])
    bar.BackgroundColor3 = Color3.fromRGB(50,50,50)
    bar.Size = UDim2.new(1,0,0.1,0)
    bar.BorderSizePixel = 0
    bar.Name = "bar"
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0.02,0)

    local label = Instance.new("TextLabel", bar)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7,0,1,0)
    label.Text = "NPC Control | @xtel"
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.new(0.05,0,0,0)

    local closeBtn = Instance.new("TextButton", bar)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220,50,50)
    closeBtn.Size = UDim2.new(0.08,0,0.8,0)
    closeBtn.Position = UDim2.new(0.91,0,0.1,0)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.2,0)

    local minBtn = Instance.new("TextButton", bar)
    minBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    minBtn.Size = UDim2.new(0.08,0,0.8,0)
    minBtn.Position = UDim2.new(0.81,0,0.1,0)
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.TextScaled = true
    minBtn.Font = Enum.Font.SourceSansBold
    minBtn.BorderSizePixel = 0
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0.2,0)

    G2L["11"] = Instance.new("ScrollingFrame", G2L["2"])
    G2L["11"].BackgroundTransparency = 1
    G2L["11"].Size = UDim2.new(0.95,0,0.85,0)
    G2L["11"].Position = UDim2.new(0.025,0,0.12,0)
    G2L["11"].ScrollBarThickness = 6
    G2L["11"].BorderSizePixel = 0
    G2L["11"].AutomaticCanvasSize = Enum.AutomaticSize.Y
    G2L["11"].CanvasSize = UDim2.new(0,0,0,0)
    G2L["11"].ScrollingDirection = Enum.ScrollingDirection.Y

    local listLayout = Instance.new("UIListLayout", G2L["11"])
    listLayout.Padding = UDim.new(0.01,0)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- status label
    local statusLabel = Instance.new("TextLabel", G2L["11"])
    statusLabel.BackgroundColor3 = Color3.fromRGB(45,45,45)
    statusLabel.Size = UDim2.new(1,0,0.1,0)
    statusLabel.Text = "NPCs: Nenhum selecionado"
    statusLabel.TextColor3 = Color3.fromRGB(255,255,255)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.SourceSansBold
    statusLabel.BorderSizePixel = 0
    Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0.1,0)

    -- helper functions (criados baseados no seu script)
    local function createButton(text, callback)
        local button = Instance.new("TextButton", G2L["11"])
        button.BackgroundColor3 = Color3.fromRGB(60,60,60)
        button.Size = UDim2.new(1,0,0.1,0)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255,255,255)
        button.TextScaled = true
        button.Font = Enum.Font.SourceSans
        button.BorderSizePixel = 0
        Instance.new("UICorner", button).CornerRadius = UDim.new(0.1,0)

        button.MouseEnter:Connect(function()
            TweenService:Create(button, api.config.fast, {BackgroundColor3 = Color3.fromRGB(80,80,80)}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, api.config.fast, {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
        end)
        button.MouseButton1Click:Connect(callback)
        return button
    end

    local function createToggle(text, callback)
        local frame = Instance.new("Frame", G2L["11"])
        frame.BackgroundColor3 = Color3.fromRGB(60,60,60)
        frame.Size = UDim2.new(1,0,0.1,0)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0.1,0)

        local label = Instance.new("TextLabel", frame)
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0.8,0,1,0)
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.TextScaled = true
        label.Font = Enum.Font.SourceSans
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Position = UDim2.new(0.05,0,0,0)

        local toggle = Instance.new("Frame", frame)
        toggle.BackgroundColor3 = Color3.fromRGB(220,50,50)
        toggle.Size = UDim2.new(0.12,0,0.6,0)
        toggle.Position = UDim2.new(0.85,0,0.2,0)
        toggle.BorderSizePixel = 0
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0.3,0)

        local button = Instance.new("TextButton", frame)
        button.BackgroundTransparency = 1
        button.Size = UDim2.new(1,0,1,0)
        button.Text = ""

        local isOn = false
        button.MouseButton1Click:Connect(function()
            isOn = not isOn
            local color = isOn and Color3.fromRGB(50,220,50) or Color3.fromRGB(220,50,50)
            TweenService:Create(toggle, api.config.fast, {BackgroundColor3 = color}):Play()
            callback(isOn)
        end)

        return {
            switch = function(state)
                isOn = state
                local color = isOn and Color3.fromRGB(50,220,50) or Color3.fromRGB(220,50,50)
                TweenService:Create(toggle, api.config.fast, {BackgroundColor3 = color}):Play()
            end
        }
    end

    -- expose registration functions para actions.lua
    api.register_button = function(text, cb) return createButton(text, cb) end
    api.register_toggle = function(text, cb) return createToggle(text, cb) end
    api.updateStatus = function(txt, color)
        statusLabel.Text = txt or statusLabel.Text
        statusLabel.TextColor3 = color or statusLabel.TextColor3
    end

    -- minimize/close
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        G2L["2"].Visible = not minimized
    end)

    closeBtn.MouseButton1Click:Connect(function()
        if api._onClose then pcall(api._onClose) end
        if G2L["1"] then G2L["1"]:Destroy() end
    end)

    G2L["1"].Parent = core
    api.print("ui loaded")
end

return M
