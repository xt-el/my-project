local M = {}
M.name = "config"
M.version = "1.0.0"

function M.init(api)
    api.config = {
        rad = 100,
        selectionRange = 100,
        autoControlRange = 20,
        fast = TweenInfo.new(0.3, Enum.EasingStyle.Exponential)
    }
    api.print("config loaded")
end

return M
