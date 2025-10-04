local M = {}
M.name = "highlight"
M.version = "1.0.0"

function M.init(api)
    local Players = api.Services.Players
    local lp = Players.LocalPlayer
    local highlight = Instance.new("Highlight")
    highlight.Parent = lp
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1

    api.lightNPC = function(adornee, color)
        task.spawn(function()
            highlight.Adornee = adornee
            highlight.OutlineColor = color
            api.Services.TweenService:Create(highlight, api.config.fast, {OutlineTransparency = 0}):Play()
            task.wait(0.5)
            api.Services.TweenService:Create(highlight, api.config.fast, {OutlineTransparency = 1}):Play()
        end)
    end

    api.print("highlight loaded")
end

return M
