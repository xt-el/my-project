-- NPC Control v7.6 - Controle de NPC Reescrito (Mais Robusto)

local G2L = {}
local core

-- CoreGui setup 
if game:FindFirstChildOfClass("CoreGui") then
    if gethui then
        core = gethui()
    else
        core = game:GetService("CoreGui")
    end
else
    core = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- Services
local rs = game:GetService("RunService")
local ws = game:GetService("Workspace")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()
local uis = game:GetService("UserInputService")

-- Variables
local selectedNPCs = {}
local npcList = {}
local connections = {}
local playerCharacterBackup = nil 
local rad = 50000 
local minimizebool = false
local currentNPC = nil
local clicknpc = false
local teleportConnection = nil 
local isControlling = false
local controlledNPC = nil 
local disabledScripts = {} 
local npcOriginalWalkSpeed = nil 
local npcOriginalAutoRotate = nil 
local isKillingAll = false 

-- Highlight/Glow system V7.6: Billboard Compacto
local npcGlows = {} 

-- Tamanhos base em Scale/Offset para manter o Billboard compacto e legível
local BASE_SIZE_X = 0.5 
local BASE_SIZE_Y = 0.5 
local FIXED_OFFSET = 100 

local function clearNPCGlows(npc)
    if npcGlows[npc] then
        if npcGlows[npc].Parent then 
            npcGlows[npc]:Destroy()
        end
        npcGlows[npc] = nil
    end
end

-- =========================================================
-- Funções de Checagem e Ownership (MANTIDO)
-- =========================================================
local function isNPC(model)
    if not model or not model.Parent or not model:IsA("Model") then return false end
    
    local hasHumanoid = model:FindFirstChildOfClass("Humanoid")
    local hasHRP = model:FindFirstChild("HumanoidRootPart")
    
    if not hasHumanoid and not hasHRP then 
        return false 
    end 
    
    local player = plrs:GetPlayerFromCharacter(model)
    if player then return false end 
    
    return true
end

local function hasNetworkOwnership(npc)
    local part = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
    if part then
        local success, result = pcall(function()
            local owner = part:GetNetworkOwner()
            return owner == lp 
        end)
        return success and result
    end
    return false
end

local function forceOwnership(npc)
    if not npc or npc.Parent ~= ws then return false end
    local part = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
    if not part then return false end
    
    if not part.Anchored then
        pcall(function()
            part:SetNetworkOwner(lp)
        end)
        task.wait(0.05)
        local ownership = hasNetworkOwnership(npc)
        return ownership
    end
    return false
end

-- =========================================================
-- BillboardGui Compacto (V7.6)
-- =========================================================
local function createGlow(npc)
    if npcGlows[npc] then return end 
    
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if not hrp then return end 

    local isSelected = table.find(selectedNPCs, npc)
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NPC_Glow_V7"
    billboard.AlwaysOnTop = true
    -- Tamanho misto para manter a legibilidade
    billboard.Size = UDim2.new(BASE_SIZE_X, FIXED_OFFSET, BASE_SIZE_Y, FIXED_OFFSET) 
    billboard.ExtentsOffset = Vector3.new(0, hrp.Size.Y / 2, 0) 
    billboard.Adornee = hrp 
    
    local glowFrame = Instance.new("Frame")
    glowFrame.Size = UDim2.new(1, 0, 1, 0)
    glowFrame.BackgroundTransparency = 1
    glowFrame.Parent = billboard

    local outline = Instance.new("UIStroke")
    outline.Color = isSelected and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 0)
    outline.Thickness = isSelected and 8 or 4 
    outline.Transparency = isSelected and 0.2 or 0.7 
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Parent = glowFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NPCNameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0) 
    nameLabel.Position = UDim2.new(0, 0, 0.65, 0)
    nameLabel.Text = npc.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.ZIndex = 2
    nameLabel.TextStrokeTransparency = 0.8 
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = glowFrame
    
    local clickButton = Instance.new("TextButton")
    clickButton.Name = "ClickSelector"
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.Parent = glowFrame
    clickButton.ZIndex = 3
    
    clickButton.MouseButton1Click:Connect(function()
        if not clicknpc then return end 
        
        currentNPC = npc
        local isCurrentlySelected = table.find(selectedNPCs, npc)
        
        if isCurrentlySelected then
            for i, selectedNPC in pairs(selectedNPCs) do
                if selectedNPC == npc then
                    table.remove(selectedNPCs, i)
                    break
                end
            end
        else
            table.insert(selectedNPCs, npc)
        end

        updateNPCList() 
        updateAllGlows()
        
        tempGlow(npc, isCurrentlySelected and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(0, 255, 0)) 
    end)


    billboard.Parent = npc
    npcGlows[npc] = billboard
