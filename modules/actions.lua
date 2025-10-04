local M = {}
M.name = "actions"
M.version = "1.0.0"

function M.init(api)
    local Services = api.Services
    local ws = Services.Workspace
    local lp = Services.Players.LocalPlayer
    local rs = Services.RunService
    local debris = Services.Debris

    -- helpers (encaminham para o npc_manager)
    local isNPC = api.npc.isNPC
    local hasOwnership = api.npc.hasNetworkOwnership
    local apply = api.applyToSelectedNPCs
    local add_selected = api.add_selected
    local get_selected = api.get_selected

    -- botão: deselecionar
    api.register_button("Desselecionar NPCs", function()
        api.clear_selected()
    end)

    -- selecionar todos e teleportar
    api.register_button("Selecionar Todos e Teleportar", function()
        api.clear_selected()
        for _, model in pairs(ws:GetDescendants()) do
            if isNPC(model) and hasOwnership(model) then
                add_selected(model)
                if lp.Character then
                    model:PivotTo(lp.Character:GetPivot() + Vector3.new(math.random(-5,5),0,math.random(-5,5)))
                    if api.lightNPC then api.lightNPC(model, Color3.fromRGB(0,255,0)) end
                end
            end
        end
    end)

    api.register_button("Eliminar NPCs", function()
        apply(function(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(15)
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,0,0)) end
            end
        end)
    end)

    api.register_button("Teleportar NPCs", function()
        if lp.Character then
            apply(function(npc)
                npc:PivotTo(lp.Character:GetPivot() + Vector3.new(math.random(-5,5),0,math.random(-5,5)))
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(0,255,0)) end
            end)
        end
    end)

    api.register_button("Ir para NPCs", function()
        local sel = get_selected()
        if sel[1] and lp.Character then
            lp.Character:PivotTo(sel[1]:GetPivot())
            if api.lightNPC then api.lightNPC(sel[1], Color3.fromRGB(0,0,255)) end
        end
    end)

    api.register_button("Punir NPCs", function()
        apply(function(npc)
            npc:PivotTo(CFrame.new(0,1000,0))
            if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,0,255)) end
        end)
    end)

    api.register_button("Sentar/Levantar", function()
        apply(function(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Sit = not hum.Sit
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,255,0)) end
            end
        end)
    end)

    api.register_button("Pular", function()
        apply(function(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(3)
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(0,255,255)) end
            end
        end)
    end)

    api.register_button("Explodir NPCs", function()
        apply(function(npc)
            local explosion = Instance.new("Explosion")
            explosion.Position = npc:GetPivot().Position
            explosion.Parent = ws
            if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,50,50)) end
        end)
    end)

    api.register_button("Congelar NPCs", function()
        apply(function(npc)
            local hrp = npc:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = not hrp.Anchored
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(0,255,255)) end
            end
        end)
    end)

    api.register_button("Mudar Velocidade", function()
        apply(function(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = hum.WalkSpeed == 16 and 32 or 16
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,165,0)) end
            end
        end)
    end)

    api.register_button("Clonar NPCs", function()
        local newNPCs = {}
        for _, npc in pairs(get_selected()) do
            if hasOwnership(npc) then
                local clone = npc:Clone()
                clone.Parent = ws
                clone:PivotTo(npc:GetPivot() + Vector3.new(math.random(-5,5),0,math.random(-5,5)))
                if hasOwnership(clone) then
                    table.insert(newNPCs, clone)
                    if api.lightNPC then api.lightNPC(clone, Color3.fromRGB(0,255,0)) end
                end
            end
        end
        for _, c in pairs(newNPCs) do
            api.add_selected(c)
        end
    end)

    api.register_button("Alternar Colisão", function()
        apply(function(npc)
            for _, part in pairs(npc:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not part.CanCollide
                    if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,255,255)) end
                end
            end
        end)
    end)

    api.register_button("NPCs Dançar", function()
        apply(function(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    local animation = Instance.new("Animation")
                    animation.AnimationId = "rbxassetid://507771019"
                    local track = animator:LoadAnimation(animation)
                    track:Play()
                    if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,105,180)) end
                    debris:AddItem(animation, 10)
                end
            end
        end)
    end)

    api.register_button("Alterar Vida", function()
        apply(function(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.MaxHealth = hum.MaxHealth == 100 and 200 or 100
                hum.Health = hum.MaxHealth
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(0,255,0)) end
            end
        end)
    end)

    api.register_button("NPC Correr", function()
        apply(function(npc)
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 32
                -- exemplo simples de movimento
                local rand = Vector3.new(math.random(-1,1),0,math.random(-1,1))
                if rand.Magnitude > 0 then
                    hum:Move(rand.Unit * 32)
                end
                if api.lightNPC then api.lightNPC(npc, Color3.fromRGB(255,69,0)) end
            end
        end)
    end)

    -- toggles (auto behaviors)
    local followToggle = api.register_toggle("NPCs Seguir", function(state)
        if state then
            api._connections.follow = rs.RenderStepped:Connect(function()
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                api.applyToSelectedNPCs(function(npc)
                    if api.npc.hasNetworkOwnership(npc) then
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:MoveTo(hrp.Position + Vector3.new(math.random(-5,5),0,math.random(-5,5)))
                        end
                    end
                end)
            end)
        else
            if api._connections.follow then api._connections.follow:Disconnect() api._connections.follow = nil end
        end
    end)

    local killAuraToggle = api.register_toggle("Kill Aura (Raio 15)", function(state)
        if state then
            api._connections.killaura = rs.Stepped:Connect(function()
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local nearby = ws:GetPartBoundsInRadius(hrp.Position, 15)
                for _, part in pairs(nearby) do
                    local model = part:FindFirstAncestorOfClass("Model")
                    if model and isNPC(model) and hasOwnership(model) and not table.find(api.get_selected(), model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:ChangeState(15)
                            if api.lightNPC then api.lightNPC(model, Color3.fromRGB(255,0,0)) end
                        end
                    end
                end
            end)
        else
            if api._connections.killaura then api._connections.killaura:Disconnect(); api._connections.killaura = nil end
        end
    end)

    local flyToggle = api.register_toggle("NPCs Voar", function(state)
        if state then
            api._connections.fly = rs.RenderStepped:Connect(function()
                api.applyToSelectedNPCs(function(npc)
                    if hasOwnership(npc) then
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                            bv.Velocity = Vector3.new(0,20,0)
                            bv.Parent = hrp
                            debris:AddItem(bv, 0.1)
                        end
                    end
                end)
            end)
        else
            if api._connections.fly then api._connections.fly:Disconnect(); api._connections.fly = nil end
        end
    end)

    local autoControlToggle = api.register_toggle("Auto Controle (Raio 20)", function(state)
        if state then
            api._connections.autocontrol = rs.Stepped:Connect(function()
                local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local nearby = ws:GetPartBoundsInRadius(hrp.Position, api.config.autoControlRange)
                for _, part in pairs(nearby) do
                    local model = part:FindFirstAncestorOfClass("Model")
                    if model and isNPC(model) and hasOwnership(model) and not table.find(api.get_selected(), model) then
                        api.add_selected(model)
                        if api.lightNPC then api.lightNPC(model, Color3.fromRGB(0,255,0)) end
                    end
                end
            end)
        else
            if api._connections.autocontrol then api._connections.autocontrol:Disconnect(); api._connections.autocontrol = nil end
        end
    end)

    api.print("actions loaded")
end

return M
