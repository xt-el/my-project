local M = {}
M.name = "npc_manager"
M.version = "1.0.0"

local selectedNPCs = {}
local connections = {}

function M.init(api)
    local Services = api.Services
    local Players = Services.Players

    api.clear_selected = function()
        selectedNPCs = {}
        if api.updateStatus then api.updateStatus("NPCs: Nenhum selecionado", Color3.fromRGB(255,255,255)) end
    end

    api.add_selected = function(model)
        if not model then return end
        if not table.find(selectedNPCs, model) then
            table.insert(selectedNPCs, model)
            if api.updateStatus then api.updateStatus(("NPCs: %d selecionados"):format(#selectedNPCs), Color3.fromRGB(0,255,0)) end
        end
    end

    api.get_selected = function()
        return selectedNPCs
    end

    function M.hasNetworkOwnership(npc)
        local part = npc and npc:FindFirstChild("HumanoidRootPart")
        return part and part.ReceiveAge == 0 and not part.Anchored
    end

    function M.isNPC(model)
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        local player = humanoid and Players:GetPlayerFromCharacter(model)
        return humanoid and not player and model
    end

    api.applyToSelectedNPCs = function(action)
        for i = 1, #selectedNPCs do
            local npc = selectedNPCs[i]
            if npc and M.hasNetworkOwnership(npc) then
                action(npc)
            end
        end
    end

    api.npc = {
        isNPC = M.isNPC,
        hasNetworkOwnership = M.hasNetworkOwnership,
        get_selected = api.get_selected
    }

    api._connections = connections
    api.print("npc_manager loaded")
end

return M