end

local function updateGlow(npc)
    local billboard = npcGlows[npc]
    if billboard and billboard.Parent then
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if not hrp then clearNPCGlows(npc); return end 
        billboard.Adornee = hrp
        
        local isSelected = table.find(selectedNPCs, npc)
        
        local nameLabel = billboard:FindFirstChildOfClass("Frame"):FindFirstChild("NPCNameLabel")
        local outline = billboard:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("UIStroke")
        
        -- Cores
        local color = isSelected and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 0)
        local transparency = isSelected and 0.2 or 0.7 
        
        if outline then
            outline.Color = color
            outline.Thickness = isSelected and 8 or 4 
            outline.Transparency = transparency
        end
        
        if nameLabel then
            nameLabel.Size = UDim2.new(1, 0, isSelected and 0.4 or 0.3, 0) 
            nameLabel.Position = UDim2.new(0, 0, isSelected and 0.55 or 0.65, 0)

            nameLabel.TextColor3 = isSelected and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
            nameLabel.TextStrokeTransparency = isSelected and 0.5 or 0.8 
        end
        
    else
        clearNPCGlows(npc)
    end
end

-- ... [Funções de Flash Glow, Scan, GUI Setup (MANTIDO)] ...

local function flashGlow(npc, color)
    task.spawn(function()
        local billboard = npcGlows[npc]
        if billboard then
            local outline = billboard:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("UIStroke")
            if outline then
                local originalColor = outline.Color
                local originalTransparency = outline.Transparency
                
                for i = 1, 2 do
                    outline.Color = color
                    outline.Transparency = 0.1
                    task.wait(0.5) 
                    outline.Color = originalColor
                    outline.Transparency = originalTransparency
                    task.wait(0.5) 
                end
                
                updateGlow(npc)
            end
        end
    end)
end

local function tempGlow(npc, color)
    task.spawn(function()
        local billboard = npcGlows[npc]
        if billboard then
            local outline = billboard:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("UIStroke")
            if outline then
                local originalColor = outline.Color
                local originalTransparency = outline.Transparency
                
                outline.Color = color
                outline.Transparency = 0.2
                
                task.wait(0.5)
                
                outline.Color = originalColor
                outline.Transparency = originalTransparency
                updateGlow(npc)
            end
        end
    end)
end

local lastScan = 0
local scanDebounce = 1.0

local function scanNPCs()
    local currentTime = tick()
    if currentTime - lastScan < scanDebounce then return npcList end
    lastScan = currentTime
    
    local newNPCList = {}
    
    local toRemove = {}
    for npc in pairs(npcGlows) do
        if not npc or not npc.Parent or not isNPC(npc) then
            clearNPCGlows(npc)
            table.insert(toRemove, npc)
        end
    end
    for _, npc in ipairs(toRemove) do
        npcGlows[npc] = nil 
    end
    
    for _, item in pairs(ws:GetDescendants()) do
        if isNPC(item) then
            if not npcGlows[item] then
                createGlow(item)
            end
            table.insert(newNPCList, item)
        end
    end
    
    table.sort(newNPCList, function(a, b)
        local char = lp.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return a.Name < b.Name end
        local hrp = char.HumanoidRootPart
        local distA = (a:FindFirstChild("HumanoidRootPart") and (a.HumanoidRootPart.Position - hrp.Position).Magnitude) or math.huge
        local distB = (b:FindFirstChild("HumanoidRootPart") and (b.HumanoidRootPart.Position - hrp.Position).Magnitude) or math.huge
        return distA < distB
    end)
    
    npcList = newNPCList
    return npcList
end

local function updateNPCInfo()
    if not G2L["11"] then return end
    
    for _, child in pairs(G2L["11"]:GetChildren()) do
        if child:IsA("TextButton") then
            local npcName = child.Text:match("^[^(]+")
            if npcName then
                npcName = npcName:gsub("%s+$", "")
                
                for _, npc in pairs(npcList) do
                    if npc and npc.Name == npcName then
                        local distance = "??"
                        local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                        local npcHRP = npc:FindFirstChild("HumanoidRootPart")
                        
                        if myHRP and npcHRP then
                            distance = math.floor((npcHRP.Position - myHRP.Position).Magnitude)
                        end
                        child.Text = npc.Name .. " (" .. distance .. ")"
                        break
                    end
                end
            end
        end
    end
end

local statusLabel 
local function updateModoCliqueButton(forceClickOff)
    if forceClickOff then
        clicknpc = false
    end

    local modoCliqueButton = G2L["modoCliqueButton"]
    
    local statusText = "NPCs: " .. #npcList .. " | Selecionados: " .. #selectedNPCs .. " | Current: " .. (currentNPC and currentNPC.Name or "Nenhum") .. " | Modo Clique: " .. (clicknpc and "ON" or "OFF")
    
    if modoCliqueButton and modoCliqueButton.Parent then
        local text = clicknpc and "ON" or "OFF"
        local color = clicknpc and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(60, 60, 60)
        
        modoCliqueButton.Text = "Modo Clique: " .. text
        modoCliqueButton.BackgroundColor3 = color
    end
    
    if statusLabel and statusLabel.Parent then 
        statusLabel.Text = statusText
    end
end

-- GUI elements creation (MANTIDO)
G2L["1"] = Instance.new("ScreenGui", core)
G2L["1"].IgnoreGuiInset = true
G2L["1"].DisplayOrder = 999
G2L["1"].ResetOnSpawn = false
G2L["2"] = Instance.new("Frame", G2L["1"])
G2L["2"].BackgroundColor3 = Color3.fromRGB(35, 35, 35)
G2L["2"].AnchorPoint = Vector2.new(0.5, 0.5)
G2L["2"].Size = UDim2.new(0.35, 0, 0.5, 0)
G2L["2"].Position = UDim2.new(0.5, 0, 0.5, 0)
G2L["2"].BorderSizePixel = 0
G2L["3"] = Instance.new("UICorner", G2L["2"])
G2L["3"].CornerRadius = UDim.new(0.02, 0)
G2L["4"] = Instance.new("Frame", G2L["2"])
G2L["4"].BackgroundColor3 = Color3.fromRGB(50, 50, 50)
G2L["4"].Size = UDim2.new(1, 0, 0.08, 0)
G2L["4"].BorderSizePixel = 0
G2L["4"].Name = "bar"
G2L["5"] = Instance.new("UICorner", G2L["4"])
G2L["5"].CornerRadius = UDim.new(0.02, 0)
G2L["6"] = Instance.new("TextLabel", G2L["4"])
G2L["6"].BackgroundTransparency = 1
G2L["6"].Size = UDim2.new(0.7, 0, 1, 0)
G2L["6"].Text = "NPC Control v7.6 | by xtel" -- Versão Atualizada
G2L["6"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["6"].TextScaled = true
G2L["6"].Font = Enum.Font.SourceSansBold
G2L["6"].TextXAlignment = Enum.TextXAlignment.Left
G2L["6"].Position = UDim2.new(0.05, 0, 0, 0)
G2L["7"] = Instance.new("TextButton", G2L["4"])
G2L["7"].BackgroundColor3 = Color3.fromRGB(220, 50, 50)
G2L["7"].Size = UDim2.new(0.06, 0, 0.7, 0)
G2L["7"].Position = UDim2.new(0.93, 0, 0.15, 0)
G2L["7"].Text = "X"
G2L["7"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["7"].TextScaled = true
G2L["7"].Font = Enum.Font.SourceSansBold
G2L["7"].BorderSizePixel = 0
G2L["7"].Name = "close"
G2L["8"] = Instance.new("UICorner", G2L["7"])
G2L["8"].CornerRadius = UDim.new(0.2, 0)
G2L["9"] = Instance.new("TextButton", G2L["4"])
G2L["9"].BackgroundColor3 = Color3.fromRGB(80, 80, 80)
G2L["9"].Size = UDim2.new(0.06, 0, 0.7, 0)
G2L["9"].Position = UDim2.new(0.86, 0, 0.15, 0)
G2L["9"].Text = "-"
G2L["9"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["9"].TextScaled = true
G2L["9"].Font = Enum.Font.SourceSansBold
G2L["9"].BorderSizePixel = 0
G2L["9"].Name = "minimize"
G2L["10"] = Instance.new("UICorner", G2L["9"])
G2L["10"].CornerRadius = UDim.new(0.2, 0)
G2L["icon"] = Instance.new("TextButton", G2L["1"])
G2L["icon"].BackgroundColor3 = Color3.fromRGB(50, 50, 50)
G2L["icon"].Size = UDim2.new(0, 50, 0, 50)
G2L["icon"].Position = UDim2.new(0, 10, 0, 10)
G2L["icon"].Text = "NPC"
G2L["icon"].TextColor3 = Color3.fromRGB(255, 255, 255)
G2L["icon"].TextScaled = true
G2L["icon"].Visible = false
G2L["icon"].Name = "icon"
G2L["iconCorner"] = Instance.new("UICorner", G2L["icon"])
G2L["iconCorner"].CornerRadius = UDim.new(0.2, 0)
G2L["11"] = Instance.new("ScrollingFrame", G2L["2"])
G2L["11"].BackgroundColor3 = Color3.fromRGB(40, 40, 40)
G2L["11"].Size = UDim2.new(0.45, 0, 0.85, 0)
G2L["11"].Position = UDim2.new(0.02, 0, 0.1, 0)
G2L["11"].ScrollBarThickness = 6
G2L["11"].ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
G2L["11"].BorderSizePixel = 0
G2L["11"].AutomaticCanvasSize = Enum.AutomaticSize.Y
G2L["12"] = Instance.new("UIListLayout", G2L["11"])
G2L["12"].Padding = UDim.new(0.01, 0)
G2L["12"].SortOrder = Enum.SortOrder.LayoutOrder
G2L["13"] = Instance.new("ScrollingFrame", G2L["2"])
G2L["13"].BackgroundTransparency = 1
G2L["13"].Size = UDim2.new(0.5, 0, 0.85, 0)
G2L["13"].Position = UDim2.new(0.48, 0, 0.1, 0)
G2L["13"].ScrollBarThickness = 6
G2L["13"].ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
G2L["13"].BorderSizePixel = 0
G2L["13"].AutomaticCanvasSize = Enum.AutomaticSize.Y
G2L["14"] = Instance.new("UIListLayout", G2L["13"])
G2L["14"].Padding = UDim.new(0.01, 0)
G2L["14"].SortOrder = Enum.SortOrder.LayoutOrder

statusLabel = Instance.new("TextLabel", G2L["2"]) 
statusLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
statusLabel.Size = UDim2.new(0.96, 0, 0.05, 0)
statusLabel.Position = UDim2.new(0.02, 0, 0.96, 0)
statusLabel.Text = "NPC Control: Scanning..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.BorderSizePixel = 0
local statusCorner = Instance.new("UICorner", statusLabel)
statusCorner.CornerRadius = UDim.new(0.1, 0)


local function createNPCButton(npc, index)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.Size = UDim2.new(0.95, 0, 0, 30)
    local distance = "??"
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("HumanoidRootPart") then
        distance = math.floor((npc.HumanoidRootPart.Position - lp.Character.HumanoidRootPart.Position).Magnitude)
    end
    button.Text = npc.Name .. " (" .. distance .. ")"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSans
    button.BorderSizePixel = 0
    button.Parent = G2L["11"]
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0.1, 0)
    local selected = table.find(selectedNPCs, npc)
    if selected then
        button.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    end
    button.MouseButton1Click:Connect(function()
        if table.find(selectedNPCs, npc) then
            for i, selectedNPC in pairs(selectedNPCs) do
                if selectedNPC == npc then
                    table.remove(selectedNPCs, i)
                    break
                end
            end
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        else
            table.insert(selectedNPCs, npc)
            button.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
        end
        currentNPC = npc
        updateAllGlows()
        updateModoCliqueButton(false) 
    end)
    button.MouseButton2Click:Connect(function()
        currentNPC = npc
        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
        if hrp then ws.CurrentCamera.CameraSubject = hrp end
        updateModoCliqueButton(false) 
        tempGlow(npc, Color3.fromRGB(0, 0, 255))
    end)
    return button
end
local function createActionButton(text, callback)
    local button = Instance.new("TextButton")
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.Size = UDim2.new(0.95, 0, 0, 35)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSans
    button.BorderSizePixel = 0
    button.Parent = G2L["13"]
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0.1, 0)
    button.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)
    return button
end

local function updateNPCList()
    for _, child in pairs(G2L["11"]:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    scanNPCs()
    for i, npc in pairs(npcList) do
        createNPCButton(npc, i)
    end
    
    updateModoCliqueButton(false) 
end

local function updateAllGlows()
    local toRemove = {}
    for npc in pairs(npcGlows) do
        if npc and npc.Parent then 
            updateGlow(npc)
        else
            clearNPCGlows(npc) 
            table.insert(toRemove, npc)
        end
    end
    for _, npc in ipairs(toRemove) do
        npcGlows[npc] = nil 
    end
end

-- =========================================================
-- Kill / Teleport (MANTIDO)
-- =========================================================
local function attemptKill(npc, attempt)
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        if attempt <= 2 then
            forceOwnership(npc)
        end
        
        local success = pcall(function() 
            hum.Health = 0 
            hum:TakeDamage(99999999)
            hum:ChangeState(Enum.HumanoidStateType.Dead)
        end)
        
        task.wait(0.1) 
        
        return success and hum.Health <= 0.01 
    end
    return true 
end

local function killNPCs(targetNPCs)
    local successCount = 0
    for _, npc in pairs(targetNPCs) do
        local isKilled = false
        for attempt = 1, 3 do
            if attemptKill(npc, attempt) then
                isKilled = true
                break
            end
            task.wait(0.1)
        end
        
        if isKilled then
            successCount = successCount + 1
            flashGlow(npc, Color3.fromRGB(255, 0, 0))
        else
            flashGlow(npc, Color3.fromRGB(150, 0, 255))
        end
    end
    return successCount
end

local function teleportToNPC()
    local targetNPCs = (#selectedNPCs == 0 and currentNPC and {currentNPC}) or selectedNPCs
    if #targetNPCs == 0 then statusLabel.Text = "Nenhum NPC selecionado para teletransportar!" return end
    
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then statusLabel.Text = "Erro: Seu personagem não está carregado." return end

    local successCount = 0
    
    for _, npc in pairs(targetNPCs) do
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if hrp then
            local destination = hrp.Position + hrp.CFrame.LookVector * 5 
            local verticalOffset = myHRP.Size.Y / 2 
            
            myHRP.CFrame = CFrame.new(destination + Vector3.new(0, verticalOffset, 0), hrp.Position) 
            
            successCount = successCount + 1
            tempGlow(npc, Color3.fromRGB(173, 216, 230))
        end
    end

    statusLabel.Text = successCount .. "/" .. #targetNPCs .. " NPC(s) teleportado(s) para você!"
end

-- =========================================================
-- Funções de Controle de NPC (v7.6 - CORRIGIDO)
-- =========================================================

local function disableNPCScripts(npc)
    disabledScripts = {}
    for _, script in npc:GetChildren() do
        if (script:IsA("Script") or script:IsA("LocalScript")) and pcall(function() return script.Enabled end) then
            local name = script.Name:lower()
            -- Adicionando mais filtros para scripts de IA
            if name:match("move") or name:match("attack") or name:match("ai") or name:match("control") or name:match("path") or name:match("walk") or name:match("run") then
                pcall(function() 
                    script.Enabled = false 
                    table.insert(disabledScripts, script) 
                end)
            end
        end
    end
end

local function reenableNPCScripts()
    for _, script in pairs(disabledScripts) do
        pcall(function() 
            script.Enabled = true 
        end)
    end
    disabledScripts = {}
end


local function stopControllingNPC()
    local toggleButton = G2L["toggleControlButton"]
    if not isControlling or not playerCharacterBackup then 
        if toggleButton then
             toggleButton.Text = "Assumir Controle (NPCs)"
             toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        return false 
    end
    
    -- 1. Desconecta os loops
    if connections.forceControl then connections.forceControl:Disconnect() connections.forceControl = nil end
    if connections.preventMovement then connections.preventMovement:Disconnect() connections.preventMovement = nil end
    
    if controlledNPC and controlledNPC.Parent and controlledNPC:FindFirstChild("HumanoidRootPart") then
        local hum = controlledNPC:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum.WalkSpeed = npcOriginalWalkSpeed or 16 
                hum.AutoRotate = npcOriginalAutoRotate or true
            end)
        end
        
        -- Libera o Network Ownership do NPC (CRUCIAL)
        local hrp = controlledNPC:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp:SetNetworkOwner(nil) 
            end)
        end
        
        reenableNPCScripts() 
    end
    
    task.wait(0.2) 
    
    -- 2. Restaura o personagem do jogador ativamente
    if playerCharacterBackup.Parent == ws then
        lp.Character = playerCharacterBackup
    end

    task.wait(0.2) 
    
    -- 3. Restaura a câmera
    if lp.Character then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        if hum then 
            ws.CurrentCamera.CameraSubject = hum 
            lp.CameraMode = Enum.CameraMode.Classic
        else
            ws.CurrentCamera.CameraSubject = lp 
            lp.CameraMode = Enum.CameraMode.Classic
        end
    end
    
    -- 4. Limpa estados
    isControlling = false
    controlledNPC = nil
    playerCharacterBackup = nil 
    npcOriginalWalkSpeed = nil
    npcOriginalAutoRotate = nil
    
    updateAllGlows() 
    return true
end

local function startContinuousOwnership()
    if connections.forceControl then return end 
    connections.forceControl = rs.RenderStepped:Connect(function()
        if isControlling and controlledNPC and controlledNPC.Parent then
            local hrp = controlledNPC:FindFirstChild("HumanoidRootPart")
            if hrp and not hasNetworkOwnership(controlledNPC) then
                pcall(function()
                    hrp:SetNetworkOwner(lp) 
                end)
            end
        else
            if connections.forceControl then connections.forceControl:Disconnect() connections.forceControl = nil end
        end
    end)
end

local function startMovementCorrection()
    if connections.preventMovement then return end
    connections.preventMovement = rs.Stepped:Connect(function()
        if isControlling and controlledNPC and controlledNPC.Parent then
            local hum = controlledNPC:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() 
                    hum:ChangeState(Enum.HumanoidStateType.Physics) 
                    hum:ChangeState(Enum.HumanoidStateType.None)    
                end)
            end
        else
            if connections.preventMovement then connections.preventMovement:Disconnect() connections.preventMovement = nil end
        end
    end)
end

local function controlNPC(npc)
    -- Assegura que o personagem do jogador existe antes de fazer o backup
    if not lp.Character or not lp.Character:FindFirstChildOfClass("Humanoid") then
        statusLabel.Text = "Erro: Seu personagem não está carregado. Não é possível assumir controle."
        return false
    end
    
    playerCharacterBackup = lp.Character 
    
    local hum = npc:FindFirstChildOfClass("Humanoid")
    local hrp = npc:FindFirstChild("HumanoidRootPart")

    if not npc or not hum or not hrp then return false end
    
    disableNPCScripts(npc)
    task.wait(0.1) -- Pausa para os scripts desligarem
    
    npcOriginalWalkSpeed = hum.WalkSpeed
    npcOriginalAutoRotate = hum.AutoRotate
    
    pcall(function()
        hum.WalkSpeed = npcOriginalWalkSpeed or 16 
        hum.AutoRotate = true 
    end)
    
    -- Tenta forçar ownership de forma mais agressiva (10 tentativas)
    local ownershipAttempts = 0
    while not hasNetworkOwnership(npc) and ownershipAttempts < 10 do 
        pcall(function() hrp:SetNetworkOwner(lp) end)
        task.wait(0.02) -- Pausa muito curta para forçar mais rápido
        ownershipAttempts = ownershipAttempts + 1
    end
    
    if not hasNetworkOwnership(npc) then
        pcall(function() hum.WalkSpeed = npcOriginalWalkSpeed; hum.AutoRotate = npcOriginalAutoRotate end)
        reenableNPCScripts() 
        return false -- Falha na Aquisição de Ownership
    end
    
    -- Transfere o controle
    lp.Character = npc
    ws.CurrentCamera.CameraSubject = hum 
    lp.CameraMode = Enum.CameraMode.Classic
    
    isControlling = true
    controlledNPC = npc
    
    startContinuousOwnership() 
    startMovementCorrection() 
    
    tempGlow(npc, Color3.fromRGB(0, 255, 0)) 
    
    return true
end


local function toggleNPCControl()
    local toggleButton = G2L["toggleControlButton"]
    if not toggleButton or not toggleButton.Parent then return end 

    if isControlling then
        local success = stopControllingNPC()
        if success then
            toggleButton.Text = "Assumir Controle (NPCs)"
            toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            statusLabel.Text = "Controle parado. Retornou ao seu Character."
        else
            statusLabel.Text = "ERRO: Falha ao parar o controle. Tente novamente."
        end
    else
        local targetNPCs = selectedNPCs 
        if #targetNPCs == 0 and currentNPC then targetNPCs = {currentNPC} end
        
        if #targetNPCs == 0 then statusLabel.Text = "Selecione um NPC antes de tentar controlar!" return end
        
        local npcToControl = targetNPCs[1]
        
        local success = controlNPC(npcToControl)
        
        if success then
            toggleButton.Text = "Parar Controle (" .. npcToControl.Name .. ")"
            toggleButton.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
            statusLabel.Text = "Controle de " .. npcToControl.Name .. " assumido com sucesso!"
        else
            toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            statusLabel.Text = "Falha ao assumir controle de " .. npcToControl.Name .. ". Falha na Aquisição de Ownership."
        end
    end
end


-- Criação dos Botões de Ação
createActionButton("Fazer NPC Pular ⬆️", function()
    local targetNPCs = (#selectedNPCs == 0 and currentNPC and {currentNPC}) or selectedNPCs
    if #targetNPCs == 0 then statusLabel.Text = "Nenhum NPC selecionado!" return end
    local successCount = 0
    for _, npc in pairs(targetNPCs) do
        local hum = npc:FindFirstChildOfClass("Humanoid")
        if hum then
            forceOwnership(npc)
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            successCount = successCount + 1
            tempGlow(npc, Color3.fromRGB(0, 255, 255))
        end
    end
    statusLabel.Text = successCount .. "/" .. #targetNPCs .. " NPCs pularam!"
end)

local killButton = createActionButton("Matar NPC(s) 💀 (Selecionados)", function()
    local targetNPCs = (#selectedNPCs == 0 and currentNPC and {currentNPC}) or selectedNPCs
    if #targetNPCs == 0 then statusLabel.Text = "Nenhum NPC selecionado para matar!" return end
    local count = killNPCs(targetNPCs)
    statusLabel.Text = count .. "/" .. #targetNPCs .. " NPCs mortos!"
end)

createActionButton("KILL ALL! 🚨 (Teleport/Kill)", function() statusLabel.Text = "Função desabilitada para esta versão de teste. Use o Teleport/Kill individualmente." end)


local toggleControlButton = createActionButton("Assumir Controle (NPCs)", toggleNPCControl)
G2L["toggleControlButton"] = toggleControlButton 

createActionButton("Teleportar para NPC (Instantâneo) 🎯", teleportToNPC) 


createActionButton("Teleportar para Mim 🧍", function()
    local targetNPCs = (#selectedNPCs == 0 and currentNPC and {currentNPC}) or selectedNPCs
    if #targetNPCs == 0 then statusLabel.Text = "Nenhum NPC selecionado para teletransportar!" return end
    
    local myHRP = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then statusLabel.Text = "Erro: Seu personagem não está carregado." return end

    local originalCFrame = myHRP.CFrame
    local successCount = 0
    
    for _, npc in pairs(targetNPCs) do
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if hrp then
            if (hrp.Position - myHRP.Position).Magnitude > 500 then
                myHRP.CFrame = CFrame.new(hrp.Position) * CFrame.new(0, 0, 100)
                task.wait(0.2) 
            end

            forceOwnership(npc) 
            
            local destination = originalCFrame.Position + originalCFrame.LookVector * 5 
            local verticalOffset = hrp.Size.Y / 2
            
            local rotationCFrame = CFrame.new(destination + Vector3.new(0, verticalOffset, 0)) * CFrame.Angles(0, 0, 0)
            
            hrp.CFrame = rotationCFrame
            
            successCount = successCount + 1
            tempGlow(npc, Color3.fromRGB(255, 0, 255)) 
        end
    end

    myHRP.CFrame = originalCFrame
    statusLabel.Text = successCount .. "/" .. #targetNPCs .. " NPC(s) teleportado(s) para você! (Strategy 2)"
end)

createActionButton("Teleportar para Clique 🚀", function()
    updateModoCliqueButton(true) 
    
    local targetNPCs = (#selectedNPCs == 0 and currentNPC and {currentNPC}) or selectedNPCs
    if #targetNPCs == 0 then statusLabel.Text = "Nenhum NPC selecionado para teletransportar!" return end
    statusLabel.Text = "Aguardando clique do mouse para Teletransporte..."
    
    if teleportConnection then teleportConnection:Disconnect() teleportConnection = nil end
    
    teleportConnection = mouse.Button1Down:Connect(function()
        if mouse.Target and mouse.Hit then
            local destination = mouse.Hit.Position
            local successCount = 0
            
            for _, npc in pairs(targetNPCs) do
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                if hrp then
                    forceOwnership(npc)
                    local verticalOffset = hrp.Size.Y / 2
                    hrp.CFrame = CFrame.new(destination + Vector3.new(0, verticalOffset, 0))
                    successCount = successCount + 1
                    tempGlow(npc, Color3.fromRGB(138, 43, 226))
                end
            end
            
            statusLabel.Text = successCount .. "/" .. #targetNPCs .. " NPC(s) teletransportado(s)!"
            if teleportConnection then teleportConnection:Disconnect() teleportConnection = nil end
        end
    end)
    
    task.delay(15, function()
        if teleportConnection then
            teleportConnection:Disconnect()
            teleportConnection = nil
            statusLabel.Text = "Ação de teleporte cancelada. Tempo esgotado."
        end
    end)
end)

createActionButton("Lançar NPC (Míssil) ☄️", function() statusLabel.Text = "Função Lançar NPC desabilitada para esta versão de teste." end) 

createActionButton("Testar Ownership (1 NPC)", function()
    if currentNPC then
        if hasNetworkOwnership(currentNPC) then
            statusLabel.Text = "Ownership: SIM (Client)"
            tempGlow(currentNPC, Color3.fromRGB(0, 255, 0))
        else
            statusLabel.Text = "Ownership: NÃO (Outro Player/Server)"
            tempGlow(currentNPC, Color3.fromRGB(255, 0, 0))
        end
    end
end)

createActionButton("Forçar Ownership (1 NPC)", function()
    if currentNPC then
        if forceOwnership(currentNPC) then
            statusLabel.Text = "Ownership forçado: SIM"
            tempGlow(currentNPC, Color3.fromRGB(0, 255, 0))
        else
            statusLabel.Text = "Ownership forçado: NÃO"
            tempGlow(currentNPC, Color3.fromRGB(255, 0, 0))
        end
    end
end)

local modoCliqueButton = createActionButton("Modo Clique: OFF", function()
    clicknpc = not clicknpc
    updateModoCliqueButton(false) 
end)
G2L["modoCliqueButton"] = modoCliqueButton 

createActionButton("Atualizar Lista 🔄", updateNPCList)

createActionButton("Selecionar Todos ✅", function()
    selectedNPCs = {}
    for _, npc in pairs(npcList) do table.insert(selectedNPCs, npc) end
    updateNPCList()
end)

createActionButton("Limpar Seleção ❌", function()
    selectedNPCs = {}
    currentNPC = nil
    updateNPCList()
end)


local function toggleMinimize()
    minimizebool = not minimizebool
    if minimizebool then
        G2L["2"].Visible = false
        G2L["icon"].Visible = true
    else
        G2L["2"].Visible = true
        G2L["icon"].Visible = false
    end
end

G2L["9"].MouseButton1Click:Connect(toggleMinimize)
G2L["icon"].MouseButton1Click:Connect(toggleMinimize)

G2L["7"].MouseButton1Click:Connect(function()
    stopControllingNPC() 
    for _, connection in pairs(connections) do if connection then connection:Disconnect() end end
    for npc, glow in pairs(npcGlows) do clearNPCGlows(npc) end 
    if playerCharacterBackup and playerCharacterBackup.Parent then 
        lp.Character = playerCharacterBackup 
        local hum = playerCharacterBackup:FindFirstChildOfClass("Humanoid")
        if hum then
             ws.CurrentCamera.CameraSubject = hum
        end
    end 
    G2L["1"]:Destroy()
end)

local dragging = false
local dragStart = nil
local startPos = nil
G2L["4"].InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = G2L["2"].Position
    end
end)
G2L["4"].InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        G2L["2"].Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
G2L["4"].InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

mouse.Button1Down:Connect(function()
    if clicknpc and mouse.Target then
        if not mouse.Target:IsDescendantOf(G2L["1"]) then
            local model = mouse.Target:FindFirstAncestorOfClass("Model")
            if model and isNPC(model) then 
                currentNPC = model
                if not table.find(selectedNPCs, model) then table.insert(selectedNPCs, model) end
                updateNPCList()
                tempGlow(model, Color3.fromRGB(0, 255, 0)) 
            end
        end
    end
end)

connections.autoscan = rs.Stepped:Connect(function()
    scanNPCs()
    updateNPCInfo()
    updateAllGlows() 
end)

connections.ownership = rs.RenderStepped:Connect(function()
    if sethiddenproperty then
        pcall(sethiddenproperty, lp, "SimulationRadius", rad)
    else
        pcall(function() lp.SimulationRadius = rad end)
    end
end)

-- Initial setup
updateNPCList()

print("NPC Control v7.6 by xtel carregado! (Controle de NPC Reescrito/Reforçado)")
